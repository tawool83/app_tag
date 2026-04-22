# color-tab-user-presets — Plan

> 색상 탭에 **사용자 단색/그라디언트 프리셋 관리 UX** 추가. 도트/눈 편집 패턴(R-series) 동형.

---

## Executive Summary

| 항목 | 내용 |
|---|---|
| Feature | `color-tab-user-presets` |
| Created | 2026-04-22 |
| Project Level | Flutter Dynamic × Clean Architecture × R-series |
| Scope | `qr_color_tab.dart` 전면 재구조화 (library + part) + `HiveColorPaletteDataSource` 확장 + UI 2-행 레이아웃 + 편집기 자동저장 |

### Value Delivered (4-perspective)

| Perspective | 내용 |
|---|---|
| **Problem** | 색상 탭은 built-in 색상/그라디언트만 지원. 사용자가 color wheel/gradient editor 로 만든 색은 **저장되지 않고 세션 상태로만 남음** (`qrColor`/`customGradient` 단일 슬롯). Hive `user_color_palettes` box 인프라는 존재하지만 UI 와 미연결. 도트/눈은 R-series 패턴으로 사용자 프리셋 관리가 완성됐는데 **색상 탭만 구식**으로 남아 있음. |
| **Solution** | 도트/눈 편집 패턴을 색상 탭에도 적용. 단색 섹션과 그라디언트 섹션 각각 **2-행 레이아웃**: (1행) 축소된 built-in 5개 + (2행) `[+]` + 사용자 프리셋 + `···` 오버플로. 섹션 라벨 우측 🗑 아이콘 → grid 모달 delete 모드. Hive 실시간 연결 + `updatedAt` 기준 최근 순 정렬. |
| **Function / UX Effect** | ① 사용자가 만든 색상/그라디언트를 **재사용 가능한 프리셋**으로 저장/관리 ② 롱프레스로 편집 진입 (단색은 신규 복사, 그라디언트는 update) ③ 뒤로가기 = 자동 저장 (도트/눈과 완전 일치) ④ 선택 체크 아이콘 + 대칭형 dedup + `···` 오버플로 모달. |
| **Core Value** | ① R-series 4번째 도메인 (도트→눈→경계/애니→**색상**) 사용자 프리셋 UX 완결 ② 기존 824줄 god-widget `qr_color_tab.dart` 를 library + 5 part 구조로 재정렬 (Hard Rule 8 위반 해소) ③ 이미 존재하던 Hive 인프라 활용 — 신규 의존성 0. |

---

## 1. 배경 (Why)

- `qr_color_tab.dart` 는 **824줄 단일 파일** — CLAUDE.md Hard Rule 8 (UI part ≤ 400줄) 위반 상태
- 단색 built-in 10개 + 그라디언트 built-in 8개 표시만 지원, 사용자 커스텀은 **1회용**
- Hive `user_color_palettes` box + `UserColorPaletteModel` (typeId 3) + `HiveColorPaletteDataSource` 이미 정의됨 — UI 에서 호출되지 않아 **dead infrastructure**
- 도트/눈 편집 UX (R-series: `refactor-qr-shape-tab` + `eye-quadrant-corners`) 완성 상태 → **일관성 확보 타이밍**

---

## 2. 요구사항 (What)

### 2.1 레이아웃 변경

**현재**:
```
┌ 단색 ────────────────┐   ┌ 그라디언트 ──────────┐
│ [10 builtin] [+]     │   │ [8 builtin] [+]     │
└──────────────────────┘   └──────────────────────┘
```

**변경 후**:
```
┌ 단색                                   [🗑] ┐
│ [■][■][■][■][■]                            │ ← built-in 5개
│ [+][user1][user2]...[...]                  │ ← + 사용자 presets (LayoutBuilder 오버플로)
└──────────────────────────────────────────────┘

┌ 그라디언트                             [🗑] ┐
│ [G1][G2][G3][G4][G5]                       │ ← built-in 5개
│ [+][user1][user2]...[...]                  │
└──────────────────────────────────────────────┘
```

