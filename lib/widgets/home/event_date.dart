import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// HOME-005 — datum događaja, ispisan na srpskom (`12. septembar 2026.`).
///
/// Widget je "glup": prima gotov datum kroz konstruktor.
class EventDate extends StatelessWidget {
  const EventDate({super.key, required this.date});

  /// Datum događaja. Može da bude `null` — tada se prikazuje objašnjenje.
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = date;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.event_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datum događaja',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value != null ? AppDate.long(value) : 'Datum nije unet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          value != null ? FontWeight.w600 : FontWeight.w400,
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
