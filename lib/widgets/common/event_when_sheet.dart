import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// Kada događaj počinje i koliko traje.
///
/// Sve troje stoji zajedno jer se zajedno i misli: „dvanaesti, u četiri, dva
/// sata". Razdvojeno na tri lista bi značilo tri otvaranja za jednu odluku.
class EventWhen {
  const EventWhen({this.start, this.durationMinutes});

  /// Datum i sat početka. `null` znači da nije uneto.
  final DateTime? start;

  /// Ugovoreno trajanje u minutima. `null` znači da nije uneto.
  final int? durationMinutes;
}

/// Otvara izbor datuma, sata početka i trajanja.
///
/// Vraća novu vrednost, ili `null` ako je korisnik odustao.
Future<EventWhen?> showEventWhenSheet(
  BuildContext context, {
  required EventWhen value,
}) {
  return showModalBottomSheet<EventWhen>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _EventWhenSheet(value: value),
  );
}

class _EventWhenSheet extends StatefulWidget {
  const _EventWhenSheet({required this.value});

  final EventWhen value;

  @override
  State<_EventWhenSheet> createState() => _EventWhenSheetState();
}

class _EventWhenSheetState extends State<_EventWhenSheet> {
  late DateTime? _start = widget.value.start;
  late int? _duration = widget.value.durationMinutes;

  /// Trajanja koja se stvarno ugovaraju. Sve ostalo ide kroz „Drugo".
  static const List<int> _commonDurations = [45, 60, 90, 120, 180, 240];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _start ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      // Prošli događaji se unose retko, ali se unose — na primer kad se
      // spisak popunjava unazad. Zato godina unazad, a ne od danas.
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;

    setState(() {
      // Sat se čuva ako je već biran; inače podrazumevano 16:00 — nastupi
      // su popodne i uveče, pa je to bliže istini nego ponoć.
      final hour = _start?.hour ?? 16;
      final minute = _start?.minute ?? 0;
      _start = DateTime(picked.year, picked.month, picked.day, hour, minute);
    });
  }

  Future<void> _pickTime() async {
    final current = _start;
    final picked = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay(hour: current.hour, minute: current.minute)
          : const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked == null) return;

    setState(() {
      // Sat bez datuma nema smisla, pa se uzima današnji dan.
      final day = current ?? DateTime.now();
      _start = DateTime(
        day.year,
        day.month,
        day.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickOtherDuration() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => const _MinutesDialog(),
    );
    if (minutes == null) return;
    setState(() => _duration = minutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _start;
    final duration = _duration;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kada i koliko',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _PickerRow(
              label: 'Datum',
              // Prazno kad nije uneto: red se zove „Datum" i vodi u kalendar,
              // pa se iz konteksta zna šta se bira. Ovo je izuzetak od opšteg
              // pravila o praznim poljima — ono važi za kartice, gde podatak
              // stoji sam, bez naziva reda pored sebe.
              value: start != null ? AppDate.dateShort(start) : '',
              hasValue: start != null,
              onTap: _pickDate,
            ),
            _PickerRow(
              label: 'Sat početka',
              value: start != null ? AppDate.time(start) : '',
              hasValue: start != null,
              onTap: _pickTime,
            ),

            const SizedBox(height: AppSpacing.md),
            Text(
              'Trajanje',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final minutes in _commonDurations)
                  ChoiceChip(
                    label: Text(AppDate.shortDuration(minutes)),
                    selected: duration == minutes,
                    onSelected: (_) => setState(() => _duration = minutes),
                  ),
                ChoiceChip(
                  label: Text(
                    duration != null && !_commonDurations.contains(duration)
                        ? AppDate.shortDuration(duration)
                        : 'Drugo',
                  ),
                  selected:
                      duration != null && !_commonDurations.contains(duration),
                  onSelected: (_) => _pickOtherDuration(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Odustani'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      EventWhen(start: _start, durationMinutes: _duration),
                    ),
                    child: const Text('Sačuvaj'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Jedan red koji otvara sistemski birač.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Unos trajanja u minutima, kad nijedno ponuđeno ne odgovara.
class _MinutesDialog extends StatefulWidget {
  const _MinutesDialog();

  @override
  State<_MinutesDialog> createState() => _MinutesDialogState();
}

class _MinutesDialogState extends State<_MinutesDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final minutes = int.tryParse(_controller.text.trim());
    // Nula i besmislene vrednosti se ćutke odbijaju — bolje nego poruka o
    // grešci usred unosa.
    if (minutes == null || minutes <= 0 || minutes > 24 * 60) return;
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Trajanje u minutima'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'na primer 150',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surfaceAlt,
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Sačuvaj')),
      ],
    );
  }
}
