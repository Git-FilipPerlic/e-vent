// Sastanak firme — termin i adresa, bez ostalih podataka o događaju
// (dogovoreno 1. oktobra 2026).

import 'package:event_app/models/event.dart';
import 'package:event_app/models/meeting.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:event_app/utils/agenda_grouping.dart';
import 'package:event_app/utils/event_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('model', () {
    test('ide u mapu i nazad bez gubitka', () {
      final meeting = CompanyMeeting(
        id: 'meeting-001',
        dateTime: DateTime(2026, 10, 5, 9, 30),
        address: 'Bulevar Oslobođenja 1, Novi Sad',
      );

      final roundTrip = CompanyMeeting.fromMap({...meeting.toMap(), 'id': meeting.id});
      expect(roundTrip.id, meeting.id);
      expect(roundTrip.dateTime, meeting.dateTime);
      expect(roundTrip.address, meeting.address);
    });

    // Pokvaren zapis ne sme da obori čitanje ostalih sastanaka — ide na
    // dno (bez datuma mu nema smisla, pa pada u prošlost), ne na vrh.
    test('pokvaren datum ne obara čitanje', () {
      final meeting = CompanyMeeting.fromMap({
        'id': 'meeting-002',
        'dateTime': 'ovo-nije-datum',
        'address': 'Adresa',
      });
      expect(meeting.dateTime.isBefore(DateTime(2000)), isTrue);
    });
  });

  group('servis', () {
    test('sastanak se pravi, vidi u spisku i briše', () async {
      final service = MockEventService();
      expect(await service.loadMeetings(), isEmpty);

      final created = await service.createMeeting(
        dateTime: DateTime(2026, 11, 1, 18),
        address: 'Magacin',
      );
      expect((await service.loadMeetings()).map((m) => m.id), [created.id]);

      await service.deleteMeeting(created.id);
      expect(await service.loadMeetings(), isEmpty);
    });

    // Uživo-praćenje (koje se otima o pravo, ne lažno vreme) proverava se
    // kroz ekran, u `events_screen_test.dart` — tamo `tester.pump` meri
    // vreme deterministički.
    test('spisak uživo počinje od onoga što trenutno postoji', () async {
      final service = MockEventService();
      await service.createMeeting(dateTime: DateTime(2026, 11, 1), address: 'Magacin');

      final first = await service.watchMeetings().first;
      expect(first, hasLength(1));
    });
  });

  group('grupisanje sa događajima', () {
    test('sastanak i događaj istog dana stoje u istoj grupi', () {
      final now = DateTime(2026, 10, 1, 10);
      final event = Event(id: 'evt-x', eventDate: DateTime(2026, 10, 1, 16));
      final meeting = CompanyMeeting(
        id: 'meeting-x',
        dateTime: DateTime(2026, 10, 1, 9),
        address: 'Magacin',
      );

      final sections = groupAgenda(events: [event], meetings: [meeting], now: now);

      expect(sections, hasLength(1));
      expect(sections.single.group, EventGroup.danas);
      // Sastanak je ranije tog dana, pa ide prvi.
      final ids = [
        for (final entry in sections.single.entries)
          switch (entry) {
            EventEntry(:final event) => event.id,
            MeetingEntry(:final meeting) => meeting.id,
          },
      ];
      expect(ids, ['meeting-x', 'evt-x']);
    });
  });
}
