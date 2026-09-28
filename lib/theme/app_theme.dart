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
  static Color background = Color(0xFFF5F4F2);

  /// Gornja boja pozadinskog gradijenta.
  static Color backgroundTop = Color(0xFFF8F7F5);

  /// Donja boja pozadinskog gradijenta.
  static Color backgroundBottom = Color(0xFFEFEDEA);

  /// Kartice.
  static Color surface = Color(0xFFFFFFFF);

  /// Istaknute kartice, polja za unos, aktivni red u listi.
  static Color surfaceAlt = Color(0xFFF1EFEC);

  /// Okviri kartica i razdelnici.
  static Color border = Color(0xFFE6E3DF);

  /// Glavni tekst — skoro crn, ne čisto crn.
  static Color textPrimary = Color(0xFF1D1D1F);

  /// Pomoćni tekst.
  static Color textSecondary = Color(0xFF6E6E73);

  /// Safirno plava: sve što se dodiruje — dugmad, ikonice, aktivni tab.
  static Color accent = Color(0xFF2F5BEA);

  /// Svetla safirna nijansa: gradijenti, sjaj, neaktivni deo talasa.
  /// Isključivo dekorativna — nikad za tekst ni za ikonicu koja nešto znači.
  static Color accentDeep = Color(0xFFDCE4FB);

  /// Breskva: podloga kartice „Sada svira" i izabranog reda.
  static Color peach = Color(0xFFFFF1E8);

  /// Jača breskva: oznake (čipovi) i pređeni deo talasnog oblika.
  static Color peachStrong = Color(0xFFFFD6BF);

  /// Breskva za crtež talasa — dovoljno jaka da se vidi na beloj podlozi.
  static Color peachWave = Color(0xFFF7A27A);

  /// Cimet: sitan topao tekst na breskvi (oznake, vreme u kartici).
  static Color cinnamon = Color(0xFF8F4A22);

  /// Spremno, završeno.
  static const Color success = Color(0xFF2E9E5B);

  /// Uskoro, nedostaje podatak. Dovoljno taman da se čita na beloj podlozi.
  static const Color warning = Color(0xFFA86A12);

  /// Greška, problem.
  static const Color danger = Color(0xFFD1453B);

  /// Boje ikonica članova ekipe.
  ///
  /// Jarke su namerno i jedine su takve u aplikaciji: služe da se čovek
  /// prepozna na prvi pogled, u spisku ili na talasu. Ne koriste se ni za
  /// šta drugo — ostatak palete i dalje nosi značenje, ne ukras.
  static const Color avatarRed = Color(0xFFE23B2E);
  static const Color avatarOrange = Color(0xFFF07B1D);
  static const Color avatarYellow = Color(0xFFE2A400);
  static const Color avatarGreen = Color(0xFF17924F);
  static const Color avatarBlue = Color(0xFF1F6FEB);
  static const Color avatarPurple = Color(0xFF7A3FD1);
  static const Color avatarPink = Color(0xFFD1348A);

  /// Tekst i ikonice na safirnoj podlozi.
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Staza isključenog prekidača.
  static Color switchOff = Color(0xFFE3E1DE);
}

/// Jedan **izgled** aplikacije: skup boja koje se biraju u konzoli.
///
/// Boje koje nose značenje — zelena za spremno, žuta za pažnju, crvena za
/// problem — **ne menjaju se ni u jednom izgledu**. Kad bi se menjale, ista
/// boja bi na dva telefona značila dve stvari. Menja se ono što je ukus:
/// boja onoga što se dodiruje, podloga i topli akcenti.
class AppSkin {
  const AppSkin({
    required this.id,
    required this.name,
    required this.accent,
    required this.accentDeep,
    required this.background,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.peach,
    required this.peachStrong,
    required this.peachWave,
    required this.cinnamon,
    required this.switchOff,
  });

  /// Kako se izgled zove u bazi i u pamćenju telefona — bez naših slova.
  final String id;

  /// Kako se zove na ekranu.
  final String name;

  final Color accent;
  final Color accentDeep;
  final Color background;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color peach;
  final Color peachStrong;
  final Color peachWave;
  final Color cinnamon;
  final Color switchOff;

  /// Sadašnji izgled: topla bela i safirno plava. Podrazumevani.
  static const AppSkin safir = AppSkin(
    id: 'safir',
    name: 'Safir',
    accent: Color(0xFF2F5BEA),
    accentDeep: Color(0xFFDCE4FB),
    background: Color(0xFFF5F4F2),
    backgroundTop: Color(0xFFF8F7F5),
    backgroundBottom: Color(0xFFEFEDEA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1EFEC),
    border: Color(0xFFE6E3DF),
    textPrimary: Color(0xFF1D1D1F),
    textSecondary: Color(0xFF6E6E73),
    peach: Color(0xFFFFF1E8),
    peachStrong: Color(0xFFFFD6BF),
    peachWave: Color(0xFFF7A27A),
    cinnamon: Color(0xFF8F4A22),
    switchOff: Color(0xFFE3E1DE),
  );

  /// Grimizna: tamno crveno na toploj beloj, sa ružičastim akcentima.
  static const AppSkin grimiz = AppSkin(
    id: 'grimiz',
    name: 'Grimizna',
    accent: Color(0xFFA81D3F),
    accentDeep: Color(0xFFF6DCE3),
    background: Color(0xFFF7F4F4),
    backgroundTop: Color(0xFFFAF7F7),
    backgroundBottom: Color(0xFFF1EBEC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF3EDEE),
    border: Color(0xFFE8DFE1),
    textPrimary: Color(0xFF1F1A1B),
    textSecondary: Color(0xFF6E6468),
    peach: Color(0xFFFDEFF1),
    peachStrong: Color(0xFFF7CAD3),
    peachWave: Color(0xFFDE8195),
    cinnamon: Color(0xFF7C2637),
    switchOff: Color(0xFFE5DEDF),
  );

