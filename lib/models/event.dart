/// Uloge u ekipi. Pišu se na jednom mestu da se ne bi kucale "peške"
/// po ekranima i da se ne bi omakla greška u kucanju.
abstract final class ParticipantRole {
  static const String glavni = 'glavni';
  static const String vozac = 'vozač';
  static const String pomocni = 'pomoćni';

  /// Uloge koje se dodeljuju po redosledu kada učesnik nema navedenu ulogu:
  /// prvi je glavni, drugi vozač, svi ostali pomoćni.
  static String byIndex(int index) {
    if (index == 0) return glavni;
    if (index == 1) return vozac;
    return pomocni;
  }
}

/// Vrsta događaja.
///
/// Postoji zato što **naziv ostaje kratak** (`7 Mia`, `Jelena i Nemanja`) —
/// u naziv se ne piše ni „rođendan" ni „svadba". Vrsta je zaseban podatak, pa
/// se u spisku na prvi pogled vidi ide li se na rođendan, krštenje, svadbu,
/// običan nastup ili festival.
enum EventType {
  rodjendan('rodjendan', 'Rođendan'),
  krstenje('krstenje', 'Krštenje'),
  svadba('svadba', 'Svadba'),
  nastup('nastup', 'Nastup'),
  festival('festival', 'Festival');

  const EventType(this.id, this.label);

  /// Kako se piše u bazi. Bez naših slova, da se ne muči ni jedan uvoz.
  final String id;

  /// Kako se prikazuje u aplikaciji.
  final String label;

  /// Vrsta iz baze. Nepoznata ili prazna vrednost daje `null` — događaj bez
  /// vrste je i dalje ispravan događaj.
  static EventType? fromId(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    final needle = id.trim().toLowerCase();
    for (final type in EventType.values) {
      if (type.id == needle) return type;
    }
    return null;
  }
}

/// Jedan član ekipe na događaju.
class Participant {
  const Participant({required this.name, required this.role});

  final String name;
  final String role;

  bool get isGlavni => role == ParticipantRole.glavni;
  bool get isVozac => role == ParticipantRole.vozac;
}

/// Jedan događaj. **Svako polje sem [id] može da nedostaje** — ekrani moraju
/// da prikažu razuman tekst umesto podatka ("Datum nije unet"), nikad da puknu.
class Event {
  const Event({
    required this.id,
    this.title,
    this.scenario = const [],
    this.organizerName,
    this.organizerPhone,
    this.address,
    this.latitude,
    this.longitude,
    this.eventDate,
    this.departureTime,
    this.travelDurationMinutes,
    this.durationMinutes,
    this.vehicleId,
    this.categoryIds = const [],
    this.participants = const [],
    this.createdBy,
    this.assignedTo = const [],
    this.type,
  });

  final String id;

  /// Naziv slavljenika / događaja, npr. '7 Mia'.
  ///
  /// Kratak, bez vrste — vrstu nosi [type].
  final String? title;

  /// Rođendan, krštenje, svadba, nastup ili festival. `null` kad nije uneta.
  final EventType? type;

  /// Tačke programa, npr. ['Doček gostiju', 'Igre za decu'].
  final List<String> scenario;

  final String? organizerName;
  final String? organizerPhone;
  final String? address;

  /// Koordinate za mini mapu i navigaciju. Idu u paru — ako fali jedna,
  /// mapa se ne prikazuje.
  final double? latitude;
  final double? longitude;

  final DateTime? eventDate;
  final DateTime? departureTime;

  /// Procenjeno trajanje puta u minutima.
  final int? travelDurationMinutes;

  /// Koliko je **ugovoreno** da nastup traje, u minutima.
  /// Iz ovoga se računa kad se završava.
  final int? durationMinutes;

  /// Kad se događaj završava, ako se zna i početak i ugovoreno trajanje.
  DateTime? get endsAt {
    final start = eventDate;
    final minutes = durationMinutes;
    if (start == null || minutes == null) return null;
    return start.add(Duration(minutes: minutes));
  }

  final String? vehicleId;

  /// Kategorije opreme izabrane za ovaj događaj (Vatra, LED, Ring...).
  ///
  /// Pamte se **samo id-jevi kategorija, ne kopije stavki** — inače se izmena
  /// u katalogu ne bi videla na već napravljenim događajima.
  final List<String> categoryIds;

  final List<Participant> participants;

  /// Ko je događaj napravio i podelio timu.
  ///
  /// Po ovome manager vidi spisak onoga što je **delegirao**.
  final String? createdBy;

  /// Kome je događaj dodeljen — spisak članova ekipe koji ga vide kao svoj.
  ///
  /// Za sada su to **imena** (`'Filip'`), jer lokalna prijava drugo i nema;
  /// sa Firebase Auth-om ovde ulaze `uid`-jevi, a ekrani se ne diraju.
  final List<String> assignedTo;

  /// Da li je događaj dodeljen datom korisniku. Veličina slova se ne gleda —
  /// ime se kuca ručno i lako se omakne.
  bool isAssignedTo(String user) {
    final needle = user.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return assignedTo.any((name) => name.trim().toLowerCase() == needle);
  }

