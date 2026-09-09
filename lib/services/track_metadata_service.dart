import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../models/track.dart';

/// Čita podatke iz samog audio fajla: naziv, izvođača i trajanje.
///
/// Bez ovoga spisak pokazuje naziv fajla i `--:--` umesto trajanja, jer se
/// trajanje inače sazna tek kad se numera otvori u plejeru.
///
/// Čitanje se radi **jednom po numeri** i pamti se; fajl koji nema oznake ili
/// se ne može pročitati ostaje kakav jeste — nikad se ne puca.
class TrackMetadataService {
  final Map<String, Track> _cache = {};

  /// Dopunjava numeru podacima iz fajla.
  ///
  /// Vraća **istu numeru** kad podataka nema — pozivalac ne mora da proverava
  /// da li se nešto promenilo.
  Future<Track> enrich(Track track) async {
    final path = track.path;
    if (path == null) return track;

    final cached = _cache[path];
    if (cached != null) return cached;

    // Numera koja stiže kao `content://` adresa se ne može otvoriti kao fajl.
    if (path.contains('://')) return track;

    try {
      final file = File(path);
      if (!await file.exists()) return track;

      final data = readMetadata(file);
      final enriched = Track(
        id: track.id,
        // Oznake u fajlu imaju prednost nad nazivom fajla, ali prazna oznaka
        // ne sme da obriše ono što već imamo.
        title: _firstFilled([data.title, track.title]),
        artist: _firstFilled([data.artist, data.albumArtist, track.artist]),
        source: track.source,
        duration: data.duration ?? track.duration,
        path: path,
      );

      _cache[path] = enriched;
      return enriched;
    } catch (_) {
      // Fajl bez oznaka ili u obliku koji čitač ne poznaje — numera ostaje
      // kakva jeste. To nije greška koju korisnik treba da vidi.
      _cache[path] = track;
      return track;
    }
  }

  /// Dopunjava ceo spisak, redom.
  ///
  /// Čitanje je brzo (samo zaglavlje fajla), ali za velike foldere ide
  /// odvojeno od crtanja ekrana.
  Future<List<Track>> enrichAll(List<Track> tracks) async {
    return [for (final track in tracks) await enrich(track)];
  }

  static String? _firstFilled(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
