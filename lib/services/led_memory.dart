import 'package:shared_preferences/shared_preferences.dart';

/// Pamti poslednji kontroler, da se pred nastup ne traži mreža iznova.
///
/// Adresa koju kontroler dobije obično je uvek ista (najčešće `192.168.4.1`
/// kad sam pravi mrežu), pa se ponuda „poveži se ponovo" gotovo uvek isplati.
///
/// Pamćenje je udobnost, ne uslov: ako čitanje ili upis pukne, LED tab radi
/// kao da ničega nije bilo.
class LedMemory {
  const LedMemory();

  static const String _addressKey = 'led_last_address';
  static const String _orderKey = 'led_color_order';

  /// Adresa poslednjeg kontrolera, ili `null`.
  Future<String?> lastAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_addressKey);
      return value == null || value.trim().isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  /// Zapamćeni redosled boja, ili `null` ako još nije biran.
  ///
  /// Pamti se uz adresu jer je to **svojstvo samog uređaja**: isti kontroler
  /// će i sledeći put očekivati isti redosled.
  Future<String?> colorOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_orderKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> remember({required String address, String? colorOrder}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_addressKey, address);
      if (colorOrder != null) await prefs.setString(_orderKey, colorOrder);
    } catch (_) {
      // Neuspelo pamćenje ne sme da prekine povezivanje.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_addressKey);
      await prefs.remove(_orderKey);
    } catch (_) {
      // Isto kao kod pamćenja: nije razlog da nešto pukne.
    }
  }
}
