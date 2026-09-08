import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/event_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget se uvek testira u pravoj temi aplikacije.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() => AppDate.init());

  test('trajanje se prepoznaje po slovu h', () {
    expect(AppDate.shortDuration(45), '45min');
    expect(AppDate.shortDuration(60), '1h');
    expect(AppDate.shortDuration(90), '1h30');
    expect(AppDate.shortDuration(120), '2h');
  });

  testWidgets('datum, sat, naziv i trajanje stoje u dva reda',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        EventTitle(
          title: '7 Mia',
          date: DateTime(2026, 9, 12, 16, 0),
          durationMinutes: 120,
        ),
      ),
    );

    expect(find.text('Događaj'), findsOneWidget);
    expect(find.text('12. septembar'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
    expect(find.text('7 Mia'), findsOneWidget);
    expect(find.text('2h'), findsOneWidget);
    // Godina se ne piše.
    expect(find.textContaining('2026'), findsNothing);
  });

  testWidgets('kad naziva nema prikazuje objašnjenje, ne prazno mesto',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EventTitle(title: null)));

    expect(find.text('Naziv događaja nije unet'), findsOneWidget);
  });

  testWidgets('prazan tekst se tretira kao da naziva nema',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EventTitle(title: '   ')));

    expect(find.text('Naziv događaja nije unet'), findsOneWidget);
  });

  testWidgets('bez datuma i trajanja kartica i dalje radi',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EventTitle(title: '7 Mia')));

    expect(find.text('Datum nije unet'), findsOneWidget);
    expect(find.text('7 Mia'), findsOneWidget);
    expect(find.textContaining('h'), findsNothing);
  });
}
