# Design: home-tile-visibility

> Plan 참조: `docs/01-plan/features/home-tile-visibility.plan.md`

---

## 1. 설계 개요

| 항목 | 내용 |
|------|------|
| Feature | home-tile-visibility |
| 작성일 | 2026-04-11 |
| 변경 파일 수 | 2개 |
| 신규 파일 | 없음 |
| 의존성 추가 | 없음 (shared_preferences 이미 존재) |

---

## 2. 아키텍처 변경

### 2.1 HomeScreen 위젯 전환

```
Before: StatelessWidget
After:  StatefulWidget (_HomeScreenState)
```

`StatelessWidget`에서 `StatefulWidget`으로 전환하는 이유:
- `_editMode` (편집 모드 활성화 여부)
- `_hiddenKeys` (숨긴 타일 key Set)
- `_showHiddenSection` (더보기 섹션 펼침 여부)
- `_initialized` (SharedPreferences 로드 완료 여부)

위 4개 상태가 모두 단일 화면 내에서 관리되므로 Riverpod 없이 `StatefulWidget`으로 충분하다.

---

## 3. 데이터 모델

### 3.1 TileItem 구조 변경

기존 `_TileItem`에 `key` 필드 추가:

```dart
class _TileItem {
  final String key;          // 새로 추가 — SharedPreferences 식별자
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
```

### 3.2 타일 Key 목록

| key | 라벨 | 아이콘 |
|-----|------|--------|
| `app` | 앱 실행 / 단축키 | `Icons.apps` / `Icons.shortcut` |
| `clipboard` | 클립보드 | `Icons.content_paste` |
| `website` | 웹 사이트 | `Icons.language` |
| `contact` | 연락처 | `Icons.contact_phone` |
| `wifi` | WiFi | `Icons.wifi` |
| `location` | 위치 | `Icons.location_on` |
| `event` | 이벤트/일정 | `Icons.event` |
| `email` | 이메일 | `Icons.email` |
| `sms` | SMS | `Icons.sms` |

---

## 4. State 설계

### 4.1 _HomeScreenState 필드

```dart
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
  ...
}
```

### 4.2 편집 모드 진입/종료

```dart
void _enterEditMode() {
  setState(() {
    _editMode = true;
    _showHiddenSection = false;  // 편집 모드 중 더보기 섹션 닫기
  });
}

void _exitEditMode() {
  setState(() => _editMode = false);
}
```

### 4.3 타일 숨기기

```dart
Future<void> _hideTile(String key) async {
  // 마지막 1개 보호
  final visibleCount = _allTiles.length - _hiddenKeys.length;
  if (visibleCount <= 1) return;

  setState(() => _hiddenKeys.add(key));
  await SettingsService.saveHiddenTileKeys(_hiddenKeys);
}
```

### 4.4 타일 복원

```dart
Future<void> _restoreTile(String key) async {
  setState(() => _hiddenKeys.remove(key));
  await SettingsService.saveHiddenTileKeys(_hiddenKeys);
}
```

---

## 5. UI 컴포넌트 설계

### 5.1 build() 구조

```dart
@override
Widget build(BuildContext context) {
  if (!_initialized) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  final allTiles = _buildTiles(context);
  final visibleTiles = allTiles.where((t) => !_hiddenKeys.contains(t.key)).toList();
  final hiddenTiles  = allTiles.where((t) =>  _hiddenKeys.contains(t.key)).toList();

  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(visibleTiles, hiddenTiles),
  );
}
```

### 5.2 AppBar 설계

```dart
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
  // 기존 AppBar (일반 모드)
  return AppBar(
    leading: const Padding(...),
    title: const Text('App Tag', style: TextStyle(fontFamily: 'BitcountGridDouble', ...)),
    actions: [
      IconButton(icon: const Icon(Icons.help_outline), ...),
      IconButton(icon: const Icon(Icons.history), ...),
    ],
  );
}
```

### 5.3 Body 레이아웃

```dart
Widget _buildBody(List<_TileItem> visibleTiles, List<_TileItem> hiddenTiles) {
  return SingleChildScrollView(
    child: Column(
      children: [
        // 메인 그리드 (보이는 타일)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: visibleTiles.map((t) => _buildTileWithBadge(t, visibleTiles.length)).toList(),
        ),

        // 더보기 버튼 (숨긴 타일 있고 편집 모드 아닐 때)
        if (hiddenTiles.isNotEmpty && !_editMode)
          _buildShowMoreButton(hiddenTiles),
      ],
    ),
  );
}
```

### 5.4 타일 + X 배지

```dart
Widget _buildTileWithBadge(_TileItem tile, int visibleCount) {
  final isLastVisible = visibleCount == 1;

  return Stack(
    clipBehavior: Clip.none,
    children: [
      // 타일 카드
      _TileCard(
        item: tile,
        editMode: _editMode,
        onLongPress: _editMode ? null : _enterEditMode,
      ),

      // X 배지 (편집 모드일 때만)
      if (_editMode)
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: isLastVisible ? null : () => _hideTile(tile.key),
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
```

### 5.5 _TileCard 수정 (onLongPress 추가)

