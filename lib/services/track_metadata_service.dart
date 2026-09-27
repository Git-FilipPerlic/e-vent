import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../models/track.dart';

/// Čita podatke iz samog audio fajla: naziv, izvođača i trajanje.
///
/// Bez ovoga spisak pokazuje naziv fajla i `--:--` umesto trajanja, jer se
/// trajanje inače sazna tek kad se numera otvori u plejeru.
///
/// Čitanje se radi **jednom po numeri** i pamti se; fajl koji nema oznake ili
/// se ne može pročitati ostaje kakav jeste — nikad se ne puca.
///
/// **Čita se u zasebnoj niti** (`Isolate.run`, od 27. septembra 2026).
/// Čitanje je sinhrono i za veliki folder traje; dok se radilo na glavnoj
/// niti, spisak od nekoliko stotina numera je zaglavljivao ekran i sve je
/// stajalo na `--:--` dok poslednja ne bude gotova.
class TrackMetadataService {
  final Map<String, Track> _cache = {};

  /// Koliko numera ide u jednu turu pre nego što se ekran osveži.
  ///
  /// Manji broj znači češće osvežavanje i brži prvi utisak; veći manje posla
  /// oko crtanja. Dvadeset je sredina — na ekran ionako staje sedam redova.
  static const int batchSize = 20;

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

    final tags = await Isolate.run(() => _readTags(path));
    if (tags == null) {
      // Fajl bez oznaka ili u obliku koji čitač ne poznaje — numera ostaje
      // kakva jeste. To nije greška koju korisnik treba da vidi.
      _cache[path] = track;
      return track;
    }

    final milliseconds = tags['ms'] as int?;
    final enriched = Track(
      id: track.id,
      // Oznake u fajlu imaju prednost nad nazivom fajla, ali prazna oznaka
      // ne sme da obriše ono što već imamo.
      title: _firstFilled([tags['title'] as String?, track.title]),
      artist: _firstFilled([tags['artist'] as String?, track.artist]),
      source: track.source,
      duration: milliseconds == null
          ? track.duration
          : Duration(milliseconds: milliseconds),
      path: path,
    );

    _cache[path] = enriched;
    return enriched;
  }

  /// Dopunjava ceo spisak, u turama.
  ///
  /// [onBatch] se zove posle svake ture, sa numerama koje su dotle
  /// pročitane — spisak tako puni trajanja postepeno, umesto da sve stoji na
  /// `--:--` dok se poslednji fajl ne pročita.
  Future<List<Track>> enrichAll(
    List<Track> tracks, {
    void Function(List<Track> done)? onBatch,
  }) async {
    final result = <Track>[];
    final batch = <Track>[];

    for (final track in tracks) {
      result.add(await enrich(track));
      batch.add(result.last);
      if (batch.length >= batchSize) {
        onBatch?.call([...batch]);
        batch.clear();
      }
    }
    if (batch.isNotEmpty) onBatch?.call([...batch]);
    return result;
  }

  /// Čita oznake iz fajla. Radi se u zasebnoj niti, pa vraća samo obične
  /// vrednosti — složeni objekti ne mogu da pređu granicu niti.
  static Map<String, Object?>? _readTags(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final data = readMetadata(file, getImage: false);
      return {
        'title': data.title,
        'artist': data.artist ?? data.albumArtist,
        'ms': data.duration?.inMilliseconds,
      };
    } catch (_) {
      return null;
    }
  }

  static String? _firstFilled(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
