import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist.dart';
import '../models/event.dart';
import '../models/team.dart';
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
    final queries = _queriesFor(assignedTo: assignedTo, createdBy: createdBy);

    final byId = <String, Event>{};
    for (final query in queries) {
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        byId[doc.id] = Event.fromMap({...doc.data(), 'id': doc.id});
      }
    }

    return _sorted(byId.values);
  }

  /// Najbliži prvi; događaj bez datuma ide na kraj — ne zna se kada je, pa
  /// ne sme da zauzme vrh spiska.
  static List<Event> _sorted(Iterable<Event> source) {
    final events = source.toList();
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
  Stream<List<Event>> watchEvents({String? assignedTo, String? createdBy}) {
    final queries = _queriesFor(assignedTo: assignedTo, createdBy: createdBy);

    // Jedan upit je i jedan tok — nema šta da se spaja.
    if (queries.length == 1) {
      return queries.first.snapshots().map(
        (snapshot) => _sorted(snapshot.docs.map(_toEvent)),
      );
    }

    // Dva upita („moji" i „delegirani") stižu svaki svojim tempom, pa se
    // pamti poslednje stanje svakog i spaja pri svakoj promeni. Isti događaj
    // ume da dođe kroz oba — zato mapa po `id`-ju, ne lista.
    final latest = List<List<Event>>.filled(queries.length, const []);
    late final StreamController<List<Event>> controller;
    final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      final byId = <String, Event>{};
      for (final events in latest) {
        for (final event in events) {
          byId[event.id] = event;
        }
      }
      controller.add(_sorted(byId.values));
    }

    controller = StreamController<List<Event>>(
      onListen: () {
        for (var i = 0; i < queries.length; i++) {
          final index = i;
          subscriptions.add(
            queries[index].snapshots().listen(
              (snapshot) {
                latest[index] = snapshot.docs.map(_toEvent).toList();
                emit();
              },
              onError: controller.addError,
            ),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Event _toEvent(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      Event.fromMap({...doc.data(), 'id': doc.id});

  /// Isti izbor upita koriste i jednokratno čitanje i praćenje uživo.
  List<Query<Map<String, dynamic>>> _queriesFor({
    String? assignedTo,
    String? createdBy,
  }) => [
    if (assignedTo != null) _events.where('assignedTo', arrayContains: assignedTo),
    if (createdBy != null) _events.where('createdBy', isEqualTo: createdBy),
    if (assignedTo == null && createdBy == null) _events,
  ];

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

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _skills =>
      _db.collection('skills');

  @override
  Future<List<TeamMember>> loadTeam() async {
    final snapshot = await _users.get();
    final team = [
      for (final doc in snapshot.docs)
        TeamMember.fromMap({...doc.data(), 'id': doc.id}),
    ]..removeWhere((member) => member.name.isEmpty);

    team.sort((a, b) => a.name.compareTo(b.name));
    return team;
  }

  @override
  Future<void> saveMemberSkills(TeamMember member) async {
    // `merge` namerno: ime i uloga stoje u istom dokumentu, a njih ovaj
    // ekran ne dira.
    await _users.doc(member.id).set(member.toSkillsMap(), SetOptions(merge: true));
  }

  @override
  Future<List<Skill>> loadSkills() async {
    final snapshot = await _skills.get();
    final skills = [
      for (final doc in snapshot.docs)
        Skill.fromMap({...doc.data(), 'id': doc.id}),
    ]..removeWhere((skill) => skill.name.isEmpty);

    skills.sort((a, b) => a.name.compareTo(b.name));
    return skills;
  }

  @override
  Future<Skill> createSkill(String name) async {
    final doc = _skills.doc();
    final skill = Skill(id: doc.id, name: name.trim());
    await doc.set(skill.toMap());
    return skill;
  }

  @override
  Future<void> saveSkill(Skill skill) => _skills.doc(skill.id).set(skill.toMap());

  @override
  Future<void> deleteSkill(String skillId) async {
    await _skills.doc(skillId).delete();
    // Obrisana veština se skida i sa ljudi — inače bi ostala zalepljena za
    // njih kao id koji više ništa ne znači.
    final holders = await _users
        .where('skills', arrayContains: skillId)
        .get();
    for (final doc in holders.docs) {
      await doc.reference.update({
        'skills': FieldValue.arrayRemove([skillId]),
      });
    }
  }

  @override
  Future<List<String>> loadTeamMembers() async {
    final snapshot = await _users.get();
    final names = [
      for (final doc in snapshot.docs)
        ((doc.data()['name'] as String?) ?? '').trim(),
    ]..removeWhere((name) => name.isEmpty);

    names.sort();
    return names;
  }
}
