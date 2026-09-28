import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:shared_preferences/shared_preferences.dart';

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

  /// Ono što je pročitano u nekom od ranijih pokretanja.
  ///
  /// Čitanje oznaka iz fajla traje, a fajlovi se ne menjaju — pa nema razloga
  /// da se pri svakom pokretanju čita isto. Pamti se uz **veličinu fajla**:
  /// kad se fajl zameni drugim pod istim imenom, veličina se skoro sigurno
  /// razlikuje, pa se oznake čitaju iznova.
  Map<String, dynamic> _remembered = {};
  bool _rememberedLoaded = false;
  bool _rememberedChanged = false;

  static const String _prefsKey = 'music_meta_cache';

  /// Koliko se numera najviše pamti.
  ///
  /// Podignuto sa 300 na 2000 (28. septembra 2026), da se pri pokretanju
  /// učita i velika plejlista bez ponovnog čitanja fajlova. Jedna numera u
  /// pamćenju zauzima stotinak bajtova, pa je i pun spisak reda 200 KB.
  static const int maxRemembered = 2000;

  Future<void> _loadRemembered() async {
    if (_rememberedLoaded) return;
    _rememberedLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) _remembered = decoded;
    } catch (_) {
      // Pamćenje je udobnost, ne uslov: bez njega se oznake samo čitaju
      // iznova.
    }
  }

  Future<void> _saveRemembered() async {
    if (!_rememberedChanged) return;
    _rememberedChanged = false;
    try {
      // Najstarije ispadaju kad se pređe granica — redosled u mapi je
      // redosled upisa.
      if (_remembered.length > maxRemembered) {
        final keep = _remembered.entries.skip(
          _remembered.length - maxRemembered,
        );
        _remembered = {for (final entry in keep) entry.key: entry.value};
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_remembered));
    } catch (_) {
      // Isto: neuspelo pamćenje ne sme da pokvari spisak.
    }
  }

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

    await _loadRemembered();
    final size = await _sizeOf(path);
    final Map<String, Object?>? tags;

    final saved = _remembered[path];
    if (saved is Map && size != null && saved['size'] == size) {
      // Pročitano ranije, fajl se nije menjao — ništa se ne čita.
      tags = {
        'title': saved['title'] as String?,
        'artist': saved['artist'] as String?,
        'ms': saved['ms'] as int?,
      };
    } else {
      tags = await Isolate.run(() => _readTags(path));
      if (tags != null && size != null) {
        _remembered[path] = {
          'size': size,
          'title': tags['title'],
          'artist': tags['artist'],
          'ms': tags['ms'],
        };
        _rememberedChanged = true;
      }
    }
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
    await _loadRemembered();
    final result = <Track>[];

    for (var start = 0; start < tracks.length; start += batchSize) {
      final end = start + batchSize;
      final slice = tracks.sublist(
        start,
        end > tracks.length ? tracks.length : end,
      );

      // Šta u ovoj turi treba pogledati na disku, i koju veličinu fajla
      // pamtimo od ranije. Veličina ide u nit sa poslom, pa se fajl koji se
      // nije menjao tamo i preskoči — bez ijednog pitanja glavnoj niti.
      final ask = <String, int?>{};
      for (final track in slice) {
        final path = track.path;
        if (path == null || path.contains('://')) continue;
        if (_cache.containsKey(path)) continue;
        final saved = _remembered[path];
        ask[path] = saved is Map ? saved['size'] as int? : null;
      }

      final read = ask.isEmpty
          ? const <String, Map<String, Object?>>{}
          : await _readBatch(ask);

      for (final entry in read.entries) {
        final tags = entry.value;
        if (tags['same'] == true) continue;
        if (tags['stale'] == true) {
          // Fajl je zamenjen ili se ne može pročitati — staro pamćenje o
          // njemu više ne važi i ne sme da se podmetne.
          if (_remembered.remove(entry.key) != null) _rememberedChanged = true;
          continue;
        }
        _remembered[entry.key] = tags;
        _rememberedChanged = true;
      }

      final done = [for (final track in slice) _withTags(track, read)];
      result.addAll(done);
      onBatch?.call(done);
    }

    // Ono što je pročitano ide na disk, da se sledeći put ne čita opet.
    await _saveRemembered();
    return result;
  }

  /// Jedna tura čitanja, u **jednoj** zasebnoj niti.
  ///
  /// Ranije je svaka numera dobijala svoju nit; pravljenje niti samo po sebi
  /// traje, pa je spisak od nekoliko stotina numera na to trošio više vremena
  /// nego na samo čitanje.
  Future<Map<String, Map<String, Object?>>> _readBatch(
    Map<String, int?> ask,
  ) async {
    try {
      return await Isolate.run(() => _readMany(ask));
    } catch (_) {
      // Bez niti se čita ovde: bolje sporije nego bez trajanja.
      return _readMany(ask);
    }
  }

  /// Numera dopunjena onim što je pročitano ili zapamćeno.
  Track _withTags(Track track, Map<String, Map<String, Object?>> read) {
    final path = track.path;
    if (path == null) return track;

    final cached = _cache[path];
    if (cached != null) return cached;

    // Šta je tura našla: ako fajl nije ni gledan (već je u kešu, ili je
    // `content://` adresa) ili se nije menjao, važi ono što je zapamćeno.
    final found = read[path];
    final Object? tags = switch (found) {
      null => _remembered[path],
      {'same': true} => _remembered[path],
      {'stale': true} => null,
      _ => found,
    };
    if (tags is! Map) {
      // Fajl bez oznaka, nepostojeći fajl ili `content://` adresa — numera
      // ostaje kakva jeste. To nije greška koju korisnik treba da vidi.
      _cache[path] = track;
      return track;
    }

    final milliseconds = tags['ms'] as int?;
    final enriched = Track(
      id: track.id,
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

  /// Čita oznake za celu turu. Radi se u zasebnoj niti, pa i ulaz i izlaz
  /// nose samo obične vrednosti.
  ///
  /// Fajl čija se veličina poklapa sa zapamćenom se **preskače** — njegove
  /// oznake već znamo.
  static Map<String, Map<String, Object?>> _readMany(Map<String, int?> ask) {
    final result = <String, Map<String, Object?>>{};
    for (final entry in ask.entries) {
      try {
        final file = File(entry.key);
        if (!file.existsSync()) {
          result[entry.key] = const {'stale': true};
          continue;
        }
        final size = file.lengthSync();
        if (entry.value != null && entry.value == size) {
          // Isti fajl kao prošli put — oznake već znamo, ne čita se.
          result[entry.key] = const {'same': true};
          continue;
        }

        final data = readMetadata(file, getImage: false);
        result[entry.key] = {
          'size': size,
          'title': data.title,
          'artist': data.artist ?? data.albumArtist,
          'ms': data.duration?.inMilliseconds,
        };
      } catch (_) {
        // Fajl bez oznaka ili u obliku koji čitač ne poznaje.
        result[entry.key] = const {'stale': true};
      }
    }
    return result;
  }

  /// Veličina fajla, po kojoj se poznaje da je zamenjen drugim.
  static Future<int?> _sizeOf(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.length();
    } catch (_) {
      return null;
    }
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
