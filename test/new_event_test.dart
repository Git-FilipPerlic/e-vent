import 'package:event_app/models/event.dart';
import 'package:event_app/screens/events_screen.dart';
import 'package:event_app/screens/home_screen.dart';
import 'package:event_app/screens/new_event_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/team_assignment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ista podešavanja jezika kao u pravoj aplikaciji — sistemski birači bez
/// njih pucaju.
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  locale: AppDate.locale2,
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
    Locale('sr'),
    Locale('en'),
  ],
  home: child,
);

Future<MockAuthService> _signedInManager() async {
  final auth = MockAuthService();
  await auth.signIn(name: 'Filip', pin: '1234');
  return auth;
}

void main() {
  setUpAll(() => AppDate.init());

  group('servis', () {
    test('nov događaj dobija id i upisuje ko ga je napravio', () async {
      final service = MockEventService();

      final event = await service.createEvent(
        createdBy: 'Filip',
        title: '5 Luka',
        type: EventType.rodjendan,
        eventDate: DateTime(2026, 10, 10, 17),
        durationMinutes: 90,
        assignedTo: const ['Filip', 'Ana'],
      );

      expect(event.id, isNotEmpty);
      expect(event.createdBy, 'Filip');
      expect(event.assignedTo, ['Filip', 'Ana']);
      expect(event.type, EventType.rodjendan);
    });

    test('nov događaj se vidi u spisku i može da se učita', () async {
      final service = MockEventService();
      final created = await service.createEvent(
        createdBy: 'Filip',
        title: '5 Luka',
        eventDate: DateTime(2026, 10, 10, 17),
        assignedTo: const ['Ana'],
      );

      final loaded = await service.loadEvent(created.id);
      expect(loaded.title, '5 Luka');

      // Ani je dodeljen, Marku nije.
      final anini = await service.loadEvents(assignedTo: 'Ana');
      expect(anini.map((e) => e.id), contains(created.id));
      final markovi = await service.loadEvents(assignedTo: 'Marko');
      expect(markovi.map((e) => e.id), isNot(contains(created.id)));
    });

    test('nov događaj može odmah da se dopuni', () async {
      final service = MockEventService();
      final created = await service.createEvent(createdBy: 'Filip');

      await service.saveEvent(created.copyWith(address: 'Kisačka 78'));
      final loaded = await service.loadEvent(created.id);

      expect(loaded.address, 'Kisačka 78');
    });

    test('prazan naziv se pamti kao da ga nema', () async {
      final service = MockEventService();
      final created = await service.createEvent(
        createdBy: 'Filip',
        title: '   ',
      );

      expect(created.title, isNull);
    });
  });

  group('ekran za nov događaj', () {
    testWidgets('onaj ko pravi događaj je unapred izabran', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          NewEventScreen(service: MockEventService(), createdBy: 'Filip'),
        ),
      );
      // Spisak ekipe stiže sa zakašnjenjem; `pumpAndSettle` ne čeka tajmere.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final filip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Filip'),
      );
      final ana = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Ana'),
      );

      expect(filip.selected, isTrue);
      expect(ana.selected, isFalse);
    });

    testWidgets('pravi događaj sa vrstom, nazivom i ekipom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          NewEventScreen(service: MockEventService(), createdBy: 'Filip'),
        ),
      );
      // Spisak ekipe stiže sa zakašnjenjem; `pumpAndSettle` ne čeka tajmere.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Svadba'));
      await tester.enterText(find.byType(TextField), 'Mina i Pavle');
      await tester.tap(find.widgetWithText(FilterChip, 'Ana'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Napravi i podeli'));
      await tester.pumpAndSettle();

      // Ekran se zatvorio, znači da je događaj napravljen.
      expect(find.text('Napravi i podeli'), findsNothing);
    });

    testWidgets('vrsta se skida ponovnim dodirom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          NewEventScreen(service: MockEventService(), createdBy: 'Filip'),
        ),
      );
      // Spisak ekipe stiže sa zakašnjenjem; `pumpAndSettle` ne čeka tajmere.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Nastup'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Nastup'))
            .selected,
        isTrue,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Nastup'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Nastup'))
            .selected,
        isFalse,
      );
    });
  });

  group('dugme na spisku', () {
    testWidgets('bez dozvole nema dugmeta za nov događaj', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(EventsScreen(onOpen: (_) {}, auth: MockAuthService())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nov događaj'), findsNothing);
    });

    testWidgets('manager dobija dugme i njime otvara ekran', (
      WidgetTester tester,
    ) async {
      final auth = await _signedInManager();

      await tester.pumpWidget(
        _wrap(EventsScreen(onOpen: (_) {}, auth: auth)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nov događaj'));
      await tester.pumpAndSettle();

      expect(find.text('Napravi i podeli'), findsOneWidget);
    });
  });

  group('dodela sa Home taba', () {
    testWidgets('prikazuje kome je događaj dodeljen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byType(TeamAssignment), 300);
      await tester.pumpAndSettle();

      expect(find.text('Ko radi'), findsOneWidget);
      // evt-001 nose Filip, Ana i Marko.
      final card = tester.widget<TeamAssignment>(find.byType(TeamAssignment));
      expect(card.assignedTo, ['Filip', 'Ana', 'Marko']);
    });

    testWidgets('bez dozvole se dodela ne menja', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(auth: MockAuthService())));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byType(TeamAssignment), 300);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Dodeli događaj'), findsNothing);
    });

    testWidgets('manager menja dodelu i izmena se odmah vidi', (
      WidgetTester tester,
    ) async {
      final auth = await _signedInManager();

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byType(TeamAssignment), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Dodeli događaj'));
      // Spisak ekipe se učitava tek kad se list otvara.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Marko izlazi iz ekipe za ovaj događaj.
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Marko'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      final card = tester.widget<TeamAssignment>(
        find.byType(TeamAssignment),
      );
      expect(card.assignedTo, ['Filip', 'Ana']);
    });
  });
}
