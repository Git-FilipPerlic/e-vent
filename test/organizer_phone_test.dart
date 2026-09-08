import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/organizer_phone.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget se uvek testira u pravoj temi aplikacije.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

/// Presreće kanal preko koga `url_launcher` traži od telefona da nešto otvori.
/// Vraća listu adresa koje su stigle, pa test vidi šta bi se zaista pozvalo.
List<String> _captureLaunches(WidgetTester tester, {bool succeeds = true}) {
  final launched = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (MethodCall call) async {
      if (call.method == 'launch') {
        launched.add((call.arguments as Map)['url'] as String);
      }
      return succeeds;
    },
  );
  return launched;
}

void main() {
  testWidgets('prikazuje broj i sve tri akcije', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const OrganizerPhone(phone: '+381641234567')));

    expect(find.text('Telefon organizatora'), findsOneWidget);
    expect(find.text('+381641234567'), findsOneWidget);
    expect(find.text('Pozovi'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('kad broja nema prikazuje objašnjenje i nema dugmadi',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const OrganizerPhone(phone: null)));

    expect(find.text('Telefon nije unet'), findsOneWidget);
    expect(find.text('Pozovi'), findsNothing);
    expect(find.text('SMS'), findsNothing);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
  });

  testWidgets('prazan tekst se tretira kao da broja nema',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const OrganizerPhone(phone: '   ')));

    expect(find.text('Telefon nije unet'), findsOneWidget);
  });

  testWidgets('poziv ide na broj bez razmaka i crtica',
      (WidgetTester tester) async {
    final launched = _captureLaunches(tester);
    await tester.pumpWidget(
      _wrap(const OrganizerPhone(phone: '+381 64 123-4567')),
    );

    await tester.tap(find.text('Pozovi'));
    await tester.pump();

    expect(launched, ['tel:+381641234567']);
  });

  testWidgets('SMS ide na isti, očišćen broj', (WidgetTester tester) async {
    final launched = _captureLaunches(tester);
    await tester.pumpWidget(
      _wrap(const OrganizerPhone(phone: '(021) 555 111')),
    );

    await tester.tap(find.text('SMS'));
    await tester.pump();

    expect(launched, ['sms:021555111']);
  });

  testWidgets('kad telefon ne može da otvori poziv, javi poruku',
      (WidgetTester tester) async {
    _captureLaunches(tester, succeeds: false);
    await tester.pumpWidget(_wrap(const OrganizerPhone(phone: '+381641234567')));

    await tester.tap(find.text('Pozovi'));
    // Prvi pump pusti da se odgovor telefona vrati,
    // drugi odigra ulazak poruke pri dnu ekrana.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Pozivanje nije moguće na ovom uređaju.'), findsOneWidget);
  });
}
