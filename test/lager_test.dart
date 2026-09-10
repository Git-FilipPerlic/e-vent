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
            isExpanded: false,
            onToggleExpanded: () {},
            onToggleItem: (_) {},
          ),
        ),
      );

      expect(find.text('Tehnika'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Zvučnik'), findsNothing);
    });

    testWidgets('dodir na stavku javlja koja je stavka',
        (WidgetTester tester) async {
      String? toggled;
      await tester.pumpWidget(
        _wrap(
          ChecklistSectionTile(
            section: _tehnika,
            checkedIds: const {},
            isExpanded: true,
            onToggleExpanded: () {},
            onToggleItem: (id) => toggled = id,
          ),
        ),
      );

      await tester.tap(find.text('Mikrofon'));
      await tester.pump();

      expect(toggled, 'mikrofon');
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
  });

  group('oprema se ne unosi na pakovanju', () {
    testWidgets('nema dodavanja ni brisanja stavki', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(_wrap(LagerScreen(auth: auth)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tehnika'));
      await tester.pumpAndSettle();

      // Spisak opreme je stvar vlasnika i uređuje se u konzoli. Pred nastup
      // se ne kucaju stavke — samo se prolaze i čekiraju.
      expect(find.text('Dodaj stavku'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      // Čekiranje i dalje radi, i ne traži nikakvu dozvolu.
      expect(find.byIcon(Icons.check_box_outline_blank_rounded), findsWidgets);
    });

    testWidgets('ni izvođač bez prijave ne vidi unos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const LagerScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tehnika'));
      await tester.pumpAndSettle();

      expect(find.text('Dodaj stavku'), findsNothing);
    });
  });
}
