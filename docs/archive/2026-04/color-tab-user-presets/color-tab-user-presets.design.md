# color-tab-user-presets — Design

> Plan: `docs/01-plan/features/color-tab-user-presets.plan.md` 기반.
> 본 프로젝트 CLAUDE.md 규약상 3-옵션 아키텍처 비교 생략. R-series Provider 패턴 내에서 `qr_color_tab.dart` 를 library + 5 part 구조로 분할.

---

## Executive Summary

| 항목 | 내용 |
|---|---|
| Architecture | R-series 내 구조화 (`qr_color_tab.dart` 824줄 → library + 5 part 분할) |
| Entity 변경 | `UserColorPalette` 무변경 (재사용). `QrGradient` 무변경 (dedup 은 helper 로) |
| Renderer 변경 | 없음 (`qrColor`/`customGradient` → 기존 setter) |
| State 변경 | `QrColorTabState` 에 `_userSolidPresets`/`_userGradientPresets`/`_selected*PresetId`/`_editingGradientPresetId` 추가 |
| Setter 변경 | `setQrColor` / `setCustomGradient` 시그니처 동일 |
| Hive schema 변경 | 없음 (typeId 3 유지). `HiveColorPaletteDataSource` 확장만 (`touchLastUsed`, `readAllSortedByRecency`, cache) |
| 신규 파일 | 5 part files (`shared` / `solid_row` / `gradient_row` / `gradient_editor` / `color_grid_modal`) |
| 수정 파일 | `qr_color_tab.dart` (library root 재작성), `hive_color_palette_datasource.dart`, `qr_color_presets.dart`, `qr_result_screen.dart` |
| l10n 추가 | 없음 (기존 `tabColorSolid`/`tabColorGradient`/`labelCustomGradient` 재활용) |

---

## 1. 기존 아키텍처 맥락

`qr_color_tab.dart` 는 **single-file 824줄** 구조 — CLAUDE.md Hard Rule 8 (UI part ≤ 400줄) 위반. 본 Design 은 **shape tab 분할 (R1)** 동형으로 library + part 패턴으로 재조직.

**현재 내부 구조** (single-file):
- state holder (`QrColorTabState`) — editor 상태 + 색상 stop 리스트
- editor UI (`_buildCustomEditor`, `_buildTypeAndOptionRow`, `_buildColorStopList`)
- 공용 위젯 (`_SectionHeader`, `_LabeledDropdown`, `_ColorCircle`, `_AddCircleButton`, `_GradientRect`, `_AddRectButton`)
- gradient slider (`_GradientSliderBar`, `_GradientSliderBarPainter`)
- `_ColorStop` 내부 모델

**Target 구조** (library + part):
```
lib/features/qr_result/tabs/
├── qr_color_tab.dart                          # library root (~620 줄 — editor UI 포함)
│     ├── library; (unnamed, Dart 3 idiom)
│     ├── import dart:math, flutter_material, flutter_colorpicker, flutter_riverpod
│     ├── import ../../../core/utils/color_hex.dart
│     ├── import ../domain/entities/qr_template.dart show QrGradient
│     ├── import ../domain/entities/qr_color_presets.dart
│     ├── import ../../../../features/color_palette/... (datasource, model)
│     ├── import ../../../l10n/app_localizations.dart
│     ├── import ../qr_result_provider.dart
│     │
│     ├── part 'qr_color_tab/shared.dart';
│     ├── part 'qr_color_tab/solid_row.dart';
│     ├── part 'qr_color_tab/gradient_row.dart';
│     ├── part 'qr_color_tab/gradient_editor.dart';
│     ├── part 'qr_color_tab/color_grid_modal.dart';
│     │
│     ├── class QrColorTab (public StatefulWidget)
│     └── class QrColorTabState (state + handlers)
│
└── qr_color_tab/
    ├── shared.dart                             # part of '../qr_color_tab.dart';
    ├── solid_row.dart                          # part of '../qr_color_tab.dart';
    ├── gradient_row.dart                       # part of '../qr_color_tab.dart';
    ├── gradient_editor.dart                    # part of '../qr_color_tab.dart';
    └── color_grid_modal.dart                   # part of '../qr_color_tab.dart';
```

**참조**: `lib/features/qr_result/tabs/qr_shape_tab.dart` 및 `qr_shape_tab/` 폴더가 완벽히 동일한 구조.

---

## 2. Entity / Model 재사용

### 2.1 `UserColorPalette` (domain/entities/user_color_palette.dart)

**그대로 사용** — 기존 필드가 요구사항 모두 커버:
- `id` (UUID)
- `name` (uuid.substring(0,8) 기본값)
- `type` (`PaletteType.solid | .gradient`)
- `solidColorArgb` (solid 전용)
- `gradientColorArgbs` / `gradientStops` / `gradientType` / `gradientAngle` (gradient 전용)
- `updatedAt` (최근 정렬 키)
- `sortOrder` (sync 용, UI 에서는 미사용)
- `remoteId` / `syncedToCloud` (sync 용)

### 2.2 `UserColorPaletteModel` (Hive, typeId=3)

**그대로 사용** — Hive schema 무변경. 기존 sync 인프라 호환 유지.

