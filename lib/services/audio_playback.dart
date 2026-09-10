import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Puštanje numera za nastup.
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
  ///
  /// [over] skraćuje ili produžava taj ulazak; `null` znači uobičajenih
  /// deset sekundi.
  Future<void> play({bool fadeIn = false, Duration? over});

  /// Pauzira. Uz `fadeOut` zvuk se spusti do tišine pa stane — da prekid
  /// ne bude sečen usred takta.
  Future<void> pause({bool fadeOut = false});

  /// Spušta zvuk do tišine za zadato vreme, bez pauziranja.
  /// Koristi se pred kraj numere.
  Future<void> fadeToSilence(Duration over);

  /// Učitava **sledeću** numeru u drugi plejer, bez diranja one koja svira.
  ///
  /// Bez ovoga bi prelaz zapinjao: otvaranje fajla traje, a preklapanje nema
  /// vremena da čeka.
  Future<void> preload(String path);

  /// Da li je sledeća numera spremna za preklapanje.
  bool get hasPreloaded;

  /// Da li je pretapanje (ulazak, izlazak ili preklapanje) u toku.
  ///
  /// **Premotavanje ga ne prekida** — to je i poenta: dok pretapanje traje,
  /// numera se dovodi na pravo mesto, a da se to u zvuku ne primeti.
  bool get isFading;

  /// Zadata jačina zvuka, 0..1.
  ///
  /// **Sva pretapanja idu do ove vrednosti, ne do pune jačine** — inače bi
  /// stišana muzika na svakom prelazu skočila nazad na 100%.
  double get masterVolume;

  Future<void> setMasterVolume(double value);

  /// Preklapa zvuk sa numere koja svira na unapred učitanu: prva se spušta,
  /// druga se penje, obe sviraju u isto vreme.
  ///
  /// Posle ovoga unapred učitana numera postaje trenutna.
  Future<void> crossfadeToPreloaded(Duration over);

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
///
/// **Drži dva plejera, ne jedan.** Preklapanje traži da dve numere sviraju u
/// istom trenutku — dok se jedna spušta, druga se penje. Zato jedan plejer
/// svira, a drugi u pozadini već ima učitanu sledeću numeru i čeka; posle
/// preklapanja zamene uloge.
///
/// Spolja se i dalje vidi jedan plejer: `position`, `duration`, `playing` i
/// `completed` uvek prate onaj koji je trenutno aktivan.
class JustAudioPlayback implements AudioPlayback {
  JustAudioPlayback({AudioPlayer? primary, AudioPlayer? secondary})
    : _players = [primary ?? AudioPlayer(), secondary ?? AudioPlayer()] {
    _bindActive();
  }

  final List<AudioPlayer> _players;
  int _activeIndex = 0;

  AudioPlayer get _active => _players[_activeIndex];
  AudioPlayer get _idle => _players[1 - _activeIndex];

  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<void>.broadcast();

  List<StreamSubscription<dynamic>> _bindings = [];

  /// Zadata jačina; 1 je puna. Sve što se dole postavlja množi se njome.
  double _masterVolume = 1;

  @override
  double get masterVolume => _masterVolume;

  @override
  Future<void> setMasterVolume(double value) async {
    _masterVolume = value.clamp(0.0, 1.0);
    // Ako je usred pretapanja, sledeći korak će sam uzeti novu vrednost;
    // inače se primenjuje odmah, da se promena čuje na dodir.
    if (_fadeTimer == null && _crossfadeTimer == null) {
      await _active.setVolume(_masterVolume);
    }
  }

  @override
  bool get isFading => _fadeTimer != null || _crossfadeTimer != null;

  Timer? _fadeTimer;
  Timer? _crossfadeTimer;
  bool _hasPreloaded = false;

  /// Koliko traje fade-in kad je uključen.
  static const Duration fadeInDuration = Duration(seconds: 10);

  /// Kraći ulazak, za obično plej dugme u traci. Deset sekundi je tamo
  /// predugo: traka služi za usputno paljenje, a ne za uvod pred publiku.
  static const Duration quickFadeDuration = Duration(seconds: 5);

  /// Koliko traje spuštanje zvuka pred kraj numere.
  static const Duration fadeOutDuration = Duration(seconds: 10);

  /// Koliko traje preklapanje dve numere.
  /// Preklapanje traje **isto koliko i ulazak iz tišine — 10 sekundi**.
  ///
  /// Ranije je bilo 6, suprotno specifikaciji. Duže nije samo lepše: dok
  /// pretapanje traje, izvođač još može da premota novu numeru na pravo
  /// mesto, a greška se u tom preklopu teže čuje. Kratko pretapanje mu ne
  /// ostavlja vremena za to.
  static const Duration crossfadeDuration = Duration(seconds: 10);

  /// Pauza se stišava kratko — deset sekundi čekanja da muzika stane bilo bi
  /// besmisleno kad neko hoće tišinu odmah.
  static const Duration pauseFadeDuration = Duration(milliseconds: 1200);