  /// Da li je događaj napravio dati korisnik.
  bool isCreatedBy(String user) {
    final owner = createdBy?.trim().toLowerCase();
    if (owner == null || owner.isEmpty) return false;
    return owner == user.trim().toLowerCase();
  }

  /// Isti događaj, sa izmenjenim poljima. Model je nepromenljiv, pa svaka
  /// izmena pravi kopiju.
  ///
  /// **Prazan tekst briše podatak.** Zato se za brisanje šalje prazan string,
  /// a ne `null` — `null` znači „ovo polje ne diraj".
  Event copyWith({
    String? title,
    List<String>? scenario,
    String? organizerName,
    String? organizerPhone,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? eventDate,
    DateTime? departureTime,
    int? travelDurationMinutes,
    int? durationMinutes,
    String? vehicleId,
    List<String>? categoryIds,
    List<Participant>? participants,
    String? createdBy,
    List<String>? assignedTo,
    EventType? type,
  }) {
    return Event(
      id: id,
      title: _edited(title, this.title),
      scenario: scenario ?? this.scenario,
      organizerName: _edited(organizerName, this.organizerName),
      organizerPhone: _edited(organizerPhone, this.organizerPhone),
      address: _edited(address, this.address),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      eventDate: eventDate ?? this.eventDate,
      departureTime: departureTime ?? this.departureTime,
      travelDurationMinutes:
          travelDurationMinutes ?? this.travelDurationMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      vehicleId: vehicleId ?? this.vehicleId,
      categoryIds: categoryIds ?? this.categoryIds,
      participants: participants ?? this.participants,
      createdBy: _edited(createdBy, this.createdBy),
      assignedTo: assignedTo ?? this.assignedTo,
      type: type ?? this.type,
    );
  }

  /// Nova vrednost teksta: `null` ne dira polje, prazan tekst ga briše.
  static String? _edited(String? incoming, String? existing) {
    if (incoming == null) return existing;
    final trimmed = incoming.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Isti događaj, samo sa drugim vozilom.
  Event withVehicle(String? newVehicleId) {
    return Event(
      id: id,
      title: title,
      scenario: scenario,
      organizerName: organizerName,
      organizerPhone: organizerPhone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      eventDate: eventDate,
      departureTime: departureTime,
      travelDurationMinutes: travelDurationMinutes,
      durationMinutes: durationMinutes,
      vehicleId: newVehicleId,
      categoryIds: categoryIds,
      participants: participants,
      createdBy: createdBy,
      assignedTo: assignedTo,
      type: type,
    );
  }

  /// Ima li dovoljno podataka da se nacrta mapa i pokrene navigacija.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Vođa ekipe, ako je neko postavljen na tu ulogu.
  Participant? get glavni {
    for (final p in participants) {
      if (p.isGlavni) return p;
    }
    return null;
  }

  /// Vozač, ako je neko postavljen na tu ulogu.
  Participant? get vozac {
    for (final p in participants) {
      if (p.isVozac) return p;
    }
    return null;
  }

  /// Pravi [Event] iz mape kakvu vraća baza (kasnije Firestore).
  ///
  /// Učesnik bez navedene uloge dobija ulogu po redosledu
  /// (1. glavni, 2. vozač, ostali pomoćni); izričito navedena uloga
  /// ima prednost nad tim pravilom.
  factory Event.fromMap(Map<String, dynamic> map) {
    final rawParticipants = (map['participants'] as List?) ?? const [];
    final participants = <Participant>[];

    for (var i = 0; i < rawParticipants.length; i++) {
      final raw = rawParticipants[i] as Map<String, dynamic>;
      final role = (raw['role'] as String?)?.trim();
      participants.add(
        Participant(
          name: (raw['name'] as String?) ?? '',
          role: (role == null || role.isEmpty)
              ? ParticipantRole.byIndex(i)
              : role,
        ),
      );
    }

    return Event(
      id: map['id'] as String,
      title: _emptyToNull(map['title'] as String?),
      scenario: ((map['scenario'] as List?) ?? const []).cast<String>(),
      organizerName: _emptyToNull(map['organizerName'] as String?),
      organizerPhone: _emptyToNull(map['organizerPhone'] as String?),
      address: _emptyToNull(map['address'] as String?),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      eventDate: _parseDate(map['eventDate'] as String?),
      departureTime: _parseDate(map['departureTime'] as String?),
      travelDurationMinutes: (map['travelDurationMinutes'] as num?)?.toInt(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
      vehicleId: _emptyToNull(map['vehicleId'] as String?),
      categoryIds: ((map['categoryIds'] as List?) ?? const []).cast<String>(),
      participants: participants,
      createdBy: _emptyToNull(map['createdBy'] as String?),
      assignedTo: ((map['assignedTo'] as List?) ?? const []).cast<String>(),
      type: EventType.fromId(map['type'] as String?),
    );
  }

  /// Prazan tekst iz baze tretiramo isto kao da podatak ne postoji.
  static String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  /// Neispravan datum ne sme da sruši aplikaciju — vraća se `null`.
  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
