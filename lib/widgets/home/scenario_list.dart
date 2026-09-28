import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Jedna tačka programa, onako kako stoji u spisku.
class ScenarioPoint {
  const ScenarioPoint(this.text, {this.isAdded = false});

  final String text;

  /// `true` za tačku koju je korisnik sam dodao — samo se takva briše.
  final bool isAdded;
}

/// HOME-025 — scenario: tačke programa.
///
/// Tačke iz baze se ne brišu; korisnik može da doda svoje i da ih obriše.
/// **Sve tačke se premeštaju prevlačenjem** za ručicu levo: kad se jedna
/// preskoči, ne briše se ceo spisak nego se samo promeni redosled.
/// Widget je "glup": dobija spisak kroz konstruktor, a dodavanje, brisanje i
/// premeštanje javlja ekranu.
class ScenarioList extends StatefulWidget {
  const ScenarioList({
    super.key,
    required this.points,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  /// Tačke programa, redom kojim se izvode.
  final List<ScenarioPoint> points;

  final ValueChanged<String> onAdd;

  /// Briše dodatu tačku po rednom broju unutar [points].
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
    final points = widget.points;

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
                if (points.isNotEmpty)
                  Text(
                    '${points.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (points.isEmpty)
              Text(
                'Scenario nije unet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              // Spisak ne skroluje sam — skroluje ceo Home ekran oko njega.
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                // Premešta se samo za ručicu: dug pritisak bilo gde po redu
                // bi se otimao sa skrolovanjem i prevlačenjem između stranica.
                buildDefaultDragHandles: false,
                itemCount: points.length,
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
                  key: ValueKey('scenario-$i-${points[i].text}'),
                  index: i,
                  text: points[i].text,
                  onRemove:
                      points[i].isAdded ? () => widget.onRemove(i) : null,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (!_isAdding)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Dodaj tačku'),
                ),
              )
            else
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

/// Jedna tačka programa: ručica za premeštanje, redni broj, tekst i — ako
/// je korisnik sam dodao — dugme za brisanje.
class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    super.key,
    required this.index,
    required this.text,
    this.onRemove,
  });

  /// Mesto u spisku, od nule.
  final int index;
  final String text;

  /// `null` za tačke iz baze — one se ne brišu.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
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
  }
}
