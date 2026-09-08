import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

/// Odakle stiže prognoza.
///
/// Ekrani zovu samo ovaj interfejs, kao i kod podataka o događaju —
/// pa se izvor kasnije može zameniti bez diranja UI-ja.
abstract interface class WeatherService {
  /// Prognoza po satima za dati raspon (početak i kraj nastupa).
  ///
  /// Baca [WeatherUnavailableException] kad prognoza ne može da se dobavi.
  Future<EventForecast> forRange({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
  });
}

/// Prognoza trenutno nije dostupna (nema mreže, servis ne odgovara, ili je
/// datum predaleko u budućnosti).
class WeatherUnavailableException implements Exception {
  const WeatherUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'Prognoza nije dostupna: $reason';
}

/// Prognoza sa **Open-Meteo** servisa.
///
/// Izabran jer je besplatan i **ne traži API ključ ni registraciju** — isti
/// duh kao izbor OpenStreetMap-a za mape. Daje prognozu po satu, pa se može
/// reći ne samo "biće kiše danas" nego "kiša oko 17h", što je jedino što
/// izvođaču zaista znači.
///
/// Prognoza ide oko 16 dana unapred; za dalje datume servis vrati grešku,
/// a kartica to kaže umesto da prikaže prazno.
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _host = 'api.open-meteo.com';
  static const String _path = '/v1/forecast';

  /// `2026-09-12` — oblik koji Open-Meteo očekuje za `start_date`/`end_date`.
  static String _apiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Future<EventForecast> forRange({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
  }) async {
    final uri = Uri.https(_host, _path, {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'hourly': 'temperature_2m,precipitation_probability,weather_code',
      // Sati se traže u vremenskoj zoni same lokacije, da se ne bi računalo
      // pomeranje sata ručno.
      'timezone': 'auto',
      'start_date': _apiDate(start),
      'end_date': _apiDate(end),
    });

    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw const WeatherUnavailableException('nema veze sa internetom');
    }

    if (response.statusCode != 200) {
      // Najčešći razlog je datum van dometa prognoze (oko 16 dana).
      throw WeatherUnavailableException('servis je vratio ${response.statusCode}');
    }

    try {
      return _parse(response.body, start: start, end: end);
    } on WeatherUnavailableException {
      rethrow;
    } catch (_) {
      throw const WeatherUnavailableException('odgovor nije razumljiv');
    }
  }

  /// Iz odgovora se uzimaju samo sati koje nastup pokriva.
  EventForecast _parse(
    String body, {
    required DateTime start,
    required DateTime end,
  }) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final hourly = decoded['hourly'] as Map<String, dynamic>?;
    if (hourly == null) {
      throw const WeatherUnavailableException('odgovor nema satnu prognozu');
    }

    final times = (hourly['time'] as List?) ?? const [];
    final temperatures = (hourly['temperature_2m'] as List?) ?? const [];
    final chances = (hourly['precipitation_probability'] as List?) ?? const [];
    final codes = (hourly['weather_code'] as List?) ?? const [];

    final hours = <HourlyWeather>[];
    for (var i = 0; i < times.length; i++) {
      final time = DateTime.tryParse(times[i] as String);
      if (time == null) continue;

      // Uzimaju se sati od onog u kome nastup počinje do onog u kome se
      // završava. Nastup 16:00–18:00 daje 16, 17 i 18 — poslednji zato što
      // se u tom satu pakuje oprema.
      final firstHour = DateTime(start.year, start.month, start.day, start.hour);
      if (time.isBefore(firstHour) || time.isAfter(end)) continue;

      hours.add(
        HourlyWeather(
          time: time,
          temperature: _toDouble(temperatures, i) ?? 0,
          precipitationChance: _toInt(chances, i) ?? 0,
          condition: WeatherCondition.fromWmoCode(_toInt(codes, i) ?? 3),
        ),
      );
    }

    return EventForecast(hours: hours);
  }

  /// Vrednost koja fali ili nije broj ne sme da sruši prognozu.
  static double? _toDouble(List values, int index) {
    if (index >= values.length) return null;
    final value = values[index];
    return value is num ? value.toDouble() : null;
  }

  static int? _toInt(List values, int index) {
    if (index >= values.length) return null;
    final value = values[index];
    return value is num ? value.round() : null;
  }
}
