import 'package:flutter/material.dart';

import '../../services/music_player_controller.dart';
import '../../theme/app_theme.dart';
import '../common/slide_switch.dart';

/// Red od četiri niske kartice iznad plejliste (od 25. septembra 2026).
///
/// **Bez natpisa** — svaka kartica se prepoznaje po ikonici, da bi red bio
/// nizak i da plejlista dobije prostor:
///
/// 1. **Fade** — prekidač sa talasićima u kružiću
/// 2. **God mode** — prekidač sa zvezdicama. Isključen: dodir na numeru je
///    odmah pušta. Uključen: dodir samo bira, a pušta se sa Ekrana 2
/// 3. **Jačina** — slovo L / E / F, dodir vrti u krug (puno, pola, tiho)
/// 4. **Ekran 2** — ogromno dugme za puštanje; radi samo u God mode-u
///
/// Oba prekidača se menjaju **samo prevlačenjem** (`SlideSwitch`), da ih
/// okrznut prst ne prebaci usred programa.
class MusicControls extends StatelessWidget {
  const MusicControls({
    super.key,
    required this.fade,
    required this.onFadeChanged,
    required this.godMode,
    required this.onGodModeChanged,
    required this.volume,
    required this.onCycleVolume,
    required this.cueEnabled,
    required this.onOpenCue,
    required this.onTapWithoutSlide,
  });

  final bool fade;
  final ValueChanged<bool> onFadeChanged;
  final bool godMode;
  final ValueChanged<bool> onGodModeChanged;
  final VolumeStep volume;
  final VoidCallback onCycleVolume;

  /// Ekran 2 je dostupan samo u God mode-u, kad je numera izabrana.
  final bool cueEnabled;

  /// Zove se i kad Ekran 2 nije dostupan — ekran tada objasni zašto.
  final VoidCallback onOpenCue;

  /// Prekidač je samo dodirnut, a ne prevučen — ekran objasni kako se menja.
  final VoidCallback onTapWithoutSlide;

  /// Visina kartica — namerno niska.
  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _Tile(
              child: SlideSwitch(
                value: fade,
                onChanged: onFadeChanged,
                label: 'Fade',
                icon: Icons.waves_rounded,
                onTapWithoutSlide: onTapWithoutSlide,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: _Tile(
              child: SlideSwitch(
                value: godMode,
                onChanged: onGodModeChanged,
                label: 'God mode',
                icon: Icons.auto_awesome_rounded,
                onTapWithoutSlide: onTapWithoutSlide,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _VolumeTile(volume: volume, onTap: onCycleVolume),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _CueTile(enabled: cueEnabled, onTap: onOpenCue),
          ),
        ],
      ),
    );
  }
}

/// Bela zaobljena kartica sa blagom senkom.
class _Tile extends StatelessWidget {
  const _Tile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kSoftShadow,
      ),
      alignment: Alignment.center,
      // Na uskom telefonu se sadržaj skuplja umesto da se prelije.
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}

/// Jačina u tri stepenika. Slovo je u safirnoj boji kad je puna jačina, a
/// u boji upozorenja na breskvi kad je stišano — stišan zvuk je stanje na
/// koje treba obratiti pažnju.
class _VolumeTile extends StatelessWidget {
  const _VolumeTile({required this.volume, required this.onTap});

  final VolumeStep volume;
  final VoidCallback onTap;

  static const Map<VolumeStep, String> _spoken = {
    VolumeStep.l: 'puna',
    VolumeStep.e: 'pola',
    VolumeStep.f: 'tiho',
  };

  @override
  Widget build(BuildContext context) {
    final reduced = volume != VolumeStep.l;
    return Semantics(
      button: true,
      label: 'Jačina: ${_spoken[volume]}',
      excludeSemantics: true,
      child: Material(
        color: reduced ? AppColors.peach : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                volume.label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: reduced ? AppColors.warning : AppColors.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ulaz na Ekran 2. Safirna kad je dostupna, utišana kad nije.
class _CueTile extends StatelessWidget {
  const _CueTile({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Ekran 2',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled ? kAccentShadow : kSoftShadow,
        ),
        child: Material(
          color: enabled ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Center(
              child: Icon(
                Icons.play_circle_rounded,
                size: 30,
                color: enabled ? AppColors.onAccent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
