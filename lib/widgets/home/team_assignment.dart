import 'package:flutter/material.dart';

import '../../models/team.dart';
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
  required List<TeamMember> team,
  required List<Skill> skills,
  required List<String> assignedTo,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) =>
        _AssignPicker(team: team, skills: skills, assignedTo: assignedTo),
  );
}

class _AssignPicker extends StatefulWidget {
  const _AssignPicker({
    required this.team,
    required this.skills,
    required this.assignedTo,
  });

  final List<TeamMember> team;
  final List<Skill> skills;
  final List<String> assignedTo;

  @override
  State<_AssignPicker> createState() => _AssignPickerState();
}

class _AssignPickerState extends State<_AssignPicker> {
  late final Set<String> _selected = {...widget.assignedTo};

  /// Po kojoj se veštini gleda ekipa; `null` znači svi.
  ///
  /// **Filter, ne zahtev** (odluka od 27. septembra 2026): na događaju se ne
  /// čekira šta treba, nego se ovde suzi spisak na one koji to umeju. Jedna
  /// veština u jednom trenutku — „ko zna i vatru i vožnju" je pitanje koje se
  /// pred nastup ne postavlja.
  String? _skillId;

  /// Ekipa posle filtera.
  List<TeamMember> get _shown {
    final skillId = _skillId;
    if (skillId == null) return widget.team;
    return [
      for (final member in widget.team)
        if (member.knows(skillId)) member,
    ];
  }

  /// Koliko je izabranih sakrio filter — da se ne pomisli da su odčekirani.
  int get _hiddenSelected {
    final shown = {for (final member in _shown) member.name};
    return _selected.where((name) => !shown.contains(name)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = _shown;

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
          if (widget.skills.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _SkillFilterChip(
                    label: 'Svi',
                    selected: _skillId == null,
                    onTap: () => setState(() => _skillId = null),
                  ),
                  for (final skill in widget.skills)
                    _SkillFilterChip(
                      label: skill.name,
                      selected: _skillId == skill.id,
                      // Ponovni dodir na istu veštinu vraća ceo spisak.
                      onTap: () => setState(
                        () => _skillId = _skillId == skill.id ? null : skill.id,
                      ),
                    ),
                ],
              ),
            ),
          if (_hiddenSelected > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: Text(
                'Još $_hiddenSelected izabranih je van filtera — ostaju dodeljeni.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                ),
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
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Tu veštinu za sada niko nema upisanu.',
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
                itemCount: shown.length,
                itemBuilder: (context, index) {
                  final member = shown[index];
                  final known = [
                    for (final skill in widget.skills)
                      if (member.knows(skill.id)) skill.name,
                  ];
                  return CheckboxListTile(
                    value: _selected.contains(member.name),
                    onChanged: (value) => setState(() {
                      if (value ?? false) {
                        _selected.add(member.name);
                      } else {
                        _selected.remove(member.name);
                      }
                    }),
                    title: Text(
                      member.name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: known.isEmpty
                        ? null
                        : Text(
                            known.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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

/// Dugme filtera po veštini, u vodoravnom spisku iznad ekipe.
class _SkillFilterChip extends StatelessWidget {
  const _SkillFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
