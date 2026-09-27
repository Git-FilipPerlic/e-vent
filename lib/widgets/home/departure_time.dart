import 'package:flutter/material.dart';

import '../../services/route_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../common/edit_text_sheet.dart';

/// HOME-007 — vreme polaska na događaj.
///
/// Widget je "glup": prima gotovo vreme kroz konstruktor.
class DepartureTime extends StatelessWidget {
  const DepartureTime({
    super.key,
    required this.departure,
    this.travelMinutes,
    this.drive,
    this.eventStart,
    this.onEdit,
  });

  /// Otvara izbor vremena polaska. `null` kad nema dozvole.
  final VoidCallback? onEdit;

  /// Planirano vreme kretanja. Može da bude `null`.
  final DateTime? departure;

  /// Procenjeno trajanje puta u minutima. Može da nedostaje — tada se
  /// prikazuje samo vreme polaska.
  final int? travelMinutes;

  /// Izračunata vožnja od magacina do adrese događaja. `null` kad adresa
  /// magacina nije uneta, kad nema mreže, ili dok se računa.
  final RouteEstimate? drive;

  /// Kad događaj počinje — iz toga se računa najkasniji polazak.
  final DateTime? eventStart;

  /// `45 min` odnosno `1 h 15 min` — kratko, da stane u jedan red.
  static String formatTravel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  /// Kad se najkasnije kreće da bi se stiglo na početak.
  ///
  /// `null` kad se ne zna ili vožnja nije izračunata — tada se ništa ne
  /// nagađa.
  DateTime? get _latestStart {
    final start = eventStart;
    final estimate = drive;
    if (start == null || estimate == null) return null;
    return start.subtract(estimate.duration);
  }

  /// Da li upisano vreme polaska znači da se kasni.
  bool get _isLate {
    final latest = _latestStart;
    final planned = departure;
    if (latest == null || planned == null) return false;
    return planned.isAfter(latest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = departure;
    final travel = travelMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.directions_car_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vreme polaska',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value != null
                        ? AppDate.time(value)
                        : 'Vreme polaska nije uneto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          value != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (drive != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      // Kilometri stoje uz vreme: po njima se odmah vidi da
                      // li je „40 minuta" gradska vožnja ili put van grada.
                      'Vožnja od magacina: ${formatTravel(drive!.minutes)} · '
                      '${drive!.kilometers.round()} km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else if (value != null && travel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Put traje oko ${formatTravel(travel)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (_latestStart != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _isLate
                          // Broj koji se u glavi ionako računa — zato ga
                          // aplikacija kaže umesto da samo upozori.
                          ? 'Kasniš — kreni najkasnije u '
                                '${AppDate.time(_latestStart!)}'
                          : 'Najkasniji polazak: ${AppDate.time(_latestStart!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _isLate
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        fontWeight: _isLate ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null)
              EditFieldButton(label: 'Vreme polaska', onTap: onEdit!),
          ],
        ),
      ),
    );
  }
}
