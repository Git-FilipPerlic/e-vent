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

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
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
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.cinnamon,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (paused)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.peachStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Pauza',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.cinnamon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  title ?? 'Ništa ne svira',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasTrack
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, value, _) => LinearProgressIndicator(
                value: hasTrack ? value : 0,
                minHeight: 6,
                color: AppColors.accent,
                backgroundColor: AppColors.peachStrong,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(elapsed, style: _timeStyle(theme)),
              const Spacer(),
              Text(remaining, style: _timeStyle(theme)),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle? _timeStyle(ThemeData theme) => theme.textTheme.bodySmall?.copyWith(
    color: AppColors.cinnamon,
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
            width: 52,
            height: 52,
            child: Icon(
              showPause ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 30,
              color: enabled ? AppColors.onAccent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
