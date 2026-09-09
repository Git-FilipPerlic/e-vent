import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../common/edit_text_sheet.dart';

/// HOME-001 — kartica događaja: datum i sat u gornjem redu, naziv i trajanje
/// u donjem.
///
/// Sve stoji u dva reda, bez odrednica koje se podrazumevaju:
///
/// ```
/// Rođendan     12. septembar   16:00
/// 7 Mia / 2h
/// ```
///
/// - **Vrsta stoji umesto reči „Događaj"** — isto mesto, a nosi podatak.
///   Bez unete vrste piše opšte „Događaj".
///
/// - **Naziv nema reč "rođendan"** — arapski broj ispred imena već znači
///   koliko slavljenik puni godina, pa i reč "godina" otpada.
/// - **Trajanje se prepoznaje po slovu `h`** — to je jedina oznaka koja treba
///   da bi se taj broj razlikovao od godina i od sata početka. Stoji odmah uz
///   ime, odvojeno kosom crtom i u bledosivoj boji: podatak koji se pogleda
///   jednom, pa zaboravi.
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
    this.type,
    this.onEdit,
  });

  /// Vrsta događaja. Stoji umesto reči „Događaj" — isti prostor, a odmah se
  /// zna ide li se na rođendan, krštenje, svadbu, nastup ili festival.
  /// `null` kad nije uneta, pa ostaje opšte „Događaj".
  final EventType? type;

  /// Otvara izmenu naziva. `null` kad korisnik nema dozvolu — kartica je tada
  /// ista, samo bez olovke.
  final VoidCallback? onEdit;

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
                  type?.label ?? 'Događaj',
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
                if (onEdit != null)
                  EditFieldButton(label: 'Naziv događaja', onTap: onEdit!),
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
            Text.rich(
              TextSpan(
                text: hasTitle ? title!.trim() : 'Naziv događaja nije unet',
                children: [
                  if (minutes != null)
                    TextSpan(
                      text: ' / ${AppDate.shortDuration(minutes)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: hasTitle
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: hasTitle ? FontWeight.w600 : FontWeight.w400,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
