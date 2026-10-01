import 'package:flutter/material.dart';

import '../models/meeting.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/common/error_retry.dart';

/// Sastanci firme — konzola.
///
/// Ovde se pravi i briše sastanak: samo termin i adresa, ništa više (vidi
/// `CompanyMeeting`). Sastanak vidi cela ekipa, u spisku događaja, drugom
/// bojom — do ovog ekrana se stiže samo uz prijavu, kao i do Ekipe i Opreme.
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key, required this.service});

  final EventService service;

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  List<CompanyMeeting> _meetings = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meetings = await widget.service.loadMeetings();
      if (!mounted) return;
      setState(() {
        _meetings = meetings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Spisak sastanaka nije učitan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _create() async {
    final input = await showModalBottomSheet<_NewMeetingInput>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _NewMeetingSheet(),
    );
    if (input == null || !mounted) return;

    try {
      final created = await widget.service.createMeeting(
        dateTime: input.dateTime,
        address: input.address,
      );
      if (!mounted) return;
      setState(() => _meetings = [..._meetings, created]);
    } catch (_) {
      _report('Sastanak nije napravljen.');
    }
  }

  Future<void> _delete(CompanyMeeting meeting) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _DeleteSheet(meeting: meeting),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _meetings = [
        for (final one in _meetings)
          if (one.id != meeting.id) one,
      ];
    });

    try {
      await widget.service.deleteMeeting(meeting.id);
    } catch (_) {
      _report('Sastanak nije obrisan.');
      await _load();
    }
  }

  void _report(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sastanci firme')),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nov sastanak'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return ErrorRetry(message: errorMessage, onRetry: _load);
    }

    if (_meetings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Nijedan sastanak nije zakazan.\nCela ekipa ga vidi u spisku '
            'događaja, drugom bojom.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final meetings = [..._meetings]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        96,
      ),
      itemCount: meetings.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(kLargeRadius),
            boxShadow: kSoftShadow,
          ),
          child: ListTile(
            title: Text(
              '${AppDate.dateShort(meeting.dateTime)} · '
              '${AppDate.time(meeting.dateTime)}',
            ),
            subtitle: Text(
              meeting.address.isEmpty ? 'Adresa nije uneta' : meeting.address,
            ),
            trailing: IconButton(
              onPressed: () => _delete(meeting),
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.danger,
              tooltip: 'Obriši sastanak',
            ),
          ),
        );
      },
    );
  }
}

/// Potvrda brisanja.
class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.meeting});

  final CompanyMeeting meeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Obrisati sastanak?', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${AppDate.dateShort(meeting.dateTime)} · '
              '${AppDate.time(meeting.dateTime)} — '
              '${meeting.address.isEmpty ? "adresa nije uneta" : meeting.address}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Obriši'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Odustani'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Šta se unosi za nov sastanak — samo termin i adresa.
class _NewMeetingInput {
  const _NewMeetingInput({required this.dateTime, required this.address});

  final DateTime dateTime;
  final String address;
}

/// List za unos novog sastanka: datum, sat i adresa.
///
/// Nema ničeg drugog — ni naziva, ni učesnika — jer sastanak firme i ne
/// nosi ništa drugo (dogovoreno 1. oktobra 2026). Ekipa već zna gde firma
/// drži sastanke, pa je adresa tekst, ne mapa.
class _NewMeetingSheet extends StatefulWidget {
  const _NewMeetingSheet();

  @override
  State<_NewMeetingSheet> createState() => _NewMeetingSheetState();
}

class _NewMeetingSheetState extends State<_NewMeetingSheet> {
  DateTime? _date;
  final TextEditingController _address = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _date ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: readableDatePicker,
    );
    if (picked == null) return;

    setState(() {
      final hour = _date?.hour ?? 16;
      final minute = _date?.minute ?? 0;
      _date = DateTime(picked.year, picked.month, picked.day, hour, minute);
    });
  }

  Future<void> _pickTime() async {
    final current = _date;
    final picked = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay(hour: current.hour, minute: current.minute)
          : const TimeOfDay(hour: 16, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
      builder: readableDatePicker,
    );
    if (picked == null) return;

    setState(() {
      final day = current ?? DateTime.now();
      _date = DateTime(
        day.year,
        day.month,
        day.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  bool get _canSave => _date != null && _address.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _date;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nov sastanak', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      date == null ? 'Datum' : AppDate.dateShort(date),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(date == null ? 'Sat' : AppDate.time(date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _address,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Adresa',
                hintText: 'na primer Bulevar Oslobođenja 1, Novi Sad',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _canSave
                  ? () => Navigator.of(context).pop(
                      _NewMeetingInput(
                        dateTime: _date!,
                        address: _address.text.trim(),
                      ),
                    )
                  : null,
              child: const Text('Napravi'),
            ),
          ],
        ),
      ),
    );
  }
}
