import 'package:flutter/material.dart';

import '../../models/track.dart';
import '../../theme/app_theme.dart';
import 'track_tile.dart';

/// Jedan red u plejlisti, u novom, obljem izgledu (od 25. septembra 2026).
///
/// - redni broj levo; numera koja svira umesto broja ima **tri pokretna
///   stubića**, a numera spremljena za Ekran 2 (God mode) plavu kvačicu
/// - naziv krupno, izvor sitno ispod, trajanje desno
/// - **zadržavanje prsta** otvara talasni oblik numere. Dok prst stoji, red
///   se blago skupi — znak da se nešto sprema, pre nego što se ekran otvori
/// - u režimu uređivanja levo stoji crveni minus za skidanje sa spiska, a
///   dodir na red ne radi ništa
class MusicRow extends StatefulWidget {
  const MusicRow({
    super.key,
    required this.track,
    required this.number,
    required this.isSounding,
    required this.isPlaying,
    required this.isCued,
    required this.editing,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
  });

  final Track track;

  /// Redni broj u spisku, od 1.
  final int number;

  /// Ova numera je ta koja se čuje (ili je pauzirana usred sviranja).
  final bool isSounding;

  /// Zvuk zaista ide — stubići se pomeraju samo tada.
  final bool isPlaying;

  /// Spremljena za Ekran 2.
  final bool isCued;

  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;

  /// Visina reda. Svesno ispod dodirne mete od 48 dp, kao i u ranijem
  /// zbijenom spisku: na nastupu je bitnije koliko numera staje na ekran
  /// nego širina mete, a red ide preko cele širine pa se ne promašuje.
  static const double height = 44;

  @override
  State<MusicRow> createState() => _MusicRowState();
}

class _MusicRowState extends State<MusicRow> {
  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing == value) return;
    setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final track = widget.track;

    final Color background;
    if (widget.isCued) {
      background = AppColors.peach;
    } else if (_pressing) {
      background = AppColors.surfaceAlt;
    } else {
      background = AppColors.surface;
    }

    // Uvećanje sistemskog fonta je ograničeno, kao kod sistemskih birača
    // datuma i sata: na krupnom fontu bi dva reda teksta prerasla visinu
    // reda, a zbijen spisak je ovde ceo smisao.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.1,
      child: AnimatedScale(
      scale: _pressing && !reduceMotion ? 0.97 : 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: MusicRow.height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(_pressing ? 18 : 0),
        ),
        // Razdelnik je uvučen kao na iPhone-u: počinje tek ispod naziva.
        // Dekoracija se ne sme ugasiti na `null` dok se red drži prstom:
        // `Container` tada izbaci ceo sloj iz stabla, a sa njim i widget
        // koji hvata dodir — pa se zadržavanje prsta prekidalo pre nego
        // što postane dug pritisak. Zato razdelnik uvek stoji, samo se
        // ne crta.
        foregroundDecoration: _InsetDivider(show: !_pressing),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.editing ? null : widget.onTap,
            onLongPress: widget.editing ? null : widget.onLongPress,
            onTapDown: widget.editing ? null : (_) => _setPressing(true),
            onTapUp: (_) => _setPressing(false),
            onTapCancel: () => _setPressing(false),
            splashColor: AppColors.accentDeep,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: MusicRow.height,
                    child: Center(child: _leading(theme)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: widget.isSounding
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontWeight: widget.isSounding
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          track.hasArtist
                              ? '${track.artist} · ${track.source.label}'
                              : track.source.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    TrackTile.formatDuration(track.duration),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _leading(ThemeData theme) {
    if (widget.editing) {
      return IconButton(
        onPressed: widget.onRemove,
        tooltip: 'Skloni sa spiska',
        icon: const Icon(Icons.remove_circle_rounded, color: AppColors.danger),
      );
    }
    if (widget.isSounding) {
      return _EqualizerBars(animate: widget.isPlaying);
    }
    if (widget.isCued) {
      return const Icon(
        Icons.check_circle_rounded,
        color: AppColors.accent,
        size: 26,
        semanticLabel: 'Spremljena za Ekran 2',
      );
    }
    return Text(
      '${widget.number}',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Tri stubića koja „sviraju" uz numeru koja se čuje. Na pauzi stoje.
class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars({required this.animate});

  final bool animate;

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.animate && !reduceMotion) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.animate ? 'Svira' : 'Pauzirano',
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 4,
                  height: 16 * _barHeight(t, i),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Visina stubića 0.35..1, svaki u svom ritmu.
  double _barHeight(double t, int i) {
    final phase = (t + i / 3) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.35 + 0.65 * wave;
  }
}

/// Tanka linija na dnu reda, uvučena sleva do početka naziva.
///
/// Ide kao zaseban ukras jer Flutter ne dozvoljava okvir samo na jednoj
/// strani zajedno sa zaobljenim uglovima.
class _InsetDivider extends Decoration {
  const _InsetDivider({required this.show});

  /// Dok se red drži prstom razdelnika nema, ali sloj ostaje.
  final bool show;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _InsetDividerPainter(show);
}

class _InsetDividerPainter extends BoxPainter {
  _InsetDividerPainter(this.show);

  final bool show;

  static const double _inset = 64;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (!show || size == null) return;
    final paint = Paint()
      ..color = AppColors.surfaceAlt
      ..strokeWidth = 1;
    final y = offset.dy + size.height - 0.5;
    canvas.drawLine(
      Offset(offset.dx + _inset, y),
      Offset(offset.dx + size.width, y),
      paint,
    );
  }
}
