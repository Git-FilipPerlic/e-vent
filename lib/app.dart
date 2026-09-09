import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';

import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lager_screen.dart';
import 'screens/led_screen.dart';
import 'screens/music_screen.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/mock_event_service.dart';
import 'services/background_audio.dart';
import 'services/team_logo_service.dart';
import 'theme/app_theme.dart';
import 'utils/date_format.dart';
import 'widgets/common/app_header.dart';
import 'widgets/common/top_tab_bar.dart';

/// Koren aplikacije: tema i navigacija sa 4 taba.
class EventApp extends StatelessWidget {
  const EventApp({super.key, this.audioHandler});

  /// Veza sa notifikacijom i kontrolama van aplikacije.
  /// `null` u testovima, gde servis ne postoji.
  final BackgroundAudioHandler? audioHandler;

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
      // Aplikacija je samo tamna, bez obzira na podešavanje telefona.
      theme: AppTheme.dark,
      home: RootNavigation(audioHandler: audioHandler),
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
  const RootNavigation({super.key, this.audioHandler});

  final BackgroundAudioHandler? audioHandler;

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  /// Jedina mesta gde se biraju servisi. Kad stigne pravi login i baza,
  /// menjaju se ove dve linije.
  /// Ko je prijavljen. Bez prijave aplikacija radi, samo se ništa ne menja.
  final AuthService _auth = MockAuthService();

  /// **Jedino mesto gde se bira izvor podataka.** Spisak, Home i Lager dele
  /// isti servis — inače svaki ekran ima svoje podatke, pa izmena napravljena
  /// na Home tabu ne stigne do spiska.
  final EventService _events = MockEventService();
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

  /// Da li se header i tabovi trenutno vide.
  bool _chromeVisible = true;

  static const List<TopTab> _destinations = [
    TopTab(label: 'Home', icon: Icons.home_rounded),
    TopTab(label: 'Muzika', icon: Icons.music_note_rounded),
    TopTab(label: 'LED', icon: Icons.lightbulb_rounded),
    TopTab(label: 'Lager', icon: Icons.checklist_rounded),
  ];

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
    super.dispose();
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(auth: _auth)),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
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

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  /// Otvara događaj: tabovi od sada pokazuju baš njegove podatke.
  void _openEvent(String eventId) {
    setState(() {
      _eventId = eventId;
      _inEvent = true;
      _currentIndex = 0;
      _chromeVisible = true;
    });
  }

  /// Nazad na spisak. Muzika se **ne prekida** — plejer ostaje u stablu,
  /// pa nastup ne stane zato što je neko pogledao raspored.
  void _backToList() {
    setState(() {
      _inEvent = false;
      _chromeVisible = true;
    });
    // Spisak je sve vreme stajao u stablu sa starim podacima.
    _eventsRevision.value++;
  }

  /// Skrolovanje nadole sklanja header i tabove, nagore ih vraća.
  bool _onScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    switch (notification.direction) {
      case ScrollDirection.reverse:
        if (_chromeVisible) setState(() => _chromeVisible = false);
      case ScrollDirection.forward:
        if (!_chromeVisible) setState(() => _chromeVisible = true);
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final path = _logoPath;
    final eventId = _eventId;
    // Menjanje logotipa traži prijavu — to je funkcija managementa.
    final canEditLogo = _auth.can(AppPermission.editTeamLogo);
    final user = _auth.currentUser;

    // Poštuje se sistemsko podešavanje za smanjen pokret.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: Column(
          children: [
            // Statusna traka ostaje zaklonjena i kad se header skloni.
            SafeArea(
              bottom: false,
              child: AnimatedSize(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _chromeVisible
                    ? Column(
                        children: [
                          AppHeader(
                            logo: path != null ? FileImage(File(path)) : null,
                            onEditLogo: canEditLogo ? _pickLogo : null,
                            onRemoveLogo: canEditLogo && path != null
                                ? _removeLogo
                                : null,
                            signedInAs: user?.name,
                            onSignIn: user == null ? _openLogin : null,
                            onSignOut: user == null ? null : _signOut,
                            onBack: _inEvent ? _backToList : null,
                          ),
                          // Na spisku događaja tabova nema — oni pripadaju
                          // jednom događaju, a tada nijedan nije otvoren.
                          if (_inEvent)
                            TopTabBar(
                              tabs: _destinations,
                              currentIndex: _currentIndex,
                              onSelected: _onTabSelected,
                            ),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
            Expanded(
              // Sadržaj ne sme da upadne pod sistemsku traku sa gestovima.
              child: SafeArea(
                top: false,
                child: IndexedStack(
                  // Nulti sloj je spisak događaja, pa tabovi. Sve stoji u
                  // stablu da bi Muzika nastavila da svira i dok se bira
                  // drugi događaj.
                  index: _inEvent ? _currentIndex + 1 : 0,
                  children: [
                    EventsScreen(
                      auth: _auth,
                      service: _events,
                      onOpen: _openEvent,
                      reloadSignal: _eventsRevision,
                    ),
                    // Ključ po događaju: kad se otvori drugi, ekran se gradi
                    // iz početka umesto da prikaže tuđe podatke.
                    eventId == null
                        ? const SizedBox.shrink()
                        : HomeScreen(
                            key: ValueKey('home-$eventId'),
                            eventId: eventId,
                            auth: _auth,
                            service: _events,
                          ),
                    MusicScreen(audioHandler: widget.audioHandler),
                    const LedScreen(),
                    eventId == null
                        ? const SizedBox.shrink()
                        : LagerScreen(
                            key: ValueKey('lager-$eventId'),
                            eventId: eventId,
                            auth: _auth,
                            service: _events,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
