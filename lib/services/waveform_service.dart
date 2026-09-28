import 'dart:async';
import 'dart:io';

import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';

/// Izvlači **talasni oblik** numere: niz vrednosti 0..1 koje kažu koliko je
/// gde glasno.
///
/// Računa se **jednom po pesmi** i pamti; nikad se ne računa u toku crtanja.
/// To je izričit zahtev iz `CLAUDE.md` — prsten se prerisava 60 puta u sekundi
/// i ne sme da čeka na obradu zvuka.
class WaveformService {
  WaveformService({Directory? cacheDirectory}) : _dir = cacheDirectory;

  /// Gde stoje izvučeni talasi.
  ///
  /// Podrazumevano je **trajan folder aplikacije**, ne privremeni: Android
  /// privremeni folder briše, pa je svaka numera posle toga opet čekala na
  /// obradu. Izvučen talas je nekoliko desetina kilobajta, pa ih i stotinu
  /// staje u par megabajta.
  Directory? _dir;

  Future<Directory> _directory() async {
    final known = _dir;
    if (known != null) return known;
    try {
      final dir = Directory(
        '${(await getApplicationSupportDirectory()).path}/talasi',
      );
      if (!await dir.exists()) await dir.create(recursive: true);
      return _dir = dir;
    } catch (_) {
      // Bez trajnog foldera se radi kao ranije — talas se samo ne pamti
      // između pokretanja.
      return _dir = Directory.systemTemp;
    }
  }

  /// Koliko numera unapred sprema [prepareAll].
  ///
  /// Četrdeset je korisnikova mera za nastupnu plejlistu. Više od toga bi
  /// obrađivalo pesme koje se te večeri neće ni otvoriti.
  static const int prepareLimit = 40;

  /// Numere koje se upravo obrađuju — da se isti fajl ne obrađuje dvaput kad
  /// se traži i u pozadini i sa ekrana.
  final Map<String, Future<List<double>?>> _inFlight = {};

  /// Koliko ekrana trenutno čeka na talas.
  ///
  /// Dok je veće od nule, priprema u pozadini staje: ono što korisnik gleda
  /// ima prednost nad onim što će mu možda trebati.
  int _waiting = 0;

  /// Već izvučeni talasni oblici, po putanji numere.
  final Map<String, List<double>> _cache = {};

  /// Numere za koje izvlačenje nije uspelo — da se ne pokušava iznova pri
  /// svakom otvaranju.
  final Set<String> _failed = <String>{};

  /// Koliko se vrednosti vraća.
  ///
  /// Više nego što stane na ekran, namerno (od 28. septembra 2026): ekran
  /// sa talasom se zumira, pa se iz ovog niza crta gušće kad se uđe u
  /// detalj. Sa 600 vrednosti je zumiran talas bio samo razvučen, bez i
  /// jednog novog podatka.
  static const int defaultSampleCount = 2400;

  /// Talasni oblik numere, ili `null` ako se ne može izvući.
  ///
  /// `null` nije greška: prsten tada crta ravnu liniju, kako i piše u
  /// specifikaciji — nikad prazan ekran.
  Future<List<double>?> amplitudes(
    String path, {
    int samples = defaultSampleCount,
    void Function(double progress)? onProgress,
  }) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    if (_failed.contains(path)) return null;

    // Ista numera se ne obrađuje dvaput: ekran se pridruži obradi koja već
    // ide (svoja ili iz pripreme u pozadini).
    final running = _inFlight[path];
    if (running != null) {
      _waiting++;
      try {
        return await running;
      } finally {
        _waiting--;
      }
    }

