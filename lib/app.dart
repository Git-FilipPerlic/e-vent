import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'screens/home_screen.dart';
import 'screens/lager_screen.dart';
import 'screens/led_screen.dart';
import 'screens/music_screen.dart';
import 'services/auth_service.dart';
import 'services/team_logo_service.dart';
import 'theme/app_theme.dart';
import 'widgets/common/app_header.dart';
import 'widgets/common/top_tab_bar.dart';

/// Koren aplikacije: tema i navigacija sa 4 taba.
class EventApp extends StatelessWidget {
  const EventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-vent',
      debugShowCheckedModeBanner: false,
      // Aplikacija je samo tamna, bez obzira na podešavanje telefona.
      theme: AppTheme.dark,
      home: const RootNavigation(),
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
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  /// Jedina mesta gde se biraju servisi. Kad stigne pravi login i baza,
  /// menjaju se ove dve linije.
  final AuthService _auth = const MockAuthService();
  final TeamLogoService _logoService = const TeamLogoService();

  final ImagePicker _picker = ImagePicker();

  int _currentIndex = 0;
  String? _logoPath;

  /// Da li se header i tabovi trenutno vide.
  bool _chromeVisible = true;

  // IndexedStack čuva stanje svakog taba pri prebacivanju
  // (npr. plejer u Muzici ostaje kako je bio).
  static const List<Widget> _tabs = [
    HomeScreen(),
    MusicScreen(),
    LedScreen(),
    LagerScreen(),
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
    _loadLogo();
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
    final canEditLogo = _auth.can(Permission.editTeamLogo);

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
