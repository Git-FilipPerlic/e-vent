import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/track.dart';
import 'audio_playback.dart';
import 'waveform_service.dart';

/// Jačina zvuka u tri koraka.
///
/// Namerno **tri stepenika, ne klizač**: na nastupu se ne pogađa tačan
/// procenat, nego se bira između „puno", „pola" i „tiho u pozadini".
/// Prikazuje se **jednim slovom**, jer za više nema mesta u traci.
/// Vrednosti su namerno **razmaknute nisko**: glasnoća se ne čuje linearno.
/// Pola amplitude ne zvuči kao pola jačine, nego tek malo tiše — zato su
/// stepenici spušteni na 35% i 5%, gde se razlika zaista čuje.
enum VolumeStep {
  l('L', 1.0),
  e('E', 0.35),
  f('F', 0.05);

  const VolumeStep(this.label, this.value);

  /// Slovo koje stoji na dugmetu.
  final String label;

  /// Jačina, 0..1.
  final double value;

  /// Sledeći stepenik u krug: L → E → F → L.
  VolumeStep get next => VolumeStep.values[(index + 1) % VolumeStep.values.length];
}

/// Koliko traje **ulazak iz tišine**, kad je `Fade` uključen.
///
/// Bira se dodirom na broj, isto kao L / E / F za jačinu (odluka od
/// 27. septembra 2026). Ranije je bio fiksan: 10 sekundi sa velikog dugmeta,
/// 5 iz trake uz spisak. Otkad se broj bira jednim dodirom, ta dva različita
/// ulaska nemaju smisla — važi ono što piše na dugmetu.
///
/// Ista dužina važi i za **preklapanje** dve numere, kako je i do sada bilo
/// vezano: preklapanje traje koliko i ulazak iz tišine. Izlazak na pauzu je
/// druga stvar i ostaje 6 sekundi.
enum FadeLength {
  s1('1', Duration(seconds: 1)),
  s4('4', Duration(seconds: 4)),
  s8('8', Duration(seconds: 8));

  const FadeLength(this.label, this.duration);

  /// Broj koji stoji na dugmetu.
  final String label;

  final Duration duration;

  /// Sledeći stepenik u krug: 1 → 4 → 8 → 1.
  FadeLength get next =>
      FadeLength.values[(index + 1) % FadeLength.values.length];
}

/// Brzina ploče — usporavanje zvuka kao na gramofonu.
///
/// Brzina i visina tona idu zajedno, pa numera zvuči kao ploča kojoj je
/// usporen platter, a ne kao snimak pušten sporije. Do nove brzine se klizi
/// za pola sekunde, da se čuje kao pokret, a ne kao prekid.
///
/// Bira se dodirom, u krug, kao jačina i dužina ulaska iz tišine.
enum RecordSpeed {
  normal('1.0', 1.0),
  slow('0.9', 0.9),
  slower('0.8', 0.8),
  slowest('0.7', 0.7);

  const RecordSpeed(this.label, this.value);

  /// Broj koji stoji na dugmetu.
  final String label;

  final double value;

  /// Da li je zvuk usporen — dugme je tada u boji.
  bool get isSlowed => this != RecordSpeed.normal;

  /// Sledeći stepenik u krug: 1.0 → 0.9 → 0.8 → 0.7 → 1.0.
  RecordSpeed get next =>
      RecordSpeed.values[(index + 1) % RecordSpeed.values.length];
}

