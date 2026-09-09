import 'package:event_app/models/checklist.dart';
import 'package:event_app/screens/lager_screen.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/event_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));
}

const List<ChecklistSection> _catalog = [
  ChecklistSection(
    id: 'sec-vatra',
    name: 'Vatra',
    items: [
      ChecklistItem(id: 'v1', name: 'Vatrene lopte'),
      ChecklistItem(id: 'v2', name: 'Gorivo'),
    ],
  ),
  ChecklistSection(
    id: 'sec-led',
    name: 'LED',
    items: [ChecklistItem(id: 'l1', name: 'LED trake')],
  ),
  ChecklistSection(
    id: 'sec-ring',
    name: 'Ring',
    items: [ChecklistItem(id: 'r1', name: 'Hoop')],
  ),
];

void main() {
  group('kategorije na Home tabu', () {
    testWidgets('prikazuje izabrane kategorije i broj delova',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const EventCategories(
            catalog: _catalog,
            selectedIds: ['sec-vatra', 'sec-led'],
          ),
        ),
      );

      expect(find.text('Vatra · 2'), findsOneWidget);
      expect(find.text('LED · 1'), findsOneWidget);
      // Ono što nije izabrano se ne prikazuje.
      expect(find.text('Ring · 1'), findsNothing);
      // Tri dela ukupno.
      expect(find.text('Ukupno 3 delova'), findsOneWidget);
    });

    testWidgets('bez izabranih kategorija to i piše',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const EventCategories(catalog: _catalog, selectedIds: [])),
      );

      expect(find.text('Nijedna kategorija nije izabrana'), findsOneWidget);
    });

    testWidgets('bez dozvole nema olovke', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const EventCategories(
            catalog: _catalog,
            selectedIds: ['sec-vatra'],
          ),
        ),
      );

      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });
  });

  group('Lager prikazuje samo izabrane kategorije', () {
    testWidgets('evt-001 nosi tehniku i animaciju, ne i vatru',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LagerScreen(eventId: 'evt-001')));
      await tester.pumpAndSettle();

      expect(find.text('Tehnika'), findsOneWidget);
      expect(find.text('Animacija'), findsOneWidget);
      // Vatra nije izabrana za rođendan.
      expect(find.text('Vatreni rekviziti'), findsNothing);
    });

    testWidgets('evt-003 nosi sve kategorije', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LagerScreen(eventId: 'evt-003')));
      await tester.pumpAndSettle();

      expect(find.text('Vatreni rekviziti'), findsOneWidget);
      expect(find.text('Svila'), findsOneWidget);
      expect(find.text('Hoop'), findsOneWidget);
    });

    testWidgets('događaj bez kategorija objasni zašto je prazno',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const LagerScreen(eventId: 'evt-004')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('nije izabrana nijedna kategorija'),
        findsOneWidget,
      );
    });
  });

  group('model', () {
    test('izabrane kategorije se pamte kao id-jevi, ne kao kopije stavki',
        () async {
      final service = MockEventService();
      final event = await service.loadEvent('evt-001');

      expect(event.categoryIds, ['sec-tehnika', 'sec-animacija']);
    });

    test('izmena kategorija se čuva', () async {
      final service = MockEventService();
      final event = await service.loadEvent('evt-001');

      await service.saveEvent(event.copyWith(categoryIds: ['sec-hoop']));
      final reloaded = await service.loadEvent('evt-001');

      expect(reloaded.categoryIds, ['sec-hoop']);
    });
  });
}
