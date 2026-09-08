import 'package:event_app/theme/app_theme.dart';
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
  testWidgets('prikazuje naziv događaja', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EventTitle(title: 'Svadba - Jelena')));

    expect(find.text('Svadba - Jelena'), findsOneWidget);
    expect(find.text('Događaj'), findsOneWidget);
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
}
