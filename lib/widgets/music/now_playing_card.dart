import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Kartica „Sada svira" na vrhu Muzika taba.
///
/// Nežna breskva kao podloga, naziv numere krupno, okruglo safirno dugme
/// za pauzu i traka napretka ispod. Ovo je naslednik LCD displeja iz
/// starog iTunes-a: jednim pogledom se vidi šta svira i koliko je ostalo.
class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({
    super.key,
    required this.title,
    required this.isPlaying,
    required this.progress,
    required this.elapsed,
    required this.remaining,
    required this.onTogglePause,
    this.cueTitle,
  });

  /// Naziv numere koja svira; `null` kad ništa ne svira.
  final String? title;

  /// Da li se numera trenutno čuje (`false` = pauza).
  final bool isPlaying;

  /// Napredak 0..1. Stoji van widget stabla, da se traka pomera bez
  /// ponovnog građenja cele kartice.
  final ValueListenable<double> progress;

  final String elapsed;
  final String remaining;

  /// `null` kad nema šta da se pauzira — dugme je tada utišano.
  final VoidCallback? onTogglePause;

  /// Numera spremljena za Ekran 2 u God mode-u.
  final String? cueTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTrack = title != null;
    final paused = hasTrack && !isPlaying;

    // Kartica ima **istu visinu u svakom stanju**. Ranije je „Pauza" bila
    // pilula koja se pojavljuje i nestaje, pa je kartica rasla i skupljala
    // se, a spisak numera ispod nje poskakivao — na nastupu se tako gubi red
    // koji se gledao. Sada je to obična reč u redu koji uvek stoji.
    //
    // Uvećanje sistemskog fonta je ograničeno kao kod sistemskih birača
    // datuma: bez toga kartica na krupnom fontu pojede četvrtinu ekrana,
    // a plejlista je ono zbog čega se ekran otvara.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.peach,
          borderRadius: BorderRadius.circular(kLargeRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cueTitle != null
                        ? 'SLEDEĆA: ${cueTitle!.toUpperCase()}'
                        : (hasTrack ? 'SADA SVIRA' : 'PLEJLISTA'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _labelStyle(theme),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(paused ? 'PAUZA' : '', style: _labelStyle(theme)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? 'Ništa ne svira',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasTrack
                          ? AppColors.onPeach
                          : AppColors.onPeachMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _PauseButton(
                  showPause: hasTrack && isPlaying,
                  onPressed: onTogglePause,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: hasTrack ? value : 0,
                  minHeight: 5,
                  color: AppColors.accent,
                  backgroundColor: AppColors.peachStrong,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(elapsed, style: _timeStyle(theme)),
                const Spacer(),
                Text(remaining, style: _timeStyle(theme)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(ThemeData theme) =>
      theme.textTheme.labelMedium?.copyWith(
        color: AppColors.onPeachLabel,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      );

  TextStyle? _timeStyle(ThemeData theme) => theme.textTheme.bodySmall?.copyWith(
    color: AppColors.onPeachLabel,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Okruglo safirno dugme za pauzu i nastavak.
class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.showPause, required this.onPressed});

  final bool showPause;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: showPause ? 'Pauza' : 'Nastavi',
      excludeSemantics: true,
      child: Material(
        color: enabled ? AppColors.accent : AppColors.switchOff,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              showPause ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 26,
              color: enabled ? AppColors.onAccent : AppColors.onPeachMuted,
            ),
          ),
        ),
      ),
    );
  }
}
