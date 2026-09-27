import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';

import 'screens/equipment_screen.dart';
import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lager_screen.dart';
import 'screens/led_screen.dart';
import 'screens/music_screen.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_event_service.dart';
import 'services/mock_event_service.dart';
import 'services/background_audio.dart';
import 'services/team_logo_service.dart';
import 'theme/app_theme.dart';
import 'utils/date_format.dart';
import 'widgets/common/app_header.dart';
import 'widgets/common/page_dots.dart';

/// Koren aplikacije: tema i navigacija sa 4 taba.
class EventApp extends StatelessWidget {
  const EventApp({super.key, this.audioHandler, this.hasFirebase = false});

  /// Veza sa notifikacijom i kontrolama van aplikacije.
  /// `null` u testovima, gde servis ne postoji.
  final BackgroundAudioHandler? audioHandler;

  /// Da li se Firebase podigao. Kad nije, aplikacija radi sa lokalnim
  /// podacima — bolje nego da uopšte ne krene.
  final bool hasFirebase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-vent',
      debugShowCheckedModeBanner: false,
      // Aplikacija je na srpskom, pa i sistemski dijalozi moraju da budu.
      // Bez ovih prevoda biranje datuma ne radi — `showDatePicker` traži
      // `MaterialLocalizations` za jezik koji mu se zada.
      locale: AppDate.locale2,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
        Locale('sr'),
        Locale('en'),
      ],
      // Aplikacija je svetla, bez obzira na podešavanje telefona
      // (odluka od 25. septembra 2026 — ranije je bila samo tamna).
      theme: AppTheme.light,
      home: RootNavigation(
        audioHandler: audioHandler,
        hasFirebase: hasFirebase,
      ),
    );
  }
}

/// Header sa logotipom, ispod njega tabovi, pa sadržaj.
///
/// Header i tabovi se **sklanjaju pri skrolovanju nadole** i vraćaju čim se
/// krene nagore — tako spisak (numere, oprema) dobije oko 150 dp više, a
/// tabovi su na dohvat jednim pokretom.
///
/// Stanje je običan [setState] — bez Riverpod-a/Provider-a u MVP fazi.
class RootNavigation extends StatefulWidget {
  const RootNavigation({
    super.key,
    this.audioHandler,
    this.hasFirebase = false,
  });

  final BackgroundAudioHandler? audioHandler;

  /// Da li je Firebase dostupan.
  final bool hasFirebase;

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  /// Jedina mesta gde se biraju servisi. Kad stigne pravi login i baza,
  /// menjaju se ove dve linije.
  /// Ko je prijavljen. Bez prijave aplikacija radi, samo se ništa ne menja.
  /// **Jedino mesto gde se biraju izvori podataka.**
  ///
  /// Kad je Firebase podignut, radi se sa pravom bazom i pravom prijavom; kad
  /// nije (nema mreže pri prvom pokretanju), aplikacija se i dalje otvara sa
  /// lokalnim podacima. Ekrani razliku ne vide — oba servisa poštuju isti
  /// interfejs, i zbog toga je ovde jedna linija umesto prepravke aplikacije.
  late final AuthService _auth = widget.hasFirebase
      ? FirebaseAuthService()
      : MockAuthService();

  /// Spisak, Home i Lager dele isti servis — inače svaki ekran ima svoje
  /// podatke, pa izmena napravljena na Home tabu ne stigne do spiska.
  late final EventService _events = widget.hasFirebase
      ? FirestoreEventService()
      : MockEventService();
  final TeamLogoService _logoService = const TeamLogoService();

  final ImagePicker _picker = ImagePicker();

  int _currentIndex = 0;
  String? _logoPath;

  /// Koji je događaj otvoren. `null` znači da još nijedan nije biran.
  ///
  /// Pamti se i pošto se izađe na spisak, da bi tabovi zadržali stanje —
  /// samo [_inEvent] kaže da li se gleda spisak ili sam događaj.
  String? _eventId;

