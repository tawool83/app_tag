import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';

const _kSupportedLanguages = [
  (locale: null, nativeName: null),       // 시스템 기본
  (locale: Locale('ko'), nativeName: '한국어'),
  (locale: Locale('en'), nativeName: 'English'),
  (locale: Locale('ja'), nativeName: '日本語'),
  (locale: Locale('zh'), nativeName: '中文(简体)'),
  (locale: Locale('es'), nativeName: 'Español'),
  (locale: Locale('fr'), nativeName: 'Français'),
  (locale: Locale('de'), nativeName: 'Deutsch'),
  (locale: Locale('pt'), nativeName: 'Português'),
  (locale: Locale('vi'), nativeName: 'Tiếng Việt'),
  (locale: Locale('th'), nativeName: 'ภาษาไทย'),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenSettingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settingsLanguage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ..._kSupportedLanguages.map((lang) {
            final isSelected = currentLocale?.languageCode ==
                lang.locale?.languageCode;
            final isSystem = lang.locale == null && currentLocale == null;

            return RadioListTile<String?>(
              value: lang.locale?.languageCode,
              groupValue: currentLocale?.languageCode,
              title: Text(
                lang.nativeName ?? l10n.settingsLanguageSystem,
                style: TextStyle(
                  fontWeight: (isSelected || isSystem)
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              onChanged: (_) {
                ref.read(localeProvider.notifier).setLocale(lang.locale);
              },
            );
          }),
        ],
      ),
    );
  }
}
