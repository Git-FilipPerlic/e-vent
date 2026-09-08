/// Najveći dozvoljen broj stavki u checklisti jednog događaja.
/// Preko ovoga se stavka ne dodaje — lista prestaje da bude upotrebljiva
/// kad se pakuje u žurbi.
const int kMaxChecklistItems = 90;

/// Jedna stavka opreme.
class ChecklistItem {
  const ChecklistItem({required this.id, required this.name});

  final String id;
  final String name;

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
    );
  }
}

/// Sekcija checkliste (Tehnika, Animacija, Specijalni efekti...).
class ChecklistSection {
  const ChecklistSection({
    required this.id,
    required this.name,
    this.items = const [],
  });

  final String id;
  final String name;
  final List<ChecklistItem> items;

  factory ChecklistSection.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? const [];
    return ChecklistSection(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      items: rawItems
          .map((raw) => ChecklistItem.fromMap(raw as Map<String, dynamic>))
          .toList(),
    );
  }
}
