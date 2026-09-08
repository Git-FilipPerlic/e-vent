import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../theme/app_theme.dart';

/// HOME-013 — status tima: da li su popunjene obavezne uloge
/// **glavni** i **vozač**.
///
/// Widget je "glup": prima spisak učesnika i sam iz njega izvodi zaključak,
/// bez servisa i baze.
class TeamStatus extends StatelessWidget {
  const TeamStatus({super.key, required this.participants});

  final List<Participant> participants;

  /// Uloge koje ekipa mora da ima da bi mogla da krene.
  static const List<String> requiredRoles = [
    ParticipantRole.glavni,
    ParticipantRole.vozac,
  ];

  /// Obavezne uloge koje niko nije preuzeo.
  List<String> get missingRoles {
    return [
      for (final role in requiredRoles)
        if (!participants.any((p) => p.role == role)) role,
    ];
  }

  bool get isReady => missingRoles.isEmpty;

  /// Rečenica koja stoji na kartici.
  String get message {
    final missing = missingRoles;
    if (missing.isEmpty) return 'Ekipa je kompletna';
    if (missing.length == 1) return 'Nedostaje uloga: ${missing.first}';
    return 'Nedostaju uloge: ${missing.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = isReady;
    final color = ready ? AppColors.success : AppColors.warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Boja nikad ne stoji sama — uvek uz ikonicu i tekst.
            Icon(
              ready ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status tima',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
