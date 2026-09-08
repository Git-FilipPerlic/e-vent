import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// HOME-025 — scenario: tačke programa.
///
/// Tačke iz baze se samo čitaju; korisnik može da doda svoje i da ih obriše.
/// Widget je "glup": dobija oba spiska kroz konstruktor, a dodavanje i
/// brisanje javlja ekranu.
class ScenarioList extends StatefulWidget {
  const ScenarioList({
    super.key,
    required this.items,
    required this.addedItems,
    required this.onAdd,
    required this.onRemoveAdded,
  });

  /// Tačke programa iz podataka o događaju. Ne mogu da se menjaju.
  final List<String> items;

  /// Tačke koje je korisnik sam dodao.
  final List<String> addedItems;

  final ValueChanged<String> onAdd;

  /// Briše dodatu tačku po rednom broju unutar [addedItems].
  final ValueChanged<int> onRemoveAdded;

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
    final total = widget.items.length + widget.addedItems.length;

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
                if (total > 0)
                  Text(
                    '$total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (total == 0)
              Text(
                'Scenario nije unet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            for (var i = 0; i < widget.items.length; i++)
              _ScenarioRow(number: i + 1, text: widget.items[i]),
            for (var i = 0; i < widget.addedItems.length; i++)
              _ScenarioRow(
                number: widget.items.length + i + 1,
                text: widget.addedItems[i],
                onRemove: () => widget.onRemoveAdded(i),
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
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
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

/// Jedna tačka programa: redni broj, tekst i — ako je korisnik sam dodao —
/// dugme za brisanje.
class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    required this.number,
    required this.text,
    this.onRemove,
  });

  final int number;
  final String text;

  /// `null` za tačke iz baze — one se ne brišu.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
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
      ),
    );
  }
}
