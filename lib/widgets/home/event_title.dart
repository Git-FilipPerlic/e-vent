import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// HOME-001 — kartica događaja: datum i sat u gornjem redu, naziv i trajanje
/// u donjem.
///
/// Sve stoji u dva reda, bez odrednica koje se podrazumevaju:
///
/// ```
/// Događaj      12. septembar   16:00
/// 7 Mia
/// 2h
/// ```
///
/// - **Naziv nema reč "rođendan"** — arapski broj ispred imena već znači
///   koliko slavljenik puni godina, pa i reč "godina" otpada.
/// - **Trajanje se prepoznaje po slovu `h`** — to je jedina oznaka koja treba
///   da bi se taj broj razlikovao od godina i od sata početka. Stoji ispod
///   imena, sitno i mirno: podatak koji se pogleda jednom, pa zaboravi.
/// - Datum je beo i naglašen, sat u boji `accent` — to su brojke iz kojih
///   izvođač u glavi računa ostalo.
///
/// Widget je "glup": prima gotove podatke kroz konstruktor.
class EventTitle extends StatelessWidget {
  const EventTitle({
    super.key,
    required this.title,
    this.date,
    this.durationMinutes,
  });

  /// Naziv događaja. Može da bude `null` ili prazan.
  final String? title;

  /// Datum i sat početka. Može da bude `null`.
  final DateTime? date;

  /// Ugovoreno trajanje u minutima. Može da bude `null`.
  final int? durationMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final when = date;
    final minutes = durationMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Događaj',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  // Pri uvećanom sistemskom fontu se datum radije skuplja nego
                  // što se seče na "12. septem…".
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      when != null ? AppDate.dayMonth(when) : 'Datum nije unet',
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: when != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: when != null
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                if (when != null) ...[
                  // Datum se skuplja do pune širine, pa mu treba razmak da se
                  // ne slepi sa satom u "12. septembar16:00".
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppDate.time(when),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasTitle ? title!.trim() : 'Naziv događaja nije unet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: hasTitle
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: hasTitle ? FontWeight.w600 : FontWeight.w400,
                height: 1.2,
              ),
            ),
            if (minutes != null)
              Text(
                AppDate.shortDuration(minutes),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
