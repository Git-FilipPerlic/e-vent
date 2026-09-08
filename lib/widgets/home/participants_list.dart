import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../theme/app_theme.dart';

/// HOME-012 — spisak ekipe sa ulogama (glavni, vozač, pomoćni).
///
/// Widget je "glup": prima gotov spisak učesnika kroz konstruktor.
class ParticipantsList extends StatelessWidget {
  const ParticipantsList({super.key, required this.participants});

  /// Članovi ekipe. Spisak može da bude prazan.
  final List<Participant> participants;

  /// Ikonica po ulozi — boja sama ne znači ništa u mraku, uvek ide uz oblik.
  static IconData iconForRole(String role) {
    switch (role) {
      case ParticipantRole.glavni:
        return Icons.star_rounded;
      case ParticipantRole.vozac:
        return Icons.drive_eta_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Učesnici',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (participants.isNotEmpty)
                  Text(
                    '${participants.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (participants.isEmpty)
              Text(
                'Ekipa još nije određena',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final participant in participants)
                _ParticipantRow(participant: participant),
          ],
        ),
      ),
    );
  }
}

/// Jedan red: ikonica uloge, ime i naziv uloge.
class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = participant.name.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            ParticipantsList.iconForRole(participant.role),
            size: 20,
            // Glavni i vozač su obavezne uloge, pa se izdvajaju bojom;
            // pomoćni ostaju mirni.
            color: participant.isGlavni || participant.isVozac
                ? AppColors.accent
                : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name.isNotEmpty ? name : 'Ime nije uneto',
              style: theme.textTheme.titleSmall?.copyWith(
                color: name.isNotEmpty
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            participant.role,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
