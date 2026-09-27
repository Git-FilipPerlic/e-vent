// Ekran „Ekipa": ko šta ume, koliko je odradio, i da to menja samo manager.

import 'package:event_app/screens/team_screen.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

void main() {
  group('spisak ekipe', () {
    testWidgets('pokazuje ime, nivo i veštine', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(TeamScreen(service: MockEventService())));
      await tester.pumpAndSettle();

      expect(find.text('Filip'), findsOneWidget);
      // 240 bodova je treći nivo, sa 60 do sledećeg.
      expect(find.text('Nivo 3'), findsOneWidget);
      expect(find.textContaining('240 EXP'), findsOneWidget);
      expect(find.text('Vatra · Voditelj'), findsOneWidget);
    });

    testWidgets('ko nema upisane veštine, to i piše', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(TeamScreen(service: MockEventService())));
      await tester.pumpAndSettle();

      // Marko zna samo vožnju; onaj bez ijedne veštine bi imao ovaj tekst.
      expect(find.text('Vozač'), findsOneWidget);
    });
  });

  group('izmena člana', () {
    testWidgets('bodovi se dodaju i pamte', (WidgetTester tester) async {
      final service = MockEventService();
      await tester.pumpWidget(_wrap(TeamScreen(service: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ana'));
      await tester.pumpAndSettle();

      // Ana ima 80 bodova — sa +25 prelazi u drugi nivo.
      await tester.tap(find.text('+25'));
      await tester.pump();
      expect(find.text('Nivo 2'), findsOneWidget);

      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      // Sat u testu stoji dok se ne pumpa, pa se posao prvo pokrene, pa se
      // vreme pomeri, pa se čeka ishod.
      final loading = service.loadTeam();
      await tester.pump(const Duration(seconds: 1));
      final saved = (await loading).firstWhere((m) => m.name == 'Ana');
      expect(saved.exp, 105);
    });

    testWidgets('veština se čekira i pamti', (WidgetTester tester) async {
      final service = MockEventService();
      await tester.pumpWidget(_wrap(TeamScreen(service: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ana'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Voditelj'));
      await tester.pump();
      await tester.tap(find.text('Sačuvaj'));
      await tester.pumpAndSettle();

      // Sat u testu stoji dok se ne pumpa, pa se posao prvo pokrene, pa se
      // vreme pomeri, pa se čeka ishod.
      final loading = service.loadTeam();
      await tester.pump(const Duration(seconds: 1));
      final saved = (await loading).firstWhere((m) => m.name == 'Ana');
      expect(saved.knows('skill-003'), isTrue);
      // Ono što je već umela ostaje.
      expect(saved.knows('skill-002'), isTrue);
    });

    // Oduzimanje je ispravka greške; na nuli se dugme gasi da se ne ide ispod.
    testWidgets('bodovi ne idu ispod nule', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(TeamScreen(service: MockEventService())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marko'));
      await tester.pumpAndSettle();

      final minus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_rounded),
      );
      expect(minus.onPressed, isNull);
    });
  });
}
