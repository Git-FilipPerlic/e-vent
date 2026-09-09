import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Čuva logotip tima na telefonu.
///
/// **Slika se prekopira u trajni folder aplikacije**, a ne ostavlja tamo gde
/// je `image_picker` spusti. Njegov folder je privremen i Android ga briše —
/// između ostalog pri reinstalaciji — pa je zapamćena putanja posle toga
/// pokazivala u prazno i logotip bi nestao.
///
/// U podešavanjima stoji samo putanja; sama slika je fajl u folderu
/// aplikacije. Kad stigne baza, ovo zamenjuje logo sa servera.
class TeamLogoService {
  const TeamLogoService({this.directory});

  /// Odakle se uzima trajni folder aplikacije.
  ///
  /// `null` znači sistemski folder; testovi ubacuju svoj privremeni, jer u
  /// testu ne postoji pravi folder aplikacije.
  final Future<Directory> Function()? directory;

  static const String _key = 'team_logo_path';

  /// Prefiks imena sačuvane slike. Ime nosi i vreme čuvanja, da nova slika
  /// nikad ne padne preko stare — inače bi Flutter i dalje crtao staru iz
  /// svog keša slika.
  static const String _filePrefix = 'team_logo_';

  Future<Directory> _dir() =>
      (directory ?? getApplicationDocumentsDirectory)();

  /// Putanja do sačuvanog logotipa, ili `null` ako nije izabran.
  ///
  /// Ako fajla više nema, zapis se čisti — header se tada vraća na ime
  /// aplikacije umesto da pokušava da nacrta sliku koje nema.
  Future<String?> load() async {
    final String? path;
    try {
      final prefs = await SharedPreferences.getInstance();
      path = prefs.getString(_key);
    } catch (_) {
      return null;
    }

    if (path == null || path.trim().isEmpty) return null;
    if (!File(path).existsSync()) {
      await clear();
      return null;
    }
    return path;
  }

  /// Prekopira izabranu sliku u folder aplikacije i pamti novu putanju.
  ///
  /// Vraća putanju do trajne kopije, ili `null` ako kopiranje nije uspelo —
  /// tada se ništa ne pamti, pa header ostaje na starom logotipu.
  Future<String?> save(String pickedPath) async {
    try {
      final source = File(pickedPath);
      if (!source.existsSync()) return null;

      final dir = await _dir();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final target = '${dir.path}/$_filePrefix$stamp${_extensionOf(pickedPath)}';
      await source.copy(target);

      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getString(_key);
      await prefs.setString(_key, target);

      // Stara kopija se briše tek kad je nova upisana, da se u slučaju
      // greške ne ostane bez ijedne.
      if (previous != null && previous != target) _deleteQuietly(previous);

      return target;
    } catch (_) {
      return null;
    }
  }

  /// Briše zapamćeni logotip i njegovu kopiju; header se vraća na ime
  /// aplikacije.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_key);
      await prefs.remove(_key);
      if (path != null) _deleteQuietly(path);
    } catch (_) {
      // Neuspelo brisanje nije razlog da nešto pukne.
    }
  }

  /// Nastavak fajla sa tačkom (`.png`), ili prazno ako ga nema.
  static String _extensionOf(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot) : '';
  }

  static void _deleteQuietly(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Fajl je možda već obrisan; nema šta da se javi korisniku.
    }
  }
}
