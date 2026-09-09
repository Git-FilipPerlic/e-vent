import 'package:flutter/material.dart';

import '../../models/track.dart';
import '../../theme/app_theme.dart';

/// Jedan red u spisku numera.
///
/// **Dodir ne pušta muziku** — samo bira numeru. Reprodukcija kreće tek u
/// plejeru, velikim dugmetom. Tako se ne desi da usred programa krene pogrešna
/// pesma zato što je prst okrznuo ekran.
///
/// Widget je "glup": prima numeru i stanje izbora kroz konstruktor.
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.isSelected,
    required this.onTap,
  });

  final Track track;
  final bool isSelected;
  final VoidCallback onTap;

  /// `3:24` — trajanje numere; `--:--` dok se ne pročita iz fajla.
  static String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isSelected ? AppColors.surfaceAlt : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.graphic_eq_rounded
                    : Icons.audiotrack_rounded,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Izvor uvek stoji uz numeru: u žurbi se lako pomeša
                      // pesma iz telefona sa pesmom iz plejliste za nastup.
                      track.hasArtist
                          ? '${track.artist} · ${track.source.label}'
                          : track.source.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatDuration(track.duration),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
