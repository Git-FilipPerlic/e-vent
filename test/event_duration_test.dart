import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/event_duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() => AppDate.init());

  test('trajanje se piše kratko', () {
    expect(EventDuration.format(45), '45 min');
    expect(EventDuration.format(60), '1 h');
    expect(EventDuration.format(90), '1 h 30 min');
    expect(EventDuration.format(120), '2 h');
  });

  testWidgets('prikazuje trajanje i izračunat kraj nastupa',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        EventDuration(minutes: 120, start: DateTime(2026, 9, 12, 16, 0)),
      ),
    );

    expect(find.text('Ugovoreno trajanje'), findsOneWidget);
    expect(find.text('2 h'), findsOneWidget);
    expect(find.text('Od 16:00 do 18:00'), findsOneWidget);
  });

  testWidgets('bez početka prikazuje samo trajanje',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(const EventDuration(minutes: 90, start: null)),
    );

    expect(find.text('1 h 30 min'), findsOneWidget);
    expect(find.textContaining('Od '), findsNothing);
  });

  testWidgets('kad trajanje nije ugovoreno to i piše',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(EventDuration(minutes: null, start: DateTime(2026, 9, 12, 16, 0))),
    );

    expect(find.text('Trajanje nije ugovoreno'), findsOneWidget);
  });
}
