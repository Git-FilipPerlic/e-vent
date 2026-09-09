import 'package:flutter/material.dart';

/// Paleta aplikacije. Vizuelni pravac: skoro crno sa hladnim, tamno-tirkiznim
/// prizvukom. Crna je osnova, tirkiz se pojavljuje kao nagoveštaj — punom
/// jačinom samo tamo gde nešto može da se dodirne.
///
/// Ovo je jedino mesto u projektu gde stoje hex vrednosti boja.
/// Nijedan widget nema boju napisanu u sebi.
abstract final class AppColors {
  /// Osnovna pozadina ekrana.
  static const Color background = Color(0xFF0A0C0C);

  /// Gornja boja pozadinskog gradijenta.
  static const Color backgroundTop = Color(0xFF0E1312);

  /// Donja boja pozadinskog gradijenta.
  static const Color backgroundBottom = Color(0xFF070909);

  /// Kartice.
  static const Color surface = Color(0xFF121716);

  /// Istaknute kartice, polja za unos, aktivni red u listi.
  static const Color surfaceAlt = Color(0xFF182120);

  /// Okviri kartica i razdelnici.
  static const Color border = Color(0xFF1F2A29);

  /// Glavni tekst — namerno nije čisto belo, da ne para oči u mraku.
  static const Color textPrimary = Color(0xFFECECEC);

  /// Pomoćni tekst: hladno siva sa zelenkastim tonom.
  static const Color textSecondary = Color(0xFF8A9A98);

  /// Sve što se dodiruje: dugmad, ikonice, aktivni tab.
  static const Color accent = Color(0xFF2FA89C);

  /// Gradijenti, sjaj, neaktivni deo prstena na Muzici.
  /// Isključivo dekorativan — nikad za tekst ni za ikonicu koja nešto znači.
  static const Color accentDeep = Color(0xFF14403C);

  /// Spremno, završeno.
  static const Color success = Color(0xFF3FA46A);

  /// Uskoro, nedostaje podatak.
  static const Color warning = Color(0xFFE0B341);

  /// Greška, problem.
  static const Color danger = Color(0xFFE5645E);
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
    colors: [Color(0xFF141A19), Color(0xFF0C1010)],
  );

  /// Sjaj oko aktivnih elemenata (veliko dugme za reprodukciju,
  /// pređeni deo prstena na Muzici).
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentDeep, Colors.transparent],
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

/// Zaobljenje kartica.
const double kCardRadius = 12;

/// Minimalna dodirna meta u dp. Sva dugmad i stavke na koje se kuca
/// moraju biti bar ovoliki — aplikacija se koristi jednom rukom tokom nastupa.
const double kMinTouchTarget = 48;

/// Tema aplikacije. **Samo tamna** — događaji su uveče i noću, pa se svetla
/// tema ne pravi (i upola je manje posla oko provere izgleda).
abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      primaryContainer: AppColors.accentDeep,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.background,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
      onError: AppColors.background,
    );

    return ThemeData(
      brightness: Brightness.dark,
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
      // Plutajuće dugme je isto što i svako drugo: dodiruje se, pa ide u
      // `accent`. Podrazumevana Material boja je bila tamna i čitala se kao
      // neaktivno.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
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
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
