import 'package:shared_preferences/shared_preferences.dart';

const _kPrintSizeCm = 'print_size_cm';
const _kDefaultPrintSizeCm = 5.0;
const _kHiddenTileKeys = 'hidden_tile_keys';
const _kQrEyeShape = 'qr_eye_shape';
const _kQrDataModuleShape = 'qr_data_module_shape';
const _kQrEmbedIcon = 'qr_embed_icon';
const _kQrCenterEmoji = 'qr_center_emoji';

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

  static Future<String> getQrEyeShape() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kQrEyeShape) ?? 'square';
  }

  static Future<void> saveQrEyeShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQrEyeShape, shape);
  }

  static Future<String> getQrDataModuleShape() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kQrDataModuleShape) ?? 'square';
  }

  static Future<void> saveQrDataModuleShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQrDataModuleShape, shape);
  }

  static Future<bool> getQrEmbedIcon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kQrEmbedIcon) ?? false;
  }

  static Future<void> saveQrEmbedIcon(bool embed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kQrEmbedIcon, embed);
  }

  static Future<String?> getQrCenterEmoji() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kQrCenterEmoji);
  }

  static Future<void> saveQrCenterEmoji(String? emoji) async {
    final prefs = await SharedPreferences.getInstance();
    if (emoji == null) {
      await prefs.remove(_kQrCenterEmoji);
    } else {
      await prefs.setString(_kQrCenterEmoji, emoji);
    }
  }
}
