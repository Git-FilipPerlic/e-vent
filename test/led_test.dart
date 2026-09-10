import 'package:event_app/screens/led_screen.dart';
import 'package:event_app/services/led_controller.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lažni kontroler — pravi uređaj u testu ne postoji.
class _FakeLed implements LedController {
  _FakeLed({this.devices = const [], this.failsToConnect = false});

  final List<LedDevice> devices;
  final bool failsToConnect;

  String? connectedTo;
  bool? lastPower;
  List<int>? lastColor;

  @override
  bool get isConnected => connectedTo != null;

  @override
  Future<List<LedDevice>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async => devices;

  @override
  Future<void> connect(String address) async {
    if (failsToConnect) throw LedConnectionException(address);
    connectedTo = address;
  }

  @override
  Future<void> disconnect() async => connectedTo = null;

  @override
  Future<void> setPower(bool on) async => lastPower = on;

  @override
  Future<void> setColor(int red, int green, int blue) async =>
      lastColor = [red, green, blue];
}

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

void main() {
  group('Magic Home protokol', () {
    test('kontrolni bajt je zbir prethodnih po modulu 256', () {
      // Bez ovog bajta kontroler poruku tiho odbaci.
      expect(
        MagicHomeController.withChecksum([0x71, 0x23, 0x0F]),
        [0x71, 0x23, 0x0F, 0xA3],
      );
      // Prelivanje preko 255 se seče.
      expect(MagicHomeController.withChecksum([0xFF, 0xFF]), [
        0xFF,
        0xFF,
        0xFE,
      ]);
    });

    test('redosled boja preslaže bajtove', () {
      const red = 10;
      const green = 20;
      const blue = 30;

      expect(ColorOrder.rgb.arrange(red, green, blue), [10, 20, 30]);
      expect(ColorOrder.grb.arrange(red, green, blue), [20, 10, 30]);
      expect(ColorOrder.brg.arrange(red, green, blue), [30, 10, 20]);
    });

    test('uređaj bez modela se ispisuje adresom', () {
      const withModel = LedDevice(address: '192.168.4.1', model: 'HF-LPB100');
      const without = LedDevice(address: '192.168.4.1');

      expect(withModel.label, 'HF-LPB100');
      expect(without.label, '192.168.4.1');
      expect(const LedDevice(address: '1.2.3.4', model: '  ').label, '1.2.3.4');
    });

    test('portovi i poruka za pronalaženje su oni koje Magic Home očekuje', () {
      expect(MagicHomeController.commandPort, 5577);
      expect(MagicHomeController.discoveryPort, 48899);
      expect(MagicHomeController.discoveryMessage, 'HF-A11ASSISTHREAD');
    });
  });

  group('LED ekran', () {
    testWidgets('nudi traženje i ručni unos dok nije povezan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(LedScreen(controller: _FakeLed())));
      await tester.pumpAndSettle();

      expect(find.text('Potraži kontroler'), findsOneWidget);
      expect(find.text('Unesi adresu ručno'), findsOneWidget);
      // Dok nema veze, kontrola bojom se i ne nudi.
      expect(find.text('Upali'), findsNothing);
    });

    testWidgets('kad ništa nije nađeno, kaže se šta da se proveri', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(LedScreen(controller: _FakeLed())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Potraži kontroler'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Wi-Fi mreži kontrolera'), findsOneWidget);
    });

    testWidgets('nađen kontroler se prikazuje i otvara vezu', (
      WidgetTester tester,
    ) async {
      final led = _FakeLed(
        devices: const [
          LedDevice(address: '192.168.4.1', model: 'HF-LPB100'),
        ],
      );

      await tester.pumpWidget(_wrap(LedScreen(controller: led)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potraži kontroler'));
      await tester.pumpAndSettle();

      expect(find.text('HF-LPB100'), findsOneWidget);

      await tester.tap(find.text('HF-LPB100'));
      await tester.pumpAndSettle();

      expect(led.connectedTo, '192.168.4.1');
      expect(find.textContaining('Povezano'), findsOneWidget);
    });

    testWidgets('kontroler koji se ne javlja daje jasnu poruku', (
      WidgetTester tester,
    ) async {
      final led = _FakeLed(
        devices: const [LedDevice(address: '192.168.4.1')],
        failsToConnect: true,
      );

      await tester.pumpWidget(_wrap(LedScreen(controller: led)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potraži kontroler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('192.168.4.1').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('se ne javlja'), findsOneWidget);
    });

    testWidgets('posle povezivanja pali, gasi i menja boju', (
      WidgetTester tester,
    ) async {
      final led = _FakeLed(
        devices: const [LedDevice(address: '192.168.4.1')],
      );

      await tester.pumpWidget(_wrap(LedScreen(controller: led)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potraži kontroler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('192.168.4.1').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upali'));
      await tester.pumpAndSettle();
      expect(led.lastPower, isTrue);

      await tester.tap(find.text('Ugasi'));
      await tester.pumpAndSettle();
      expect(led.lastPower, isFalse);

      // Prva boja u paleti je čisto crvena.
      await tester.tap(find.byKey(const ValueKey('boja-0')));
      await tester.pumpAndSettle();
      expect(led.lastColor, [255, 0, 0]);
    });
  });
}
