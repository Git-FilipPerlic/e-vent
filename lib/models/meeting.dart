/// Sastanak firme — termin i adresa, bez ostalih podataka o događaju.
///
/// Za razliku od [Event], sastanak nema ni naziv, ni učesnike, ni opremu:
/// pravi ga samo onaj ko vodi ekipu, iz konzole (dogovoreno 1. oktobra
/// 2026), a vidi ga **cela ekipa**, ne samo oni kojima je nešto dodeljeno —
/// zato se spisak događaja ne filtrira po njemu kao po `assignedTo`.
class CompanyMeeting {
  const CompanyMeeting({
    required this.id,
    required this.dateTime,
    required this.address,
  });

  final String id;

  /// Kad je sastanak — datum i sat. Nosi ga spisak događaja, u istu grupu
  /// (Danas / Sutra / Ova nedelja…) kao i događaji tog dana.
  final DateTime dateTime;

  /// Gde se sastanak drži. Samo tekst — ekipa već zna gde firma drži
  /// sastanke, pa nema potrebe za mapom ni navigacijom.
  final String address;

  Map<String, dynamic> toMap() => {
    'dateTime': dateTime.toIso8601String(),
    'address': address,
  };

  factory CompanyMeeting.fromMap(Map<String, dynamic> map) {
    final raw = map['dateTime'];
    final parsed = raw is String ? DateTime.tryParse(raw) : null;

    return CompanyMeeting(
      id: (map['id'] as String?) ?? '',
      // Pokvaren ili nepostojeći zapis ne sme da obori spisak — ovakav
      // sastanak jednostavno padne na dno (bez datuma), umesto da sruši
      // čitanje ostalih.
      dateTime: parsed ?? DateTime.fromMillisecondsSinceEpoch(0),
      address: ((map['address'] as String?) ?? '').trim(),
    );
  }
}
