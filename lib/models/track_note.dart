/// Beleška koju je neko ostavio na određenom mestu u pesmi.
///
/// „Omiljeni deo", „ovde ulazi vatra", „skrati" — ono što se inače pamti u
/// glavi ili piše na papiriću. Vidi je **cela ekipa** (odluka od 28.
/// septembra 2026), pa se uz nju čuva ko ju je ostavio i njegova ikonica.
class TrackNote {
  const TrackNote({
    required this.id,
    required this.trackKey,
    required this.positionMs,
    this.trackDurationMs,
    required this.text,
    required this.authorName,
    this.authorAvatarId,
    this.createdAt,
  });

  final String id;

  /// Po čemu se numera prepoznaje **na svim telefonima**.
  ///
  /// Putanja ne valja: isti fajl stoji na različitim mestima kod različitih
  /// ljudi. Zato se uzima **naziv fajla bez nastavka**, u malim slovima —
  /// ono što ostaje isto kad se pesma prekopira sa telefona na telefon.
  ///
  /// Cena je što preimenovan fajl gubi svoje beleške. To je prihvaćeno:
  /// bolje nego da se beleške ne vide nigde osim na jednom telefonu.
  final String trackKey;

  /// Gde u pesmi, u milisekundama od početka.
  final int positionMs;

  /// Koliko je pesma trajala **po onome ko je belešku ostavio**.
  ///
  /// Čuva se zato što se trajanje razlikuje od izvora do izvora: ono iz
  /// oznaka u fajlu i ono što plejer izmeri nisu uvek isti broj, a kod
  /// VBR zapisa razlika ume da bude osetna. Bez ovoga bi ista beleška
  /// sledeći put pala na drugo mesto na talasu. `null` je kod starih
  /// beleški — tada se uzima trajanje koje telefon trenutno zna.
  final int? trackDurationMs;

  final String text;

  /// Ko ju je ostavio — ime pod kojim ga ekipa vidi.
  final String authorName;

  /// Njegova ikonica, da se na talasu prepozna bez čitanja imena.
  final String? authorAvatarId;

  final DateTime? createdAt;

  Duration get position => Duration(milliseconds: positionMs);

  /// Gde je beleška u pesmi, 0..1 — po trajanju koje je uz nju zapamćeno.
  ///
  /// [fallback] je trajanje koje telefon trenutno zna; koristi se samo za
  /// stare beleške, upisane pre nego što se trajanje čuvalo.
  double? fractionIn(Duration? fallback) {
    final reference = trackDurationMs ?? fallback?.inMilliseconds;
    if (reference == null || reference <= 0) return null;
    return (positionMs / reference).clamp(0.0, 1.0);
  }

  /// Gradi ključ numere od putanje do fajla.
  ///
  /// `/sdcard/Music/Nrg/01. Act Won.mp3` daje `01. act won`.
  static String keyForPath(String path) {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    var name = slash >= 0 ? path.substring(slash + 1) : path;
    final dot = name.lastIndexOf('.');
    // Ime koje počinje tačkom je skriven fajl, ne nastavak — kao i u spisku.
    if (dot > 0) name = name.substring(0, dot);
    return name.trim().toLowerCase();
  }

  Map<String, dynamic> toMap() => {
    'trackKey': trackKey,
    'positionMs': positionMs,
    'trackDurationMs': trackDurationMs,
    'text': text,
    'authorName': authorName,
    'authorAvatar': authorAvatarId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory TrackNote.fromMap(Map<String, dynamic> map) {
    final created = map['createdAt'];
    return TrackNote(
      id: (map['id'] as String?) ?? '',
      trackKey: ((map['trackKey'] as String?) ?? '').trim().toLowerCase(),
      positionMs: switch (map['positionMs']) {
        final int value => value < 0 ? 0 : value,
        final num value => value < 0 ? 0 : value.round(),
        _ => 0,
      },
      trackDurationMs: switch (map['trackDurationMs']) {
        final int value => value > 0 ? value : null,
        final num value => value > 0 ? value.round() : null,
        _ => null,
      },
      text: ((map['text'] as String?) ?? '').trim(),
      authorName: ((map['authorName'] as String?) ?? '').trim(),
      authorAvatarId: (map['authorAvatar'] as String?)?.trim(),
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}
