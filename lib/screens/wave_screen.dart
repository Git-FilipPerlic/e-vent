import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/track.dart';
import '../services/music_player_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common/slide_switch.dart';
import '../widgets/music/track_tile.dart';

/// Talasni oblik numere preko **celog ekrana, odozgo nadole**.
///
/// Otvara se zadržavanjem prsta na numeri u plejlisti (dogovoreno 25.
/// septembra 2026). Na ekranu nema ničeg drugog — samo talas, vodoravna
/// linija na sredini i vreme ispod nje.
///
/// - **skrol** kroz pesmu, kao kroz Instagram: linija na sredini je mesto
///   odakle bi numera krenula. Deo iznad linije je breskva (već prošlo), deo
///   ispod je safirni
/// - **dva brza dodira** zumiraju: pesma se razvuče i skroluje se sporije i
///   preciznije; ponovo dva dodira vraćaju ceo pregled
/// - **zadržavanje prsta** pušta numeru od tog mesta. Oko linije se puni
///   krug, pa numera krene — ako nešto već svira, prelazi se na nju
///   pretapanjem (kad je Fade uključen). Ako je to numera koja već svira,
///   samo se premota
///
/// Pesma 1 svira, izvođač otvori pesmu 2, skroluje do dela koji mu treba i
/// zadrži prst — pesma 2 uđe baš od tog mesta.
class WaveScreen extends StatefulWidget {
  const WaveScreen({
    super.key,
    required this.controller,
    required this.track,
    required this.fade,
  });

  final MusicPlayerController controller;
  final Track track;

  /// Da li se na drugu numeru prelazi pretapanjem.
  final bool fade;

  /// Otvaranje uz blago „izranjanje" — ekran se pojavi, ne klizne.
  static Route<bool> route({
    required MusicPlayerController controller,
    required Track track,
    required bool fade,
  }) {
    return PageRouteBuilder<bool>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) =>
          WaveScreen(controller: controller, track: track, fade: fade),
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.of(context).disableAnimations) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<WaveScreen> createState() => _WaveScreenState();
}

