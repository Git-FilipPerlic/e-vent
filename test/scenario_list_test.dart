import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/scenario_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

const List<ScenarioPoint> _fromDatabase = [
  ScenarioPoint('Doček gostiju'),
  ScenarioPoint('Igre za decu'),
  ScenarioPoint('Završni plesni program'),
];

ScenarioList _list(
  List<ScenarioPoint> points, {
  ValueChanged<String>? onAdd,
  ValueChanged<int>? onRemove,
  void Function(int from, int to)? onReorder,
}) {
  return ScenarioList(
    points: points,
    onAdd: onAdd ?? (_) {},
    onRemove: onRemove ?? (_) {},
    onReorder: onReorder ?? (_, _) {},
  );
}

void main() {
  testWidgets('prikazuje tačke iz baze, numerisane redom',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_list(_fromDatabase)));

    expect(find.text('Doček gostiju'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('dodate tačke nastavljaju numeraciju',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        _list(const [..._fromDatabase, ScenarioPoint('Bis', isAdded: true)]),
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
        _list(
          const [
            ScenarioPoint('Doček gostiju'),
            ScenarioPoint('Bis', isAdded: true),
            ScenarioPoint('Igre za decu'),
          ],
          onRemove: (index) => removedIndex = index,
        ),
      ),
    );

    // Samo dodata tačka ima dugme za brisanje.
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    // Broj je mesto u celom spisku, ne među dodatim.
    expect(removedIndex, 1);
  });

  testWidgets('svaka tačka ima ručicu za premeštanje',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        _list(const [..._fromDatabase, ScenarioPoint('Bis', isAdded: true)]),
      ),
    );

    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(4));
  });

  testWidgets('prevlačenje za ručicu javlja novo mesto tačke',
      (WidgetTester tester) async {
    int? from;
    int? to;
    await tester.pumpWidget(
      _wrap(
        _list(
          _fromDatabase,
          onReorder: (f, t) {
            from = f;
            to = t;
          },
        ),
      ),
    );

    // Prva tačka se spušta ispod poslednje.
    final handle = find.byIcon(Icons.drag_indicator_rounded).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(from, 0);
    expect(to, 2);
  });

  testWidgets('prazan scenario ima svoje objašnjenje',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_list(const [])));

    expect(find.text('Scenario nije unet'), findsOneWidget);
    expect(find.text('Dodaj tačku'), findsOneWidget);
  });

  testWidgets('nova tačka se javlja ekranu bez viška razmaka',
      (WidgetTester tester) async {
    String? added;
    await tester.pumpWidget(
      _wrap(_list(_fromDatabase, onAdd: (text) => added = text)),
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
      _wrap(_list(_fromDatabase, onAdd: (_) => calls++)),
    );

    await tester.tap(find.text('Dodaj tačku'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });
}
