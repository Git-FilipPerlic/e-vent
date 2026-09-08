import 'package:flutter/material.dart';

import 'app.dart';
import 'utils/date_format.dart';

Future<void> main() async {
  // Nazivi meseci i dana na srpskom moraju da se učitaju pre prvog crtanja,
  // inače ispis datuma pukne.
  WidgetsFlutterBinding.ensureInitialized();
  await AppDate.init();

  // Kasnije ovde ide Firebase.initializeApp() pre runApp().
  runApp(const EventApp());
}
