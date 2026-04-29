import 'package:shared_preferences/shared_preferences.dart';

const _kPrintSizeCm = 'print_size_cm';
const _kDefaultPrintSizeCm = 5.0;
const _kHiddenTileKeys = 'hidden_tile_keys';
const _kQrEyeShape = 'qr_eye_shape';
const _kQrDataModuleShape = 'qr_data_module_shape';
const _kQrEmbedIcon = 'qr_embed_icon';
const _kQrCenterEmoji = 'qr_center_emoji';
const _kActiveTemplateId = 'active_template_id';
const _kLocaleCode = 'app_locale';
const _kReadabilityAlert = 'readability_alert';
const _kMoreBarcodes = 'more_barcodes_enabled';

class SettingsService {
  // 앱 생명주기 동안 SharedPreferences Future 를 재사용 — 매 호출 getInstance() 반복 제거.
  // SharedPreferences 자체도 내부 캐시가 있지만 Future round-trip 을 아예 회피.
  static Future<SharedPreferences>? _cached;
  static Future<SharedPreferences> get _prefs =>
      _cached ??= SharedPreferences.getInstance();

  // ── 내부 헬퍼: null 이면 키 제거, 아니면 set ──
  static Future<void> _setStringOrRemove(String key, String? value) async {
    final p = await _prefs;
    if (value == null) {
      await p.remove(key);
    } else {
      await p.setString(key, value);
    }
  }

  // ── Locale ──
  static Future<String?> getLocaleCode() async =>
      (await _prefs).getString(_kLocaleCode);
  static Future<void> saveLocaleCode(String? code) =>
      _setStringOrRemove(_kLocaleCode, code);

  // ── Readability alert ──
  static Future<bool> getReadabilityAlert() async =>
      (await _prefs).getBool(_kReadabilityAlert) ?? false;
  static Future<void> saveReadabilityAlert(bool enabled) async =>
      (await _prefs).setBool(_kReadabilityAlert, enabled);

  // ── More barcodes (PDF417, DataMatrix, EAN, UPC, Code128, ... 마스터 게이트) ──
  // 본 cycle 에서는 설정값만 저장. 실제 분기 동작은 향후 cycle 에서 구현.
  static Future<bool> getMoreBarcodesEnabled() async =>
      (await _prefs).getBool(_kMoreBarcodes) ?? false;
  static Future<void> saveMoreBarcodesEnabled(bool enabled) async =>
      (await _prefs).setBool(_kMoreBarcodes, enabled);

  // ── Print size ──
  static Future<double> getLastPrintSizeCm() async =>
      (await _prefs).getDouble(_kPrintSizeCm) ?? _kDefaultPrintSizeCm;
  static Future<void> saveLastPrintSizeCm(double sizeCm) async =>
      (await _prefs).setDouble(_kPrintSizeCm, sizeCm);

  // ── Hidden tile keys ──
  static Future<Set<String>> getHiddenTileKeys() async {
    final csv = (await _prefs).getString(_kHiddenTileKeys) ?? '';
    if (csv.isEmpty) return {};
    return csv.split(',').toSet();
  }

  static Future<void> saveHiddenTileKeys(Set<String> keys) async =>
      (await _prefs).setString(_kHiddenTileKeys, keys.join(','));

  // ── QR shape/style ──
  static Future<String> getQrEyeShape() async =>
      (await _prefs).getString(_kQrEyeShape) ?? 'square';
  static Future<void> saveQrEyeShape(String shape) async =>
      (await _prefs).setString(_kQrEyeShape, shape);

  static Future<String> getQrDataModuleShape() async =>
      (await _prefs).getString(_kQrDataModuleShape) ?? 'square';
  static Future<void> saveQrDataModuleShape(String shape) async =>
      (await _prefs).setString(_kQrDataModuleShape, shape);

  static Future<bool> getQrEmbedIcon() async =>
      (await _prefs).getBool(_kQrEmbedIcon) ?? false;
  static Future<void> saveQrEmbedIcon(bool embed) async =>
      (await _prefs).setBool(_kQrEmbedIcon, embed);

  // ── Center emoji (nullable) ──
  static Future<String?> getQrCenterEmoji() async =>
      (await _prefs).getString(_kQrCenterEmoji);
  static Future<void> saveQrCenterEmoji(String? emoji) =>
      _setStringOrRemove(_kQrCenterEmoji, emoji);

  // ── Active template (nullable) ──
  static Future<String?> getActiveTemplateId() async =>
      (await _prefs).getString(_kActiveTemplateId);
  static Future<void> saveActiveTemplateId(String? id) =>
      _setStringOrRemove(_kActiveTemplateId, id);
}
