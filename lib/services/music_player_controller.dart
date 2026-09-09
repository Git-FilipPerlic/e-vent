import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/track.dart';
import 'audio_playback.dart';

/// Vodi reprodukciju i **red čekanja** (MUSIC-009).
///
/// Živi u Muzika tabu, a nastupni ekran ga samo pozajmljuje — zato zvuk ne
/// prestaje kad se izađe iz nastupnog ekrana nazad na spisak.
///
/// Pravilo koje se ne krši: **dodir na numeru nikada ne pokreće zvuk.**
/// Dodir je ubacuje u red ili je postavlja kao trenutnu; zvuk kreće tek
/// velikim dugmetom.
class MusicPlayerController extends ChangeNotifier {
  MusicPlayerController({required this.playback}) {
    _subscriptions.addAll([
      playback.position.listen((value) {
        _position = value;
        _maybeFadeOut();
        _updateProgress();
        notifyListeners();
      }),
      playback.duration.listen((value) {
        _duration = value;
        _updateProgress();
        notifyListeners();
      }),
      playback.playing.listen((value) {
        _isPlaying = value;
        notifyListeners();
      }),
      // Kad numera odsvira do kraja, red sam prelazi na sledeću.
      playback.completed.listen((_) => _onCompleted()),
    ]);
  }

  final AudioPlayback playback;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Napredak stoji van widget stabla, da prsten može da se prerisava bez
  /// ponovnog građenja ekrana.
  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  final List<Track> _queue = [];
  int _currentIndex = -1;

  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;
  bool _fadeIn = false;
  bool _fadeOut = false;

  /// Da stišavanje pred kraj numere ne krene dvaput za istu numeru.
  bool _isFadingOut = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// Red čekanja, redom kojim će se svirati.
  List<Track> get queue => List.unmodifiable(_queue);

  int get currentIndex => _currentIndex;

  Track? get current =>
      _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  Duration get position => _position;
  Duration? get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get fadeIn => _fadeIn;
  bool get fadeOut => _fadeOut;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasNext => _currentIndex >= 0 && _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  /// Da li se numera može puštati i premotavati.
  bool get isReady => current != null && !_isLoading && _errorMessage == null;

  /// Pred kraj numere zvuk se sam spusti do tišine, ako je fade-out uključen.
  ///
  /// Traje isto koliko i fade-in, pa nastup ima simetrične ivice: pesma
  /// izađe iz tišine i u tišinu se vrati.
  void _maybeFadeOut() {
    if (!_fadeOut || _isFadingOut || !_isPlaying) return;

    final total = _duration;
    if (total == null || total == Duration.zero) return;

    final left = total - _position;
    if (left > JustAudioPlayback.fadeOutDuration) return;

    _isFadingOut = true;
    playback.fadeToSilence(left.isNegative ? Duration.zero : left);
  }

  void _updateProgress() {
    final total = _duration?.inMilliseconds ?? 0;
    progress.value = total == 0
        ? 0
        : (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Šta se dešava na dodir numere u spisku.
  ///
  /// - numera koja nije u redu, a ništa se ne svira → postaje trenutna
  /// - numera koja nije trenutna → ubacuje se kao **sledeća**, bez prekidanja
  /// - trenutna numera → vraća se na početak
  Future<void> onTrackTapped(Track track) async {
    if (current?.id == track.id) {
      await restartCurrent();
      return;
    }

    if (current == null) {
      _queue
        ..clear()
        ..add(track);
      await _loadAt(0);
      return;
    }

    enqueueNext(track);
  }

  /// Stavlja numeru odmah iza trenutne.
  void enqueueNext(Track track) {
    // Ista numera se ne duplira u redu — pomera se na mesto sledeće.
    _queue.removeWhere((t) => t.id == track.id && t.id != current?.id);
    if (_currentIndex >= _queue.length) _currentIndex = _queue.length - 1;

    _queue.insert(_currentIndex + 1, track);
    notifyListeners();
  }

  /// Postavlja ceo red i učitava prvu numeru, bez puštanja.
  Future<void> setQueue(List<Track> tracks) async {
    _queue
      ..clear()
      ..addAll(tracks);
    if (_queue.isEmpty) {
      _currentIndex = -1;
      notifyListeners();
      return;
    }
    await _loadAt(0);
  }

  /// Vraća trenutnu numeru na početak. Zvuk se ne pokreće sam.
  Future<void> restartCurrent() async {
    if (current == null) return;
    await playback.seek(Duration.zero);
    _position = Duration.zero;
    _updateProgress();
    notifyListeners();
  }

  Future<void> next() async {
    if (!hasNext) return;
    final wasPlaying = _isPlaying;
    await _loadAt(_currentIndex + 1);
    if (wasPlaying) await play();
  }

  Future<void> previous() async {
    // Prvo pritiskanje unazad vraća na početak numere, kao na svakom plejeru;
    // tek ako je pesma tek počela, ide se na prethodnu.
    if (_position > const Duration(seconds: 3)) {
      await restartCurrent();
      return;
    }
    if (!hasPrevious) {
      await restartCurrent();
      return;
    }
    final wasPlaying = _isPlaying;
    await _loadAt(_currentIndex - 1);
    if (wasPlaying) await play();
  }

  Future<void> _onCompleted() async {
    if (hasNext) {
      await _loadAt(_currentIndex + 1);
      await play();
      return;
    }
    // Kraj reda: numera ostaje, ali se vraća na početak i staje.
    await playback.pause();
    _isFadingOut = false;
    await restartCurrent();
  }

  Future<void> _loadAt(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _currentIndex = index;
    _isFadingOut = false;
    _position = Duration.zero;
    _duration = _queue[index].duration;
    _errorMessage = null;
    _isLoading = true;
    _updateProgress();
    notifyListeners();

    final path = _queue[index].path;
    if (path == null) {
      _isLoading = false;
      _errorMessage = 'Numera nema putanju do fajla.';
      notifyListeners();
      return;
    }

    try {
      final loaded = await playback.load(path);
      _duration = loaded ?? _queue[index].duration;
      _isLoading = false;
    } on AudioLoadException {
      _isLoading = false;
      _errorMessage = 'Numera se ne može otvoriti.';
    }
    _updateProgress();
    notifyListeners();
  }

  Future<void> play() async {
    if (!isReady) return;
    await playback.play(fadeIn: _fadeIn);
  }

  Future<void> toggle() async {
    if (!isReady) return;
    if (_isPlaying) {
      await playback.pause(fadeOut: _fadeOut);
    } else {
      _isFadingOut = false;
      await playback.play(fadeIn: _fadeIn);
    }
  }

  /// Pomera reprodukciju, uz granice numere.
  Future<void> skip(Duration by) async {
    if (!isReady) return;

    var target = _position + by;
    if (target < Duration.zero) target = Duration.zero;
    final total = _duration;
    if (total != null && target > total) target = total;

    await playback.seek(target);
    _position = target;
    _updateProgress();
    notifyListeners();
  }

  void setFadeIn(bool value) {
    _fadeIn = value;
    notifyListeners();
  }

  void setFadeOut(bool value) {
    _fadeOut = value;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    progress.dispose();
    playback.dispose();
    super.dispose();
  }
}
