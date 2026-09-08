import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/event_address.dart';
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
  testWidgets('bez koordinata prikazuje adresu i navigaciju, ali bez mape',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(const EventAddress(address: 'Kisačka 78, Novi Sad')),
    );

    expect(find.text('Adresa'), findsOneWidget);
    expect(find.text('Kisačka 78'), findsOneWidget);
    expect(find.text('Navigacija'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('kad adrese nema prikazuje objašnjenje i nema dugmadi',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EventAddress(address: null)));

    expect(find.text('Adresa nije uneta'), findsOneWidget);
    expect(find.text('Navigacija'), findsNothing);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
  });

  testWidgets('prazan tekst se tretira kao da adrese nema',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const EventAddress(address: '   ')));

    expect(find.text('Adresa nije uneta'), findsOneWidget);
  });

  testWidgets('navigacija sa koordinatama vodi na tačnu tačku',
      (WidgetTester tester) async {
    final launched = _captureLaunches(tester);
    await tester.pumpWidget(
      _wrap(
        const EventAddress(
          address: 'Bulevar Oslobođenja 45, Novi Sad',
          latitude: 45.2671,
          longitude: 19.8335,
        ),
      ),
    );

    await tester.tap(find.text('Navigacija'));
    await tester.pump();

    expect(launched, [
      'https://www.google.com/maps/dir/?api=1&destination=45.2671%2C19.8335',
    ]);
  });

  testWidgets('bez koordinata navigacija ide po tekstu adrese',
      (WidgetTester tester) async {
    final launched = _captureLaunches(tester);
    await tester.pumpWidget(
      _wrap(const EventAddress(address: 'Kisačka 78, Novi Sad')),
    );

    await tester.tap(find.text('Navigacija'));
    await tester.pump();

    expect(launched.single, contains('destination=Kisa'));
  });

  testWidgets('kad telefon ne može da otvori mapu, javi poruku',
      (WidgetTester tester) async {
    _captureLaunches(tester, succeeds: false);
    await tester.pumpWidget(
      _wrap(const EventAddress(address: 'Kisačka 78, Novi Sad')),
    );

    await tester.tap(find.text('Navigacija'));
    // Prvi pump pusti da se odgovor telefona vrati,
    // drugi odigra ulazak poruke pri dnu ekrana.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('Navigacija nije moguća na ovom uređaju.'),
      findsOneWidget,
    );
  });

  test('grad se izvlači iz adrese, sa velikim početnim slovom', () {
    expect(
      EventAddress.cityFrom('Bulevar Oslobođenja 45, Novi Sad'),
      'Novi Sad',
    );
    // Adresa bez zareza nema izdvojen grad.
    expect(EventAddress.cityFrom('Kisačka 78'), isNull);
    expect(EventAddress.cityFrom('Kisačka 78,   '), isNull);
  });

  test('ulica se piše bez grada, jer grad stoji u redu iznad', () {
    expect(
      EventAddress.streetFrom('Bulevar Oslobođenja 45, Novi Sad'),
      'Bulevar Oslobođenja 45',
    );
    // Bez zareza nema šta da se skida.
    expect(EventAddress.streetFrom('Kisačka 78'), 'Kisačka 78');
  });

  testWidgets('grad stoji sitno uz naslov kartice',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(const EventAddress(address: 'Bulevar Oslobođenja 45, Novi Sad')),
    );

    expect(find.text('Novi Sad'), findsOneWidget);
    // Grad se ne ponavlja u redu sa ulicom.
    expect(find.text('Bulevar Oslobođenja 45'), findsOneWidget);
  });
}
