// Osnovni test skeleta: aplikacija se otvara spiskom događaja, izbor
// događaja otvara 4 taba, strelica nazad vraća na spisak.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_app/app.dart';
import 'package:event_app/widgets/common/edit_text_sheet.dart';
import 'package:event_app/widgets/common/top_tab_bar.dart';
import 'package:event_app/utils/date_format.dart';

/// Podiže aplikaciju i otvara prvi događaj sa spiska.
Future<void> _openFirstEvent(WidgetTester tester) async {
  await tester.pumpWidget(const EventApp());
  await tester.pumpAndSettle();

  await tester.tap(find.text('7 Mia'));
  await tester.pumpAndSettle();
}

void main() {
  // U pravoj aplikaciji ovo radi `main()`; test podiže `EventApp` direktno,
  // pa nazive meseci mora da učita sam.
  setUpAll(() => AppDate.init());

  testWidgets('otvara se spiskom događaja, bez tabova', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EventApp());

    // Dok spisak stiže, stoji indikator učitavanja.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Tabovi pripadaju jednom događaju, a nijedan još nije otvoren.
    expect(find.byType(TopTabBar), findsNothing);
    expect(find.text('7 Mia'), findsOneWidget);
  });

  testWidgets('izbor događaja otvara 4 taba sa njegovim podacima', (
    WidgetTester tester,
  ) async {
    await _openFirstEvent(tester);

    expect(find.byType(TopTabBar), findsOneWidget);
    // Ime i trajanje su u istom redu: "7 Mia / 2h".
    expect(find.textContaining('7 Mia'), findsOneWidget);
  });

  testWidgets('strelica nazad vraća na spisak', (WidgetTester tester) async {
    await _openFirstEvent(tester);

    await tester.tap(find.byTooltip('Nazad na spisak događaja'));
    await tester.pumpAndSettle();

    expect(find.byType(TopTabBar), findsNothing);
    // Spisak je i dalje tu, sa svojim grupama.
    expect(find.text('7 Mia'), findsOneWidget);
  });

  testWidgets('Prebacivanje na Lager tab', (WidgetTester tester) async {
    await _openFirstEvent(tester);

    await tester.tap(find.text('Lager'));
    await tester.pumpAndSettle();

    // Lager tab pokazuje checklist opreme, sa režimima pakovanja.
    expect(find.text('Pakovanje'), findsOneWidget);
    expect(find.text('Tehnika'), findsOneWidget);
  });

  testWidgets('skrolovanje nadole sklanja header i tabove, nagore ih vraća', (
    WidgetTester tester,
  ) async {
    await _openFirstEvent(tester);

    expect(find.byType(TopTabBar), findsOneWidget);

    // Povlačenje nagore = skrolovanje nadole kroz spisak.
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byType(TopTabBar), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(TopTabBar), findsOneWidget);
  });

  testWidgets('izmena datuma se vidi na spisku po povratku', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EventApp());
    await tester.pumpAndSettle();

    // Prijava, da bi olovke uopšte postojale.
    await tester.tap(find.byTooltip('Prijava'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Filip');
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 Mia'));
    await tester.pumpAndSettle();

    // Trajanje sa 2h na 3h.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is EditFieldButton && w.label == 'Datum, sat i trajanje',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '3h'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sačuvaj'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nazad na spisak događaja'));
    await tester.pumpAndSettle();

    // Spisak stoji u stablu sve vreme, pa mora da se osveži sam. Rođendan je
    // sada 3h, kao i svadba — otud dva.
    expect(find.text('2h'), findsNothing);
    expect(find.text('3h'), findsNWidgets(2));
  });

}
