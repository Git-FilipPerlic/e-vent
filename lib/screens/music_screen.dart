import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/music_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/music/track_tile.dart';

/// Muzika tab — spisak numera za nastup.
///
/// Izbor numere **ne pokreće reprodukciju**; ona kreće tek u plejeru, velikim
/// dugmetom. Zato ekran ima dva koraka: prvo se numera izabere iz spiska, pa
/// se otvori plejer.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  /// Jedino mesto gde se bira izvor numera.
  final MusicService _service = MockMusicService();

  List<Track> _tracks = const [];
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
        _tracks = tracks;
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

  Track? get _selectedTrack {
    for (final track in _tracks) {
      if (track.id == _selectedTrackId) return track;
    }
    return null;
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

    if (_tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Nijedna numera nije učitana.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final selected = _selectedTrack;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTracks,
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return TrackTile(
                  track: track,
                  isSelected: track.id == _selectedTrackId,
                  onTap: () => setState(() => _selectedTrackId = track.id),
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

  void _openPlayer(Track track) {
    // Plejer se pravi u sledećem koraku; do tada se javlja šta bi se otvorilo.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Plejer za "${track.displayTitle}"')),
      );
  }
}
