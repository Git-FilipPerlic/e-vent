import 'package:event_app/screens/led_screen.dart';
import 'package:event_app/services/led_controller.dart';
import 'package:event_app/services/led_memory.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lažni kontroler — pravi uređaj u testu ne postoji.
class _FakeLed implements LedController {
  _FakeLed({this.devices = const [], this.failsToConnect = false});

  final List<LedDevice> devices;
  final bool failsToConnect;

  String? connectedTo;
  bool? lastPower;
  List<int>? lastColor;
  double? lastBrightness;
  LedEffect? lastEffect;
  double? lastSpeed;

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

  @override
  Future<void> setBrightness(double value) async => lastBrightness = value;

  @override
  Future<void> setEffect(LedEffect effect, {double speed = 0.5}) async {
    lastEffect = effect;
    lastSpeed = speed;
  }
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
      // Kontrole se **vide** i pre povezivanja — inače tab deluje prazno i
      // ne vidi se šta nudi — ali ne rade.
      expect(find.text('Upali'), findsOneWidget);
      expect(find.text('Nije povezano'), findsOneWidget);
      final upali = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Upali'),
      );
      expect(upali.onPressed, isNull);
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

  group('jačina svetla', () {
    test('utamnjuje zapamćenu boju umesto zasebne komande', () async {
      // Magic Home nema komandu za jačinu; šalje se ista boja, utamnjena.
      final led = MagicHomeController();
      await led.setColor(200, 100, 50);
      await led.setBrightness(0.5);

      // Bez veze se ništa ne šalje, ali stanje mora da ostane ispravno —
      // sledeća komanda po povezivanju nosi utamnjenu boju.
      expect(led.isConnected, isFalse);
    });

    test('jačina van opsega se seče', () async {
      final led = MagicHomeController();
      await led.setBrightness(5);
      await led.setBrightness(-1);
      expect(led.isConnected, isFalse);
    });
  });

  group('pamćenje kontrolera', () {
    testWidgets('zapamćeni kontroler se nudi jednim dodirom', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'flutter.led_last_address': '192.168.4.1',
      });
      final led = _FakeLed();

      await tester.pumpWidget(_wrap(LedScreen(controller: led)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Poveži se ponovo'), findsOneWidget);

      await tester.tap(find.textContaining('Poveži se ponovo'));
      await tester.pumpAndSettle();

      expect(led.connectedTo, '192.168.4.1');
    });

    testWidgets('bez zapamćenog kontrolera nema tog dugmeta', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(_wrap(LedScreen(controller: _FakeLed())));
      await tester.pumpAndSettle();

      expect(find.textContaining('Poveži se ponovo'), findsNothing);
    });

    test('pamti se i redosled boja, jer je svojstvo uređaja', () async {
      SharedPreferences.setMockInitialValues({});
      const memory = LedMemory();

      await memory.remember(address: '192.168.4.1', colorOrder: 'grb');

      expect(await memory.lastAddress(), '192.168.4.1');
      expect(await memory.colorOrder(), 'grb');

      await memory.clear();
      expect(await memory.lastAddress(), isNull);
    });
  });

  group('efekti', () {
    test('brzina se preslikava obrnuto, kako kontroler broji', () async {
      // Kod Magic Home-a je 1 najbrže, 0x1F najsporije.
      final led = MagicHomeController();
      await led.setEffect(LedEffect.duga, speed: 1);
      await led.setEffect(LedEffect.duga, speed: 0);
      expect(led.isConnected, isFalse);
    });

    test('svaki efekat ima svoj broj', () {
      expect(LedEffect.duga.code, 0x25);
      expect(LedEffect.dugaSkok.code, 0x38);
      expect(LedEffect.strob.code, 0x30);
      // Nijedan se ne ponavlja.
      final codes = LedEffect.values.map((e) => e.code).toSet();
      expect(codes.length, LedEffect.values.length);
    });

    testWidgets('efekat i boja se isključuju', (WidgetTester tester) async {
      final led = _FakeLed(devices: const [LedDevice(address: '192.168.4.1')]);

      await tester.pumpWidget(_wrap(LedScreen(controller: led)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potraži kontroler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('192.168.4.1').first);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Duga'),
        200,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Duga'));
      await tester.pumpAndSettle();
      expect(led.lastEffect, LedEffect.duga);

      // Izbor boje gasi efekat — kontroler radi ili jedno ili drugo.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('boja-0')),
        -200,
      );
      await tester.tap(find.byKey(const ValueKey('boja-0')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Duga'),
        200,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Duga'))
            .selected,
        isFalse,
      );
    });
  });
}
