import 'package:event_app/models/weather.dart';
import 'package:event_app/services/weather_service.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/event_weather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

/// Odgovor kakav Open-Meteo vraća: satna prognoza za dan događaja.
/// U 17h je kiša — to je slučaj zbog koga kartica i postoji.
const String _response = '''
{
  "hourly": {
    "time": ["2026-09-12T15:00", "2026-09-12T16:00", "2026-09-12T17:00",
             "2026-09-12T18:00", "2026-09-12T19:00"],
    "temperature_2m": [24.4, 23.8, 22.1, 21.0, 20.2],
    "precipitation_probability": [5, 10, 80, 20, 5],
    "weather_code": [0, 2, 61, 3, 1]
  }
}
''';

void main() {
  setUpAll(() => AppDate.init());

  group('WMO šifre', () {
    test('svode se na stanja koja nešto znače na terenu', () {
      expect(WeatherCondition.fromWmoCode(0), WeatherCondition.vedro);
      expect(WeatherCondition.fromWmoCode(2), WeatherCondition.delimicnoOblacno);
      expect(WeatherCondition.fromWmoCode(3), WeatherCondition.oblacno);
      expect(WeatherCondition.fromWmoCode(61), WeatherCondition.kisa);
      expect(WeatherCondition.fromWmoCode(73), WeatherCondition.sneg);
      expect(WeatherCondition.fromWmoCode(95), WeatherCondition.grmljavina);
      // Nepoznata šifra ne sme da pukne.
      expect(WeatherCondition.fromWmoCode(999), WeatherCondition.oblacno);
    });

    test('padavine su prepoznate kao mokro stanje', () {
      expect(WeatherCondition.kisa.isWet, isTrue);
      expect(WeatherCondition.grmljavina.isWet, isTrue);
      expect(WeatherCondition.vedro.isWet, isFalse);
    });
  });

  group('Open-Meteo servis', () {
    test('uzima samo sate koje nastup pokriva', () async {
      late Uri asked;
      final service = OpenMeteoWeatherService(
        client: MockClient((request) async {
          asked = request.url;
          return http.Response(_response, 200);
        }),
      );

      final forecast = await service.forRange(
        latitude: 45.2671,
        longitude: 19.8335,
        start: DateTime(2026, 9, 12, 16, 0),
        end: DateTime(2026, 9, 12, 18, 0),
      );

      // Traži se baš dan događaja, sa satnom prognozom.
      expect(asked.host, 'api.open-meteo.com');
      expect(asked.queryParameters['start_date'], '2026-09-12');
      expect(asked.queryParameters['hourly'], contains('precipitation'));

      // 15h otpada (završava se pre početka), 19h otpada (počinje posle kraja).
      expect(forecast.hours.length, 3);
      expect(forecast.atStart!.temperature, 23.8);
      expect(forecast.atStart!.condition, WeatherCondition.delimicnoOblacno);
    });

    test('nađe prvi sat sa kišom usred nastupa', () async {
      final service = OpenMeteoWeatherService(
        client: MockClient((_) async => http.Response(_response, 200)),
      );

      final forecast = await service.forRange(
        latitude: 45.2671,
        longitude: 19.8335,
        start: DateTime(2026, 9, 12, 16, 0),
        end: DateTime(2026, 9, 12, 18, 0),
      );

      final wet = forecast.firstWetHour!;
      expect(wet.time.hour, 17);
      expect(wet.precipitationChance, 80);
    });

    test('greška servisa se javlja kao nedostupna prognoza', () async {
      final service = OpenMeteoWeatherService(
        client: MockClient((_) async => http.Response('nope', 400)),
      );

      expect(
        () => service.forRange(
          latitude: 45.2671,
          longitude: 19.8335,
          start: DateTime(2026, 9, 12, 16, 0),
          end: DateTime(2026, 9, 12, 18, 0),
        ),
        throwsA(isA<WeatherUnavailableException>()),
      );
    });

    test('neispravan odgovor ne ruši aplikaciju', () async {
      final service = OpenMeteoWeatherService(
        client: MockClient((_) async => http.Response('{"nesto": 1}', 200)),
      );

      expect(
        () => service.forRange(
          latitude: 45.2671,
          longitude: 19.8335,
          start: DateTime(2026, 9, 12, 16, 0),
          end: DateTime(2026, 9, 12, 18, 0),
        ),
        throwsA(isA<WeatherUnavailableException>()),
      );
    });
  });

  group('kartica vremena', () {
    testWidgets('prikazuje temperaturu, stanje i upozorenje na kišu',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventWeather(
            weather: EventForecast(
              hours: [
                HourlyWeather(
                  time: DateTime(2026, 9, 12, 16),
                  temperature: 23.8,
                  precipitationChance: 10,
                  condition: WeatherCondition.delimicnoOblacno,
                ),
                HourlyWeather(
                  time: DateTime(2026, 9, 12, 17),
                  temperature: 22.1,
                  precipitationChance: 80,
                  condition: WeatherCondition.kisa,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Vreme na događaju'), findsOneWidget);
      expect(find.text('24°'), findsOneWidget);
      expect(find.text('Delimično oblačno'), findsOneWidget);
      expect(find.text('Kiša oko 17:00 (80%)'), findsOneWidget);
    });

    testWidgets('bez kiše nema upozorenja', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          EventWeather(
            weather: EventForecast(
              hours: [
                HourlyWeather(
                  time: DateTime(2026, 9, 12, 16),
                  temperature: 25.0,
                  precipitationChance: 0,
                  condition: WeatherCondition.vedro,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Vedro'), findsOneWidget);
      expect(find.byIcon(Icons.umbrella_rounded), findsNothing);
    });

    testWidgets('greška nudi ponovni pokušaj', (WidgetTester tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _wrap(
          EventWeather(
            weather: null,
            errorMessage: 'Prognoza nije dostupna (nema veze sa internetom).',
            onRetry: () => retries++,
          ),
        ),
      );

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('prazna prognoza to i kaže', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const EventWeather(weather: EventForecast(hours: []))),
      );

      expect(
        find.text('Prognoza za taj dan još nije dostupna'),
        findsOneWidget,
      );
    });
  });
}