### 2.3 `QrGradient`

**그대로 사용**. dedup 에서는 엔티티의 `operator==` 이 colors/stops 를 무시하므로(type/angle/center 만 비교) **dedup 헬퍼를 따로 정의**:

```dart
// qr_color_tab/gradient_row.dart 내부 helper
bool _gradientEquals(QrGradient a, QrGradient b) {
  if (a.type != b.type) return false;
  if (a.angleDegrees != b.angleDegrees) return false;
  if (a.center != b.center) return false;
  if (a.colors.length != b.colors.length) return false;
  for (var i = 0; i < a.colors.length; i++) {
    if (a.colors[i].toARGB32() != b.colors[i].toARGB32()) return false;
  }
  final aStops = a.stops;
  final bStops = b.stops;
  if (aStops == null && bStops == null) return true;
  if (aStops == null || bStops == null) return false;
  if (aStops.length != bStops.length) return false;
  for (var i = 0; i < aStops.length; i++) {
    if ((aStops[i] - bStops[i]).abs() > 1e-6) return false;
  }
  return true;
}
```

`QrGradient` 자체 `operator==` 수정 안 함 (다른 사용처 영향 범위 예측 어려움).

---

## 3. Hive 데이터소스 확장

### 3.1 현재 (변경 전)

```dart
class HiveColorPaletteDataSource {
  static const String boxName = 'user_color_palettes';
  final Box<UserColorPaletteModel> _box;

  List<UserColorPaletteModel> readAll() { /* sortOrder 기반 */ }
  UserColorPaletteModel? readById(String id) => _box.get(id);
  Future<void> write(model) => _box.put(model.id, model);
  Future<void> delete(String id) => _box.delete(id);
  Future<void> clear() => _box.clear();
}
```

### 3.2 확장 후

```dart
class HiveColorPaletteDataSource {
  static const String boxName = 'user_color_palettes';
  final Box<UserColorPaletteModel> _box;

  // in-memory cache per type. save/delete 시 해당 type 무효화.
  final Map<PaletteType, List<UserColorPalette>> _cacheByType = {};

  const HiveColorPaletteDataSource(this._box);

  // ── 기존 (sync 용 유지) ──
  List<UserColorPaletteModel> readAll();
  UserColorPaletteModel? readById(String id);
  Future<void> write(UserColorPaletteModel model);  // + cache 무효화
  Future<void> delete(String id);                    // + cache 무효화
  Future<void> clear();                              // + cache 무효화

  // ── 신규 (UI 용) ──

  /// 타입별 필터링 + updatedAt desc 정렬. 캐시 적중 시 O(1).
  List<UserColorPalette> readAllSortedByRecency(PaletteType type) {
    return _cacheByType[type] ??= _loadFiltered(type);
  }

  List<UserColorPalette> _loadFiltered(PaletteType type) {
    final items = _box.values
        .where((m) => m.typeIndex == type.index)
        .map((m) => m.toEntity())
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  /// id 기반 updatedAt 만 갱신 (select 시 호출).
  Future<void> touchLastUsed(String id) async {
    final model = _box.get(id);
    if (model == null) return;
    model.updatedAt = DateTime.now();
    await model.save();
    _cacheByType.remove(PaletteType.values[model.typeIndex.clamp(0, 1)]);
  }
}
```

**참조**: `LocalUserShapePresetDatasource` (`qr_result/data/datasources/local_user_shape_preset_datasource.dart`) 과 캐시/정렬 패턴 동형.

---

## 4. qr_color_tab.dart (library root) 시그니처

### 4.1 Widget

```dart
library; // Dart 3 unnamed library — part 파일에서 `part of '../qr_color_tab.dart';` 로 참조

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/color_hex.dart' as app_color_hex;
import '../../color_palette/data/datasources/hive_color_palette_datasource.dart';
import '../../color_palette/data/models/user_color_palette_model.dart';
import '../../color_palette/domain/entities/user_color_palette.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/qr_color_presets.dart';
import '../domain/entities/qr_template.dart' show QrGradient;
import '../qr_result_provider.dart' show qrResultProvider;

part 'qr_color_tab/shared.dart';
part 'qr_color_tab/solid_row.dart';
part 'qr_color_tab/gradient_row.dart';
part 'qr_color_tab/gradient_editor.dart';
part 'qr_color_tab/color_grid_modal.dart';

/// [색상] 탭: built-in 5개 + 사용자 단색/그라디언트 프리셋 + 편집기.
class QrColorTab extends ConsumerStatefulWidget {
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged;
  final ValueChanged<bool>? onEditorModeChanged;

  const QrColorTab({
    super.key,
    required this.onColorSelected,
    required this.onGradientChanged,
    this.onEditorModeChanged,
  });

  @override
  ConsumerState<QrColorTab> createState() => QrColorTabState();
}
```

### 4.2 State

