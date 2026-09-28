import 'dart:convert';
import 'dart:io';

import 'package:event_app/models/track.dart';
import 'package:event_app/services/track_library_service.dart';
import 'package:event_app/services/track_metadata_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('podaci iz fajla', () {
    test('numera bez putanje ostaje kakva jeste', () async {
      final service = TrackMetadataService();
      const track = Track(id: 't', title: 'Bez fajla');

      expect(identical(await service.enrich(track), track), isTrue);
    });

    test('content:// adresa se ne može čitati kao fajl', () async {
      final service = TrackMetadataService();
      const track = Track(id: 't', path: 'content://media/audio/17');

      expect(identical(await service.enrich(track), track), isTrue);
    });

    test('nepostojeći fajl ne obara ništa', () async {
      final service = TrackMetadataService();
      const track = Track(
        id: 't',
        title: 'nema.mp3',
        path: '/nema/ovoga/nigde.mp3',
      );

      final result = await service.enrich(track);
      expect(result.displayTitle, 'nema.mp3');
    });

    test('ceo spisak prolazi i kad neki fajl ne valja', () async {
      final service = TrackMetadataService();
      final tracks = [
        const Track(id: 'a', title: 'a.mp3', path: '/nema/a.mp3'),
        const Track(id: 'b', title: 'b.mp3'),
      ];

      final result = await service.enrichAll(tracks);
      expect(result.length, 2);
      expect(result[0].id, 'a');
      expect(result[1].id, 'b');
    });
  });

  group('velik spisak pri pokretanju', () {
    // Spisak od nekoliko stotina numera se pamti ceo; pitanje je samo da li
    // se učita, jer provera postojanja fajlova ide u zasebnu nit.
    test('dug zapamćen spisak se učita ceo, bez fajlova kojih nema', () async {
      final folder = Directory.systemTemp.createTempSync('evt-spisak');
      addTearDown(() => folder.deleteSync(recursive: true));

      final paths = <String>[];
      for (var i = 0; i < TrackLibraryService.threadFrom + 20; i++) {
        final file = File('${folder.path}/numera-$i.mp3')
          ..writeAsBytesSync([0, 1]);
        paths.add(file.path);
      }
      // Jedan koji je u međuvremenu obrisan — on samo smeta na nastupu.
      paths.add('${folder.path}/nema-ovoga.mp3');

      SharedPreferences.setMockInitialValues({'music_track_paths': paths});

      final tracks = await const TrackLibraryService().load();

      expect(tracks.length, paths.length - 1);
      expect(tracks.first.path, paths.first);
      expect(tracks.map((t) => t.path), isNot(contains(paths.last)));
    });

    // Fajlovi se ne menjaju, pa se pri svakom pokretanju ne čita isto: ako
    // se veličina poklapa sa zapamćenom, oznake se uzimaju iz pamćenja.
    test('zapamćene oznake se ne čitaju iznova', () async {
      final folder = Directory.systemTemp.createTempSync('evt-oznake');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/numera.mp3')
        ..writeAsBytesSync([0, 1, 2]);

      SharedPreferences.setMockInitialValues({
        'music_meta_cache': jsonEncode({
          file.path: {
            'size': 3,
            'title': 'Iz pamćenja',
            'artist': 'Zapamćen izvođač',
            'ms': 200000,
          },
        }),
      });

      final service = TrackMetadataService();
      final result = await service.enrichAll([
        Track(id: 't', title: 'numera.mp3', path: file.path),
      ]);

      // Fajl je prazan i nema nikakve oznake — sve ovo dolazi iz pamćenja.
      expect(result.single.title, 'Iz pamćenja');
      expect(result.single.artist, 'Zapamćen izvođač');
      expect(result.single.duration, const Duration(milliseconds: 200000));
    });

    // Kad se fajl zameni drugim pod istim imenom, veličina se razlikuje, pa
    // pamćenje ne sme da se koristi.
    test('zamenjen fajl ne uzima staro pamćenje', () async {
      final folder = Directory.systemTemp.createTempSync('evt-zamena');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/numera.mp3')
        ..writeAsBytesSync([0, 1, 2, 3, 4]);

      SharedPreferences.setMockInitialValues({
        'music_meta_cache': jsonEncode({
          file.path: {'size': 3, 'title': 'Stara pesma', 'ms': 200000},
        }),
      });

      final service = TrackMetadataService();
      final result = await service.enrichAll([
        Track(id: 't', title: 'numera.mp3', path: file.path),
      ]);

      // Iz ovakvog fajla nema šta da se pročita, pa numera ostaje kakva je —
      // ali stari naziv se ne podmeće.
      expect(result.single.displayTitle, 'numera.mp3');
      expect(result.single.duration, isNull);
    });
  });
}
