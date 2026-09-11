import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_theme.dart';

/// Pozadina u pokretu (proba „zlatno-crno"): preko pozadinskog gradijenta
/// polako plutaju dva zlatna odsjaja, a iza njih se okreću zupčanici kao u
/// satnom mehanizmu — kucnu, pa stanu, pa opet kucnu.
///
/// Crta se kroz [CustomPainter] vezan za protok vremena, pa se pri svakom
/// kadru samo preslika pozadina — stablo widgeta iznad nje se ne gradi ponovo.
/// Uz sistemski „smanjen pokret" pozadina stoji.
class AnimatedBackdrop extends StatefulWidget {
  const AnimatedBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// Proteklo vreme u sekundama. Ne vrti se u krug kao kontroler, pa
  /// zupčanici nikad ne preskoče nazad na početni položaj.
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);

  /// Koliko je vremena proteklo pre poslednjeg zaustavljanja.
  double _base = 0;

  void _onTick(Duration elapsed) {
    _seconds.value = _base + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_ticker.isActive) {
        _base = _seconds.value;
        _ticker.stop();
      }
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _BackdropPainter(_seconds)),
        ),
        widget.child,
      ],
    );
  }
}

/// Jedan zupčanik na ekranu: gde stoji, koliko ima zuba i kako se okreće u
/// odnosu na pogonski zupčanik (ugao = [phase] + [ratio] × ugao pogona).
class _Gear {
  _Gear({
    required this.center,
    required this.pitchRadius,
    required this.teeth,
    required this.phase,
    required this.ratio,
    required this.spokes,
    required this.path,
  });

  final Offset center;
  final double pitchRadius;
  final int teeth;
  final double phase;
  final double ratio;
  final int spokes;