/// Vodi reprodukciju i red čekanja.
///
/// Živi u Muzika tabu, a nastupni ekran ga samo pozajmljuje — zato zvuk ne
/// prestaje kad se izađe iz nastupnog ekrana nazad na spisak.
///
/// **Dve stvari se namerno razlikuju:**
///
/// - [selected] — numera koju si dodirnuo u spisku. Nju će pustiti veliko
///   dugme. Dodir nikada ne pokreće zvuk.
/// - [sounding] — numera koja se u tom trenutku čuje.
///
/// Dok ništa ne svira, to je ista numera. Čim nešto svira, dodir na drugu
/// pesmu samo **priprema** tu pesmu: ono što svira se ne seče. Veliki „play"
/// tada prelazi na pripremljenu — uz preklapanje ako je `fade` uključen,
/// inače odmah.
class MusicPlayerController extends ChangeNotifier {
  MusicPlayerController({required this.playback, WaveformService? waveforms})
    : _waveforms = waveforms ?? WaveformService() {
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

  final WaveformService _waveforms;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Napredak stoji van widget stabla, da prsten može da se prerisava bez
  /// ponovnog građenja ekrana.
  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  /// Talasni oblik izabrane numere; `null` dok se ne izvuče iz fajla.
  /// Stoji van widget stabla, kao i napredak — prsten ga čita direktno.
  final ValueNotifier<List<double>?> waveform =
      ValueNotifier<List<double>?>(null);

  final List<Track> _queue = [];

  /// Numera koju je korisnik izabrao dodirom — nju pušta veliko dugme.
  int _selectedIndex = -1;

  /// Numera koja se čuje. `-1` kad ništa ne svira.
  int _soundingIndex = -1;

  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;

  /// Jedan prekidač za sve pretapanje: ulazak iz tišine, izlazak u tišinu i
  /// preklapanje dve numere. Jedno dugme umesto tri — na nastupu se ne bira
  /// između tri prekidača.
  bool _fade = false;

  /// Srednji stepenik je podrazumevan: 1 s je gotovo rez, 8 s je uvod
  /// pred publiku, a 4 s je ono što najčešće treba.
  FadeLength _fadeLength = FadeLength.s4;

  RecordSpeed _recordSpeed = RecordSpeed.normal;

  /// Da stišavanje pred kraj numere ne krene dvaput za istu numeru.
  bool _isFadingOut = false;

  VolumeStep _volume = VolumeStep.l;

  bool _isLoading = false;
  String? _errorMessage;

  /// Dok prst vuče po prstenu, pozicija sa plejera se ne upisuje u prsten —
  /// inače bi linija skakala napred-nazad ispod prsta.
  bool _isScrubbing = false;

  /// Red čekanja, redom kojim će se svirati.
  List<Track> get queue => List.unmodifiable(_queue);

  /// Numera koju je korisnik izabrao; nju pušta veliko dugme.
  Track? get selected => _at(_selectedIndex);

  /// Numera koja se čuje, ako se nešto čuje.
  Track? get sounding => _at(_soundingIndex);

  /// Da li se izabrana numera razlikuje od one koja svira.
  bool get isAnotherSounding =>
      _soundingIndex >= 0 && _soundingIndex != _selectedIndex;

  Track? _at(int index) =>
      index >= 0 && index < _queue.length ? _queue[index] : null;

  Duration get position => _position;
  Duration? get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get fade => _fade;

  FadeLength get fadeLength => _fadeLength;

  RecordSpeed get recordSpeed => _recordSpeed;

  /// Trenutna jačina zvuka.
  VolumeStep get volume => _volume;

  /// Prebacuje na sledeći stepenik jačine: L → E → F → L.
  /// Sledeća brzina ploče, u krug. Zvuk do nje klizi, ne skače.
  Future<void> cycleRecordSpeed() async {
    _recordSpeed = _recordSpeed.next;
    notifyListeners();
    await playback.setRecordSpeed(_recordSpeed.value);
  }

  /// Sledeća dužina ulaska iz tišine, u krug.
  void cycleFadeLength() {
    _fadeLength = _fadeLength.next;
    notifyListeners();
  }

  Future<void> cycleVolume() async {
    _volume = _volume.next;
    notifyListeners();
    await playback.setMasterVolume(_volume.value);
  }

  /// Talasni oblik bilo koje numere sa spiska — za ekran talasnog oblika.
  ///
  /// Ide kroz isti keš kao talas izabrane numere, pa se ista pesma ne
  /// obrađuje dvaput. `null` kad fajl ne može da se pročita.
  Future<List<double>?> amplitudesFor(
    Track track, {
    void Function(double progress)? onProgress,
  }) async {
    final path = track.path;
    if (path == null) return null;
    return _waveforms.amplitudes(path, onProgress: onProgress);
  }

  /// Pauza i nastavak **numere koja svira** — dugme u kartici „Sada svira".
  ///
  /// Za razliku od [toggle], ne gleda koja je numera izabrana: u God mode-u
  /// izabrana je obično sledeća, a dugme za pauzu ne sme da pređe na nju.
  Future<void> togglePauseSounding() async {
    if (sounding == null) return;
    if (_isPlaying) {
      await playback.pause(fadeOut: _fade, windDown: !_fade);
    } else {
      await playback.play(fadeIn: _fade, over: _fadeLength.duration);
    }
    notifyListeners();
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasNext => _selectedIndex >= 0 && _selectedIndex < _queue.length - 1;
  bool get hasPrevious => _selectedIndex > 0;

  /// Da li se izabrana numera može pustiti i premotavati.
  bool get isReady => selected != null && !_isLoading && _errorMessage == null;

  void _updateProgress() {
    if (_isScrubbing) return;
    final total = _duration?.inMilliseconds ?? 0;
    progress.value = total == 0
        ? 0
        : (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Prst je spušten na prsten.
  void beginScrub() {
    if (!isReady) return;
    _isScrubbing = true;
  }

  /// Prst se pomera po prstenu: linija ga prati odmah, zvuk još ne.
  void updateScrub(double fraction) {
    if (!_isScrubbing) return;
    progress.value = fraction.clamp(0.0, 1.0);
  }

  /// Prst je podignut — tek tada se pesma zaista premota.
  ///
  /// Premotavanje se ne radi u toku vučenja: svako pomeranje bi tražilo novo
  /// otvaranje mesta u fajlu, pa bi zvuk krčao.
  Future<void> endScrub(double fraction) async {
    if (!_isScrubbing) return;
    _isScrubbing = false;

    final total = _duration;
    if (total == null || total == Duration.zero) return;

    final target = total * fraction.clamp(0.0, 1.0);
    await playback.seek(target);
    _position = target;
    _isFadingOut = false;
    _updateProgress();
    notifyListeners();
  }

  /// Pred kraj numere zvuk se sam spusti do tišine, ako je pretapanje
  /// uključeno i ako iza nje ne ide preklapanje na sledeću.
  void _maybeFadeOut() {
    if (!_fade || _isFadingOut || !_isPlaying) return;
    // Usred preklapanja se ne dira jačina: dva pretapanja bi se otimala oko
    // istog plejera, pa bi zvuk poskakivao.
    if (playback.isFading) return;

    final total = _duration;
    if (total == null || total == Duration.zero) return;

    final left = total - _position;
    if (left > JustAudioPlayback.fadeOutDuration) return;

    _isFadingOut = true;
    playback.fadeToSilence(left.isNegative ? Duration.zero : left);
  }

  /// Gde je mesto „sledeća": odmah iza numere koja svira.
  ///
  /// Dok ništa ne svira, to je vrh reda.
  int get _nextSlot => _soundingIndex >= 0 ? _soundingIndex + 1 : 0;

  /// Šta se dešava na dodir numere u spisku.
  ///
  /// **Dodir nikada ne pušta zvuk.** Uvek radi jedno te isto: stavlja tu
  /// numeru na mesto **sledeća**, odmah iza one koja svira. Odatle je uzima
  /// veliko dugme na nastupnom ekranu.
  ///
  /// - numera koja je već negde u redu se **premešta** na to mesto
  /// - **dodir na numeru koja svira dodaje još jednu njenu kopiju** odmah iza
  ///   nje. To je namerno: tako se uvod pusti ponovo i kupi vreme na
  ///   pretapanju, dok se ne dogovori šta dalje.
  Future<void> onTrackTapped(Track track) async {
    final soundingId = sounding?.id;
    final slot = _nextSlot;

    // Numera koja svira: ide njena kopija odmah iza nje.
    if (soundingId == track.id) {
      _queue.insert(slot, track);
      await _select(slot);
      return;
    }

    // Ista numera već negde u redu (ali ne ona koja svira) se premešta.
    var existing = -1;
    for (var i = 0; i < _queue.length; i++) {
      if (i != _soundingIndex && _queue[i].id == track.id) {
        existing = i;
        break;
      }
    }
    if (existing >= 0) {
      final moved = _queue.removeAt(existing);
      // Vađenje ispred numere koja svira pomera i nju.
      if (existing < _soundingIndex) _soundingIndex--;
      final target = (existing < slot ? slot - 1 : slot).clamp(
        0,
        _queue.length,
      );
      _queue.insert(target, moved);
      await _select(target);
      return;
    }

    _queue.insert(slot, track);
    await _select(slot);
  }

  /// Izbacuje numeru iz reda čekanja.
  ///
  /// Vraća `false` ako je ta numera **upravo ta koja svira** — nju ne diramo:
  /// usred nastupa muzika ne sme da stane zbog sređivanja spiska. Sve njene
  /// kopije koje ne sviraju se uklanjaju.
  Future<bool> removeFromQueue(String trackId) async {
    if (sounding?.id == trackId) return false;

    final selectedRemoved = selected?.id == trackId;

    final kept = <Track>[];
    var newSounding = -1;
    var newSelected = -1;

    for (var i = 0; i < _queue.length; i++) {
      final isSoundingRow = i == _soundingIndex;
      // Numera koja svira ostaje čak i ako se poklapa sa traženom.
      if (_queue[i].id == trackId && !isSoundingRow) continue;

      if (isSoundingRow) newSounding = kept.length;
      if (i == _selectedIndex) newSelected = kept.length;
      kept.add(_queue[i]);
    }

    if (kept.length == _queue.length) return true;

    _queue
      ..clear()
      ..addAll(kept);
    _soundingIndex = newSounding;

    if (!selectedRemoved) {
      _selectedIndex = newSelected;
      notifyListeners();
      return true;
    }

    // Izabrana numera je izbačena: izabranom postaje ono što je došlo na
    // njeno mesto, a ako reda više nema — nijedna.
    if (_queue.isEmpty) {
      _selectedIndex = -1;
      _duration = null;
      _position = Duration.zero;
      waveform.value = null;
      _updateProgress();
      notifyListeners();
      return true;
    }

    final target = _selectedIndex.clamp(0, _queue.length - 1);
    await _select(target);
    return true;
  }

  /// Zamenjuje numere u redu dopunjenim podacima iz fajlova.
  ///
  /// Ne dira ni izabranu ni onu koja svira — menja se samo ono što piše, da
  /// plejer ne bi pokazivao naziv fajla dok spisak već pokazuje pravi naziv.
  void refreshQueue(Map<String, Track> byId) {
    var changed = false;
    for (var i = 0; i < _queue.length; i++) {
      final better = byId[_queue[i].id];
      if (better == null) continue;
      _queue[i] = better;
      changed = true;
    }

    // Trajanje iz fajla vredi i za prikaz, dok plejer ne kaže svoje.
    final current = selected;
    if (changed && _duration == null && current?.duration != null) {
      _duration = current!.duration;
      _updateProgress();
    }
    if (changed) notifyListeners();
  }

  /// Postavlja ceo red i priprema prvu numeru, bez puštanja.
  Future<void> setQueue(List<Track> tracks) async {
    _queue
      ..clear()
      ..addAll(tracks);
    _soundingIndex = -1;
    if (_queue.isEmpty) {
      _selectedIndex = -1;
      notifyListeners();
      return;
    }
    await _select(0);
  }

  /// Bira numeru: učitava je ako ništa ne svira, inače je samo priprema.
  Future<void> _select(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _selectedIndex = index;
    _errorMessage = null;
    _isLoading = true;
    // Talas pripada numeri: dok se novi ne izvuče, prsten crta ravnu liniju.
    waveform.value = null;

    // Dok ništa ne svira, vreme i prsten pripadaju izabranoj numeri.
    if (_soundingIndex < 0) {
      _isFadingOut = false;
      _position = Duration.zero;
      _duration = _queue[index].duration;
      _updateProgress();
    }
    notifyListeners();

    final path = _queue[index].path;
    if (path == null) {
      _isLoading = false;
      _errorMessage = 'Numera nema putanju do fajla.';
      notifyListeners();
      return;
    }

    try {
      if (_soundingIndex < 0) {
        final loaded = await playback.load(path);
        _duration = loaded ?? _queue[index].duration;
      } else {
        // Nešto svira: izabrana numera se sprema u drugom plejeru, spremna
        // za preklapanje.
        await playback.preload(path);
      }
      _isLoading = false;
    } on AudioLoadException {
      _isLoading = false;
      _errorMessage = 'Numera se ne može otvoriti.';
    }
    _updateProgress();
    notifyListeners();

    unawaited(_loadWaveform(index, path));
  }

  /// Izvlačenje talasnog oblika traje, pa ide sa strane — ekran ga ne čeka.
  ///
  /// Ako korisnik u međuvremenu izabere drugu numeru, rezultat se odbacuje:
  /// inače bi na prstenu osvanuo talas pogrešne pesme.
  Future<void> _loadWaveform(int index, String path) async {
    final amplitudes = await _waveforms.amplitudes(path);
    if (index != _selectedIndex) return;
    waveform.value = amplitudes;
  }

  /// Vraća numeru koja svira na početak. Zvuk se ne pokreće sam.
  Future<void> restartCurrent() async {
    if (selected == null) return;
    await playback.seek(Duration.zero);
    _position = Duration.zero;
    _isFadingOut = false;
    _updateProgress();
    notifyListeners();
  }

  Future<void> next() async {
    if (!hasNext) return;
    final wasPlaying = _isPlaying;
    await _switchTo(_selectedIndex + 1, crossfade: false);
    if (wasPlaying) await play();
  }

  Future<void> previous() async {
    // Prvo pritiskanje unazad vraća na početak numere, kao na svakom plejeru;
    // tek ako je pesma tek počela, ide se na prethodnu.
    if (_position > const Duration(seconds: 3) || !hasPrevious) {
      await restartCurrent();
      return;
    }
    final wasPlaying = _isPlaying;
    await _switchTo(_selectedIndex - 1, crossfade: false);
    if (wasPlaying) await play();
  }

  /// Veliko dugme.
  ///
  /// - izabrana numera je ona koja već svira → nastavlja se
  /// - izabrana je druga, a nešto svira → **prelazi se na izabranu**;
  ///   uz `fade` obe numere sviraju u preklopu, bez njega prelaz je odmah
  /// - ništa ne svira → pušta se izabrana
  ///
  /// [fade] zamenjuje opšti prekidač samo za ovo jedno puštanje — Ekran 2
  /// ima svoj „Fade in", koji ne sme da prepiše onaj gore na spisku.
  Future<void> play({bool? fade}) async {
    if (!isReady) return;
    final useFade = fade ?? _fade;

    if (isAnotherSounding) {
      await _switchTo(_selectedIndex, crossfade: useFade);
      return;
    }

    _isFadingOut = false;
    _soundingIndex = _selectedIndex;
    await playback.play(fadeIn: useFade, over: _fadeLength.duration);
    notifyListeners();
  }

  /// Pušta numeru **odmah** — dodir na spisak kad God mode nije uključen,
  /// i zadržavanje prsta na talasnom obliku.
  ///
  /// - ako nešto već svira, prelazi se na novu numeru; uz [fade] preklapanjem
  /// - [from] pušta numeru od zadatog mesta umesto od početka (talasni oblik)
  /// - dodir na numeru koja **već svira** ne radi ništa: usred programa
  ///   okrznut prst ne sme da vrati pesmu na početak. Sa [from] se ta ista
  ///   numera samo premota na izabrano mesto.
  Future<void> playNow(Track track, {bool? fade, Duration? from}) async {
    final useFade = fade ?? _fade;

    if (sounding?.id == track.id) {
      // Premotavanje sa talasa: ista numera se samo pomera, ne udvaja.
      if (from != null) {
        await playback.seek(from);
        _position = from;
        _isFadingOut = false;
        _updateProgress();
        notifyListeners();
        return;
      }

      // Pauzirana numera na dodir samo nastavlja, ne kreće iz početka.
      if (!_isPlaying) {
        await playback.play(fadeIn: useFade, over: _fadeLength.duration);
        notifyListeners();
        return;
      }

      // Numera koja svira se pušta **još jednom, preko sebe** (odluka od
      // 28. septembra 2026). To je DJ potez: dok prva ide na petnaestoj
      // sekundi, uvod se vrati preko nje i dve se preklope. Zato se u red
      // ubacuje njena kopija, pa se na nju pređe pretapanjem — bez `Fade`
      // prelaz je odmah, dakle numera kreće iz početka.
      final slot = _nextSlot;
      _queue.insert(slot, track);
      await _select(slot);
      if (!isReady) return;
      await _switchTo(slot, crossfade: useFade);
      return;
    }

    // Numera koja je već u redu pušta se **sa svog mesta**, bez premeštanja:
    // posle nje ide ono što stoji ispod nje u spisku, kao na svakom plejeru.
    final existing = _queue.indexWhere((t) => t.id == track.id);
    if (existing >= 0) {
      await _select(existing);
    } else {
      await onTrackTapped(track);
    }
    if (!isReady) return;

    if (isAnotherSounding) {
      await _switchTo(_selectedIndex, crossfade: useFade, from: from);
      return;
    }

    _isFadingOut = false;
    _soundingIndex = _selectedIndex;
    if (from != null) {
      await playback.seek(from);
      _position = from;
      _updateProgress();
    }
    await playback.play(fadeIn: useFade, over: _fadeLength.duration);
    notifyListeners();
  }

  Future<void> toggle() async {
    if (!isReady) return;

    if (_isPlaying && !isAnotherSounding) {
      await playback.pause(fadeOut: _fade, windDown: !_fade);
      return;
    }
    await play();
  }

  /// Prebacuje zvuk na numeru pod datim rednim brojem.
  ///
  /// [from] je mesto u novoj numeri odakle se kreće; bez njega od početka.
  Future<void> _switchTo(
    int index, {
    required bool crossfade,
    Duration? from,
  }) async {
    if (index < 0 || index >= _queue.length) return;

    if (crossfade && playback.hasPreloaded) {
      await playback.crossfadeToPreloaded(_fadeLength.duration);
      // Nova numera je sada aktivni plejer, pa premotavanje ide na nju. U tom
      // trenutku je jedva čujna, pa se skok ne primeti.
      if (from != null) await playback.seek(from);
      _selectedIndex = index;
      _soundingIndex = index;
      _isFadingOut = false;
      _position = from ?? Duration.zero;
      _duration = _queue[index].duration;
      _updateProgress();
      notifyListeners();
      return;
    }

    // Bez preklapanja: numera se učita na mesto one koja svira.
    _soundingIndex = -1;
    _selectedIndex = index;
    await _select(index);
    if (_errorMessage != null) return;

    if (from != null) {
      await playback.seek(from);
      _position = from;
      _updateProgress();
    }
    _soundingIndex = index;
    await playback.play(fadeIn: crossfade, over: _fadeLength.duration);
    notifyListeners();
  }

  Future<void> _onCompleted() async {
    if (hasNext) {
      await _switchTo(_selectedIndex + 1, crossfade: false);
      await playback.play(fadeIn: _fade, over: _fadeLength.duration);
      return;
    }
    // Kraj reda: numera ostaje, ali se vraća na početak i staje.
    await playback.pause();
    _soundingIndex = -1;
    _isFadingOut = false;
    await restartCurrent();
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

  void setFade(bool value) {
    _fade = value;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    progress.dispose();
    waveform.dispose();
    playback.dispose();
    super.dispose();
  }
}
