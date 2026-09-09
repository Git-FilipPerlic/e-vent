import 'package:event_app/models/checklist.dart';
import 'package:event_app/screens/lager_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/lager/checklist_progress.dart';
import 'package:event_app/widgets/lager/checklist_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

const ChecklistSection _tehnika = ChecklistSection(
  id: 'tehnika',
  name: 'Tehnika',
  items: [
    ChecklistItem(id: 'zvucnik', name: 'Zvučnik'),
    ChecklistItem(id: 'mikrofon', name: 'Mikrofon'),
  ],
);

void main() {
  group('traka napretka', () {
    testWidgets('pokazuje odnos čekiranog i ukupnog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const ChecklistProgress(checked: 3, total: 8, label: 'Spakovano'),
        ),
      );

      expect(find.text('3/8'), findsOneWidget);
      expect(find.text('Spakovano'), findsOneWidget);
    });

    testWidgets('prazna lista ne deli nulom', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const ChecklistProgress(checked: 0, total: 0, label: 'Spakovano'),
        ),
      );

      expect(find.text('0/0'), findsOneWidget);
    });
  });

  group('sekcija', () {
    testWidgets('zatvorena pokazuje naziv i brojač, bez stavki',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          ChecklistSectionTile(
            section: _tehnika,
            checkedIds: const {'zvucnik'},
            addedItemIds: const {},
            isExpanded: false,
            canEditItems: true,
            onToggleExpanded: () {},
            onToggleItem: (_) {},
            onAddItem: (_) {},
            onRemoveItem: (_) {},
          ),
        ),
      );

      expect(find.text('Tehnika'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Zvučnik'), findsNothing);
    });

    testWidgets('otvorena pokazuje stavke i dugme za dodavanje',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          ChecklistSectionTile(
            section: _tehnika,
            checkedIds: const {},
            addedItemIds: const {},
            isExpanded: true,
            canEditItems: true,
            onToggleExpanded: () {},
            onToggleItem: (_) {},
            onAddItem: (_) {},
            onRemoveItem: (_) {},
          ),
        ),
      );

      expect(find.text('Zvučnik'), findsOneWidget);
      expect(find.text('Mikrofon'), findsOneWidget);
      expect(find.text('Dodaj stavku'), findsOneWidget);
    });

    testWidgets('dodir na stavku javlja koja je stavka',
        (WidgetTester tester) async {
      String? toggled;
      await tester.pumpWidget(
        _wrap(
          ChecklistSectionTile(
            section: _tehnika,
            checkedIds: const {},
            addedItemIds: const {},
            isExpanded: true,
            canEditItems: true,
            onToggleExpanded: () {},
            onToggleItem: (id) => toggled = id,
            onAddItem: (_) {},
            onRemoveItem: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Mikrofon'));
      await tester.pump();

      expect(toggled, 'mikrofon');
    });

    testWidgets('samo dodate stavke mogu da se obrišu',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          ChecklistSectionTile(
            section: _tehnika,
            checkedIds: const {},
            addedItemIds: const {'mikrofon'},
            isExpanded: true,
            canEditItems: true,
            onToggleExpanded: () {},
            onToggleItem: (_) {},
            onAddItem: (_) {},
            onRemoveItem: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('prazna stavka se ne dodaje', (WidgetTester tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          ChecklistSectionTile(
            section: _tehnika,
            checkedIds: const {},
            addedItemIds: const {},
            isExpanded: true,
            canEditItems: true,
            onToggleExpanded: () {},
            onToggleItem: (_) {},
            onAddItem: (_) => calls++,
            onRemoveItem: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Dodaj stavku'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Dodaj'));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });

  group('Lager ekran', () {
    testWidgets('učita sve sekcije i drži ih zatvorene',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LagerScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tehnika'), findsOneWidget);
      expect(find.text('Animacija'), findsOneWidget);
      expect(find.text('Pakovanje'), findsOneWidget);
      expect(find.text('Raspakivanje'), findsOneWidget);
      // Zatvorene sekcije ne prikazuju dugme za dodavanje.
      expect(find.text('Dodaj stavku'), findsNothing);
    });

    testWidgets('pakovanje i raspakivanje imaju odvojene kvačice',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LagerScreen()));
      await tester.pumpAndSettle();

      // Otvori prvu sekciju i čekiraj prvu stavku.
      await tester.tap(find.text('Tehnika'));
      await tester.pumpAndSettle();

      final firstBox = find.byIcon(Icons.check_box_outline_blank_rounded).first;
      await tester.tap(firstBox);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_box_rounded), findsWidgets);

      // Prebacivanje na raspakivanje počinje od nule.
      await tester.tap(find.text('Raspakivanje'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_rounded), findsNothing);
    });

    testWidgets('dodata stavka ulazi u sekciju i u brojač',
        (WidgetTester tester) async {
      // Dodavanje menja katalog firme, pa traži prijavljenog managera.
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(LagerScreen(auth: auth)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tehnika'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dodaj stavku'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Rezervni kabl');
      await tester.tap(find.text('Dodaj'));
      await tester.pumpAndSettle();

      expect(find.text('Rezervni kabl'), findsOneWidget);
      // I može da se obriše, jer ju je korisnik dodao.
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Upis u katalog ide u pozadini; sačekaj ga da test ne ostavi tajmer.
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
