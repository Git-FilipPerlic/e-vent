import 'package:event_app/services/auth_service.dart';
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
}
