import 'package:flutter/material.dart';

import '../../services/music_player_controller.dart';
import '../../theme/app_theme.dart';
import 'track_tile.dart';

/// Kontrole uz sam spisak numera: naziv trenutne numere, preskakanje po
/// 10 sekundi, puštanje i pauza, i prelaz na sledeću.
///
/// Ovo je **prvi nivo** — dovoljno da se upravlja bez napuštanja spiska.
/// Drugi nivo je nastupni ekran, sa ogromnim dugmetom i prstenom; do njega
/// vodi `onOpenPlayer`.
///
/// Widget je "glup": prima kontroler i prikazuje njegovo stanje.
class PlaybackBar extends StatelessWidget {
  const PlaybackBar({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
    required this.onBrowse,
  });

  final MusicPlayerController controller;
  final VoidCallback onOpenPlayer;

  /// Otvara pregled fajlova. Stoji kao **sama ikonica foldera**, bez natpisa.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = controller.selected;
    if (track == null) return const SizedBox.shrink();

    final ready = controller.isReady;
    final error = controller.errorMessage;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    // Naslov se pretapa pri prelasku na drugu numeru — inače
                    // se promena ne primeti.
                    child: AnimatedSwitcher(
                      duration: MediaQuery.of(context).disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      child: Text(
                        track.displayTitle,
                        key: ValueKey(track.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: error == null
                              ? AppColors.textPrimary
                              : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${TrackTile.formatDuration(controller.position)}'
                    ' / ${TrackTile.formatDuration(controller.duration)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (controller.isAnotherSounding)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      // Izabrana numera čeka na dugme, a čuje se druga.
                      'svira: ${controller.sounding!.displayTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BarButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Prethodna numera',
                    onPressed: ready ? controller.previous : null,
                  ),
                  _BarButton(
                    icon: Icons.replay_10_rounded,
                    label: '10 sekundi unazad',
                    onPressed: ready
                        ? () => controller.skip(const Duration(seconds: -10))
                        : null,
                  ),
                  _BarButton(
                    icon: controller.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    label: controller.isPlaying ? 'Pauza' : 'Pusti',
                    size: 44,
                    onPressed: ready ? controller.toggle : null,
                  ),
                  _BarButton(
                    icon: Icons.forward_10_rounded,
                    label: '10 sekundi unapred',
                    onPressed: ready
                        ? () => controller.skip(const Duration(seconds: 10))
                        : null,
                  ),
                  _BarButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Sledeća numera',
                    onPressed: ready && controller.hasNext
                        ? controller.next
                        : null,
                  ),
                ],
              ),
              // Drugi red: fajlovi, ulaz u nastupni ekran i jačina zvuka.
              //
              // Odvojen je namerno. Gornji red je premotavanje i pauza — ono
              // što se dira u hodu; ovde su odluke druge vrste. Red je
              // **niži od gornjeg**, jer se ova tri dugmeta ne traže u žurbi,
              // a spisak numera time dobija prostor.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BarButton(
                    icon: Icons.folder_open_rounded,
                    label: 'Pregledaj fajlove',
                    size: 26,
                    height: _shortRow,
                    onPressed: onBrowse,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _BarButton(
                    icon: Icons.open_in_full_rounded,
                    label: 'Otvori nastupni ekran',
                    size: 26,
                    height: _shortRow,
                    onPressed: onOpenPlayer,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Jačina: jedno slovo koje se vrti L → E → F. Tri
                  // stepenika umesto klizača — na nastupu se ne pogađa
                  // procenat, nego se bira „puno / pola / tiho".
                  _VolumeButton(controller: controller),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visina donjeg reda. Namerno ispod 48 dp — ova tri dugmeta se ne traže u
/// žurbi, a red preko cele širine ostaje lako pogodljiv. Isti izuzetak kao
/// kod spiska numera, opisan u `CLAUDE.md`.
const double _shortRow = 36;

/// Jačina zvuka, jednim slovom.
class _VolumeButton extends StatelessWidget {
  const _VolumeButton({required this.controller});

  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final step = controller.volume;
    final isFull = step == VolumeStep.l;

    return Semantics(
      button: true,
      label: 'Jačina zvuka: ${step.label}',
      child: Tooltip(
        message: 'Jačina zvuka',
        child: InkResponse(
          onTap: controller.cycleVolume,
          radius: kMinTouchTarget / 2,
          child: SizedBox(
            width: kMinTouchTarget,
            height: _shortRow,
            child: Center(
              child: Text(
                step.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  // Stišano je stanje na koje treba obratiti pažnju, pa je
                  // slovo tada u boji upozorenja.
                  color: isFull ? AppColors.accent : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jedno dugme u traci.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 28,
    this.height,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  /// Visina dodirne mete. `null` znači uobičajenih 48 dp.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: size,
        tooltip: label,
        color: AppColors.accent,
        disabledColor: AppColors.border,
        padding: EdgeInsets.zero,
        constraints: height == null
            ? null
            : BoxConstraints(
                minWidth: kMinTouchTarget,
                minHeight: height!,
              ),
      ),
    );
  }
}
