import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/edit_text_sheet.dart';
import '../widgets/common/error_retry.dart';

/// Veštine firme — spisak svega što ekipa ume.
///
/// Ovo je **katalog cele firme**, ne jednog čoveka: odavde manager pravi
/// veštine (Vatra, Svila, Voditelj, Vozač…), a onda uz svakog člana čekira
/// šta ume. Isti obrazac kao „Oprema firme": jednom se upiše, pa se posle
/// samo bira.
///
/// Do ovog ekrana se stiže iz „Ekipe", dakle samo uz prijavu.
class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key, required this.service});

  final EventService service;

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  List<Skill> _skills = const [];
  bool _isLoading = true;
  String? _errorMessage;

  /// Da li je katalog menjan — „Ekipa" po povratku mora da ga pročita ponovo.
  bool _changed = false;

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
      final skills = await widget.service.loadSkills();
      if (!mounted) return;
      setState(() {
        _skills = skills;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Spisak veština nije učitan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _add() async {
    final name = await showEditTextSheet(
      context,
      label: 'Nova veština',
      value: null,
      hint: 'na primer Vatra',
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !mounted) return;

    try {
      final created = await widget.service.createSkill(trimmed);
      if (!mounted) return;
      setState(() {
        _skills = [..._skills, created];
        _changed = true;
      });
    } catch (_) {
      _report('Veština nije napravljena.');
    }
  }

  Future<void> _rename(Skill skill) async {
    final name = await showEditTextSheet(
      context,
      label: 'Naziv veštine',
      value: skill.name,
    );
    final trimmed = name?.trim();
    // Prazan naziv ovde **ne briše** — brisanje ide svojim dugmetom, jer
    // skida veštinu i sa svih ljudi.
    if (trimmed == null || trimmed.isEmpty || !mounted) return;

    final updated = skill.copyWith(name: trimmed);
    setState(() {
      _skills = [
        for (final one in _skills)
          if (one.id == skill.id) updated else one,
      ];
      _changed = true;
    });

    try {
      await widget.service.saveSkill(updated);
    } catch (_) {
      _report('Izmena nije sačuvana.');
      await _load();
    }
  }

  Future<void> _delete(Skill skill) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _DeleteSheet(skill: skill),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _skills = [
        for (final one in _skills)
          if (one.id != skill.id) one,
      ];
      _changed = true;
    });

    try {
      await widget.service.deleteSkill(skill.id);
    } catch (_) {
      _report('Veština nije obrisana.');
      await _load();
    }
  }

  void _report(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Veštine firme')),
        body: SafeArea(child: _buildBody()),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova veština'),
        ),
      ),
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

    if (_skills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Nijedna veština još nije upisana.\nDodaj ono što ekipa ume — '
            'Vatra, Svila, Voditelj, Vozač…',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        96,
      ),
      itemCount: _skills.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final skill = _skills[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(kLargeRadius),
            boxShadow: kSoftShadow,
          ),
          child: ListTile(
            title: Text(skill.name),
            onTap: () => _rename(skill),
            trailing: IconButton(
              onPressed: () => _delete(skill),
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.danger,
              tooltip: 'Obriši veštinu',
            ),
          ),
        );
      },
    );
  }
}

/// Potvrda brisanja — izričito kaže da veština nestaje i sa ljudi.
class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.skill});

  final Skill skill;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Obrisati „${skill.name}"?', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Veština se briše iz kataloga i skida se sa svih članova ekipe '
              'koji je imaju.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Obriši'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Odustani'),
            ),
          ],
        ),
      ),
    );
  }
}
