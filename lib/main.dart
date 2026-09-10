import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/background_audio.dart';
import 'utils/date_format.dart';

Future<void> main() async {
  // Nazivi meseci i dana na srpskom moraju da se učitaju pre prvog crtanja,
  // inače ispis datuma pukne.
  WidgetsFlutterBinding.ensureInitialized();
  await AppDate.init();

  // Servis koji drži reprodukciju u pozadini i crta notifikaciju sa
  // kontrolama. Podiže se pre `runApp` jer ga sistem može pokrenuti i pre
  // nego što se vidi ijedan ekran.
  final audioHandler = await AudioService.init(
    builder: BackgroundAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.eventapp.event_app.audio',
      androidNotificationChannelName: 'Muzika za nastup',
      // Notifikacija ostaje dok muzika svira; sklanja se kad se pauzira.
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Firebase se podiže pre prvog ekrana: bez toga svaki poziv ka bazi ili
  // prijavi puca. Ako podizanje ne uspe (nema mreže pri prvom pokretanju),
  // aplikacija se **i dalje otvara** — samo radi sa lokalnim podacima, što je
  // bolje nego crn ekran pred nastup.
  var hasFirebase = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    hasFirebase = false;
  }

  runApp(EventApp(audioHandler: audioHandler, hasFirebase: hasFirebase));
}
