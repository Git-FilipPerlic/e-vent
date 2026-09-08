import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../services/mock_event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/home/event_title.dart';
import '../widgets/home/organizer_name.dart';
import '../widgets/home/organizer_phone.dart';

/// Home tab — priprema i polazak na događaj.
///
/// Ekran je jedini koji priča sa servisom; widgeti ispod njega dobijaju
/// gotove podatke kroz konstruktor.
///
/// Elementi se dodaju redom po spisku iz `CLAUDE.md`:
/// naziv (HOME-001) → organizator (HOME-002) → telefon (HOME-004) → adresa → datum → sat →
/// polazak → vozilo → učesnici → status → podsetnik → scenario.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Jedino mesto gde se bira izvor podataka. Kad se priključi Firebase,
  /// menja se samo ova linija — nijedan widget se ne dira.
  final EventService _service = MockEventService();

  /// Za sada se uvek učitava isti test događaj, kao u ranijoj verziji
  /// aplikacije. Kasnije će ga birati prijavljeni korisnik.
  static const String _eventId = 'evt-001';

  Event? _event;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final event = await _service.loadEvent(_eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Podaci o događaju nisu učitani.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return ErrorRetry(message: errorMessage, onRetry: _loadEvent);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        EventTitle(title: _event?.title),
        OrganizerName(name: _event?.organizerName),
        OrganizerPhone(phone: _event?.organizerPhone),
      ],
    );
  }
}
