import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/settings_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/providers/auth_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _editMode = false;
  Set<String> _hiddenKeys = {};
  bool _showHiddenSection = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadHiddenKeys();
  }

  Future<void> _loadHiddenKeys() async {
    final keys = await SettingsService.getHiddenTileKeys();
    setState(() {
      _hiddenKeys = keys;
      _initialized = true;
    });
  }

  void _enterEditMode() {
    setState(() {
      _editMode = true;
      _showHiddenSection = false;
    });
  }

  void _exitEditMode() {
    setState(() => _editMode = false);
  }

  Future<void> _hideTile(String key, int visibleCount) async {
    if (visibleCount <= 1) return;
    setState(() => _hiddenKeys.add(key));
    await SettingsService.saveHiddenTileKeys(_hiddenKeys);
  }

  Future<void> _restoreTile(String key) async {
    setState(() => _hiddenKeys.remove(key));
    await SettingsService.saveHiddenTileKeys(_hiddenKeys);
  }

  List<_TileItem> _buildTiles() {
    final l10n = AppLocalizations.of(context)!;
    return [
      _TileItem(
        key: 'app',
        icon: Platform.isAndroid ? Icons.apps : CupertinoIcons.square_stack_3d_up,
        label: Platform.isAndroid ? l10n.tileAppAndroid : l10n.tileAppIos,
        iconColor: Colors.white,
        bgColor: const Color(0xFF5C6BC0),
        onTap: () => context.push(
          Platform.isAndroid ? '/app-picker' : '/ios-input',
        ),
      ),
      _TileItem(
        key: 'clipboard',
        icon: Icons.content_paste,
        label: l10n.tileClipboard,
        iconColor: Colors.white,
        bgColor: const Color(0xFF78909C),
        onTap: () => context.push('/clipboard-tag'),
      ),
      _TileItem(
        key: 'website',
        icon: Icons.language,
        label: l10n.tileWebsite,
        iconColor: Colors.white,
        bgColor: const Color(0xFF42A5F5),
        onTap: () => context.push('/website-tag'),
      ),
      _TileItem(
        key: 'contact',
        icon: Icons.contact_phone,
        label: l10n.tileContact,
        iconColor: Colors.white,
        bgColor: const Color(0xFF66BB6A),
        onTap: () => context.push('/contact-tag'),
      ),
      _TileItem(
        key: 'wifi',
        icon: Icons.wifi,
        label: l10n.tileWifi,
        iconColor: Colors.white,
        bgColor: const Color(0xFF26A69A),
        onTap: () => context.push('/wifi-tag'),
      ),
      _TileItem(
        key: 'location',
        icon: Icons.location_on,
        label: l10n.tileLocation,
        iconColor: Colors.white,
        bgColor: const Color(0xFFEF5350),
        onTap: () => context.push('/location-tag'),
      ),
      _TileItem(
        key: 'event',
        icon: Icons.event,
        label: l10n.tileEvent,
        iconColor: Colors.white,
        bgColor: const Color(0xFFFFA726),
        onTap: () => context.push('/event-tag'),
      ),
      _TileItem(
        key: 'email',
        icon: Icons.email,
        label: l10n.tileEmail,
        iconColor: Colors.white,
        bgColor: const Color(0xFF7E57C2),
        onTap: () => context.push('/email-tag'),
      ),
      _TileItem(
        key: 'sms',
        icon: Icons.sms,
        label: l10n.tileSms,
        iconColor: Colors.white,
        bgColor: const Color(0xFFEC407A),
        onTap: () => context.push('/sms-tag'),
      ),
    ];
  }

  AppBar _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    if (_editMode) {
      return AppBar(
        title: Text(l10n.screenHomeEditModeTitle),
        actions: [
          TextButton(
            onPressed: _exitEditMode,
            child: Text(l10n.actionDone, style: const TextStyle(fontSize: 16)),
          ),
        ],
      );
    }
    final isLoggedIn = ref.watch(authProvider).user != null;
    return AppBar(
      actions: [
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allTiles = _buildTiles();
    final visibleTiles =
        allTiles.where((t) => !_hiddenKeys.contains(t.key)).toList();
    final hiddenTiles =
        allTiles.where((t) => _hiddenKeys.contains(t.key)).toList();

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _editMode ? null : _buildDrawer(),
      body: Stack(
        children: [
          // 고정 배경 로고
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.06,
                child: Image.asset(
                  'assets/img/logo.png',
                  width: 240,
                  height: 240,
                ),
              ),
            ),
          ),
          // 스크롤 가능한 콘텐츠
          SingleChildScrollView(
        child: Column(
          children: [
            // 메인 그리드
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: visibleTiles
                  .map((t) => _buildTileWithBadge(t, visibleTiles.length))
                  .toList(),
            ),

            // 더보기 버튼 + 숨긴 타일 섹션
            if (hiddenTiles.isNotEmpty && !_editMode)
              _buildHiddenSection(hiddenTiles),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildTileWithBadge(_TileItem tile, int visibleCount) {
    final isLastVisible = visibleCount == 1;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        _TileCard(
          item: tile,
          editMode: _editMode,
          onLongPress: _editMode ? null : _enterEditMode,
        ),
        if (_editMode)
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: isLastVisible ? null : () => _hideTile(tile.key, visibleCount),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isLastVisible ? Colors.grey : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHiddenSection(List<_TileItem> hiddenTiles) {
    return Column(
      children: [
        // 더보기 / 접기 버튼
        InkWell(
          onTap: () =>
              setState(() => _showHiddenSection = !_showHiddenSection),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showHiddenSection
                      ? AppLocalizations.of(context)!.actionCollapseHidden
                      : AppLocalizations.of(context)!.actionShowHidden(hiddenTiles.length),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showHiddenSection
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        // 숨긴 타일 그리드
        if (_showHiddenSection)
          Opacity(
            opacity: 0.5,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: hiddenTiles.map((t) {
                final restoreTile = _TileItem(
                  key: t.key,
                  icon: t.icon,
                  label: t.label,
                  iconColor: t.iconColor,
                  bgColor: t.bgColor,
                  onTap: () => _restoreTile(t.key),
                );
                return _TileCard(
                  item: restoreTile,
                  editMode: false,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── 데이터 모델 ────────────────────────────────────────────────────────────────

class _TileItem {
  final String key;
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _TileItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });
}

// ── 타일 카드 위젯 ─────────────────────────────────────────────────────────────

class _TileCard extends StatelessWidget {
  final _TileItem item;
  final bool editMode;
  final VoidCallback? onLongPress;

  const _TileCard({
    required this.item,
    required this.editMode,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: item.bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: editMode ? null : item.onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 48, color: item.iconColor),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w600, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
