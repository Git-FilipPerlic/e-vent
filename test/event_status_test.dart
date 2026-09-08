import 'package:event_app/models/event.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/data_readiness.dart';
import 'package:event_app/widgets/home/event_reminder.dart';
import 'package:event_app/widgets/home/event_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

final DateTime _departure = DateTime(2026, 9, 12, 14, 30);
final DateTime _start = DateTime(2026, 9, 12, 16, 0);

/// Lažni sat koji uvek vraća isto vreme.
DateTime Function() _clockAt(DateTime moment) => () => moment;

void main() {
  group('spremnost podataka', () {
    test('pun događaj nema šta da fali', () {
      final event = Event(
        id: 'evt-001',
        title: 'Rođendan',
        organizerName: 'Jovana',
        organizerPhone: '+381641234567',
        address: 'Kisačka 78',
        eventDate: _start,
        durationMinutes: 120,
        departureTime: _departure,
        vehicleId: 'vehicle-001',
        participants: const [
          Participant(name: 'Marko', role: ParticipantRole.glavni),
        ],
      );

      expect(DataReadiness.missingFor(event), isEmpty);
    });

    test('prazan događaj prijavljuje sve što fali', () {
      const event = Event(id: 'evt-004');

      expect(
        DataReadiness.missingFor(event).length,
        DataReadiness.totalChecks,
      );
    });

    test('kad događaja nema, fale svi podaci', () {
      expect(DataReadiness.missingFor(null), ['svi podaci']);
    });

    testWidgets('prikazuje koliko je popunjeno i šta fali',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const DataReadiness(
            event: Event(id: 'evt-004', title: 'Samo naziv'),
          ),
        ),
      );

      expect(find.text('1/9'), findsOneWidget);
      expect(find.textContaining('Nedostaje:'), findsOneWidget);
    });
  });

  group('status događaja', () {
    EventPhase? phaseAt(DateTime now) => EventStatusBanner.phaseAt(
          now: now,
          departure: _departure,
          eventStart: _start,
        );

    test('pre polaska je planirano', () {
      expect(phaseAt(DateTime(2026, 9, 12, 10, 0)), EventPhase.planirano);
    });

    test('od vremena polaska do početka je polazak', () {
      expect(phaseAt(_departure), EventPhase.polazak);
      expect(phaseAt(DateTime(2026, 9, 12, 15, 30)), EventPhase.polazak);
    });

    test('od početka je u toku', () {
      expect(phaseAt(_start), EventPhase.uToku);
      expect(phaseAt(DateTime(2026, 9, 12, 18, 0)), EventPhase.uToku);
    });

    test('posle pretpostavljenog trajanja je završeno', () {
      final after = _start.add(
        EventStatusBanner.assumedDuration + const Duration(minutes: 1),
      );
      expect(phaseAt(after), EventPhase.zavrseno);
    });

    test('bez ijednog vremena status nije poznat', () {
      expect(
        EventStatusBanner.phaseAt(now: DateTime(2026, 9, 12), departure: null,
            eventStart: null),
        isNull,
      );
    });

    testWidgets('prikazuje naziv faze', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventStatusBanner(
            departure: _departure,
            eventStart: _start,
            now: _clockAt(DateTime(2026, 9, 12, 15, 0)),
          ),
        ),
      );

      expect(find.text('Polazak'), findsOneWidget);
    });

    testWidgets('bez vremena piše da status nije poznat',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventStatusBanner(
            departure: null,
            eventStart: null,
            now: _clockAt(DateTime(2026, 9, 12, 15, 0)),
          ),
        ),
      );

      expect(find.text('Status nije poznat'), findsOneWidget);
    });
  });

  group('podsetnik', () {
    test('preostalo vreme se piše kratko', () {
      expect(EventReminder.formatRemaining(const Duration(seconds: 30)),
          'manje od minut');
      expect(EventReminder.formatRemaining(const Duration(minutes: 45)),
          '45 min');
      expect(EventReminder.formatRemaining(const Duration(hours: 2)), '2 h');
      expect(
        EventReminder.formatRemaining(const Duration(hours: 2, minutes: 15)),
        '2 h 15 min',
      );
      expect(EventReminder.formatRemaining(const Duration(days: 3)), '3 d');
      expect(
        EventReminder.formatRemaining(const Duration(days: 1, hours: 5)),
        '1 d 5 h',
      );
    });

    testWidgets('pre polaska odbrojava do polaska',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventReminder(
            departure: _departure,
            eventStart: _start,
            now: _clockAt(DateTime(2026, 9, 12, 12, 15)),
          ),
        ),
      );

      expect(find.text('Polazak za 2 h 15 min'), findsOneWidget);
    });

    testWidgets('posle polaska odbrojava do početka događaja',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventReminder(
            departure: _departure,
            eventStart: _start,
            now: _clockAt(DateTime(2026, 9, 12, 15, 0)),
          ),
        ),
      );

      expect(find.text('Početak događaja za 1 h'), findsOneWidget);
    });

    testWidgets('kad je sve prošlo, nema više čekanja',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventReminder(
            departure: _departure,
            eventStart: _start,
            now: _clockAt(DateTime(2026, 9, 12, 20, 0)),
          ),
        ),
      );

      expect(find.text('Nema više čekanja'), findsOneWidget);
    });

    testWidgets('bez unetih vremena to i piše', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventReminder(
            departure: null,
            eventStart: null,
            now: _clockAt(DateTime(2026, 9, 12, 20, 0)),
          ),
        ),
      );

      expect(find.text('Vremena nisu uneta'), findsOneWidget);
    });
  });
}
