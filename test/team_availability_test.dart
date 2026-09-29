import 'package:event_app/models/event.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/utils/team_availability.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _four = DateTime(2026, 10, 3, 16);

Event _event(
  String id, {
  String? title,
  DateTime? at,
  int? minutes,
  List<String> crew = const [],
}) => Event(
  id: id,
  title: title,
  eventDate: at,
  durationMinutes: minutes,
  assignedTo: crew,
);

void main() {
  setUpAll(() => AppDate.init());

  test('ko radi na događaju koji se preklapa je zauzet, uz naziv i sat', () {
    final busy = busyMembers(
      events: [_event('a', title: '7 Mia', at: _four, minutes: 120, crew: ['Ana'])],
      start: _four.add(const Duration(hours: 1)),
      durationMinutes: 60,
    );

    expect(busy, {'Ana': 'Radi na: 7 Mia, 16:00'});
  });

  test('nastup koji počinje kad se drugi završi nije sukob', () {
    final busy = busyMembers(
      events: [_event('a', at: _four, minutes: 120, crew: ['Ana'])],
      start: _four.add(const Duration(hours: 2)),
      durationMinutes: 60,
    );

    expect(busy, isEmpty);
  });

  test('bez ugovorenog trajanja računa se četiri sata', () {
    final events = [_event('a', at: _four, crew: ['Ana'])];

    expect(
      busyMembers(events: events, start: _four.add(const Duration(hours: 3))),
      contains('Ana'),
    );
    expect(
      busyMembers(events: events, start: _four.add(const Duration(hours: 4))),
      isEmpty,
    );
  });

  test('događaj koji se menja ne čini ekipu zauzetom samim sobom', () {
    final busy = busyMembers(
      events: [_event('a', at: _four, crew: ['Ana'])],
      start: _four,
      exceptEventId: 'a',
    );

    expect(busy, isEmpty);
  });

  test('bez početka nema provere — ništa se ne nagađa', () {
    final busy = busyMembers(
      events: [_event('a', at: _four, crew: ['Ana'])],
      start: null,
    );

    expect(busy, isEmpty);
  });

  test('događaj bez datuma nikog ne zauzima', () {
    final busy = busyMembers(
      events: [_event('a', crew: ['Ana'])],
      start: _four,
    );

    expect(busy, isEmpty);
  });

  test('događaj bez naziva se opisuje rečima, a prvi sukob ima prednost', () {
    final busy = busyMembers(
      events: [
        _event('b', title: 'Svadba', at: _four.add(const Duration(hours: 1)), crew: ['Ana']),
        _event('a', at: _four, crew: ['Ana']),
      ],
      start: _four,
    );

    expect(busy['Ana'], 'Radi na: drugi događaj, 16:00');
  });
}
