import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta aplikacije. Vizuelni pravac (od 25. septembra 2026): **svetao,
/// nežan, „Apple" osećaj** — topla bela podloga, safirno plava za sve što se
/// dodiruje, breskva i cimet kao topli akcenti. Oblici su jako zaobljeni,
/// da aplikacija deluje prijateljski, a ne „opasno".
///
/// Ovo je jedino mesto u projektu gde stoje hex vrednosti boja.
/// Nijedan widget nema boju napisanu u sebi.
///
/// Nazivi uloga su ostali isti kao u tamnoj temi (`background`, `surface`,
/// `accent`…), pa su se svi ekrani prebacili na novi izgled bez diranja.
abstract final class AppColors {
  /// Osnovna pozadina ekrana — topla, skoro bela.
  static const Color background = Color(0xFFF5F4F2);

  /// Gornja boja pozadinskog gradijenta.
  static const Color backgroundTop = Color(0xFFF8F7F5);

  /// Donja boja pozadinskog gradijenta.
  static const Color backgroundBottom = Color(0xFFEFEDEA);

  /// Kartice.
  static const Color surface = Color(0xFFFFFFFF);

  /// Istaknute kartice, polja za unos, aktivni red u listi.
  static const Color surfaceAlt = Color(0xFFF1EFEC);

  /// Okviri kartica i razdelnici.
  static const Color border = Color(0xFFE6E3DF);

  /// Glavni tekst — skoro crn, ne čisto crn.
  static const Color textPrimary = Color(0xFF1D1D1F);

  /// Pomoćni tekst.
  static const Color textSecondary = Color(0xFF6E6E73);

  /// Safirno plava: sve što se dodiruje — dugmad, ikonice, aktivni tab.
  static const Color accent = Color(0xFF2F5BEA);

  /// Svetla safirna nijansa: gradijenti, sjaj, neaktivni deo talasa.
  /// Isključivo dekorativna — nikad za tekst ni za ikonicu koja nešto znači.
  static const Color accentDeep = Color(0xFFDCE4FB);

  /// Breskva: podloga kartice „Sada svira" i izabranog reda.
  static const Color peach = Color(0xFFFFF1E8);

  /// Jača breskva: oznake (čipovi) i pređeni deo talasnog oblika.
  static const Color peachStrong = Color(0xFFFFD6BF);

  /// Breskva za crtež talasa — dovoljno jaka da se vidi na beloj podlozi.
  static const Color peachWave = Color(0xFFF7A27A);

  /// Cimet: sitan topao tekst na breskvi (oznake, vreme u kartici).
  static const Color cinnamon = Color(0xFF8F4A22);

  /// Spremno, završeno.
  static const Color success = Color(0xFF2E9E5B);

  /// Uskoro, nedostaje podatak. Dovoljno taman da se čita na beloj podlozi.
  static const Color warning = Color(0xFFA86A12);

  /// Greška, problem.
  static const Color danger = Color(0xFFD1453B);

  /// Tekst i ikonice na safirnoj podlozi.
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Staza isključenog prekidača.
  static const Color switchOff = Color(0xFFE3E1DE);
}

/// Gradijenti su deo teme, ne improvizacija po widgetima.
/// Idu samo na veće površine — iza sitnog teksta nikad, jer tekst mora
/// da ima ujednačenu podlogu.
abstract final class AppGradients {
  /// Vertikalno, preko celog ekrana.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
  );

  /// Dijagonalno (135°), za istaknute kartice i header.
  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F6)],
  );

  /// Sjaj oko aktivnih elemenata.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentDeep, Color(0x00DCE4FB)],
  );

  /// Veliko dugme za puštanje na Ekranu 2: svetlije gore levo, kao da je
  /// ispupčeno.
  static const RadialGradient playButton = RadialGradient(
    center: Alignment(-0.3, -0.4),
    radius: 0.9,
    colors: [Color(0xFF4A74F2), AppColors.accent, Color(0xFF2549C9)],
    stops: [0, 0.55, 1],
  );
}

/// Razmaci koji se koriste u celoj aplikaciji.
/// Uvek koristiti ove konstante umesto "magičnih" brojeva u widgetima.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Zaobljenje kartica. Namerno veliko: obline su deo „nežnog" izgleda.
const double kCardRadius = 22;

/// Zaobljenje velikih kartica i grupa (plejlista, kartica „Sada svira").
const double kLargeRadius = 26;

/// Minimalna dodirna meta u dp. Sva dugmad i stavke na koje se kuca
/// moraju biti bar ovoliki — aplikacija se koristi jednom rukom tokom nastupa.
const double kMinTouchTarget = 48;

/// Blaga senka ispod belih kartica — kartica se odvaja od podloge bez okvira.
const List<BoxShadow> kSoftShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
];

/// Senka kružića na prekidaču — kružić deluje kao da leži na stazi.
const List<BoxShadow> kKnobShadow = [
  BoxShadow(color: Color(0x2E000000), blurRadius: 8, offset: Offset(0, 3)),
];

/// Senka ispod safirnih dugmadi — plavičast odsjaj, ne siva mrlja.
const List<BoxShadow> kAccentShadow = [
  BoxShadow(color: Color(0x4D2F5BEA), blurRadius: 16, offset: Offset(0, 6)),
];

/// Tema aplikacije. **Svetla** (odluka od 25. septembra 2026).
abstract final class AppTheme {
  /// Stari naziv iz vremena tamne teme. Ostaje kao drugo ime za [light],
  /// da testovi i stariji ekrani rade bez izmena.
  static ThemeData get dark => light;

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.accentDeep,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceAlt,
      surfaceContainerLow: AppColors.surface,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
      onError: AppColors.onAccent,
    );

    const pill = StadiumBorder();

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      // Dodirne mete nikad manje od 48 dp.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        // Tamne ikonice u statusnoj traci — na svetloj podlozi bele se ne vide.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        shape: StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          shape: pill,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.accentDeep,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accentDeep,
        height: 72,
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceAlt,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
