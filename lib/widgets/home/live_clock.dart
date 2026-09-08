import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// HOME-006 — sat uživo: trenutno vreme, osvežava se svake sekunde.
///
/// Sat se **ne animira** — tekst koji se menja svake sekunde a pritom treperi
/// je iritantan (pravilo iz `CLAUDE.md`). Menja se samo brojka.
///
/// Widget sam drži svoj tajmer; ne priča ni sa servisom ni sa bazom.
class LiveClock extends StatefulWidget {
  const LiveClock({super.key, this.now = DateTime.now});

  /// Odakle se čita trenutno vreme. U aplikaciji je to sat telefona;
  /// u testu se podmetne lažni sat, jer se pravo vreme ne može ubrzati.
  final DateTime Function() now;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.now();
    _scheduleNextTick();
  }

  /// Kucanje se poravnava sa punom sekundom, da se prikaz ne bi menjao
  /// "na pola" i preskakao pokoju sekundu.
  void _scheduleNextTick() {
    final untilNextSecond = Duration(
      milliseconds: 1000 - widget.now().millisecond,
    );
    _timer = Timer(untilNextSecond, () {
      if (!mounted) return;
      setState(() => _now = widget.now());
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Sekunde uz sat i minut: `14:30:07`
  String get _formatted {
    final seconds = _now.second.toString().padLeft(2, '0');
    return '${AppDate.time(_now)}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tačno vreme',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatted,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      // Brojke iste širine, da se tekst ne pomera svake sekunde.
                      fontFeatures: const [FontFeature.tabularFigures()],
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
