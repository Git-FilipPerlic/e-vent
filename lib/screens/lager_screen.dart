import 'package:flutter/material.dart';

import '../widgets/common/placeholder_body.dart';

/// Lager tab — checklist opreme po sekcijama.
class LagerScreen extends StatelessWidget {
  const LagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lager')),
      body: const PlaceholderBody(
        icon: Icons.checklist_outlined,
        title: 'Lager tab',
        message: 'Ovde ide checklist opreme po sekcijama,\n'
            'pakovanje pre i raspakivanje posle događaja.',
      ),
    );
  }
}
