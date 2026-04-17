import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';

const _kSupportedLanguages = [
  (code: null, nativeName: null),       // 시스템 기본
  (code: 'ko', nativeName: '한국어'),
  (code: 'en', nativeName: 'English'),
  (code: 'ja', nativeName: '日本語'),
  (code: 'zh', nativeName: '中文(简体)'),
  (code: 'es', nativeName: 'Español'),
  (code: 'fr', nativeName: 'Français'),
  (code: 'de', nativeName: 'Deutsch'),
  (code: 'pt', nativeName: 'Português'),
  (code: 'vi', nativeName: 'Tiếng Việt'),
  (code: 'th', nativeName: 'ภาษาไทย'),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentCode = currentLocale?.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 언어 설정 항목
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<String?>(
              value: currentCode,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: _kSupportedLanguages.map((lang) {
                return DropdownMenuItem<String?>(
                  value: lang.code,
                  child: Text(
                    lang.nativeName ?? l10n.settingsLanguageSystem,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (code) {
                final locale = code != null ? Locale(code) : null;
                ref.read(localeProvider.notifier).setLocale(locale);
              },
            ),
          ),
        ],
      ),
    );
  }
}
