import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/event_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  // Nazivi meseci se učitavaju jednom, isto kao u `main()`.
  setUpAll(() => AppDate.init());

  test('datum se ispisuje latinicom, na srpskom', () {
    expect(AppDate.long(DateTime(2026, 9, 12)), '12. septembar 2026.');
    expect(AppDate.weekday(DateTime(2026, 9, 12)), 'subota');
    expect(AppDate.time(DateTime(2026, 9, 12, 14, 30)), '14:30');
  });

  testWidgets('prikazuje datum događaja', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(EventDate(date: DateTime(2026, 9, 12))));

    expect(find.text('Datum događaja'), findsOneWidget);
    expect(find.text('12. septembar 2026.'), findsOneWidget);
  });

  testWidgets('kad datuma nema prikazuje objašnjenje',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EventDate(date: null)));

    expect(find.text('Datum nije unet'), findsOneWidget);
  });

  testWidgets('prikazuje sat početka krupno i osenči ga u traci',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(EventDate(date: DateTime(2026, 9, 12, 16, 0))),
    );
    // Traka se sama pomera na izabrani sat tek posle prvog kadra.
    await tester.pumpAndSettle();

    expect(find.text('16:00'), findsOneWidget);
    expect(find.text('Sat početka'), findsOneWidget);
    // Traka ima svih 24 časa, ali su iscrtani samo vidljivi.
    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('bez dozvole se sat ne menja dodirom',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(EventDate(date: DateTime(2026, 9, 12, 16, 0))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    // Krupna brojka je i dalje 16:00 — dodir ništa ne menja.
    expect(find.text('16:00'), findsOneWidget);
  });

  testWidgets('u admin konzoli dodir menja sat i javlja ga',
      (WidgetTester tester) async {
    int? chosen;
    await tester.pumpWidget(
      _wrap(
        EventDate(
          date: DateTime(2026, 9, 12, 16, 0),
          onHourSelected: (hour) => chosen = hour,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    expect(chosen, 15);
    expect(find.text('15:00'), findsOneWidget);
  });
}
