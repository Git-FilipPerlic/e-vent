import '../models/track.dart';

/// Odakle stiže spisak numera.
///
/// Ekrani zovu samo ovaj interfejs. Kad se priključi pravi izvor (folder na
/// telefonu ili plejlista), menja se jedna linija — ekran se ne dira.
abstract interface class MusicService {
  /// Spisak numera za nastup.
  Future<List<Track>> loadTracks();
}

/// Lokalni spisak za razvoj.
///
/// Numere su izmišljene i **ne puštaju se** — služe da se proveri raspored
/// ekrana, izbor numere i plejer, pre nego što se izabere paket za zvuk.
class MockMusicService implements MusicService {
  /// Kratka pauza da se vidi kako izgleda učitavanje, kao da fajlovi stižu
  /// sa diska.
  static const Duration _delay = Duration(milliseconds: 300);

  @override
  Future<List<Track>> loadTracks() async {
    await Future<void>.delayed(_delay);
    return _tracks.map((map) => Track.fromMap(map)).toList();
  }
}

/// Spisak je prazan dok korisnik ne doda numere sa telefona.
///
/// Ranije su ovde stajale izmišljene numere, radi provere rasporeda. One su
/// uklonjene čim je spisak počeo da se puni pravim fajlovima: numera koja ne
/// može da se pusti samo smeta na nastupu.
const List<Map<String, dynamic>> _tracks = [];
