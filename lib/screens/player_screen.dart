import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/music_player_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/music/edge_progress_ring.dart';
import '../widgets/music/track_tile.dart';

/// Nastupni ekran — drugi nivo plejera.
///
/// Na njemu je samo ono što treba u trenutku izvođenja: prsten po ivici
/// ekrana, vreme, **ogromno dugme** i **jedan prekidač za pretapanje**.
/// Kontroler se **pozajmljuje** iz Muzika taba, pa zvuk ne prestaje kad se
/// odavde izađe nazad na spisak.
///
/// Dugme je namerno preveliko: traži se prstom, u mraku, bez gledanja u ekran.
///
/// Kad nešto svira a izabrana je druga numera, veliko dugme **prelazi na
/// izabranu**: uz pretapanje obe sviraju u preklopu — jedna izlazi, druga
/// ulazi — a bez pretapanja prelaz je odmah.
///
/// **Veliko dugme pusti numeru i odmah vrati na spisak.** Tako radi nastup:
/// pesma krene, a ruke su ti već slobodne da pripremiš sledeću. Nazad se
/// ulazi dugmetom kad treba pogledati prsten ili pauzirati.
///
/// **Gornja linija prstena ne ide uz samu ivicu ekrana**, nego ispod mesta gde
/// stoji header — inače bi premotavanje prevlačenjem padalo u pojas kojim se
/// otvara sistemska zavesa. Uz to ekran radi bez sistemskih traka, kao druga
/// brana: prvo povlačenje ih samo nakratko prikaže.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.controller});

  final MusicPlayerController controller;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// Koliko se preskače jednim dodirom.
  static const Duration skipStep = Duration(seconds: 10);

  /// Prečnik velikog dugmeta. Namerno ogroman — pogađa se bez gledanja.
  static const double _playButtonSize = 200;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Puštanje vraća na spisak; pauza ostavlja ekran otvorenim.
  Future<void> _onPlayPressed() async {
    final controller = widget.controller;
    final navigator = Navigator.of(context);

    if (controller.isPlaying) {
      await controller.toggle();
      return;
    }

    await controller.play();
    if (!mounted) return;
    navigator.pop();
  }

  @override
  void dispose() {
    // Trake se vraćaju čim se izađe. Kontroler se **ne gasi** — on pripada
    // Muzika tabu, pa muzika ide dalje i posle povratka na spisak.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final track = controller.selected;

          return SafeArea(
            child: EdgeProgressRing(
              progress: controller.progress,
              onSeekStart: controller.beginScrub,
              onSeekUpdate: controller.updateScrub,
              onSeekEnd: controller.endScrub,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Nazad na spisak',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      track?.displayTitle ?? 'Nijedna numera nije izabrana',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Kad svira jedna numera a izabrana je druga, mora da se
                    // vidi šta se čuje a šta čeka na dugme.
                    if (controller.isAnotherSounding) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'svira: ${controller.sounding!.displayTitle}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    // Vreme se ne animira — brojka koja treperi svake sekunde
                    // smeta.
                    Text(
                      '${TrackTile.formatDuration(controller.position)}'
                      ' / ${TrackTile.formatDuration(controller.duration)}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _playButton(theme, controller),
                    const SizedBox(height: AppSpacing.md),
                    _skips(controller),
                    const SizedBox(height: AppSpacing.lg),
                    _fadeSwitch(theme, controller),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Preskakanje po 10 sekundi — ispod velikog dugmeta, da mu ne otimaju
  /// prostor.
  Widget _skips(MusicPlayerController controller) {
    final ready = controller.isReady;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SkipButton(
          icon: Icons.replay_10_rounded,
          label: '10 sekundi unazad',
          onPressed: ready ? () => controller.skip(-skipStep) : null,
        ),
        const SizedBox(width: AppSpacing.xl),
        _SkipButton(
          icon: Icons.forward_10_rounded,
          label: '10 sekundi unapred',
          onPressed: ready ? () => controller.skip(skipStep) : null,
        ),
      ],
    );
  }

  Widget _playButton(ThemeData theme, MusicPlayerController controller) {
    if (controller.isLoading) {
      return const SizedBox(
        width: _playButtonSize,
        height: _playButtonSize,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = controller.errorMessage;
    if (error != null) {
      return SizedBox(
        width: _playButtonSize,
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      );
    }

    // Puna tirkizna podloga i tamna ikonica: dugme mora da se vidi iz ruke,
    // u mraku, bez traženja.
    return Semantics(
      button: true,
      label: controller.isPlaying ? 'Pauza' : 'Pusti',
      child: Container(
        width: _playButtonSize,
        height: _playButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDeep,
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _onPlayPressed,
            child: Icon(
              controller.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: _playButtonSize * 0.55,
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }

  /// Jedan prekidač umesto tri: na nastupu se ne bira između tri opcije.
  ///
  /// Uključen znači i ulazak iz tišine, i izlazak u tišinu, i **preklapanje**
  /// sa numerom koja svira kad se pređe na izabranu.
  Widget _fadeSwitch(ThemeData theme, MusicPlayerController controller) {
    return _FadeToggle(
      label: 'Fade',
      value: controller.fade,
      onChanged: controller.setFade,
    );
  }
}

/// Prekidač za pretapanje zvuka, sa natpisom u istom redu.
class _FadeToggle extends StatelessWidget {
  const _FadeToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      toggled: value,
      label: label,
      child: InkWell(
        // I natpis se dodiruje, ne samo prekidač — meta je time šira.
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: value
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dugme za preskakanje 10 sekundi. Manje od velikog, ali i dalje puna
/// dodirna meta.
class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;

  /// `null` dok numera nije spremna — dugme tada stoji ugašeno.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 40,
        tooltip: label,
        color: AppColors.accent,
        disabledColor: AppColors.border,
      ),
    );
  }
}
