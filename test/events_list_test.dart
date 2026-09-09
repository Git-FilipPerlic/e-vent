import 'package:event_app/models/event.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('spisak događaja', () {
    test('bez filtera vraća sve, poređane po datumu', () async {
      final service = MockEventService();
      final events = await service.loadEvents();

      expect(events.map((e) => e.id), [
        'evt-001', // 12. septembar
        'evt-002', // 19. septembar
        'evt-003', // 3. oktobar
        'evt-004', // bez datuma — na kraju
      ]);
    });

    test('„moji" su samo dodeljeni događaji', () async {
      final service = MockEventService();
      final events = await service.loadEvents(assignedTo: 'Ana');

      // Ana je na rođendanu i svadbi, ali ne i na krštenju.
      expect(events.map((e) => e.id), ['evt-001', 'evt-003']);
    });

    test('veličina slova u imenu ne menja spisak', () async {
      final service = MockEventService();
      final events = await service.loadEvents(assignedTo: '  ana  ');

      expect(events.map((e) => e.id), ['evt-001', 'evt-003']);
    });

    test('„delegirani" su svi koje je manager napravio', () async {
      final service = MockEventService();
      final events = await service.loadEvents(createdBy: 'Filip');

      // Uključujući i onaj koji još nikome nije dodeljen.
      expect(events.map((e) => e.id), contains('evt-004'));
      expect(events, hasLength(4));
    });

    test('ko ništa nema, nema ni spisak', () async {
      final service = MockEventService();

      expect(await service.loadEvents(assignedTo: 'Nepoznat'), isEmpty);
      expect(await service.loadEvents(createdBy: 'Nepoznat'), isEmpty);
    });

    test('izmena događaja se vidi i u spisku', () async {
      final service = MockEventService();
      final event = await service.loadEvent('evt-001');

      await service.saveEvent(event.copyWith(title: 'Novi naziv'));
      final events = await service.loadEvents();

      expect(events.first.title, 'Novi naziv');
    });
  });

  group('dodela događaja', () {
    const event = Event(
      id: 'evt-x',
      createdBy: 'Filip',
      assignedTo: ['Filip', 'Ana'],
    );

    test('prepoznaje kome je dodeljen', () {
      expect(event.isAssignedTo('ana'), isTrue);
      expect(event.isAssignedTo('Marko'), isFalse);
      // Prazno ime nikad ne pogađa nikoga.
      expect(event.isAssignedTo('   '), isFalse);
    });

    test('prepoznaje ko ga je napravio', () {
      expect(event.isCreatedBy('FILIP'), isTrue);
      expect(event.isCreatedBy('Ana'), isFalse);
      expect(const Event(id: 'evt-y').isCreatedBy('Filip'), isFalse);
    });

    test('izmena podataka ne gubi dodelu', () {
      final edited = event.copyWith(title: 'Nešto');

      expect(edited.createdBy, 'Filip');
      expect(edited.assignedTo, ['Filip', 'Ana']);
    });

    test('promena vozila ne gubi dodelu', () {
      final edited = event.withVehicle('vehicle-002');

      expect(edited.createdBy, 'Filip');
      expect(edited.assignedTo, ['Filip', 'Ana']);
    });
  });
}
