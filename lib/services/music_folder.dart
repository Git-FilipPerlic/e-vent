import 'dart:io';

import '../models/track.dart';

/// Čitanje numera iz foldera koji je korisnik izabrao.
///
/// **Zašto ovo ume da ne uspe:** na Androidu birač foldera često vrati
/// `content://` adresu (SAF), a ne pravu putanju na disku. Takva adresa se ne
/// može otvoriti običnim čitanjem foldera, pa se u tom slučaju korisniku kaže
/// da bira same fajlove. Bolje jasna poruka nego prazan spisak.
abstract final class MusicFolder {
  /// Nastavci koje plejer ume da pusti.
  static const Set<String> audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'opus',
    'wma',
  };

  /// Da li se dati odgovor birača uopšte može čitati kao folder.
  static bool isReadablePath(String path) => !path.contains('://');

  static bool _isAudio(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return false;
    return audioExtensions.contains(path.substring(dot + 1).toLowerCase());
  }

  /// Numere iz foldera, sortirane po nazivu fajla.
  ///
  /// Ne ulazi se u podfoldere: spisak za nastup je jedan folder, a ne cela
  /// muzička biblioteka.
  ///
  /// Baca [FolderNotReadableException] kad folder ne može da se pročita.
  static Future<List<Track>> tracksIn(String folderPath) async {
    if (!isReadablePath(folderPath)) {
      throw FolderNotReadableException(folderPath);
    }

    final directory = Directory(folderPath);
    final List<FileSystemEntity> entries;
    try {
      entries = await directory.list(followLinks: false).toList();
    } catch (_) {
      throw FolderNotReadableException(folderPath);
    }

    final files = entries.whereType<File>().where((f) => _isAudio(f.path)).toList()
      ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    return [
      for (var i = 0; i < files.length; i++)
        Track(
          id: 'folder-$i-${files[i].path.hashCode}',
          title: files[i].path.split(RegExp(r'[/\\]')).last,
          source: TrackSource.folder,
          path: files[i].path,
        ),
    ];
  }
}

/// Folder ne može da se pročita (SAF adresa, ili nema dozvole).
class FolderNotReadableException implements Exception {
  const FolderNotReadableException(this.path);

  final String path;

  @override
  String toString() => 'Folder se ne može pročitati: $path';
}
