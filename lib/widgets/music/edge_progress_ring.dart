import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Prsten reprodukcije: linija koja obilazi **ivicu ekrana**.
///
/// Kreće iz gornjeg levog ugla, ide desno duž gornje ivice, niz desnu ivicu,
/// duž donje nalevo i uz levu nagore — nazad u gornji levi ugao. Kraj se
/// poklapa sa početkom, pa pesma korisniku deluje kao krug koji se zatvara.
///
/// Pređeni deo je u boji `accent`, nepređeni u `accentDeep`; na trenutnoj
/// poziciji stoji mala tačka koja klizi po putanji.
///
/// **Prevlačenjem po liniji se premota pesma** (MUSIC-015), ako je prosleđen
/// [onSeek]. Dodir se hvata samo u uskim trakama uz ivice, pa spisak u sredini
/// i dalje normalno skroluje.
///
/// **Gornja linija ne ide uz samu ivicu ekrana**, nego ispod mesta gde stoji
/// header. Uz ivicu bi prevlačenje padalo u pojas kojim sistem otvara zavesu
/// sa podešavanjima — usred nastupa je dovoljno da prst malo promaši pa da se
/// isključi Wi-Fi.
///
/// **Za performanse:** prerisavanje okida [progress] kao `Listenable`, bez
/// ponovnog građenja widget stabla; putanja se gradi jednom po veličini
/// ekrana, a ceo prsten ide u `RepaintBoundary`.
///
/// Talasni oblik pesme (amplitude) dolazi u kasnijoj fazi — dok ga nema,
/// crta se ravna linija, nikad prazan ekran.
class EdgeProgressRing extends StatefulWidget {
  const EdgeProgressRing({
    super.key,
    required this.progress,
    this.child,
    this.topInset = defaultTopInset,
    this.onSeekStart,
    this.onSeekUpdate,
    this.onSeekEnd,
  });

  /// Dokle je stigla reprodukcija, 0..1.
  final ValueListenable<double> progress;

  /// Sadržaj koji stoji unutar prstena.
  final Widget? child;

  /// Koliko je gornja linija spuštena na ovom ekranu.
  final double topInset;

  /// Javljaju premotavanje prevlačenjem. Kad su `null`, prsten se samo gleda.
  final VoidCallback? onSeekStart;
  final ValueChanged<double>? onSeekUpdate;
  final ValueChanged<double>? onSeekEnd;

  /// Koliko je linija uvučena sa leve, desne i donje ivice.
  static const double inset = 18;

  /// Koliko je gornja linija spuštena od vrha.
  ///
  /// Jednako visini headera (72 dp) — linija prolazi tačno ispod mesta gde
  /// header stoji, van pojasa kojim se otvara sistemska zavesa.
  static const double defaultTopInset = 72;

  /// Debljina linije.
  static const double strokeWidth = 4;

  /// Širina trake uz ivicu u kojoj se hvata prevlačenje.
  static const double touchBand = 30;

  @override
  State<EdgeProgressRing> createState() => _EdgeProgressRingState();
}

class _EdgeProgressRingState extends State<EdgeProgressRing> {
  ui.Path? _path;
  List<ui.PathMetric> _metrics = const [];
  double _length = 0;
  Size? _builtFor;
  double _builtTopInset = -1;

  bool get _canSeek => widget.onSeekUpdate != null || widget.onSeekEnd != null;

  /// Poslednje mesto na koje je prst stigao — kraj prevlačenja ne nosi
  /// položaj, pa se pamti usput.
  Offset _lastPoint = Offset.zero;

