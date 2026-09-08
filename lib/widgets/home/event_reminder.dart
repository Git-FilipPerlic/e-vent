import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// HOME-019 — podsetnik: koliko je ostalo do polaska, odnosno do početka
/// događaja kada je polazak već prošao.
///
/// Odbrojavanje se **ne animira** — brojka koja treperi svake sekunde smeta.
class EventReminder extends StatefulWidget {
  const EventReminder({
    super.key,
    required this.departure,
    required this.eventStart,
    this.now = DateTime.now,
  });

  final DateTime? departure;
  final DateTime? eventStart;

  /// Odakle se čita trenutno vreme; u testu se podmetne lažni sat.
  final DateTime Function() now;

  /// Ispod ovoliko vremena do polaska podsetnik prelazi u boju upozorenja.
  static const Duration soon = Duration(minutes: 30);

  /// Preostalo vreme napisano rečju: `2 h 15 min`, `45 min`, `manje od minut`.
  static String formatRemaining(Duration left) {
    if (left.inMinutes < 1) return 'manje od minut';

    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;

    if (days > 0) return hours == 0 ? '$days d' : '$days d $hours h';
    if (hours > 0) return minutes == 0 ? '$hours h' : '$hours h $minutes min';
    return '$minutes min';
  }

  @override
  State<EventReminder> createState() => _EventReminderState();
}

class _EventReminderState extends State<EventReminder> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = widget.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Šta se sledeće dešava: prvo polazak, pa početak događaja.
  /// `null` znači da više nema šta da se čeka.
  ({String label, DateTime at})? get _next {
    final departure = widget.departure;
    final start = widget.eventStart;

    if (departure != null && departure.isAfter(_now)) {
      return (label: 'Polazak', at: departure);
    }
    if (start != null && start.isAfter(_now)) {
      return (label: 'Početak događaja', at: start);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = _next;
    final hasAnyTime = widget.departure != null || widget.eventStart != null;

    final String message;
    final Color color;
    final IconData icon;

    if (next == null) {
      message = hasAnyTime ? 'Nema više čekanja' : 'Vremena nisu uneta';
      color = AppColors.textSecondary;
      icon = Icons.notifications_none_rounded;
    } else {
      final left = next.at.difference(_now);
      message =
          '${next.label} za ${EventReminder.formatRemaining(left)}';
      final isSoon = left <= EventReminder.soon;
      color = isSoon ? AppColors.warning : AppColors.textPrimary;
      icon = isSoon
          ? Icons.notifications_active_rounded
          : Icons.notifications_none_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Podsetnik',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
