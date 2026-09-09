import 'dart:async';

import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/audio_playback.dart';
import '../theme/app_theme.dart';
import '../widgets/music/edge_progress_ring.dart';
import '../widgets/music/track_tile.dart';

/// Plejer za jednu numeru.
///
/// Ovde i samo ovde kreće zvuk — i to tek kad se pritisne veliko dugme.
/// Prsten po ivici ekrana pokazuje dokle je pesma stigla; u sredini stoji
/// vreme, jer prsten je dopuna, ne zamena za brojku.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.track, this.playback});

  final Track track;

  /// Ubacuje se u testu; u aplikaciji se pravi sam.
  final AudioPlayback? playback;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final AudioPlayback _playback = widget.playback ?? JustAudioPlayback();

  /// Napredak se drži van widget stabla, da prsten može da se prerisava
  /// bez ponovnog građenja ekrana.
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;
  bool _fadeIn = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final path = widget.track.path;
    if (path == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Numera nema putanju do fajla.';
      });
      return;
    }

    _subscriptions.add(
      _playback.position.listen((position) {
        if (!mounted) return;
        setState(() => _position = position);
        _updateProgress();
      }),
    );
    _subscriptions.add(
      _playback.duration.listen((duration) {
        if (!mounted) return;
        setState(() => _duration = duration);
        _updateProgress();
      }),
    );
    _subscriptions.add(
      _playback.playing.listen((playing) {
        if (!mounted) return;
        setState(() => _isPlaying = playing);
      }),
    );

    try {
      final duration = await _playback.load(path);
      if (!mounted) return;
      setState(() {
        _duration = duration ?? widget.track.duration;
        _isLoading = false;
      });
    } on AudioLoadException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Numera se ne može otvoriti.';
      });
    }
  }

  void _updateProgress() {
    final total = _duration?.inMilliseconds ?? 0;
    _progress.value = total == 0
        ? 0
        : (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _playback.pause();
    } else {
      await _playback.play(fadeIn: _fadeIn);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _progress.dispose();
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: EdgeProgressRing(
          progress: _progress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Nazad na spisak',
                  ),
                ),
                const Spacer(),
                Text(
                  widget.track.displayTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.track.hasArtist) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.track.artist!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                // Vreme se ne animira — brojka koja treperi svake sekunde smeta.
                Text(
                  '${TrackTile.formatDuration(_position)}'
                  ' / ${TrackTile.formatDuration(_duration)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _playButton(theme),
                const SizedBox(height: AppSpacing.lg),
                _fadeInSwitch(theme),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playButton(ThemeData theme) {
    if (_isLoading) {
      return const SizedBox(
        width: 96,
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _errorMessage;
    if (error != null) {
      return Column(
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
      );
    }

    return Semantics(
      button: true,
      label: _isPlaying ? 'Pauza' : 'Pusti',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.accent,
        ),
        child: SizedBox(
          width: 120,
          height: 120,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: Icon(
                _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 64,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fadeInSwitch(ThemeData theme) {
    return SwitchListTile(
      value: _fadeIn,
      onChanged: (value) => setState(() => _fadeIn = value),
      title: Text(
        'Fade in 10 sek',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Zvuk kreće iz tišine i penje se',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      activeThumbColor: AppColors.accent,
      contentPadding: EdgeInsets.zero,
    );
  }
}
