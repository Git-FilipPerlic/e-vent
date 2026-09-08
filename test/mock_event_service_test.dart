import 'package:event_app/models/event.dart';
import 'package:event_app/services/event_service.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockEventService service;

  setUp(() => service = MockEventService());

  test('evt-001 ima sve podatke i tri učesnika', () async {
    final event = await service.loadEvent('evt-001');

    expect(event.title, 'Rođendan - Mia (7 godina)');
    expect(event.organizerPhone, '+381641234567');
    expect(event.hasCoordinates, isTrue);
    expect(event.participants, hasLength(3));
    expect(event.glavni?.name, 'Filip');
    expect(event.vozac?.name, 'Ana');
  });

  test('evt-003 nema telefon ni vozilo, uloge se dodeljuju po redosledu',
      () async {
    final event = await service.loadEvent('evt-003');

    expect(event.organizerPhone, isNull);
    expect(event.vehicleId, isNull);
    expect(event.participants[0].role, ParticipantRole.glavni);
    expect(event.participants[1].role, ParticipantRole.vozac);
  });

  test('evt-004 je prazan i ne puca', () async {
    final event = await service.loadEvent('evt-004');

    expect(event.id, 'evt-004');
    expect(event.title, isNull);
    expect(event.eventDate, isNull);
    expect(event.hasCoordinates, isFalse);
    expect(event.scenario, isEmpty);
    expect(event.participants, isEmpty);
    expect(event.glavni, isNull);
  });

  test('nepostojeći događaj baca EventNotFoundException', () {
    expect(
      () => service.loadEvent('evt-999'),
      throwsA(isA<EventNotFoundException>()),
    );
  });

  test('dodavanje vozila vraća novo vozilo i pamti ga', () async {
    expect(await service.loadVehicles(), hasLength(2));

    final added = await service.addVehicle('Crni Transporter');
    expect(added.id, 'vehicle-003');

    final vehicles = await service.loadVehicles();
    expect(vehicles, hasLength(3));
    expect(vehicles.last.name, 'Crni Transporter');
  });

  test('checklist šablon ima svih šest sekcija', () async {
    final sections = await service.loadChecklistTemplate();

    expect(
      sections.map((s) => s.name),
      containsAll(<String>[
        'Tehnika',
        'Animacija',
        'Specijalni efekti',
        'Vatreni rekviziti',
        'Svila',
        'Hoop',
      ]),
    );
  });
}
