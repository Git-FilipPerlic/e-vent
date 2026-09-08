import 'package:flutter/material.dart';

/// Stanje vremena, svedeno na ono što izvođaču znači na terenu.
///
/// Open-Meteo vraća WMO šifru (0..99); ovde se ta lepeza svodi na šest
/// stanja, jer razlika između "slaba susnežica" i "umerena susnežica" ne
/// menja ništa u pripremi nastupa.
enum WeatherCondition {
  vedro('Vedro', Icons.wb_sunny_rounded),
  delimicnoOblacno('Delimično oblačno', Icons.wb_cloudy_rounded),
  oblacno('Oblačno', Icons.cloud_rounded),
  kisa('Kiša', Icons.water_drop_rounded),
  sneg('Sneg', Icons.ac_unit_rounded),
  grmljavina('Grmljavina', Icons.thunderstorm_rounded);

  const WeatherCondition(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Da li stanje znači padavine — po tome se odlučuje da li se pali
  /// upozorenje na kartici.
  bool get isWet =>
      this == kisa || this == sneg || this == grmljavina;

  /// Prevodi WMO šifru iz Open-Meteo odgovora.
  /// Nepoznata šifra se tretira kao oblačno — nikad se ne puca.
  factory WeatherCondition.fromWmoCode(int code) {
    if (code == 0) return vedro;
    if (code == 1 || code == 2) return delimicnoOblacno;
    if (code == 3 || code == 45 || code == 48) return oblacno;
    // Grmljavina je 95..99; sve preko toga je besmislena šifra, ne oluja.
    if (code >= 95 && code <= 99) return grmljavina;
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return sneg;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return kisa;
    return oblacno;
  }
}

/// Vreme u jednom satu.
class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationChance,
    required this.condition,
  });

  final DateTime time;

  /// Temperatura u stepenima Celzijusa.
  final double temperature;

  /// Verovatnoća padavina, 0..100.
  final int precipitationChance;

  final WeatherCondition condition;
}

/// Prognoza za sate u kojima traje nastup.
class EventForecast {
  const EventForecast({required this.hours});

  /// Sati koje nastup pokriva, redom. Može da bude prazno ako prognoza
  /// za taj dan još ne postoji.
  final List<HourlyWeather> hours;

  bool get isEmpty => hours.isEmpty;

  /// Vreme na početku nastupa — to je ono što se prikazuje krupno.
  HourlyWeather? get atStart => hours.isEmpty ? null : hours.first;

  /// Ispod ove verovatnoće se padavine ne pominju; iznad se pali upozorenje.
  static const int rainWarningThreshold = 40;

  /// Prvi sat u kome se očekuju padavine, ako ga ima.
  ///
  /// Ovo je cela poenta kartice: da organizator unapred zna da mu kiša pada
  /// na pola programa, a ne da to otkrije na licu mesta.
  HourlyWeather? get firstWetHour {
    for (final hour in hours) {
      final wet =
          hour.condition.isWet ||
          hour.precipitationChance >= rainWarningThreshold;
      if (wet) return hour;
    }
    return null;
  }

  /// Najviša i najniža temperatura tokom nastupa.
  double? get maxTemperature => hours.isEmpty
      ? null
      : hours.map((h) => h.temperature).reduce((a, b) => a > b ? a : b);

  double? get minTemperature => hours.isEmpty
      ? null
      : hours.map((h) => h.temperature).reduce((a, b) => a < b ? a : b);
}