  /// Obris sa zubima, oko (0, 0). Gradi se jednom po veličini ekrana.
  final Path path;
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.seconds) : super(repaint: seconds);

  final ValueNotifier<double> seconds;

  Size? _layoutSize;
  List<_Gear> _gears = const [];

  /// Na koliko sekundi mehanizam kucne.
  static const double _tickPeriod = 1.4;

  /// Koliko traje sam pokret jednog kucanja; ostatak vremena stoji.
  static const double _tickMove = 0.3;

  /// Ugao pogonskog zupčanika: pola zuba po kucanju, sa malim prebačajem
  /// na kraju pokreta — kao zaporni točak koji legne na mesto.
  static double _driverAngle(double s, int teeth) {
    final k = (s / _tickPeriod).floorToDouble();
    final f = ((s - k * _tickPeriod) / _tickMove).clamp(0.0, 1.0);
    final step = f >= 1 ? 1.0 : Curves.easeOutBack.transform(f);
    return (k + step) * math.pi / teeth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = AppGradients.background.createShader(rect),
    );

    final s = seconds.value;

    // Odsjaji: putanje su periodične po 2π, pa se krug zatvara bez skoka.
    final t = s / 24 * 2 * math.pi;
    _glow(
      canvas,
      size,
      Offset(0.5 + 0.35 * math.cos(t), 0.3 + 0.2 * math.sin(2 * t)),
      radius: size.longestSide * 0.6,
      strength: 0.55,
    );
    _glow(
      canvas,
      size,
      Offset(0.5 - 0.35 * math.cos(t + 1.3), 0.75 + 0.18 * math.sin(t)),
      radius: size.longestSide * 0.5,
      strength: 0.35,
    );

    if (_layoutSize != size) {
      _gears = _layout(size);
      _layoutSize = size;
    }
    if (_gears.isEmpty) return;

    final drive = _driverAngle(s, _gears.first.teeth);
    final fill = Paint()
      ..color = AppColors.accentDeep.withValues(alpha: 0.22);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.accent.withValues(alpha: 0.16);

    for (final gear in _gears) {
      final r = gear.pitchRadius;
      canvas
        ..save()
        ..translate(gear.center.dx, gear.center.dy)
        ..rotate(gear.phase + gear.ratio * drive)
        ..drawPath(gear.path, fill)
        ..drawPath(gear.path, stroke)
        // Venac, glavčina i osovina.
        ..drawCircle(Offset.zero, r * 0.72, stroke)
        ..drawCircle(Offset.zero, r * 0.26, stroke)
        ..drawCircle(Offset.zero, r * 0.08, fill);
      // Paoci između glavčine i venca — po njima se okretanje i vidi.
      for (var i = 0; i < gear.spokes; i++) {
        final a = i * 2 * math.pi / gear.spokes;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(dir * (r * 0.26), dir * (r * 0.72), stroke);
      }
      canvas.restore();
    }
  }

  /// Raspored zupčanika: jedan niz gore desno, drugi dole levo, delom van
  /// ekrana. Svaki sledeći je zakačen za prethodni — zubi upadaju tačno u
  /// međuzublje, pa se okreću u suprotnom smeru, srazmerno broju zuba.
  static List<_Gear> _layout(Size size) {
    if (size.isEmpty) return const [];
    final w = size.width;
    final h = size.height;
    final m = size.shortestSide * 0.013; // modul: veličina jednog zuba

    final gears = <_Gear>[];

    _Gear make(Offset center, int teeth, double phase, double ratio, int spokes) {
      final r = m * teeth / 2;
      return _Gear(
        center: center,
        pitchRadius: r,
        teeth: teeth,
        phase: phase,
        ratio: ratio,
        spokes: spokes,
        path: _gearPath(r, teeth, m),
      );
    }

    // Novi zupčanik zakačen za [parent], u pravcu [angle] od njegovog centra.
    _Gear mesh(_Gear parent, double angle, int teeth, int spokes) {
      final r = m * teeth / 2;
      // Mali zazor, kao kod pravih zupčanika — da se zubi ne dodiruju.
      final distance = parent.pitchRadius + r + 0.15 * m;
      final center = parent.center +
          Offset(math.cos(angle), math.sin(angle)) * distance;
      final k = parent.teeth / teeth;
      // Kad zub roditelja gleda ka detetu, dete mora da mu okrene
      // međuzublje.
      final c = angle + math.pi + math.pi / teeth + k * angle;
      return make(center, teeth, c - k * parent.phase, -k * parent.ratio, spokes);
    }

    final a = make(Offset(w * 0.98, h * 0.16), 30, 0, 1, 6);
    final b = mesh(a, 150 * math.pi / 180, 16, 5);
    final c = mesh(b, 215 * math.pi / 180, 10, 4);

    // Drugi niz ima svoj pogon, sporiji i u suprotnom smeru.
    final d = make(Offset(w * 0.02, h * 0.86), 36, 0.3, -0.7, 8);
    final e = mesh(d, -40 * math.pi / 180, 14, 5);
    final f = mesh(e, 20 * math.pi / 180, 20, 6);

    gears.addAll([a, b, c, d, e, f]);
    return gears;
  }

  /// Obris zupčanika sa [teeth] zuba oko (0, 0); prvi zub gleda udesno.
  static Path _gearPath(double pitchRadius, int teeth, double module) {
    final tip = pitchRadius + module;
    final root = pitchRadius - 1.25 * module;
    final period = 2 * math.pi / teeth;
    final halfRoot = 0.27 * period;
    final halfTip = 0.14 * period;

    Offset polar(double radius, double angle) =>
        Offset(math.cos(angle) * radius, math.sin(angle) * radius);

    final path = Path();
    for (var j = 0; j < teeth; j++) {
      final a = j * period;
      final p0 = polar(root, a - halfRoot);
      if (j == 0) {
        path.moveTo(p0.dx, p0.dy);
      } else {
        path.lineTo(p0.dx, p0.dy);
      }
      final p1 = polar(tip, a - halfTip);
      final p2 = polar(tip, a + halfTip);
      final p3 = polar(root, a + halfRoot);
      path
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy);
    }
    return path..close();
  }

  void _glow(
    Canvas canvas,
    Size size,
    Offset relative, {
    required double radius,
    required double strength,
  }) {
    final center = Offset(relative.dx * size.width, relative.dy * size.height);
    final shader = RadialGradient(
      colors: [
        AppColors.accentDeep.withValues(alpha: strength),
        AppColors.accentDeep.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.seconds != seconds;
}