- **built-in 단색 축소**: 10 → **5 (검정 / 진파랑 / 진초록 / 진빨강 / 진보라)**
- **built-in 그라디언트 축소**: 8 → **5 (블루-퍼플 / 선셋 / 에메랄드-네이비 / 로즈-퍼플 / 라디얼 다크)**
- **두 번째 행**: `[+]` 추가 버튼 + 사용자 프리셋 + `···` 오버플로 (화면 넘침 시)
- **섹션 라벨 우측 🗑**: 사용자 프리셋이 1개 이상일 때 표시, 탭 시 grid 모달 (delete 모드)

### 2.2 동작 스펙 (도트/눈 동형)

| 제스처 | 대상 | 동작 |
|---|---|---|
| Tap | built-in 색상/그라디언트 | 선택 적용 + 사용자 preset 선택 해제 |
| Tap | 사용자 preset | 선택 적용 + `updatedAt` 갱신 + 약간 지연 후 재정렬 |
| Long-press | 사용자 단색 preset | Color wheel 열기 (현재 색상 pre-loaded) → 확정 시 **새 preset 생성** (원본 유지) |
| Long-press | 사용자 그라디언트 preset | Gradient editor 로드 (`editingId` 세팅) → 뒤로가기 자동 저장 (**update**) |
| Tap | `[+]` 단색 | Color wheel 열기 → 확정 시 새 preset 생성 (dedup) |
| Tap | `[+]` 그라디언트 | Gradient editor 진입 → 뒤로가기 자동 저장 (dedup) |
| Tap | `···` (오버플로) | `_ColorGridModal` (view 모드) 열기 |
| Tap | 🗑 아이콘 | `_ColorGridModal` (delete 모드) 열기 |

### 2.3 편집기 UX 통일 (shape editor 와 동형)

- 뒤로가기 `[<]` = **자동 저장** (다이얼로그 없음)
- AppBar `[저장]` 버튼 **제거** (shape editor 에 했던 것과 동일)
- 새 preset 생성 vs 기존 update 판단은 `_editingPresetId != null` 기준
- dedup: 동일 파라미터 이미 있으면 해당 preset 선택 + `touchLastUsed`

### 2.4 Dedup 기준

| 타입 | 비교 기준 |
|---|---|
| Solid | `solidColorArgb` 동일 |
| Gradient | `colors` list + `stops` list + `type` + `angleDegrees` (linear) 또는 `center` (radial) 모두 동일 |

---

## 3. 아키텍처 (How)

### 3.1 파일 구조 (R-series 동형)

```
lib/features/qr_result/tabs/
├── qr_color_tab.dart                  # library root (~250 줄)
└── qr_color_tab/
    ├── shared.dart                    # _ColorCircle, _GradientCircle, _AddButton, _SectionHeader
    ├── solid_row.dart                 # _SolidRow (builtin 5 + user layout)
    ├── gradient_row.dart              # _GradientRow (builtin 5 + user layout)
    ├── gradient_editor.dart           # _GradientEditor (기존 _buildCustomEditor 이동)
    └── color_grid_modal.dart          # _ColorGridModal (view/delete)
```

**주의**: `qr_shape_tab/` 과 구조 동형. Library root 는 state + 핸들러 + `_saveCurrentAsPreset` / `_updateExistingPreset` / `_showColorGridModal` 만 보유.

### 3.2 Hive 데이터소스 확장

**파일**: `lib/features/color_palette/data/datasources/hive_color_palette_datasource.dart`

추가 메서드:
```dart
class HiveColorPaletteDataSource {
  // 기존: readAll (sortOrder 기반 — sync 용 유지)

  /// 타입별 필터링 + updatedAt desc 정렬 (in-memory cache).
  List<UserColorPalette> readAllSortedByRecency(PaletteType type);

  /// updatedAt 만 갱신 (id 기반).
  Future<void> touchLastUsed(String id);

  void invalidateCache();  // save/delete 시 자동 호출
}
```

in-memory cache 패턴은 `LocalUserShapePresetDatasource` 와 동일.

### 3.3 State (qr_color_tab.dart)

