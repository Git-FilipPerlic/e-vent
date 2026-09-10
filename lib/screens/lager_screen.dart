import 'package:flutter/material.dart';

import '../models/checklist.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
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

/// Lager tab — checklist opreme po kategorijama.
///
/// Prikazuju se **samo kategorije koje je manager izabrao za taj događaj**, sa
/// svim delovima koji im pripadaju. Ono što se ne nosi se ne prikazuje — na
/// nastupu nema vremena za prelistavanje opreme koja nije ni ponesena.
///
/// **Ovde se oprema ne unosi.** Spisak je stvar vlasnika i uređuje se u
/// konzoli, pod „Oprema firme"; na događaju se biraju samo kategorije, a
/// ovde se prolazi i čekira. Poenta je da pred nastup ne kucaš stavke.
///
/// Ista lista služi dvaput: **pre** događaja se čekira šta je spakovano, a
/// **posle** događaja šta se vratilo. Zato svaki režim ima svoje kvačice —
/// pakovanje se ne poništava kad se posle raspakuje.
class LagerScreen extends StatefulWidget {
  const LagerScreen({
    super.key,
    this.eventId = 'evt-001',
    this.auth,
    this.service,
  });

  /// Izvor podataka. `null` znači sopstveni mock; u aplikaciji je isti onaj
  /// koji koriste spisak i Home tab.
  final EventService? service;

  /// Događaj čije se kategorije prikazuju.
  final String eventId;

  /// Ko je prijavljen. Dodavanje i brisanje delova menja **katalog firme**,
  /// pa traži dozvolu; čekiranje na pakovanju ne traži ništa.
  final AuthService? auth;

  @override
  State<LagerScreen> createState() => _LagerScreenState();
}

class _LagerScreenState extends State<LagerScreen> {
  late final EventService _service = widget.service ?? MockEventService();

  /// Ceo katalog kategorija koje firma ima.
  List<ChecklistSection> _catalog = const [];

  /// Kategorije izabrane za ovaj događaj.
  List<String> _selectedCategoryIds = const [];
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

  @override
  void initState() {
    super.initState();
    widget.auth?.addListener(_onAuthChanged);
    _loadTemplate();
  }

  void _onAuthChanged() => setState(() {});

  @override
  void dispose() {
    widget.auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Treba i katalog i događaj: katalog kaže šta firma ima, događaj kaže
      // šta se na njega nosi.
      final results = await Future.wait([
        _service.loadChecklistTemplate(),
        _service.loadEvent(widget.eventId),
      ]);
      if (!mounted) return;
      setState(() {
        _catalog = results[0] as List<ChecklistSection>;
        _selectedCategoryIds = (results[1] as Event).categoryIds;
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

  /// Kategorije koje se prikazuju: samo one izabrane za ovaj događaj.
  List<ChecklistSection> get _sections => [
    for (final section in _catalog)
      if (_selectedCategoryIds.contains(section.id)) section,
  ];

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
          if (_sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Za ovaj događaj nije izabrana nijedna kategorija opreme. '
                'Bira ih manager na Home tabu.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          for (final section in _sections)
            ChecklistSectionTile(
              section: section,
              checkedIds: checked,
              isExpanded: _expanded.contains(section.id),
              onToggleExpanded: () => _toggleSection(section.id),
              onToggleItem: _toggleItem,
            ),
        ],
      ),
    );
  }
}
