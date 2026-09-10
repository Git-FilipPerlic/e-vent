import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist.dart';
import '../models/event.dart';
import '../models/vehicle.dart';
import 'event_service.dart';

/// Podaci iz Firestore baze.
///
/// **Isti interfejs kao mock servis**, pa se zamena svodi na jednu liniju
/// tamo gde se servis pravi — nijedan ekran se ne dira. To je i bio razlog
/// što od početka nijedan widget ne priča sa bazom.
///
/// Kolekcije:
///
/// * `events/{id}` — događaji
/// * `vehicles/{id}` — vozila
/// * `checklistTemplates/{id}` — kategorije opreme sa delovima
/// * `users/{id}` — ekipa; iz nje se bira kome se događaj dodeljuje
class FirestoreEventService implements EventService {
  FirestoreEventService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  @override
  Future<Event> loadEvent(String eventId) async {
    final doc = await _events.doc(eventId).get();
    final data = doc.data();
    if (!doc.exists || data == null) throw EventNotFoundException(eventId);

    return Event.fromMap({...data, 'id': doc.id});
  }

  @override
  Future<List<Event>> loadEvents({
    String? assignedTo,
    String? createdBy,
  }) async {
    // Filtrira **baza**, ne ekran. Da ekran prosejava, tuđi događaji bi mu
    // ionako već stigli — a to je upravo ono što pravila pristupa brane.
    final queries = <Query<Map<String, dynamic>>>[
      if (assignedTo != null)
        _events.where('assignedTo', arrayContains: assignedTo),
      if (createdBy != null) _events.where('createdBy', isEqualTo: createdBy),
      if (assignedTo == null && createdBy == null) _events,
    ];

    final byId = <String, Event>{};
    for (final query in queries) {
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        byId[doc.id] = Event.fromMap({...doc.data(), 'id': doc.id});
      }
    }

    final events = byId.values.toList();
    // Najbliži prvi; događaj bez datuma ide na kraj — ne zna se kada je, pa
    // ne sme da zauzme vrh spiska.
    events.sort((a, b) {
      final left = a.eventDate;
      final right = b.eventDate;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
    return events;
  }

  @override
  Future<Event> createEvent({
    required String createdBy,
    String? title,
    EventType? type,
    DateTime? eventDate,
    int? durationMinutes,
    List<String> assignedTo = const [],
  }) async {
    final trimmed = title?.trim();
    final doc = _events.doc();

    final event = Event(
      id: doc.id,
      title: trimmed == null || trimmed.isEmpty ? null : trimmed,
      type: type,
      eventDate: eventDate,
      durationMinutes: durationMinutes,
      createdBy: createdBy,
      assignedTo: assignedTo,
    );

    await doc.set(event.toMap());
    return event;
  }

  @override
  Future<void> saveEvent(Event event) async {
    final doc = _events.doc(event.id);
    if (!(await doc.get()).exists) throw EventNotFoundException(event.id);

    // Ceo dokument se prepisuje: `toMap` izostavlja prazna polja, pa bi
    // spajanje ostavilo stare vrednosti tamo gde je korisnik obrisao podatak.
    await doc.set(event.toMap());
  }

  @override
  Future<void> setEventVehicle(String eventId, String vehicleId) async {
    final doc = _events.doc(eventId);
    if (!(await doc.get()).exists) throw EventNotFoundException(eventId);

    await doc.update({'vehicleId': vehicleId});
  }

  @override
  Future<List<Vehicle>> loadVehicles() async {
    final snapshot = await _db.collection('vehicles').get();
    return [
      for (final doc in snapshot.docs)
        Vehicle.fromMap({...doc.data(), 'id': doc.id}),
    ];
  }

  @override
  Future<Vehicle> addVehicle(String name) async {
    final doc = _db.collection('vehicles').doc();
    final vehicle = Vehicle(id: doc.id, name: name.trim());
    await doc.set({'name': vehicle.name});
    return vehicle;
  }

  @override
  Future<List<ChecklistSection>> loadChecklistTemplate() async {
    final snapshot = await _db.collection('checklistTemplates').get();
    return [
      for (final doc in snapshot.docs)
        ChecklistSection.fromMap({...doc.data(), 'id': doc.id}),
    ];
  }

  @override
  Future<ChecklistSection> createCategory(String name) async {
    final doc = _db.collection('checklistTemplates').doc();
    final category = ChecklistSection(id: doc.id, name: name.trim());
    await doc.set(category.toMap());
    return category;
  }

  @override
  Future<void> deleteCategory(String categoryId) =>
      _db.collection('checklistTemplates').doc(categoryId).delete();

  @override
  Future<void> saveCategory(ChecklistSection category) async {
    // Menja **katalog firme**, pa se izmena vidi na svim događajima koji tu
    // kategoriju nose.
    await _db
        .collection('checklistTemplates')
        .doc(category.id)
        .set(category.toMap());
  }

  @override
  Future<List<String>> loadTeamMembers() async {
    final snapshot = await _db.collection('users').get();
    final names = [
      for (final doc in snapshot.docs)
        ((doc.data()['name'] as String?) ?? '').trim(),
    ]..removeWhere((name) => name.isEmpty);

    names.sort();
    return names;
  }
}
