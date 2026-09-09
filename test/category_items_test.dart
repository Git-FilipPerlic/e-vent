import 'package:event_app/models/checklist.dart';
import 'package:event_app/screens/category_items_screen.dart';
import 'package:event_app/screens/lager_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/event_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ChecklistSection _vatra = ChecklistSection(
  id: 'sec-vatra',
  name: 'Vatra',
  items: [
    ChecklistItem(id: 'v1', name: 'Vatrene lopte'),
    ChecklistItem(id: 'v2', name: 'Gorivo'),
  ],
);

Widget _editor([ChecklistSection category = _vatra]) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: CategoryItemsScreen(category: category),
  );
}

void main() {
  group('izmena delova kategorije', () {
    testWidgets('prikazuje delove i upozorava da izmena važi svuda', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_editor());

      expect(find.text('Vatrene lopte'), findsOneWidget);
      expect(find.text('Gorivo'), findsOneWidget);
      expect(find.textContaining('važe za sve događaje'), findsOneWidget);
    });

    testWidgets('dodavanje dela ga prikaže u spisku', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_editor());

      await tester.tap(find.text('Dodaj deo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Baklje');
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      expect(find.text('Baklje'), findsOneWidget);
    });

    testWidgets('brisanje dela ga skloni sa spiska', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_editor());

      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Vatrene lopte'), findsNothing);
      expect(find.text('Gorivo'), findsOneWidget);
    });

    testWidgets('prazan naziv briše deo', (WidgetTester tester) async {
      await tester.pumpWidget(_editor());

      await tester.tap(find.text('Gorivo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      expect(find.text('Gorivo'), findsNothing);
      expect(find.text('Vatrene lopte'), findsOneWidget);
    });

    testWidgets('prazna kategorija to i kaže', (WidgetTester tester) async {
      await tester.pumpWidget(
        _editor(
          const ChecklistSection(id: 'sec-prazna', name: 'Prazna', items: []),
        ),
      );

      expect(find.textContaining('nema nijednog dela'), findsOneWidget);
    });
  });

  group('katalog firme', () {
    test('izmenjena kategorija se vidi na svim događajima', () async {
      final service = MockEventService();

      await service.saveCategory(
        const ChecklistSection(
          id: 'sec-tehnika',
          name: 'Tehnika',
          items: [ChecklistItem(id: 't-novo', name: 'Rezervni kabl')],
        ),
      );
      final catalog = await service.loadChecklistTemplate();
      final tehnika = catalog.firstWhere((s) => s.id == 'sec-tehnika');

      expect(tehnika.items.single.name, 'Rezervni kabl');
    });
  });

  group('dozvole za katalog', () {
    testWidgets('bez prijave se delovi ne dodaju', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: LagerScreen(eventId: 'evt-001', auth: MockAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tehnika'));
      await tester.pumpAndSettle();

      // Stavke se i dalje čekiraju, ali katalog firme ostaje netaknut.
      expect(find.text('Dodaj stavku'), findsNothing);
    });

    testWidgets('glavni sme da dodaje delove', (WidgetTester tester) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: LagerScreen(eventId: 'evt-001', auth: auth),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tehnika'));
      await tester.pumpAndSettle();

      expect(find.text('Dodaj stavku'), findsOneWidget);
    });

    testWidgets('olovka za delove se ne nudi bez dozvole', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCategoryPicker(
                context,
                catalog: const [_vatra],
                selectedIds: const [],
              ),
              child: const Text('otvori'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('otvori'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Izmeni delove'), findsNothing);
    });

    testWidgets('sa dozvolom olovka otvara delove kategorije', (
      WidgetTester tester,
    ) async {
      ChecklistSection? edited;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCategoryPicker(
                context,
                catalog: const [_vatra],
                selectedIds: const [],
                onEditItems: (section) => edited = section,
              ),
              child: const Text('otvori'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('otvori'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Izmeni delove'));
      await tester.pumpAndSettle();

      expect(edited?.id, 'sec-vatra');
    });
  });
}