```dart
class QrColorTabState extends ConsumerState<QrColorTab> {
  // ── 프리셋 데이터 ──
  HiveColorPaletteDataSource? _datasource;
  List<UserColorPalette> _solidPresets = [];
  List<UserColorPalette> _gradientPresets = [];

  // ── 선택 상태 (null = built-in 또는 미선택) ──
  String? _selectedSolidPresetId;
  String? _selectedGradientPresetId;

  // ── 그라디언트 편집기 상태 ──
  bool _showGradientEditor = false;
  String? _editingGradientPresetId;
  String _gradientType = 'linear';
  double _angleDegrees = 45;
  String _center = 'center';
  late List<_ColorStop> _stops;

  // ── 재정렬 지연 타이머 (select 후 ~100ms 뒤 reorder) ──
  Timer? _reorderTimer;

  @override
  void initState() { ... _initDatasource() ... }
  @override
  void dispose() { _reorderTimer?.cancel(); super.dispose(); }

  Future<void> _initDatasource() async { ... }
  void _loadPresets() { setState(...) }
  void _delayedReloadPresets() { ... Timer 100ms ... }

  // ── 편집기 열기/닫기 ──
  void _openGradientEditor({String? editingId}) { ... }
  void _confirmGradientEditor() { ... applies + close ... }

  // ── 외부(부모) 호출용 공개 API ──
  Future<bool> cancelAndCloseEditor() async {
    // 뒤로가기 = 자동 저장 (도트/눈 동형)
    if (!_showGradientEditor) return true;
    if (_editingGradientPresetId != null) {
      await _updateExistingGradientPreset();
    } else {
      await _saveCurrentGradientAsPreset();
    }
    _confirmGradientEditor();
    return true;
  }
  Future<void> confirmAndCloseEditor() async { /* 탭 전환 시 동일 auto-save */ }
  String? activeEditorLabel(AppLocalizations l10n) =>
      _showGradientEditor ? l10n.labelCustomGradient : null;

  // ── Preset 저장/수정/삭제 ──
  Future<void> _saveSolidAsPreset(Color color) async { ... dedup + uuid + save ... }
  Future<void> _saveCurrentGradientAsPreset() async { ... dedup + save ... }
  Future<void> _updateExistingGradientPreset() async { ... id 기반 overwrite ... }

  // ── Select handlers ──
  void _onBuiltinSolidSelect(Color c) { ... clear selectedSolidId + setQrColor(c) + clearGradient ... }
  void _onUserSolidSelect(UserColorPalette p) async { ... setQrColor + touchLastUsed + delayedReload ... }
  void _onUserSolidLongPress(UserColorPalette p) async {
    // color wheel + 신규 생성 (원본 유지) — 사용자 Q3 선택
    await _openColorWheel(context, Color(p.solidColorArgb!), (newColor) {
      _saveSolidAsPreset(newColor);
    });
  }
  void _onBuiltinGradientSelect(QrGradient g) { ... clear selectedGradientId + setGradient ... }
  void _onUserGradientSelect(UserColorPalette p) async { ... setGradient + touchLastUsed ... }
  void _onUserGradientLongPress(UserColorPalette p) async {
    // gradient editor 로드 + editingId 세팅 (update 경로)
    _loadGradientIntoEditorState(p);
    _openGradientEditor(editingId: p.id);
  }

  // ── Grid modal ──
  Future<void> _showSolidGridModal({required _ColorGridMode mode}) async { ... }
  Future<void> _showGradientGridModal({required _ColorGridMode mode}) async { ... }

  // ── Color wheel dialog (공용) ──
  Future<void> _openColorWheel(BuildContext context, Color initial,
      ValueChanged<Color> onConfirm) async { ... 기존 코드 재사용 ... }

  // ── build() ──
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrResultProvider);
    final l10n = AppLocalizations.of(context)!;

    if (_showGradientEditor) {
      return _buildGradientEditor(l10n);  // defined in gradient_editor.dart (part of)
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 단색 섹션 ──
          _SolidSectionHeader(
            onDeleteTap: _solidPresets.isNotEmpty
                ? () => _showSolidGridModal(mode: _ColorGridMode.delete)
                : null,
          ),
          const SizedBox(height: 10),
          _SolidRow(
            builtinSelected: state.style.customGradient == null && _selectedSolidPresetId == null
                ? state.style.qrColor
                : null,
            userPresets: _solidPresets,
            selectedPresetId: _selectedSolidPresetId,
            onBuiltinSelect: _onBuiltinSolidSelect,
            onAddTap: () => _openColorWheel(context, state.style.qrColor, _saveSolidAsPreset),
            onUserSelect: _onUserSolidSelect,
            onUserLongPress: _onUserSolidLongPress,
            onShowAll: () => _showSolidGridModal(mode: _ColorGridMode.view),
          ),

          const SizedBox(height: 24),

          // ── 그라디언트 섹션 ──
          _GradientSectionHeader(
            onDeleteTap: _gradientPresets.isNotEmpty
                ? () => _showGradientGridModal(mode: _ColorGridMode.delete)
                : null,
          ),
          const SizedBox(height: 10),
          _GradientRow(
            currentGradient: state.style.customGradient,
            userPresets: _gradientPresets,
            selectedPresetId: _selectedGradientPresetId,
            onBuiltinSelect: _onBuiltinGradientSelect,
            onAddTap: () => _openGradientEditor(),
            onUserSelect: _onUserGradientSelect,
            onUserLongPress: _onUserGradientLongPress,
            onShowAll: () => _showGradientGridModal(mode: _ColorGridMode.view),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Part 파일 시그니처

### 5.1 `shared.dart`

```dart
part of '../qr_color_tab.dart';

