import 'package:event_app/models/track.dart';
import 'package:event_app/screens/player_screen.dart';
import 'package:event_app/services/music_player_controller.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/music/edge_progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: child);
}

const List<Track> _tracks = [
  Track(
    id: 'trk-001',
    title: 'Uvodna špica',
    artist: 'Miks za doček',
    path: '/muzika/uvodna-spica.mp3',
  ),
  Track(id: 'trk-002', title: 'Igre za decu', path: '/muzika/igre.mp3'),
  Track(id: 'trk-003', title: 'Finale', path: '/muzika/finale.mp3'),
];

Future<MusicPlayerController> _controllerWith(
  FakePlayback playback, {
  List<Track> queue = _tracks,
}) async {
  final controller = MusicPlayerController(playback: playback);
  await controller.setQueue(queue);
  return controller;
}

void main() {
  group('red čekanja', () {
    test('postavljanje reda učita prvu numeru, ali je ne pusti', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      expect(controller.selected?.id, 'trk-001');
      expect(playback.loadedPath, '/muzika/uvodna-spica.mp3');
      // Dodir i učitavanje nikad ne pokreću zvuk.
      expect(playback.playCalls, 0);
      controller.dispose();
    });

    test('dok ništa ne svira, dodir bira tu numeru', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      // Gledaš spisak, izabereš pesmu — ona postaje ta koja će se pustiti.
      await controller.onTrackTapped(_tracks[2]);

      expect(controller.selected?.id, 'trk-003');
      expect(playback.loadedPath, '/muzika/finale.mp3');
      // Izbor i dalje ne pokreće zvuk.
      expect(playback.playCalls, 0);
      controller.dispose();
    });

    test('dok nešto svira, dodir bira novu numeru a staru ne prekida',
        () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();

      await controller.onTrackTapped(_tracks[2]);

      // Izabrana je nova numera...
      expect(controller.selected?.id, 'trk-003');
      // ...a stara i dalje svira, sve dok se ne pritisne veliko dugme.
      expect(controller.sounding?.id, 'trk-001');
      expect(playback.playCalls, 1);
      controller.dispose();
    });

    test('numera van reda se dodirom ubacuje i odmah bira', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback, queue: [_tracks.first]);

      await controller.onTrackTapped(_tracks[1]);

      expect(controller.selected?.id, 'trk-002');
      expect(controller.queue.length, 2);
      controller.dispose();
    });

    test('dodir na trenutnu numeru je vraća na početak', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      playback.emitPosition(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);

      await controller.onTrackTapped(_tracks[0]);

      expect(playback.lastSeek, Duration.zero);
      expect(playback.playCalls, 0);
      controller.dispose();
    });

    test('sledeća i prethodna se kreću kroz red', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      await controller.next();
      expect(controller.selected?.id, 'trk-002');

      // Unazad na samom početku numere ide na prethodnu.
      await controller.previous();
      expect(controller.selected?.id, 'trk-001');
      controller.dispose();
    });

    test('unazad usred numere prvo vraća na njen početak', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.next();
      playback.emitPosition(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);

      await controller.previous();

      expect(controller.selected?.id, 'trk-002');
      expect(playback.lastSeek, Duration.zero);
      controller.dispose();
    });

    test('kraj numere sam prelazi na sledeću i pušta je', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();

      playback.emitCompleted();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.selected?.id, 'trk-002');
      expect(controller.sounding?.id, 'trk-002');
      controller.dispose();
    });

    test('kraj poslednje numere staje i vraća na početak', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback, queue: [_tracks.first]);

      playback.emitCompleted();
      await Future<void>.delayed(Duration.zero);

      expect(controller.selected?.id, 'trk-001');
      expect(playback.pauseCalls, 1);
      expect(playback.lastSeek, Duration.zero);
      controller.dispose();
    });

    test('preskakanje ne izlazi izvan numere', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 15));
      final controller = await _controllerWith(playback);

      await controller.skip(const Duration(seconds: -10));
      expect(playback.lastSeek, Duration.zero);

      await controller.skip(const Duration(seconds: 10));
      await controller.skip(const Duration(seconds: 10));
      expect(playback.lastSeek, const Duration(seconds: 15));
      controller.dispose();
    });

    test('numera bez putanje javlja grešku i ne pušta se', () async {
      final playback = FakePlayback();
      final controller = MusicPlayerController(playback: playback);
      await controller.setQueue([const Track(id: 'x', title: 'Bez fajla')]);

      expect(controller.errorMessage, 'Numera nema putanju do fajla.');
      expect(controller.isReady, isFalse);
      controller.dispose();
    });
  });

  group('nastupni ekran', () {
    testWidgets('prikazuje numeru i vreme, bez puštanja',
        (WidgetTester tester) async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 154),
      );
      final controller = await _controllerWith(playback);

      await tester.pumpWidget(_wrap(PlayerScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Uvodna špica'), findsOneWidget);
      expect(find.text('0:00 / 2:34'), findsOneWidget);
      expect(playback.playCalls, 0);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      controller.dispose();
    });

    testWidgets('veliko dugme pusti numeru i vrati na spisak',
        (WidgetTester tester) async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 154),
      );
      final controller = await _controllerWith(playback);

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlayerScreen(controller: controller),
                    ),
                  ),
                  child: const Text('Otvori'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otvori'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(playback.playCalls, 1);
      // Pesma je krenula, a ruke su slobodne za sledeću — nazad na spisak.
      expect(find.text('Otvori'), findsOneWidget);
      expect(find.byType(PlayerScreen), findsNothing);

      controller.dispose();
    });

    testWidgets('uključen fade in se prosleđuje plejeru',
        (WidgetTester tester) async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 154),
      );
      final controller = await _controllerWith(playback);

      await tester.pumpWidget(_wrap(PlayerScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(playback.lastFadeIn, isTrue);
      controller.dispose();
    });

    testWidgets('vreme i prsten prate poziciju', (WidgetTester tester) async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 200),
      );
      final controller = await _controllerWith(playback);

      await tester.pumpWidget(_wrap(PlayerScreen(controller: controller)));
      await tester.pumpAndSettle();

      playback.emitPosition(const Duration(seconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('0:50 / 3:20'), findsOneWidget);

      final ring = tester.widget<EdgeProgressRing>(
        find.byType(EdgeProgressRing),
      );
      // 50 od 200 sekundi je četvrtina kruga.
      expect(ring.progress.value, closeTo(0.25, 0.001));

      controller.dispose();
    });

    testWidgets('numera koja ne može da se otvori javlja grešku',
        (WidgetTester tester) async {
      final playback = FakePlayback(failsToLoad: true);
      final controller = await _controllerWith(playback);

      await tester.pumpWidget(_wrap(PlayerScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Numera se ne može otvoriti.'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

      controller.dispose();
    });

    testWidgets('izlazak sa ekrana ne gasi plejer — muzika ide dalje',
        (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 10));
      final controller = await _controllerWith(playback);

      await tester.pumpWidget(_wrap(PlayerScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_wrap(const SizedBox()));
      await tester.pumpAndSettle();

      expect(playback.disposed, isFalse);
      controller.dispose();
    });
  });

  group('fade-out', () {
    test('pauza uz fade-out stišava zvuk pre nego što stane', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      controller.setFade(true);

      await controller.play();
      await controller.toggle();

      expect(playback.lastFadeOut, isTrue);
      controller.dispose();
    });

    test('bez fade-out-a pauza seče odmah', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      await controller.play();
      await controller.toggle();

      expect(playback.lastFadeOut, isFalse);
      controller.dispose();
    });

    test('pred kraj numere zvuk se sam spusti', () async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 120),
      );
      final controller = await _controllerWith(playback);
      controller.setFade(true);
      await controller.play();

      // Još je rano — ništa se ne stišava.
      playback.emitPosition(const Duration(seconds: 60));
      await Future<void>.delayed(Duration.zero);
      expect(playback.lastFadeToSilence, isNull);

      // Ušlo se u poslednjih deset sekundi.
      playback.emitPosition(const Duration(seconds: 114));
      await Future<void>.delayed(Duration.zero);
      expect(playback.lastFadeToSilence, const Duration(seconds: 6));

      controller.dispose();
    });

    test('bez fade-out-a se ništa ne stišava pred kraj', () async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 120),
      );
      final controller = await _controllerWith(playback);
      await controller.play();

      playback.emitPosition(const Duration(seconds: 114));
      await Future<void>.delayed(Duration.zero);

      expect(playback.lastFadeToSilence, isNull);
      controller.dispose();
    });

    testWidgets('nastupni ekran ima jedan prekidač za pretapanje',
        (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      await tester.pumpWidget(_wrap(PlayerScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Fade'), findsOneWidget);

      await tester.tap(find.text('Fade'));
      await tester.pumpAndSettle();
      expect(controller.fade, isTrue);
      controller.dispose();
    });
  });

  group('preklapanje', () {
    test('dodir dok nešto svira sprema numeru, bez prekidanja', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();

      await controller.onTrackTapped(_tracks[2]);

      // Bira se nova numera, a stara i dalje svira.
      expect(controller.selected?.id, 'trk-003');
      expect(controller.sounding?.id, 'trk-001');
      expect(controller.isAnotherSounding, isTrue);
      // Nova je spremna u drugom plejeru.
      expect(playback.preloadedPath, '/muzika/finale.mp3');
      controller.dispose();
    });

    test('veliko dugme uz pretapanje preklapa dve numere', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      controller.setFade(true);
      await controller.play();
      await controller.onTrackTapped(_tracks[2]);

      await controller.play();

      expect(playback.crossfadeCalls, 1);
      expect(controller.selected?.id, 'trk-003');
      expect(controller.sounding?.id, 'trk-003');
      expect(controller.isAnotherSounding, isFalse);
      controller.dispose();
    });

    test('bez pretapanja veliko dugme prelazi odmah', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();
      await controller.onTrackTapped(_tracks[2]);

      await controller.play();

      expect(playback.crossfadeCalls, 0);
      expect(controller.sounding?.id, 'trk-003');
      expect(playback.loadedPath, '/muzika/finale.mp3');
      controller.dispose();
    });

    test('dodir na već izabranu numeru dok druga svira ništa ne prekida',
        () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();
      await controller.onTrackTapped(_tracks[2]);

      await controller.onTrackTapped(_tracks[2]);

      expect(controller.sounding?.id, 'trk-001');
      expect(playback.lastSeek, isNull);
      controller.dispose();
    });

    testWidgets('nastupni ekran kaže šta svira kad je izabrana druga numera',
        (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();
      await controller.onTrackTapped(_tracks[2]);

      await tester.pumpWidget(_wrap(PlayerScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Finale'), findsOneWidget);
      expect(find.text('svira: Uvodna špica'), findsOneWidget);
      controller.dispose();
    });
  });
}
