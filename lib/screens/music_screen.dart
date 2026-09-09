import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/music_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/music/track_tile.dart';
import 'file_browser_screen.dart';
import 'player_screen.dart';

/// Muzika tab — spisak numera za nastup.
///
/// Izbor numere **ne pokreće reprodukciju**; ona kreće tek u plejeru, velikim
/// dugmetom. Zato ekran ima dva koraka: prvo se numera izabere iz spiska, pa
/// se otvori plejer.
///
/// Numere se dodaju kroz **sopstveni pregled fajlova** (`FileBrowserScreen`),
/// koji radi kao Moji fajlovi: ulazak u foldere, pa "ceo folder" ili označene
/// numere. Sistemski birač se više ne koristi, jer na Androidu vraća
/// `content://` adresu foldera koja ne može da se čita.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key, this.service});

  /// Ubacuje se u testu; u aplikaciji se pravi sam.
  final MusicService? service;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  /// Jedino mesto gde se bira izvor numera.
  late final MusicService _service = widget.service ?? MockMusicService();

  List<Track> _tracks = const [];

  /// Numere koje je korisnik dodao sa telefona. Drže se odvojeno, da ih
  /// osvežavanje spiska ne obriše.
  final List<Track> _pickedTracks = [];

  String? _selectedTrackId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTracks();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Spisak numera nije učitan.';
        _isLoading = false;
      });
    }
  }

  /// Otvara pregled fajlova i dodaje ono što se odande vrati.
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
      // Prva dodata numera je verovatno ona od koje se kreće.
      _selectedTrackId = tracks.first.id;
    });
  }

  Track? get _selectedTrack {
    for (final track in _tracks) {
      if (track.id == _selectedTrackId) return track;
    }
    return null;
  }

  void _openPlayer(Track track) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(track: track)),
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

    final selected = _selectedTrack;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _browse,
              icon: const Icon(Icons.folder_open_rounded, size: 20),
              label: const Text('Pregledaj fajlove'),
            ),
          ),
        ),
        Expanded(
          child: _tracks.isEmpty
              ? _emptyList(context)
              : RefreshIndicator(
                  onRefresh: _loadTracks,
                  color: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemExtent: TrackTile.height,
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      return TrackTile(
                        track: track,
                        isSelected: track.id == _selectedTrackId,
                        onTap: () =>
                            setState(() => _selectedTrackId = track.id),
                      );
                    },
                  ),
                ),
        ),
        // Dugme za plejer stoji pri dnu, van spiska — u toku nastupa se traži
        // prstom, bez gledanja u ekran.
        if (selected != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openPlayer(selected),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text('Otvori plejer — ${selected.displayTitle}'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyList(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Nijedna numera nije dodata.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
