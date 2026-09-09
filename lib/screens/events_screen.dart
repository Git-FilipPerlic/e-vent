import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/mock_event_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/event_grouping.dart';
import '../widgets/common/error_retry.dart';
import '../widgets/home/event_address.dart';

/// Koji spisak događaja se gleda.
enum EventScope {
  /// Događaji dodeljeni prijavljenom korisniku.
  moji('Moji'),

  /// Događaji koje je prijavljeni korisnik napravio i podelio timu.
  delegirani('Delegirani');

  const EventScope(this.label);

  final String label;
}

/// Prvi ekran aplikacije — spisak događaja.
///
/// Aplikacija se otvara sa pitanjem „koji mi je sledeći", pa je spisak
/// odgovor na to pitanje, a ne prepreka pred njim. Kad se izabere događaj,
/// otvaraju se tabovi za **taj** događaj.
///
/// Manageru isti ovaj spisak služi i kao pregled onoga što je delegirao —
/// zato prekidač, a ne poseban ekran.
class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    required this.onOpen,
    this.auth,
    this.service,
  });

  /// Poziva se sa id-jem izabranog događaja.
  final ValueChanged<String> onOpen;

  final AuthService? auth;

  /// Izvor podataka. `null` znači uobičajeni servis; testovi ubacuju svoj.
  final EventService? service;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final EventService _service = widget.service ?? MockEventService();

  List<Event> _events = const [];
  bool _isLoading = true;
  String? _errorMessage;

  EventScope _scope = EventScope.moji;

  /// Da li korisnik uopšte delegira događaje — samo njemu treba prekidač.
  bool get _canDelegate => widget.auth?.can(AppPermission.editEvent) ?? false;

  String? get _userName => widget.auth?.currentUser?.name;

  @override
  void initState() {
    super.initState();
    widget.auth?.addListener(_onAuthChanged);
    _load();
  }

  @override
  void dispose() {
    widget.auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Prijava i odjava menjaju čiji se spisak gleda, pa se učitava ponovo.
  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      if (!_canDelegate) _scope = EventScope.moji;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _userName;
      // Bez prijave se ne zna ko gleda, pa se vidi ceo spisak. Sa pravim
      // backendom to ograničava baza, ne ekran.
      final events = await _service.loadEvents(
        assignedTo: name != null && _scope == EventScope.moji ? name : null,
        createdBy: name != null && _scope == EventScope.delegirani
            ? name
            : null,
      );
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Spisak događaja nije učitan.';
        _isLoading = false;
      });
    }
  }

  void _setScope(EventScope scope) {
    if (_scope == scope) return;
    setState(() => _scope = scope);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return ErrorRetry(message: errorMessage, onRetry: _load);
    }

    final sections = groupEvents(_events, now: DateTime.now());

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          if (_canDelegate)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SegmentedButton<EventScope>(
                segments: [
                  for (final scope in EventScope.values)
                    ButtonSegment(value: scope, label: Text(scope.label)),
                ],
                selected: {_scope},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => _setScope(selection.first),
              ),
            ),
          if (sections.isEmpty)
            _EmptyList(scope: _scope, canDelegate: _canDelegate),
          for (final section in sections) ...[
            _GroupHeader(label: section.group.label),
            for (final event in section.events)
              _EventRow(event: event, onTap: () => widget.onOpen(event.id)),
          ],
        ],
      ),
    );
  }
}

/// Naslov jedne vremenske grupe.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Jedan događaj u spisku: sat, naziv, pa vrsta sa mestom i trajanjem.
///
/// Datum se ne ponavlja — nosi ga naslov grupe. Sat stoji jer je više
/// nastupa istog dana uobičajeno, pa se redosled mora videti odmah.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final date = event.eventDate;
    final duration = event.durationMinutes;
    final address = event.address;
    final city = address == null ? null : EventAddress.cityFrom(address);

    // Vrsta i mesto u donjem redu; vrsta prva jer je to prvo pitanje pred
    // polazak — ide li se na rođendan ili na svadbu. Ono čega nema se
    // preskače, pa nema usamljene tačke ni praznog reda.
    //
    // Trajanje je u levoj koloni uz sat: na uskom telefonu sa uvećanim
    // sistemskim fontom (320 dp, 1,3×) sve troje u jednom redu ne staje, a
    // trajanje i onako pripada uz vreme.
    final details = [?event.type?.label, ?city].join(' · ');

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // Bez datuma nema ni sata — crtica, ne prazno mesto.
                      date == null ? '—' : AppDate.time(date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: date == null
                            ? AppColors.textSecondary
                            : AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (duration != null)
                      Text(
                        AppDate.shortDuration(duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Naziv dobija ceo red za sebe. Trajanje je sišlo u donji
                    // red jer je gore sekao imena („Svadba - Jel…").
                    Text(
                      // Kratko namerno: na uskom ekranu duži tekst se seče,
                      // a ovde je poenta samo da red nije prazan.
                      event.title ?? 'Bez naziva',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: event.title == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prazan spisak — objašnjava zašto je prazan, ne samo da jeste.
class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.scope, required this.canDelegate});

  final EventScope scope;
  final bool canDelegate;

  @override
  Widget build(BuildContext context) {
    final message = switch (scope) {
      EventScope.delegirani => 'Još nisi napravio nijedan događaj za tim.',
      EventScope.moji when canDelegate => 'Nijedan događaj ti nije dodeljen.',
      EventScope.moji =>
        'Nijedan događaj ti nije dodeljen. Dodeljuje ih onaj ko vodi ekipu.',
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
