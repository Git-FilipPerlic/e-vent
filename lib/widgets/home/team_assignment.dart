import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Kome je događaj dodeljen — „share" iz „create and share".
///
/// Razlikuje se od kartice **Učesnici**: tamo piše ko šta radi na samom
/// nastupu (glavni, vozač, pomoćni), a ovde ko uopšte **vidi taj događaj** u
/// svojoj aplikaciji. Zato dve kartice, a ne jedna.
///
/// Widget je „glup": dobija spisak kroz konstruktor, izmenu javlja ekranu.
class TeamAssignment extends StatelessWidget {
  const TeamAssignment({super.key, required this.assignedTo, this.onEdit});

  /// Kome je dodeljeno. Prazan spisak je ispravno stanje.
  final List<String> assignedTo;

  /// Otvara izbor. `null` kad korisnik nema dozvolu.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ko radi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    iconSize: 20,
                    color: AppColors.accent,
                    tooltip: 'Dodeli događaj',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (assignedTo.isEmpty)
              Text(
                // Događaj koji niko ne radi je samo beleška — zato se to i
                // kaže, a ne ostavi prazno.
                'Nikome nije dodeljen',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final name in assignedTo) _PersonChip(name: name),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
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
        name,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

/// Izbor kome se događaj dodeljuje, u listu koji se izvuče odozdo.
///
/// Vraća nov spisak imena, ili `null` ako je korisnik odustao.
Future<List<String>?> showAssignPicker(
  BuildContext context, {
  required List<String> team,
  required List<String> assignedTo,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _AssignPicker(team: team, assignedTo: assignedTo),
  );
}

class _AssignPicker extends StatefulWidget {
  const _AssignPicker({required this.team, required this.assignedTo});

  final List<String> team;
  final List<String> assignedTo;

  @override
  State<_AssignPicker> createState() => _AssignPickerState();
}

class _AssignPickerState extends State<_AssignPicker> {
  late final Set<String> _selected = {...widget.assignedTo};

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
                  'Ko radi ovaj događaj',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Izabranima se događaj pojavljuje u njihovom spisku.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.team.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Spisak ekipe nije učitan.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.team.length,
                itemBuilder: (context, index) {
                  final member = widget.team[index];
                  return CheckboxListTile(
                    value: _selected.contains(member),
                    onChanged: (value) => setState(() {
                      if (value ?? false) {
                        _selected.add(member);
                      } else {
                        _selected.remove(member);
                      }
                    }),
                    title: Text(
                      member,
                      style: const TextStyle(color: AppColors.textPrimary),
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
