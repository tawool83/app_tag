import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/legal_urls.dart';
import '../../core/error/result.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/providers/auth_providers.dart';
import '../qr_result/domain/entities/template_engine_version.dart';
import '../qr_task/domain/entities/qr_task.dart';
import '../qr_task/presentation/providers/qr_task_providers.dart';
import 'widgets/create_picker_sheet.dart';
import 'widgets/qr_task_action_sheet.dart';
import 'widgets/qr_task_gallery_card.dart';  // QrTaskGalleryTile

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<QrTask> _tasks = [];
  bool _loading = true;

  /// 삭제 모드 활성 여부.
  bool _deleteMode = false;

  /// 삭제 모드에서 선택된 task id 들.
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final result = await ref.read(listHomeVisibleUseCaseProvider)();
    if (!mounted) return;
    setState(() {
      _tasks = result.valueOrNull ?? [];
      _loading = false;
    });
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const CreatePickerSheet(),
    );
  }

  void _showActionSheet(QrTask task) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: QrTaskActionSheet(
          task: task,
          onChanged: _loadTasks,
        ),
      ),
    );
  }

  // ── 삭제 모드 ────────────────────────────────────────────────────────

  void _enterDeleteMode() {
    setState(() {
      _deleteMode = true;
      _selectedIds.clear();
    });
  }

  void _exitDeleteMode() {
    setState(() {
      _deleteMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// "모두선택" 탭 → 즐겨찾기 제외한 전체 항목 선택.
  void _selectAll() {
    setState(() {
      _selectedIds.addAll(
        _tasks.where((t) => !t.isFavorite).map((t) => t.id),
      );
    });
  }

  /// "확인" 탭 → 선택된 항목 삭제 확인 다이얼로그.
  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.dialogDeleteSelectedTitle),
        content: Text(l10n.dialogDeleteSelectedContent(_selectedIds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final hideUseCase = ref.read(hideFromHomeUseCaseProvider);
      for (final id in _selectedIds) {
        await hideUseCase(id);
      }
      _exitDeleteMode();
      _loadTasks();
    }
  }

  AppBar _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(authProvider).user != null;
    return AppBar(
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: l10n.tileScanner,
          onPressed: () => context.push('/scanner'),
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: l10n.tooltipHelp,
          onPressed: () => context.push('/help'),
        ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: l10n.tooltipHistory,
          onPressed: () => context.push('/history'),
        ),
        IconButton(
          icon: Icon(isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined),
          tooltip: isLoggedIn ? l10n.profileTitle : l10n.loginPrompt,
          onPressed: () => context.push(isLoggedIn ? '/profile' : '/login'),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset('assets/img/logo.png', width: 48),
                const SizedBox(height: 12),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.screenSettingsTitle),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.drawerSvgStorage),
            onTap: () {
              Navigator.pop(context);
              context.push('/svg-storage');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.drawerAppInfo),
            onTap: () {
              Navigator.pop(context);
              _showAppInfoDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAppInfoDialog() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: '${info.version} (${l10n.appInfoBuild} ${info.buildNumber})',
      applicationIcon: Image.asset('assets/img/logo.png', width: 64, height: 64),
      children: [
        const SizedBox(height: 16),
        Text('${l10n.appInfoTemplateEngine} v$kTemplateEngineVersion'),
        const SizedBox(height: 4),
        Text('${l10n.appInfoTemplateSchema} v$kTemplateSchemaVersion'),
        const Divider(height: 24),
        _LegalLinkTile(
          icon: Icons.privacy_tip_outlined,
          label: l10n.legalPrivacyPolicy,
          url: LegalUrls.privacyPolicy,
        ),
        _LegalLinkTile(
          icon: Icons.description_outlined,
          label: l10n.legalTermsOfService,
          url: LegalUrls.termsOfService,
        ),
        _LegalLinkTile(
          icon: Icons.person_remove_outlined,
          label: l10n.legalAccountDeletion,
          url: LegalUrls.accountDeletion,
        ),
        _LegalLinkTile(
          icon: Icons.mail_outline,
          label: l10n.legalSupport,
          url: LegalUrls.support,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // ── CTA: 새로 만들기 + 삭제 버튼 ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: FilledButton.icon(
                      onPressed: _deleteMode ? null : _showCreateSheet,
                      icon: const Icon(Icons.add, size: 28),
                      label: Text(
                        l10n.actionCreateNew,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                if (_tasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 64,
                    child: _deleteMode
                        ? _buildDeleteModeButton(l10n)
                        : IconButton.filled(
                            onPressed: _enterDeleteMode,
                            icon: const Icon(Icons.delete_outline),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(56, 64),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),

          // ── QrTask 타일 갤러리 ──────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? _buildEmptyState(l10n)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 100 / 130,
                        ),
                        itemCount: _tasks.length,
                        itemBuilder: (_, i) {
                          final task = _tasks[i];
                          return QrTaskGalleryTile(
                            task: task,
                            selectable: _deleteMode,
                            selected: _selectedIds.contains(task.id),
                            onTap: _deleteMode
                                ? () => _toggleSelection(task.id)
                                : () => _showActionSheet(task),
                            onLongPress: _deleteMode
                                ? () => _toggleSelection(task.id)
                                : () => _showActionSheet(task),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 삭제 모드 버튼: 선택 없으면 "모두선택", 선택 있으면 "확인".
  /// 취소는 X 아이콘으로.
  Widget _buildDeleteModeButton(AppLocalizations l10n) {
    final hasSelection = _selectedIds.isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: hasSelection ? _confirmDeleteSelected : _selectAll,
          style: FilledButton.styleFrom(
            backgroundColor: hasSelection
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(0, 64),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(
            hasSelection ? l10n.actionConfirm : l10n.actionSelectAll,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _exitDeleteMode,
          icon: const Icon(Icons.close),
          tooltip: l10n.actionCancel,
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.homeEmptyTitle,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LegalLinkTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
