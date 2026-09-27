import 'package:event_app/models/track.dart';
import 'package:event_app/services/audio_playback.dart';
import 'package:event_app/services/music_player_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

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
  group('zaustavljanje ploče', () {
    // Ono što je traženo: kad se plejer isključi, zvuk se uspori i spusti u
    // visini tona, kao ploča kojoj je stao platter.
    test('pauza bez pretapanja zaustavlja ploču', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();

      await controller.toggle();

      expect(playback.lastWindDown, isTrue);
      controller.dispose();
    });

    // Sa uključenim `Fade` pauza je povlačenje pred publikom — šest sekundi
    // mirnog izlaska, bez efekta.
    test('uz pretapanje pauza ostaje mirno povlačenje', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      controller.setFade(true);
      await controller.play();

      await controller.toggle();

      expect(playback.lastFadeOut, isTrue);
      expect(playback.lastWindDown, isFalse);
      controller.dispose();
    });
  });

  group('brzina ploče', () {
    test('dodir vrti brzinu u krug i javlja je plejeru', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      expect(controller.recordSpeed, RecordSpeed.normal);
      expect(playback.recordSpeed, 1.0);

      await controller.cycleRecordSpeed();
      expect(controller.recordSpeed, RecordSpeed.slow);
      expect(playback.recordSpeed, 0.9);

      await controller.cycleRecordSpeed();
      await controller.cycleRecordSpeed();
      expect(controller.recordSpeed, RecordSpeed.slowest);
      expect(playback.recordSpeed, 0.7);

      // Krug se zatvara na normalnoj brzini.
      await controller.cycleRecordSpeed();
      expect(controller.recordSpeed, RecordSpeed.normal);
      expect(playback.recordSpeed, 1.0);
      controller.dispose();
    });

    test('usporena ploča se prepoznaje po stanju, ne po broju', () {
      expect(RecordSpeed.normal.isSlowed, isFalse);
      expect(RecordSpeed.slow.isSlowed, isTrue);
      expect(RecordSpeed.slowest.isSlowed, isTrue);
    });
  });

  group('dužina ulaska iz tišine', () {
    test('broj se dodirom vrti u krug 1 → 4 → 8 → 1', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      // Srednji stepenik je podrazumevan.
      expect(controller.fadeLength, FadeLength.s4);
      controller.cycleFadeLength();
      expect(controller.fadeLength, FadeLength.s8);
      controller.cycleFadeLength();
      expect(controller.fadeLength, FadeLength.s1);
      controller.cycleFadeLength();
      expect(controller.fadeLength, FadeLength.s4);
      controller.dispose();
    });

    test('izabrani broj je dužina ulaska iz tišine', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      controller.setFade(true);
      controller.cycleFadeLength(); // 8 s

      await controller.play();

      expect(playback.lastFadeIn, isTrue);
      expect(playback.lastFadeInOver, const Duration(seconds: 8));
      controller.dispose();
    });

    // Preklapanje traje koliko i ulazak iz tišine — to pravilo je od ranije,
    // samo što se dužina sada bira.
    test('izabrani broj je i dužina preklapanja', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      controller.setFade(true);
      controller.cycleFadeLength();
      controller.cycleFadeLength(); // 1 s
      await controller.play();
      await controller.onTrackTapped(_tracks[2]);

      await controller.play();

      expect(playback.crossfadeCalls, 1);
      expect(playback.lastCrossfade, const Duration(seconds: 1));
      controller.dispose();
    });
  });

  group('kriva pretapanja', () {
    // Jačina koja se čuje ne prati amplitudu pravolinijski: pola amplitude
    // je oko −6 dB, što se jedva primeti. Zbog toga je pravolinijsko
    // pretapanje zvučalo kao da numera koja izlazi ne izlazi, a ona koja
    // ulazi kao da upada.
    test('krajevi su tišina i puna jačina', () {
      expect(JustAudioPlayback.fadeCurve(0), 0);
      expect(JustAudioPlayback.fadeCurve(1), 1);
    });

    test('na pola puta je zvuk znatno tiši nego pola jačine', () {
      final half = JustAudioPlayback.fadeCurve(0.5);
      expect(half, lessThan(0.2));
      expect(half, greaterThan(0.0));
    });

    test('raste bez skokova', () {
      var previous = 0.0;
      for (var i = 1; i <= 20; i++) {
        final value = JustAudioPlayback.fadeCurve(i / 20);
        expect(value, greaterThan(previous));
        previous = value;
      }
    });
  });

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

    test('numera van reda se dodirom ubacuje kao sledeća', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback, queue: [_tracks.first]);

      await controller.onTrackTapped(_tracks[1]);

      expect(controller.selected?.id, 'trk-002');
      expect(controller.queue.length, 2);
      controller.dispose();
    });

    test('dodir na numeru koja svira dodaje njenu kopiju kao sledeću',
        () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();
      final before = controller.queue.length;

      await controller.onTrackTapped(_tracks[0]);

      // Trik za ponavljanje uvoda: ista numera stoji dvaput, jedna za drugom.
      expect(controller.queue.length, before + 1);
      expect(controller.sounding?.id, 'trk-001');
      expect(controller.selected?.id, 'trk-001');
      expect(controller.queue[0].id, 'trk-001');
      expect(controller.queue[1].id, 'trk-001');
      // I dalje bez zvuka na dodir.
      expect(playback.playCalls, 1);
      controller.dispose();
    });

    test('dodir premešta numeru na mesto sledeća, iza one koja svira',
        () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();

      // Treća numera je na kraju reda; dodir je diže odmah iza prve.
      await controller.onTrackTapped(_tracks[2]);

      expect(controller.queue.map((t) => t.id).toList(), [
        'trk-001',
        'trk-003',
        'trk-002',
      ]);
      expect(controller.selected?.id, 'trk-003');
      expect(controller.sounding?.id, 'trk-001');
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
  });

  group('premotavanje prstom po prstenu', () {
    test('dok prst vuče, prsten prati prst a zvuk se ne dira', () async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 200),
      );
      final controller = await _controllerWith(playback);
      await controller.play();

      controller.beginScrub();
      controller.updateScrub(0.75);

      // Linija je odmah otišla za prstom...
      expect(controller.progress.value, closeTo(0.75, 0.001));
      // ...a pesma još nije premotana: premotavanje u toku vučenja bi krčalo.
      expect(playback.lastSeek, isNull);
      controller.dispose();
    });

    test('pozicija sa plejera ne pomera prsten dok prst vuče', () async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 200),
      );
      final controller = await _controllerWith(playback);
      await controller.play();

      controller.beginScrub();
      controller.updateScrub(0.75);
      playback.emitPosition(const Duration(seconds: 10));
      await Future<void>.delayed(Duration.zero);

      expect(controller.progress.value, closeTo(0.75, 0.001));
      controller.dispose();
    });

    test('kad se prst podigne, pesma se premota na to mesto', () async {
      final playback = FakePlayback(
        trackDuration: const Duration(seconds: 200),
      );
      final controller = await _controllerWith(playback);
      await controller.play();

      controller.beginScrub();
      controller.updateScrub(0.5);
      await controller.endScrub(0.5);

      expect(playback.lastSeek, const Duration(seconds: 100));
      expect(controller.position, const Duration(seconds: 100));
      controller.dispose();
    });

    test('bez spremne numere prevlačenje ne radi ništa', () async {
      final playback = FakePlayback(failsToLoad: true);
      final controller = await _controllerWith(playback);

      controller.beginScrub();
      await controller.endScrub(0.5);

      expect(playback.lastSeek, isNull);
      controller.dispose();
    });
  });

  group('pretapanje naslova', () {
  });

  group('jačina zvuka', () {
    test('kreće od pune i vrti se L → E → F → L', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      expect(controller.volume, VolumeStep.l);
      expect(controller.volume.label, 'L');

      await controller.cycleVolume();
      expect(controller.volume, VolumeStep.e);
      expect(playback.masterVolume, closeTo(0.35, 0.0001));

      await controller.cycleVolume();
      expect(controller.volume, VolumeStep.f);
      // Nisko namerno: glasnoća se ne čuje linearno, pa se na 15% razlika
      // jedva osećala.
      expect(playback.masterVolume, closeTo(0.05, 0.0001));

      await controller.cycleVolume();
      expect(controller.volume, VolumeStep.l);
      expect(playback.masterVolume, 1.0);
      controller.dispose();
    });
  });

  group('veliko dugme uvek pušta', () {
  });

  group('pretapanje se ne prekida premotavanjem', () {
    test('premotavanje ne gasi pretapanje', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();
      playback.fading = true;

      await controller.skip(const Duration(seconds: 10));

      // Poenta: dok pretapanje traje, numera se dovodi na pravo mesto, a da
      // se to u zvuku ne primeti.
      expect(playback.isFading, isTrue);
      expect(playback.lastSeek, const Duration(seconds: 10));
      controller.dispose();
    });

    test('stišavanje pred kraj ne upada usred pretapanja', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      controller.setFade(true);
      await controller.play();
      playback.fading = true;

      // Numera je pri kraju: bez zaštite bi krenulo i stišavanje.
      playback.emitPosition(const Duration(seconds: 55));
      await Future<void>.delayed(Duration.zero);

      expect(playback.fadeToSilenceCalls, 0);
      controller.dispose();
    });

  });

  group('skidanje iz reda čekanja', () {
    test('numera koja svira se ne dira', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();

      final removed = await controller.removeFromQueue('trk-001');

      // Usred nastupa muzika ne sme da stane zbog sređivanja spiska.
      expect(removed, isFalse);
      expect(controller.sounding?.id, 'trk-001');
      expect(controller.queue.length, 3);
      controller.dispose();
    });

    test('numera koja ne svira izlazi iz reda', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();

      final removed = await controller.removeFromQueue('trk-003');

      expect(removed, isTrue);
      expect(controller.queue.map((t) => t.id), ['trk-001', 'trk-002']);
      // Ono što svira ostaje netaknuto.
      expect(controller.sounding?.id, 'trk-001');
      controller.dispose();
    });

    test('ni kopija numere koja svira se ne skida dok svira', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);
      await controller.play();
      // Dodir na numeru koja svira pravi njenu kopiju — trik za ponavljanje
      // uvoda.
      await controller.onTrackTapped(_tracks[0]);
      expect(controller.queue.length, 4);

      final removed = await controller.removeFromQueue('trk-001');

      // Odbija se u celosti: dok ta numera svira, njen red se ne dira. Tako
      // je pravilo jedno i predvidivo, umesto „kopija da, original ne".
      expect(removed, isFalse);
      expect(controller.queue.length, 4);
      controller.dispose();
    });

    test('skidanje izabrane numere pomera izbor', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      // Ništa ne svira; izabrana je prva.
      expect(controller.selected?.id, 'trk-001');
      await controller.removeFromQueue('trk-001');

      expect(controller.queue.map((t) => t.id), ['trk-002', 'trk-003']);
      expect(controller.selected?.id, 'trk-002');
      controller.dispose();
    });

    test('prazan red ostaje bez izabrane numere', () async {
      final playback = FakePlayback(trackDuration: const Duration(seconds: 60));
      final controller = await _controllerWith(playback);

      for (final track in _tracks) {
        await controller.removeFromQueue(track.id);
      }

      expect(controller.queue, isEmpty);
      expect(controller.selected, isNull);
      controller.dispose();
    });
  });

  group('pauza', () {
    test('nikad ne seče naglo, ni kad je Fade isključen', () {
      // Pola sekunde: dovoljno da nestane „klik" na prekidu, prekratko da bi
      // se osetilo kao pretapanje.
      expect(
        JustAudioPlayback.shortPauseFade,
        const Duration(milliseconds: 500),
      );
      // Uz uključen Fade muzika se povlači **tri sekunde** — toliko da
      // deluje kao namera, a ne kao kvar. Šest je u radu bilo predugo
      // čekanje da zvuk utihne (skraćeno 27. septembra 2026).
      expect(
        JustAudioPlayback.pauseFadeDuration,
        const Duration(seconds: 3),
      );
      expect(
        JustAudioPlayback.pauseFadeDuration.inMilliseconds,
        greaterThan(JustAudioPlayback.shortPauseFade.inMilliseconds),
      );
    });
  });

}
