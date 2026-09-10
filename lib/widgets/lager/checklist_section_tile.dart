import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../theme/app_theme.dart';

/// Jedna sekcija checkliste (Tehnika, Animacija, Vatreni rekviziti...).
///
/// Sekcija se otvara i zatvara; unutra su stavke sa kvačicom.
///
/// **Ovde se delovi ne dodaju ni ne brišu.** Spisak opreme je stvar vlasnika
/// i uređuje se u konzoli, pod „Oprema firme"; na pakovanju se samo čekira.
/// Cela poenta je da pred nastup ne kucaš stavke nego da ih samo prođeš.
///
/// Widget je "glup": dobija sekciju i skup čekiranih stavki kroz konstruktor,
/// a svaku promenu javlja ekranu.
class ChecklistSectionTile extends StatelessWidget {
  const ChecklistSectionTile({
    super.key,
    required this.section,
    required this.checkedIds,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onToggleItem,
  });

  final ChecklistSection section;

  /// Id-jevi stavki koje su čekirane.
  final Set<String> checkedIds;

  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onToggleItem;

  int get _checkedCount =>
      section.items.where((item) => checkedIds.contains(item.id)).length;

  bool get _isComplete =>
      section.items.isNotEmpty && _checkedCount == section.items.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: BorderRadius.circular(kCardRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    _isComplete
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: _isComplete
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      section.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$_checkedCount/${section.items.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(),
            for (final item in section.items)
              _ItemRow(
                item: item,
                isChecked: checkedIds.contains(item.id),
                onToggle: () => onToggleItem(item.id),
              ),
          ],
        ],
      ),
    );
  }
}

/// Jedna stavka opreme sa kvačicom.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.isChecked,
    required this.onToggle,
  });

  final ChecklistItem item;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            // Kvačica se pojavi za ~120 ms — potvrda da je dodir pogodio.
            SizedBox(
              width: kMinTouchTarget,
              height: kMinTouchTarget,
              child: Center(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  child: Icon(
                    isChecked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    key: ValueKey(isChecked),
                    color: isChecked
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                item.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isChecked
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