```dart
class QrColorTabState extends ConsumerState<QrColorTab> {
  HiveColorPaletteDataSource? _datasource;
  List<UserColorPalette> _userSolidPresets = [];
  List<UserColorPalette> _userGradientPresets = [];

  String? _selectedSolidPresetId;
  String? _selectedGradientPresetId;

  // 편집기 상태
  bool _showGradientEditor = false;
  String? _editingGradientPresetId;

  // 편집기 임시 값
  String _gradientType = 'linear';
  double _angleDegrees = 45;
  String _center = 'center';
  List<_ColorStop> _stops = [default 2];

  Timer? _reorderTimer;

  // Public API (qr_result_screen 호환)
  Future<bool> cancelAndCloseEditor() async { ... auto-save ... return true; }
  Future<void> confirmAndCloseEditor() async { ... auto-save ... }
  String? activeEditorLabel(AppLocalizations l10n) => _showGradientEditor ? l10n.labelCustomGradient : null;
}
```

### 3.4 Built-in 축소 (qr_color_presets.dart)

```dart
const qrSafeColors = [
  Color(0xFF000000), // 검정
  Color(0xFF0000CD), // 진파랑
  Color(0xFF006400), // 진초록
  Color(0xFF8B0000), // 진빨강
  Color(0xFF4B0082), // 진보라
];

const kQrPresetGradients = [
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFF0066CC), Color(0xFF6A0DAD)]),  // 블루-퍼플
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC3300), Color(0xFFCC8800)]),  // 선셋
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF006644), Color(0xFF003388)]),  // 에메랄드-네이비
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC0055), Color(0xFF660099)]),  // 로즈-퍼플
  QrGradient(type: 'radial',
      colors: [Color(0xFF880000), Color(0xFF4A0080)]),  // 라디얼 다크
];
```

제거: 남색, 청록, 진갈색, 진주황, 인디고 (단색) / 오션, 포레스트, 미드나잇 (그라디언트).

### 3.5 AppBar [저장] 버튼 제거

**파일**: `lib/features/qr_result/qr_result_screen.dart`

이전 feature 에서 `_shapeEditorMode` 일 때 [저장] 숨김. 이번엔 color editor 일 때도 숨김:
```dart
// Before:
if (_colorEditorMode) Padding( ... FilledButton([저장]) ... )

// After:
// 모든 편집기 뒤로가기가 자동 저장으로 통일 — [저장] 버튼 불필요
// (actions: [] 또는 삭제)
```

### 3.6 Entity / Model 무변경

- `UserColorPalette` (domain) 기존 필드 사용 (`updatedAt`, `solidColorArgb`, `gradientColorArgbs` 등)
- `UserColorPaletteModel` Hive typeId 3 **그대로 유지** (기존 sync 호환)
- `QrGradient` 기존 필드 사용

### 3.7 l10n 추가 (app_ko.arb)

```json
// 기존 유지: tabColorSolid, tabColorGradient, labelCustomGradient
// 신규 키 없음 — 섹션 헤더는 기존 키 재활용, 사용자 프리셋 설명은 불필요
```

실제로 신규 키 불필요 — 기존 라벨만 재활용 (tabColorSolid = "단색", tabColorGradient = "그라디언트" 섹션 헤더 그대로 쓰고, 삭제 아이콘 옆에 로컬 텍스트 없음).

---

## 4. 영향 파일

| # | 파일 | 변경 | 예상 규모 |
|---|---|---|---|
| 1 | `lib/features/qr_result/tabs/qr_color_tab.dart` | **재작성** (library root) | ~250줄 |
| 2 | `lib/features/qr_result/tabs/qr_color_tab/shared.dart` | **신규** (공용 위젯) | ~200줄 |
| 3 | `lib/features/qr_result/tabs/qr_color_tab/solid_row.dart` | **신규** (2행 레이아웃) | ~180줄 |
| 4 | `lib/features/qr_result/tabs/qr_color_tab/gradient_row.dart` | **신규** (2행 레이아웃) | ~180줄 |
| 5 | `lib/features/qr_result/tabs/qr_color_tab/gradient_editor.dart` | **신규** (기존 편집기 이동) | ~330줄 |
| 6 | `lib/features/qr_result/tabs/qr_color_tab/color_grid_modal.dart` | **신규** (view/delete modal) | ~230줄 |
| 7 | `lib/features/color_palette/data/datasources/hive_color_palette_datasource.dart` | **확장** (touchLastUsed, readAllSortedByRecency, cache) | +40줄 |
| 8 | `lib/features/qr_result/domain/entities/qr_color_presets.dart` | **수정** (축소 10→5, 8→5) | -15줄 |
| 9 | `lib/features/qr_result/qr_result_screen.dart` | **수정** ([저장] 버튼 제거 조건) | -2줄 |

