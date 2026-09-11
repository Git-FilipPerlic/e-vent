import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Pozadina u pokretu (proba): preko pozadinskog gradijenta polako plutaju
/// dva topla odsjaja.
///
/// Crta se kroz [CustomPainter] vezan za kontroler, pa se pri svakom kadru
/// samo preslika pozadina — stablo widgeta iznad nje se ne gradi ponovo.
/// Uz sistemski „smanjen pokret" pozadina stoji.
class AnimatedBackdrop extends StatefulWidget {
  const AnimatedBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  /// Jedan pun krug odsjaja. Sporo namerno — pokret se oseti, ne gleda.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _BackdropPainter(_controller)),
        ),
        widget.child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = AppGradients.background.createShader(rect),
    );

    // Putanje su periodične po 2π, pa se krug zatvara bez skoka.
    final t = progress.value * 2 * math.pi;
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
      oldDelegate.progress != progress;
}
