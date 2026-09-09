import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/music_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/music/track_tile.dart';
import 'player_screen.dart';

/// Muzika tab — spisak numera za nastup.
///
/// Izbor numere **ne pokreće reprodukciju**; ona kreće tek u plejeru, velikim
/// dugmetom. Zato ekran ima dva koraka: prvo se numera izabere iz spiska, pa
/// se otvori plejer.
///
/// Spisak čine test numere i **fajlovi koje korisnik doda sa telefona**.
/// Biranje ide kroz sistemski birač, pa ne treba posebna dozvola za čitanje
/// memorije — korisnik sam pokazuje šta sme da se čita.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  /// Jedino mesto gde se bira izvor numera.
  final MusicService _service = MockMusicService();

  List<Track> _tracks = const [];

  /// Numere koje je korisnik dodao sa telefona. Drže se odvojeno, da ih
  /// osvežavanje spiska ne obriše.
  final List<Track> _pickedTracks = [];

  int _nextPickedNumber = 1;
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

  /// Otvara sistemski birač i dodaje izabrane numere u spisak.
  Future<void> _pickTracks() async {
    final messenger = ScaffoldMessenger.of(context);

    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(type: FileType.audio);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Biranje numera nije uspelo.')),
        );
      return;
    }

    // Korisnik je odustao — ništa se ne menja i ništa se ne javlja.
    if (files.isEmpty) return;

    final added = [
      for (final file in files)
        Track(
          id: 'izabrano-${_nextPickedNumber++}',
          title: file.name,
          // Na Androidu birač vraća `content://` adresu, ne putanju na disku,
          // pa se pamti cela adresa — plejer ume da pusti i jedno i drugo.
          path: file.path ?? file.uri.toString(),
        ),
    ];

    if (!mounted) return;
    setState(() {
      _pickedTracks.addAll(added);
      _tracks = [..._tracks, ...added];
      // Poslednja dodata numera je verovatno ona koja se traži.
      _selectedTrackId = added.last.id;
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
            0,
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickTracks,
              icon: const Icon(Icons.library_music_rounded, size: 20),
              label: const Text('Dodaj numere sa telefona'),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
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
