import 'dart:io';

import 'package:just_waveform/just_waveform.dart';

/// Izvlači **talasni oblik** numere: niz vrednosti 0..1 koje kažu koliko je
/// gde glasno.
///
/// Računa se **jednom po pesmi** i pamti; nikad se ne računa u toku crtanja.
/// To je izričit zahtev iz `CLAUDE.md` — prsten se prerisava 60 puta u sekundi
/// i ne sme da čeka na obradu zvuka.
class WaveformService {
  WaveformService({Directory? cacheDirectory})
    : _cacheDirectory = cacheDirectory ?? Directory.systemTemp;

  final Directory _cacheDirectory;

  /// Već izvučeni talasni oblici, po putanji numere.
  final Map<String, List<double>> _cache = {};

  /// Numere za koje izvlačenje nije uspelo — da se ne pokušava iznova pri
  /// svakom otvaranju.
  final Set<String> _failed = <String>{};

  /// Koliko se vrednosti vraća. Otprilike broj tačaka po obimu ekrana —
  /// finije od toga se ne vidi.
  static const int defaultSampleCount = 600;

  /// Talasni oblik numere, ili `null` ako se ne može izvući.
  ///
  /// `null` nije greška: prsten tada crta ravnu liniju, kako i piše u
  /// specifikaciji — nikad prazan ekran.
  Future<List<double>?> amplitudes(
    String path, {
    int samples = defaultSampleCount,
  }) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    if (_failed.contains(path)) return null;

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
      final out = File(
        '${_cacheDirectory.path}/talas-${path.hashCode}.wave',
      );

      Waveform? waveform;
      await for (final progress in JustWaveform.extract(
        audioInFile: audio,
        waveOutFile: out,
      )) {
        if (progress.waveform != null) waveform = progress.waveform;
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
