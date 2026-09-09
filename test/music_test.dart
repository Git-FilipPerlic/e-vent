import 'package:event_app/models/track.dart';
import 'package:event_app/screens/music_screen.dart';
import 'package:event_app/services/music_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/music/track_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  group('numera', () {
    test('naziv pada na naziv fajla, pa na objašnjenje', () {
      expect(
        const Track(id: 't', title: 'Uvodna špica').displayTitle,
        'Uvodna špica',
      );
      expect(
        const Track(id: 't', path: '/muzika/bez-naziva-04.mp3').displayTitle,
        'bez-naziva-04.mp3',
      );
      expect(const Track(id: 't').displayTitle, 'Numera bez naziva');
      // Prazan naziv se tretira kao da ga nema.
      expect(
        const Track(id: 't', title: '   ', path: '/m/a.mp3').displayTitle,
        'a.mp3',
      );
    });

    test('nepoznat izvor pada na folder', () {
      expect(TrackSource.fromName('playlist'), TrackSource.playlist);
      expect(TrackSource.fromName('folder'), TrackSource.folder);
      expect(TrackSource.fromName('nesto'), TrackSource.folder);
      expect(TrackSource.fromName(null), TrackSource.folder);
    });

    test('trajanje se piše kao minut:sekund', () {
      expect(TrackTile.formatDuration(const Duration(seconds: 154)), '2:34');
      expect(TrackTile.formatDuration(const Duration(seconds: 60)), '1:00');
      expect(TrackTile.formatDuration(const Duration(seconds: 5)), '0:05');
      // Trajanje se ne zna dok se fajl ne pročita.
      expect(TrackTile.formatDuration(null), '--:--');
    });
  });

  group('red u spisku', () {
    testWidgets('prikazuje naziv, izvođača, izvor i trajanje',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          TrackTile(
            track: const Track(
              id: 'trk-001',
              title: 'Uvodna špica',
              artist: 'Miks za doček',
              source: TrackSource.playlist,
              duration: Duration(seconds: 154),
            ),
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Uvodna špica'), findsOneWidget);
      expect(find.text('Miks za doček · Playlista'), findsOneWidget);
      expect(find.text('2:34'), findsOneWidget);
    });

    testWidgets('bez izvođača se prikazuje samo izvor',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          TrackTile(
            track: const Track(id: 'trk-003', title: 'Vatreni show'),
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Folder'), findsOneWidget);
    });
  });

  group('Muzika ekran', () {
    testWidgets('učita spisak numera', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MusicScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Uvodna špica'), findsOneWidget);
      expect(find.text('Igre za decu'), findsOneWidget);
      // Numera bez naziva pada na naziv fajla.
      expect(find.text('bez-naziva-04.mp3'), findsOneWidget);
    });

    testWidgets('dodir bira numeru, ali ne pokreće reprodukciju',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MusicScreen()));
      await tester.pumpAndSettle();

      // Dok ništa nije izabrano, nema ni dugmeta za plejer.
      expect(find.textContaining('Otvori plejer'), findsNothing);

      await tester.tap(find.text('Igre za decu'));
      await tester.pumpAndSettle();

      // Izbor samo otvara put do plejera — muzika ne kreće sama.
      expect(
        find.textContaining('Otvori plejer — Igre za decu'),
        findsOneWidget,
      );
    });

    testWidgets('izbor druge numere menja dugme',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MusicScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Igre za decu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vatreni show'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Otvori plejer — Vatreni show'),
        findsOneWidget,
      );
    });
  });

  group('mock servis', () {
    test('vraća numere iz oba izvora', () async {
      final tracks = await MockMusicService().loadTracks();

      expect(tracks.length, 5);
      expect(
        tracks.any((t) => t.source == TrackSource.playlist),
        isTrue,
      );
      expect(tracks.any((t) => t.source == TrackSource.folder), isTrue);
      // Jedna numera namerno nema poznato trajanje.
      expect(tracks.any((t) => t.duration == null), isTrue);
    });
  });
}
