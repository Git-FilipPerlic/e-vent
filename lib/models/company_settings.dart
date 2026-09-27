/// Podešavanja firme — ono što važi za sve događaje, ne za jedan.
///
/// Za sada je tu samo **magacin**: adresa odakle ekipa kreće. Odluka od
/// 27. septembra 2026 — put do događaja se računa uvek od magacina, ne od
/// trenutne lokacije telefona. Tako nije potrebna dozvola za lokaciju, a
/// broj je tačniji: ekipa kreće po opremu, ne od kuće.
class CompanySettings {
  const CompanySettings({this.baseAddress, this.baseLatitude, this.baseLongitude});

  /// Adresa magacina, onako kako je upisana. `null` dok nije uneta.
  final String? baseAddress;

  /// Koordinate magacina, zapamćene pošto se adresa jednom pronađe na mapi.
  /// Bez njih se adresa traži iznova pri svakom računanju puta.
  final double? baseLatitude;
  final double? baseLongitude;

  bool get hasAddress => (baseAddress ?? '').trim().isNotEmpty;

  bool get hasCoordinates => baseLatitude != null && baseLongitude != null;

  CompanySettings copyWith({
    String? baseAddress,
    double? baseLatitude,
    double? baseLongitude,
    bool clearCoordinates = false,
  }) {
    return CompanySettings(
      baseAddress: baseAddress ?? this.baseAddress,
      baseLatitude: clearCoordinates ? null : baseLatitude ?? this.baseLatitude,
      baseLongitude: clearCoordinates
          ? null
          : baseLongitude ?? this.baseLongitude,
    );
  }

  Map<String, dynamic> toMap() => {
    'baseAddress': baseAddress,
    'baseLatitude': baseLatitude,
    'baseLongitude': baseLongitude,
  };

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    final address = (map['baseAddress'] as String?)?.trim();
    return CompanySettings(
      baseAddress: address == null || address.isEmpty ? null : address,
      baseLatitude: (map['baseLatitude'] as num?)?.toDouble(),
      baseLongitude: (map['baseLongitude'] as num?)?.toDouble(),
    );
  }
}
