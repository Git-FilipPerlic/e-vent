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

const List<String> _fromDatabase = [
  'Doček gostiju',
  'Igre za decu',
  'Završni plesni program',
];

ScenarioList _list(
  List<String> items, {
  bool canEdit = true,
  ValueChanged<String>? onAdd,
  ValueChanged<int>? onRemove,
  void Function(int from, int to)? onReorder,
}) {
  return ScenarioList(
    items: items,
    canEdit: canEdit,
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

  testWidgets('svaka tačka se briše i ima ručicu za premeštanje',
      (WidgetTester tester) async {
    int? removedIndex;
    await tester.pumpWidget(
      _wrap(_list(_fromDatabase, onRemove: (index) => removedIndex = index)),
    );

    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(3));

    await tester.tap(find.byIcon(Icons.close_rounded).at(1));
    await tester.pump();

    expect(removedIndex, 1);
  });

  testWidgets('bez prava izmene spisak se samo čita',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_list(_fromDatabase, canEdit: false)));

    expect(find.text('Doček gostiju'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('Dodaj tačku'), findsNothing);
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