  /// Tirkiz: hladna bela i duboko zeleno-plava, uz iste tople akcente.
  static const AppSkin tirkiz = AppSkin(
    id: 'tirkiz',
    name: 'Tirkiz',
    accent: Color(0xFF0E7C86),
    accentDeep: Color(0xFFD2EBEE),
    background: Color(0xFFF3F6F5),
    backgroundTop: Color(0xFFF7F9F9),
    backgroundBottom: Color(0xFFEAEFEE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDF2F1),
    border: Color(0xFFDDE6E4),
    textPrimary: Color(0xFF15201F),
    textSecondary: Color(0xFF5E6C6A),
    peach: Color(0xFFFFF1E8),
    peachStrong: Color(0xFFFFD6BF),
    peachWave: Color(0xFFF2946A),
    cinnamon: Color(0xFF8A4520),
    switchOff: Color(0xFFDEE4E3),
  );

  /// Bledo siva: bez ijedne jarke boje, za onoga kome boje odvlače pažnju.
  static const AppSkin siva = AppSkin(
    id: 'siva',
    name: 'Bledo siva',
    accent: Color(0xFF4F5B6B),
    accentDeep: Color(0xFFE1E5EA),
    background: Color(0xFFF4F4F5),
    backgroundTop: Color(0xFFF8F8F9),
    backgroundBottom: Color(0xFFECECEE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFEFF1),
    border: Color(0xFFE1E1E5),
    textPrimary: Color(0xFF1C1D1F),
    textSecondary: Color(0xFF6B6D73),
    peach: Color(0xFFF2F1EF),
    peachStrong: Color(0xFFDBD8D3),
    peachWave: Color(0xFFA8A29A),
    cinnamon: Color(0xFF55504A),
    switchOff: Color(0xFFE2E2E4),
  );

  /// Svi izgledi, redom kojim stoje u konzoli.
  static const List<AppSkin> all = [safir, grimiz, tirkiz, siva];

  /// Izgled po id-u; nepoznat ili prazan daje podrazumevani.
  static AppSkin byId(String? id) {
    for (final skin in all) {
      if (skin.id == id) return skin;
    }
    return safir;
  }

  /// Postavlja boje cele aplikacije na ovaj izgled.
  ///
  /// Boje su zato promenljive, a ne `const`: paleta i dalje stoji na jednom
  /// mestu — nijedan widget ne zna nijednu hex vrednost.
  void apply() {
    AppColors.accent = accent;
    AppColors.accentDeep = accentDeep;
    AppColors.background = background;
    AppColors.backgroundTop = backgroundTop;
    AppColors.backgroundBottom = backgroundBottom;
    AppColors.surface = surface;
    AppColors.surfaceAlt = surfaceAlt;
    AppColors.border = border;
    AppColors.textPrimary = textPrimary;
    AppColors.textSecondary = textSecondary;
    AppColors.peach = peach;
    AppColors.peachStrong = peachStrong;
    AppColors.peachWave = peachWave;
    AppColors.cinnamon = cinnamon;
    AppColors.switchOff = switchOff;
  }

  /// Svetlija nijansa iste boje — za gradijent na velikom dugmetu.
  static Color lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Tamnija nijansa iste boje.
  static Color darken(Color color, double amount) => lighten(color, -amount);
}

/// Gradijenti su deo teme, ne improvizacija po widgetima.
/// Idu samo na veće površine — iza sitnog teksta nikad, jer tekst mora
/// da ima ujednačenu podlogu.
abstract final class AppGradients {
  /// Vertikalno, preko celog ekrana.
  ///
  /// Gradijenti se **računaju iz boja**, pa nisu `const`: izgled se bira u
  /// konzoli i boje se menjaju u toku rada.
  static LinearGradient get background => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
  );

  /// Dijagonalno (135°), za istaknute kartice i header.
  static LinearGradient get surface => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surface, AppColors.backgroundTop],
  );

  /// Sjaj oko aktivnih elemenata.
  static LinearGradient get accent => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentDeep, AppColors.accentDeep.withValues(alpha: 0)],
  );

  /// Veliko dugme za puštanje na Ekranu 2: svetlije gore levo, kao da je
  /// ispupčeno.
  ///
  /// Svetlija i tamnija nijansa se izvode iz same boje izgleda, da dugme
  /// prati izabrani izgled.
  static RadialGradient get playButton => RadialGradient(
    center: const Alignment(-0.3, -0.4),
    radius: 0.9,
    colors: [
      AppSkin.lighten(AppColors.accent, 0.12),
      AppColors.accent,
      AppSkin.darken(AppColors.accent, 0.12),
    ],
    stops: const [0, 0.55, 1],
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

/// Senka ispod dugmadi u boji izgleda — obojen odsjaj, ne siva mrlja.
///
/// Nije `const` jer prati izabrani izgled.
List<BoxShadow> get kAccentShadow => [
  BoxShadow(
    color: AppColors.accent.withValues(alpha: 0.3),
    blurRadius: 16,
    offset: Offset(0, 6),
  ),
];

/// Tema aplikacije. **Svetla** (odluka od 25. septembra 2026).
abstract final class AppTheme {
  /// Stari naziv iz vremena tamne teme. Ostaje kao drugo ime za [light],
  /// da testovi i stariji ekrani rade bez izmena.
  static ThemeData get dark => light;

  static ThemeData get light {
    final scheme = ColorScheme.light(
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
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
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
          side: BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
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
          side: BorderSide(color: AppColors.border),
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
        labelStyle: TextStyle(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accentDeep,
        height: 72,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceAlt,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
