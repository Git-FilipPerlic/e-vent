import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Puštanje jedne numere.
///
/// Ekran zove samo ovaj interfejs i ne zna koji je paket ispod — pa se paket
/// kasnije može zameniti bez diranja plejera, a u testu se podmetne lažni
/// plejer, jer se pravi zvuk u testu ne može pustiti.
abstract interface class AudioPlayback {
  Stream<Duration> get position;
  Stream<Duration?> get duration;
  Stream<bool> get playing;

  /// Javlja da je numera odsvirala do kraja — po tome red čekanja prelazi
  /// na sledeću.
  Stream<void> get completed;

  /// Učitava numeru i vraća njeno trajanje, ako se zna.
  /// Baca [AudioLoadException] kad numera ne može da se otvori.
  Future<Duration?> load(String path);

  /// Pušta numeru. Uz `fadeIn` zvuk kreće od tišine i penje se
  /// [JustAudioPlayback.fadeInDuration] — da uvod ne "udari" iz zvučnika.
  Future<void> play({bool fadeIn = false});

  /// Pauzira. Uz `fadeOut` zvuk se spusti do tišine pa stane — da prekid
  /// ne bude sečen usred takta.
  Future<void> pause({bool fadeOut = false});

  /// Spušta zvuk do tišine za zadato vreme, bez pauziranja.
  /// Koristi se pred kraj numere.
  Future<void> fadeToSilence(Duration over);

  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

/// Numera ne može da se otvori (obrisana, nije zvuk, ili nema dozvole).
class AudioLoadException implements Exception {
  const AudioLoadException(this.path);

  final String path;

  @override
  String toString() => 'Numera se ne može otvoriti: $path';
}

/// Prava reprodukcija, preko `just_audio`.
class JustAudioPlayback implements AudioPlayback {
  JustAudioPlayback({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Timer? _fadeTimer;

  /// Koliko traje fade-in kad je uključen.
  static const Duration fadeInDuration = Duration(seconds: 10);

  /// Koliko traje spuštanje zvuka pred kraj numere.
  static const Duration fadeOutDuration = Duration(seconds: 10);

  /// Pauza se stišava kratko — deset sekundi čekanja da muzika stane bilo bi
  /// besmisleno kad neko hoće tišinu odmah.
  static const Duration pauseFadeDuration = Duration(milliseconds: 1200);

  /// Koliko se najduže čeka da se numera otvori.
  ///
  /// Bez ovoga plejer ume da ostane zauvek na "učitava se": kad putanja ne
  /// postoji ili je fajl nedostupan, `just_audio` ne vrati ni grešku.
  static const Duration loadTimeout = Duration(seconds: 15);

  /// Na koliko koraka se pojačava zvuk. Sitniji koraci se ne čuju bolje,
  /// a troše bateriju.
  static const Duration _fadeStep = Duration(milliseconds: 200);

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<Duration?> get duration => _player.durationStream;

  @override
  Stream<bool> get playing => _player.playingStream;

  @override
  Stream<void> get completed => _player.processingStateStream
      .where((state) => state == ProcessingState.completed);

  @override
  Future<Duration?> load(String path) async {
    try {
      // Na Androidu birač fajlova vraća `content://` adresu, ne putanju
      // na disku — plejer mora da primi i jedno i drugo.
      if (path.contains('://')) {
        return await _player.setUrl(path).timeout(loadTimeout);
      }
      return await _player.setFilePath(path).timeout(loadTimeout);
    } catch (_) {
      throw AudioLoadException(path);
    }
  }

  @override
  Future<void> play({bool fadeIn = false}) async {
    _cancelFade();

    if (!fadeIn) {
      await _player.setVolume(1);
      await _player.play();
      return;
    }

    await _player.setVolume(0);
    unawaited(_player.play());
    unawaited(_fade(target: 1, over: fadeInDuration));
  }

  /// Vodi jačinu od trenutne do [target] za zadato vreme.
  ///
  /// Vraća `Future` koji se završi kad se stigne do cilja, pa pauza može da
  /// sačeka da zvuk zaista utihne.
  Future<void> _fade({required double target, required Duration over}) {
    _cancelFade();

    final start = _player.volume;
    final steps = (over.inMilliseconds / _fadeStep.inMilliseconds)
        .round()
        .clamp(1, 1000);
    var step = 0;

    final done = Completer<void>();
    _fadeTimer = Timer.periodic(_fadeStep, (timer) {
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      _player.setVolume(start + (target - start) * t);
      if (t >= 1) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
  }

  @override
  Future<void> fadeToSilence(Duration over) => _fade(target: 0, over: over);

  @override
  Future<void> pause({bool fadeOut = false}) async {
    if (fadeOut && _player.playing) {
      await _fade(target: 0, over: pauseFadeDuration);
    }
    _cancelFade();
    await _player.pause();
    // Ako je pauza pala usred fade-in-a ili posle stišavanja, zvuk bi pri
    // nastavku ostao tih — zato se jačina vraća na punu.
    await _player.setVolume(1);
  }

  @override
  Future<void> stop() async {
    _cancelFade();
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  @override
  Future<void> dispose() async {
    _cancelFade();
    await _player.dispose();
  }
}
