import 'package:event_app/screens/login_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/common/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prijava', () {
    test('bez prijave se ništa ne menja', () {
      final auth = MockAuthService();

      expect(auth.isSignedIn, isFalse);
      for (final permission in AppPermission.values) {
        expect(auth.can(permission), isFalse, reason: permission.name);
      }
    });

    test('glavni sme da menja, običan izvođač ne', () async {
      final auth = MockAuthService();

      expect(await auth.signIn(name: 'Filip', pin: '1234'), isNull);
      expect(auth.currentUser?.role, UserRole.glavni);
      expect(auth.can(AppPermission.editEvent), isTrue);

      await auth.signOut();
      expect(await auth.signIn(name: 'Ana', pin: '1111'), isNull);
      expect(auth.currentUser?.role, UserRole.user);
      // Izvođač vidi sve, ali ne dira podatke tima.
      expect(auth.can(AppPermission.editEvent), isFalse);
    });

    test('pogrešno ime i pogrešan PIN daju istu poruku', () async {
      final auth = MockAuthService();

      final wrongName = await auth.signIn(name: 'Nepostojeci', pin: '1234');
      final wrongPin = await auth.signIn(name: 'Filip', pin: '9999');

      // Ista poruka namerno: iz različitih poruka bi se saznalo koja imena
      // postoje.
      expect(wrongName, wrongPin);
      expect(auth.isSignedIn, isFalse);
    });

    test('prazno polje se javlja pre provere naloga', () async {
      final auth = MockAuthService();

      expect(await auth.signIn(name: '  ', pin: '1234'), 'Unesi ime.');
      expect(await auth.signIn(name: 'Filip', pin: ' '), 'Unesi PIN.');
    });

    test('ime nije osetljivo na velika slova i razmake', () async {
      final auth = MockAuthService();

      expect(await auth.signIn(name: '  FILIP ', pin: '1234'), isNull);
      expect(auth.currentUser?.name, 'FILIP');
    });

    test('odjava vraća aplikaciju u čitanje', () async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(auth.can(AppPermission.editTeamLogo), isFalse);
    });

    test('prijava i odjava javljaju promenu ekranima', () async {
      final auth = MockAuthService();
      var notifications = 0;
      auth.addListener(() => notifications++);

      await auth.signIn(name: 'Filip', pin: '1234');
      await auth.signOut();

      expect(notifications, 2);
    });
  });

  group('konzola umesto dugmadi u headeru', () {
    testWidgets('header ima jedno dugme, ne tri', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AppHeader(signedInAs: 'Filip', onOpenConsole: () {}),
          ),
        ),
      );

      // Tri ikonice su prekrivale baner; logotip se menja iz konzole.
      expect(find.byTooltip('Konzola'), findsOneWidget);
      expect(find.byTooltip('Promeni logotip tima'), findsNothing);
      expect(find.byTooltip('Ukloni logotip'), findsNothing);
      expect(find.byTooltip('Odjava'), findsNothing);
    });

    testWidgets('bez prijave dugme vodi u prijavu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: AppHeader(onOpenConsole: () {})),
        ),
      );

      expect(find.byTooltip('Prijava'), findsOneWidget);
    });

    testWidgets('prijavljen glavni u konzoli menja logotip i odjavljuje se', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');
      var edited = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: LoginScreen(
            auth: auth,
            hasLogo: true,
            onEditLogo: () async => edited++,
            onRemoveLogo: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prijavljen: Filip'), findsOneWidget);
      expect(find.text('Ukloni logotip'), findsOneWidget);

      await tester.tap(find.text('Promeni logotip'));
      await tester.pumpAndSettle();
      expect(edited, 1);

      await tester.tap(find.text('Odjavi se'));
      await tester.pumpAndSettle();
      expect(auth.isSignedIn, isFalse);
    });

    testWidgets('bez logotipa nema šta da se ukloni', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: LoginScreen(auth: auth, onEditLogo: () async {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ukloni logotip'), findsNothing);
    });

    testWidgets('izvođaču konzola ne nudi logotip', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Ana', pin: '1111');

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: LoginScreen(auth: auth)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prijavljen: Ana'), findsOneWidget);
      expect(find.text('Promeni logotip'), findsNothing);
      expect(find.text('Odjavi se'), findsOneWidget);
    });
  });
}
