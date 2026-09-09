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

/// Test numere. Namerno različite: sa izvođačem i bez, iz foldera i iz
/// plejliste, jedna bez naziva (proverava pad na naziv fajla) i jedna bez
/// poznatog trajanja.
const List<Map<String, dynamic>> _tracks = [
  {
    'id': 'trk-001',
    'title': 'Uvodna špica',
    'artist': 'Miks za doček',
    'source': 'playlist',
    'durationSeconds': 154,
    'path': '/muzika/uvodna-spica.mp3',
  },
  {
    'id': 'trk-002',
    'title': 'Igre za decu',
    'artist': 'Dečji miks',
    'source': 'playlist',
    'durationSeconds': 212,
    'path': '/muzika/igre-za-decu.mp3',
  },
  {
    'id': 'trk-003',
    'title': 'Vatreni show',
    'source': 'folder',
    'durationSeconds': 187,
    'path': '/muzika/vatreni-show.mp3',
  },
  {
    'id': 'trk-004',
    'source': 'folder',
    'durationSeconds': 240,
    'path': '/muzika/bez-naziva-04.mp3',
  },
  {
    'id': 'trk-005',
    'title': 'Završni plesni program',
    'artist': 'Finale',
    'source': 'playlist',
    'path': '/muzika/finale.mp3',
  },
];
