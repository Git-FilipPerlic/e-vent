import 'package:flutter/material.dart';

import '../widgets/common/placeholder_body.dart';

/// Home tab — priprema i polazak na događaj.
/// Sadržaj se dodaje redom po elementima iz CLAUDE.md (naziv, organizator,
/// telefon, adresa, datum, sat, polazak, vozilo, učesnici, status, scenario).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const PlaceholderBody(
        icon: Icons.home_outlined,
        title: 'Home tab',
        message: 'Ovde ide priprema za događaj: naziv, organizator, adresa,\n'
            'datum, vreme polaska, ekipa i scenario.',
      ),
    );
  }
}
