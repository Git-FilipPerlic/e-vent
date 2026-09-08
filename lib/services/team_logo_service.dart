import 'package:shared_preferences/shared_preferences.dart';

/// Čuva putanju do logotipa tima na telefonu.
///
/// Sama slika ostaje tamo gde ju je `image_picker` ostavio; ovde se pamti
/// samo putanja. Kad stigne baza, ovo zamenjuje logo sa servera.
class TeamLogoService {
  const TeamLogoService();

  static const String _key = 'team_logo_path';

  /// Putanja do sačuvanog logotipa, ili `null` ako nije izabran.
  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    if (path == null || path.trim().isEmpty) return null;
    return path;
  }

  /// Pamti novi logotip.
  Future<void> save(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  /// Briše zapamćeni logotip; header se vraća na ime aplikacije.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