/// 섹션 헤더 (라벨 + 우측 선택 aware 삭제 아이콘)
class _SectionLabelWithDelete extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleteTap;  // null = 숨김
  const _SectionLabelWithDelete({required this.label, this.onDeleteTap});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: ...)),
      if (onDeleteTap != null)
        GestureDetector(
          onTap: onDeleteTap,
          child: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade600),
        ),
    ],
  );
}

/// 단색 원형 버튼 (built-in / user 공용)
class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  // ... 기존 구현 + onLongPress 추가 ...
}

/// 그라디언트 원형 버튼 (built-in / user 공용)
class _GradientCircle extends StatelessWidget {
  final QrGradient gradient;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  // ... 기존 _GradientRect 기반, size 48x48 원형 ...
}

/// "+" 추가 버튼 (원형 + 아이콘)
class _AddCircleButton extends StatelessWidget { ... 기존 재사용 ... }

/// 라벨 + 드롭다운 (편집기에서 사용)
class _LabeledDropdown<T> extends StatelessWidget { ... 기존 재사용 ... }

/// 섹션 헤더 단순 (사용자 눈 패턴의 _sectionLabel 과 동형)
class _SolidSectionHeader extends StatelessWidget {
  final VoidCallback? onDeleteTap;
  // l10n.tabColorSolid + 선택적 🗑
}
class _GradientSectionHeader extends StatelessWidget {
  final VoidCallback? onDeleteTap;
  // l10n.tabColorGradient + 선택적 🗑
}
```

### 5.2 `solid_row.dart`

```dart
part of '../qr_color_tab.dart';

/// 단색 2-행 레이아웃.
///
/// 첫 행: built-in 5개 (Wrap)
/// 두 번째 행: [+][user presets...][...] (LayoutBuilder 오버플로)
class _SolidRow extends StatelessWidget {
  final Color? builtinSelected;  // null = user preset 선택 중
  final List<UserColorPalette> userPresets;
  final String? selectedPresetId;
  final ValueChanged<Color> onBuiltinSelect;
  final VoidCallback onAddTap;
  final ValueChanged<UserColorPalette> onUserSelect;
  final ValueChanged<UserColorPalette> onUserLongPress;
  final VoidCallback onShowAll;

  static const _chipSize = 36.0;
  static const _gap = 10.0;

  const _SolidRow({ ... });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 첫 행: built-in 5개 ──
        Wrap(
          spacing: _gap, runSpacing: _gap,
          children: qrSafeColors.map((c) {
            final isSelected = builtinSelected?.toARGB32() == c.toARGB32();
            return _ColorCircle(color: c, isSelected: isSelected,
                onTap: () => onBuiltinSelect(c));
          }).toList(),
        ),
        const SizedBox(height: 10),

        // ── 두 번째 행: [+] + user presets + ... ──
        SizedBox(
          height: _chipSize + 4,  // 40
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final fixedWidth = _chipSize + _gap;  // [+] 1개
              final remaining = totalWidth - fixedWidth;
              final maxSlots = (remaining / (_chipSize + _gap)).floor();
              final needMore = userPresets.length > maxSlots && maxSlots > 0;
              final inlineCount = needMore
                  ? (maxSlots - 1).clamp(0, userPresets.length)
                  : maxSlots.clamp(0, userPresets.length);
              final inlinePresets = userPresets.sublist(0, inlineCount);

              return Row(children: [
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: _AddCircleButton(onTap: onAddTap),
                ),
                ...inlinePresets.map((p) => Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: _ColorCircle(
                    color: Color(p.solidColorArgb!),
                    isSelected: p.id == selectedPresetId,
                    onTap: () => onUserSelect(p),
                    onLongPress: () => onUserLongPress(p),
                  ),
                )),
                if (needMore)
                  Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: _MoreCircleButton(onTap: onShowAll),
                  ),
              ]);
            },
          ),
        ),
      ],
    );
  }
}

class _MoreCircleButton extends StatelessWidget { ... "···" 표시 원형 ... }
```

### 5.3 `gradient_row.dart`

구조 동일. 차이점:
- `qrSafeColors` → `kQrPresetGradients`
- `_ColorCircle` → `_GradientCircle`
- `solidColorArgb!` → `_buildQrGradientFromPreset(p)` helper 필요:

```dart
part of '../qr_color_tab.dart';

class _GradientRow extends StatelessWidget {
  final QrGradient? currentGradient;
  final List<UserColorPalette> userPresets;
  final String? selectedPresetId;
  final ValueChanged<QrGradient> onBuiltinSelect;
  final VoidCallback onAddTap;
  final ValueChanged<UserColorPalette> onUserSelect;
  final ValueChanged<UserColorPalette> onUserLongPress;
  final VoidCallback onShowAll;

  static const _chipSize = 48.0;
  static const _gap = 12.0;

  // ... build() 동형 ...
}

