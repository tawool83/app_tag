import 'dart:ui' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final code = await SettingsService.getLocaleCode();
    state = code != null ? Locale(code) : null;
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await SettingsService.saveLocaleCode(locale?.languageCode);
  }
}
