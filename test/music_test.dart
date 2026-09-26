import 'package:event_app/models/track.dart';
import 'package:event_app/screens/music_screen.dart';
import 'package:event_app/screens/wave_screen.dart';
import 'package:event_app/services/music_player_controller.dart';
import 'package:event_app/services/music_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/common/slide_switch.dart';
import 'package:event_app/widgets/music/track_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

/// Lažni izvor numera — spisak u aplikaciji je prazan dok korisnik ne doda
/// fajlove sa telefona, pa se u testu podmeće nekoliko numera.
class FakeMusicService implements MusicService {
  FakeMusicService(this.tracks);

  final List<Track> tracks;

  @override
  Future<List<Track>> loadTracks() async => tracks;
}

final List<Track> _sample = [
  const Track(
    id: 'trk-001',
    title: 'Uvodna špica',
    artist: 'Miks za doček',
    source: TrackSource.playlist,
    duration: Duration(seconds: 154),
    path: '/muzika/uvodna-spica.mp3',
  ),
  const Track(
    id: 'trk-002',
    title: 'Igre za decu',
    artist: 'Dečji miks',
    source: TrackSource.playlist,
    duration: Duration(seconds: 212),
    path: '/muzika/igre-za-decu.mp3',
  ),
  const Track(
    id: 'trk-003',
    title: 'Vatreni show',
    duration: Duration(seconds: 187),
    path: '/muzika/vatreni-show.mp3',
  ),
  const Track(id: 'trk-004', path: '/muzika/bez-naziva-04.mp3'),
];

