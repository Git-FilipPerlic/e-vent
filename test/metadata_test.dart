import 'package:event_app/models/track.dart';
import 'package:event_app/services/track_metadata_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
