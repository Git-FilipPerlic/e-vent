import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/organizer_name.dart';
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

void main() {
  testWidgets('prikazuje ime organizatora i dugme za kopiranje',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const OrganizerName(name: 'Milan Jovanović')));

    expect(find.text('Organizator'), findsOneWidget);
    expect(find.text('Milan Jovanović'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('kad imena nema prikazuje objašnjenje i nema šta da se kopira',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const OrganizerName(name: null)));

    expect(find.text('Organizator nije unet'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
  });

  testWidgets('prazan tekst se tretira kao da imena nema',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const OrganizerName(name: '   ')));

    expect(find.text('Organizator nije unet'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
  });

  testWidgets('dodir na dugme kopira ime i javi potvrdu',
      (WidgetTester tester) async {
    // Clipboard je sistemski kanal — u testu se presreće i pamti šta je stiglo.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(_wrap(const OrganizerName(name: 'Milan Jovanović')));
    await tester.tap(find.byIcon(Icons.copy_rounded));
    // Prvi pump pusti da se `await Clipboard.setData` završi,
    // drugi odigra ulazak poruke pri dnu ekrana.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(copied, 'Milan Jovanović');
    expect(find.text('Kopirano: Ime organizatora'), findsOneWidget);
  });
}