**합계**: 2 수정 / 6 신규 / 1 삭제-성 수정 / 1 library root 재작성, 총 ~1370 신규/유지 + ~17 삭제

---

## 5. 구현 순서

1. **`qr_color_presets.dart`** — built-in 축소 (10→5, 8→5)
2. **`hive_color_palette_datasource.dart`** — `touchLastUsed`, `readAllSortedByRecency`, cache 추가
3. **`qr_color_tab/shared.dart` 신규** — `_ColorCircle`, `_GradientCircle`, `_AddButton` 등 공용
4. **`qr_color_tab/gradient_editor.dart` 신규** — 기존 `_buildCustomEditor` + `_GradientSliderBar` 이동
5. **`qr_color_tab/color_grid_modal.dart` 신규** — view/delete modal (dot pattern mirror)
6. **`qr_color_tab/solid_row.dart` 신규** — 2행 레이아웃 (builtin wrap + user LayoutBuilder)
7. **`qr_color_tab/gradient_row.dart` 신규** — 동일 패턴
8. **`qr_color_tab.dart` 재작성** — library root + state + 핸들러
9. **`qr_result_screen.dart`** — AppBar [저장] 버튼 조건 업데이트
10. **`flutter analyze`** — 기존 참조 잔재 탐지
11. **수동 테스트**:
    - 단색 preset 생성/선택/삭제/편집 (=복사)
    - 그라디언트 preset 생성/선택/삭제/롱프레스 편집 (update)
    - `···` 오버플로 (user preset 10+ 개 생성)
    - 최근 선택이 첫 번째
    - 뒤로가기 자동 저장

---

## 6. Edge Cases / 검증 포인트

| 케이스 | 기대 동작 |
|---|---|
| 사용자 단색 preset 0개 | 두 번째 행에 `[+]` 만. 🗑 아이콘 숨김 |
| builtin 색상 선택 중 사용자 preset 추가 | builtin 체크 유지, 새 preset 은 reflector 없이 목록에만 |
| 그라디언트 편집기에서 뒤로가기 | 자동 저장 + grid modal 에 신규 preset 표시 |
| 동일 그라디언트 2회 저장 | dedup 으로 하나만 존재, 두 번째는 기존 선택 + `touchLastUsed` |
| 단색 롱프레스 → color wheel → 확정 | 새 preset 생성 (원본 유지, dedup 동일 색이면 기존 선택) |
| user preset 10+ 개 | `···` 표시, 탭 시 grid modal view 모드 |
| 섹션 라벨 옆 🗑 탭 | grid modal delete 모드, 선택 후 일괄 삭제 버튼 |
| AppBar `[<]` | 편집기 자동 저장 후 닫힘 |
| 탭 전환 (shape → color → template) | 편집기 자동 확인 (기존 `confirmAndCloseEditor` 경로 재사용) |
| Hive legacy 데이터 | 현재 box 비어있음 — 마이그레이션 불필요 |

---

## 7. 향후 확장 (Out of Scope)

- 그라디언트 stop 개수 확장 (현재 max 5)
- 사용자 preset 에 이름 달기 (현재 uuid 앞 8자리)
- 사용자 preset 순서 수동 변경 (drag-reorder)
- 클라우드 sync (이미 `UserColorPaletteModel.remoteId` / `syncedToCloud` 인프라 존재 — 별도 feature)
- 다이나믹 gradient preset (QR 에 애니메이션)

---

## Next Step

```
/pdca design color-tab-user-presets
```

본 Plan 의 §3 아키텍처를 디자인 문서에서 각 part 파일의 위젯 시그니처 + state 흐름도로 발전시킴.
CLAUDE.md 규약상 Checkpoint 3 (3-옵션 비교)는 스킵 — R-series 패턴 고정.

---

**참조**: `docs/archive/2026-04/refactor-qr-shape-tab/` (R1 shape tab 분할 — 본 feature 직접 선례), `docs/archive/2026-04/color-tab-redesign/` (색상 탭 직전 재설계, 92% Match Rate)