void main() {
  group('numera', () {
    test('naziv pada na naziv fajla, pa na objašnjenje', () {
      expect(
        const Track(id: 't', title: 'Uvodna špica').displayTitle,
        'Uvodna špica',
      );
      expect(
        const Track(id: 't', path: '/muzika/bez-naziva-04.mp3').displayTitle,
        'bez-naziva-04',
      );
      expect(const Track(id: 't').displayTitle, 'Numera bez naziva');
      // Prazan naziv se tretira kao da ga nema.
      expect(
        const Track(id: 't', title: '   ', path: '/m/a.mp3').displayTitle,
        // Bez nastavka: „.mp3" na kraju svakog reda ne kaže ništa.
        'a',
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
    testWidgets('u jednom redu: naziv sa izvođačem, ikonica izvora, trajanje',
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

      expect(find.text('Uvodna špica · Miks za doček'), findsOneWidget);
      // Izvor se vidi po ikonici, jer za tekst u zbijenom redu nema mesta.
      expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
      expect(find.text('2:34'), findsOneWidget);
    });

    testWidgets('bez izvođača stoji samo naziv',
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

      expect(find.text('Vatreni show'), findsOneWidget);
      // Obe ikonice su muzičke: folder u spisku pesama zbunjuje.
      expect(find.byIcon(Icons.audiotrack_rounded), findsOneWidget);
    });
  });

  group('Muzika ekran', () {
    testWidgets('učita spisak numera', (WidgetTester tester) async {
      final controller = MusicPlayerController(
        playback: FakePlayback(trackDuration: const Duration(seconds: 60)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(
            service: FakeMusicService(_sample),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Uvodna špica'), findsOneWidget);
      expect(find.textContaining('Igre za decu'), findsOneWidget);
      // Numera bez naziva pada na naziv fajla.
      expect(find.textContaining('bez-naziva-04'), findsOneWidget);
    });

    testWidgets('bez God mode-a dodir odmah pušta numeru',
        (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(
            service: FakeMusicService(_sample),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Igre za decu'));
      // Ne `pumpAndSettle`: stubići uz numeru koja svira se stalno pomeraju.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(playback.playCalls, 1);
      expect(controller.sounding?.title, 'Igre za decu');
    });

    testWidgets('u God mode-u dodir samo bira numeru za Ekran 2',
        (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(
            service: FakeMusicService(_sample),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // God mode se uključuje prevlačenjem prekidača.
      await tester.drag(_switch('God mode'), const Offset(80, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Igre za decu'));
      await tester.pumpAndSettle();

      expect(playback.playCalls, 0);
      expect(find.text('SLEDEĆA: IGRE ZA DECU'), findsOneWidget);
    });

    testWidgets('dodir na prekidač ga ne menja, nego kaže da se prevlači',
        (WidgetTester tester) async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = MusicPlayerController(playback: playback);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(
            service: FakeMusicService(_sample),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_switch('God mode'));
      await tester.pumpAndSettle();

      expect(
        find.text('Prevuci prekidač — dodir ga ne menja'),
        findsOneWidget,
      );
      expect(
        tester.widget<SlideSwitch>(_switch('God mode')).value,
        isFalse,
      );
    });

    testWidgets('Ekran 2 bez God mode-a objasni zašto se ne otvara',
        (WidgetTester tester) async {
      final controller = MusicPlayerController(
        playback: FakePlayback(trackDuration: const Duration(seconds: 60)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(
            service: FakeMusicService(_sample),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ekran 2 radi uz God mode'), findsOneWidget);
    });

    testWidgets('jačina se vrti L → E → F', (WidgetTester tester) async {
      final controller = MusicPlayerController(
        playback: FakePlayback(trackDuration: const Duration(seconds: 60)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(
            service: FakeMusicService(_sample),
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();
      expect(find.text('E'), findsOneWidget);
      expect(controller.volume, VolumeStep.e);
    });
  });

  group('podrazumevani servis', () {
    test('spisak je prazan dok korisnik ne doda numere', () async {
      // Izmišljene numere su uklonjene: numera koja ne može da se pusti
      // samo smeta na nastupu.
      expect(await MockMusicService().loadTracks(), isEmpty);
    });

    testWidgets('prazan spisak to i kaže', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MusicScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nijedna numera nije dodata.'), findsOneWidget);
      // Jedini put do numera je sopstveni pregled fajlova.
      expect(find.text('Pregledaj fajlove'), findsOneWidget);
    });
  });

  group('prazan spisak', () {
    testWidgets('bez numera nema ni trake sa „Uredi"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(MusicScreen(service: _EmptyMusicService())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nijedna numera nije dodata.'), findsOneWidget);
      // Nema šta da se uređuje; do numera se stiže dugmetom u sredini.
      expect(find.text('Uredi'), findsNothing);
    });
  });

  group('talasni oblik', () {
    testWidgets('zadržavanje prsta na numeri otvara talasni oblik', (
      WidgetTester tester,
    ) async {
      final controller = MusicPlayerController(
        playback: FakePlayback(trackDuration: const Duration(seconds: 60)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(service: _SampleMusicService(), controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Druga'));
      await tester.pumpAndSettle();

      expect(find.byType(WaveScreen), findsOneWidget);
    });

    // Red se pod prstom skupi i izgubi razdelnik. Dok se to radilo tako što
    // dekoracija ode na `null`, `Container` bi izbacio ceo sloj iz stabla, a
    // sa njim i widget koji hvata dodir — pa se zadržavanje prekidalo čim
    // počne. Zato se ovde okvir crta između pritiska i puštanja.
    testWidgets('zadržavanje prsta radi i kad se red skupi pod prstom', (
      WidgetTester tester,
    ) async {
      final controller = MusicPlayerController(
        playback: FakePlayback(trackDuration: const Duration(seconds: 60)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(service: _SampleMusicService(), controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final press = await tester.startGesture(tester.getCenter(find.text('Druga')));
      // Dovoljno da se okine pritisak i da se red prerisa skupljen.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 500));
      await press.up();
      await tester.pumpAndSettle();

      expect(find.byType(WaveScreen), findsOneWidget);
    });

    // Pretapanje se bira i na talasu: izvođač tu bira deo pesme koji ulazi
    // dok prethodna izlazi, pa mora da može da uključi Fade bez izlaska.
    testWidgets('talas ima svoj prekidač za pretapanje', (
      WidgetTester tester,
    ) async {
      final controller = MusicPlayerController(
        playback: FakePlayback(trackDuration: const Duration(seconds: 60)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(service: _SampleMusicService(), controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Druga'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(WaveScreen),
          matching: find.byType(SlideSwitch),
        ),
        findsOneWidget,
      );
    });
  });

  group('skidanje numera sa spiska', () {
    Future<void> openEditing(WidgetTester tester) async {
      final controller = MusicPlayerController(
        playback: FakePlayback(trackDuration: const Duration(seconds: 60)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          MusicScreen(service: _SampleMusicService(), controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uredi'));
      await tester.pumpAndSettle();
      // Druga numera u spisku.
      await tester.tap(find.byIcon(Icons.remove_circle_rounded).at(1));
      await tester.pumpAndSettle();
    }

    testWidgets('„Uredi" nudi skidanje, uz jasno „fajl ostaje"', (
      WidgetTester tester,
    ) async {
      await openEditing(tester);

      expect(find.text('Skloni'), findsOneWidget);
      // Bez ovoga bi „skloni" zvučalo kao brisanje muzike sa telefona.
      expect(find.textContaining('ostaje na telefonu'), findsOneWidget);
    });

    testWidgets('odustajanje ostavlja spisak kakav jeste', (
      WidgetTester tester,
    ) async {
      await openEditing(tester);
      await tester.tap(find.text('Odustani'));
      await tester.pumpAndSettle();

      expect(find.text('Druga'), findsOneWidget);
    });

    testWidgets('potvrda skida numeru sa spiska', (WidgetTester tester) async {
      await openEditing(tester);
      await tester.tap(find.text('Skloni'));
      await tester.pumpAndSettle();

      expect(find.text('Druga'), findsNothing);
      // Ostale numere ostaju.
      expect(find.text('Prva'), findsOneWidget);
    });
  });

  group('naziv fajla', () {
    test('nastavak se skida', () {
      expect(Track.withoutExtension('Beat It.mp3'), 'Beat It');
      expect(Track.withoutExtension('spot.mix.final.wav'), 'spot.mix.final');
    });

    test('ime bez nastavka ostaje kakvo jeste', () {
      expect(Track.withoutExtension('Uvod'), 'Uvod');
    });

    test('skriven fajl se ne kljaštri', () {
      // Tačka na početku znači skriven fajl, ne nastavak.
      expect(Track.withoutExtension('.tajna'), '.tajna');
    });
  });
}

/// Prekidač po nazivu za čitač ekrana (na samom prekidaču nema teksta).
Finder _switch(String label) => find.byWidgetPredicate(
  (widget) => widget is SlideSwitch && widget.label == label,
);

/// Prazan spisak — kao na tek instaliranoj aplikaciji.
class _EmptyMusicService implements MusicService {
  @override
  Future<List<Track>> loadTracks() async => const [];
}

/// Dve numere, dovoljno da spisak ne bude prazan.
class _SampleMusicService implements MusicService {
  @override
  Future<List<Track>> loadTracks() async => const [
    Track(id: 'trk-1', title: 'Prva', path: '/muzika/1.mp3'),
    Track(id: 'trk-2', title: 'Druga', path: '/muzika/2.mp3'),
  ];
}
