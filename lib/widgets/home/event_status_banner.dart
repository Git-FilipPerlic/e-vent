import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Faza u kojoj se događaj nalazi, izvedena iz vremena.
enum EventPhase {
  /// Još se čeka polazak.
  planirano('Planirano', Icons.event_available_rounded),

  /// Vreme je za polazak, događaj još nije počeo.
  polazak('Polazak', Icons.directions_car_rounded),

  /// Događaj traje.
  uToku('U toku', Icons.play_circle_outline_rounded),

  /// Događaj je prošao.
  zavrseno('Završeno', Icons.check_circle_outline_rounded);

  const EventPhase(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// HOME-018 — status događaja izveden iz vremena:
/// planirano → polazak → u toku → završeno.
///
/// Widget je "glup": prima vremena kroz konstruktor i sam gleda na sat.
class EventStatusBanner extends StatefulWidget {
  const EventStatusBanner({
    super.key,
    required this.departure,
    required this.eventStart,
    this.eventEnd,
    this.now = DateTime.now,
  });

  final DateTime? departure;
  final DateTime? eventStart;

  /// Kraj nastupa, izračunat iz ugovorenog trajanja. Kad ga nema, koristi se
  /// [assumedDuration].
  final DateTime? eventEnd;

  /// Odakle se čita trenutno vreme; u testu se podmetne lažni sat.
  final DateTime Function() now;

  /// Koliko se pretpostavlja da događaj traje **kada ugovoreno trajanje nije
  /// uneto**. Ako trajanje postoji, ova vrednost se ne koristi.
  static const Duration assumedDuration = Duration(hours: 4);

  /// Računa fazu iz vremena. Kad nema dovoljno podataka, vraća `null` —
  /// tada se prikazuje da status nije poznat.
  static EventPhase? phaseAt({
    required DateTime now,
    DateTime? departure,
    DateTime? eventStart,
    DateTime? eventEnd,
  }) {
    if (eventStart == null && departure == null) return null;

    if (eventStart != null) {
      final end = eventEnd ?? eventStart.add(assumedDuration);
      if (now.isAfter(end)) {
        return EventPhase.zavrseno;
      }
      if (!now.isBefore(eventStart)) return EventPhase.uToku;
    }

    if (departure != null && !now.isBefore(departure)) {
      return EventPhase.polazak;
    }

    return EventPhase.planirano;
  }

  @override
  State<EventStatusBanner> createState() => _EventStatusBannerState();
}

class _EventStatusBannerState extends State<EventStatusBanner> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.now();
    // Status se menja retko, ali mora sam da pređe u sledeću fazu bez
    // ponovnog ulaska u ekran.
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

  Color _colorFor(EventPhase? phase) {
    switch (phase) {
      case EventPhase.polazak:
        return AppColors.warning;
      case EventPhase.uToku:
        return AppColors.accent;
      case EventPhase.zavrseno:
        return AppColors.success;
      case EventPhase.planirano:
      case null:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = EventStatusBanner.phaseAt(
      now: _now,
      departure: widget.departure,
      eventStart: widget.eventStart,
      eventEnd: widget.eventEnd,
    );
    final color = _colorFor(phase);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              phase?.icon ?? Icons.help_outline_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status događaja',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Naglo prebacivanje boje zbunjuje — boja se pretapa 300 ms.
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ) ??
                        TextStyle(color: color),
                    child: Text(phase?.label ?? 'Status nije poznat'),
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
