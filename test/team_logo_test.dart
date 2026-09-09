import 'dart:io';

import 'package:event_app/services/team_logo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Folder aplikacije se u testu podmeće, jer pravi ne postoji.
late Directory _appDir;

TeamLogoService _service() =>
    TeamLogoService(directory: () async => _appDir);

/// Pravi „izabranu" sliku u privremenom folderu — onakvu kakvu ostavi
/// `image_picker`.
File _pickedImage(String name) {
  final file = File('${_appDir.parent.path}/$name')
    ..createSync(recursive: true)
    ..writeAsBytesSync([1, 2, 3]);
  return file;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final root = await Directory.systemTemp.createTemp('e-vent-logo');
    _appDir = Directory('${root.path}/app')..createSync();
  });

  tearDown(() {
    if (_appDir.parent.existsSync()) {
      _appDir.parent.deleteSync(recursive: true);
    }
  });

  group('logotip tima', () {
    test('bez izabranog logotipa nema ničega', () async {
      expect(await _service().load(), isNull);
    });

    test('slika se kopira u folder aplikacije', () async {
      final picked = _pickedImage('sa-galerije.png');

      final saved = await _service().save(picked.path);

      expect(saved, isNotNull);
      // Ključno: kopija, a ne ista putanja — privremeni fajl Android briše.
      expect(saved, isNot(picked.path));
      expect(File(saved!).existsSync(), isTrue);
      expect(saved.startsWith(_appDir.path), isTrue);
      expect(saved.endsWith('.png'), isTrue);
    });

    test('sačuvani logotip se čita i posle', () async {
      final picked = _pickedImage('logo.jpg');
      final saved = await _service().save(picked.path);

      expect(await _service().load(), saved);
    });

    test('brisanje privremenog fajla ne odnosi logotip', () async {
      final picked = _pickedImage('privremeno.png');
      final saved = await _service().save(picked.path);

      // Ovo je tačno ono što se dešava pri reinstalaciji aplikacije.
      picked.deleteSync();

      expect(await _service().load(), saved);
      expect(File(saved!).existsSync(), isTrue);
    });

    test('nova slika ne pada preko stare', () async {
      final first = await _service().save(_pickedImage('prva.png').path);
      final second = await _service().save(_pickedImage('druga.png').path);

      // Različita imena, da Flutter ne nacrta staru sliku iz svog keša.
      expect(second, isNot(first));
      expect(File(first!).existsSync(), isFalse);
      expect(File(second!).existsSync(), isTrue);
    });

    test('nestala kopija se čisti, header se vraća na ime aplikacije',
        () async {
      final saved = await _service().save(_pickedImage('logo.png').path);
      File(saved!).deleteSync();

      expect(await _service().load(), isNull);
      // Zapis je obrisan, pa se sledeći put ni ne pokušava.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('team_logo_path'), isNull);
    });

    test('uklanjanje briše i zapis i kopiju', () async {
      final saved = await _service().save(_pickedImage('logo.png').path);

      await _service().clear();

      expect(await _service().load(), isNull);
      expect(File(saved!).existsSync(), isFalse);
    });

    test('slika koje nema se ne pamti', () async {
      expect(await _service().save('/ne/postoji.png'), isNull);
      expect(await _service().load(), isNull);
    });
  });
}
