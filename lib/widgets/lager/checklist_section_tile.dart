import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../theme/app_theme.dart';

/// Jedna sekcija checkliste (Tehnika, Animacija, Vatreni rekviziti...).
///
/// Sekcija se otvara i zatvara; unutra su stavke sa kvačicom i red za
/// dodavanje svoje stavke.
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
    required this.onAddItem,
    required this.onRemoveItem,
    required this.addedItemIds,
    this.canEditItems = false,
  });

  /// Da li korisnik sme da dodaje i briše delove.
  ///
  /// Delovi pripadaju **katalogu firme**, pa ih menja samo manager. Čekiranje
  /// na pakovanju ne traži nikakvu dozvolu.
  final bool canEditItems;

  final ChecklistSection section;

  /// Id-jevi stavki koje su čekirane.
  final Set<String> checkedIds;

  /// Id-jevi stavki koje je korisnik sam dodao — samo one mogu da se obrišu.
  final Set<String> addedItemIds;

  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onToggleItem;
  final ValueChanged<String> onAddItem;
  final ValueChanged<String> onRemoveItem;

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
                canRemove: canEditItems && addedItemIds.contains(item.id),
                onToggle: () => onToggleItem(item.id),
                onRemove: () => onRemoveItem(item.id),
              ),
            if (canEditItems) _AddItemRow(onAdd: onAddItem),
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
    required this.canRemove,
    required this.onToggle,
    required this.onRemove,
  });

  final ChecklistItem item;
  final bool isChecked;
  final bool canRemove;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

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
            if (canRemove)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
                iconSize: 18,
                color: AppColors.textSecondary,
                tooltip: 'Obriši stavku',
              ),
          ],
        ),
      ),
    );
  }
}

/// Red za dodavanje svoje stavke u sekciju.
class _AddItemRow extends StatefulWidget {
  const _AddItemRow({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<_AddItemRow> {
  final TextEditingController _controller = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    // Prazna stavka se ne dodaje — ćutke, bez poruke o grešci.
    if (name.isEmpty) return;

    widget.onAdd(name);
    _controller.clear();
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdding) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: TextButton.icon(
            onPressed: () => setState(() => _isAdding = true),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Dodaj stavku'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Naziv opreme',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(onPressed: _submit, child: const Text('Dodaj')),
        ],
      ),
    );
  }
}
