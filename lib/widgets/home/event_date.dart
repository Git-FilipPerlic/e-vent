import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// HOME-005 — datum i sat događaja, u jednom sitnom redu **iznad naziva
/// događaja**.
///
/// Namerno je suptilno i manje od naziva: to je podatak koji se hvata
/// pogledom, ne čita. Godina se ne piše — posao se planira nedeljama unapred,
/// pa godina samo zauzima mesto. Sat je istaknut bojom `accent`, jer izvođač
/// iz njega u glavi izračuna sve ostalo.
///
/// Widget je "glup": prima gotov datum kroz konstruktor.
class EventDate extends StatelessWidget {
  const EventDate({super.key, required this.date});

  /// Datum i vreme događaja. Može da bude `null`.
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = date;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                value != null ? AppDate.dayMonth(value) : 'Datum nije unet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (value != null)
              Text(
                AppDate.time(value),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
