import 'package:flutter/material.dart';

import '../models/checklist.dart';
import '../services/event_service.dart';
import '../services/mock_event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/lager/checklist_progress.dart';
import '../widgets/lager/checklist_section_tile.dart';

/// Šta se trenutno radi sa opremom.
enum LagerMode {
  /// Pre događaja: oprema se pakuje u vozilo.
  pakovanje('Pakovanje', 'Spakovano'),

  /// Posle događaja: proverava se da li se sve vratilo kući.
  raspakivanje('Raspakivanje', 'Raspakovano');

  const LagerMode(this.label, this.progressLabel);

  final String label;

  /// Kako se zove traka napretka u tom režimu.
  final String progressLabel;
}

/// Lager tab — checklist opreme po sekcijama.
///
/// Ista lista služi dvaput: **pre** događaja se čekira šta je spakovano, a
/// **posle** događaja šta se vratilo. Zato svaki režim ima svoje kvačice —
/// pakovanje se ne poništava kad se posle raspakuje.
class LagerScreen extends StatefulWidget {
  const LagerScreen({super.key});

  @override
  State<LagerScreen> createState() => _LagerScreenState();
}

class _LagerScreenState extends State<LagerScreen> {
  /// Jedino mesto gde se bira izvor podataka.
  final EventService _service = MockEventService();

  List<ChecklistSection> _sections = const [];
  bool _isLoading = true;
  String? _errorMessage;

  LagerMode _mode = LagerMode.pakovanje;

  /// Čekirane stavke, odvojeno po režimu.
  final Map<LagerMode, Set<String>> _checked = {
    LagerMode.pakovanje: <String>{},
    LagerMode.raspakivanje: <String>{},
  };

  /// Otvorene sekcije. Na početku su sve zatvorene — spisak od šest sekcija
  /// mora da stane na jedan ekran.
  final Set<String> _expanded = <String>{};

  /// Stavke koje je korisnik sam dodao; samo one mogu da se obrišu.
  final Set<String> _addedItemIds = <String>{};

  int _nextAddedNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sections = await _service.loadChecklistTemplate();
      if (!mounted) return;
      setState(() {
        _sections = sections;
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

  int get _totalItems =>
      _sections.fold(0, (sum, section) => sum + section.items.length);

  int get _checkedItems {
    final checked = _checked[_mode]!;
    return _sections.fold(
      0,
      (sum, section) =>
          sum + section.items.where((i) => checked.contains(i.id)).length,
    );
  }

  void _toggleItem(String itemId) {
    setState(() {
      final checked = _checked[_mode]!;
      if (!checked.remove(itemId)) checked.add(itemId);
    });
  }

  void _toggleSection(String sectionId) {
    setState(() {
      if (!_expanded.remove(sectionId)) _expanded.add(sectionId);
    });
  }

  /// Dodaje stavku u sekciju. Preko [kMaxChecklistItems] se ne ide —
  /// lista prestaje da bude upotrebljiva kad se pakuje u žurbi.
  void _addItem(String sectionId, String name) {
    if (_totalItems >= kMaxChecklistItems) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Dostignut je limit od $kMaxChecklistItems stavki.',
            ),
          ),
        );
      return;
    }

    final id = 'dodato-${_nextAddedNumber++}';
    setState(() {
      _addedItemIds.add(id);
      _sections = [
        for (final section in _sections)
          if (section.id == sectionId)
            ChecklistSection(
              id: section.id,
              name: section.name,
              items: [...section.items, ChecklistItem(id: id, name: name)],
            )
          else
            section,
      ];
    });
  }

  void _removeItem(String sectionId, String itemId) {
    setState(() {
      _addedItemIds.remove(itemId);
      for (final checked in _checked.values) {
        checked.remove(itemId);
      }
      _sections = [
        for (final section in _sections)
          if (section.id == sectionId)
            ChecklistSection(
              id: section.id,
              name: section.name,
              items: section.items.where((i) => i.id != itemId).toList(),
            )
          else
            section,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return ErrorRetry(message: errorMessage, onRetry: _loadTemplate);
    }

    final checked = _checked[_mode]!;

    return RefreshIndicator(
      onRefresh: _loadTemplate,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<LagerMode>(
              segments: [
                for (final mode in LagerMode.values)
                  ButtonSegment(value: mode, label: Text(mode.label)),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
          ),
          ChecklistProgress(
            checked: _checkedItems,
            total: _totalItems,
            label: _mode.progressLabel,
          ),
          for (final section in _sections)
            ChecklistSectionTile(
              section: section,
              checkedIds: checked,
              addedItemIds: _addedItemIds,
              isExpanded: _expanded.contains(section.id),
              onToggleExpanded: () => _toggleSection(section.id),
              onToggleItem: _toggleItem,
              onAddItem: (name) => _addItem(section.id, name),
              onRemoveItem: (itemId) => _removeItem(section.id, itemId),
            ),
        ],
      ),
    );
  }
}
