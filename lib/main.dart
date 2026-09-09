import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'app.dart';
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

  // Kasnije ovde ide Firebase.initializeApp() pre runApp().
  runApp(EventApp(audioHandler: audioHandler));
}