```dart
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
        onTap: editMode ? null : item.onTap,       // 편집 모드 중 탭 비활성화
        onLongPress: onLongPress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 48, color: item.iconColor),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.6 더보기 섹션

```dart
Widget _buildShowMoreButton(List<_TileItem> hiddenTiles) {
  return Column(
    children: [
      // 더보기 / 접기 버튼
      InkWell(
        onTap: () => setState(() => _showHiddenSection = !_showHiddenSection),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _showHiddenSection ? '숨긴 메뉴 접기' : '숨긴 메뉴 보기 (${hiddenTiles.length})',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showHiddenSection ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),

      // 숨긴 타일 그리드 (펼쳤을 때만)
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
            children: hiddenTiles
                .map((t) => _TileCard(
                      item: t,
                      editMode: false,
                      onLongPress: null,
                    ))
                .toList(),
          ),
        ),
    ],
  );
}
```

> 숨긴 타일 탭 시 `_TileCard`의 `onTap`에서 `_restoreTile(tile.key)` 호출.
> 단, 숨긴 타일은 `item.onTap`이 기존 네비게이션 로직이므로 복원 전용 onTap을 별도로 전달해야 한다.
>
> **수정 방향**: `_TileCard`에 `overrideTap` 파라미터를 추가하거나, 숨긴 섹션용으로 `onTap` 자체를 복원 함수로 교체한다.

#### 숨긴 타일 복원 onTap 처리

```dart
// 숨긴 타일 그리드에서는 onTap을 복원 로직으로 오버라이드
children: hiddenTiles.map((t) {
  final restoreTile = _TileItem(
    key: t.key,
    icon: t.icon,
    label: t.label,
    iconColor: t.iconColor,
    onTap: () => _restoreTile(t.key),  // 복원 함수로 교체
  );
  return _TileCard(item: restoreTile, editMode: false);
}).toList(),
```

---

## 6. SettingsService 추가 메서드

**파일**: `lib/services/settings_service.dart`

```dart
const _kHiddenTileKeys = 'hidden_tile_keys';

static Future<Set<String>> getHiddenTileKeys() async {
  final prefs = await SharedPreferences.getInstance();
  final csv = prefs.getString(_kHiddenTileKeys) ?? '';
  if (csv.isEmpty) return {};
  return csv.split(',').toSet();
}

static Future<void> saveHiddenTileKeys(Set<String> keys) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kHiddenTileKeys, keys.join(','));
}
```

---

## 7. 전체 데이터 흐름

```
앱 시작
  └─ initState()
       └─ SettingsService.getHiddenTileKeys()
            └─ SharedPreferences → _hiddenKeys 로드
            └─ setState(_initialized = true)

사용자: 타일 길게 누름
  └─ _enterEditMode() → _editMode = true → rebuild
  └─ 각 타일에 X 배지 표시

사용자: X 배지 탭
  └─ _hideTile(key)
       └─ visibleCount > 1 검사
       └─ _hiddenKeys.add(key)
       └─ SettingsService.saveHiddenTileKeys(_hiddenKeys)
       └─ setState → rebuild (타일 사라짐)

사용자: "완료" 탭
  └─ _exitEditMode() → _editMode = false → rebuild
  └─ 숨긴 타일 있으면 "더보기" 버튼 표시

사용자: "더보기" 탭
  └─ _showHiddenSection = true → rebuild
  └─ 숨긴 타일 그리드 표시 (opacity 0.5)

사용자: 숨긴 타일 탭
  └─ _restoreTile(key)
       └─ _hiddenKeys.remove(key)
       └─ SettingsService.saveHiddenTileKeys(_hiddenKeys)
       └─ setState → rebuild (타일 복원)
```

---

## 8. 파일별 변경 명세

### 8.1 `lib/features/home/home_screen.dart`

| 변경 항목 | 설명 |
|---------|------|
| `HomeScreen` 클래스 | `StatelessWidget` → `StatefulWidget` |
| `_HomeScreenState` | 신규 State 클래스 (4개 필드, 4개 메서드) |
| `_buildTiles()` | `_TileItem`에 `key` 필드 추가 |
| `_TileItem` | `key: String` 필드 추가 |
| `_TileCard` | `editMode: bool`, `onLongPress` 파라미터 추가 |
| `_buildAppBar()` | 편집 모드/일반 모드 분기 |
| `_buildBody()` | `SingleChildScrollView` + 그리드 + 더보기 섹션 |
| `_buildTileWithBadge()` | `Stack` + `Positioned` X 배지 |
| `_buildShowMoreButton()` | 더보기 버튼 + 숨긴 타일 그리드 |

### 8.2 `lib/services/settings_service.dart`

| 변경 항목 | 설명 |
|---------|------|
| `_kHiddenTileKeys` | 상수 추가 |
| `getHiddenTileKeys()` | `Future<Set<String>>` 반환 |
| `saveHiddenTileKeys()` | `Set<String>` → comma-separated string 저장 |

---

## 9. 수용 기준 (Acceptance Criteria)

- [ ] `_initialized = false`일 때 로딩 스피너 표시
- [ ] 아무 타일이나 길게 누르면 `_editMode = true`, X 배지 + "완료" 버튼 표시
- [ ] 편집 모드에서 타일 onTap 비활성화 (X 배지만 반응)
- [ ] X 탭 → 해당 타일이 그리드에서 제거, SharedPreferences 저장
- [ ] 표시 중 타일이 1개뿐일 때 X 배지가 회색이며 탭해도 숨기지 않음
- [ ] "완료" → 편집 모드 종료, 더보기 버튼 표시 (숨긴 타일 있을 때)
- [ ] "더보기" 탭 → 숨긴 타일 그리드 펼침 (opacity 0.5)
- [ ] 숨긴 타일 탭 → 복원, SharedPreferences 저장
- [ ] 앱 재시작 후 숨김 상태 유지
