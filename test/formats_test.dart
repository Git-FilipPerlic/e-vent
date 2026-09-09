import 'package:event_app/services/file_browser.dart';
import 'package:flutter_test/flutter_test.dart';

/// MUSIC-021 — spisak nastavaka mora da prati ono što plejer zaista ume da
/// pusti. Nastavak koji se ponudi a ne radi je gori od nastavka koji fali.
void main() {
  group('podržani formati', () {
    test('prepoznaje uobičajene muzičke fajlove', () {
      for (final name in [
        'pesma.mp3',
        'pesma.M4A',
        'pesma.aac',
        'pesma.wav',
        'pesma.flac',
        'pesma.ogg',
        'pesma.oga',
        'pesma.opus',
      ]) {
        expect(FileBrowser.isAudio('/muzika/$name'), isTrue, reason: name);
      }
    });

    test('wma se ne nudi, jer ga Android ne ume pustiti', () {
      // Ranije je stajao u spisku: fajl bi se ponudio, pa bi plejer javio
      // grešku pri otvaranju.
      expect(FileBrowser.isAudio('/muzika/pesma.wma'), isFalse);
      expect(FileBrowser.audioExtensions.contains('wma'), isFalse);
    });

    test('ne nudi fajlove koji nisu zvuk', () {
      for (final name in [
        'slika.jpg',
        'spisak.txt',
        'film.avi',
        'bez-nastavka',
        '.skriveni',
      ]) {
        expect(FileBrowser.isAudio('/muzika/$name'), isFalse, reason: name);
      }
    });

    test('velika i mala slova u nastavku su svejedno', () {
      expect(FileBrowser.isAudio('/m/A.MP3'), isTrue);
      expect(FileBrowser.isAudio('/m/A.Mp3'), isTrue);
    });
  });
}
