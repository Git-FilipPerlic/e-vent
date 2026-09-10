import 'package:event_app/screens/home_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/common/edit_text_sheet.dart';
import 'package:event_app/widgets/common/event_when_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ista podešavanja jezika kao u pravoj aplikaciji.
///
/// Bitno je da ih test ima: bez njih `showDatePicker` na telefonu ruši ekran
/// porukom „No MaterialLocalizations found", a to se u testu sa podrazumevanim
/// `MaterialApp`-om ne bi videlo.
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

/// Olovka koja menja baš to polje.
Finder _pencil(String label) => find.byWidgetPredicate(
  (widget) => widget is EditFieldButton && widget.label == label,
);

/// Otvara list „Kada i koliko" sa datom vrednošću i vraća šta je izabrano.
Future<EventWhen?> _openSheet(
  WidgetTester tester,
  EventWhen value, {
  required Future<void> Function(WidgetTester tester) act,
}) async {
  EventWhen? result;

  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showEventWhenSheet(context, value: value);
          },
          child: const Text('otvori'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('otvori'));
  await tester.pumpAndSettle();
  await act(tester);
  return result;
}

void main() {
  setUpAll(() => AppDate.init());

  group('list „Kada i koliko"', () {
    testWidgets('prikazuje postojeći datum, sat i trajanje', (
      WidgetTester tester,
    ) async {
      await _openSheet(
        tester,
        EventWhen(
          start: DateTime(2026, 9, 12, 16, 0),
          durationMinutes: 120,
        ),
        act: (tester) async {},
      );

      // Godina se ne piše kad je tekuća — na uskom telefonu je zbog nje
      // datum ispadao kao „12. septembar …".
      expect(find.text('12. septembar'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);
      // Izabrano trajanje stoji među ponuđenima.
      expect(find.widgetWithText(ChoiceChip, '2h'), findsOneWidget);
    });

    testWidgets('prazno stanje ne puca', (WidgetTester tester) async {
      await _openSheet(
        tester,
        const EventWhen(),
        act: (tester) async {},
      );

      // Prazno, ne „Nije unet": red se zove „Datum" i vodi u kalendar, pa se
      // iz konteksta zna šta se bira.
      expect(find.text('Nije unet'), findsNothing);
      expect(find.text('Datum'), findsOneWidget);
      expect(find.text('Sat početka'), findsOneWidget);
    });

    testWidgets('odustajanje ne menja ništa', (WidgetTester tester) async {
      final result = await _openSheet(
        tester,
        EventWhen(start: DateTime(2026, 9, 12, 16, 0), durationMinutes: 120),
        act: (tester) async {
          await tester.tap(find.text('Odustani'));
          await tester.pumpAndSettle();
        },
      );

      expect(result, isNull);
    });

    testWidgets('izbor trajanja se vraća ekranu', (WidgetTester tester) async {
      final result = await _openSheet(
        tester,
        EventWhen(start: DateTime(2026, 9, 12, 16, 0), durationMinutes: 120),
        act: (tester) async {
          await tester.tap(find.widgetWithText(ChoiceChip, '3h'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sačuvaj'));
          await tester.pumpAndSettle();
        },
      );

      expect(result?.durationMinutes, 180);
      // Datum se ne dira kad se menja samo trajanje.
      expect(result?.start, DateTime(2026, 9, 12, 16, 0));
    });

    testWidgets('„Drugo" prima trajanje u minutima', (
      WidgetTester tester,
    ) async {
      final result = await _openSheet(
        tester,
        const EventWhen(),
        act: (tester) async {
          await tester.tap(find.widgetWithText(ChoiceChip, 'Drugo'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), '150');
          await tester.tap(find.widgetWithText(FilledButton, 'Sačuvaj').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sačuvaj'));
          await tester.pumpAndSettle();
        },
      );

      expect(result?.durationMinutes, 150);
    });

    testWidgets('besmislen broj minuta se ne prihvata', (
      WidgetTester tester,
    ) async {
      final result = await _openSheet(
        tester,
        const EventWhen(),
        act: (tester) async {
          await tester.tap(find.widgetWithText(ChoiceChip, 'Drugo'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), '0');
          await tester.tap(find.widgetWithText(FilledButton, 'Sačuvaj').last);
          await tester.pumpAndSettle();
          // Dijalog ostaje otvoren; odustaje se pa se zatvara list.
          await tester.tap(find.text('Odustani').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sačuvaj'));
          await tester.pumpAndSettle();
        },
      );

      expect(result?.durationMinutes, isNull);
    });
  });

  group('biranje na Home tabu', () {
    testWidgets('bez dozvole nema olovke za datum ni za polazak', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(HomeScreen(auth: MockAuthService())));
      await tester.pumpAndSettle();

      expect(_pencil('Datum, sat i trajanje'), findsNothing);
      expect(_pencil('Vreme polaska'), findsNothing);
    });

    testWidgets('olovka za datum otvara izbor', (WidgetTester tester) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      await tester.tap(_pencil('Datum, sat i trajanje'));
      await tester.pumpAndSettle();

      expect(find.text('Kada i koliko'), findsOneWidget);
      // Isti datum stoji i na kartici ispod lista, pa ih je dva.
      expect(find.text('12. septembar'), findsWidgets);
    });

    testWidgets('sistemski birač datuma se otvara na srpskom', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      await tester.tap(_pencil('Datum, sat i trajanje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Datum'));
      await tester.pumpAndSettle();

      // Bez srpskih prevoda ovde puca „No MaterialLocalizations found".
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('sistemski birač sata se otvara', (WidgetTester tester) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      await tester.tap(_pencil('Datum, sat i trajanje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sat početka'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('izmena trajanja se odmah vidi na kartici', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(HomeScreen(auth: auth)));
      await tester.pumpAndSettle();

      await tester.tap(_pencil('Datum, sat i trajanje'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '3h'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      expect(find.textContaining('3h'), findsOneWidget);
    });
  });
}
