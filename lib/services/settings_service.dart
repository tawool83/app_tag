import 'package:shared_preferences/shared_preferences.dart';

const _kPrintSizeCm = 'print_size_cm';
const _kDefaultPrintSizeCm = 5.0;
const _kHiddenTileKeys = 'hidden_tile_keys';

class SettingsService {
  static Future<double> getLastPrintSizeCm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kPrintSizeCm) ?? _kDefaultPrintSizeCm;
  }

  static Future<void> saveLastPrintSizeCm(double sizeCm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrintSizeCm, sizeCm);
  }

  static Future<Set<String>> getHiddenTileKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final csv = prefs.getString(_kHiddenTileKeys) ?? '';
    if (csv.isEmpty) return {};
    return csv.split(',').toSet();
  }

  static Future<void> saveHiddenTileKeys(Set<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHiddenTileKeys, keys.join(','));
  }
}
