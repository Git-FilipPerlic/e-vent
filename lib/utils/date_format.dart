import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Ispis datuma i vremena na srpskom, latinicom.
///
/// Sve na jednom mestu, da se isti datum svuda u aplikaciji piše isto —
/// i da se ne kucaju nazivi meseci rukom.
abstract final class AppDate {
  /// Srpski, latinica. (Obično `sr` je ćirilica — zato izričito `sr_Latn`.)
  static const String locale = 'sr_Latn';

  /// Učitava nazive meseci i dana za naš jezik. Zove se jednom, u `main()`,
  /// pre nego što se bilo šta iscrta.
  static Future<void> init() => initializeDateFormatting(locale);

  /// Pun datum: `12. septembar 2026.`
  static String long(DateTime value) =>
      DateFormat.yMMMMd(locale).format(value);

  /// Dan i mesec, **bez godine**: `12. septembar`.
  ///
  /// Godina se ne piše namerno — posao se planira nedeljama unapred, a ne
  /// godinama, pa godina samo zauzima mesto.
  static String dayMonth(DateTime value) =>
      DateFormat('d. MMMM', locale).format(value);

  /// Dan u nedelji: `subota`
  static String weekday(DateTime value) =>
      DateFormat.EEEE(locale).format(value);

  /// Sat i minut u 24-časovnom obliku: `14:30`
  static String time(DateTime value) => DateFormat.Hm(locale).format(value);

  /// Trajanje u najkraćem obliku: `2h`, `1h30`, `45min`.
  ///
  /// Slovo `h` je jedina oznaka koja treba — po njemu se broj trajanja
  /// razlikuje od ostalih brojeva u redu (godine slavljenika, sat početka).
  static String shortDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h$rest';
  }
}
