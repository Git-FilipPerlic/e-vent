import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../models/track.dart';

/// Jedna stavka u pregledu fajlova: folder ili numera.
class BrowserEntry {
  const BrowserEntry({
    required this.path,
    required this.name,
    required this.isFolder,
  });

  final String path;
  final String name;
  final bool isFolder;
}

/// Čitanje foldera na telefonu, za pregled fajlova u Muzika tabu.
///
/// Od Androida 11 aplikacija ne sme da čita tuđe foldere bez izričite dozvole
/// **"Pristup svim fajlovima"**, koju korisnik daje u sistemskim podešavanjima.
/// Bez nje se ne vidi ništa — zato pregled prvo proverava dozvolu, pa tek onda
/// čita.
abstract final class FileBrowser {
  /// Nastavci koje plejer **zaista** ume da pusti na Androidu (MUSIC-021).
  ///
  /// Spisak prati ono što Androidov plejer podržava, a ne ono što bi bilo
  /// lepo da podržava. Nastavak koji se ovde nađe a ne može da se pusti je
  /// gori od nastavka koji fali: korisnik izabere pesmu, a ona ne radi.
  ///
  /// **`wma` je namerno izostavljen** — Android nikad nije podržavao Windows
  /// Media Audio. Ranije je stajao u spisku, pa bi se takav fajl ponudio a
  /// zatim odbio da se otvori.
  static const Set<String> audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'oga',
    'opus',
    'amr',
    'mka',
  };

  /// Unutrašnja memorija telefona. Odatle kreće pregled.
  static const String internalStorage = '/storage/emulated/0';

  static bool isAudio(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return false;
    return audioExtensions.contains(path.substring(dot + 1).toLowerCase());
  }

  /// Da li je dozvola za čitanje fajlova već data.
  static Future<bool> hasAccess() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    // Na starijim Androidima je dovoljna obična dozvola za memoriju.
    return Permission.storage.isGranted;
  }

  /// Traži dozvolu. Za "Pristup svim fajlovima" Android otvara svoj ekran
  /// podešavanja, pa korisnik tamo prevuče prekidač i vrati se.
  static Future<bool> requestAccess() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    final legacy = await Permission.storage.request();
    return legacy.isGranted;
  }

  /// Otvara sistemska podešavanja aplikacije — kad je dozvola trajno odbijena.
  static Future<void> openSettings() => openAppSettings();

  /// Mesta odakle pregled kreće: unutrašnja memorija i, ako postoji,
  /// SD kartica ili USB.
  static Future<List<BrowserEntry>> roots() async {
    final roots = <BrowserEntry>[];

    if (await Directory(internalStorage).exists()) {
      roots.add(
        const BrowserEntry(
          path: internalStorage,
          name: 'Memorija telefona',
          isFolder: true,
        ),
      );
    }

    // Ostali nosači stoje uz /storage; preskaču se sistemski unosi.
    try {
      final storage = Directory('/storage');
      await for (final entry in storage.list(followLinks: false)) {
        if (entry is! Directory) continue;
        final name = entry.path.split('/').last;
        if (name == 'emulated' || name == 'self') continue;
        roots.add(
          BrowserEntry(path: entry.path, name: name, isFolder: true),
        );
      }
    } catch (_) {
      // Nema pristupa spisku nosača — ostaje bar unutrašnja memorija.
    }

    return roots;
  }

  /// Sadržaj foldera: prvo podfolderi, pa numere, oba po azbuci.
  ///
  /// Prikazuju se **samo folderi i numere** — ostali fajlovi bi samo smetali
  /// u pregledu čija je jedina svrha da se nađe muzika.
  ///
  /// Baca [FolderNotReadableException] kad folder ne može da se pročita.
  static Future<List<BrowserEntry>> list(String path) async {
    final List<FileSystemEntity> entries;
    try {
      entries = await Directory(path).list(followLinks: false).toList();
    } catch (_) {
      throw FolderNotReadableException(path);
    }

    final folders = <BrowserEntry>[];
    final files = <BrowserEntry>[];

    for (final entry in entries) {
      final name = entry.path.split('/').last;
      // Skriveni folderi (.thumbnails i slično) samo zatrpavaju spisak.
      if (name.startsWith('.')) continue;

      if (entry is Directory) {
        folders.add(BrowserEntry(path: entry.path, name: name, isFolder: true));
      } else if (entry is File && isAudio(entry.path)) {
        files.add(BrowserEntry(path: entry.path, name: name, isFolder: false));
      }
    }

    int byName(BrowserEntry a, BrowserEntry b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());

    folders.sort(byName);
    files.sort(byName);
    return [...folders, ...files];
  }

  /// Numere iz jednog foldera, bez ulaska u podfoldere.
  static Future<List<Track>> tracksIn(String folderPath) async {
    final entries = await list(folderPath);
    return [
      for (final entry in entries)
        if (!entry.isFolder) trackFor(entry),
    ];
  }

  /// Pravi numeru od jednog fajla.
  static Track trackFor(BrowserEntry entry) {
    return Track(
      id: 'fajl-${entry.path.hashCode}',
      title: Track.withoutExtension(entry.name),
      source: TrackSource.folder,
      path: entry.path,
    );
  }
}

/// Folder ne može da se pročita (nema dozvole ili ga nema).
class FolderNotReadableException implements Exception {
  const FolderNotReadableException(this.path);

  final String path;

  @override
  String toString() => 'Folder se ne može pročitati: $path';
}
