import 'dart:async';
import 'dart:math' as math;

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
  ///
  /// Uz `windUp` zvuk **kreće usporen pa se digne** do normalne brzine,
  /// kao ploča koja se zavrti. Suprotno od zaustavljanja na pauzi.
  Future<void> play({bool fadeIn = false, Duration? over, bool windUp = false});

  /// Pauzira. Uz `fadeOut` zvuk se spusti do tišine pa stane — da prekid
  /// ne bude sečen usred takta.
  ///
  /// Uz `windDown` zvuk se pritom i **uspori i spusti u visini tona**, kao
  /// ploča kojoj je stao platter. To je efekat, ne podešavanje: traje oko
  /// sekund i sam se vrati na normalnu brzinu, da sledeće puštanje krene
  /// kako treba.
  Future<void> pause({bool fadeOut = false, bool windDown = false});

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

  /// Brzina ploče: 1.0 je normalna, manje usporava zvuk.
  ///
  /// **Menja i visinu tona zajedno sa brzinom**, kao kad se gramofonska
  /// ploča uspori — zato se ne zove „brzina reprodukcije". Do nove vrednosti
  /// se **klizi**, ne skače: ploča se ne zaustavlja u jednom kadru.
  Future<void> setRecordSpeed(double value);

  /// Trenutna brzina ploče.
  double get recordSpeed;

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

  /// Brzina ploče, 1.0 = normalna. Pamti se da bi je i numera koja se
  /// učita kasnije nasledila — na gramofonu se platter ne ubrza sam kad se
  /// promeni ploča.
  double _recordSpeed = 1;

  /// Brzina koja je stvarno na plejeru u ovom trenutku — u toku
  /// zaustavljanja ploče se razlikuje od zadate.
  double _speedNow = 1;

  Timer? _speedTimer;

  @override
  double get recordSpeed => _recordSpeed;

  /// Koliko traje klizanje do nove brzine. Kratko koliko treba da se čuje
  /// kao usporavanje ploče, a ne kao kvar u zvuku.
  static const Duration recordGlide = Duration(milliseconds: 600);

  /// Dokle se spusti numera **koja izlazi** u preklopu: do 20%, ne do
  /// tišine (odluka od 27. septembra 2026).
  ///
  /// Kad obe strane idu do kraja, u sredini preklopa obe budu jedva čujne i
  /// nastane rupa — zvuči kao da je muzika stala. Ovako se dve numere zaista
  /// **preklope**: stara se povuče u pozadinu, ali se čuje sve do kraja
  /// prelaza, a onda utihne za tren.
  static const double crossfadeOutFloor = 0.2;

  /// Odakle kreće numera **koja ulazi** u preklopu: od 10%, ne iz tišine.
  /// Tako se odmah čuje da dolazi, umesto da se pojavi tek na pola puta.
  static const double crossfadeInFloor = 0.1;

  /// Koliko traje kratko gašenje one koja je izašla, pošto se preklop
  /// završi. Sa 20% na nulu odjednom bi se čuo „klik".
  static const Duration crossfadeTail = Duration(milliseconds: 250);

  /// Koliko traje zaustavljanje ploče na pauzi.
  ///
  /// Duže nego što deluje potrebno, namerno: kratak pad se čuje kao
  /// greška u zvuku, a ovoliko se čuje kao potez (produženo 28.
  /// septembra 2026, na zahtev da bude izraženije).
  static const Duration recordStopGlide = Duration(milliseconds: 1200);

  /// Koliko traje zavrtanje ploče pri puštanju, kad `Fade` nije uključen.
  static const Duration recordStartGlide = Duration(milliseconds: 700);

  /// Dokle se spusti brzina pri zaustavljanju.
  ///
  /// Nije nula: plejer na nuli ne svira ništa, pa bi se poslednji deo
  /// zvuka izgubio. Spušteno sa 0,2 na 0,08 (28. septembra 2026) — na
  /// dvadeset posto se pad jedva čuje, a ovde treba da zvuči kao ploča
  /// kojoj je stao platter.
  static const double recordStopSpeed = 0.08;

  @override
  Future<void> setRecordSpeed(double value) async {
    _recordSpeed = value.clamp(0.25, 2.0);
    await _glideSpeed(_recordSpeed, recordGlide);
  }

  /// Gasi numeru koja je izašla iz preklopa — sa poda na tišinu, pa stop.
  Future<void> _tailOut(AudioPlayer player) async {
    final steps =
        (crossfadeTail.inMilliseconds / _fadeStep.inMilliseconds).round().clamp(
          1,
          100,
        );
    final start = crossfadeOutFloor * _masterVolume;
    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(_fadeStep);
      await player.setVolume(start * (1 - step / steps));
    }
    await player.stop();
  }

  /// Vodi brzinu (i visinu tona sa njom) od trenutne do zadate.
  Future<void> _glideSpeed(double target, Duration over) {
    _speedTimer?.cancel();

    final start = _speedNow;
    _speedNow = target;
    if ((target - start).abs() < 0.001 || over == Duration.zero) {
      return _applySpeed(_active, target);
    }

    final steps = (over.inMilliseconds / _fadeStep.inMilliseconds).round().clamp(
      1,
      1000,
    );
    var step = 0;
    final done = Completer<void>();
    _speedTimer = Timer.periodic(_fadeStep, (timer) {
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      _applySpeed(_active, start + (target - start) * t);
      if (t >= 1) {
        timer.cancel();
        _speedTimer = null;
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
  }

  /// Brzina i visina tona idu zajedno — to je ono što zvuči kao ploča.
  Future<void> _applySpeed(AudioPlayer player, double value) async {
    await player.setSpeed(value);
    await player.setPitch(value);
  }

  @override
  bool get isFading => _fadeTimer != null || _crossfadeTimer != null;

  Timer? _fadeTimer;
  Timer? _crossfadeTimer;
  bool _hasPreloaded = false;

  /// Podrazumevani ulazak iz tišine, kad se dužina ne zada.
  /// Kontroler je uvek zadaje — broj se bira na Muzika tabu (1 / 4 / 8 s).
  static const Duration fadeInDuration = Duration(seconds: 10);

  /// Koliko traje spuštanje zvuka pred kraj numere.
  static const Duration fadeOutDuration = Duration(seconds: 10);

  /// Pauza se stišava kratko — deset sekundi čekanja da muzika stane bilo bi
  /// besmisleno kad neko hoće tišinu odmah.
  /// Koliko traje izlazak u tišinu kad se pritisne pauza, uz uključen `Fade`.
  ///
  /// **Tri sekunde** (skraćeno sa šest, 27. septembra 2026). Dovoljno da se
  /// muzika pred publikom povuče kao namera, a ne kao kvar; šest se u radu
  /// pokazalo kao predugo čekanje da zvuk utihne.
  static const Duration pauseFadeDuration = Duration(seconds: 3);

  /// Raspon pretapanja u decibelima.
  ///
  /// **Jačina koja se čuje ne prati amplitudu pravolinijski.** Pola amplitude
  /// nije pola glasnoće nego otprilike −6 dB, što se jedva primeti; zato je
  /// pravolinijsko stišavanje zvučalo kao da numera koja izlazi uopšte ne
  /// izlazi, a ona koja ulazi kao da upada. Rampa je zato pravolinijska **u
  /// decibelima**: svaki deo puta oduzme isto toliko glasnoće, pa se izlazak
  /// čuje od prve sekunde, a ulazak se penje mirno.
  ///
  /// 45 dB je izabrano namerno: 60 bi ostavilo predugu tišinu na početku
  /// ulaska, a 30 se i dalje čuje kao skok.
  static const double _fadeRangeDb = 45;

  /// Amplituda za napredak [t] (0..1) po rampi iz [_fadeRangeDb].
  static double fadeCurve(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return math.pow(10, (t - 1) * _fadeRangeDb / 20).toDouble();
  }

  /// **Pauza nikad ne seče naglo.** I kad je `Fade` isključen, zvuk se spusti
  /// za pola sekunde — dovoljno da nestane onaj „klik" na prekidu, a
  /// prekratko da bi se osetilo kao pretapanje. Sa uključenim `Fade` izlazak
  /// traje [pauseFadeDuration].
  static const Duration shortPauseFade = Duration(milliseconds: 500);

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
    final loaded = await _open(_active, path);
    // Nova numera nasleđuje brzinu ploče: platter se ne ubrzava sam.
    _speedNow = _recordSpeed;
    await _applySpeed(_active, _recordSpeed);
    return loaded;
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
    await _applySpeed(incoming, _recordSpeed);
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
      // Obe strane idu po istoj rampi, ali **nijedna do kraja**: ona koja
      // izlazi staje na 20%, a ona koja ulazi kreće od 10%. Bez toga se
      // u sredini preklopa obe jedva čuju i nastane rupa.
      incoming.setVolume(
        (crossfadeInFloor + (1 - crossfadeInFloor) * fadeCurve(t)) *
            _masterVolume,
      );
      outgoing.setVolume(
        (crossfadeOutFloor + (1 - crossfadeOutFloor) * fadeCurve(1 - t)) *
            _masterVolume,
      );
      if (t >= 1) {
        timer.cancel();
        _crossfadeTimer = null;
        // Sa 20% na nulu odjednom bi se čuo prekid, pa stara numera još
        // četvrt sekunde utihne pre nego što stane.
        unawaited(_tailOut(outgoing));
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
      // Rampa ide po glasnoći koja se čuje, a ne po amplitudi; kad se
      // zvuk spušta, ista kriva se čita unazad.
      final eased = target > start ? fadeCurve(t) : 1 - fadeCurve(1 - t);
      player.setVolume(start + (target - start) * eased);
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
  Future<void> play({
    bool fadeIn = false,
    Duration? over,
    bool windUp = false,
  }) async {
    _fadeTimer?.cancel();

    if (!fadeIn) {
      await _active.setVolume(_masterVolume);
      if (windUp) {
        // Ploča se zavrti: zvuk kreće usporen i u niskom tonu, pa se digne
        // do normalne brzine. Suprotno od zaustavljanja na pauzi.
        await _applySpeed(_active, recordStopSpeed);
        _speedNow = recordStopSpeed;
        await _active.play();
        unawaited(_glideSpeed(_recordSpeed, recordStartGlide));
        return;
      }
      await _active.play();
      return;
    }

    await _active.setVolume(0);
    unawaited(_active.play());
    unawaited(_fade(target: _masterVolume, over: over ?? fadeInDuration));
  }

  @override
  Future<void> pause({bool fadeOut = false, bool windDown = false}) async {
    if (_active.playing) {
      if (windDown) {
        // Ploča staje: brzina i jačina se spuštaju zajedno, pa se u istom
        // trenutku i utiša i uspori. Zvuk se tako „izduva", kao na gramofonu.
        final glide = _glideSpeed(recordStopSpeed, recordStopGlide);
        await _fade(target: 0, over: recordStopGlide);
        await glide;
      } else {
        await _fade(
          target: 0,
          over: fadeOut ? pauseFadeDuration : shortPauseFade,
        );
      }
    }
    _cancelFades();
    _speedTimer?.cancel();
    _speedTimer = null;
    await _active.pause();
    // Sledeće puštanje kreće normalnom brzinom, ma kako pauza izgledala.
    _speedNow = _recordSpeed;
    await _applySpeed(_active, _recordSpeed);
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
    _speedTimer?.cancel();
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
