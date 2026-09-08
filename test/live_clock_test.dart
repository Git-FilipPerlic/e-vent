import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/live_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

/// Vreme kakvo sat ispisuje: `14:30:07`
final RegExp _clockText = RegExp(r'^\d{2}:\d{2}:\d{2}$');

String _shownTime(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere(_clockText.hasMatch);
}

void main() {
  setUpAll(() => AppDate.init());

  testWidgets('prikazuje vreme u obliku sat:minut:sekund',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LiveClock()));

    expect(find.text('Tačno vreme'), findsOneWidget);
    expect(_shownTime(tester), matches(_clockText));
  });

  testWidgets('vreme se osvežava dok sat stoji na ekranu',
      (WidgetTester tester) async {
    // Lažni sat: svako čitanje je sekundu kasnije. Pravo vreme se u testu
    // ne može ubrzati, pa se sat podmetne.
    var fake = DateTime(2026, 9, 12, 14, 30, 0);
    DateTime now() {
      fake = fake.add(const Duration(seconds: 1));
      return fake;
    }

    await tester.pumpWidget(_wrap(LiveClock(now: now)));
    expect(find.text('14:30:01'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('14:30:03'), findsOneWidget);
  });

  testWidgets('tajmer se gasi kad sat nestane sa ekrana',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LiveClock()));
    await tester.pumpWidget(_wrap(const SizedBox()));

    // Da tajmer nije otkazan, test bi ovde pukao porukom
    // "A Timer is still pending".
    await tester.pump(const Duration(seconds: 2));
  });
}
