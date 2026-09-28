import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// HOME-025 — scenario: tačke programa.
///
/// Scenario je deo događaja i vidi ga cela ekipa. Ko ima pravo izmene može
/// da doda tačku, obriše je i **premesti prevlačenjem** za ručicu levo: kad
/// se jedna preskoči, ne briše se ceo spisak nego se samo promeni redosled.
/// Bez prava izmene spisak se samo čita.
/// Widget je "glup": dobija spisak kroz konstruktor, a dodavanje, brisanje i
/// premeštanje javlja ekranu.
class ScenarioList extends StatefulWidget {
  const ScenarioList({
    super.key,
    required this.items,
    required this.canEdit,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  /// Tačke programa, redom kojim se izvode.
  final List<String> items;

  /// `false` — nema ručica, brisanja ni dodavanja; spisak se samo čita.
  final bool canEdit;

  final ValueChanged<String> onAdd;

  /// Briše tačku po rednom broju unutar [items].
  final ValueChanged<int> onRemove;

  /// Tačka sa mesta `from` ide na mesto `to`, računato **posle** vađenja iz
  /// spiska — ekran samo uradi `removeAt(from)` pa `insert(to, …)`.
  final void Function(int from, int to) onReorder;

  @override
  State<ScenarioList> createState() => _ScenarioListState();
}

class _ScenarioListState extends State<ScenarioList> {
  final TextEditingController _newItem = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _newItem.text.trim();
    // Prazna tačka programa nema smisla — ćutke se odbija.
    if (text.isEmpty) return;

    widget.onAdd(text);
    _newItem.clear();
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Scenario',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  Text(
                    '${items.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              Text(
                'Scenario nije unet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else if (!widget.canEdit)
              for (var i = 0; i < items.length; i++)
                _ScenarioRow(index: i, text: items[i])
            else
              // Spisak ne skroluje sam — skroluje ceo Home ekran oko njega.
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                // Premešta se samo za ručicu: dug pritisak bilo gde po redu
                // bi se otimao sa skrolovanjem i prevlačenjem između stranica.
                buildDefaultDragHandles: false,
                itemCount: items.length,
                onReorderItem: (from, to) {
                  if (to != from) widget.onReorder(from, to);
                },
                proxyDecorator: (child, index, animation) => Material(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                ),
                itemBuilder: (context, i) => _ScenarioRow(
                  // Ista tačka može da se upiše dvaput, pa ključ nosi i mesto.
                  key: ValueKey('scenario-$i-${items[i]}'),
                  index: i,
                  text: items[i],
                  onRemove: () => widget.onRemove(i),
                  canMove: true,
                ),
              ),
            if (widget.canEdit) const SizedBox(height: AppSpacing.sm),
            if (widget.canEdit && !_isAdding)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Dodaj tačku'),
                ),
              )
            else if (widget.canEdit)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newItem,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Nova tačka programa',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Dodaj'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Jedna tačka programa: redni broj i tekst, a uz pravo izmene i ručica za
/// premeštanje i dugme za brisanje.
class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    super.key,
    required this.index,
    required this.text,
    this.onRemove,
    this.canMove = false,
  });

  /// Mesto u spisku, od nule.
  final int index;
  final String text;

  /// `null` kad nema prava izmene.
  final VoidCallback? onRemove;

  /// Da li stoji ručica za premeštanje. Traži [ReorderableListView] iznad.
  final bool canMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final row = Row(
      children: [
        if (canMove)
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: 'Premesti tačku',
              child: SizedBox(
                width: kMinTouchTarget,
                height: kMinTouchTarget,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        SizedBox(
          width: 24,
          child: Text(
            '${index + 1}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            iconSize: 18,
            color: AppColors.textSecondary,
            tooltip: 'Obriši tačku',
          ),
      ],
    );

    // Bez ručice i dugmeta red je nizak, pa mu treba malo vazduha.
    if (canMove || onRemove != null) return row;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: row,
    );
  }
}