class _WaveScreenState extends State<WaveScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();

  /// Krug koji se puni dok prst stoji. Kad se napuni, numera krene.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..addStatusListener(_onHoldStatus);

  /// Pretapanje za **ovo** puštanje. Kreće od onoga što stoji na Muzika
  /// tabu, ali se ovde menja: na talasu se bira deo pesme koji ulazi, pa
  /// se tu i odlučuje da li prethodna numera izlazi pretapanjem.
  late bool _fade = widget.fade;

  List<double>? _amplitudes;
  bool _loaded = false;

  /// Dokle je stiglo izvlačenje talasa, 0..1.
  ///
  /// Izvlačenje traje nekoliko sekundi po numeri, a dotle se crta samo
  /// tanka linija — bez ovoga je delovalo kao da je ekran pokvaren.
  double _progress = 0;

  /// 1 = cela pesma na jednom ekranu; veće = razvučeno.
  double _zoom = 1;
  static const double _zoomedIn = 4;

  /// Visina prikaza, poznata tek posle prvog crtanja.
  double _viewport = 0;
  bool _positioned = false;
  bool _starting = false;

  Duration? get _duration {
    final own = widget.track.duration;
    if (own != null && own > Duration.zero) return own;
    if (widget.controller.sounding?.id == widget.track.id) {
      return widget.controller.duration;
    }
    return null;
  }

  bool get _isSounding => widget.controller.sounding?.id == widget.track.id;

  double get _contentHeight => _viewport * _zoom;

  /// Koji deo pesme je pod linijom, 0..1.
  double get _fraction {
    if (!_scroll.hasClients || _contentHeight <= 0) return 0;
    return (_scroll.offset / _contentHeight).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _loadWave();
  }

  Future<void> _loadWave() async {
    final amplitudes = await widget.controller.amplitudesFor(
      widget.track,
      onProgress: (value) {
        if (!mounted || _loaded) return;
        setState(() => _progress = value);
      },
    );
    if (!mounted) return;
    setState(() {
      _amplitudes = amplitudes;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Prvi put ekran staje tamo gde numera trenutno svira; druga numera
  /// kreće od početka.
  void _positionOnce() {
    if (_positioned || !_scroll.hasClients) return;
    _positioned = true;
    final total = _duration;
    if (!_isSounding || total == null || total == Duration.zero) return;
    final f = widget.controller.position.inMilliseconds / total.inMilliseconds;
    _scroll.jumpTo(f.clamp(0.0, 1.0) * _contentHeight);
  }

  void _toggleZoom() {
    final keep = _fraction;
    setState(() => _zoom = _zoom == 1 ? _zoomedIn : 1);
    HapticFeedback.selectionClick();
    // Posle promene visine linija ostaje na istom mestu u pesmi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(keep * _contentHeight);
    });
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _startHere();
  }

  Future<void> _startHere() async {
    if (_starting) return;
    _starting = true;
    HapticFeedback.heavyImpact();

    final total = _duration;
    final from = total == null
        ? null
        : Duration(milliseconds: (total.inMilliseconds * _fraction).round());

    await widget.controller.playNow(
      widget.track,
      // Ista numera se samo premota — pretapanje sa samom sobom nema smisla.
      fade: _isSounding ? false : _fade,
      from: from,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// Šta piše u pilulici na sredini: dok se talas računa — dokle je stiglo,
  /// posle — vreme, a ako talasa nema — i to.
  String _waveLabel() {
    if (!_loaded) {
      final percent = (_progress * 100).clamp(0, 99).round();
      return 'Talas se računa · $percent%';
    }
    if (_amplitudes == null) return 'Talas nije dostupan · ${_timeLabel()}';
    return _timeLabel();
  }

  String _timeLabel() {
    final total = _duration;
    if (total == null) return '--:-- / --:--';
    final at = Duration(
      milliseconds: (total.inMilliseconds * _fraction).round(),
    );
    final zoom = _zoom == 1 ? '' : ' · zum';
    return '${TrackTile.formatDuration(at)} / '
        '${TrackTile.formatDuration(total)}$zoom';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundTop,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewport = constraints.maxHeight;
          final width = constraints.maxWidth;
          final half = _viewport / 2;
          WidgetsBinding.instance.addPostFrameCallback((_) => _positionOnce());

          return Stack(
            children: [
              RawGestureDetector(
                gestures: {
                  // Zadržavanje kreće posle kratkih 200 ms, pa se krug puni
                  // još 650 ms. Pomeranje prsta je skrol i poništava ga.
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(
                        () => LongPressGestureRecognizer(
                          duration: const Duration(milliseconds: 200),
                        ),
                        (instance) {
                          instance
                            ..onLongPressStart = (_) {
                              HapticFeedback.selectionClick();
                              _hold.forward();
                            }
                            ..onLongPressEnd = (_) {
                              if (!_hold.isCompleted) _hold.reverse();
                            }
                            ..onLongPressCancel = () {
                              if (!_hold.isCompleted) _hold.reverse();
                            };
                        },
                      ),
                  DoubleTapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        DoubleTapGestureRecognizer
                      >(
                        DoubleTapGestureRecognizer.new,
                        (instance) => instance.onDoubleTap = _toggleZoom,
                      ),
                },
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder: (context, _) => CustomPaint(
                      size: Size(width, _contentHeight + _viewport),
                      painter: _WavePainter(
                        amplitudes: _amplitudes,
                        top: half,
                        height: _contentHeight,
                        playheadY: half + _fraction * _contentHeight,
                      ),
                    ),
                  ),
                ),
              ),
              // Linija na sredini — mesto odakle numera kreće.
              Positioned(
                left: 0,
                right: 0,
                top: half - 1,
                child: IgnorePointer(
                  child: Container(height: 2, color: AppColors.textPrimary),
                ),
              ),
              // Krug koji se puni dok prst stoji.
              Positioned(
                left: width / 2 - 40,
                top: half - 40,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _hold,
                    builder: (context, _) => Opacity(
                      opacity: _hold.value == 0 ? 0 : 1,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: _hold.value,
                          strokeWidth: 5,
                          color: AppColors.accent,
                          backgroundColor: AppColors.accentDeep,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Vreme ispod linije.
              Positioned(
                left: 0,
                right: 0,
                top: half + 16,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _scroll,
                      builder: (context, _) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: kSoftShadow,
                        ),
                        child: Text(
                          _waveLabel(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Pretapanje se bira ovde, a ne samo na spisku: dok jedna
              // numera izlazi, sa talasa se ubacuje tačan deo druge.
              Positioned(
                right: AppSpacing.md,
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                child: Row(
                  children: [
                    Text(
                      'Fade',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _fade
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SlideSwitch(
                      value: _fade,
                      onChanged: (value) => setState(() => _fade = value),
                      label: 'Pretapanje',
                      icon: Icons.waves_rounded,
                      onTapWithoutSlide: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Prevuci prekidač — dodir ga ne menja',
                            ),
                          ),
                        ),
                    ),
                  ],
                ),
              ),
              // Jedino dugme: nazad na spisak.
              Positioned(
                left: AppSpacing.md,
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                child: Material(
                  color: AppColors.surface,
                  shape: const CircleBorder(),
                  shadowColor: Colors.transparent,
                  child: IconButton(
                    tooltip: 'Zatvori',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Crta talas uspravno: sredina ekrana je osa, a glasnoća se širi levo i
/// desno. Iznad linije breskva, ispod safir.
class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.amplitudes,
    required this.top,
    required this.height,
    required this.playheadY,
  });

  /// Vrednosti 0..1; `null` = crta se tanka ravna linija.
  final List<double>? amplitudes;

  /// Gde počinje pesma (pola ekrana od vrha sadržaja).
  final double top;

  /// Koliko je pesma visoka na ekranu.
  final double height;

  /// Gde je linija, u koordinatama sadržaja.
  final double playheadY;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final maxHalf = size.width * 0.46;
    final values = amplitudes;

    final path = Path();
    if (values == null || values.isEmpty) {
      // Dok se talas računa stoji tanka, tiha linija. Ranije je bila
      // debela i u boji numere, pa je ličila na kvar.
      canvas.drawRect(
        Rect.fromLTWH(cx - 0.5, top, 1, height),
        Paint()..color = AppColors.border,
      );
      return;
    }

    final n = values.length;
    final step = height / n;
    path.moveTo(cx, top);
    for (var i = 0; i < n; i++) {
      final a = values[i].clamp(0.02, 1.0);
      path.lineTo(cx + a * maxHalf, top + (i + 0.5) * step);
    }
    path.lineTo(cx, top + height);
    for (var i = n - 1; i >= 0; i--) {
      final a = values[i].clamp(0.02, 1.0);
      path.lineTo(cx - a * maxHalf, top + (i + 0.5) * step);
    }
    path.close();

    final past = Paint()..color = AppColors.peachWave;
    final ahead = Paint()..color = AppColors.accent;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, playheadY));
    canvas.drawPath(path, past);
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, playheadY, size.width, size.height));
    canvas.drawPath(path, ahead);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.amplitudes != amplitudes ||
      old.top != top ||
      old.height != height ||
      old.playheadY != playheadY;
}
