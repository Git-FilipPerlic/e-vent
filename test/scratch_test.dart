// Vučenje zvuka prstom po talasu — „scratch".

import 'package:event_app/models/track.dart';
import 'package:event_app/screens/wave_screen.dart';
import 'package:event_app/services/music_player_controller.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/common/slide_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const Track _track = Track(
  id: 'trk-1',
  title: 'Act Won',
  path: '/muzika/01. Act Won.mp3',
  duration: Duration(minutes: 3),
);

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

Finder _switch(String label) => find.byWidgetPredicate(
  (widget) => widget is SlideSwitch && widget.label == label,
);

void main() {
  group('vučenje zvuka', () {
    test('zvuk skače za prstom i menja brzinu bez klizanja', () async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      await controller.setQueue([_track]);
      await controller.play();

      await controller.scratchTo(const Duration(seconds: 45), 1.8);

      expect(playback.lastSeek, const Duration(seconds: 45));
      expect(playback.lastScratchSpeed, 1.8);
      controller.dispose();
    });

    // Unazad plejer ne ume da svira, pa se tamo samo premotava uz najnižu
    // brzinu — bolje isprekidan zvuk nego tišina koja deluje kao kvar.
    test('vučenje unazad pada na najnižu brzinu', () async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      await controller.setQueue([_track]);
      await controller.play();

      await controller.scratchTo(const Duration(seconds: 20), -1.2);

      expect(playback.lastScratchSpeed, 0.25);
      controller.dispose();
    });

    test('dok ništa ne svira vučenje ne dira plejer', () async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      await controller.setQueue([_track]);

      await controller.scratchTo(const Duration(seconds: 45), 1.5);

      expect(playback.lastScratchSpeed, isNull);
      controller.dispose();
    });

    test('podignut prst vraća brzinu na zadatu', () async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      await controller.setQueue([_track]);
      await controller.play();

      await controller.endScratch();

      expect(playback.scratchEndCalls, 1);
      controller.dispose();
    });
  });

  group('prekidač na talasu', () {
    testWidgets('talas nudi Scratch pored Pretapanja', (
      WidgetTester tester,
    ) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(WaveScreen(controller: controller, track: _track, fade: false)),
      );
      await tester.pumpAndSettle();

      expect(_switch('Vučenje zvuka'), findsOneWidget);
      expect(
        tester.widget<SlideSwitch>(_switch('Vučenje zvuka')).value,
        isFalse,
      );
    });

    // Dok se talas samo razgleda, zvuk ne sme da skače za prstom.
    testWidgets('dok je Scratch isključen skrol ne dira zvuk', (
      WidgetTester tester,
    ) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      await controller.setQueue([_track]);
      await controller.play();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(WaveScreen(controller: controller, track: _track, fade: false)),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(playback.lastScratchSpeed, isNull);
      expect(playback.scratchEndCalls, 0);
    });

    // Uključen: prevlačenje po talasu vuče i sam zvuk, a brzina ide po
    // tome koliko je prst prešao. Podignut prst je vraća na normalnu.
    testWidgets('sa uključenim Scratch-om prevlačenje vuče zvuk', (
      WidgetTester tester,
    ) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      await controller.setQueue([_track]);
      await controller.play();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(WaveScreen(controller: controller, track: _track, fade: false)),
      );
      await tester.pumpAndSettle();

      // Prekidač se pomera prevlačenjem, ne dodirom.
      await tester.drag(_switch('Vučenje zvuka'), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SlideSwitch>(_switch('Vučenje zvuka')).value,
        isTrue,
      );

      final wave = find.byType(SingleChildScrollView).first;
      final drag = await tester.startGesture(tester.getCenter(wave));
      for (var i = 0; i < 6; i++) {
        await drag.moveBy(const Offset(0, -40));
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(playback.lastScratchSpeed, isNotNull);

      await drag.up();
      await tester.pumpAndSettle();
      expect(playback.scratchEndCalls, greaterThan(0));
    });

    // Prekidač se menja prevlačenjem, kao svi ostali — okrznut prst ne sme
    // da uključi vučenje zvuka usred programa.
    testWidgets('dodir na prekidač ga ne menja', (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(minutes: 3));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(WaveScreen(controller: controller, track: _track, fade: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(_switch('Vučenje zvuka'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<SlideSwitch>(_switch('Vučenje zvuka')).value,
        isFalse,
      );
      expect(find.text('Prevuci prekidač — dodir ga ne menja'), findsOneWidget);
    });
  });
}
