// Beleške na delovima pesme — vidi ih cela ekipa.

import 'package:event_app/models/track.dart';
import 'package:event_app/models/track_note.dart';
import 'package:event_app/screens/wave_screen.dart';
import 'package:event_app/services/music_player_controller.dart';
import 'package:event_app/services/track_note_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/common/team_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const Track _track = Track(
  id: 'trk-1',
  title: 'Act Won',
  path: '/sdcard/Music/Nrg/01. Act Won.mp3',
  duration: Duration(minutes: 3),
);

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

void main() {
  group('ključ numere', () {
    // Putanja ne valja: isti fajl kod svakog stoji na svom mestu. Naziv
    // fajla ostaje isti kad se pesma prekopira sa telefona na telefon.
    test('gradi se od naziva fajla, bez putanje i nastavka', () {
      expect(
        TrackNote.keyForPath('/sdcard/Music/Nrg/01. Act Won.mp3'),
        '01. act won',
      );
      expect(TrackNote.keyForPath(r'C:\Muzika\01. Act Won.mp3'), '01. act won');
      // Isti fajl na dva telefona daje isti ključ.
      expect(
        TrackNote.keyForPath('/storage/emulated/0/Music/01. Act Won.mp3'),
        TrackNote.keyForPath('/sdcard/Nrg/01. Act Won.mp3'),
      );
    });

    test('ime koje počinje tačkom je skriven fajl, ne nastavak', () {
      expect(TrackNote.keyForPath('/muzika/.skriveno'), '.skriveno');
    });
  });

  group('čuvanje beleški', () {
    test('beleška se doda i vrati sa svojim mestom u pesmi', () async {
      final service = InMemoryTrackNoteService();

      final saved = await service.add(
        const TrackNote(
          id: '',
          trackKey: '01. act won',
          positionMs: 45000,
          text: 'omiljeni deo',
          authorName: 'Filip',
          authorAvatarId: 'vatra',
        ),
      );

      expect(saved.id, isNotEmpty);
      expect(saved.createdAt, isNotNull);
      final notes = await service.notesFor('01. act won');
      expect(notes.single.text, 'omiljeni deo');
    });

    test('beleške stižu redom kroz pesmu, ne redom upisa', () async {
      final service = InMemoryTrackNoteService();
      for (final ms in [90000, 15000, 45000]) {
        await service.add(
          TrackNote(
            id: '',
            trackKey: 'pesma',
            positionMs: ms,
            text: '$ms',
            authorName: 'Ana',
          ),
        );
      }

      final notes = await service.notesFor('pesma');
      expect(notes.map((n) => n.positionMs), [15000, 45000, 90000]);
    });

    test('tuđa numera ne vuče tuđe beleške', () async {
      final service = InMemoryTrackNoteService();
      await service.add(
        const TrackNote(
          id: '',
          trackKey: 'prva',
          positionMs: 0,
          text: 'x',
          authorName: 'Ana',
        ),
      );

      expect(await service.notesFor('druga'), isEmpty);
    });
  });

  group('mesto beleške', () {
    // Trajanje iz oznaka u fajlu i ono što plejer izmeri nisu uvek isti
    // broj. Beleška zato nosi trajanje po kom je računata, pa pada na isto
    // mesto i kad telefon misli da pesma traje drugačije.
    test('mesto se računa po trajanju zapamćenom uz belešku', () {
      const note = TrackNote(
        id: 'n1',
        trackKey: 'pesma',
        positionMs: 45000,
        trackDurationMs: 180000,
        text: 'omiljeni deo',
        authorName: 'Filip',
      );

      // Telefon misli da pesma traje tri i po minuta — mesto se ne pomera.
      expect(note.fractionIn(const Duration(minutes: 3, seconds: 30)), 0.25);
      expect(note.fractionIn(null), 0.25);
    });

    test('stara beleška bez trajanja pada na ono što telefon zna', () {
      const note = TrackNote(
        id: 'n1',
        trackKey: 'pesma',
        positionMs: 45000,
        text: 'stara',
        authorName: 'Ana',
      );

      expect(note.fractionIn(const Duration(minutes: 3)), 0.25);
      // Bez ijednog trajanja se ne nagađa.
      expect(note.fractionIn(null), isNull);
    });
  });

  group('talas sa beleškama', () {
    testWidgets('ikonica onoga ko je ostavio belešku stoji na talasu', (
      WidgetTester tester,
    ) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);
      final notes = InMemoryTrackNoteService([
        const TrackNote(
          id: 'n1',
          trackKey: '01. act won',
          positionMs: 45000,
          text: 'omiljeni deo',
          authorName: 'Filip',
          authorAvatarId: 'vatra',
        ),
      ]);

      await tester.pumpWidget(
        _wrap(
          WaveScreen(
            controller: controller,
            track: _track,
            fade: false,
            notes: notes,
            authorName: 'Filip',
            authorAvatarId: 'vatra',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeamAvatarDot), findsWidgets);

      // Dodir na ikonicu otvara šta piše.
      await tester.tap(find.byType(TeamAvatarDot).first);
      // Talas osluškuje i dva brza dodira (zum), pa običan dodir čeka da
      // se to vreme istekne pre nego što se okine.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('omiljeni deo'), findsOneWidget);
      expect(find.text('Filip'), findsOneWidget);
      // Svoju belešku svako sme da skloni.
      expect(find.text('Skloni belešku'), findsOneWidget);
    });

    testWidgets('tuđa beleška se ne sklanja', (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);
      final notes = InMemoryTrackNoteService([
        const TrackNote(
          id: 'n1',
          trackKey: '01. act won',
          positionMs: 45000,
          text: 'ovde ulazi vatra',
          authorName: 'Ana',
          authorAvatarId: 'svila',
        ),
      ]);

      await tester.pumpWidget(
        _wrap(
          WaveScreen(
            controller: controller,
            track: _track,
            fade: false,
            notes: notes,
            authorName: 'Filip',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TeamAvatarDot).first);
      // Talas osluškuje i dva brza dodira (zum), pa običan dodir čeka da
      // se to vreme istekne pre nego što se okine.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('ovde ulazi vatra'), findsOneWidget);
      expect(find.text('Skloni belešku'), findsNothing);
    });

    // Beleška mora da se vrati tačno tamo gde je ostavljena: upisuje se
    // mesto u pesmi, pa se pri sledećem otvaranju crta na istom procentu.
    testWidgets('beleška se upisuje na mestu gde stoji linija', (
      WidgetTester tester,
    ) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);
      final notes = InMemoryTrackNoteService();

      await tester.pumpWidget(
        _wrap(
          WaveScreen(
            controller: controller,
            track: _track,
            fade: false,
            notes: notes,
            authorName: 'Filip',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cela pesma je jedan pun skrol: kraj skrola je kraj pesme.
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      final position = scroll.controller!.position;
      scroll.controller!.jumpTo(position.maxScrollExtent * 0.25);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zabeleži'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'omiljeni deo');
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      final saved = await notes.notesFor('01. act won');
      expect(saved.single.text, 'omiljeni deo');
      // Četvrtina pesme od tri minuta je 45 sekundi.
      expect(saved.single.positionMs, closeTo(45000, 500));
      // Uz mesto se pamti i trajanje po kom je računato.
      expect(saved.single.trackDurationMs, 180000);
    });

    // Dok se kuca, ekran se skupi (tastatura, podeljen ekran) — a sa njim i
    // visina talasa, pa linija na sredini pada na drugo mesto u pesmi. Mesto
    // se zato uzima pre nego što se list za unos otvori.
    testWidgets('beleška ostaje na svom mestu i kad se ekran skupi', (
      WidgetTester tester,
    ) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);
      final notes = InMemoryTrackNoteService();

      await tester.pumpWidget(
        _wrap(
          WaveScreen(
            controller: controller,
            track: _track,
            fade: false,
            notes: notes,
            authorName: 'Filip',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      scroll.controller!.jumpTo(
        scroll.controller!.position.maxScrollExtent * 0.25,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zabeleži'));
      await tester.pumpAndSettle();

      // Ekran je sada upola niži.
      final size = tester.view.physicalSize;
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = Size(size.width, size.height / 2);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'omiljeni deo');
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      final saved = await notes.notesFor('01. act won');
      // Četvrtina pesme od tri minuta je 45 sekundi — bez obzira na to što se
      // ekran u međuvremenu skupio.
      expect(saved.single.positionMs, closeTo(45000, 500));
    });

    // Neprijavljen ih samo čita — nema čime da se potpiše.
    testWidgets('bez prijave nema dugmeta za belešku', (
      WidgetTester tester,
    ) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          WaveScreen(
            controller: controller,
            track: _track,
            fade: false,
            notes: InMemoryTrackNoteService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zabeleži'), findsNothing);
    });
  });
}
