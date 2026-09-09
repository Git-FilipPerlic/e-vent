import 'dart:async';

import 'package:event_app/models/track.dart';
import 'package:event_app/screens/player_screen.dart';
import 'package:event_app/services/audio_playback.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/music/edge_progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: child,
  );
}

/// Lažni plejer: pravi zvuk se u testu ne može pustiti, pa se vodi samo
/// evidencija šta je od plejera traženo.
class FakePlayback implements AudioPlayback {
  FakePlayback({this.failsToLoad = false, this.trackDuration});

  final bool failsToLoad;
  final Duration? trackDuration;

  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();

  String? loadedPath;
  int playCalls = 0;
  int pauseCalls = 0;
  bool? lastFadeIn;
  bool disposed = false;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration?> get duration => _duration.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<Duration?> load(String path) async {
    if (failsToLoad) throw AudioLoadException(path);
    loadedPath = path;
    return trackDuration;
  }

  @override
  Future<void> play({bool fadeIn = false}) async {
    playCalls++;
    lastFadeIn = fadeIn;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _playing.add(false);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
    await _position.close();
    await _duration.close();
    await _playing.close();
  }

  /// Pomera reprodukciju, kao da je pesma odmakla.
  void emitPosition(Duration value) => _position.add(value);
}

const Track _track = Track(
  id: 'trk-001',
  title: 'Uvodna špica',
  artist: 'Miks za doček',
  path: '/muzika/uvodna-spica.mp3',
);

void main() {
  testWidgets('otvara numeru, ali je ne pušta sam',
      (WidgetTester tester) async {
    final playback = FakePlayback(trackDuration: const Duration(seconds: 154));
    await tester.pumpWidget(
      _wrap(PlayerScreen(track: _track, playback: playback)),
    );
    await tester.pumpAndSettle();

    expect(playback.loadedPath, '/muzika/uvodna-spica.mp3');
    expect(find.text('Uvodna špica'), findsOneWidget);
    expect(find.text('Miks za doček'), findsOneWidget);
    expect(find.text('0:00 / 2:34'), findsOneWidget);
    // Zvuk ne kreće dok se ne pritisne dugme.
    expect(playback.playCalls, 0);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('veliko dugme pušta i pauzira', (WidgetTester tester) async {
    final playback = FakePlayback(trackDuration: const Duration(seconds: 154));
    await tester.pumpWidget(
      _wrap(PlayerScreen(track: _track, playback: playback)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(playback.playCalls, 1);
    expect(playback.lastFadeIn, isFalse);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();

    expect(playback.pauseCalls, 1);
  });

  testWidgets('uključen fade in se prosleđuje plejeru',
      (WidgetTester tester) async {
    final playback = FakePlayback(trackDuration: const Duration(seconds: 154));
    await tester.pumpWidget(
      _wrap(PlayerScreen(track: _track, playback: playback)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(playback.lastFadeIn, isTrue);
  });

  testWidgets('vreme i prsten prate poziciju', (WidgetTester tester) async {
    final playback = FakePlayback(trackDuration: const Duration(seconds: 200));
    await tester.pumpWidget(
      _wrap(PlayerScreen(track: _track, playback: playback)),
    );
    await tester.pumpAndSettle();

    playback.emitPosition(const Duration(seconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('0:50 / 3:20'), findsOneWidget);

    final ring = tester.widget<EdgeProgressRing>(
      find.byType(EdgeProgressRing),
    );
    // 50 od 200 sekundi je četvrtina kruga.
    expect(ring.progress.value, closeTo(0.25, 0.001));
  });

  testWidgets('numera koja ne može da se otvori javlja grešku',
      (WidgetTester tester) async {
    final playback = FakePlayback(failsToLoad: true);
    await tester.pumpWidget(
      _wrap(PlayerScreen(track: _track, playback: playback)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Numera se ne može otvoriti.'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('numera bez putanje ne pokušava da se učita',
      (WidgetTester tester) async {
    final playback = FakePlayback();
    await tester.pumpWidget(
      _wrap(
        PlayerScreen(
          track: const Track(id: 'trk-x', title: 'Bez fajla'),
          playback: playback,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(playback.loadedPath, isNull);
    expect(find.text('Numera nema putanju do fajla.'), findsOneWidget);
  });

  testWidgets('izlazak sa ekrana gasi plejer', (WidgetTester tester) async {
    final playback = FakePlayback(trackDuration: const Duration(seconds: 10));
    await tester.pumpWidget(
      _wrap(PlayerScreen(track: _track, playback: playback)),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pumpAndSettle();

    expect(playback.disposed, isTrue);
  });
}
