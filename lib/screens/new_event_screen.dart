import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/common/event_when_sheet.dart';

/// Nov događaj — „Create and share".
///
/// Ovde se unosi **samo ono bez čega događaj nema smisla**: vrsta, naziv,
/// kada je i ko ga radi. Adresa, organizator, telefon i oprema se popunjavaju
/// na Home tabu, olovkama koje već postoje — nema razloga da se isti unos
/// pravi dvaput.
///
/// Dodela ekipe je **deo pravljenja**, ne poseban korak: događaj koji niko ne
/// radi je samo beleška. Može da se promeni kasnije, sa Home taba.
///
/// Vraća napravljeni događaj kroz `Navigator.pop`, ili `null` ako je korisnik
/// odustao.
class NewEventScreen extends StatefulWidget {
  const NewEventScreen({
    super.key,
    required this.service,
    required this.createdBy,
  });

  final EventService service;

  /// Ko pravi događaj — po tome ga posle vidi u „Delegirani".
  final String createdBy;

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final TextEditingController _title = TextEditingController();

  EventType? _type;
  EventWhen _when = const EventWhen();
  final Set<String> _assigned = <String>{};

  List<String> _team = const [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    try {
      final team = await widget.service.loadTeamMembers();
      if (!mounted) return;
      setState(() {
        _team = team;
        // Onaj ko pravi događaj gotovo uvek i ide na njega, pa je unapred
        // čekiran. Može da se otčekira.
        if (team.contains(widget.createdBy)) _assigned.add(widget.createdBy);
      });
    } catch (_) {
      // Bez spiska ekipe se događaj i dalje pravi — samo se ne dodeljuje
      // odmah. Ekran zbog toga ne sme da stane.
      if (!mounted) return;
      setState(() => _team = const []);
    }
  }

  Future<void> _pickWhen() async {
    final picked = await showEventWhenSheet(context, value: _when);
    if (picked == null) return;
    setState(() => _when = picked);
  }

  Future<void> _create() async {
    setState(() => _isSaving = true);

    try {
      final event = await widget.service.createEvent(
        createdBy: widget.createdBy,
        title: _title.text,
        type: _type,
        eventDate: _when.start,
        durationMinutes: _when.durationMinutes,
        assignedTo: _assigned.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(event);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Događaj nije napravljen.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _when.start;
    final duration = _when.durationMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Nov događaj')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Label(text: 'Vrsta'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final type in EventType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _type == type,
                    // Ponovni dodir skida izbor — vrsta sme da nedostaje.
                    onSelected: (selected) => setState(
                      () => _type = selected ? type : null,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            _Label(text: 'Naziv'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _title,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                // Konvencija iz specifikacije, u samom polju — kraće nego
                // objašnjavati je posle.
                hintText: 'na primer 7 Mia',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Broj ispred imena znači godine slavljenika. Vrsta se ne piše '
              'u naziv — nosi je red iznad.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            _Label(text: 'Kada i koliko'),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickWhen,
              icon: const Icon(Icons.edit_calendar_rounded, size: 20),
              label: Text(
                start == null
                    ? 'Izaberi datum i sat'
                    : [
                        AppDate.dateShort(start),
                        AppDate.time(start),
                        if (duration != null) AppDate.shortDuration(duration),
                      ].join(' · '),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            _Label(text: 'Ko radi'),
            const SizedBox(height: AppSpacing.sm),
            if (_team.isEmpty)
              Text(
                'Spisak ekipe nije učitan. Događaj može da se napravi sada, '
                'a ekipa da se doda kasnije.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final member in _team)
                    FilterChip(
                      label: Text(member),
                      selected: _assigned.contains(member),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _assigned.add(member);
                        } else {
                          _assigned.remove(member);
                        }
                      }),
                    ),
                ],
              ),

            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _isSaving ? null : _create,
              child: Text(
                _isSaving ? 'Pravim…' : 'Napravi i podeli',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ostalo — adresa, organizator, telefon i oprema — popunjava se '
              'na Home tabu, kad se dogovori.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Naslov jednog dela obrasca.
class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