/// UserColorPalette → QrGradient 변환
QrGradient _qrGradientFromPalette(UserColorPalette p) {
  return QrGradient(
    type: p.gradientType ?? 'linear',
    colors: p.gradientColorArgbs!.map((i) => Color(i)).toList(),
    stops: p.gradientStops,
    angleDegrees: (p.gradientAngle ?? 45).toDouble(),
    center: p.gradientType == 'radial' ? 'center' : null,
  );
}

/// built-in QrGradient dedup 비교 (colors 포함)
bool _gradientEquals(QrGradient a, QrGradient b) { ... }
```

### 5.4 `gradient_editor.dart` — 위젯/Painter 만 포함

**최종 결정 (Do phase 중 수정됨)**: Flutter 의 `setState` 는 `@protected` 이며 extension 에서 호출하면 lint 경고가 발생한다. 따라서 편집기 UI build 메서드 (`_buildGradientEditor`, `_buildTypeAndOptionRow`, `_buildColorStopList`, `_emitGradient`, `_redistributeStopPositions`, `_loadGradientIntoEditorState`, `_resetEditorStateToDefault`) 는 **`QrColorTabState` 본체** 에 배치한다.

`gradient_editor.dart` 는 다음 위젯/모델만 포함:
- `_ColorStop` 데이터 모델
- `_GradientSliderBar` (StatefulWidget)
- `_GradientSliderBarPainter` (CustomPainter)

→ library root (`qr_color_tab.dart`) 는 목표 ~620 줄 (당초 ~250 → 편집기 UI 포함으로 증가). CLAUDE.md Rule 8 의 UI part 400 줄 제한은 `qr_color_tab/*.dart` 개별 part 파일에만 적용 (shared.dart, solid_row.dart 등). library root 는 shape tab 선례처럼 state + lifecycle + 주요 handler 를 포함하므로 예외.

```dart
part of '../qr_color_tab.dart';

// ── 그라디언트 편집기 build ──
extension _GradientEditorBuilder on QrColorTabState {
  Widget _buildGradientEditor(AppLocalizations l10n) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabelWithDelete(label: l10n.labelCustomGradient),
              const SizedBox(height: 12),
              _buildTypeAndOptionRow(l10n),
              const SizedBox(height: 16),
              Text(l10n.labelColorStops, style: ...),
              const SizedBox(height: 6),
              _GradientSliderBar(stops: _stops, onChanged: ..., onStopAdded: ...),
              const SizedBox(height: 16),
              _buildColorStopList(l10n),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildTypeAndOptionRow(AppLocalizations l10n) { ... 기존 동일 ... }
  Widget _buildColorStopList(AppLocalizations l10n) { ... 기존 동일 + redistribute ... }

  void _emitGradient() {
    final gradient = QrGradient(
      type: _gradientType,
      colors: _stops.map((s) => s.color).toList(),
      stops: _stops.map((s) => s.position).toList(),
      angleDegrees: _angleDegrees,
      center: _gradientType == 'radial' ? _center : null,
    );
    widget.onGradientChanged(gradient);
  }

  void _loadGradientIntoEditorState(UserColorPalette p) {
    setState(() {
      _gradientType = p.gradientType ?? 'linear';
      _angleDegrees = (p.gradientAngle ?? 45).toDouble();
      _center = 'center';
      _stops = List.generate(p.gradientColorArgbs!.length, (i) {
        return _ColorStop(
          color: Color(p.gradientColorArgbs![i]),
          position: p.gradientStops?[i] ?? (i / (p.gradientColorArgbs!.length - 1)),
        );
      });
    });
  }
}

class _ColorStop { ... 기존 동일 ... }
class _GradientSliderBar extends StatefulWidget { ... 기존 동일 ... }
class _GradientSliderBarState extends State<_GradientSliderBar> { ... 기존 동일 ... }
class _GradientSliderBarPainter extends CustomPainter { ... 기존 동일 ... }
```

**Note**: State 메서드를 `_GradientEditorBuilder` extension 으로 분리하는 이유 — `QrColorTabState` 자체의 본체를 가볍게 유지 (lifecycle + 핸들러만). 편집기 UI 는 extension 에서 제공.

### 5.5 `color_grid_modal.dart`

도트/눈 grid modal 동형.

```dart
part of '../qr_color_tab.dart';

enum _ColorGridMode { view, delete }

sealed class _ColorGridResult {}
class _ColorGridDeleteResult extends _ColorGridResult {
  final Set<String> deletedIds;
  _ColorGridDeleteResult(this.deletedIds);
}
class _ColorGridEditResult extends _ColorGridResult {
  final UserColorPalette preset;
  _ColorGridEditResult(this.preset);
}
class _ColorGridSelectResult extends _ColorGridResult {
  final UserColorPalette preset;
  _ColorGridSelectResult(this.preset);
}

class _ColorGridModal extends StatefulWidget {
  final List<UserColorPalette> presets;
  final _ColorGridMode mode;
  final String? selectedPresetId;
  final bool isGradient;  // 렌더 분기 (solid circle vs gradient circle)

  const _ColorGridModal({
    required this.presets,
    required this.mode,
    required this.isGradient,
    this.selectedPresetId,
  });

  @override
  State<_ColorGridModal> createState() => _ColorGridModalState();
}

class _ColorGridModalState extends State<_ColorGridModal> {
  final _markedForDeletion = <String>{};

  @override
  Widget build(BuildContext context) {
    // 5-column GridView + delete button at bottom (isDelete 일 때)
    // itemBuilder:
    //   - tap: view 모드면 select 결과, delete 모드면 mark toggle
    //   - longPress: view 모드에서 gradient 만 → _ColorGridEditResult
    //     (solid 는 long-press 시 "신규 생성" UX 라 modal 에서는 select 로 끝)
    //   - 렌더: isGradient 면 _GradientCircle, 아니면 _ColorCircle
  }
}
```

**Note**: solid 의 경우 grid modal 에서 long-press 는 동작 없음 (위 Plan 결정에 따라 solid 롱프레스는 color wheel + 신규 생성). Grid modal 에서의 편집 진입은 gradient 만 지원.

---

## 6. qr_color_presets.dart 축소

```dart
// Before: 10 colors
const qrSafeColors = [ /* 10 items */ ];

