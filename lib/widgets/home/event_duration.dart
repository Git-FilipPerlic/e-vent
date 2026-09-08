import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// Ugovoreno trajanje nastupa — koliko je dogovoreno da se radi.
///
/// Uz trajanje se odmah računa i **kad se završava**, jer je to podatak koji
/// izvođač inače računa u glavi pred svaki nastup.
///
/// Widget je "glup": prima trajanje i početak kroz konstruktor.
class EventDuration extends StatelessWidget {
  const EventDuration({super.key, required this.minutes, required this.start});

  /// Ugovoreno trajanje u minutima. Može da bude `null`.
  final int? minutes;

  /// Početak događaja — potreban samo da bi se ispisao kraj.
  final DateTime? start;

  /// `90 min` → `1 h 30 min`, `120` → `2 h`.
  static String format(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = minutes;
    final from = start;

    final DateTime? to = (value != null && from != null)
        ? from.add(Duration(minutes: value))
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_bottom_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ugovoreno trajanje',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value != null
                        ? EventDuration.format(value)
                        : 'Trajanje nije ugovoreno',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (to != null && from != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      // Kraj nastupa je ono što izvođača zaista zanima.
                      'Od ${AppDate.time(from)} do ${AppDate.time(to)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
