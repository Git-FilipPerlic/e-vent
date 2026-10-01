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
      expect(AppSkin.byId('zuta').id, 'zuta');
      // Grimizna, Tirkiz i Bledo siva su uklonjene 1. oktobra 2026 (manje
      // izgleda u konzoli); ko ih je imao zapamćene sa starije instalacije
      // ne sme da ostane na nepostojećem izgledu, nego pada na podrazumevani.
      expect(AppSkin.byId('grimiz').id, 'safir');
      expect(AppSkin.byId('tirkiz').id, 'safir');
      expect(AppSkin.byId('punk').id, 'safir');
      expect(AppSkin.byId('crna').id, 'safir');
      expect(AppSkin.byId('crvena').id, 'safir');
      expect(AppSkin.byId('siva').id, 'safir');
    });

    test('svaki izgled ima svoj id i naziv', () {
      final ids = AppSkin.all.map((s) => s.id).toSet();
      expect(ids.length, AppSkin.all.length);
      expect(AppSkin.all.length, 6);
      expect(AppSkin.all.first.id, 'safir');
      for (final skin in AppSkin.all) {
        expect(skin.name, isNotEmpty);
      }
    });

    test('izbor izgleda menja boje cele aplikacije', () {
      final safir = AppColors.accent;

      AppSkin.zuta.apply();
      expect(AppColors.accent, AppSkin.zuta.accent);
      expect(AppColors.accent, isNot(safir));
      expect(AppColors.border, AppSkin.zuta.border);

      // Tema se gradi iz tih boja, pa je i ona nova.
      expect(AppTheme.light.colorScheme.primary, AppSkin.zuta.accent);
    });

    // Bela je dovoljno tamna na safiru — na žutoj i na neonima bi skoro
    // nestala, pa ti izgledi nose crnu.
    test('tekst na accent podlozi je crn samo na svetlim bojama dodira', () {
      expect(AppSkin.safir.onAccent, const Color(0xFFFFFFFF));
      expect(AppSkin.neon.onAccent, isNot(const Color(0xFFFFFFFF)));
      expect(AppSkin.zelena.onAccent, isNot(const Color(0xFFFFFFFF)));
      expect(AppSkin.zuta.onAccent, isNot(const Color(0xFFFFFFFF)));

      AppSkin.zuta.apply();
      expect(AppColors.onAccent, AppSkin.zuta.onAccent);
      expect(AppTheme.light.colorScheme.onPrimary, AppSkin.zuta.onAccent);
    });

    // Korisnikova ispravka od 1. oktobra 2026: „više crne boje" na žutom
    // izgledu — čist crn tekst, i okvir kartica i staza prekidača tamno
    // ugljene, ne bledo peščane kao kod ostalih izgleda.
    test('žuti izgled nosi više crne nego ostali', () {
      expect(AppSkin.zuta.textPrimary, const Color(0xFF000000));
      expect(AppSkin.zuta.border, isNot(AppSkin.safir.border));
      expect(AppSkin.zuta.switchOff, isNot(AppSkin.safir.switchOff));
    });

    // Žuti krug koji se puni dok prst stoji iznad talasa mora da se vidi —
    // zato je talas kod Žute crn, a ne u boji dodira.
    test('talas prati izgled, a kod Žute je taman', () {
      AppSkin.safir.apply();
      expect(AppColors.waveAhead, AppSkin.safir.accent);

      AppSkin.zuta.apply();
      expect(AppColors.waveAhead, isNot(AppColors.accent));
      expect(AppColors.waveAhead.computeLuminance(), lessThan(0.05));
    });

    // Roza-breskva je kod žutog izgleda skoro crna, pa tekst na njoj mora
    // da bude svetao — inače bi crn tekst na crnoj kartici nestao.
    test('tekst na breskvi prati njenu boju', () {
      AppSkin.safir.apply();
      expect(AppColors.onPeach, AppSkin.safir.textPrimary);
      expect(AppColors.onPeachLabel, AppSkin.safir.cinnamon);
      expect(AppColors.onPeachMuted, AppSkin.safir.textSecondary);

      AppSkin.zuta.apply();
      expect(AppColors.peach.computeLuminance(), lessThan(0.05));
      expect(AppColors.onPeach.computeLuminance(), greaterThan(0.5));
      expect(AppColors.onPeachLabel.computeLuminance(), greaterThan(0.5));
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

  // Svaki izgled mora da bude čitljiv: tekst na dugmetu i tekst na tamnoj
  // kartici bar 4,5:1 (WCAG AA), a boja dodira na beloj bar 3:1, jer
  // ikonice i dugmad sa okvirom stoje direktno na belom. Žuta je izuzetak
  // za ovo poslednje — žuto na belom se slabo vidi, pa ona nosi crne
  // okvire i ikonice tamo gde je to bitno.
  group('kontrast', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final skin in AppSkin.all) {
      test('${skin.name}: tekst na dugmetu i na tamnoj kartici se čita', () {
        skin.apply();
        expect(contrast(skin.accent, skin.onAccent), greaterThanOrEqualTo(4.5));
        expect(
          contrast(AppColors.peach, AppColors.onPeach),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(AppColors.peach, AppColors.onPeachLabel),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    // Tamni izgledi (crna podloga): boja dodira se čita kao tekst na svakoj
    // tamnoj podlozi, a tekst i pomoćni tekst su svetli.
    for (final z in [AppSkin.zelena, AppSkin.rozeCrna, AppSkin.zutoCrna]) {
      test('${z.name}: na crnoj podlozi se sve čita', () {
        expect(z.dark, isTrue);
        for (final bg in [z.background, z.surface, z.surfaceAlt, z.peach]) {
          expect(contrast(z.accent, bg), greaterThanOrEqualTo(4.5));
          expect(contrast(z.textPrimary, bg), greaterThanOrEqualTo(7));
          expect(contrast(z.textSecondary, bg), greaterThanOrEqualTo(4.5));
        }
        // Talas mora da se vidi na crnom.
        expect(
          contrast(z.waveAhead!, z.backgroundTop),
          greaterThanOrEqualTo(3),
        );
      });
    }

    // Krug koji se puni dok prst stoji je u boji dodira, preko talasa. Kod
    // Roze crne je slabije odvojen od srednje sivog talasa (≈2:1) — svesno,
    // da raspored ostane isti kao kod Neon zelene; odvaja ga tamna staza.
    for (final z in [AppSkin.zelena, AppSkin.zutoCrna]) {
      test('${z.name}: krug se vidi preko talasa', () {
        expect(contrast(z.accent, z.waveAhead!), greaterThanOrEqualTo(3));
      });
    }
  });

  group('tamna podloga', () {
    // Na tamnom izgledu tema mora da bude tamna — inače podrazumevan tekst
    // ostaje crn na crnoj podlozi.
    test('tema prati izgled', () {
      AppSkin.zelena.apply();
      expect(AppTheme.light.brightness, Brightness.dark);
      expect(AppTheme.light.colorScheme.brightness, Brightness.dark);

      AppSkin.safir.apply();
      expect(AppTheme.light.brightness, Brightness.light);
    });
  });

  group('neon', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    // Neon ne može da prođe 4,5:1 kao tekst — svesna cena izgleda. Ali
    // prag za ikonice, okvire i krupan tekst (3:1) mora da drži na svakoj
    // podlozi, inače se dugme sa okvirom ne vidi.
    for (final n in [AppSkin.neon]) {
      test('${n.name}: vidi se bar kao ikonica na svakoj podlozi', () {
        for (final bg in [
          n.surface,
          n.surfaceAlt,
          n.background,
          n.backgroundTop,
          n.backgroundBottom,
        ]) {
          expect(contrast(n.accent, bg), greaterThanOrEqualTo(3));
        }
        // Krug koji se puni dok prst stoji je u boji dodira, preko crnog
        // talasa.
        expect(contrast(n.accent, n.waveAhead!), greaterThanOrEqualTo(3));
      });
    }
  });

  group('pamćenje izgleda', () {
    // Izgled je lična stvar, pa se pamti na telefonu — ne u bazi firme.
    test('izabran izgled se pamti i vraća', () async {
      SharedPreferences.setMockInitialValues(const {});
      const service = SkinService();

      expect((await service.load()).id, 'safir');

      await service.save(AppSkin.zuta);
      expect((await service.load()).id, 'zuta');
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

      await tester.tap(find.text('Žuta'));
      await tester.pumpAndSettle();

      expect(chosen?.id, 'zuta');
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
