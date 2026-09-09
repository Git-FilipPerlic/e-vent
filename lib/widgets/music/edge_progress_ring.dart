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
/// **Za performanse:** prerisavanje okida [progress] kao `Listenable`, bez
/// ponovnog građenja widget stabla; putanja se gradi jednom po veličini
/// ekrana, a ceo prsten stoji u `RepaintBoundary`.
///
/// Talasni oblik pesme (amplitude) dolazi u kasnijoj fazi — dok ga nema,
/// crta se ravna linija, nikad prazan ekran.
class EdgeProgressRing extends StatelessWidget {
  const EdgeProgressRing({super.key, required this.progress, this.child});

  /// Dokle je stigla reprodukcija, 0..1.
  final ValueListenable<double> progress;

  /// Sadržaj koji stoji unutar prstena (vreme, dugme za puštanje).
  final Widget? child;

  /// Koliko je linija uvučena od same ivice ekrana.
  static const double inset = 10;

  /// Debljina linije.
  static const double strokeWidth = 4;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _EdgeRingPainter(progress: progress),
        child: child,
      ),
    );
  }
}

class _EdgeRingPainter extends CustomPainter {
  _EdgeRingPainter({required this.progress}) : super(repaint: progress);

  final ValueListenable<double> progress;

  /// Putanja se gradi jednom po veličini ekrana, ne po kadru.
  ui.Path? _cachedPath;
  Size? _cachedSize;
  double _cachedLength = 0;

  ui.Path _pathFor(Size size) {
    if (_cachedPath != null && _cachedSize == size) return _cachedPath!;

    final rect = Rect.fromLTWH(
      EdgeProgressRing.inset,
      EdgeProgressRing.inset,
      size.width - EdgeProgressRing.inset * 2,
      size.height - EdgeProgressRing.inset * 2,
    );

    // Putanja kreće iz gornjeg levog ugla i ide u smeru kazaljke na satu.
    final path = ui.Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(kCardRadius * 2)),
      );

    _cachedPath = path;
    _cachedSize = size;
    _cachedLength = path
        .computeMetrics()
        .fold<double>(0, (sum, metric) => sum + metric.length);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _pathFor(size);
    final value = progress.value.clamp(0.0, 1.0);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = EdgeProgressRing.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accentDeep;

    // Nepređeni deo: vidljiv, ali povučen.
    canvas.drawPath(path, basePaint);

    if (value <= 0) return;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final travelled = ui.Path();
    var remaining = _cachedLength * value;
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
    final head = _pointAt(metrics, _cachedLength * value);
    if (head != null) {
      canvas.drawCircle(
        head,
        EdgeProgressRing.strokeWidth * 1.6,
        Paint()..color = AppColors.accent,
      );
    }
  }

  /// Gde se na putanji nalazi data dužina.
  Offset? _pointAt(List<ui.PathMetric> metrics, double distance) {
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
    return oldDelegate.progress != progress;
  }
}
