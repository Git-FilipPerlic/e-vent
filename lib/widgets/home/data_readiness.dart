import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../theme/app_theme.dart';

/// HOME-011 — spremnost podataka: šta od podataka o događaju nedostaje.
///
/// Widget je "glup": dobija događaj i sam prebroji šta fali.
class DataReadiness extends StatelessWidget {
  const DataReadiness({super.key, required this.event});

  /// Događaj. `null` znači da podaci nisu učitani.
  final Event? event;

  /// Podaci bez kojih se ne kreće na događaj, redom kako se traže.
  /// Naziv je onakav kakav korisnik vidi na ekranu.
  static List<String> missingFor(Event? event) {
    if (event == null) return const ['svi podaci'];

    return [
      if (event.title == null) 'naziv događaja',
      if (event.organizerName == null) 'organizator',
      if (event.organizerPhone == null) 'telefon',
      if (event.address == null) 'adresa',
      if (event.eventDate == null) 'datum',
      if (event.departureTime == null) 'vreme polaska',
      if (event.vehicleId == null) 'vozilo',
      if (event.participants.isEmpty) 'učesnici',
    ];
  }

  /// Ukupan broj podataka koji se prati — imenilac trake napretka.
  static const int totalChecks = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = missingFor(event);
    final filled = totalChecks - missing.length;
    final ratio = filled / totalChecks;
    final isComplete = missing.isEmpty;
    final color = isComplete ? AppColors.success : AppColors.warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete
                      ? Icons.task_alt_rounded
                      : Icons.pending_actions_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Spremnost podataka',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '$filled/$totalChecks',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Traka se animira ~300 ms, inače vrednost skače.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) => ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: color,
                  backgroundColor: AppColors.surfaceAlt,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isComplete
                  ? 'Svi podaci su uneti'
                  : 'Nedostaje: ${missing.join(', ')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isComplete ? AppColors.textPrimary : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
