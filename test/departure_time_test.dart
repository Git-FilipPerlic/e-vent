import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/departure_time.dart';
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

  test('trajanje puta se piše kratko', () {
    expect(DepartureTime.formatTravel(45), '45 min');
    expect(DepartureTime.formatTravel(60), '1 h');
    expect(DepartureTime.formatTravel(75), '1 h 15 min');
  });

  testWidgets('prikazuje vreme polaska i trajanje puta',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        DepartureTime(
          departure: DateTime(2026, 9, 12, 14, 30),
          travelMinutes: 45,
        ),
      ),
    );

    expect(find.text('Vreme polaska'), findsOneWidget);
    expect(find.text('14:30'), findsOneWidget);
    expect(find.text('Put traje oko 45 min'), findsOneWidget);
  });

  testWidgets('bez trajanja puta prikazuje samo vreme',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(DepartureTime(departure: DateTime(2026, 9, 12, 14, 30))),
    );

    expect(find.text('14:30'), findsOneWidget);
    expect(find.textContaining('Put traje'), findsNothing);
  });

  testWidgets('kad vremena polaska nema prikazuje objašnjenje',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(const DepartureTime(departure: null, travelMinutes: 45)),
    );

    expect(find.text('Vreme polaska nije uneto'), findsOneWidget);
    expect(find.textContaining('Put traje'), findsNothing);
  });
}
