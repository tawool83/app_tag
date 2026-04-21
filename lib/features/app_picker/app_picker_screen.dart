import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/deep_link_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/output_action_buttons.dart';
import 'domain/entities/app_info.dart';
import 'presentation/providers/app_picker_providers.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  AppInfo? _selectedApp;

  Map<String, dynamic> _buildArgs() => {
        'appName': _selectedApp!.appName,
        'deepLink': DeepLinkConstants.androidIntentLink(_selectedApp!.packageName),
        'packageName': _selectedApp!.packageName,
        'platform': 'android',
        'appIconBytes': _selectedApp!.icon,
      };

  void _onQr() {
    if (_selectedApp == null) {
      context.showSnack(AppLocalizations.of(context)!.msgSelectApp);
      return;
    }
    context.push('/qr-result', extra: _buildArgs());
  }

  void _onNfc() {
    if (_selectedApp == null) {
      context.showSnack(AppLocalizations.of(context)!.msgSelectApp);
      return;
    }
    context.push('/nfc-writer', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appListProvider);
    final filtered = ref.watch(filteredAppsProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenAppPickerTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.hintAppSearch,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── 앱 목록 ──────────────────────────────────────────────
          Expanded(
            child: appsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(l10n.msgAppListError),
                    const SizedBox(height: 8),
                    Text('$e',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              data: (_) => filtered.isEmpty
                  ? Center(child: Text(l10n.msgSearchNoResults))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final app = filtered[index];
                        final isSelected = _selectedApp?.packageName ==
                            app.packageName;
                        return _AppListTile(
                          app: app,
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedApp = app),
                        );
                      },
                    ),
            ),
          ),

          // ── QR / NFC 버튼 ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: OutputActionButtons(
              onQrPressed: _onQr,
              onNfcPressed: _onNfc,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppListTile extends StatelessWidget {
  final AppInfo app;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppListTile({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      leading: app.icon != null
          ? Image.memory(app.icon!, width: 40, height: 40)
          : const Icon(Icons.android, size: 40),
      title: Text(app.appName),
      subtitle: Text(
        app.packageName,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
