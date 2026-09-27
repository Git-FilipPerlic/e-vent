import 'dart:convert';

import 'package:http/http.dart' as http;

/// Koliko se vozi od magacina do događaja.
class RouteEstimate {
  const RouteEstimate({required this.duration, required this.kilometers});

  /// Koliko traje vožnja u normalnim uslovima.
  ///
  /// **Bez saobraćaja u realnom vremenu** (odluka od 27. septembra 2026):
  /// izvori koji znaju gužvu, zatvorene ulice i udese traže nalog i ključ, a
  /// za prvu verziju je dogovoreno da se ide sa besplatnim podacima.
  final Duration duration;

  final double kilometers;

  int get minutes => (duration.inSeconds / 60).round();
}

/// Koordinate jedne tačke na mapi.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Put ne može da se izračuna (nema mreže, adresa se ne prepoznaje, servis
/// ne odgovara). Kartica tada prikazuje ono što ima, bez vremena vožnje.
class RouteUnavailableException implements Exception {
  const RouteUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'Put nije izračunat: $reason';
}

/// Odakle stižu koordinate i vreme vožnje.
///
/// Ekrani zovu samo ovaj interfejs, kao i kod prognoze — izvor se kasnije
/// može zameniti bez diranja UI-ja. To je i put kojim će doći saobraćaj u
/// realnom vremenu, ako se jednom uzme nalog kod nekog od plaćenih servisa.
abstract interface class RouteService {
  /// Pretvara adresu u koordinate. Baca [RouteUnavailableException] kad se
  /// adresa ne prepozna.
  Future<GeoPoint> locate(String address);

  /// Vožnja od tačke do tačke.
  Future<RouteEstimate> drive({required GeoPoint from, required GeoPoint to});
}

/// Put preko **OpenStreetMap-a**: adrese kroz Nominatim, vožnja kroz OSRM.
///
/// Izabrani zato što **ne traže ni nalog ni ključ ni karticu** — isti duh kao
/// Open-Meteo za prognozu i OSM pločice za mapu. Cena je što ne znaju
/// saobraćaj: vreme je „koliko se vozi kad je normalno".
///
/// Oba servisa imaju pravila korišćenja za javne servere (Nominatim traži
/// najviše jedan zahtev u sekundi i da se aplikacija predstavi; OSRM-ov
/// demo server je za lagan saobraćaj). Za jednu ekipu je to sasvim u redu;
/// ako aplikacija ikad izađe šire, prelazi se na svoj ili plaćen server.
class OsmRouteService implements RouteService {
  OsmRouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Nominatim traži da se aplikacija predstavi — bez toga ume da odbije.
  static const Map<String, String> _headers = {
    'User-Agent': 'e-vent/1.0 (mobilna aplikacija za izvođače)',
  };

  static const Duration _timeout = Duration(seconds: 12);

  @override
  Future<GeoPoint> locate(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      throw const RouteUnavailableException('adresa nije uneta');
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'json',
      'limit': '1',
      // Bez ovoga Nominatim ume da vrati tačku u drugoj državi kad je ulica
      // upisana bez grada.
      'countrycodes': 'rs',
    });

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(_timeout);
    } catch (error) {
      throw RouteUnavailableException('adresa nije potražena ($error)');
    }
    if (response.statusCode != 200) {
      throw RouteUnavailableException('servis adresa: ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        throw const RouteUnavailableException('adresa nije pronađena');
      }
      final first = decoded.first as Map<String, dynamic>;
      final latitude = double.parse(first['lat'] as String);
      final longitude = double.parse(first['lon'] as String);
      return GeoPoint(latitude, longitude);
    } on RouteUnavailableException {
      rethrow;
    } catch (_) {
      throw const RouteUnavailableException('odgovor servisa nije razumljiv');
    }
  }

  @override
  Future<RouteEstimate> drive({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    // OSRM očekuje redosled dužina,širina — obrnuto od uobičajenog.
    final points =
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final uri = Uri.https('router.project-osrm.org', '/route/v1/driving/$points', {
      // Sam oblik puta na mapi se ne crta, pa se ni ne traži.
      'overview': 'false',
    });

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(_timeout);
    } catch (error) {
      throw RouteUnavailableException('put nije potražen ($error)');
    }
    if (response.statusCode != 200) {
      throw RouteUnavailableException('servis puta: ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) {
        throw const RouteUnavailableException('put nije pronađen');
      }
      final route = routes.first as Map<String, dynamic>;
      final seconds = (route['duration'] as num).round();
      final meters = (route['distance'] as num).toDouble();
      return RouteEstimate(
        duration: Duration(seconds: seconds),
        kilometers: meters / 1000,
      );
    } on RouteUnavailableException {
      rethrow;
    } catch (_) {
      throw const RouteUnavailableException('odgovor servisa nije razumljiv');
    }
  }
}
