import 'package:flutter/material.dart';

import '../models/checklist.dart';
import '../models/event.dart';
import '../models/team.dart';
import '../models/vehicle.dart';
import '../models/weather.dart';
import '../services/event_service.dart';
import '../services/route_service.dart';
import '../services/auth_service.dart';
import '../services/mock_event_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/edit_text_sheet.dart';
import '../widgets/common/event_when_sheet.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/home/event_address.dart';
import '../widgets/home/event_categories.dart';
import '../widgets/home/departure_time.dart';
import '../widgets/home/data_readiness.dart';
import '../widgets/home/event_reminder.dart';
import '../widgets/home/event_status_banner.dart';
import '../widgets/home/event_weather.dart';
import '../widgets/home/event_title.dart';
import '../widgets/home/organizer_name.dart';
import '../widgets/home/organizer_phone.dart';
import '../widgets/home/participants_list.dart';
import '../widgets/home/scenario_list.dart';
import '../widgets/home/team_assignment.dart';
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
  const HomeScreen({
    super.key,
    this.eventId = 'evt-001',
    this.auth,
    this.service,
    this.route,
    this.onExit,
  });

  /// Izvor podataka. `null` znači sopstveni mock — tako testovi mogu da
  /// podignu ekran sam, ali u aplikaciji ga **deli sa spiskom događaja**,
  /// inače spisak ne vidi izmene napravljene ovde.
  final EventService? service;

  /// Računa put od magacina do događaja.
  ///
  /// `null` znači **bez računanja puta** — tako ekran u testu ne ide na
  /// mrežu. Aplikacija ga uvek prosleđuje; podrazumevano se ne pravi sam,
  /// jer mrežni poziv ne sme da se desi slučajno.
  final RouteService? route;

  /// Koji se događaj prikazuje. Bira se na spisku događaja.
  final String eventId;

  /// Ko je prijavljen. Bez prijave su kartice samo za čitanje.
  final AuthService? auth;

  /// Izlazak nazad na spisak događaja. `null` kad ekran stoji sam
  /// (u testu), pa se dugme ne crta.
  final VoidCallback? onExit;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final EventService _service = widget.service ?? MockEventService();

  /// Put do događaja ide preko OpenStreetMap-a — bez naloga i ključa.
  RouteService? get _route => widget.route;

  /// Koliko se vozi od magacina. `null` dok se ne izračuna ili kad
  /// adresa magacina nije uneta.
  RouteEstimate? _drive;

  /// Prognoza dolazi sa Open-Meteo servisa — besplatan, bez API ključa.
  final WeatherService _weather = OpenMeteoWeatherService();

  Event? _event;
  List<Vehicle> _vehicles = const [];

  /// Sve kategorije opreme koje firma ima — iz njih manager bira.
  List<ChecklistSection> _catalog = const [];

  EventForecast? _forecast;
  bool _isForecastLoading = false;
  String? _forecastError;

  /// Tačke scenarija koje je korisnik sam dodao. Za sada žive samo dok traje
  /// ekran — trajno čuvanje ide uz bazu.
  final List<String> _addedScenario = [];
  bool _isLoading = true;
  String? _errorMessage;

  /// Da li prijavljeni korisnik sme da menja podatke o događaju.
  bool get _canEdit =>
      widget.auth?.can(AppPermission.editEvent) ?? false;

  @override
  void initState() {
    super.initState();
    // Prijava i odjava menjaju kartice iz čitanja u unos i nazad.
    widget.auth?.addListener(_onAuthChanged);
    _loadEvent();
  }

  void _onAuthChanged() => setState(() {});

  @override
  void dispose() {
    widget.auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Otvara unos jednog podatka i čuva izmenu.
  ///
  /// Izmena se odmah vidi, a upis ide u pozadini; ako upis pukne, stanje se
  /// vraća i javi porukom, da ekran ne laže. Isto kao kod izbora vozila.
  Future<void> _editField({
    required String label,
    required String? value,
    required Event Function(Event event, String text) apply,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) async {
    final event = _event;
    if (event == null) return;

    final text = await showEditTextSheet(
      context,
      label: label,
      value: value,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
    // Korisnik je odustao.
    if (text == null) return;
    if (!mounted) return;

    await _saveEdited(apply(event, text), previous: event);
  }

  /// Upisuje izmenjen događaj: prvo na ekran, pa u servis.
  ///
  /// Ako upis pukne, vraća se staro stanje i javi porukom — bolje nego da
  /// korisnik ostane sa podatkom koji misli da je sačuvan.
  Future<void> _saveEdited(Event updated, {required Event previous}) async {
    setState(() => _event = updated);

    try {
      await _service.saveEvent(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _event = previous);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Izmena nije sačuvana.')),
        );
    }
  }

  /// Datum, sat početka i trajanje — sve troje kroz jedan list.
  Future<void> _editWhen() async {
    final event = _event;
    if (event == null) return;

    final picked = await showEventWhenSheet(
      context,
      value: EventWhen(
        start: event.eventDate,
        durationMinutes: event.durationMinutes,
      ),
    );
    if (picked == null) return;
    if (!mounted) return;

    await _saveEdited(
      event.copyWith(
        eventDate: picked.start,
        durationMinutes: picked.durationMinutes,
      ),
      previous: event,
    );
  }

  /// Vreme polaska. Dan se uzima od događaja — polazi se na dan nastupa.
  Future<void> _editDeparture() async {
    final event = _event;
    if (event == null) return;

    final current = event.departureTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay(hour: current.hour, minute: current.minute)
          : const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked == null) return;
    if (!mounted) return;

    final day = current ?? event.eventDate ?? DateTime.now();
    await _saveEdited(
      event.copyWith(
        departureTime: DateTime(
          day.year,
          day.month,
          day.day,
          picked.hour,
          picked.minute,
        ),
      ),
      previous: event,
    );
  }

  /// Kome je događaj dodeljen — „share" iz „create and share".
  Future<void> _editAssignment() async {
    final event = _event;
    if (event == null) return;

    // Uz imena stižu i veštine: po njima se u listu sužava spisak na one
    // koji traženo umeju.
    List<TeamMember> team;
    List<Skill> skills;
    try {
      team = await _service.loadTeam();
      skills = await _service.loadSkills();
    } catch (_) {
      team = const [];
      skills = const [];
    }
    if (!mounted) return;

    final picked = await showAssignPicker(
      context,
      team: team,
      skills: skills,
      assignedTo: event.assignedTo,
    );
    if (picked == null) return;
    if (!mounted) return;

    await _saveEdited(event.copyWith(assignedTo: picked), previous: event);
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
        _service.loadEvent(widget.eventId),
        _service.loadVehicles(),
        _service.loadChecklistTemplate(),
      ]);
      if (!mounted) return;
      final event = results[0] as Event;
      setState(() {
        _event = event;
        _vehicles = results[1] as List<Vehicle>;
        _catalog = results[2] as List<ChecklistSection>;
        _isLoading = false;
      });
      // Prognoza se učitava odvojeno: ekran se ne čeka zbog mreže, a ako
      // prognoza pukne, ostatak podataka i dalje stoji.
      _loadForecast(event);
      _loadDrive(event);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Podaci o događaju nisu učitani.';
        _isLoading = false;
      });
    }
  }

  /// Koliko se vozi od magacina do adrese događaja.
  ///
  /// Računa se **od magacina**, ne od trenutne lokacije telefona (odluka od
  /// 27. septembra 2026): ekipa kreće po opremu, pa je taj broj tačniji, a
  /// aplikaciji ne treba dozvola za lokaciju.
  ///
  /// Kad bilo šta zafali — adresa magacina, adresa događaja, mreža — kartica
  /// ostaje kakva jeste. Vreme vožnje je dopuna, ne uslov za rad.
  Future<void> _loadDrive(Event event) async {
    final route = _route;
    if (route == null) return;

    try {
      final settings = await _service.loadSettings();
      if (!settings.hasAddress) return;

      final GeoPoint from;
      if (settings.hasCoordinates) {
        from = GeoPoint(settings.baseLatitude!, settings.baseLongitude!);
      } else {
        from = await route.locate(settings.baseAddress!);
        // Pronađena tačka se pamti, da se adresa ne traži pri svakom
        // otvaranju događaja.
        if (_canEdit) {
          await _service.saveSettings(
            settings.copyWith(
              baseLatitude: from.latitude,
              baseLongitude: from.longitude,
            ),
          );
        }
      }

      final GeoPoint to;
      if (event.hasCoordinates) {
        to = GeoPoint(event.latitude!, event.longitude!);
      } else {
        final address = event.address?.trim() ?? '';
        if (address.isEmpty) return;
        to = await route.locate(address);
        if (_canEdit) {
          await _service.saveEvent(
            event.copyWith(latitude: to.latitude, longitude: to.longitude),
          );
        }
      }

      final estimate = await route.drive(from: from, to: to);
      if (!mounted) return;
      setState(() => _drive = estimate);
    } catch (_) {
      // Bez puta kartica prikazuje samo vreme polaska.
    }
  }

  /// Prognoza za sate u kojima nastup traje.
  ///
  /// Bez koordinata ili bez datuma nema šta da se traži — kartica tada sama
  /// kaže da prognoze nema.
  Future<void> _loadForecast(Event event) async {
    final start = event.eventDate;
    if (!event.hasCoordinates || start == null) {
      setState(() {
        _forecast = null;
        _forecastError = 'Bez adrese i datuma nema prognoze.';
        _isForecastLoading = false;
      });
      return;
    }

    setState(() {
      _isForecastLoading = true;
      _forecastError = null;
    });

    try {
      final forecast = await _weather.forRange(
        latitude: event.latitude!,
        longitude: event.longitude!,
        start: start,
        end: event.endsAt ?? start,
      );
      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _isForecastLoading = false;
      });
    } on WeatherUnavailableException catch (e) {
      if (!mounted) return;
      setState(() {
        _forecast = null;
        _forecastError = 'Prognoza nije dostupna (${e.reason}).';
        _isForecastLoading = false;
      });
    }
  }

  /// Otvara izbor kategorija opreme i pamti ga.
  Future<void> _editCategories() async {
    final event = _event;
    if (event == null) return;

    final chosen = await showCategoryPicker(
      context,
      catalog: _catalog,
      selectedIds: event.categoryIds,
    );
    // Korisnik je odustao.
    if (chosen == null) return;
    if (!mounted) return;

    final updated = event.copyWith(categoryIds: chosen);
    setState(() => _event = updated);

    try {
      await _service.saveEvent(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _event = event);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Izbor kategorija nije sačuvan.')),
        );
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
      await _service.setEventVehicle(widget.eventId, vehicleId);
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
    final onExit = widget.onExit;
    return Scaffold(
      body: Column(
        children: [
          // Umesto headera stoji jedno jedino dugme — izlazak nazad na spisak
          // događaja (odluka od 27. septembra 2026). Header je nosio logotip i
          // ulaz u konzolu, ali ih je nosio na svim stranicama i trošio visinu;
          // ostale stranice ga više nemaju, pa ga nema ni ova.
          if (onExit != null)
            Align(
              alignment: Alignment.centerLeft,
              // Strelica dobija tačno onoliko prostora koliko joj treba:
              // pojas u kom je stajao ceo header je za jedno dugme bio
              // prazna siva zona.
              child: IconButton(
                onPressed: onExit,
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                constraints: const BoxConstraints.tightFor(height: 32),
                tooltip: 'Nazad na spisak događaja',
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
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
            type: _event?.type,
            onEditWhen: !_canEdit ? null : _editWhen,
            onEdit: !_canEdit
                ? null
                : () => _editField(
                    label: 'Naziv događaja',
                    value: _event?.title,
                    apply: (event, text) => event.copyWith(title: text),
                  ),
          ),
          OrganizerName(
            name: _event?.organizerName,
            onEdit: !_canEdit
                ? null
                : () => _editField(
                    label: 'Organizator',
                    value: _event?.organizerName,
                    apply: (event, text) => event.copyWith(organizerName: text),
                  ),
          ),
          OrganizerPhone(
            phone: _event?.organizerPhone,
            onEdit: !_canEdit
                ? null
                : () => _editField(
                    label: 'Telefon organizatora',
                    value: _event?.organizerPhone,
                    keyboardType: TextInputType.phone,
                    apply: (event, text) =>
                        event.copyWith(organizerPhone: text),
                  ),
          ),
          EventAddress(
            address: _event?.address,
            latitude: _event?.latitude,
            longitude: _event?.longitude,
            onEdit: !_canEdit
                ? null
                : () => _editField(
                    label: 'Adresa',
                    value: _event?.address,
                    maxLines: 2,
                    apply: (event, text) => event.copyWith(address: text),
                  ),
          ),
          EventWeather(
            weather: _forecast,
            isLoading: _isForecastLoading,
            errorMessage: _forecastError,
            onRetry: _event == null ? null : () => _loadForecast(_event!),
          ),
          DepartureTime(
            departure: _event?.departureTime,
            travelMinutes: _event?.travelDurationMinutes,
            drive: _drive,
            eventStart: _event?.eventDate,
            onEdit: !_canEdit ? null : _editDeparture,
          ),
          VehiclePicker(
            vehicles: _vehicles,
            selectedVehicleId: _event?.vehicleId,
            onSelected: _selectVehicle,
            onAdd: _addVehicle,
            // Vozilo bira manager; bez prijave se samo vidi koje je izabrano.
            canEdit: _canEdit,
          ),
          EventCategories(
            catalog: _catalog,
            selectedIds: _event?.categoryIds ?? const [],
            onEdit: _canEdit ? _editCategories : null,
          ),
          TeamAssignment(
            assignedTo: _event?.assignedTo ?? const [],
            onEdit: _canEdit ? _editAssignment : null,
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
