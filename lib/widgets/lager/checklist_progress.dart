import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Traka napretka pakovanja: koliko je stavki čekirano od ukupnog broja.
///
/// Widget je "glup": prima gotove brojeve kroz konstruktor.
class ChecklistProgress extends StatelessWidget {
  const ChecklistProgress({
    super.key,
    required this.checked,
    required this.total,
    required this.label,
  });

  final int checked;
  final int total;

  /// "Spakovano" ili "Raspakovano" — zavisi od toga šta se trenutno radi.
  final String label;

  bool get isComplete => total > 0 && checked == total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : checked / total;
    final color = isComplete ? AppColors.success : AppColors.accent;

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
                      ? Icons.check_circle_rounded
                      : Icons.inventory_2_outlined,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '$checked/$total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}
