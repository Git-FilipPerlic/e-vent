import 'package:flutter/material.dart';

import '../../models/weather.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// Vreme u satima kada nastup traje.
///
/// Nije opšta prognoza za dan, nego baš za **sate programa** — poenta je da
/// organizator unapred zna da mu kiša pada na pola nastupa, a ne da to
/// otkrije na licu mesta.
///
/// Widget je "glup": prima gotovu prognozu i stanje učitavanja kroz
/// konstruktor; mrežu zove ekran.
class EventWeather extends StatelessWidget {
  const EventWeather({
    super.key,
    required this.weather,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  /// Prognoza. `null` dok se učitava ili kad je pukla.
  final EventForecast? weather;

  final bool isLoading;

  /// Zašto prognoze nema. Kad je popunjeno, prikazuje se umesto podataka.
  final String? errorMessage;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vreme na događaju',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _body(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ThemeData theme) {
    if (isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Prognoza se učitava…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    final error = errorMessage;
    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
        ],
      );
    }

    final data = weather;
    final start = data?.atStart;
    if (data == null || start == null) {
      return Text(
        'Prognoza za taj dan još nije dostupna',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final wet = data.firstWetHour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(start.condition.icon, color: AppColors.accent, size: 28),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${start.temperature.round()}°',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                start.condition.label,
                maxLines: 2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (wet != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.umbrella_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  // Sat je ono što se pamti: "kiša oko 17h".
                  '${wet.condition.label} oko ${AppDate.time(wet.time)}'
                  ' (${wet.precipitationChance}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