  /// Koliko se najduže čeka da se numera otvori.
  ///
  /// Bez ovoga plejer ume da ostane zauvek na "učitava se": kad putanja ne
  /// postoji ili je fajl nedostupan, `just_audio` ne vrati ni grešku.
  static const Duration loadTimeout = Duration(seconds: 15);

  /// Na koliko koraka se menja jačina. Sitniji koraci se ne čuju bolje,
  /// a troše bateriju.
  static const Duration _fadeStep = Duration(milliseconds: 200);

  /// Streamovi prate aktivni plejer; pri zameni uloga se prevezuju.
  void _bindActive() {
    for (final binding in _bindings) {
      binding.cancel();
    }
    _bindings = [
      _active.positionStream.listen(_position.add),
      _active.durationStream.listen(_duration.add),
      _active.playingStream.listen(_playing.add),
      _active.processingStateStream
          .where((state) => state == ProcessingState.completed)
          .listen((_) => _completed.add(null)),
    ];
  }

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration?> get duration => _duration.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  bool get hasPreloaded => _hasPreloaded;

  /// Otvara numeru na datom plejeru. Prima i putanju na disku i adresu sa
  /// shemom (`content://` sa Androidovog birača, `file://`, `https://`).
  Future<Duration?> _open(AudioPlayer player, String path) async {
    try {
      if (path.contains('://')) {
        return await player.setUrl(path).timeout(loadTimeout);
      }
      return await player.setFilePath(path).timeout(loadTimeout);
    } catch (_) {
      throw AudioLoadException(path);
    }
  }

  @override
  Future<Duration?> load(String path) async {
    _cancelFades();
    // Nova numera poništava pripremljeno preklapanje.
    _hasPreloaded = false;
    await _idle.stop();
    await _active.setVolume(_masterVolume);
    return _open(_active, path);
  }

  @override
  Future<void> preload(String path) async {
    await _idle.setVolume(0);
    await _open(_idle, path);
    _hasPreloaded = true;
  }

  @override
  Future<void> crossfadeToPreloaded(Duration over) async {
    if (!_hasPreloaded) return;

    _crossfadeTimer?.cancel();
    final outgoing = _active;
    final incoming = _idle;

    await incoming.setVolume(0);
    unawaited(incoming.play());

    // Uloge se menjaju odmah: vreme i prsten od ovog trenutka prate novu
    // numeru, jer je ona ta koja se sluša.
    _activeIndex = 1 - _activeIndex;
    _hasPreloaded = false;
    _bindActive();

    final steps = (over.inMilliseconds / _fadeStep.inMilliseconds)
        .round()
        .clamp(1, 1000);
    var step = 0;

    _crossfadeTimer = Timer.periodic(_fadeStep, (timer) {
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      incoming.setVolume(t * _masterVolume);
      outgoing.setVolume((1 - t) * _masterVolume);
      if (t >= 1) {
        timer.cancel();
        _crossfadeTimer = null;
        outgoing.stop();
      }
    });
  }

  /// Vodi jačinu aktivnog plejera od trenutne do [target] za zadato vreme.
  ///
  /// Vraća `Future` koji se završi kad se stigne do cilja, pa pauza može da
  /// sačeka da zvuk zaista utihne.
  Future<void> _fade({required double target, required Duration over}) {
    _fadeTimer?.cancel();

    final player = _active;
    final start = player.volume;
    final steps = (over.inMilliseconds / _fadeStep.inMilliseconds)
        .round()
        .clamp(1, 1000);
    var step = 0;

    final done = Completer<void>();
    _fadeTimer = Timer.periodic(_fadeStep, (timer) {
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      player.setVolume(start + (target - start) * t);
      if (t >= 1) {
        timer.cancel();
        _fadeTimer = null;
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
  }

  @override
  Future<void> fadeToSilence(Duration over) => _fade(target: 0, over: over);

  @override
  Future<void> play({bool fadeIn = false, Duration? over}) async {
    _fadeTimer?.cancel();

    if (!fadeIn) {
      await _active.setVolume(_masterVolume);
      await _active.play();
      return;
    }

    await _active.setVolume(0);
    unawaited(_active.play());
    unawaited(_fade(target: _masterVolume, over: over ?? fadeInDuration));
  }

  @override
  Future<void> pause({bool fadeOut = false}) async {
    if (fadeOut && _active.playing) {
      await _fade(target: 0, over: pauseFadeDuration);
    }
    _cancelFades();
    await _active.pause();
    // Ako je pauza pala usred pretapanja, zvuk bi pri nastavku ostao tih —
    // zato se jačina vraća na zadatu.
    await _active.setVolume(_masterVolume);
  }

  @override
  Future<void> stop() async {
    _cancelFades();
    await _active.stop();
    await _idle.stop();
    _hasPreloaded = false;
  }

  @override
  Future<void> seek(Duration position) => _active.seek(position);

  void _cancelFades() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
  }

  @override
  Future<void> dispose() async {
    _cancelFades();
    for (final binding in _bindings) {
      await binding.cancel();
    }
    await _position.close();
    await _duration.close();
    await _playing.close();
    await _completed.close();
    for (final player in _players) {
      await player.dispose();
    }
  }
}
