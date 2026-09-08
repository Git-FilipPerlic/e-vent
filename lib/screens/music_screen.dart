import 'package:flutter/material.dart';

import '../widgets/common/placeholder_body.dart';

/// Muzika tab — plejer za nastup (lista fajlova, tajmer, fade in/out).
class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const PlaceholderBody(
        icon: Icons.music_note_outlined,
        title: 'Muzika tab',
        message: 'Ovde ide lista muzičkih fajlova i plejer sa tajmerom.',
      ),
    );
  }
}
