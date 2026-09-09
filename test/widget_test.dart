// Osnovni test skeleta: aplikacija se podiže i prebacuje između 4 taba.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_app/app.dart';
import 'package:event_app/widgets/common/top_tab_bar.dart';
import 'package:event_app/utils/date_format.dart';

void main() {
  // U pravoj aplikaciji ovo radi `main()`; test podiže `EventApp` direktno,
  // pa nazive meseci mora da učita sam.
  setUpAll(() => AppDate.init());

  testWidgets('Prikazuje 4 taba i naziv događaja na Home',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EventApp());

    expect(find.byType(TopTabBar), findsOneWidget);

    // Dok podaci stižu, na Home stoji indikator učitavanja.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Ime i trajanje su u istom redu: "7 Mia / 2h".
    expect(find.textContaining('7 Mia'), findsOneWidget);
  });

  testWidgets('Prebacivanje na Lager tab', (WidgetTester tester) async {
    await tester.pumpWidget(const EventApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lager'));
    await tester.pumpAndSettle();

    // Lager tab pokazuje checklist opreme, sa režimima pakovanja.
    expect(find.text('Pakovanje'), findsOneWidget);
    expect(find.text('Tehnika'), findsOneWidget);
  });

  testWidgets('skrolovanje nadole sklanja header i tabove, nagore ih vraća',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EventApp());
    await tester.pumpAndSettle();

    expect(find.byType(TopTabBar), findsOneWidget);

    // Povlačenje nagore = skrolovanje nadole kroz spisak.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byType(TopTabBar), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(TopTabBar), findsOneWidget);
  });
}
