import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return [
      _TileItem(
        key: 'app',
        icon: Platform.isAndroid ? Icons.apps : CupertinoIcons.square_stack_3d_up,
        label: Platform.isAndroid ? '앱 실행' : '단축어',
        iconColor: Colors.indigo,
        onTap: () => Navigator.pushNamed(
          context,
          Platform.isAndroid ? '/app-picker' : '/ios-input',
        ),
      ),
      _TileItem(
        key: 'clipboard',
        icon: Icons.content_paste,
        label: '클립보드',
        iconColor: Colors.blueGrey,
        onTap: () => Navigator.pushNamed(context, '/clipboard-tag'),
      ),
      _TileItem(
        key: 'website',
        icon: Icons.language,
        label: '웹 사이트',
        iconColor: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/website-tag'),
      ),
      _TileItem(
        key: 'contact',
        icon: Icons.contact_phone,
        label: '연락처',
        iconColor: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/contact-tag'),
      ),
      _TileItem(
        key: 'wifi',
        icon: Icons.wifi,
        label: 'WiFi',
        iconColor: Colors.teal,
        onTap: () => Navigator.pushNamed(context, '/wifi-tag'),
      ),
      _TileItem(
        key: 'location',
        icon: Icons.location_on,
        label: '위치',
        iconColor: Colors.red,
        onTap: () => Navigator.pushNamed(context, '/location-tag'),
      ),
      _TileItem(
        key: 'event',
        icon: Icons.event,
        label: '이벤트/일정',
        iconColor: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/event-tag'),
      ),
      _TileItem(
        key: 'email',
        icon: Icons.email,
        label: '이메일',
        iconColor: Colors.deepPurple,
        onTap: () => Navigator.pushNamed(context, '/email-tag'),
      ),
      _TileItem(
        key: 'sms',
        icon: Icons.sms,
        label: 'SMS',
        iconColor: Colors.pink,
        onTap: () => Navigator.pushNamed(context, '/sms-tag'),
      ),
    ];
  }

  AppBar _buildAppBar() {
    if (_editMode) {
      return AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.nfc),
        ),
        title: const Text('편집 모드'),
        actions: [
          TextButton(
            onPressed: _exitEditMode,
            child: const Text('완료', style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    }
    return AppBar(
      leadingWidth: 72,
      leading: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code),
            SizedBox(width: 4),
            Icon(Icons.nfc),
          ],
        ),
      ),
      title: const Text(
        'QR, NFC 생성기',
        style: TextStyle(
            fontFamily: 'BitcountGridDouble', fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: '사용 안내',
          onPressed: () => Navigator.pushNamed(context, '/help'),
        ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: '생성 이력',
          onPressed: () => Navigator.pushNamed(context, '/history'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        appBar: _buildAppBar(),
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
      body: SingleChildScrollView(
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
                      ? '숨긴 메뉴 접기'
                      : '숨긴 메뉴 보기 (${hiddenTiles.length})',
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
  final VoidCallback onTap;

  const _TileItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.iconColor,
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
      elevation: 2,
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
                  fontSize: 21, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