  /// Putanja se gradi jednom po veličini ekrana, ne po kadru.
  void _buildPath(Size size) {
    if (_builtFor == size && _builtTopInset == widget.topInset) return;

    final rect = Rect.fromLTRB(
      EdgeProgressRing.inset,
      widget.topInset,
      size.width - EdgeProgressRing.inset,
      size.height - EdgeProgressRing.inset,
    );

    // Putanja se gradi ručno, a ne preko `addRRect`, zato što `addRRect`
    // počinje na svom mestu i u svom smeru. Specifikacija traži tačno:
    // kreni iz **gornjeg levog ugla**, pa desno duž gornje ivice, niz desnu,
    // duž donje nalevo, i uz levu nazad gore.
    const double r = kCardRadius * 2;
    final path = ui.Path()
      ..moveTo(rect.left + r, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + r),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(
        Offset(rect.right - r, rect.bottom),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(
        Offset(rect.left, rect.bottom - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(
        Offset(rect.left + r, rect.top),
        radius: const Radius.circular(r),
      )
      ..close();

    _path = path;
    _metrics = path.computeMetrics().toList();
    _length = _metrics.fold<double>(0, (sum, m) => sum + m.length);
    _builtFor = size;
    _builtTopInset = widget.topInset;
  }

  /// Gde se na putanji nalazi data dužina.
  Offset? _pointAtLength(double distance) {
    var remaining = distance;
    for (final metric in _metrics) {
      if (remaining <= metric.length) {
        return metric.getTangentForOffset(remaining)?.position;
      }
      remaining -= metric.length;
    }
    return null;
  }

  /// Koji deo pesme odgovara mestu na koje je korisnik stavio prst.
  ///
  /// Putanja se uzorkuje i traži se najbliža tačka — jednostavnije i sigurnije
  /// od računanja po uglovima, a dovoljno tačno za prst.
  double _fractionFor(Offset point) {
    if (_length == 0) return 0;

    const samples = 240;
    var best = 0.0;
    var bestDistance = double.infinity;

    for (var i = 0; i <= samples; i++) {
      final fraction = i / samples;
      final candidate = _pointAtLength(_length * fraction);
      if (candidate == null) continue;
      final distance = (candidate - point).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = fraction;
      }
    }
    return best;
  }

  void _onDragStart(Offset local) {
    _lastPoint = local;
    widget.onSeekStart?.call();
    widget.onSeekUpdate?.call(_fractionFor(local));
  }

  void _onDragUpdate(Offset local) {
    _lastPoint = local;
    widget.onSeekUpdate?.call(_fractionFor(local));
  }

  void _onDragEnd(Offset local) {
    widget.onSeekEnd?.call(_fractionFor(local));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _buildPath(size);

        return Stack(
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: _EdgeRingPainter(
                  progress: widget.progress,
                  path: _path!,
                  metrics: _metrics,
                  length: _length,
                ),
              ),
            ),
            if (widget.child != null) Positioned.fill(child: widget.child!),
            if (_canSeek) ..._touchBands(size),
          ],
        );
      },
    );
  }

  /// Četiri uske trake uz ivice, u kojima se hvata prevlačenje.
  ///
  /// Gornja i donja hvataju **vodoravno** prevlačenje, leva i desna
  /// **uspravno** — u smeru u kome linija i ide. Tako spisak u sredini
  /// normalno skroluje, a prevlačenje uz ivicu premota pesmu.
  List<Widget> _touchBands(Size size) {
    const band = EdgeProgressRing.touchBand;

    Widget horizontal(double top) => Positioned(
      left: 0,
      right: 0,
      top: top,
      height: band,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (d) => _onDragStart(d.localPosition + Offset(0, top)),
        onHorizontalDragUpdate: (d) =>
            _onDragUpdate(d.localPosition + Offset(0, top)),
        onHorizontalDragEnd: (_) => _onDragEnd(_lastPoint),
      ),
    );

    Widget vertical(double left) => Positioned(
      top: 0,
      bottom: 0,
      left: left,
      width: band,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (d) => _onDragStart(d.localPosition + Offset(left, 0)),
        onVerticalDragUpdate: (d) =>
            _onDragUpdate(d.localPosition + Offset(left, 0)),
        onVerticalDragEnd: (_) => _onDragEnd(_lastPoint),
      ),
    );

    return [
      horizontal(widget.topInset - band / 2),
      horizontal(size.height - EdgeProgressRing.inset - band / 2),
      vertical(EdgeProgressRing.inset - band / 2),
      vertical(size.width - EdgeProgressRing.inset - band / 2),
    ];
  }

}

class _EdgeRingPainter extends CustomPainter {
  _EdgeRingPainter({
    required this.progress,
    required this.path,
    required this.metrics,
    required this.length,
  }) : super(repaint: progress);

  final ValueListenable<double> progress;
  final ui.Path path;
  final List<ui.PathMetric> metrics;
  final double length;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.value.clamp(0.0, 1.0);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = EdgeProgressRing.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accentDeep;

    // Nepređeni deo: vidljiv, ali povučen.
    canvas.drawPath(path, basePaint);

    if (value <= 0 || metrics.isEmpty) return;

    final travelled = ui.Path();
    var remaining = length * value;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0.0, metric.length);
      travelled.addPath(metric.extractPath(0, take), Offset.zero);
      remaining -= take;
    }

    final donePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = EdgeProgressRing.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;

    // Blagi sjaj oko pređenog dela.
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = EdgeProgressRing.strokeWidth * 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accentDeep
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(travelled, glowPaint);
    canvas.drawPath(travelled, donePaint);

    // Tačka na trenutnoj poziciji.
    final head = _pointAtLength(length * value);
    if (head != null) {
      canvas.drawCircle(
        head,
        EdgeProgressRing.strokeWidth * 1.6,
        Paint()..color = AppColors.accent,
      );
    }
  }

  Offset? _pointAtLength(double distance) {
    var remaining = distance;
    for (final metric in metrics) {
      if (remaining <= metric.length) {
        return metric.getTangentForOffset(remaining)?.position;
      }
      remaining -= metric.length;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _EdgeRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.path != path;
  }
}
