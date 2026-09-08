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
}
