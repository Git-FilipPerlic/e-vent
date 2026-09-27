import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import 'skills_screen.dart';

/// Ekipa — ko šta ume i koliko je odradio.
///
/// Do ekrana se stiže iz konzole, pored „Opreme firme", i sve što se ovde
/// menja menja **manager**: veštine se čekiraju iz kataloga firme, a bodovi
/// se dodeljuju rukom, posle odrađenog posla (odluka od 27. septembra 2026).
/// Spisak koji svako sebi popunjava ne znači ništa, a bodovi bi bili šala.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.service});

  final EventService service;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<TeamMember> _team = const [];
  List<Skill> _skills = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final team = await widget.service.loadTeam();
      final skills = await widget.service.loadSkills();
      if (!mounted) return;
      setState(() {
        _team = team;
        _skills = skills;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ekipa nije učitana.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSkills() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SkillsScreen(service: widget.service)),
    );
    // Veština je možda obrisana ili preimenovana, pa se ekipa čita ponovo.
    if (changed == true && mounted) await _load();
  }

  /// Otvara jednog člana: šta ume i koliko ima bodova.
  Future<void> _edit(TeamMember member) async {
    final changed = await showModalBottomSheet<TeamMember>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _MemberSheet(member: member, skills: _skills),
    );
    if (changed == null || !mounted) return;

    setState(() {
      _team = [
        for (final one in _team)
          if (one.id == changed.id) changed else one,
      ];
    });

    try {
      await widget.service.saveMemberSkills(changed);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Izmena nije sačuvana.')));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekipa'),
        actions: [
          IconButton(
            onPressed: _openSkills,
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Veštine firme',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return ErrorRetry(message: errorMessage, onRetry: _load);
    }

    if (_team.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'U ekipi još nema nikoga.\nČlan se pojavi ovde čim se prvi put '
            'prijavi u aplikaciju.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _team.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final member = _team[index];
        return _MemberCard(
          member: member,
          skills: _skills,
          onTap: () => _edit(member),
        );
      },
    );
  }
}

/// Jedan član u spisku: ime, šta ume i dokle je stigao.
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.skills,
    required this.onTap,
  });

  final TeamMember member;
  final List<Skill> skills;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = [
      for (final skill in skills)
        if (member.knows(skill.id)) skill.name,
    ];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(kLargeRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kLargeRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      member.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (member.role == 'glavni')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.peach,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'vodi ekipu',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.cinnamon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ExpBar(member: member),
              const SizedBox(height: AppSpacing.sm),
              Text(
                known.isEmpty ? 'Veštine nisu upisane' : known.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Traka napretka: koliko je bodova skupljeno u tekućem nivou.
///
/// Broj bodova stoji uz traku, jer traka sama kaže „negde oko pola", a
/// manager mora da zna tačnu brojku kad dodaje nove.
class ExpBar extends StatelessWidget {
  const ExpBar({super.key, required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Nivo ${member.level}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${member.exp} EXP · još ${member.expToNextLevel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: member.levelProgress,
            minHeight: 6,
            color: AppColors.accent,
            backgroundColor: AppColors.accentDeep,
          ),
        ),
      ],
    );
  }
}

/// Izmena jednog člana: kvačice za veštine i bodovi.
class _MemberSheet extends StatefulWidget {
  const _MemberSheet({required this.member, required this.skills});

  final TeamMember member;
  final List<Skill> skills;

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  late List<String> _skillIds = [...widget.member.skillIds];
  late int _exp = widget.member.exp;

  /// Koliko se bodova dodaje jednim dodirom.
  static const List<int> _steps = [10, 25, 50];

  TeamMember get _edited =>
      widget.member.copyWith(skillIds: _skillIds, exp: _exp);

  void _toggle(String skillId) {
    setState(() {
      if (_skillIds.contains(skillId)) {
        _skillIds = [
          for (final id in _skillIds)
            if (id != skillId) id,
        ];
      } else {
        _skillIds = [..._skillIds, skillId];
      }
    });
  }

  void _add(int amount) {
    setState(() {
      final next = _exp + amount;
      _exp = next < 0 ? 0 : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.member.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              ExpBar(member: _edited),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final step in _steps) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _add(step),
                        child: Text('+$step'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  // Oduzimanje je ispravka greške, pa stoji po strani i sitnije.
                  IconButton(
                    onPressed: _exp == 0 ? null : () => _add(-10),
                    icon: const Icon(Icons.remove_rounded),
                    tooltip: 'Oduzmi 10',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Veštine',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.skills.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Katalog veština je prazan — napravi ga prvo, dugmetom '
                    'gore desno.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final skill in widget.skills)
                      FilterChip(
                        label: Text(skill.name),
                        selected: _skillIds.contains(skill.id),
                        onSelected: (_) => _toggle(skill.id),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_edited),
                child: const Text('Sačuvaj'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
