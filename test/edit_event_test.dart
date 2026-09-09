import 'package:event_app/models/event.dart';
import 'package:event_app/screens/home_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/services/event_service.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/common/edit_text_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: child);
}

/// Olovka koja menja baš to polje. Traži se po nazivu polja, ne po broju
/// olovaka — spisak se gradi u koracima, pa broj zavisi od skrolovanja.
Finder _pencil(String label) => find.byWidgetPredicate(
  (widget) => widget is EditFieldButton && widget.label == label,
);

void main() {
  setUpAll(() => AppDate.init());

  group('izmena podataka o događaju', () {
    test('copyWith menja samo prosleđeno polje', () {
      const event = Event(
        id: 'evt-001',
        title: 'Stari naziv',
        organizerName: 'Jovana',
      );

      final changed = event.copyWith(title: 'Novi naziv');

      expect(changed.title, 'Novi naziv');
      // Ostalo se ne dira.
      expect(changed.organizerName, 'Jovana');
      expect(changed.id, 'evt-001');
    });

    test('prazan tekst briše podatak', () {
      const event = Event(id: 'evt-001', organizerPhone: '+381641234567');

      expect(event.copyWith(organizerPhone: '  ').organizerPhone, isNull);
    });

    test('višak razmaka se skida', () {
      const event = Event(id: 'evt-001');

      expect(event.copyWith(title: '  Svadba  ').title, 'Svadba');
    });

    test('servis pamti izmenu i vraća je pri sledećem učitavanju', () async {
      final service = MockEventService();
      final event = await service.loadEvent('evt-001');

      await service.saveEvent(event.copyWith(title: 'Izmenjen naziv'));
      final reloaded = await service.loadEvent('evt-001');

      expect(reloaded.title, 'Izmenjen naziv');
    });

    test('izmena nepostojećeg događaja se odbija', () async {
      final service = MockEventService();

      expect(
        () => service.saveEvent(const Event(id: 'nema-me')),
        throwsA(isA<EventNotFoundException>()),
      );
    });
  });

  group('olovke na karticama', () {
    testWidgets('bez prijave nema nijedne olovke',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(auth: MockAuthService())));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });

    testWidgets('prijavljen glavni dobija olovke na karticama',
        (WidgetTester tester) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      // Naziv, organizator, telefon i adresa.
      // Ne broji se koliko ih ima — spisak se gradi u koracima, pa broj
      // zavisi od toga dokle je skrolovano. Proverava se da su prave tu.
      expect(_pencil('Naziv događaja'), findsOneWidget);
      expect(_pencil('Datum, sat i trajanje'), findsOneWidget);
      expect(_pencil('Organizator'), findsOneWidget);
    });

    testWidgets('izvođač bez dozvole nema olovke',
        (WidgetTester tester) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Ana', pin: '1111');

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });

    testWidgets('izmena naziva se odmah vidi na kartici',
        (WidgetTester tester) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      await tester.tap(_pencil('Naziv događaja'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '9 Petar');
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      expect(find.textContaining('9 Petar'), findsOneWidget);
    });
  });
}
