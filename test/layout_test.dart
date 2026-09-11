import 'package:event_app/models/checklist.dart';
import 'package:event_app/models/track.dart';
import 'package:event_app/screens/events_screen.dart';
import 'package:event_app/screens/lager_screen.dart';
import 'package:event_app/screens/music_screen.dart';
import 'package:event_app/screens/player_screen.dart';
import 'package:event_app/services/music_player_controller.dart';
import 'package:event_app/services/music_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/event_categories.dart';
import 'package:event_app/widgets/music/playback_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// MUSIC-022 — provera da se raspored ne prelije ni na uskom telefonu ni na
/// velikom, ni kad je sistemski font uvećan.
///
/// Ovo nije formalnost: prelivanje od 16 piksela na nastupnom ekranu je
/// jednom već odnelo dugme "+10" sa ekrana, i primećeno je tek na snimku
/// telefona. Test to hvata pre telefona.

/// Ekrani na kojima se proverava: uzak telefon, uobičajen, veliki i tablet.
const List<Size> _screens = [
  Size(320, 640),
  Size(393, 851),
  Size(430, 932),
  Size(800, 1280),
];

/// Uvećanja teksta koja ljudi zaista koriste.
const List<double> _textScales = [1.0, 1.3];

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: child);
}

final List<Track> _sample = [
  for (var i = 1; i <= 12; i++)
    Track(
      id: 'trk-$i',
      title: 'Numera sa poprilično dugačkim nazivom broj $i.mp3',
      artist: 'Izvođač sa dugačkim imenom $i',
      path: '/muzika/$i.mp3',
    ),
];

/// Katalog sa dugačkim nazivima — najgori slučaj za širinu reda.
const List<ChecklistSection> _catalog = [
  ChecklistSection(
    id: 'sec-tehnika',
    name: 'Tehnika',
    items: [
      ChecklistItem(id: 't1', name: 'Zvučnik'),
      ChecklistItem(id: 't2', name: 'Mikrofon'),
      ChecklistItem(id: 't3', name: 'Produžni kabl'),
    ],
  ),
  ChecklistSection(
    id: 'sec-animacija',
    name: 'Animacija',
    items: [
      ChecklistItem(id: 'a1', name: 'Kostimi'),
      ChecklistItem(id: 'a2', name: 'Baloni'),
    ],
  ),
];

class _FakeMusicService implements MusicService {
  @override
  Future<List<Track>> loadTracks() async => _sample;
}

/// Postavlja veličinu ekrana i uvećanje teksta, pa sve vraća kako je bilo.
Future<void> _atSize(
  WidgetTester tester,
  Size size,
  double textScale,
  Future<void> Function() body,
) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await body();
}

Widget _scaled(double textScale, Widget child) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

void main() {
  setUpAll(() => AppDate.init());

  // Neonski sjaj se vrti bez kraja, pa `pumpAndSettle` nikad ne bi dočekao
  // mirno stanje. Uz sistemski „smanjen pokret" on stoji.
  setUp(() {
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });

  for (final size in _screens) {
    for (final scale in _textScales) {
      final label = '${size.width.toInt()}x${size.height.toInt()}'
          ' pri uvećanju teksta ${scale}x';

      testWidgets('spisak numera staje $label', (WidgetTester tester) async {
        await _atSize(tester, size, scale, () async {
          await tester.pumpWidget(
            _wrap(
              _scaled(scale, MusicScreen(service: _FakeMusicService())),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      });

      testWidgets('nastupni ekran staje $label', (WidgetTester tester) async {
        final playback = FakePlayback(
          trackDuration: const Duration(seconds: 154),
        );
        final controller = MusicPlayerController(playback: playback);
        addTearDown(controller.dispose);
        await controller.setQueue(_sample);

        await _atSize(tester, size, scale, () async {
          await tester.pumpWidget(
            _wrap(_scaled(scale, PlayerScreen(controller: controller))),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      });

      testWidgets('traka plejera staje $label', (WidgetTester tester) async {
        // Traka nosi šest dugmadi i slovo za jačinu; na uskom telefonu sa
        // uvećanim fontom se već jednom prelila za 44 piksela.
        final playback = FakePlayback(
          trackDuration: const Duration(seconds: 154),
        );
        final controller = MusicPlayerController(playback: playback);
        addTearDown(controller.dispose);
        await controller.setQueue(_sample);

        await _atSize(tester, size, scale, () async {
          await tester.pumpWidget(
            _wrap(
              _scaled(
                scale,
                Scaffold(
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: PlaybackBar(
                      controller: controller,
                      onOpenPlayer: () {},
                      onBrowse: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      });

      testWidgets('spisak događaja staje $label', (WidgetTester tester) async {
        await _atSize(tester, size, scale, () async {
          await tester.pumpWidget(
            _wrap(_scaled(scale, EventsScreen(onOpen: (_) {}))),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      });

      testWidgets('kartica opreme staje $label', (WidgetTester tester) async {
        // Naslov, broj delova i olovka moraju da stanu u isti red. Na uskom
        // telefonu se to jednom već prelilo za 22 piksela.
        await _atSize(tester, size, scale, () async {
          await tester.pumpWidget(
            _wrap(
              _scaled(
                scale,
                Scaffold(
                  body: EventCategories(
                    catalog: _catalog,
                    selectedIds: const ['sec-tehnika', 'sec-animacija'],
                    onEdit: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      });

      testWidgets('Lager staje $label', (WidgetTester tester) async {
        await _atSize(tester, size, scale, () async {
          await tester.pumpWidget(_wrap(_scaled(scale, const LagerScreen())));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      });
    }
  }
}
