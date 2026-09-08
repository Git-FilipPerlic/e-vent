import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/vehicle.dart';
import '../services/event_service.dart';
import '../services/mock_event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/home/event_address.dart';
import '../widgets/home/departure_time.dart';
import '../widgets/home/data_readiness.dart';
import '../widgets/home/event_reminder.dart';
import '../widgets/home/event_status_banner.dart';
import '../widgets/home/event_title.dart';
import '../widgets/home/organizer_name.dart';
import '../widgets/home/organizer_phone.dart';
import '../widgets/home/participants_list.dart';
import '../widgets/home/scenario_list.dart';
import '../widgets/home/team_status.dart';
import '../widgets/home/vehicle_picker.dart';

/// Home tab — priprema i polazak na događaj.
///
/// Ekran je jedini koji priča sa servisom; widgeti ispod njega dobijaju
/// gotove podatke kroz konstruktor.
///
/// Elementi se dodaju redom po spisku iz `CLAUDE.md`:
/// naziv sa datumom, satom i trajanjem (HOME-001/005) → organizator (HOME-002) → telefon (HOME-004) → adresa (HOME-003) → polazak (HOME-007) → vozilo → učesnici (HOME-012) → status tima (HOME-013) → spremnost (HOME-011) →
/// status događaja (HOME-018) → podsetnik (HOME-019) → scenario (HOME-025).
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
  List<Vehicle> _vehicles = const [];

  /// Tačke scenarija koje je korisnik sam dodao. Za sada žive samo dok traje
  /// ekran — trajno čuvanje ide uz bazu.
  final List<String> _addedScenario = [];
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
      // Događaj i spisak vozila stižu uporedo — nema razloga da se čeka
      // jedno pa drugo.
      final results = await Future.wait([
        _service.loadEvent(_eventId),
        _service.loadVehicles(),
      ]);
      if (!mounted) return;
      setState(() {
        _event = results[0] as Event;
        _vehicles = results[1] as List<Vehicle>;
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

  /// Izabrano vozilo se odmah vidi na ekranu, a upis ide u pozadini —
  /// korisnik ne čeka da bi video šta je izabrao.
  Future<void> _selectVehicle(String vehicleId) async {
    final event = _event;
    if (event == null) return;

    final previous = event.vehicleId;
    setState(() => _event = event.withVehicle(vehicleId));

    try {
      await _service.setEventVehicle(_eventId, vehicleId);
    } catch (_) {
      if (!mounted) return;
      // Upis nije prošao — vraća se staro stanje, da ekran ne laže.
      setState(() => _event = event.withVehicle(previous));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Izbor vozila nije sačuvan.')),
        );
    }
  }

  /// Novo vozilo se doda u spisak i odmah postaje izabrano.
  Future<void> _addVehicle(String name) async {
    try {
      final vehicle = await _service.addVehicle(name);
      if (!mounted) return;
      setState(() => _vehicles = [..._vehicles, vehicle]);
      await _selectVehicle(vehicle.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Vozilo nije dodato.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

    final participants = _event?.participants ?? const <Participant>[];

    return RefreshIndicator(
      onRefresh: _loadEvent,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: ListView(
        // `always` da povlačenje nadole radi i kad je spisak kraći od ekrana.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          EventTitle(
            title: _event?.title,
            date: _event?.eventDate,
            durationMinutes: _event?.durationMinutes,
          ),
          OrganizerName(name: _event?.organizerName),
          OrganizerPhone(phone: _event?.organizerPhone),
          EventAddress(
            address: _event?.address,
            latitude: _event?.latitude,
            longitude: _event?.longitude,
          ),
          DepartureTime(
            departure: _event?.departureTime,
            travelMinutes: _event?.travelDurationMinutes,
          ),
          VehiclePicker(
            vehicles: _vehicles,
            selectedVehicleId: _event?.vehicleId,
            onSelected: _selectVehicle,
            onAdd: _addVehicle,
          ),
          ParticipantsList(participants: participants),
          TeamStatus(participants: participants),
          DataReadiness(event: _event),
          EventStatusBanner(
            departure: _event?.departureTime,
            eventStart: _event?.eventDate,
            eventEnd: _event?.endsAt,
          ),
          EventReminder(
            departure: _event?.departureTime,
            eventStart: _event?.eventDate,
          ),
          ScenarioList(
            items: _event?.scenario ?? const [],
            addedItems: _addedScenario,
            onAdd: (text) => setState(() => _addedScenario.add(text)),
            onRemoveAdded: (index) =>
                setState(() => _addedScenario.removeAt(index)),
          ),
        ],
      ),
    );
  }
}
