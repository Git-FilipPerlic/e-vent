import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Pamti koji je **izgled** aplikacije izabran.
///
/// Izgled je lična stvar, ne podatak firme: svaki izvođač bira ono što mu
/// bolje leži, pa se pamti **na telefonu**, a ne u bazi. Zato ga i vidi samo
/// onaj čiji je telefon, bez obzira na ulogu.
class SkinService {
  const SkinService();

  static const String _key = 'app_skin';

  /// Izgled zapamćen na ovom telefonu; bez zapisa je to podrazumevani.
  Future<AppSkin> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppSkin.byId(prefs.getString(_key));
    } catch (_) {
      // Pamćenje je udobnost, ne uslov za rad.
      return AppSkin.safir;
    }
  }

  /// Pamti izabrani izgled.
  Future<void> save(AppSkin skin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, skin.id);
    } catch (_) {
      // Neuspelo pamćenje ne sme da spreči promenu izgleda u ovom pokretanju.
    }
  }
}
