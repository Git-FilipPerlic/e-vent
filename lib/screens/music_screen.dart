import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/track.dart';
import '../services/audio_playback.dart';
import '../services/background_audio.dart';
import '../services/music_player_controller.dart';
import '../services/music_service.dart';
import '../services/track_library_service.dart';
import '../services/track_metadata_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/music/music_controls.dart';
import '../widgets/music/music_row.dart';
import '../widgets/music/now_playing_card.dart';
import '../widgets/music/track_tile.dart';
import 'cue_screen.dart';
import 'file_browser_screen.dart';
import 'wave_screen.dart';

/// Muzika tab — plejlista za nastup, u svetlom, oblom izgledu
/// (redizajn od 25. septembra 2026, iTunes jednostavnost).
///
/// Odozgo nadole: kartica „Sada svira", red od četiri niske kartice
/// (Fade, God mode, jačina L/E/F, Ekran 2), plejlista i traka sa folderom
/// i „Uredi".
///
/// - dodir na numeru je pušta, osim u God mode-u, gde je samo bira za
///   Ekran 2
/// - zadržavanje prsta na numeri otvara talasni oblik preko celog ekrana
/// - kontroler živi ovde, pa muzika ide dalje i kad se izađe sa Ekrana 2 ili
///   talasnog oblika
///
/// Numere se dodaju kroz **sopstveni pregled fajlova** (`FileBrowserScreen`),
/// koji radi kao Moji fajlovi: ulazak u foldere, pa "ceo folder" ili označene
/// numere. Sistemski birač se više ne koristi, jer na Androidu vraća
/// `content://` adresu foldera koja ne može da se čita.
class MusicScreen extends StatefulWidget {
  const MusicScreen({
    super.key,
    this.service,
    this.controller,
    this.audioHandler,
    this.metadata,
  });

  /// Veza sa notifikacijom i kontrolama van aplikacije.
  final BackgroundAudioHandler? audioHandler;

  /// Ubacuje se u testu; u aplikaciji se pravi sam.
  final MusicService? service;
  final MusicPlayerController? controller;

  /// Čitač podataka iz fajla; u testu se podmeće lažni, jer se pravi
  /// audio fajlovi u testu ne čitaju.
  final TrackMetadataService? metadata;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  /// Jedino mesto gde se bira izvor numera.
  late final MusicService _service = widget.service ?? MockMusicService();

  /// Pamti dodate numere između pokretanja aplikacije.
  final TrackLibraryService _library = const TrackLibraryService();

  /// Čita izvođača i trajanje iz samih fajlova.
  late final TrackMetadataService _metadata =
      widget.metadata ?? TrackMetadataService();

  /// Reprodukcija i red čekanja. Nastupni ekran ga samo pozajmljuje.
  late final MusicPlayerController _player =
      widget.controller ?? MusicPlayerController(playback: JustAudioPlayback());

  /// Gasi se samo kontroler koji je ovaj ekran i napravio; ubačeni pripada
  /// onome ko ga je dao, pa bi ga dvostruko gašenje oborilo.
  bool get _ownsPlayer => widget.controller == null;

  List<Track> _tracks = const [];

  /// Numere koje je korisnik dodao sa telefona. Drže se odvojeno, da ih
  /// osvežavanje spiska ne obriše.
  final List<Track> _pickedTracks = [];

  bool _isLoading = true;
  String? _errorMessage;

  /// Isključen: dodir na numeru je odmah pušta. Uključen: dodir samo bira,
  /// a pušta se sa Ekrana 2.
  bool _godMode = false;

  /// Numera izabrana u God mode-u — nju pušta Ekran 2.
  Track? _cueTrack;

