// Put od magacina do događaja: adrese kroz Nominatim, vožnja kroz OSRM.

import 'package:event_app/services/route_service.dart';
import 'package:event_app/utils/date_format.dart';
import 'package:event_app/widgets/home/departure_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String _addressResponse = '''
[{"lat":"45.2671","lon":"19.8335","display_name":"Novi Sad"}]
''';

const String _routeResponse = '''
{"code":"Ok","routes":[{"duration":2520.4,"distance":31480.2}]}
''';

void main() {
  // Kartica ispisuje sat na srpskom, pa nazivi moraju da se učitaju.
  setUpAll(() => AppDate.init());

  group('adresa u koordinate', () {
    test('vraća tačku iz odgovora', () async {
      final service = OsmRouteService(
        client: MockClient((_) async => http.Response(_addressResponse, 200)),
      );

      final point = await service.locate('Bulevar Oslobođenja 1, Novi Sad');

      expect(point.latitude, closeTo(45.2671, 0.0001));
      expect(point.longitude, closeTo(19.8335, 0.0001));
    });

    test('prazna adresa se ne traži', () async {
      final service = OsmRouteService(
        client: MockClient((_) async => fail('servis ne sme da se zove')),
      );

      expect(
        () => service.locate('   '),
        throwsA(isA<RouteUnavailableException>()),
      );
    });

    test('nepoznata adresa javlja grešku, ne vraća nasumičnu tačku', () async {
      final service = OsmRouteService(
        client: MockClient((_) async => http.Response('[]', 200)),
      );

      expect(
        () => service.locate('Ulica koje nema'),
        throwsA(isA<RouteUnavailableException>()),
      );
    });

    // Aplikacija se mora predstaviti, inače Nominatim ume da odbije zahtev.
    test('zahtev nosi ime aplikacije', () async {
      String? agent;
      final service = OsmRouteService(
        client: MockClient((request) async {
          agent = request.headers['User-Agent'];
          return http.Response(_addressResponse, 200);
        }),
      );

      await service.locate('Novi Sad');

      expect(agent, contains('e-vent'));
    });
  });

  group('vožnja', () {
    test('vreme i kilometri iz odgovora', () async {
      final service = OsmRouteService(
        client: MockClient((_) async => http.Response(_routeResponse, 200)),
      );

      final estimate = await service.drive(
        from: const GeoPoint(45.2671, 19.8335),
        to: const GeoPoint(44.7866, 20.4489),
      );

      expect(estimate.minutes, 42);
      expect(estimate.kilometers, closeTo(31.48, 0.01));
    });

    // OSRM očekuje dužinu pa širinu — obrnuto od uobičajenog reda.
    test('tačke idu redom dužina, širina', () async {
      String? path;
      final service = OsmRouteService(
        client: MockClient((request) async {
          path = request.url.path;
          return http.Response(_routeResponse, 200);
        }),
      );

      await service.drive(
        from: const GeoPoint(45.2671, 19.8335),
        to: const GeoPoint(44.7866, 20.4489),
      );

      expect(path, contains('19.8335,45.2671;20.4489,44.7866'));
    });

    test('servis bez puta javlja grešku', () async {
      final service = OsmRouteService(
        client: MockClient(
          (_) async => http.Response('{"code":"NoRoute","routes":[]}', 200),
        ),
      );

      expect(
        () => service.drive(
          from: const GeoPoint(45.2671, 19.8335),
          to: const GeoPoint(44.7866, 20.4489),
        ),
        throwsA(isA<RouteUnavailableException>()),
      );
    });
  });

  group('kartica vremena polaska', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('pokazuje vožnju i najkasniji polazak', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DepartureTime(
            departure: DateTime(2026, 9, 28, 14),
            drive: const RouteEstimate(
              duration: Duration(minutes: 42),
              kilometers: 31.5,
            ),
            eventStart: DateTime(2026, 9, 28, 16),
          ),
        ),
      );

      expect(find.textContaining('Vožnja od magacina'), findsOneWidget);
      expect(find.textContaining('42 min'), findsOneWidget);
      expect(find.textContaining('32 km'), findsOneWidget);
      // 16:00 minus 42 minuta.
      expect(find.textContaining('15:18'), findsOneWidget);
    });

    testWidgets('kad se kasni, to se kaže', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          DepartureTime(
            // Polazak u 15:40, a stiže se tek u 16:22.
            departure: DateTime(2026, 9, 28, 15, 40),
            drive: const RouteEstimate(
              duration: Duration(minutes: 42),
              kilometers: 31.5,
            ),
            eventStart: DateTime(2026, 9, 28, 16),
          ),
        ),
      );

      expect(find.textContaining('Kasniš'), findsOneWidget);
    });

    // Vožnja je dopuna, ne uslov: bez nje kartica radi kao i pre.
    testWidgets('bez izračunate vožnje kartica stoji kao ranije', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DepartureTime(
            departure: DateTime(2026, 9, 28, 14),
            travelMinutes: 30,
          ),
        ),
      );

      expect(find.textContaining('Put traje oko 30 min'), findsOneWidget);
      expect(find.textContaining('Najkasniji polazak'), findsNothing);
    });
  });
}