  /// Da li su otvoreni tabovi jednog događaja (`false` = spisak događaja).
  bool _inEvent = false;

  /// Kucne kad se treba vratiti na spisak, da se podaci ponovo učitaju —
  /// događaj je u međuvremenu mogao da se izmeni.
  final ValueNotifier<int> _eventsRevision = ValueNotifier<int>(0);

  /// Kucne kad se otvori Lager tab, da ponovo pročita kategorije događaja.
  /// One se biraju na Home tabu, a Lager sve vreme stoji u stablu.
  final ValueNotifier<int> _lagerRevision = ValueNotifier<int>(0);

  /// Nazivi stranica, redom. Ne ispisuju se nigde — traka sa dugmadima
  /// je otpala kad se prešlo na prevlačenje — ali ih čitač ekrana
  /// izgovara uz tačkice.
  static const List<String> _pageLabels = ['Home', 'Muzika', 'LED', 'Lager'];

  /// Stranice jednog događaja. Prevlačenjem se ide s leva na desno;
  /// sve stoje u stablu, da muzika ne stane kad se ode na Lager.
  final PageController _pages = PageController();

  @override
  void initState() {
    super.initState();
    // Prijava i odjava menjaju ceo ekran — kartice iz čitanja prelaze u unos.
    _auth.addListener(_onAuthChanged);
    _loadLogo();
  }

