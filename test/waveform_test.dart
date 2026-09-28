import 'package:event_app/services/waveform_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('talasni oblik', () {
    test('numera koja stiže kao content:// adresa nema talas', () async {
      final service = WaveformService();
      // Takva adresa se ne može otvoriti kao fajl; prsten tada crta ravnu
      // liniju umesto da pukne.
      expect(await service.amplitudes('content://media/audio/17'), isNull);
    });

    test('nepostojeći fajl nema talas', () async {
      final service = WaveformService();
      expect(await service.amplitudes('/nema/ovoga/nigde.mp3'), isNull);
    });

    test('neuspeh se pamti, pa se ne pokušava iznova', () async {
      final service = WaveformService();
      await service.amplitudes('/nema/ovoga/nigde.mp3');
      // Drugi poziv vraća isto, bez novog pokušaja čitanja diska.
      expect(await service.amplitudes('/nema/ovoga/nigde.mp3'), isNull);
    });
  });

  group('priprema talasa u pozadini', () {
    // Prvo otvaranje talasa je inače čekanje od nekoliko sekundi po pesmi.
    // Zato se talasi spremaju unapred — ali samo za nastupnu plejlistu, ne
    // za ceo telefon.
    test('sprema se najviše zadati broj numera', () async {
      final service = _CountingWaveforms();

      await service.prepareAll([
        for (var i = 0; i < 60; i++) '/muzika/pesma-$i.mp3',
      ], limit: 5);

      expect(service.asked.length, 5);
      expect(service.asked.first, '/muzika/pesma-0.mp3');
    });

    test('numera koja je već obrađena se preskače', () async {
      final service = _CountingWaveforms(ready: {'/muzika/b.mp3'});

      await service.prepareAll([
        '/muzika/a.mp3',
        '/muzika/b.mp3',
        '/muzika/c.mp3',
      ]);

      expect(service.asked, ['/muzika/a.mp3', '/muzika/c.mp3']);
    });

    test('numera bez talasa se ne pokušava drugi put', () async {
      final service = WaveformService();
      await service.amplitudes('/nema/ovoga/nigde.mp3');

      // Priprema gleda isti spisak neuspelih kao i ekran.
      await service.prepareAll(['/nema/ovoga/nigde.mp3']);
      expect(await service.amplitudes('/nema/ovoga/nigde.mp3'), isNull);
    });
  });
}

/// Beleži za koje je numere priprema tražila talas, bez diranja diska.
class _CountingWaveforms extends WaveformService {
  _CountingWaveforms({Set<String> ready = const {}}) {
    for (final path in ready) {
      // Numera koja je već obrađena stoji u kešu, kao u aplikaciji.
      remember(path, const [0.5, 0.5]);
    }
  }

  final List<String> asked = [];

  @override
  Future<List<double>?> amplitudes(
    String path, {
    int samples = WaveformService.defaultSampleCount,
    void Function(double progress)? onProgress,
  }) async {
    asked.add(path);
    return const [0.5, 0.5];
  }
}
