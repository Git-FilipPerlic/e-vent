// Osnovni test skeleta: aplikacija se podiže i prebacuje između 4 taba.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_app/app.dart';

void main() {
  testWidgets('Prikazuje 4 taba i naziv događaja na Home',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EventApp());

    expect(find.byType(NavigationBar), findsOneWidget);

    // Dok podaci stižu, na Home stoji indikator učitavanja.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Rođendan - Mia (7 godina)'), findsOneWidget);
  });

  testWidgets('Prebacivanje na Lager tab', (WidgetTester tester) async {
    await tester.pumpWidget(const EventApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lager'));
    await tester.pumpAndSettle();

    expect(find.text('Lager tab'), findsOneWidget);
  });
}
