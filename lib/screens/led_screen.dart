import 'package:flutter/material.dart';

import '../widgets/common/placeholder_body.dart';

/// LED tab — kontrola LED rasvete preko Bluetooth-a.
class LedScreen extends StatelessWidget {
  const LedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const PlaceholderBody(
        icon: Icons.lightbulb_outline,
        title: 'LED tab',
        message: 'Ovde ide kontrola LED rasvete: boje, scene i efekti.',
      ),
    );
  }
}