// After: 5 colors (계열 대표)
const qrSafeColors = [
  Color(0xFF000000), // 검정
  Color(0xFF0000CD), // 진파랑
  Color(0xFF006400), // 진초록
  Color(0xFF8B0000), // 진빨강
  Color(0xFF4B0082), // 진보라
];

// Before: 8 gradients
const kQrPresetGradients = [ /* 8 items */ ];

// After: 5 gradients
const kQrPresetGradients = [
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFF0066CC), Color(0xFF6A0DAD)]),   // 블루-퍼플
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC3300), Color(0xFFCC8800)]),   // 선셋
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF006644), Color(0xFF003388)]),   // 에메랄드-네이비
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC0055), Color(0xFF660099)]),   // 로즈-퍼플
  QrGradient(type: 'radial',
      colors: [Color(0xFF880000), Color(0xFF4A0080)]),   // 라디얼 다크
];
```

---

## 7. qr_result_screen.dart 변경

기존:
```dart
actions: [
  // shape 편집기는 뒤로가기가 자동 저장이므로 [저장] 버튼 불필요.
  // 색상 편집기만 [저장] 버튼 유지.
  if (_colorEditorMode)
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton(
        onPressed: _confirmActiveEditor,
        child: Text(l10n.actionSave),
      ),
    ),
],
```

변경 후:
```dart
actions: const [],
// 모든 편집기 뒤로가기가 자동 저장 — [저장] 버튼 불필요.
```

또는 `if (false)` 로 비활성화 — **깔끔한 제거 선호**.

---

## 8. Preset 저장 로직 상세

### 8.1 `_saveSolidAsPreset(Color color)` (신규 생성 경로)

```dart
Future<void> _saveSolidAsPreset(Color color) async {
  if (_datasource == null) return;
  final argb = color.toARGB32();

  // Dedup: 동일 ARGB 있으면 기존 선택 + touchLastUsed
  final existing = _solidPresets
      .where((p) => p.solidColorArgb == argb)
      .firstOrNull;
  if (existing != null) {
    setState(() => _selectedSolidPresetId = existing.id);
    await _datasource!.touchLastUsed(existing.id);
    widget.onGradientChanged(null);
    widget.onColorSelected(color);
    _loadPresets();
    return;
  }

  // 신규 생성
  final id = const Uuid().v4();
  final now = DateTime.now();
  final preset = UserColorPalette(
    id: id,
    name: id.substring(0, 8),
    type: PaletteType.solid,
    solidColorArgb: argb,
    createdAt: now,
    updatedAt: now,
  );
  await _datasource!.write(UserColorPaletteModel.fromEntity(preset));
  setState(() => _selectedSolidPresetId = id);
  widget.onGradientChanged(null);
  widget.onColorSelected(color);
  _loadPresets();
}
```

### 8.2 `_saveCurrentGradientAsPreset()` (그라디언트 신규 경로)

```dart
Future<void> _saveCurrentGradientAsPreset() async {
  if (_datasource == null) return;
  final current = QrGradient(
    type: _gradientType,
    colors: _stops.map((s) => s.color).toList(),
    stops: _stops.map((s) => s.position).toList(),
    angleDegrees: _angleDegrees,
    center: _gradientType == 'radial' ? _center : null,
  );

  // Dedup
  final existing = _gradientPresets.where((p) {
    return _gradientEquals(_qrGradientFromPalette(p), current);
  }).firstOrNull;
  if (existing != null) {
    setState(() => _selectedGradientPresetId = existing.id);
    await _datasource!.touchLastUsed(existing.id);
    _loadPresets();
    return;
  }

  final id = const Uuid().v4();
  final now = DateTime.now();
  final preset = UserColorPalette(
    id: id,
    name: id.substring(0, 8),
    type: PaletteType.gradient,
    gradientColorArgbs: current.colors.map((c) => c.toARGB32()).toList(),
    gradientStops: current.stops,
    gradientType: current.type,
    gradientAngle: current.angleDegrees.toInt(),
    createdAt: now,
    updatedAt: now,
  );
  await _datasource!.write(UserColorPaletteModel.fromEntity(preset));
  setState(() => _selectedGradientPresetId = id);
  _loadPresets();
}
```

### 8.3 `_updateExistingGradientPreset()` (편집 경로)

```dart
Future<void> _updateExistingGradientPreset() async {
  if (_datasource == null || _editingGradientPresetId == null) return;
  final existing = _gradientPresets
      .where((p) => p.id == _editingGradientPresetId)
      .firstOrNull;
  if (existing == null) {
    // 편집 중 삭제된 경우 등 — 신규 저장으로 fallback
    await _saveCurrentGradientAsPreset();
    return;
  }
  final updated = UserColorPalette(
    id: existing.id,
    name: existing.name,
    type: existing.type,
    gradientColorArgbs: _stops.map((s) => s.color.toARGB32()).toList(),
    gradientStops: _stops.map((s) => s.position).toList(),
    gradientType: _gradientType,
    gradientAngle: _angleDegrees.toInt(),
    sortOrder: existing.sortOrder,
    createdAt: existing.createdAt,
    updatedAt: DateTime.now(),
    remoteId: existing.remoteId,
    syncedToCloud: false,  // 수정되었으므로 sync 대기
  );
  await _datasource!.write(UserColorPaletteModel.fromEntity(updated));
  setState(() => _selectedGradientPresetId = existing.id);
  _loadPresets();
}
```

---

## 9. 데이터 흐름

```
┌────────────────────────────────────────────────────────────────┐
│  사용자 UI (QrColorTab build)                                   │
│    - _SolidRow / _GradientRow                                   │
│    - _ColorGridModal (view / delete)                            │
│    - Gradient Editor (_buildGradientEditor)                     │
└────────────────────────────────────────────────────────────────┘
        │ onXxxSelect / onXxxLongPress / onAddTap / onShowAll
        ▼
