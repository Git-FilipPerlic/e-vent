import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// HOME-001 — naziv događaja (ime slavljenika), krupno i samo za čitanje.
///
/// Widget je "glup": prima gotov tekst kroz konstruktor, ne zna ništa
/// o servisu ni o bazi.
class EventTitle extends StatelessWidget {
  const EventTitle({super.key, required this.title});

  /// Naziv događaja. Može da bude `null` ili prazan — tada se prikazuje
  /// objašnjenje umesto praznog mesta.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTitle = title != null && title!.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Događaj',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasTitle ? title!.trim() : 'Naziv događaja nije unet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: hasTitle
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: hasTitle ? FontWeight.w600 : FontWeight.w400,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
