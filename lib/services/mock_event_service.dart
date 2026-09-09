import '../models/checklist.dart';
import '../models/event.dart';
import '../models/vehicle.dart';
import 'event_service.dart';

/// Lokalni podaci za razvoj — isti test događaji kao u React Native verziji.
///
/// Namerno postoje četiri različita slučaja da bi se ekrani proverili i na
/// nepotpunim podacima:
///
/// * `evt-001` — sve popunjeno
/// * `evt-002` — samo jedan učesnik
/// * `evt-003` — bez telefona i bez vozila
/// * `evt-004` — sva polja prazna (provera praznih stanja)
class MockEventService implements EventService {
  /// Koliko se "čeka" na podatke. Kratka pauza da se vidi kako izgleda
  /// učitavanje, kao da podaci stižu sa mreže.
  static const Duration _delay = Duration(milliseconds: 400);

  /// Vozila se drže u memoriji da bi dodavanje novog vozila radilo
  /// dok se ne priključi prava baza.
  final List<Vehicle> _vehicles = [
    const Vehicle(id: 'vehicle-001', name: 'Beli kombi'),
    const Vehicle(id: 'vehicle-002', name: 'Sivi Caddy'),
  ];

  int _nextVehicleNumber = 3;

  /// Izabrano vozilo po događaju. Test događaji su nepromenljivi (`const`),
  /// pa se izbor pamti sa strane — dok ne dođe prava baza.
  final Map<String, String> _selectedVehicles = {};

  /// Izmene unete kroz admin konzolu. Test događaji su `const`, pa se izmene
  /// pamte sa strane — dok ne dođe prava baza.
  final Map<String, Event> _edited = {};

  /// Izmenjene kategorije opreme, po id-ju. Katalog je `const`, pa izmene
  /// stoje sa strane — dok ne dođe prava baza.
  final Map<String, ChecklistSection> _editedCategories = {};

  @override
  Future<Event> loadEvent(String eventId) async {
    await Future<void>.delayed(_delay);

    if (!_events.containsKey(eventId)) throw EventNotFoundException(eventId);

    return _resolve(eventId);
  }

  @override
  Future<List<Event>> loadEvents({
    String? assignedTo,
    String? createdBy,
  }) async {
    await Future<void>.delayed(_delay);

    final events = [for (final id in _events.keys) _resolve(id)];

    final matching = [
      for (final event in events)
        if (_matches(event, assignedTo: assignedTo, createdBy: createdBy))
          event,
    ];

    // Najbliži prvi; događaj bez datuma ide na kraj — ne zna se kada je,
    // pa ne sme da zauzme vrh spiska.
    matching.sort((a, b) {
      final left = a.eventDate;
      final right = b.eventDate;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });

    return matching;
  }

  bool _matches(Event event, {String? assignedTo, String? createdBy}) {
    if (assignedTo != null && event.isAssignedTo(assignedTo)) return true;
    if (createdBy != null && event.isCreatedBy(createdBy)) return true;
    // Bez filtera se vraća sve.
    return assignedTo == null && createdBy == null;
  }

  /// Događaj sa uračunatim izmenama i izabranim vozilom.
  Event _resolve(String eventId) {
    final map = _events[eventId]!;

    final edited = _edited[eventId];
    if (edited != null) return edited;

    final chosenVehicle = _selectedVehicles[eventId];
    if (chosenVehicle != null) {
      return Event.fromMap({...map, 'vehicleId': chosenVehicle});
    }

    return Event.fromMap(map);
  }

  @override
  Future<List<Vehicle>> loadVehicles() async {
    await Future<void>.delayed(_delay);
    return List.unmodifiable(_vehicles);
  }

  @override
  Future<Vehicle> addVehicle(String name) async {
    await Future<void>.delayed(_delay);

    final vehicle = Vehicle(
      id: 'vehicle-${_nextVehicleNumber.toString().padLeft(3, '0')}',
      name: name,
    );
    _nextVehicleNumber++;
    _vehicles.add(vehicle);
    return vehicle;
  }

  @override
  Future<void> setEventVehicle(String eventId, String vehicleId) async {
    await Future<void>.delayed(_delay);

    if (!_events.containsKey(eventId)) throw EventNotFoundException(eventId);
    _selectedVehicles[eventId] = vehicleId;
  }

  @override
  Future<void> saveEvent(Event event) async {
    await Future<void>.delayed(_delay);

    if (!_events.containsKey(event.id)) throw EventNotFoundException(event.id);
    _edited[event.id] = event;
  }

  @override
  Future<List<ChecklistSection>> loadChecklistTemplate() async {
    await Future<void>.delayed(_delay);
    return [
      for (final map in _checklistTemplate)
        _editedCategories[map['id'] as String] ?? ChecklistSection.fromMap(map),
    ];
  }

  @override
  Future<void> saveCategory(ChecklistSection category) async {
    await Future<void>.delayed(_delay);
    _editedCategories[category.id] = category;
  }
}