  void _onAuthChanged() => setState(() {});

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    _eventsRevision.dispose();
    _lagerRevision.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Spisak opreme cele firme — odatle se prave kategorije koje se posle
  /// biraju po događaju.
  Future<void> _openEquipment() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EquipmentScreen(service: _events)),
    );
  }

  /// Otvara prijavu, odnosno konzolu kad je neko već prijavljen.
  ///
  /// Tu su i logotip i odjava — na glavnoj strani su tri ikonice prekrivale
  /// baner, a te se stvari diraju retko.
  Future<void> _openConsole() async {
    final canEditLogo = _auth.can(AppPermission.editTeamLogo);

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          auth: _auth,
          hasLogo: _logoPath != null,
          onEditLogo: canEditLogo ? _pickLogo : null,
          onRemoveLogo: canEditLogo && _logoPath != null ? _removeLogo : null,
          onOpenEquipment: _auth.can(AppPermission.editEvent)
              ? _openEquipment
              : null,
        ),
      ),
    );
  }

  Future<void> _loadLogo() async {
    final path = await _logoService.load();
    if (!mounted) return;
    setState(() => _logoPath = path);
  }

  /// Bira sliku iz galerije i pamti je kao logotip tima.
  Future<void> _pickLogo() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        // Logotip stoji na 52 dp visine — veća slika bi samo trošila
        // memoriju i vreme učitavanja.
        maxWidth: 1024,
        maxHeight: 1024,
      );
      // Korisnik je odustao — ništa se ne menja i ništa se ne javlja.
      if (picked == null) return;

      // Slika se kopira u folder aplikacije; pamti se ta kopija, ne
      // privremeni fajl koji Android obriše.
      final saved = await _logoService.save(picked.path);
      if (!mounted) return;
      if (saved == null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Logotip nije sačuvan.')),
          );
        return;
      }
      setState(() => _logoPath = saved);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Logotip nije učitan.')));
    }
  }

  Future<void> _removeLogo() async {
    await _logoService.clear();
    if (!mounted) return;
    setState(() => _logoPath = null);
  }

  /// Redni broj Lager stranice.
  static const int _lagerPage = 3;

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // Oprema se bira na Home stranici; Lager mora da je pročita ponovo
    // kad se otvori, inače pokazuje ono što je zatekao pri prvom
    // otvaranju.
    if (index == _lagerPage) _lagerRevision.value++;
  }

  /// Otvara događaj: tabovi od sada pokazuju baš njegove podatke.
  void _openEvent(String eventId) {
    setState(() {
      _eventId = eventId;
      _inEvent = true;
      _currentIndex = 0;
    });
    // Svaki događaj se otvara na prvoj stranici, ma gde stao prethodni.
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  /// Nazad na spisak. Muzika se **ne prekida** — plejer ostaje u stablu,
  /// pa nastup ne stane zato što je neko pogledao raspored.
  void _backToList() {
    setState(() {
      _inEvent = false;
    });
    // Spisak je sve vreme stajao u stablu sa starim podacima.
    _eventsRevision.value++;
  }


  @override
  Widget build(BuildContext context) {
    final path = _logoPath;
    final eventId = _eventId;
    final user = _auth.currentUser;

    // Header stoji samo tamo gde nečemu služi: na spisku događaja i na prvoj
    // stranici jednog događaja, odakle se strelicom izlazi nazad na spisak
    // (odluka od 27. septembra 2026). Muzika, LED i Lager ga nemaju — tamo je
    // samo trošio visinu, a pri skrolovanju je nestajao i vraćao se, pa se
    // spisak numera pod prstom preraspodeljivao. Izvođači su se žalili da ih
    // to dezorijentiše.
    final showHeader = !_inEvent || _currentIndex == 0;

    return Scaffold(
      body: Column(
        children: [
          if (showHeader)
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  AppHeader(
                    logo: path != null ? FileImage(File(path)) : null,
                    signedInAs: user?.name,
                    onOpenConsole: _openConsole,
                    onBack: _inEvent ? _backToList : null,
                  ),
                  // Na spisku događaja tačkica nema — stranice pripadaju
                  // jednom događaju, a tada nijedan nije otvoren.
                  if (_inEvent)
                    PageDots(
                      count: _pageLabels.length,
                      currentIndex: _currentIndex,
                      labels: _pageLabels,
                    ),
                ],
              ),
            ),
            Expanded(
              // Sadržaj ne sme da upadne pod sistemsku traku sa gestovima,
              // a gore mora da ga zakloni statusna traka kad headera nema.
              child: SafeArea(
                top: !showHeader,
                child: IndexedStack(
                  // Spisak događaja i stranice jednog događaja stoje jedno
                  // pored drugog. Oboje ostaje u stablu: muzika ne prestaje
                  // dok se bira drugi događaj, a spisak ne gubi svoje mesto.
                  index: _inEvent ? 1 : 0,
                  children: [
                    EventsScreen(
                      auth: _auth,
                      service: _events,
                      onOpen: _openEvent,
                      reloadSignal: _eventsRevision,
                    ),
                    // Između stranica se **prevlači** (odluka od 26.
                    // septembra 2026). Svaka je `_KeepAlivePage`, jer
                    // `PageView` inače ukloni stranicu koja nije uz
                    // trenutnu — a sa Muzika stranicom bi otišao i plejer,
                    // pa bi muzika stala čim se ode na Lager.
                    PageView(
                      controller: _pages,
                      onPageChanged: _onPageChanged,
                      children: [
                        // Ključ po događaju: kad se otvori drugi, ekran se
                        // gradi iz početka umesto da prikaže tuđe podatke.
                        _KeepAlivePage(
                          child: eventId == null
                              ? const SizedBox.shrink()
                              : HomeScreen(
                                  key: ValueKey('home-$eventId'),
                                  eventId: eventId,
                                  auth: _auth,
                                  service: _events,
                                ),
                        ),
                        _KeepAlivePage(
                          child: MusicScreen(audioHandler: widget.audioHandler),
                        ),
                        const _KeepAlivePage(child: LedScreen()),
                        _KeepAlivePage(
                          child: eventId == null
                              ? const SizedBox.shrink()
                              : LagerScreen(
                                  key: ValueKey('lager-$eventId'),
                                  eventId: eventId,
                                  auth: _auth,
                                  service: _events,
                                  reloadSignal: _lagerRevision,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stranica koja ostaje u stablu i kad se sa nje ode.
///
/// `PageView` čuva samo susedne stranice. Bez ovoga bi odlazak sa Muzike na
/// Lager ugasio plejer — a reprodukcija pripada Muzika stranici i ne sme da
/// stane zato što je neko proverio opremu.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
