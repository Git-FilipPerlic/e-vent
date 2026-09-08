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
    this.vehicleId,
    this.participants = const [],
  });

  final String id;

  /// Naziv slavljenika / događaja, npr. 'Rođendan - Mia (7 godina)'.
  final String? title;

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

  final String? vehicleId;
  final List<Participant> participants;

  /// Ista podaci o događaju, samo sa drugim vozilom. Model je nepromenljiv,
  /// pa se pri izboru vozila pravi kopija.
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
      vehicleId: newVehicleId,
      participants: participants,
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
      vehicleId: _emptyToNull(map['vehicleId'] as String?),
      participants: participants,
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