┌────────────────────────────────────────────────────────────────┐
│  QrColorTabState (qr_color_tab.dart)                           │
│    _selectedSolidPresetId / _selectedGradientPresetId            │
│    _editingGradientPresetId                                      │
│    _stops, _gradientType, _angleDegrees, _center                │
│    _saveSolidAsPreset / _saveCurrentGradientAsPreset            │
│    _updateExistingGradientPreset / _loadPresets                 │
└────────────────────────────────────────────────────────────────┘
        │
    ┌───┴────┬─────────────────────────────┐
    ▼        ▼                             ▼
┌──────────┐ ┌─────────────────┐ ┌──────────────────────────────┐
│ Parent    │ │ HiveColor       │ │ qrResultProvider             │
│ callbacks │ │  Palette        │ │  setQrColor / setCustomGrad. │
│  onColor  │ │  Datasource     │ │  (기존 setter, 무변경)        │
│  Selected │ │  readAll...     │ │                              │
│  onGrad.. │ │  write          │ │                              │
│  Changed  │ │  delete         │ │                              │
└──────────┘ │  touchLastUsed  │ └──────────────────────────────┘
             └─────────────────┘
                      │
                      ▼
             ┌─────────────────┐
             │ Hive box         │
             │ user_color_      │
             │ palettes         │
             │ (typeId 3)       │
             └─────────────────┘
