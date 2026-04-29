import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/settings_service.dart';
import '../auth/presentation/providers/auth_providers.dart';
import '../sync/presentation/providers/sync_providers.dart';

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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _readabilityAlert = false;
  bool _moreBarcodesEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      SettingsService.getReadabilityAlert(),
      SettingsService.getMoreBarcodesEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _readabilityAlert = results[0];
      _moreBarcodesEnabled = results[1];
    });
  }

  void _showMoreBarcodesInfo(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsMoreBarcodesInfoTitle),
        content: Text(l10n.settingsMoreBarcodesInfoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentCode = currentLocale?.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 계정 섹션 ──
          _AccountSection(),
          const Divider(),
          // 언어 설정
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<String?>(
              value: currentCode,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(8),
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
          const Divider(),
          // 인식률 알림 설정
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settingsReadabilityAlert),
            value: _readabilityAlert,
            onChanged: (v) {
              setState(() => _readabilityAlert = v);
              SettingsService.saveReadabilityAlert(v);
            },
          ),
          // 더 많은 바코드 사용 (PDF417, DataMatrix, EAN, UPC, ... 마스터 게이트)
          // 본 cycle 에서는 설정값만 저장. 토글 ON 시 다른 화면 변화 없음.
          SwitchListTile(
            secondary: const Icon(Icons.qr_code_2_outlined),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(l10n.settingsMoreBarcodes)),
                const SizedBox(width: 4),
                InkResponse(
                  onTap: () => _showMoreBarcodesInfo(context, l10n),
                  radius: 16,
                  child: Icon(Icons.info_outline,
                      size: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
            value: _moreBarcodesEnabled,
            onChanged: (v) {
              setState(() => _moreBarcodesEnabled = v);
              SettingsService.saveMoreBarcodesEnabled(v);
            },
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final user = authState.user;

    if (user == null) {
      // 비로그인 상태
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(l10n.loginPrompt),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/login'),
      );
    }

    // 로그인 상태
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user.nickname ?? user.email),
          subtitle: Text(user.email),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/profile'),
        ),
        if (syncState.templateSync != SyncStatus.idle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  syncState.templateSync == SyncStatus.synced
                      ? Icons.cloud_done
                      : syncState.templateSync == SyncStatus.syncing
                          ? Icons.sync
                          : Icons.cloud_off,
                  size: 16,
                  color: syncState.templateSync == SyncStatus.error
                      ? Colors.red
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  syncState.templateSync == SyncStatus.synced
                      ? l10n.synced
                      : syncState.templateSync == SyncStatus.syncing
                          ? l10n.syncing
                          : l10n.syncError,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
