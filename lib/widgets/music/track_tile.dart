import 'package:flutter/material.dart';

import '../../models/track.dart';
import '../../theme/app_theme.dart';

/// Jedan red u spisku numera.
///
/// **Namerno je zbijen** — jedan red od 36 dp, bez kartice i bez razmaka oko
/// sebe. Na nastupu se pesma traži u spisku od nekoliko desetina numera, pa
/// je gustina važnija od prostora.
///
/// **Svesno odstupanje od pravila:** 36 dp je ispod minimalne dodirne mete od
/// 48 dp iz `CLAUDE.md`. Korisnik je tako tražio, da bi na ekran stalo više
/// numera; red je i dalje preko cele širine ekrana, pa je meta široka i pored
/// manje visine.
///
/// Da bi sve stalo u jedan red, **izvor se vidi po ikonici** (folder ili
/// plejlista) umesto po tekstu, a izvođač ide uz naziv kad ima mesta.
///
/// **Dodir ne pušta muziku** — samo bira numeru. Reprodukcija kreće tek u
/// plejeru, velikim dugmetom. Tako se ne desi da usred programa krene pogrešna
/// pesma zato što je prst okrznuo ekran.
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

  /// Visina jednog reda.
  static const double height = 36;

  /// `3:24` — trajanje numere; `--:--` dok se ne pročita iz fajla.
  static String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Izvor se prepoznaje po ikonici, jer za tekst nema mesta u zbijenom redu.
  static IconData iconForSource(TrackSource source) {
    return source == TrackSource.playlist
        ? Icons.queue_music_rounded
        : Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? AppColors.surfaceAlt : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Tooltip(
                message: track.source.label,
                child: Icon(
                  isSelected
                      ? Icons.graphic_eq_rounded
                      : iconForSource(track.source),
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  track.hasArtist
                      ? '${track.displayTitle} · ${track.artist}'
                      : track.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatDuration(track.duration),
                style: theme.textTheme.bodySmall?.copyWith(
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
