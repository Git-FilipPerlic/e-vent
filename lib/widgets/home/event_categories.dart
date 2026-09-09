import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../theme/app_theme.dart';

/// Kategorije opreme izabrane za ovaj događaj (Vatra, LED, Ring...).
///
/// Manager ih bira ovde, a **Lager tab onda prikazuje baš te kategorije i sve
/// delove koji im pripadaju**. Ono što nije izabrano se na pakovanju ne
/// prikazuje — na nastupu ne treba prelistavati opremu koja se ne nosi.
///
/// Widget je "glup": dobija katalog i izabrano kroz konstruktor, a izmenu
/// javlja ekranu.
class EventCategories extends StatelessWidget {
  const EventCategories({
    super.key,
    required this.catalog,
    required this.selectedIds,
    this.onEdit,
  });

  /// Sve kategorije koje firma ima.
  final List<ChecklistSection> catalog;

  /// Izabrane kategorije za ovaj događaj.
  final List<String> selectedIds;

  /// Otvara izbor. `null` kad korisnik nema dozvolu — kartica je tada ista,
  /// samo bez olovke.
  final VoidCallback? onEdit;

  List<ChecklistSection> get _selected => [
    for (final section in catalog)
      if (selectedIds.contains(section.id)) section,
  ];

  /// Koliko delova ukupno nose izabrane kategorije.
  int get _itemCount =>
      _selected.fold(0, (sum, section) => sum + section.items.length);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Oprema za događaj',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (selected.isNotEmpty)
                  Text(
                    // Broj delova je ono što se zaista pakuje.
                    '${selected.length} · $_itemCount delova',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    iconSize: 18,
                    color: AppColors.accent,
                    tooltip: 'Izmeni kategorije',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (selected.isEmpty)
              Text(
                'Nijedna kategorija nije izabrana',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final section in selected)
                    _CategoryChip(
                      name: section.name,
                      itemCount: section.items.length,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Jedna izabrana kategorija, sa brojem delova koje nosi.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.name, required this.itemCount});

  final String name;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$name · $itemCount',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Izbor kategorija, u listi koja se izvuče odozdo.
///
/// Vraća nov spisak id-jeva, ili `null` ako je korisnik odustao.
Future<List<String>?> showCategoryPicker(
  BuildContext context, {
  required List<ChecklistSection> catalog,
  required List<String> selectedIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) =>
        _CategoryPicker(catalog: catalog, selectedIds: selectedIds),
  );
}

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({required this.catalog, required this.selectedIds});

  final List<ChecklistSection> catalog;
  final List<String> selectedIds;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  late final Set<String> _selected = {...widget.selectedIds};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oprema za događaj',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Izabrane kategorije se pojavljuju na Lager tabu, sa svim '
                  'delovima koji im pripadaju.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.catalog.length,
              itemBuilder: (context, index) {
                final section = widget.catalog[index];
                final isOn = _selected.contains(section.id);

                return CheckboxListTile(
                  value: isOn,
                  onChanged: (value) => setState(() {
                    if (value ?? false) {
                      _selected.add(section.id);
                    } else {
                      _selected.remove(section.id);
                    }
                  }),
                  title: Text(
                    section.name,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${section.items.length} delova',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  activeColor: AppColors.accent,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Odustani'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selected.toList()),
                    child: const Text('Sačuvaj'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
