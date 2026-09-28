import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Prekidač koji se menja **samo prevlačenjem**, ne dodirom.
///
/// Zamisao (dogovoreno 25. septembra 2026): prekidač mora da bude lep,
/// pametan i intuitivan, a da se **ne prebaci slučajno** kad izvođač radi
/// brzo. Okrznut prst ga ne menja; kružić mora da se prevuče na drugu
/// stranu, kao „prevuci za otključavanje" na telefonu.
///
/// Običan dodir poziva [onTapWithoutSlide] — ekran tada kaže da prekidač
/// treba prevući, da korisnik ne pomisli da je pokvaren.
///
/// Za čitač ekrana prekidač radi i dvostrukim dodirom: tamo je svaki pokret
/// nameran, pa zaštita od okrznutog prsta nije potrebna.
class SlideSwitch extends StatefulWidget {
  const SlideSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.icon,
    this.onTapWithoutSlide,
    this.width = 60,
    this.height = 36,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Naziv za čitač ekrana (na samom prekidaču nema teksta).
  final String label;

  /// Ikonica u kružiću — kaže šta prekidač radi, bez slova.
  final IconData? icon;

  final VoidCallback? onTapWithoutSlide;
  final double width;
  final double height;

  @override
  State<SlideSwitch> createState() => _SlideSwitchState();
}

class _SlideSwitchState extends State<SlideSwitch> {
  static const double _pad = 3;

  /// Položaj kružića dok ga prst vuče; `null` kad prst nije na prekidaču.
  double? _drag;

  double get _knob => widget.height - _pad * 2;
  double get _travel => widget.width - _pad * 2 - _knob;
  double get _rest => widget.value ? _travel : 0;

  void _onDragEnd() {
    final x = _drag ?? _rest;
    final on = x > _travel / 2;
    setState(() => _drag = null);
    if (on != widget.value) {
      HapticFeedback.selectionClick();
      widget.onChanged(on);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final x = (_drag ?? _rest).clamp(0.0, _travel);
    final lit = _drag != null ? x > _travel / 2 : widget.value;
    final dragging = _drag != null;

    return Semantics(
      label: widget.label,
      toggled: widget.value,
      onTap: () => widget.onChanged(!widget.value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTapWithoutSlide,
        onHorizontalDragStart: (_) => setState(() => _drag = _rest),
        onHorizontalDragUpdate: (details) => setState(() {
          _drag = ((_drag ?? _rest) + details.delta.dx).clamp(0.0, _travel);
        }),
        onHorizontalDragEnd: (_) => _onDragEnd(),
        onHorizontalDragCancel: () => setState(() => _drag = null),
        // Dodirna meta je bar 48 dp visoka, i kad je sam prekidač niži.
        child: SizedBox(
          width: widget.width,
          height: widget.height < kMinTouchTarget
              ? kMinTouchTarget
              : widget.height,
          child: Center(
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: lit ? AppColors.accent : AppColors.switchOff,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: dragging || reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    left: _pad + x,
                    top: _pad,
                    child: Container(
                      width: _knob,
                      height: _knob,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: kKnobShadow,
                      ),
                      child: widget.icon == null
                          ? null
                          : Icon(
                              widget.icon,
                              size: _knob * 0.56,
                              color: lit
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
