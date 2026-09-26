import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/track.dart';
import '../services/music_player_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common/slide_switch.dart';

/// **Ekran 2** — samo ogromno dugme za puštanje i veliki prekidač Fade in.
///
/// Do njega se stiže iz God mode-a: na spisku se numera dodirom samo
/// izabere, a ovde se pusti. Ništa drugo na ekranu ne postoji — dugme je
/// krug preko skoro cele širine, da voditelj koji drži mikrofon može da ga
/// pipne bez gledanja.
///
/// Fade in ovde važi **samo za ovo jedno puštanje**; opšti prekidač Fade na
/// spisku se ne menja. Na početku stoji kako je podešen opšti.
///
/// Posle puštanja ekran se sam zatvara, pa su ruke slobodne da se na spisku
/// spremi sledeća numera.
class CueScreen extends StatefulWidget {
  const CueScreen({
    super.key,
    required this.controller,
    required this.track,
    required this.initialFade,
  });

  final MusicPlayerController controller;

  /// Numera koja će se pustiti.
  final Track track;

  final bool initialFade;

  @override
  State<CueScreen> createState() => _CueScreenState();
}

class _CueScreenState extends State<CueScreen> {
  late bool _fade = widget.initialFade;
  bool _starting = false;

  Future<void> _play() async {
    if (_starting) return;
    _starting = true;
    HapticFeedback.mediumImpact();
    await widget.controller.playNow(widget.track, fade: _fade);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _slideHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Prevuci prekidač — dodir ga ne menja')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sounding = widget.controller.sounding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _BackPill(onTap: () => Navigator.of(context).pop()),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLEDEĆA',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.cinnamon,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.track.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sounding == null
                          ? 'Trenutno ništa ne svira'
                          : 'Sada svira: ${sounding.displayTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side =
                        (constraints.maxWidth < constraints.maxHeight
                                ? constraints.maxWidth
                                : constraints.maxHeight) -
                            AppSpacing.lg;
                    final size = side.clamp(96.0, 360.0);
                    return Center(
                      child: _GiantPlayButton(size: size, onTap: _play),
                    );
                  },
                ),
              ),
              _FadeCard(
                value: _fade,
                onChanged: (value) => setState(() => _fade = value),
                onTapWithoutSlide: _slideHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dugme „nazad" u obliku pilule.
class _BackPill extends StatelessWidget {
  const _BackPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(),
      shadowColor: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 18, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left_rounded, color: AppColors.accent),
              Text(
                'Plejlista',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ogromno okruglo dugme. Ceo krug je dodirljiv, ne samo trougao.
class _GiantPlayButton extends StatelessWidget {
  const _GiantPlayButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pusti izabranu numeru',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.playButton,
          boxShadow: kAccentShadow,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              // Trougao je malo pomeren udesno, da optički stoji u sredini.
              child: Padding(
                padding: EdgeInsets.only(left: size * 0.06),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: size * 0.5,
                  color: AppColors.onAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Velika kartica sa prekidačem Fade in.
class _FadeCard extends StatelessWidget {
  const _FadeCard({
    required this.value,
    required this.onChanged,
    required this.onTapWithoutSlide,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapWithoutSlide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.fromLTRB(24, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fade in',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'ulazi iz tišine · 10 s' : 'kreće odmah',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SlideSwitch(
            value: value,
            onChanged: onChanged,
            label: 'Fade in',
            icon: Icons.waves_rounded,
            onTapWithoutSlide: onTapWithoutSlide,
            width: 100,
            height: 60,
          ),
        ],
      ),
    );
  }
}
