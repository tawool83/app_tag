import 'package:shared_preferences/shared_preferences.dart';

const _kPrintSizeCm = 'print_size_cm';
const _kDefaultPrintSizeCm = 5.0;

class SettingsService {
  static Future<double> getLastPrintSizeCm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kPrintSizeCm) ?? _kDefaultPrintSizeCm;
  }

  static Future<void> saveLastPrintSizeCm(double sizeCm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrintSizeCm, sizeCm);
  }
}
