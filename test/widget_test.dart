// Osnovni test skeleta: aplikacija se otvara spiskom događaja, izbor
// događaja otvara 4 stranice kroz koje se prevlači, strelica nazad
// vraća na spisak.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_app/app.dart';
import 'package:event_app/widgets/common/edit_text_sheet.dart';
import 'package:event_app/screens/music_screen.dart';
import 'package:event_app/widgets/common/page_dots.dart';
import 'package:event_app/utils/date_format.dart';

/// Podiže aplikaciju i otvara prvi događaj sa spiska.
/// Prevlači ulevo zadati broj puta — jedna stranica po prevlačenju.
Future<void> _swipePages(WidgetTester tester, int times) async {
  for (var i = 0; i < times; i++) {
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }
}

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

  testWidgets('otvara se spiskom događaja, bez tačkica', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EventApp());

    // Dok spisak stiže, stoji indikator učitavanja.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Stranice pripadaju jednom događaju, a nijedan još nije otvoren.
    expect(find.byType(PageDots), findsNothing);
    expect(find.text('7 Mia'), findsOneWidget);
  });

  testWidgets('izbor događaja otvara 4 stranice sa njegovim podacima', (
    WidgetTester tester,
  ) async {
    await _openFirstEvent(tester);

    expect(find.byType(PageDots), findsOneWidget);
    // Ime i trajanje su u istom redu: "7 Mia / 2h".
    expect(find.textContaining('7 Mia'), findsOneWidget);
  });

  testWidgets('strelica nazad vraća na spisak', (WidgetTester tester) async {
    await _openFirstEvent(tester);

    await tester.tap(find.byTooltip('Nazad na spisak događaja'));
    await tester.pumpAndSettle();

    expect(find.byType(PageDots), findsNothing);
    // Spisak je i dalje tu, sa svojim grupama.
    expect(find.text('7 Mia'), findsOneWidget);
  });

  testWidgets('prevlačenjem se stiže do Lager stranice', (
    WidgetTester tester,
  ) async {
    await _openFirstEvent(tester);

    // Home · Muzika · LED · Lager — tri prevlačenja do poslednje.
    await _swipePages(tester, 3);

    // Lager stranica pokazuje checklist opreme, sa režimima pakovanja.
    expect(find.text('Pakovanje'), findsOneWidget);
    expect(find.text('Tehnika'), findsOneWidget);
  });

  // Reprodukcija pripada Muzika stranici, pa ta stranica mora da ostane u
  // stablu i kad se sa nje ode. Bez `_KeepAlivePage` bi je `PageView` uklonio
  // čim se dve stranice udalji — i muzika bi stala nasred nastupa.
  testWidgets('Muzika stranica ostaje u stablu i sa Lagera', (
    WidgetTester tester,
  ) async {
    await _openFirstEvent(tester);
    await _swipePages(tester, 3);

    expect(find.text('Pakovanje'), findsOneWidget);
    expect(find.byType(MusicScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('skrolovanje nadole sklanja header i tačkice, nagore ih vraća', (
    WidgetTester tester,
  ) async {
    await _openFirstEvent(tester);

    expect(find.byType(PageDots), findsOneWidget);

    // Povlačenje nagore = skrolovanje nadole kroz spisak.
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byType(PageDots), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(PageDots), findsOneWidget);
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
