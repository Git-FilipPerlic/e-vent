import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lager_screen.dart';
import 'screens/led_screen.dart';
import 'screens/music_screen.dart';
import 'services/auth_service.dart';
import 'services/background_audio.dart';
import 'services/team_logo_service.dart';
import 'theme/app_theme.dart';
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
  final TeamLogoService _logoService = const TeamLogoService();

  final ImagePicker _picker = ImagePicker();

  int _currentIndex = 0;
  String? _logoPath;

  /// Da li se header i tabovi trenutno vide.
  bool _chromeVisible = true;

  // IndexedStack čuva stanje svakog taba pri prebacivanju
  // (npr. plejer u Muzici ostaje kako je bio).
  late final List<Widget> _tabs = [
    const HomeScreen(),
    MusicScreen(audioHandler: widget.audioHandler),
    const LedScreen(),
    const LagerScreen(),
  ];

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

      await _logoService.save(picked.path);
      if (!mounted) return;
      setState(() => _logoPath = picked.path);
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
                          ),
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
                child: IndexedStack(index: _currentIndex, children: _tabs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
