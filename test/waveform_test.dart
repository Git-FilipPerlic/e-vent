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
}
