import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Neonski sjaj koji diše (proba): oko deteta se crta sjaj u boji `accent`
/// koji se polako pojačava i stišava.
///
/// Kad [active] nije uključen, sjaja nema. Uz sistemski „smanjen pokret"
/// sjaj ostaje, ali miruje na pola jačine.
class NeonGlow extends StatefulWidget {
  const NeonGlow({
    super.key,
    required this.child,
    this.active = true,
    this.circle = false,
    this.borderRadius = 0,
    this.intensity = 1,
    this.period = const Duration(milliseconds: 1600),
  });

  final Widget child;

  /// Da li sjaj uopšte postoji.
  final bool active;

  /// Krug umesto zaobljenog pravougaonika.
  final bool circle;

  /// Zaobljenje uglova, kad nije krug.
  final double borderRadius;

  /// Koliko je sjaj jak: 1 je obično, više je upadljivije.
  final double intensity;

  /// Jedan udah i izdah.
  final Duration period;

  @override
  State<NeonGlow> createState() => _NeonGlowState();
}

class _NeonGlowState extends State<NeonGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(NeonGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period;
    }
    _sync();
  }

  void _sync() {
    if (widget.active && !_reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _reduceMotion
            ? 0.5
            : Curves.easeInOut.transform(_controller.value);
        final k = widget.intensity;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              // Širok, mek oblak.
              BoxShadow(
                color: AppColors.accent.withValues(
                  alpha: ((0.18 + 0.27 * t) * k).clamp(0, 1),
                ),
                blurRadius: (14 + 18 * t) * k,
                spreadRadius: 2 * t * k,
              ),
              // Uzak, jak rub uz samu ivicu — to oko čita kao neon.
              BoxShadow(
                color: AppColors.accent.withValues(
                  alpha: ((0.35 + 0.3 * t) * k).clamp(0, 1),
                ),
                blurRadius: 4 + 4 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
