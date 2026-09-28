import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/track.dart';
import '../models/track_note.dart';
import '../services/music_player_controller.dart';
import '../services/track_note_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/edit_text_sheet.dart';
import '../widgets/common/slide_switch.dart';
import '../widgets/common/team_avatar.dart';
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
    this.notes,
    this.authorName,
    this.authorAvatarId,
  });

  final MusicPlayerController controller;
  final Track track;

  /// Da li se na drugu numeru prelazi pretapanjem.
  final bool fade;

  /// Beleške na pesmi, koje vidi cela ekipa. `null` znači bez beleški —
  /// tako ekran u testu ne ide na mrežu.
  final TrackNoteService? notes;

  /// Ko upisuje belešku. `null` (neprijavljen) ih samo čita.
  final String? authorName;
  final String? authorAvatarId;

  /// Otvaranje uz blago „izranjanje" — ekran se pojavi, ne klizne.
  static Route<bool> route({
    required MusicPlayerController controller,
    required Track track,
    required bool fade,
    TrackNoteService? notes,
    String? authorName,
    String? authorAvatarId,
  }) {
    return PageRouteBuilder<bool>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => WaveScreen(
        controller: controller,
        track: track,
        fade: fade,
        notes: notes,
        authorName: authorName,
        authorAvatarId: authorAvatarId,
      ),
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

  /// Beleške koje je ekipa ostavila na ovoj pesmi.
  List<TrackNote> _trackNotes = const [];

  /// Po čemu se numera prepoznaje na svim telefonima — naziv fajla, ne
  /// putanja, jer isti fajl kod svakog stoji na svom mestu.
  String get _noteKey {
    final path = widget.track.path;
    return path == null ? '' : TrackNote.keyForPath(path);
  }

  /// Gde je beleška u pesmi, 0..1.
  ///
  /// Računa se po trajanju koje je **uz belešku zapamćeno**, ne po onom koje
  /// ovaj telefon trenutno zna: ta dva broja ume da se razlikuju, pa je
  /// ista beleška pri sledećem otvaranju padala na drugo mesto.
  double? _fractionOf(TrackNote note) => note.fractionIn(_duration);

  /// Mesta beleški, za isprekidane linije na talasu.
  List<double> get _noteFractions => [
    for (final note in _trackNotes)
      if (_fractionOf(note) != null) _fractionOf(note)!,
  ];

  /// Otvara belešku: tekst, ko ju je ostavio i gde je u pesmi.
  Future<void> _openNote(TrackNote note) async {
    final removed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _NoteSheet(
        note: note,
        // Svoju belešku svako sme da skloni; tuđu ne dira.
        canRemove:
            widget.authorName != null && widget.authorName == note.authorName,
      ),
    );
    if (removed != true || !mounted) return;

    setState(() {
      _trackNotes = [
        for (final one in _trackNotes)
          if (one.id != note.id) one,
      ];
    });
    try {
      await widget.notes?.remove(note.id);
    } catch (_) {
      await _loadNotes();
    }
  }

  /// Ostavlja belešku tamo gde stoji linija.
  ///
  /// Mesto je ono što se vidi — linija na sredini ekrana — pa se ne pita
  /// „gde", nego samo „šta".
  Future<void> _addNote() async {
    final service = widget.notes;
    final author = widget.authorName;
    final total = _duration;
    if (service == null || author == null || total == null) return;

    // Mesto se uzima **pre** nego što se otvori list za unos, i posle se ne
    // računa ponovo. Dok se kuca, tastatura skupi ekran, a sa njim i visinu
    // talasa; mesto izračunato posle toga je padalo dalje kroz pesmu nego
    // linija na kojoj je beleška ostavljena.
    final position = _positionNow(total);

    final text = await showEditTextSheet(
      context,
      label: 'Beleška na ${TrackTile.formatDuration(position)}',
      value: null,
      hint: 'na primer omiljeni deo',
    );
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty || !mounted) return;

    final draft = TrackNote(
      id: '',
      trackKey: _noteKey,
      positionMs: position.inMilliseconds,
      // Uz mesto se pamti i trajanje po kom je računato.
      trackDurationMs: total.inMilliseconds,
      text: trimmed,
      authorName: author,
      authorAvatarId: widget.authorAvatarId,
    );

    try {
      final saved = await service.add(draft);
      if (!mounted) return;
      setState(() => _trackNotes = [..._trackNotes, saved]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Beleška nije sačuvana.')));
    }
  }

  /// Gde je linija u pesmi, u vremenu.
  Duration _positionNow(Duration total) =>
      Duration(milliseconds: (total.inMilliseconds * _fraction).round());

  Future<void> _loadNotes() async {
    final service = widget.notes;
    if (service == null || _noteKey.isEmpty) return;
    try {
      final notes = await service.notesFor(_noteKey);
      if (!mounted) return;
      setState(() => _trackNotes = notes);
    } catch (_) {
      // Bez beleški talas i dalje radi — one su dopuna, ne uslov.
    }
  }

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
    _loadNotes();
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
      // I ista numera ide uz pretapanje: izabrani deo ulazi **preko**
      // onoga što svira, pa se pesma preklapa sama sa sobom. Bez `Fade`
      // se samo premota na to mesto.
      fade: _fade,
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
      // Tastatura ne skuplja talas: kad se ekran skrati, linija na sredini
      // pada na drugo mesto u pesmi, a beleška se ostavlja upravo tu.
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Gornja traka (zatvaranje i Fade) ne pripada talasu. Bez toga
          // zadržavanje prsta pri prevlačenju prekidača ume da se upiše
          // kao „pusti odavde" — a muzika ne sme da krene od okrznutog
          // prsta pored prekidača.
          final bar = MediaQuery.of(context).padding.top + 72;
          _viewport = constraints.maxHeight - bar;
          final width = constraints.maxWidth;
          final half = _viewport / 2;
          final lineY = bar + half;
          WidgetsBinding.instance.addPostFrameCallback((_) => _positionOnce());

          return Stack(
            children: [
              Positioned.fill(
                top: bar,
                child: RawGestureDetector(
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
                    child: SizedBox(
                      width: width,
                      height: _contentHeight + _viewport,
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _scroll,
                            builder: (context, _) => CustomPaint(
                              size: Size(width, _contentHeight + _viewport),
                              painter: _WavePainter(
                                amplitudes: _amplitudes,
                                top: half,
                                height: _contentHeight,
                                playheadY: half + _fraction * _contentHeight,
                                notes: _noteFractions,
                              ),
                            ),
                          ),
                          // Ikonica onoga ko je ostavio belešku stoji uz levu
                          // ivicu, na visini svog mesta u pesmi.
                          for (final note in _trackNotes)
                            if (_fractionOf(note) != null)
                              Positioned(
                                left: AppSpacing.sm,
                                top:
                                    half +
                                    _fractionOf(note)! * _contentHeight -
                                    16,
                                child: GestureDetector(
                                  onTap: () => _openNote(note),
                                  child: TeamAvatarDot(
                                    avatarId: note.authorAvatarId,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Linija na sredini — mesto odakle numera kreće.
              Positioned(
                left: 0,
                right: 0,
                top: lineY - 1,
                child: IgnorePointer(
                  child: Container(height: 2, color: AppColors.textPrimary),
                ),
              ),
              // Krug koji se puni dok prst stoji.
              Positioned(
                left: width / 2 - 40,
                top: lineY - 40,
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
                top: lineY + 16,
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
              // Beleška se ostavlja tamo gde stoji linija — mesto se vidi,
              // pa se pita samo šta piše.
              if (widget.notes != null && widget.authorName != null)
                Positioned(
                  right: AppSpacing.md,
                  bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                  child: FloatingActionButton.extended(
                    onPressed: _addNote,
                    icon: const Icon(Icons.bookmark_add_rounded),
                    label: const Text('Zabeleži'),
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
                    icon: Icon(
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
    this.notes = const [],
  });

  /// Vrednosti 0..1; `null` = crta se tanka ravna linija.
  final List<double>? amplitudes;

  /// Gde počinje pesma (pola ekrana od vrha sadržaja).
  final double top;

  /// Koliko je pesma visoka na ekranu.
  final double height;

  /// Gde je linija, u koordinatama sadržaja.
  final double playheadY;

  /// Mesta beleški u pesmi, 0..1 — svaka dobija isprekidanu liniju.
  final List<double> notes;

  /// Koliko visine uzima jedna crtica sa razmakom.
  static const double _barPitch = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final maxHalf = size.width * 0.42;
    final values = amplitudes;

    if (values == null || values.isEmpty) {
      // Dok se talas računa stoji tanka, tiha linija. Ranije je bila
      // debela i u boji numere, pa je ličila na kvar.
      canvas.drawRect(
        Rect.fromLTWH(cx - 0.5, top, 1, height),
        Paint()..color = AppColors.border,
      );
      return;
    }

    final past = Paint()..color = AppColors.peachWave;
    final ahead = Paint()..color = AppColors.accent;

    final n = values.length;

    // Koliko crtica staje po visini. Crtica i razmak zajedno uzimaju 3 dp —
    // gušće od toga se stapa u blok boje.
    final bars = (height / _barPitch).floor().clamp(1, n);
    final pitch = height / bars;
    final thickness = math.max(1.0, pitch * 0.55);

    // Crta se **samo ono što se vidi**. Niz ima 2400 vrednosti, a na ekran
    // ih staje nekoliko stotina; bez ovoga bi se pri svakom pomeraju prsta
    // crtalo hiljadama pravougaonika uzalud.
    final scroll = playheadY - top;
    final first = ((scroll - top) / pitch).floor().clamp(0, bars - 1);
    final last = ((scroll + top) / pitch).ceil().clamp(0, bars);

    for (var i = first; i < last; i++) {
      // Jedna crtica pokriva više vrednosti iz niza, pa se uzima **najglasnija**
      // u tom opsegu. Tako zumiran talas pokazuje pravi detalj, a nezumiran
      // vrhove — a ne prosek, koji sve spljošti.
      final from = (i * n / bars).floor();
      final to = math.max(from + 1, ((i + 1) * n / bars).ceil());
      var peak = 0.0;
      for (var j = from; j < to && j < n; j++) {
        final value = values[j];
        if (value > peak) peak = value;
      }

      // Blaga kriva razvlači razliku između tihog i glasnog: današnja
      // muzika je izravnata, pa bi bez toga sve bilo podjednako široko.
      final a = math.pow(peak.clamp(0.0, 1.0), 1.6).toDouble();
      final half = math.max(1.0, a * maxHalf);
      final y = top + i * pitch;
      canvas.drawRect(
        Rect.fromLTWH(cx - half, y, half * 2, thickness),
        y + thickness / 2 < playheadY ? past : ahead,
      );
    }

    _paintNotes(canvas, size);
  }

  /// Isprekidana linija preko celog talasa, tamo gde je neko ostavio
  /// belešku. Ikonicu crta sam ekran, jer je to widget.
  void _paintNotes(Canvas canvas, Size size) {
    if (notes.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1;
    const dash = 6.0;
    const gap = 5.0;

    for (final fraction in notes) {
      final y = top + fraction * height;
      for (var x = 0.0; x < size.width; x += dash + gap) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.amplitudes != amplitudes ||
      old.top != top ||
      old.height != height ||
      old.playheadY != playheadY ||
      old.notes.length != notes.length;
}

/// Beleška u listu: šta piše, ko ju je ostavio i gde je u pesmi.
class _NoteSheet extends StatelessWidget {
  const _NoteSheet({required this.note, required this.canRemove});

  final TrackNote note;

  /// Svoju belešku svako sme da skloni; tuđu ne dira.
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TeamAvatarDot(avatarId: note.authorAvatarId),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    note.authorName.isEmpty ? 'Neko iz ekipe' : note.authorName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  TrackTile.formatDuration(note.position),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(note.text, style: theme.textTheme.bodyLarge),
            if (canRemove) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Skloni belešku'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
