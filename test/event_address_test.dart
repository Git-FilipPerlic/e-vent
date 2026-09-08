import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/event_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
    expect(find.text('Kisačka 78, Novi Sad'), findsOneWidget);
    expect(find.text('Navigacija'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
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

  testWidgets('sa koordinatama se prikazuje mini mapa',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        const EventAddress(
          address: 'Bulevar Oslobođenja 45, Novi Sad',
          latitude: 45.2671,
          longitude: 19.8335,
        ),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
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
}
