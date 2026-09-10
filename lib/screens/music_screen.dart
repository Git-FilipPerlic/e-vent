import 'dart:async';

import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/audio_playback.dart';
import '../services/background_audio.dart';
import '../services/music_player_controller.dart';
import '../services/music_service.dart';
import '../services/track_library_service.dart';
import '../services/track_metadata_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/music/edge_progress_ring.dart';
import '../widgets/music/playback_bar.dart';
import '../widgets/music/track_tile.dart';
import 'file_browser_screen.dart';
import 'player_screen.dart';

/// Muzika tab — spisak numera za nastup.
///
/// Plejer ima **dva nivoa**: kontrole stoje uz sam spisak, pa se ne mora
/// izlaziti iz njega, a ogromno dugme i prsten su na nastupnom ekranu.
/// Kontroler živi ovde, pa muzika ide dalje i kad se izađe sa nastupnog ekrana.
///
/// Dodir na numeru **ne pokreće zvuk**: numera se ubacuje u red čekanja, a
/// zvuk kreće tek dugmetom.
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
  });

  /// Veza sa notifikacijom i kontrolama van aplikacije.
  final BackgroundAudioHandler? audioHandler;

  /// Ubacuje se u testu; u aplikaciji se pravi sam.
  final MusicService? service;
  final MusicPlayerController? controller;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  /// Jedino mesto gde se bira izvor numera.
  late final MusicService _service = widget.service ?? MockMusicService();

  /// Pamti dodate numere između pokretanja aplikacije.
  final TrackLibraryService _library = const TrackLibraryService();

  /// Čita izvođača i trajanje iz samih fajlova.
  final TrackMetadataService _metadata = TrackMetadataService();

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
    });
    // Red čekanja mora da dobije iste podatke, inače bi plejer pokazivao
    // naziv fajla dok spisak već pokazuje pravi naziv.
    _player.refreshQueue(byId);
  }

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(controller: _player),
      ),
    );
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

    return Column(
      children: [
        // Dugme za fajlove više ne stoji iznad spiska: preselilo se u traku,
        // kao **sama ikonica foldera**. Spisak time dobija ceo prostor, a
        // ikonica je jasna i bez natpisa.
        Expanded(
          // Prsten obilazi **spisak**, ne ceo ekran: dokle je pesma stigla
          // vidi se i ovde, a prevlačenjem uz ivicu se premota dok svira.
          // Dugmad iznad i traka ispod ostaju van prstena, da ih linija ne seče.
          //
          // **Praznog spiska se prsten ne tiče.** Dok nijedna numera nije
          // dodata nema šta da pokazuje, a linija oko praznog ekrana izgleda
          // kao greška — korisnik ju je i prijavio kao „neka zelena linija".
          child: _tracks.isEmpty
              ? _emptyList(context)
              : ValueListenableBuilder<List<double>?>(
                  valueListenable: _player.waveform,
                  builder: (context, amplitudes, child) => EdgeProgressRing(
                    progress: _player.progress,
                    amplitudes: amplitudes,
                    topInset: EdgeProgressRing.inset,
                    onSeekStart: _player.beginScrub,
                    onSeekUpdate: _player.updateScrub,
                    onSeekEnd: _player.endScrub,
                    child: child,
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadTracks,
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Spisak stoji unutar prstena, da ga ni linija ni talas
                      // ne preseca.
                      padding: const EdgeInsets.symmetric(
                        horizontal:
                            EdgeProgressRing.inset +
                            EdgeProgressRing.waveHeight +
                            AppSpacing.xs,
                        vertical:
                            EdgeProgressRing.inset +
                            EdgeProgressRing.waveHeight,
                      ),
                      itemExtent: TrackTile.height,
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        return TrackTile(
                          track: track,
                          isSelected: track.id == _player.selected?.id,
                          onTap: () => _player.onTrackTapped(track),
                          // Dug pritisak skida numeru sa spiska. Nije
                          // prevlačenje: usred nastupa se prst lako okrzne o
                          // ekran, pa bi prevlačenje brisalo numere samo od
                          // sebe.
                          onLongPress: () => _confirmRemove(track),
                        );
                      },
                    ),
                  ),
                ),
        ),
        // Prvi nivo: kontrole uz sam spisak, bez izlaska iz njega.
        // Trake nema dok se numera ne izabere — prazna traka samo zauzima red.
        if (_player.selected != null)
          PlaybackBar(
            controller: _player,
            onOpenPlayer: _openPlayer,
            onBrowse: _browse,
            onClearList: _tracks.isEmpty ? null : _confirmRemoveAll,
          ),
      ],
    );
  }

  Widget _emptyList(BuildContext context) {
    return Center(
      child: Padding(
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
            OutlinedButton.icon(
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
