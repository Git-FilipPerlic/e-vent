import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';

/// HOME-005 — datum događaja, ispisan na srpskom (`12. septembar 2026.`),
/// sa satom u koji je tezga zakazana.
///
/// Ispod datuma stoji traka od **0 do 23 časa**; osenčen je čas u koji
/// događaj počinje, pa se sa jednog pogleda vidi da li je tezga popodne
/// ili kasno uveče. Sat je podatak od koga izvođač u glavi računa sve
/// ostalo, pa se prikazuje krupno i tačno.
///
/// Traka je **samo za čitanje** dok se ne prosledi [onHourSelected] — sat
/// događaja se unosi u admin konzoli, posle prijave, a ne dodirom na Home
/// ekranu.
class EventDate extends StatefulWidget {
  const EventDate({super.key, required this.date, this.onHourSelected});

  /// Datum i vreme događaja. Može da bude `null`.
  final DateTime? date;

  /// Kad je prosleđen, traka postaje izmenjiva i izabrani čas se javlja
  /// nadređenom ekranu (admin konzola). Dok je `null`, traka se samo čita.
  final ValueChanged<int>? onHourSelected;

  /// Sati u danu: 0..23.
  static const int hoursInDay = 24;

  @override
  State<EventDate> createState() => _EventDateState();
}

class _EventDateState extends State<EventDate> {
  /// Širina jednog polja u traci, plus razmak — koristi se i za računanje
  /// gde traku treba pomeriti da bi izabrani čas bio na sredini.
  static const double _slotWidth = 52;
  static const double _slotGap = AppSpacing.xs;

  late final ScrollController _strip = ScrollController();
  int? _hour;

  @override
  void initState() {
    super.initState();
    _hour = widget.date?.hour;
    // Traka se otvara tako da izabrani čas bude u vidnom polju,
    // a ne da korisnik traži gde je 20h.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHour());
  }

  @override
  void didUpdateWidget(covariant EventDate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kad stignu novi podaci o događaju, traka prati novi sat.
    if (widget.date?.hour != oldWidget.date?.hour) {
      setState(() => _hour = widget.date?.hour);
      _scrollToHour();
    }
  }

  @override
  void dispose() {
    _strip.dispose();
    super.dispose();
  }

  void _scrollToHour() {
    final hour = _hour;
    if (hour == null || !_strip.hasClients) return;

    final viewport = _strip.position.viewportDimension;
    final target =
        hour * (_slotWidth + _slotGap) - (viewport / 2) + (_slotWidth / 2);
    _strip.jumpTo(target.clamp(0.0, _strip.position.maxScrollExtent));
  }

  /// Bez dozvole se sat ne menja ovde — vraća `null`, pa polje nije dodirno.
  VoidCallback? _tapHandler(int hour) {
    final notify = widget.onHourSelected;
    if (notify == null) return null;
    return () {
      setState(() => _hour = hour);
      notify(hour);
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = widget.date;
    final hour = _hour;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datum događaja',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        value != null ? AppDate.long(value) : 'Datum nije unet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: value != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: value != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hour != null)
                  Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sat početka',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: kMinTouchTarget,
              child: ListView.separated(
                controller: _strip,
                scrollDirection: Axis.horizontal,
                itemCount: EventDate.hoursInDay,
                separatorBuilder: (_, _) => const SizedBox(width: _slotGap),
                itemBuilder: (context, index) => _HourSlot(
                  hour: index,
                  isSelected: index == hour,
                  width: _slotWidth,
                  onTap: _tapHandler(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jedan čas u traci. Izabrani je izdignut i u boji `accent`.
class _HourSlot extends StatelessWidget {
  const _HourSlot({
    required this.hour,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  final int hour;
  final bool isSelected;
  final double width;

  /// `null` znači da polje nije dodirno — sat se unosi u admin konzoli.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSelected
                    ? const [AppColors.surfaceAlt, AppColors.surface]
                    : const [AppColors.backgroundBottom, AppColors.surface],
              ),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              hour.toString().padLeft(2, '0'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
