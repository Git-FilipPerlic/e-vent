import 'dart:math' as math;

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

  /// Koliki je kvadrat velikog dugmeta.
  ///
  /// **Namerno ogroman — otprilike četiri petine ekrana.** Zamišljen je za
  /// voditelja koji drži mikrofon i ne gleda u telefon: dovoljno je da pipne
  /// bilo gde po sredini, ne mora da gađa malu metu.
  ///
  /// Visina je i dalje granica: na niskom ekranu, ili kad je sistemski font
  /// uvećan, dugme se smanji pre nego što sadržaj ispadne sa ekrana.
  double _playButtonSize(BoxConstraints constraints) {
    return math.min(constraints.maxWidth * 0.8, constraints.maxHeight * 0.62);
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Veliko dugme **uvek pušta** — nikad ne pauzira.
  ///
  /// Na nastupnom ekranu pauza ne postoji. Ovaj ekran ima jedno značenje:
  /// „pusti ono što je izabrano". Ako neko usred programa promaši dugme,
  /// najgore što može da se desi jeste da numera krene — a ne da muzika
  /// stane pred publikom. Iz ekrana se izlazi strelicom nazad, pauza stoji
  /// u traci uz spisak.
  Future<void> _onPlayPressed() async {
    final controller = widget.controller;
    final navigator = Navigator.of(context);

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
            child: ValueListenableBuilder<List<double>?>(
              valueListenable: controller.waveform,
              builder: (context, amplitudes, child) => EdgeProgressRing(
                progress: controller.progress,
                amplitudes: amplitudes,
                onSeekStart: controller.beginScrub,
                onSeekUpdate: controller.updateScrub,
                onSeekEnd: controller.endScrub,
                child: child,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    // Sadržaj se centrira dok ima mesta, a klizi kad ga nema —
                    // ništa ne sme da ispadne sa ekrana.
                    SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                // Sadržaj počinje **iza prstena**, ne preko njega: inače
                // naslov ulazi u talas i oba postanu nečitljiva.
                padding: const EdgeInsets.all(
                  EdgeProgressRing.inset +
                      EdgeProgressRing.waveHeight +
                      AppSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Naslov se pretapa pri prelasku na sledeću numeru:
                    // naglo prebacivanje teksta se ne primeti, a pretapanje
                    // kaže da se nešto promenilo. Ostatak ekrana miruje.
                    _FadingTitle(
                      text:
                          track?.displayTitle ??
                          'Nijedna numera nije izabrana',
                      // Manje i blaže nego ranije: naslov je podatak koji se
                      // proveri jednom, a ne ono što se gleda tokom nastupa.
                      // Krupno belo na crnom je usput i štipalo oči.
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _playButton(theme, controller, _playButtonSize(constraints)),
                    const SizedBox(height: AppSpacing.md),
                    _skips(controller),
                    const SizedBox(height: AppSpacing.lg),
                    _fadeSwitch(theme, controller),
                  ],
                ),
                        ),
                      ),
                    ),
                    // Dugme za nazad stoji u uglu, van sadržaja koji klizi.
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Nazad na spisak',
                      ),
                    ),
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

  Widget _playButton(
    ThemeData theme,
    MusicPlayerController controller,
    double size,
  ) {
    if (controller.isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final error = controller.errorMessage;
    if (error != null) {
      return SizedBox(
        width: size,
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

    // **Šuplje dugme:** obojena je samo ikonica, a kvadrat je obeležen
    // linijom. Puna tirkizna površina preko četiri petine ekrana svetli kao
    // lampa i vidi se iz publike — a ovaj ekran se otvara usred programa, u
    // mraku. Linija i dalje kaže dokle se sme pipnuti, dok se meta ne nauči
    // napamet; ceo kvadrat je dodirljiv, ne samo ikonica.
    return Semantics(
      button: true,
      label: 'Pusti',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          // Kvadrat, ne krug: iz istog prostora se dobija veća meta, a
          // uglovi su blago zaobljeni da ne seku ekran.
          borderRadius: BorderRadius.circular(kCardRadius * 2),
          border: Border.all(color: AppColors.accentDeep, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kCardRadius * 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(kCardRadius * 2),
            onTap: _onPlayPressed,
            child: Icon(
              // Nikad pauza: ovaj ekran samo pušta.
              Icons.play_arrow_rounded,
              size: size * 0.55,
              color: AppColors.accent,
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

/// Naslov koji se **pretopi** kad se pređe na drugu numeru.
///
/// Traje 200 ms, koliko i piše u pravilima za pokret: animira se samo ono što
/// nosi informaciju. Ovde je informacija baš to da se numera promenila.
class _FadingTitle extends StatelessWidget {
  const _FadingTitle({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: Text(
        text,
        // Ključ po tekstu: bez njega se pretapanje ne bi ni okinulo.
        key: ValueKey(text),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
