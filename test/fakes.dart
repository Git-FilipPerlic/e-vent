import 'dart:async';

import 'package:event_app/services/audio_playback.dart';

/// Lažni plejer: pravi zvuk se u testu ne može pustiti, pa se vodi samo
/// evidencija šta je od plejera traženo.
class FakePlayback implements AudioPlayback {
  FakePlayback({this.failsToLoad = false, this.trackDuration});

  final bool failsToLoad;
  final Duration? trackDuration;

  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<void>.broadcast();

  final List<String> loadedPaths = [];
  int playCalls = 0;

  /// Zadata jačina — testovi je čitaju da provere stepenike L/E/F.
  double _masterVolume = 1;

  /// Da li je pretapanje u toku — testovi ga postavljaju ručno.
  bool fading = false;

  /// Koliko je puta traženo stišavanje pred kraj numere.
  int fadeToSilenceCalls = 0;

  @override
  bool get isFading => fading;

  @override
  double get masterVolume => _masterVolume;

  @override
  Future<void> setMasterVolume(double value) async {
    _masterVolume = value;
  }
  int pauseCalls = 0;
  Duration? lastSeek;
  bool? lastFadeIn;
  bool? lastFadeOut;
  Duration? lastFadeToSilence;
  String? preloadedPath;
  Duration? lastCrossfade;
  int crossfadeCalls = 0;
  bool disposed = false;

  String? get loadedPath => loadedPaths.isEmpty ? null : loadedPaths.last;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration?> get duration => _duration.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<Duration?> load(String path) async {
    if (failsToLoad) throw AudioLoadException(path);
    preloadedPath = null;
    loadedPaths.add(path);
    return trackDuration;
  }

  @override
  Future<void> play({bool fadeIn = false}) async {
    playCalls++;
    lastFadeIn = fadeIn;
    _playing.add(true);
  }

  @override
  Future<void> pause({bool fadeOut = false}) async {
    pauseCalls++;
    lastFadeOut = fadeOut;
    _playing.add(false);
  }

  @override
  Future<void> fadeToSilence(Duration over) async {
    lastFadeToSilence = over;
    fadeToSilenceCalls++;
  }

  @override
  Future<void> preload(String path) async {
    if (failsToLoad) throw AudioLoadException(path);
    preloadedPath = path;
  }

  @override
  bool get hasPreloaded => preloadedPath != null;

  @override
  Future<void> crossfadeToPreloaded(Duration over) async {
    if (preloadedPath == null) return;
    crossfadeCalls++;
    lastCrossfade = over;
    loadedPaths.add(preloadedPath!);
    preloadedPath = null;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    _position.add(position);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _position.close();
    await _duration.close();
    await _playing.close();
    await _completed.close();
  }

  /// Pomera reprodukciju, kao da je pesma odmakla.
  void emitPosition(Duration value) => _position.add(value);

  /// Javlja da je numera odsvirala do kraja.
  void emitCompleted() => _completed.add(null);
}