```

**State:**
- Parent callback 들은 기존과 동일 (`onColorSelected(Color)` → `setQrColor`, `onGradientChanged(QrGradient?)` → `setCustomGradient`)
- Hive 는 별도 경로로 preset list 관리
- 둘은 독립 — 선택 시 Parent 로는 렌더 값, Hive 로는 preset 메타 (`touchLastUsed` 등)

---

## 10. Edge Cases

| 케이스 | 기대 동작 |
|---|---|
| `_datasource == null` (init 대기 중) | preset 리스트 빈 상태로 렌더, 사용자 버튼은 disable 된 상태처럼 표시 |
| User preset 0개 | 두 번째 행에 `[+]` 만, 🗑 아이콘 숨김 |
| User preset 1개 롱프레스 솔리드 | color wheel 열림, 새 색상 확정 시 dedup 없으면 2번째 preset 생성 |
| 동일 QrGradient 2회 저장 시도 | `_gradientEquals` 로 dedup, 기존 preset `touchLastUsed` 만 수행 |
| 편집 중 편집 대상 preset 이 외부에서 삭제됨 | `_updateExistingGradientPreset` 에서 `existing == null` → `_saveCurrentGradientAsPreset` fallback |
| Solid preset 삭제 후 선택되어 있던 id | `_selectedSolidPresetId` 를 null 로 하고 parent callback 으로 qrColor 는 유지 (제거되어도 현재 렌더 색은 바뀌지 않음) |
| `_stops.length` 변경 후 저장 | `gradientStops` 가 `colors` 와 같은 길이로 저장 (`_loadGradientIntoEditorState` 에서도 일치) |
| Built-in 색상 선택 중 user preset 탭 | user preset 으로 전환, `_selectedSolidPresetId` 세팅, built-in 체크 해제 |
| Hive box 미열림 에러 | `_initDatasource` 의 async 에러 catch 필요 (addPostFrameCallback 에서 snackbar 표시) |

---

## 11. 검증 (Gap Analysis 대비 체크포인트)

| 항목 | 검증 방법 |
|---|---|
| 파일 구조 | `ls lib/features/qr_result/tabs/qr_color_tab/` 에 5 part 파일 존재 |
| library root 라인 수 | `wc -l lib/features/qr_result/tabs/qr_color_tab.dart` ≈ 620 (editor UI 포함, `setState @protected` lint 로 extension→body 이동 반영된 새 목표) |
| Built-in 축소 | `qr_color_presets.dart` grep 으로 색상 5개, 그라디언트 5개 확인 |
| Hive 확장 메서드 존재 | `grep "touchLastUsed\|readAllSortedByRecency" hive_color_palette_datasource.dart` |
| [저장] 버튼 제거 | `qr_result_screen.dart` AppBar actions 내 `if (_colorEditorMode)` 부재 |
| flutter analyze | 0 errors (기존 pre-existing info/warning 는 제외 기준) |
| 뒤로가기 자동 저장 | 수동 테스트: 그라디언트 편집기 진입 → 수정 → `[<]` → 프리셋에 추가됨 |
| 최근 사용 정렬 | 수동 테스트: preset A, B 차례로 선택 → 다음 번 열 때 B 가 첫 번째 |
| 솔리드 롱프레스 = 신규 생성 | 수동 테스트: preset A 롱프레스 → color wheel → 다른 색 확정 → A 유지 + 새 preset 추가 |
| 동일 그라디언트 dedup | 수동 테스트: 같은 값 2번 저장 → 리스트에 1개만 |

---

## 12. 구현 순서 (Do phase)

1. **`qr_color_presets.dart`**: 축소 (10→5, 8→5)
2. **`hive_color_palette_datasource.dart`**: `touchLastUsed`, `readAllSortedByRecency`, cache 확장
3. **`qr_color_tab/shared.dart` 신규**: 공용 위젯 (`_ColorCircle`, `_GradientCircle`, `_AddCircleButton`, `_MoreCircleButton`, `_SolidSectionHeader`, `_GradientSectionHeader`, `_LabeledDropdown`)
4. **`qr_color_tab/gradient_editor.dart` 신규**: 기존 편집기 코드 이동 (`_ColorStop`, `_GradientSliderBar`, extension `_GradientEditorBuilder`)
5. **`qr_color_tab/color_grid_modal.dart` 신규**: `_ColorGridModal` (view/delete modes, isGradient 분기)
6. **`qr_color_tab/solid_row.dart` 신규**: `_SolidRow` (2-row with LayoutBuilder 오버플로)
7. **`qr_color_tab/gradient_row.dart` 신규**: `_GradientRow` (2-row) + `_qrGradientFromPalette` + `_gradientEquals` helper
8. **`qr_color_tab.dart` 재작성**: library root + state + handlers + public API (`cancelAndCloseEditor`, `confirmAndCloseEditor`, `activeEditorLabel`)
9. **`qr_result_screen.dart`**: AppBar actions 제거
10. **`flutter analyze`**: 타입 에러/미사용 검증
11. **수동 테스트**: Edge Cases 목록 + 주요 플로우

---

## 13. Risks & Mitigations

| Risk | 영향 | 완화 |
|---|---|---|
| 기존 `_showCustomEditor` 상태명을 `_showGradientEditor` 로 변경 | 외부 참조 단절 가능성 | `qr_result_screen.dart` 외에는 내부 상태라 외부 영향 없음. 외부에서 쓰는 공개 API (`cancelAndCloseEditor` 등)은 시그니처 유지 |
| `HiveColorPaletteDataSource` 확장에서 cache 와 sync(remoteId 갱신) 충돌 | sync 모듈이 직접 box.put 하는 경우 stale cache | 확장 메서드 `write`/`delete` 에서 `invalidateCache` 호출. 만약 sync 가 datasource 를 우회하면 sync 측도 cache invalidate 필요 (현재 코드상 `HiveColorPaletteDataSource` 는 sync 에 미사용이라 safe) |
| Built-in 10→5 축소 | 기존 선택된 색상 중 삭제된 색상이 저장 상태에 있을 경우 | `qrColor` 는 ARGB int — 렌더는 정상 동작. built-in 5 중 아니면 체크 안 됨 (무해) |
| `QrGradient.operator==` 불완전 | dedup 엔티티 == 쓸 수 없음 | `_gradientEquals` helper 로 명시적 비교 |
| File size 증가 | CLAUDE.md Rule 8 재위반 우려 | library root 250 목표, 각 part < 400, 합계 증가하지만 분할로 단일 파일은 제한 준수 |
| Editor extension (`_GradientEditorBuilder on QrColorTabState`) | Dart 의 private extension 접근 제약 | 같은 library 내 part 파일이므로 `_` prefix 접근 가능. 관례적으로 작동 |

---

## 14. Future Work (Out of Scope)

- Preset 이름 수동 편집 (현재 uuid 앞 8자)
- Preset drag-reorder
- Cloud sync 연결 (기존 `syncedToCloud` 인프라 활용)
- Color wheel 내부에서 HSV/HSL 탭 토글
- 단색 롱프레스 = update (현재 신규 생성 고정)

---

**Plan 참조**: `docs/01-plan/features/color-tab-user-presets.plan.md`
**Next**: `/pdca do color-tab-user-presets` — Checkpoint 4 + 순차 구현