/// Test događaji. Ključ mape je `id` događaja.
const Map<String, Map<String, dynamic>> _events = {
  'evt-001': {
    'id': 'evt-001',
    // Broj ispred imena je broj godina slavljenika — reč "rođendan"
    // i odrednica "godina" se podrazumevaju i ne pišu se; vrstu nosi 'type'.
    'title': '7 Mia',
    'type': 'rodjendan',
    'scenario': ['Doček gostiju', 'Igre za decu', 'Završni plesni program'],
    'organizerName': 'Jovana Petrović',
    'organizerPhone': '+381641234567',
    'address': 'Bulevar Oslobođenja 45, Novi Sad',
    'latitude': 45.2671,
    'longitude': 19.8335,
    'eventDate': '2026-09-12T16:00:00',
    'departureTime': '2026-09-12T14:30:00',
    'travelDurationMinutes': 35,
    'durationMinutes': 120,
    'vehicleId': 'vehicle-001',
    // Rođendan: samo animacija i tehnika, bez vatre.
    'categoryIds': ['sec-tehnika', 'sec-animacija'],
    'participants': [
      {'name': 'Filip', 'role': 'glavni'},
      {'name': 'Ana', 'role': 'vozač'},
      {'name': 'Marko', 'role': 'pomoćni'},
    ],
    'createdBy': 'Filip',
    'assignedTo': ['Filip', 'Ana', 'Marko'],
  },
  // Samo jedan učesnik — proverava status tima kad fali vozač.
  'evt-002': {
    'id': 'evt-002',
    'title': 'Nikolić',
    'type': 'krstenje',
    'scenario': ['Doček gostiju', 'Bengalke ispred sale'],
    'organizerName': 'Milan Nikolić',
    'organizerPhone': '+381621112233',
    'address': 'Futoški put 12, Novi Sad',
    'latitude': 45.2551,
    'longitude': 19.8181,
    'eventDate': '2026-09-19T18:00:00',
    'departureTime': '2026-09-19T16:45:00',
    'travelDurationMinutes': 25,
    'durationMinutes': 90,
    'vehicleId': 'vehicle-002',
    'categoryIds': ['sec-tehnika', 'sec-specijalni-efekti'],
    'participants': [
      {'name': 'Filip', 'role': 'glavni'},
    ],
    'createdBy': 'Filip',
    'assignedTo': ['Filip'],
  },
  // Bez telefona i bez vozila. Učesnici namerno nemaju upisane uloge —
  // dodeljuju se po redosledu (Filip glavni, Ana vozač).
  'evt-003': {
    'id': 'evt-003',
    'title': 'Jelena i Nemanja',
    'type': 'svadba',
    'scenario': ['Doček mladenaca', 'Vatreni show', 'Svila i hoop tačka'],
    'organizerName': 'Jelena Simić',
    'address': 'Kisačka 78, Novi Sad',
    'latitude': 45.2634,
    'longitude': 19.8443,
    'eventDate': '2026-10-03T20:00:00',
    'departureTime': '2026-10-03T18:30:00',
    'travelDurationMinutes': 40,
    'durationMinutes': 180,
    // Svadba: ide sve, uključujući vatru, svilu i hoop.
    'categoryIds': [
      'sec-tehnika',
      'sec-animacija',
      'sec-specijalni-efekti',
      'sec-vatreni-rekviziti',
      'sec-svila',
      'sec-hoop',
    ],
    'participants': [
      {'name': 'Filip'},
      {'name': 'Ana'},
    ],
    'createdBy': 'Filip',
    'assignedTo': ['Filip', 'Ana'],
  },
  // Sva polja prazna — jedini siguran način da se provere prazna stanja.
  // Napravljen ali još nikome dodeljen — takav se vidi samo u „Delegirani".
  'evt-004': {'id': 'evt-004', 'createdBy': 'Filip'},
};

/// Šablon checkliste opreme.
///
/// Sekcije su one dogovorene u `CLAUDE.md`. **Stavke unutar sekcija su
/// privremene** — treba ih zameniti pravim spiskom opreme.
const List<Map<String, dynamic>> _checklistTemplate = [
  {
    'id': 'sec-tehnika',
    'name': 'Tehnika',
    'items': [
      {'id': 'teh-01', 'name': 'Zvučnik'},
      {'id': 'teh-02', 'name': 'Mikrofon'},
      {'id': 'teh-03', 'name': 'Produžni kabl'},
    ],
  },
  {
    'id': 'sec-animacija',
    'name': 'Animacija',
    'items': [
      {'id': 'ani-01', 'name': 'Kostimi'},
      {'id': 'ani-02', 'name': 'Rekviziti za igre'},
    ],
  },
  {
    'id': 'sec-specijalni-efekti',
    'name': 'Specijalni efekti',
    'items': [
      {'id': 'spe-01', 'name': 'Mašina za dim'},
      {'id': 'spe-02', 'name': 'Konfete'},
    ],
  },
  {
    'id': 'sec-vatreni-rekviziti',
    'name': 'Vatreni rekviziti',
    'items': [
      {'id': 'vat-01', 'name': 'Vatrene lopte'},
      {'id': 'vat-02', 'name': 'Gorivo'},
    ],
  },
  {
    'id': 'sec-svila',
    'name': 'Svila',
    'items': [
      {'id': 'svi-01', 'name': 'Svila'},
      {'id': 'svi-02', 'name': 'Karabineri'},
    ],
  },
  {
    'id': 'sec-hoop',
    'name': 'Hoop',
    'items': [
      {'id': 'hoo-01', 'name': 'Hoop'},
      {'id': 'hoo-02', 'name': 'Sajla za kačenje'},
    ],
  },
];
