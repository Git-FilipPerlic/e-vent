import 'package:flutter/material.dart';

import '../../services/music_player_controller.dart';
import '../../theme/app_theme.dart';
import '../common/slide_switch.dart';

/// Red od četiri kontrole iznad plejliste.
///
/// **Bez natpisa i bez okvira** (okviri su otpali 26. septembra 2026) —
/// svaka se prepoznaje po ikonici, a red je time nizak i plejlista dobija
/// prostor:
///
/// 1. **Fade** — prekidač sa talasićima u kružiću, a uz njega **broj**:
///    koliko sekundi traje ulazak iz tišine (1 / 4 / 8)
/// 2. **God mode** — prekidač sa zvezdicama. Isključen: dodir na numeru je
///    odmah pušta. Uključen: dodir samo bira, a pušta se sa Ekrana 2
/// 3. **Ploča** — usporavanje zvuka kao na gramofonu (1.0 / 0.9 / 0.8 / 0.7)
/// 4. **Jačina** — slovo L / E / F, dodir vrti u krug (puno, pola, tiho)
/// 5. **Ekran 2** — ogromno dugme za puštanje; radi samo u God mode-u
///
/// Oba prekidača se menjaju **samo prevlačenjem** (`SlideSwitch`), da ih
/// okrznut prst ne prebaci usred programa.
class MusicControls extends StatelessWidget {
  const MusicControls({
    super.key,
    required this.fade,
    required this.onFadeChanged,
    required this.fadeLength,
    required this.onCycleFadeLength,
    required this.godMode,
    required this.onGodModeChanged,
    required this.volume,
    required this.onCycleVolume,
    required this.recordSpeed,
    required this.onCycleRecordSpeed,
    required this.cueEnabled,
    required this.onOpenCue,
    required this.onTapWithoutSlide,
  });

  final bool fade;
  final ValueChanged<bool> onFadeChanged;

  /// Koliko traje ulazak iz tišine. Broj se dodirom vrti u krug.
  final FadeLength fadeLength;
  final VoidCallback onCycleFadeLength;
  final bool godMode;
  final ValueChanged<bool> onGodModeChanged;
  final VolumeStep volume;
  final VoidCallback onCycleVolume;

  /// Brzina ploče — usporavanje zvuka kao na gramofonu.
  final RecordSpeed recordSpeed;
  final VoidCallback onCycleRecordSpeed;

  /// Ekran 2 je dostupan samo u God mode-u, kad je numera izabrana.
  final bool cueEnabled;

  /// Zove se i kad Ekran 2 nije dostupan — ekran tada objasni zašto.
  final VoidCallback onOpenCue;

  /// Prekidač je samo dodirnut, a ne prevučen — ekran objasni kako se menja.
  final VoidCallback onTapWithoutSlide;

  /// Visina reda. Bez okvira oko dugmadi red je niži nego ranije — prostor
  /// dobija plejlista, koja je ono zbog čega se ekran otvara.
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      // Šest kontrola na uskom telefonu sa uvećanim fontom ne staju u red.
      // Umesto da se nešto preliva ili seče, ceo red se srazmerno smanji —
      // svih šest ostaje vidljivo i na mestu na kom ih je prst naučio.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlideSwitch(
              value: fade,
              onChanged: onFadeChanged,
              label: 'Fade',
              icon: Icons.waves_rounded,
              onTapWithoutSlide: onTapWithoutSlide,
            ),
            _FadeLengthButton(
              length: fadeLength,
              enabled: fade,
              onTap: onCycleFadeLength,
            ),
            const SizedBox(width: AppSpacing.sm),
            SlideSwitch(
              value: godMode,
              onChanged: onGodModeChanged,
              label: 'God mode',
              icon: Icons.auto_awesome_rounded,
              onTapWithoutSlide: onTapWithoutSlide,
            ),
            const SizedBox(width: AppSpacing.sm),
            _RecordButton(speed: recordSpeed, onTap: onCycleRecordSpeed),
            _VolumeButton(volume: volume, onTap: onCycleVolume),
            _CueButton(enabled: cueEnabled, onTap: onOpenCue),
          ],
        ),
      ),
    );
  }
}

/// Dužina ulaska iz tišine: 1, 4 ili 8 sekundi. Dodir vrti broj u krug,
/// isto kao slovo za jačinu.
///
/// Kad je `Fade` isključen broj je utišan, jer tada ne radi ništa — ali se i
/// dalje dodiruje, da se dužina namesti unapred.
class _FadeLengthButton extends StatelessWidget {
  const _FadeLengthButton({
    required this.length,
    required this.enabled,
    required this.onTap,
  });

  final FadeLength length;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ulazak iz tišine: ${length.label} sekundi',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 40,
          height: MusicControls.height,
          child: Center(
            child: Text(
              length.label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jačina u tri stepenika. Slovo je u safirnoj boji kad je puna jačina, a u
/// boji upozorenja kad je stišano — stišan zvuk je stanje na koje treba
/// obratiti pažnju.
///
/// Bez okvira: slovo je dovoljno, a okvir je samo jeo visinu (odluka od
/// 26. septembra 2026).
class _VolumeButton extends StatelessWidget {
  const _VolumeButton({required this.volume, required this.onTap});

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
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: MusicControls.height,
          child: Center(
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
    );
  }
}

/// Brzina ploče: dodir je vrti u krug (1.0 → 0.9 → 0.8 → 0.7). Ikonica
/// ploče je u boji dok je zvuk usporen, da se na prvi pogled vidi da numera
/// ne ide normalnom brzinom.
class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.speed, required this.onTap});

  final RecordSpeed speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = speed.isSlowed ? AppColors.warning : AppColors.textSecondary;
    return Semantics(
      button: true,
      label: 'Brzina ploče: ${speed.label}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 44,
          height: MusicControls.height,
          // Ikonica i broj jedno ispod drugog na uvećanom fontu prerastu
          // visinu reda, pa se skupe umesto da se preliju.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.album_rounded, size: 20, color: color),
                Text(
                  speed.label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ulaz na Ekran 2. Safirna kad je dostupna, utišana kad nije.
class _CueButton extends StatelessWidget {
  const _CueButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Ekran 2',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: MusicControls.height,
          child: Icon(
            Icons.play_circle_rounded,
            size: 32,
            color: enabled ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
