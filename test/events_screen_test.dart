import 'package:event_app/models/checklist.dart';
import 'package:event_app/models/event.dart';
import 'package:event_app/models/vehicle.dart';
import 'package:event_app/screens/events_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/services/event_service.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servis koji uvek pukne — za proveru poruke o grešci.
class _FailingService implements EventService {
  @override
  Future<List<Event>> loadEvents({String? assignedTo, String? createdBy}) {
    throw Exception('nema mreže');
  }

  @override
  Future<Event> loadEvent(String eventId) => throw UnimplementedError();
  @override
  Future<List<Vehicle>> loadVehicles() => throw UnimplementedError();
  @override
  Future<Vehicle> addVehicle(String name) => throw UnimplementedError();
  @override
  Future<void> setEventVehicle(String eventId, String vehicleId) =>
      throw UnimplementedError();
  @override
  Future<void> saveEvent(Event event) => throw UnimplementedError();
  @override
  Future<List<ChecklistSection>> loadChecklistTemplate() =>
      throw UnimplementedError();
  @override
  Future<void> saveCategory(ChecklistSection category) =>
      throw UnimplementedError();
}

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

void main() {
  setUpAll(() => AppDate.init());

  group('spisak događaja', () {
    testWidgets('prikazuje događaje sa satom i mestom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(EventsScreen(onOpen: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('7 Mia'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);
      // Mesto i trajanje dele donji red, da naziv ne bi bio isečen.
      expect(find.text('Novi Sad · 2h'), findsOneWidget);
    });

    testWidgets('događaj bez datuma ima crticu umesto sata', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(EventsScreen(onOpen: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('Događaj bez naziva'), findsOneWidget);
    });

    testWidgets('dodir na događaj javlja koji je izabran', (
      WidgetTester tester,
    ) async {
      String? opened;

      await tester.pumpWidget(
        _wrap(EventsScreen(onOpen: (id) => opened = id)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('7 Mia'));
      await tester.pump();

      expect(opened, 'evt-001');
    });

    testWidgets('greška nudi pokušaj ponovo', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(EventsScreen(onOpen: (_) {}, service: _FailingService())),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('nije učitan'), findsOneWidget);
      expect(find.text('Pokušaj ponovo'), findsOneWidget);
    });
  });

  group('čiji se spisak gleda', () {
    testWidgets('bez prijave nema prekidača', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(EventsScreen(onOpen: (_) {}, auth: MockAuthService())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delegirani'), findsNothing);
    });

    testWidgets('izvođač vidi samo svoje događaje, bez prekidača', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Ana', pin: '1111');

      await tester.pumpWidget(
        _wrap(EventsScreen(onOpen: (_) {}, auth: auth)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delegirani'), findsNothing);
      expect(find.text('7 Mia'), findsOneWidget);
      // Krštenje je dodeljeno samo Filipu.
      expect(find.textContaining('Krštenje'), findsNothing);
    });

    testWidgets('manager prebacuje na delegirane', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(
        _wrap(EventsScreen(onOpen: (_) {}, auth: auth)),
      );
      await tester.pumpAndSettle();

      // "Moji" ne sadrži događaj koji još nikome nije dodeljen.
      expect(find.text('Događaj bez naziva'), findsNothing);

      await tester.tap(find.text('Delegirani'));
      await tester.pumpAndSettle();

      expect(find.text('Događaj bez naziva'), findsOneWidget);
    });

    testWidgets('prazan spisak objasni zašto je prazan', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService(
        signedInAs: const AppUser(name: 'Nepoznat', role: UserRole.user),
      );

      await tester.pumpWidget(
        _wrap(
          EventsScreen(
            onOpen: (_) {},
            auth: auth,
            service: MockEventService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('nije dodeljen'), findsOneWidget);
    });
  });
}
