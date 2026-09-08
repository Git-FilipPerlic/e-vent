import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'screens/home_screen.dart';
import 'screens/lager_screen.dart';
import 'screens/led_screen.dart';
import 'screens/music_screen.dart';
import 'services/auth_service.dart';
import 'services/team_logo_service.dart';
import 'theme/app_theme.dart';
import 'widgets/common/app_header.dart';

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

/// Donja navigacija sa 4 taba i zajednički header iznad njih.
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

  // IndexedStack čuva stanje svakog taba pri prebacivanju
  // (npr. plejer u Muzici ostaje kako je bio).
  static const List<Widget> _tabs = [
    HomeScreen(),
    MusicScreen(),
    LedScreen(),
    LagerScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.music_note_outlined),
      selectedIcon: Icon(Icons.music_note),
      label: 'Muzika',
    ),
    NavigationDestination(
      icon: Icon(Icons.lightbulb_outline),
      selectedIcon: Icon(Icons.lightbulb),
      label: 'LED',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'Lager',
    ),
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
        // Logotip stoji na 32 dp visine — velika slika bi samo trošila
        // memoriju i vreme učitavanja.
        maxWidth: 512,
        maxHeight: 512,
      );
      // Korisnik je odustao — ništa se ne menja i ništa se ne javlja.
      if (picked == null) return;

      await _logoService.save(picked.path);
      if (!mounted) return;
      setState(() => _logoPath = picked.path);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Logotip nije učitan.')),
        );
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

  @override
  Widget build(BuildContext context) {
    final path = _logoPath;
    // Menjanje logotipa traži prijavu — to je funkcija managementa.
    final canEditLogo = _auth.can(Permission.editTeamLogo);

    return Scaffold(
      appBar: AppHeader(
        logo: path != null ? FileImage(File(path)) : null,
        onEditLogo: canEditLogo ? _pickLogo : null,
        onRemoveLogo: canEditLogo && path != null ? _removeLogo : null,
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: _destinations,
      ),
    );
  }
}
