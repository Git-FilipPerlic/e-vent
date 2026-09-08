import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/scenario_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

const List<String> _fromDatabase = [
  'Doček gostiju',
  'Igre za decu',
  'Završni plesni program',
];

void main() {
  testWidgets('prikazuje tačke iz baze, numerisane redom',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        ScenarioList(
          items: _fromDatabase,
          addedItems: const [],
          onAdd: (_) {},
          onRemoveAdded: (_) {},
        ),
      ),
    );

    expect(find.text('Doček gostiju'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('dodate tačke nastavljaju numeraciju',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        ScenarioList(
          items: _fromDatabase,
          addedItems: const ['Bis'],
          onAdd: (_) {},
          onRemoveAdded: (_) {},
        ),
      ),
    );

    expect(find.text('4.'), findsOneWidget);
    expect(find.text('Bis'), findsOneWidget);
  });

  testWidgets('tačke iz baze se ne brišu, dodate se brišu',
      (WidgetTester tester) async {
    int? removedIndex;
    await tester.pumpWidget(
      _wrap(
        ScenarioList(
          items: _fromDatabase,
          addedItems: const ['Bis'],
          onAdd: (_) {},
          onRemoveAdded: (index) => removedIndex = index,
        ),
      ),
    );

    // Samo dodata tačka ima dugme za brisanje.
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(removedIndex, 0);
  });

  testWidgets('prazan scenario ima svoje objašnjenje',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        ScenarioList(
          items: const [],
          addedItems: const [],
          onAdd: (_) {},
          onRemoveAdded: (_) {},
        ),
      ),
    );

    expect(find.text('Scenario nije unet'), findsOneWidget);
    expect(find.text('Dodaj tačku'), findsOneWidget);
  });

  testWidgets('nova tačka se javlja ekranu bez viška razmaka',
      (WidgetTester tester) async {
    String? added;
    await tester.pumpWidget(
      _wrap(
        ScenarioList(
          items: _fromDatabase,
          addedItems: const [],
          onAdd: (text) => added = text,
          onRemoveAdded: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Dodaj tačku'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Torta  ');
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    expect(added, 'Torta');
    // Polje se zatvara posle unosa.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('prazna tačka se ne prihvata', (WidgetTester tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _wrap(
        ScenarioList(
          items: _fromDatabase,
          addedItems: const [],
          onAdd: (_) => calls++,
          onRemoveAdded: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Dodaj tačku'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });
}
