import 'package:flutter/material.dart';

import '../models/checklist.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/edit_text_sheet.dart';
import '../widgets/common/error_retry.dart';
import 'category_items_screen.dart';

/// Oprema firme — spisak svih kategorija koje firma poseduje.
///
/// Ovo je **katalog cele firme**, ne jednog događaja: odavde manager pravi
/// podeoke (Vatra, Svila, Tehnika, Kablovi, LED…), a onda na svakom događaju
/// bira koje od njih se tog dana nose. Lager tab prikazuje samo izabrane, sa
/// svim delovima koji im pripadaju.
///
/// Do ovog ekrana se stiže iz konzole, dakle samo uz prijavu.
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key, required this.service});

  final EventService service;

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<ChecklistSection> _catalog = const [];
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
      final catalog = await widget.service.loadChecklistTemplate();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Spisak opreme nije učitan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _add() async {
    final name = await showEditTextSheet(
      context,
      label: 'Nova kategorija opreme',
      value: null,
      hint: 'na primer Vatra',
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !mounted) return;

    try {
      final created = await widget.service.createCategory(trimmed);
      if (!mounted) return;
      setState(() => _catalog = [..._catalog, created]);
    } catch (_) {
      _report('Kategorija nije napravljena.');
    }
  }

  Future<void> _rename(ChecklistSection category) async {
    final name = await showEditTextSheet(
      context,
      label: 'Naziv kategorije',
      value: category.name,
    );
    final trimmed = name?.trim();
    // Prazan naziv ovde **ne briše** — brisanje ide svojim dugmetom, jer
    // odnosi i sve delove koji pripadaju kategoriji.
    if (trimmed == null || trimmed.isEmpty || !mounted) return;

    final updated = ChecklistSection(
      id: category.id,
      name: trimmed,
      items: category.items,
    );

    setState(() {
      _catalog = [
        for (final one in _catalog)
          if (one.id == category.id) updated else one,
      ];
    });

    try {
      await widget.service.saveCategory(updated);
    } catch (_) {
      _report('Izmena nije sačuvana.');
      await _load();
    }
  }

  Future<void> _delete(ChecklistSection category) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _DeleteSheet(category: category),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _catalog = [
        for (final one in _catalog)
          if (one.id != category.id) one,
      ];
    });

    try {
      await widget.service.deleteCategory(category.id);
    } catch (_) {
      _report('Kategorija nije obrisana.');
      await _load();
    }
  }

  /// Otvara delove jedne kategorije — ono što joj pripada.
  Future<void> _editItems(ChecklistSection category) async {
    final changed = await Navigator.of(context).push<ChecklistSection>(
      MaterialPageRoute(
        builder: (_) => CategoryItemsScreen(category: category),
      ),
    );
    if (changed == null || !mounted) return;

    setState(() {
      _catalog = [
        for (final one in _catalog)
          if (one.id == changed.id) changed else one,
      ];
    });

    try {
      await widget.service.saveCategory(changed);
    } catch (_) {
      _report('Izmena kategorije nije sačuvana.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Oprema firme')),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova kategorija'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return ErrorRetry(message: errorMessage, onRetry: _load);
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      children: [
        Text(
          'Ovo je spisak cele firme. Na svakom događaju biraš koje od ovih '
          'kategorija se tog dana nose, a Lager tab onda prikazuje njih i sve '
          'delove koji im pripadaju.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_catalog.isEmpty)
          Text(
            'Nijedna kategorija još nije napravljena.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        for (final category in _catalog)
          Card(
            child: ListTile(
              title: Text(
                category.name,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                category.items.isEmpty
                    ? 'Nema delova'
                    : '${category.items.length} delova',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              // Dodir otvara delove; olovka menja naziv, kanta briše.
              onTap: () => _editItems(category),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _rename(category),
                    icon: const Icon(Icons.edit_rounded),
                    iconSize: 18,
                    color: AppColors.accent,
                    tooltip: 'Izmeni naziv',
                  ),
                  IconButton(
                    onPressed: () => _delete(category),
                    icon: const Icon(Icons.delete_outline_rounded),
                    iconSize: 18,
                    color: AppColors.textSecondary,
                    tooltip: 'Obriši kategoriju',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Potvrda brisanja kategorije.
class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.category});

  final ChecklistSection category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Obrisati „${category.name}"?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.items.isEmpty
                  ? 'Kategorija nestaje sa svih događaja koji su je nosili.'
                  : 'Sa njom odlazi i ${category.items.length} delova, i '
                        'nestaje sa svih događaja koji su je nosili.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Odustani'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Obriši'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