  /// Režim „Uredi": uz numere stoji minus za skidanje sa spiska.
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _player.addListener(_onPlayerChanged);
    // Notifikacija prati ovaj isti kontroler — dugmad u njoj rade isto što i
    // dugmad u aplikaciji.
    widget.audioHandler?.attach(_player);
    _loadTracks();
  }

  void _onPlayerChanged() => setState(() {});

  @override
  void dispose() {
    _player.removeListener(_onPlayerChanged);
    widget.audioHandler?.detach(_player);
    if (_ownsPlayer) _player.dispose();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tracks = await _service.loadTracks();
      if (!mounted) return;
      setState(() {
        _tracks = [...tracks, ..._pickedTracks];
        _isLoading = false;
      });

      // Zapamćene numere se dodaju **posle** toga i ne drže ekran: spisak se
      // vidi odmah, a ono što je zapamćeno ulazi čim se pročita.
      unawaited(_restoreRemembered());
      // Osvežavanje spiska vraća numere onakve kakve su dodate, bez
      // izvođača i trajanja. Zato se podaci čitaju ponovo — iz keša je to
      // trenutno, jer je fajl već jednom pročitan.
      if (_pickedTracks.isNotEmpty) unawaited(_fillMetadata(_pickedTracks));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Spisak numera nije učitan.';
        _isLoading = false;
      });
    }
  }

  /// Otvara pregled fajlova i dodaje ono što se odande vrati.
  /// Dodaje numere zapamćene iz prethodnog pokretanja.
  ///
  /// Bez ovoga bi izvođač pred svaki nastup ponovo tražio isti folder —
  /// spisak je ranije živeo samo dok je aplikacija otvorena.
  Future<void> _restoreRemembered() async {
    if (_pickedTracks.isNotEmpty) return;

    final remembered = await _library.load();
    if (!mounted || remembered.isEmpty) return;

    setState(() {
      _pickedTracks.addAll(remembered);
      _tracks = [..._tracks, ...remembered];
    });

    await _player.setQueue(_tracks);
    await _fillMetadata(remembered);
  }

  /// Pita da li se numera skida sa spiska.
  ///
  /// **Fajl ostaje na telefonu** — ovo briše samo red iz spiska. To i piše u
  /// listu, jer bi inače „ukloni" zvučalo kao brisanje muzike.
  Future<void> _confirmRemove(Track track) async {
    final removed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _RemoveSheet(title: track.displayTitle),
    );
    if (removed != true || !mounted) return;

    final wasRemoved = await _player.removeFromQueue(track.id);
    if (!mounted) return;

    if (!wasRemoved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Numera koja svira ne može da se skloni.'),
          ),
        );
      return;
    }

    setState(() {
      _tracks = [..._tracks]..removeWhere((t) => t.id == track.id);
      _pickedTracks.removeWhere((t) => t.id == track.id);
    });
    unawaited(_library.save(_pickedTracks));
  }

  /// Skida sve numere sa spiska, kad je ceo folder pogrešan.
  Future<void> _confirmRemoveAll() async {
    final removed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => const _RemoveSheet(title: null),
    );
    if (removed != true || !mounted) return;

    setState(() {
      _tracks = const [];
      _pickedTracks.clear();
    });
    await _player.setQueue(const []);
    unawaited(_library.save(const []));
  }

  Future<void> _browse() async {
    final tracks = await Navigator.of(context).push<List<Track>>(
      MaterialPageRoute(builder: (_) => const FileBrowserScreen()),
    );

    // Korisnik je odustao.
    if (tracks == null || tracks.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _pickedTracks.addAll(tracks);
      _tracks = [..._tracks, ...tracks];
    });
    // Spisak se pamti odmah, da preživi zatvaranje aplikacije.
    unawaited(_library.save(_pickedTracks));
    // Dodate numere postaju red čekanja, ali se ne puštaju same.
    await _player.setQueue(tracks);

    // Izvođač i trajanje se čitaju iz fajlova tek posle toga: spisak se vidi
    // odmah, a podaci ulaze čim stignu.
    await _fillMetadata(tracks);
  }

  /// Dopunjava spisak podacima iz samih fajlova.
  Future<void> _fillMetadata(List<Track> tracks) async {
    final enriched = await _metadata.enrichAll(tracks);
    if (!mounted) return;

    final byId = {for (final track in enriched) track.id: track};
    setState(() {
      _tracks = [for (final track in _tracks) byId[track.id] ?? track];
      // I dodate numere dobijaju iste podatke: spisak se gradi od njih
      // pri svakom osvežavanju, pa bi inače trajanje nestalo čim se
      // povuče nadole.
      for (var i = 0; i < _pickedTracks.length; i++) {
        final enrichedTrack = byId[_pickedTracks[i].id];
        if (enrichedTrack != null) _pickedTracks[i] = enrichedTrack;
      }
    });
    // Red čekanja mora da dobije iste podatke, inače bi plejer pokazivao
    // naziv fajla dok spisak već pokazuje pravi naziv.
    _player.refreshQueue(byId);
  }

  /// Dodir na numeru u spisku.
  ///
  /// - **God mode isključen:** numera se odmah pušta (uz pretapanje ako je
  ///   Fade uključen). Pravilo je promenjeno 25. septembra 2026 — korisnici
  ///   su se žalili da im nije intuitivno da u plejeru ima toliko koraka.
  /// - **God mode uključen:** dodir samo bira numeru i sprema je u pozadini;
  ///   pušta se sa Ekrana 2.
  Future<void> _onRowTap(Track track) async {
    if (_godMode) {
      setState(() => _cueTrack = track);
      await _player.onTrackTapped(track);
      return;
    }
    await _player.playNow(track);
  }

  void _setGodMode(bool value) {
    setState(() {
      _godMode = value;
      _cueTrack = null;
    });
  }

  Future<void> _openCue() async {
    final cue = _cueTrack;
    if (!_godMode) {
      _hint('Ekran 2 radi uz God mode');
      return;
    }
    if (cue == null) {
      _hint('Prvo izaberi numeru u listi');
      return;
    }
    final played = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CueScreen(
          controller: _player,
          track: cue,
          initialFade: _player.fade,
        ),
      ),
    );
    if (played == true && mounted) setState(() => _cueTrack = null);
  }

  Future<void> _openWave(Track track) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push<bool>(
      WaveScreen.route(controller: _player, track: track, fade: _player.fade),
    );
  }

  void _hint(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return ErrorRetry(message: errorMessage, onRetry: _loadTracks);
    }

    final sounding = _player.sounding;
    final total = _player.duration;
    final position = _player.position;
    final left = total == null ? null : total - position;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NowPlayingCard(
            title: sounding?.displayTitle,
            isPlaying: _player.isPlaying,
            progress: _player.progress,
            elapsed: sounding == null
                ? '0:00'
                : TrackTile.formatDuration(position),
            remaining: sounding == null || left == null || left.isNegative
                ? '-0:00'
                : '-${TrackTile.formatDuration(left)}',
            onTogglePause: sounding == null ? null : _player.togglePauseSounding,
            cueTitle: _godMode ? _cueTrack?.displayTitle : null,
          ),
          const SizedBox(height: 10),
          MusicControls(
            fade: _player.fade,
            onFadeChanged: _player.setFade,
            fadeLength: _player.fadeLength,
            onCycleFadeLength: _player.cycleFadeLength,
            godMode: _godMode,
            onGodModeChanged: _setGodMode,
            volume: _player.volume,
            onCycleVolume: _player.cycleVolume,
            recordSpeed: _player.recordSpeed,
            onCycleRecordSpeed: _player.cycleRecordSpeed,
            cueEnabled: _godMode && _cueTrack != null,
            onOpenCue: _openCue,
            onTapWithoutSlide: () =>
                _hint('Prevuci prekidač — dodir ga ne menja'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(kLargeRadius),
                boxShadow: kSoftShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: _tracks.isEmpty ? _emptyList(context) : _list(),
            ),
          ),
          if (_tracks.isNotEmpty) _footer(context),
          if (_tracks.isEmpty) const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _list() {
    final sounding = _player.sounding;
    return RefreshIndicator(
      onRefresh: _loadTracks,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemExtent: MusicRow.height,
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final track = _tracks[index];
          final isSounding = sounding?.id == track.id;
          return MusicRow(
            key: ValueKey(track.id),
            track: track,
            number: index + 1,
            isSounding: isSounding,
            isPlaying: isSounding && _player.isPlaying,
            isCued: _godMode && _cueTrack?.id == track.id && !isSounding,
            editing: _editing,
            onTap: () => _onRowTap(track),
            // Zadržavanje otvara talasni oblik. Skidanje sa spiska se
            // preselilo u „Uredi", da se ne otimaju oko istog pokreta.
            onLongPress: () => _openWave(track),
            onRemove: () => _confirmRemove(track),
          );
        },
      ),
    );
  }

  /// Traka ispod spiska: folder za dodavanje numera, kratko uputstvo i
  /// „Uredi" za skidanje numera sa spiska.
  Widget _footer(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Dodaj numere',
            onPressed: _editing ? null : _browse,
            icon: const Icon(Icons.create_new_folder_rounded),
          ),
          Expanded(
            child: Text(
              _editing
                  ? 'Minus skida numeru sa spiska'
                  : (_godMode
                        ? 'Dodir bira · zadrži za talas'
                        : 'Dodir pušta · zadrži za talas'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (_editing)
            IconButton(
              tooltip: 'Skloni sve',
              onPressed: _confirmRemoveAll,
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.danger,
              ),
            ),
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Gotovo' : 'Uredi'),
          ),
        ],
      ),
    );
  }

  Widget _emptyList(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nijedna numera nije dodata.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            // Dok spiska nema, nema ni trake — pa folder mora da stoji ovde,
            // inače se numere ne bi imale odakle dodati.
            FilledButton.icon(
              onPressed: _browse,
              icon: const Icon(Icons.folder_open_rounded, size: 20),
              label: const Text('Pregledaj fajlove'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Potvrda skidanja sa spiska.
///
/// [title] je naziv numere; `null` znači „ceo spisak". Tekst izričito kaže da
/// fajl ostaje na telefonu — bez toga bi „ukloni" zvučalo kao brisanje muzike.
class _RemoveSheet extends StatelessWidget {
  const _RemoveSheet({required this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAll = title == null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isAll ? 'Skloni sve numere sa spiska?' : title!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Skida se samo sa spiska. Fajl ostaje na telefonu i može '
              'ponovo da se doda kroz pregled fajlova.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Odustani'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(isAll ? 'Skloni sve' : 'Skloni'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
