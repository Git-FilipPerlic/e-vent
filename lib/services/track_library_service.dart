import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

/// Pamti koje je numere izvođač dodao, da spisak preživi zatvaranje
/// aplikacije.
///
/// Bez ovoga bi se pred svaki nastup ponovo tražio isti folder — spisak je
/// živeo samo dok je aplikacija otvorena.
///
/// **Pamte se samo putanje do fajlova**, ne i sami fajlovi ni podaci iz njih.
/// Izvođač i trajanje se ionako iznova čitaju iz fajla pri učitavanju, pa bi
/// njihovo pamćenje značilo da zastare čim se fajl zameni.
class TrackLibraryService {
  const TrackLibraryService();

  static const String _key = 'music_track_paths';

  /// Učitava zapamćeni spisak.
  ///
  /// **Fajlovi kojih više nema se preskaču** — obrisana numera na nastupu
  /// samo smeta, a plejer bi na njoj javio grešku.
  Future<List<Track>> load() async {
    // Pamćenje spiska je udobnost, ne uslov za rad: ako čitanje pukne,
    // Muzika tab se otvara prazan umesto da javi grešku.
    final List<String> paths;
    try {
      final prefs = await SharedPreferences.getInstance();
      paths = prefs.getStringList(_key) ?? const [];
    } catch (_) {
      return const [];
    }

    final tracks = <Track>[];
    for (final path in paths) {
      if (!File(path).existsSync()) continue;
      tracks.add(trackFor(path));
    }
    return tracks;
  }

  /// Pamti ceo spisak, redom kojim stoji na ekranu.
  Future<void> save(List<Track> tracks) async {
    final paths = [
      for (final track in tracks)
        if (track.path != null) track.path!,
    ];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, paths);
    } catch (_) {
      // Neuspelo pamćenje ne sme da prekine dodavanje numera.
    }
  }

  /// Briše zapamćeni spisak.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Isto kao kod pamćenja: nije razlog da nešto pukne.
    }
  }

  /// Numera od same putanje.
  ///
  /// Id se računa iz putanje, isto kao u pregledu fajlova, da ista numera
  /// posle ponovnog pokretanja ne dobije drugi id.
  static Track trackFor(String path) {
    return Track(
      id: 'fajl-${path.hashCode}',
      title: Track.withoutExtension(path.split(RegExp(r'[/\\]')).last),
      source: TrackSource.folder,
      path: path,
    );
  }
}