    final work = _extract(path, samples: samples, onProgress: onProgress);
    _inFlight[path] = work;
    _waiting++;
    try {
      return await work;
    } finally {
      _waiting--;
      _inFlight.remove(path);
    }
  }

  /// Upisuje gotov talas u keš.
  ///
  /// Postoji zbog testova i zbog eventualnog spremanja sa strane — obrada je
  /// jedino što traje, a rezultat je običan niz.
  void remember(String path, List<double> amplitudes) {
    _cache[path] = amplitudes;
  }

  /// Sprema talase za spisak numera, u pozadini.
  ///
  /// Bez ovoga se na svaku numeru čeka pri prvom otvaranju talasa, a to je
  /// nekoliko sekundi po pesmi — usred programa predugo. Ide **jedna po
  /// jedna** i staje dok neki ekran čeka na svoj talas.
  Future<void> prepareAll(
    List<String> paths, {
    int limit = prepareLimit,
  }) async {
    var done = 0;
    for (final path in paths) {
      if (done >= limit) return;
      if (_cache.containsKey(path) || _failed.contains(path)) continue;
      if (_inFlight.containsKey(path)) continue;

      // Ono što korisnik gleda ima prednost.
      while (_waiting > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      done++;
      await amplitudes(path);
    }
  }

  Future<List<double>?> _extract(
    String path, {
    int samples = defaultSampleCount,
    void Function(double progress)? onProgress,
  }) async {
    // Numera koja stiže kao `content://` adresa se ne može otvoriti kao fajl.
    // Sopstveni pregled fajlova daje prave putanje, pa je ovo redak slučaj.
    if (path.contains('://')) {
      _failed.add(path);
      return null;
    }

    final audio = File(path);
    if (!await audio.exists()) {
      _failed.add(path);
      return null;
    }

    try {
      // Naziv nosi i veličinu fajla: kad se pesma zameni drugom pod istim
      // imenom, stari talas se ne podmeće.
      final size = await audio.length();
      final out = File(
        '${(await _directory()).path}/talas-${path.hashCode}-$size.wave',
      );

      Waveform? waveform;

      // Već izvučen u nekom od ranijih pokretanja — samo se pročita.
      if (await out.exists()) {
        try {
          waveform = await JustWaveform.parse(out);
        } catch (_) {
          // Nedovršen ili pokvaren zapis se odbacuje i izvlači iznova.
          try {
            await out.delete();
          } catch (_) {}
          waveform = null;
        }
      }

      // Dvadeset tačaka po sekundi zvuka: taman da se iz zapisa može
      // izvući 2400 vrednosti i za kratke numere, a da obrada ne traje
      // predugo na telefonu.
      if (waveform == null) {
        await for (final progress in JustWaveform.extract(
          audioInFile: audio,
          waveOutFile: out,
          zoom: const WaveformZoom.pixelsPerSecond(20),
        )) {
          onProgress?.call(progress.progress);
          if (progress.waveform != null) waveform = progress.waveform;
        }
      }

      if (waveform == null || waveform.length == 0) {
        _failed.add(path);
        return null;
      }

      final result = _reduce(waveform, samples);
      _cache[path] = result;
      return result;
    } catch (_) {
      _failed.add(path);
      return null;
    }
  }

  /// Svodi talasni oblik na zadati broj vrednosti 0..1.
  ///
  /// Iz svakog opsega se uzima **najglasniji** trenutak, ne prosek: prosek
  /// spljošti pesmu i sve deluje podjednako tiho.
  static List<double> _reduce(Waveform waveform, int samples) {
    final pixels = waveform.length;
    final result = List<double>.filled(samples, 0);

    // 16-bitni zapis ide do 32768; 8-bitni do 128.
    final scale = (waveform.flags & 1) == 1 ? 128.0 : 32768.0;

    for (var i = 0; i < samples; i++) {
      final from = (i * pixels) ~/ samples;
      final to = (((i + 1) * pixels) ~/ samples).clamp(from + 1, pixels);

      var peak = 0;
      for (var p = from; p < to; p++) {
        final min = waveform.getPixelMin(p).abs();
        final max = waveform.getPixelMax(p).abs();
        final loudest = min > max ? min : max;
        if (loudest > peak) peak = loudest;
      }
      result[i] = (peak / scale).clamp(0.0, 1.0);
    }

    return _normalize(result);
  }

  /// Diže tihu pesmu na punu visinu.
  ///
  /// Bez ovoga bi numera snimljena tiho davala jedva vidljiv talas, iako je
  /// odnos glasnih i tihih delova u njoj isti.
  static List<double> _normalize(List<double> values) {
    var peak = 0.0;
    for (final value in values) {
      if (value > peak) peak = value;
    }
    // Skoro nečujna numera se ne pojačava — to bi bio samo šum.
    if (peak < 0.02) return values;

    return [for (final value in values) (value / peak).clamp(0.0, 1.0)];
  }
}
