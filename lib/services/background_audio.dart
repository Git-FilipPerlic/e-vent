import 'package:audio_service/audio_service.dart';

import 'music_player_controller.dart';

/// Veza između reprodukcije i **notifikacije sa kontrolama** (MUSIC-019).
///
/// Muzika svira i kad aplikacija nije na ekranu, a u notifikaciji i na
/// zaključanom ekranu stoje dugmad: pusti, pauziraj, sledeća, prethodna.
///
/// **Zašto `audio_service`, a ne `just_audio_background`:** onaj jednostavniji
/// paket radi samo sa **jednim** plejerom, a naš ih drži dva zbog preklapanja
/// numera. `audio_service` dozvoljava više plejera, pa se preklapanje ne gubi.
///
/// Ovaj sloj **ne pušta zvuk sam** — samo prosleđuje komande kontroleru i
/// javlja sistemu šta se trenutno dešava.
class BackgroundAudioHandler extends BaseAudioHandler {
  /// Kontroler stiže tek kad se otvori Muzika tab, pa se postavlja naknadno.
  MusicPlayerController? _controller;

  void attach(MusicPlayerController controller) {
    _controller?.removeListener(_publish);
    _controller = controller;
    controller.addListener(_publish);
    _publish();
  }

  void detach(MusicPlayerController controller) {
    if (!identical(_controller, controller)) return;
    controller.removeListener(_publish);
    _controller = null;
  }

  /// Javlja sistemu šta svira i dokle je stiglo.
  void _publish() {
    final controller = _controller;
    if (controller == null) return;

    final track = controller.sounding ?? controller.selected;
    if (track != null) {
      mediaItem.add(
        MediaItem(
          id: track.path ?? track.id,
          title: track.displayTitle,
          artist: track.artist,
          duration: controller.duration,
        ),
      );
    }

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (controller.isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: controller.isLoading
            ? AudioProcessingState.loading
            : AudioProcessingState.ready,
        playing: controller.isPlaying,
        updatePosition: controller.position,
      ),
    );
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.toggle();

  @override
  Future<void> skipToNext() async => _controller?.next();

  @override
  Future<void> skipToPrevious() async => _controller?.previous();

  @override
  Future<void> seek(Duration position) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.skip(position - controller.position);
  }

  @override
  Future<void> stop() async {
    final controller = _controller;
    if (controller != null && controller.isPlaying) {
      await controller.toggle();
    }
    await super.stop();
  }
}
