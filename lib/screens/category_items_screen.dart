import 'package:flutter/material.dart';

import '../models/checklist.dart';
import '../theme/app_theme.dart';
import '../widgets/common/edit_text_sheet.dart';

/// Delovi jedne kategorije opreme — ono što joj pripada.
///
/// Ovo menja **katalog firme**, ne jedan događaj: dodat rekvizit se pojavi na
/// svakom događaju koji tu kategoriju nosi. Zato ekran to i kaže, da se ne
/// pomeša sa čekiranjem na pakovanju.
///
/// Vraća izmenjenu kategoriju kroz `Navigator.pop`, ili `null` ako se ništa
/// nije promenilo.
class CategoryItemsScreen extends StatefulWidget {
  const CategoryItemsScreen({super.key, required this.category});

  final ChecklistSection category;

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  late List<ChecklistItem> _items = [...widget.category.items];
  bool _changed = false;

  int _nextNumber = 1;

  Future<void> _add() async {
    final name = await showEditTextSheet(
      context,
      label: 'Nov deo u kategoriji „${widget.category.name}"',
      value: null,
      hint: 'Naziv opreme',
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    setState(() {
      _items = [
        ..._items,
        ChecklistItem(
          id: '${widget.category.id}-novo-${_nextNumber++}',
          name: trimmed,
        ),
      ];
      _changed = true;
    });
  }

  Future<void> _rename(ChecklistItem item) async {
    final name = await showEditTextSheet(
      context,
      label: 'Naziv dela',
      value: item.name,
    );
    if (name == null) return;

    final trimmed = name.trim();
    setState(() {
      // Prazan naziv briše deo — isto pravilo kao svuda u aplikaciji.
      _items = trimmed.isEmpty
          ? _items.where((i) => i.id != item.id).toList()
          : [
              for (final i in _items)
                if (i.id == item.id)
                  ChecklistItem(id: i.id, name: trimmed)
                else
                  i,
            ];
      _changed = true;
    });
  }

  void _remove(ChecklistItem item) {
    setState(() {
      _items = _items.where((i) => i.id != item.id).toList();
      _changed = true;
    });
  }

  void _close() {
    Navigator.of(context).pop(
      _changed
          ? ChecklistSection(
              id: widget.category.id,
              name: widget.category.name,
              items: _items,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
          leading: IconButton(
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Nazad',
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  // Bez ovoga se lako pomisli da se menja samo ovaj događaj.
                  'Izmene važe za sve događaje koji nose ovu kategoriju.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'U ovoj kategoriji nema nijednog dela.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _ItemRow(
                            item: item,
                            onRename: () => _rename(item),
                            onRemove: () => _remove(item),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Dodaj deo'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Jedan deo kategorije: naziv, izmena i brisanje.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onRename,
    required this.onRemove,
  });

  final ChecklistItem item;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRename,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRename,
                icon: const Icon(Icons.edit_rounded),
                iconSize: 18,
                color: AppColors.accent,
                tooltip: 'Izmeni naziv',
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                iconSize: 18,
                color: AppColors.textSecondary,
                tooltip: 'Obriši deo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
