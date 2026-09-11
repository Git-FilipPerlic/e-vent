// Zlatni listići na dodir (proba): dodir i dalje stiže do dugmeta ispod,
// listići padnu i sat stane, a uz smanjen pokret ih uopšte nema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_app/widgets/common/gold_burst.dart';

Widget _app(VoidCallback onTap) => MaterialApp(
  builder: (context, child) => GoldBurst(child: child!),
  home: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: const SizedBox.expand(),
  ),
);

void main() {
  testWidgets('dodir stiže do sadržaja ispod, a listići padnu i stanu', (
    WidgetTester tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_app(() => taps++));

    await tester.tap(find.byType(GestureDetector));
    await tester.pump(const Duration(milliseconds: 16));

    expect(taps, 1);
    expect(tester.hasRunningAnimations, isTrue);

    // Kad padnu, sat se ugasi — `pumpAndSettle` bi inače visio.
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('prevlačenje ostavlja trag koji se takođe smiri', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(() {}));

    await tester.drag(find.byType(GestureDetector), const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('uz smanjen pokret nema listića', (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    var taps = 0;
    await tester.pumpWidget(_app(() => taps++));

    await tester.tap(find.byType(GestureDetector));
    await tester.pump(const Duration(milliseconds: 16));

    expect(taps, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
