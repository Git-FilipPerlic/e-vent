// Izgled aplikacije: nekoliko kombinacija boja, biraju se u konzoli.

import 'package:event_app/screens/login_screen.dart';
import 'package:event_app/services/auth_service.dart';
import 'package:event_app/services/skin_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Boje su promenljive, pa svaki test vraća podrazumevani izgled — inače
  // bi jedan test menjao boje ostalima.
  tearDown(AppSkin.safir.apply);

  group('izgledi', () {
    test('nepoznat ili prazan izgled daje podrazumevani', () {
      expect(AppSkin.byId(null).id, 'safir');
      expect(AppSkin.byId('nema-ovoga').id, 'safir');
      expect(AppSkin.byId('grimiz').id, 'grimiz');
    });

    test('svaki izgled ima svoj id i naziv', () {
      final ids = AppSkin.all.map((s) => s.id).toSet();
      expect(ids.length, AppSkin.all.length);
      expect(AppSkin.all.length, 4);
      expect(AppSkin.all.first.id, 'safir');
      for (final skin in AppSkin.all) {
        expect(skin.name, isNotEmpty);
      }
    });

    test('izbor izgleda menja boje cele aplikacije', () {
      final safir = AppColors.accent;

      AppSkin.grimiz.apply();
      expect(AppColors.accent, AppSkin.grimiz.accent);
      expect(AppColors.accent, isNot(safir));
      expect(AppColors.background, AppSkin.grimiz.background);

      // Tema se gradi iz tih boja, pa je i ona nova.
      expect(AppTheme.light.colorScheme.primary, AppSkin.grimiz.accent);
    });

    // Zelena, žuta i crvena nose značenje: kad bi se menjale sa izgledom,
    // ista boja bi na dva telefona značila dve stvari.
    test('boje koje nose značenje se ne menjaju', () {
      final success = AppColors.success;
      final warning = AppColors.warning;
      final danger = AppColors.danger;

      for (final skin in AppSkin.all) {
        skin.apply();
        expect(AppColors.success, success);
        expect(AppColors.warning, warning);
        expect(AppColors.danger, danger);
      }
    });
  });

  group('pamćenje izgleda', () {
    // Izgled je lična stvar, pa se pamti na telefonu — ne u bazi firme.
    test('izabran izgled se pamti i vraća', () async {
      SharedPreferences.setMockInitialValues(const {});
      const service = SkinService();

      expect((await service.load()).id, 'safir');

      await service.save(AppSkin.tirkiz);
      expect((await service.load()).id, 'tirkiz');
    });

    test('pokvaren zapis ne obara aplikaciju', () async {
      SharedPreferences.setMockInitialValues(const {'app_skin': 'nesto-drugo'});
      expect((await const SkinService().load()).id, 'safir');
    });
  });

  group('izbor u konzoli', () {
    testWidgets('konzola nudi sve izglede i vraća izabrani', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');
      AppSkin? chosen;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LoginScreen(
            auth: auth,
            skin: AppSkin.safir,
            onSkin: (skin) => chosen = skin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Izgled'), findsOneWidget);
      for (final skin in AppSkin.all) {
        expect(find.text(skin.name), findsOneWidget);
      }

      await tester.tap(find.text('Grimizna'));
      await tester.pumpAndSettle();

      expect(chosen?.id, 'grimiz');
    });

    // Neprijavljenom se konzola i ne otvara, a bez načina da se izgled
    // promeni ne treba ni da se nudi.
    testWidgets('bez načina za promenu nema izbora izgleda', (
      WidgetTester tester,
    ) async {
      final auth = MockAuthService();
      await auth.signIn(name: 'Filip', pin: '1234');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LoginScreen(auth: auth),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Izgled'), findsNothing);
    });
  });
}
