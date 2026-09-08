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

  /// Dan u nedelji: `subota`
  static String weekday(DateTime value) =>
      DateFormat.EEEE(locale).format(value);

  /// Sat i minut u 24-časovnom obliku: `14:30`
  static String time(DateTime value) => DateFormat.Hm(locale).format(value);
}
