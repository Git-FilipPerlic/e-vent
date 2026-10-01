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

  /// Tekst i ikonice na podlozi u boji `accent`.
  ///
  /// Bela radi na safirnoj podlozi — dovoljno je tamna. Promenljiva je
  /// (ne `const`) zato što to prestaje da
  /// važi kod svetle podloge: žuti izgled ovde stavlja crnu, jer bela na
  /// žutom skoro da se ne vidi.
  static Color onAccent = Color(0xFFFFFFFF);

  /// Staza isključenog prekidača.
  static Color switchOff = Color(0xFFE3E1DE);

  /// Glavni tekst na podlozi u boji `peach` (kartica „Sada svira", izabran
  /// red, sastanak u spisku). Kod svetle breskve je to isto što i
  /// `textPrimary`; žuti izgled ima tamnu podlogu tu, pa i svetao tekst.
  static Color onPeach = Color(0xFF1D1D1F);

  /// Sitan istaknut tekst na `peach` podlozi (oznake, vreme). Kod svetle
  /// breskve je to cimet.
  static Color onPeachLabel = Color(0xFF8F4A22);

  /// Pomoćni tekst na `peach` podlozi (izvođač, trajanje).
  static Color onPeachMuted = Color(0xFF6E6E73);

  /// Deo talasa (ekran sa talasom) koji tek dolazi. Kod Safira je to boja
  /// dodira; kod Žute je crn, jer bi žuti krug koji se puni dok prst stoji
  /// na žutom talasu nestao.
  static Color waveAhead = Color(0xFF2F5BEA);

  /// Da li je podloga tamna. Aplikacija je inače svetla; tamni su Neon
  /// zelena, Roze crna i Žuto crna (crna podloga). Po ovome tema bira tamnu šemu —
  /// podrazumevan tekst postaje svetao — i statusna traka svetle ikonice.
  static bool isDark = false;
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
    this.onAccent = const Color(0xFFFFFFFF),
    this.onPeach,
    this.onPeachLabel,
    this.onPeachMuted,
    this.waveAhead,
    this.dark = false,
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

  /// Tekst i ikonice na podlozi obojenoj sa [accent]. Belo radi svuda osim
  /// na svetloj (žutoj) podlozi, pa je jedini izgled koji ga menja.
  final Color onAccent;

  /// Tekst na `peach` podlozi. `null` znači isto što i [textPrimary],
  /// [cinnamon] i [textSecondary] — tako je kod svakog izgleda sa svetlom
  /// breskvom. Menja ih samo izgled kod kog je `peach` taman.
  final Color? onPeach;
  final Color? onPeachLabel;
  final Color? onPeachMuted;

  /// Deo talasa koji tek dolazi. `null` znači [accent].
  final Color? waveAhead;

  /// Tamna podloga (svetao tekst, svetle ikonice u statusnoj traci).
  final bool dark;

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

  /// Žuta: probni izgled po predlogu korisnika (1. oktobra 2026) — jako
  /// kontrastna žuta i crna, sve ostalo belo/bledo sivo kao kod Safira.
  ///
  /// Jedini izgled kod kog [onAccent] nije belo: žuta podloga je toliko
  /// svetla da bi beo tekst na njoj skoro nestao, pa dugmad i ikonice na
  /// njoj nose crnu. Crna nosi i ostatak ekrana (ispravka od 1. oktobra
  /// 2026, na molbu korisnika za „više crne boje"): tekst je čisto crn, a
  /// okviri kartica i staza isključenog prekidača su tamno ugljene, ne
  /// bledo peščane kao kod ostalih izgleda — zato svaka kartica dobije
  /// vidljiv crn obrub. Roza-breskva je zamenjena skoro crnom sivom
  /// (`peach` — kartica „Sada svira", izabran red, sastanak u spisku,
  /// značke): na njoj tekst ide belo, oznake žuto, pomoćni tekst svetlo
  /// sivo ([onPeach], [onPeachLabel], [onPeachMuted]).
  static const AppSkin zuta = AppSkin(
    id: 'zuta',
    name: 'Žuta',
    accent: Color(0xFFFFC800),
    accentDeep: Color(0xFFFFF3C4),
    background: Color(0xFFF5F4F2),
    backgroundTop: Color(0xFFF8F7F5),
    backgroundBottom: Color(0xFFEFEDEA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1EFEC),
    border: Color(0xFF2B2B2B),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF454545),
    peach: Color(0xFF1C1C1E),
    peachStrong: Color(0xFF3A3A3C),
    // Pređeni deo talasa: svetlo siv, „odrađeno"; ono što dolazi je crno.
    peachWave: Color(0xFFB5B5B8),
    cinnamon: Color(0xFF1C1C1E),
    switchOff: Color(0xFF2B2B2B),
    onAccent: Color(0xFF141414),
    onPeach: Color(0xFFFFFFFF),
    onPeachLabel: Color(0xFFFFC800),
    onPeachMuted: Color(0xFFA8A8AC),
    waveAhead: Color(0xFF1C1C1E),
  );

  /// Neon roze: fluorescentno roze na beloj podlozi, uz crno (predlog
  /// korisnika, 1. oktobra 2026). Id je ostao `neon` iz prve probe, da
  /// telefon koji ga je već izabrao ne padne na Safir.
  ///
  /// Neon je po prirodi svetao, pa kao **tekst** na beloj podlozi ne može da
  /// prođe 4,5:1 — ovde je ≈3,6:1 na beloj i bar 3:1 na najtamnijoj sivoj
  /// podlozi. To je svesna cena „neon" izgleda: 3:1 je prag za ikonice,
  /// okvire i krupan tekst, a sitan tekst u boji dodira (vreme u spisku,
  /// natpis na dugmetu sa okvirom) se čita lošije nego u ostalim izgledima.
  /// Zato je podloga čisto bela i svetlo siva, a ne bledo roze: svaka
  /// nijansa ispod bele bi neon još više ugasila.
  ///
  /// Na neon dugmetu tekst je crn (≈5,9:1). Tamne kartice su crne sa neon
  /// oznakama, talas je crn, a krug koji se puni dok prst stoji je neon.
  static const AppSkin neon = AppSkin(
    id: 'neon',
    name: 'Neon roze',
    accent: Color(0xFFFF0FA6),
    accentDeep: Color(0xFFFFD1EE),
    background: Color(0xFFF7F7F7),
    backgroundTop: Color(0xFFFAFAFA),
    backgroundBottom: Color(0xFFF0F0F0),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F2F2),
    border: Color(0xFF111111),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF3D3D3D),
    peach: Color(0xFF111111),
    peachStrong: Color(0xFF4A0A33),
    peachWave: Color(0xFFFFB8E6),
    cinnamon: Color(0xFF111111),
    switchOff: Color(0xFF111111),
    onAccent: Color(0xFF000000),
    onPeach: Color(0xFFFFFFFF),
    onPeachLabel: Color(0xFFFF0FA6),
    onPeachMuted: Color(0xFFA8A8AC),
    waveAhead: Color(0xFF111111),
  );

  /// Neon zelena (1. oktobra 2026): **prvi tamni izgled** — crna
  /// podloga, bledo sivi detalji i pravi neon zeleni `#39FF14` (na
  /// izričit zahtev korisnika).
  ///
  /// Na crnom neon tek pokazuje šta je: kao tekst je ≈15:1, pa se ovde
  /// čita sve što je u boji dodira — za razliku od prve probe na beloj,
  /// gde je isti neon bio ≈1,4:1. Na zelenom dugmetu tekst je crn.
  ///
  /// Talas: ono što dolazi je srednje sivo, a ne bledo sivo — neon krug koji
  /// se puni dok prst stoji ne bi se video preko svetlog.
  ///
  /// Pažnja: zelena inače znači „spremno" (`AppColors.success`); ta boja se
  /// ne menja.
  static const AppSkin zelena = AppSkin(
    id: 'zelena',
    name: 'Neon zelena',
    dark: true,
    accent: Color(0xFF39FF14),
    accentDeep: Color(0xFF1A4D10),
    background: Color(0xFF000000),
    backgroundTop: Color(0xFF0A0A0A),
    backgroundBottom: Color(0xFF000000),
    surface: Color(0xFF141414),
    surfaceAlt: Color(0xFF1F1F1F),
    border: Color(0xFF8A8A8E),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFB0B0B4),
    peach: Color(0xFF262626),
    peachStrong: Color(0xFF3A3A3C),
    peachWave: Color(0xFF2C2C2E),
    cinnamon: Color(0xFF39FF14),
    switchOff: Color(0xFF3A3A3C),
    onAccent: Color(0xFF000000),
    onPeach: Color(0xFFF2F2F2),
    onPeachLabel: Color(0xFF39FF14),
    onPeachMuted: Color(0xFFB0B0B4),
    waveAhead: Color(0xFF6E6E73),
  );

  /// Roze crna: isti raspored kao Neon zelena, ali **mekši** — nežna roze
  /// `#F07AAE` na ugljeno sivoj umesto čisto crne podloge (1. oktobra 2026).
  ///
  /// Istorija: `#FF13F0` je bila magenta (previše plava), pa `#FF2290`,
  /// koja je „čupala oči" uz čistu crnu. Ublaženo po pravilu za tamne
  /// ekrane: jarka, zasićena boja na čistoj crnoj treperi i zamara oko, pa
  /// je roze svetlija i manje zasićena, a crna je postala ugljeno siva
  /// (`#141416`). I tekst je za nijansu prigušeniji od čisto belog.
  ///
  /// I dalje se sve čita: roze na kartici ≈5,4:1, tamni tekst na roze
  /// dugmetu ≈6,7:1. Krug koji se puni dok prst stoji je od srednje sivog
  /// talasa odvojen ≈2:1; odvaja ga i njegova tamna staza (`accentDeep`).
  static const AppSkin rozeCrna = AppSkin(
    id: 'rozecrna',
    name: 'Roze crna',
    dark: true,
    accent: Color(0xFFF07AAE),
    accentDeep: Color(0xFF4A2236),
    background: Color(0xFF141416),
    backgroundTop: Color(0xFF18181B),
    backgroundBottom: Color(0xFF141416),
    surface: Color(0xFF1E1E21),
    surfaceAlt: Color(0xFF28282C),
    border: Color(0xFF6E6E73),
    textPrimary: Color(0xFFE8E6E8),
    textSecondary: Color(0xFFA8A6AA),
    peach: Color(0xFF2C2C30),
    peachStrong: Color(0xFF3E3E43),
    peachWave: Color(0xFF3A3A3E),
    cinnamon: Color(0xFFF07AAE),
    switchOff: Color(0xFF3A3A3E),
    onAccent: Color(0xFF1A1A1C),
    onPeach: Color(0xFFE8E6E8),
    onPeachLabel: Color(0xFFF07AAE),
    onPeachMuted: Color(0xFFA8A6AA),
    waveAhead: Color(0xFF6E6E73),
  );

  /// Žuto crna: isti raspored kao Neon zelena, sa žutom iz svetle Žute
  /// (`#FFC800`) na crnoj podlozi (1. oktobra 2026). Na crnom žuta drži
  /// ≈13:1.
  static const AppSkin zutoCrna = AppSkin(
    id: 'zutocrna',
    name: 'Žuto crna',
    dark: true,
    accent: Color(0xFFFFC800),
    accentDeep: Color(0xFF4D3D00),
    background: Color(0xFF000000),
    backgroundTop: Color(0xFF0A0A0A),
    backgroundBottom: Color(0xFF000000),
    surface: Color(0xFF141414),
    surfaceAlt: Color(0xFF1F1F1F),
    border: Color(0xFF8A8A8E),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFB0B0B4),
    peach: Color(0xFF262626),
    peachStrong: Color(0xFF3A3A3C),
    peachWave: Color(0xFF2C2C2E),
    cinnamon: Color(0xFFFFC800),
    switchOff: Color(0xFF3A3A3C),
    onAccent: Color(0xFF000000),
    onPeach: Color(0xFFF2F2F2),
    onPeachLabel: Color(0xFFFFC800),
    onPeachMuted: Color(0xFFB0B0B4),
    waveAhead: Color(0xFF6E6E73),
  );

  /// Svi izgledi, redom kojim stoje u konzoli.
  static const List<AppSkin> all = [
    safir,
    zuta,
    neon,
    zelena,
    rozeCrna,
    zutoCrna,
  ];

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
    AppColors.onAccent = onAccent;
    AppColors.onPeach = onPeach ?? textPrimary;
    AppColors.onPeachLabel = onPeachLabel ?? cinnamon;
    AppColors.onPeachMuted = onPeachMuted ?? textSecondary;
    AppColors.waveAhead = waveAhead ?? accent;
    AppColors.isDark = dark;
    // Ekrani bez gornje trake (spisak događaja, stranice događaja) uzimaju
    // ovo, ne temu — inače bi na crnoj podlozi ikonice sata i baterije
    // ostale crne i nestale.
    // Donja sistemska traka (dugmad za nazad i početni ekran) ide u boju
    // podloge — inače na crnoj podlozi ostane svetlo siva pruga.
    SystemChrome.setSystemUIOverlayStyle(
      (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: background,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
    );
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
    final brightness = AppColors.isDark ? Brightness.dark : Brightness.light;
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
    ).copyWith(brightness: brightness);

    const pill = StadiumBorder();

    return ThemeData(
      brightness: brightness,
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
        // Tamne ikonice u statusnoj traci — na svetloj podlozi bele se ne
        // vide. Na tamnoj (Neon zelena) obrnuto.
        systemOverlayStyle: AppColors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
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
