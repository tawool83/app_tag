# Design — 사용자 프리셋 reorder 정책 개선

> 생성일: 2026-04-29
> 갱신일: 2026-04-29 (v2 — 시트 닫기 동작 + reorder 시점 지연)
> Feature ID: `preset-reorder-policy`
> Plan: [`docs/01-plan/features/preset-reorder-policy.plan.md`](../../01-plan/features/preset-reorder-policy.plan.md)

> CLAUDE.md PDCA Override: Checkpoint 3 (3-옵션 아키텍처 비교) 생략. R-series Provider 패턴 + Clean Architecture 자동 적용. 본 feature 는 위젯 로컬 State 만 건드리는 작은 변경이라 신규 entity/sub-state/mixin 없음.

---

## 0. v1 → v2 변경 요약 (이 문서 핵심)

**v1 (구현 완료)**: inline tap 의 reorder 제거 + sheet tap 의 inline 조건부 reorder + sheet 진입 시 selection highlight.

**v2 (이번 design)**: 시트 닫는 시점을 사용자가 결정하도록 변경. sheet 항목 탭은 시트를 닫지 않고 미리보기·highlight 만 즉시 갱신. reorder 는 시트 dismiss 시점에 마지막 선택 1개만 일괄 처리. v1 의 *sheet 핸들러 즉시 reorder* 분기는 *sheet 닫힘-후 처리* 로 이동.

**무엇이 바뀌나**:
1. modal 위젯에 `onSelect` 콜백 + 자체 state `_localSelectedId` 추가
2. modal 셀 onTap 핸들러: `Navigator.pop` 제거 → `setState(_localSelectedId)` + `widget.onSelect(preset)`
3. sheet result 의 `_XxxGridSelectResult` 케이스 제거 (콜백으로 처리)
4. 부모: `await showModalBottomSheet` 후 `result == null` 분기에서 진입-전 vs 진입-후 selectedId 비교 → reorder 결정
5. v1 의 color tab 의 `_onUserSolid/GradientSelectFromSheet` 핸들러는 v2 에서 단순화 — sheet 콜백은 inline 핸들러와 동일하게 동작 (touchLastUsed 호출 안 함). reorder 로직은 sheet 호출부의 닫힘-후 분기로 이동.

---

## 1. 변경 매트릭스 (v2)

| 탭 | 진입점 | v0 (원본) | v2 (목표) |
|---|---|---|---|
| **boundary** | inline tap | `touchLastUsed` + 재정렬 | ❌ 제거 |
| boundary | inline long-press → 편집기 | `touchLastUsed` + 편집기 | ✅ 유지 |
| boundary | sheet tap (시트 열린 동안) | `Navigator.pop(SelectResult)` → `touchLastUsed` 즉시 | 🆕 시트 유지, 부모 select 콜백, reorder 보류 |
| boundary | sheet 닫힘 (바깥 탭/dismiss) | (해당 없음 — 항상 즉시 닫힘) | 🆕 진입-전과 다른 sheet-only 면 reorder 1회 |
| boundary | sheet long-press → 편집기 | 시트 닫힘 + 편집기 + reorder | ✅ 그대로 |
| **dot** | inline tap | `touchLastUsed` + delayed reload | ❌ 제거 |
| dot | inline long-press → 편집기 | `touchLastUsed` + 편집기 | ✅ 유지 |
| dot | sheet tap (열린 동안) | `Navigator.pop(SelectResult)` → 즉시 reorder | 🆕 시트 유지, 부모 select 콜백, reorder 보류 |
| dot | sheet 닫힘 | — | 🆕 sheet-only 면 reorder 1회 |
| dot | sheet long-press → 편집기 | 시트 닫힘 + 편집기 | ✅ 그대로 |
| **eye** | (dot 와 동일 패턴) | — | 동일 |
| **color solid** | inline tap | `touchLastUsed` + delayed reload | ❌ 제거 |
| color solid | sheet tap (열린 동안) | `Navigator.pop` → `_onUserSolidSelect` | 🆕 시트 유지, 부모 select 콜백, reorder 보류 |
| color solid | sheet 닫힘 | — | 🆕 sheet-only 면 reorder 1회 |
| color solid | inline/sheet long-press | 색상 휠 → 신규 저장 | ✅ 그대로 |
| **color gradient** | (color solid 와 동일 패턴) | — | 동일 |
| **모든 탭** | 편집기 confirm (신규 저장) | reorder ✅ | ✅ 그대로 |
| 모든 탭 | 편집기 confirm (dedupe 매칭) | reorder ✅ | ✅ 그대로 |

범례: ❌ 제거 / ✅ 유지 / 🆕 v2 신규

---

## 2. 핵심 결정: inline-visible id 통보 방식

### 2.1 결정: callback 통보 (`onInlineIdsChanged`)

기존 `_BoundaryUserPresetRow.build` 안의 `LayoutBuilder` 가 이미 inlinePresets 를 계산함. 그 결과 id 집합을 부모 State 에 콜백으로 통보.

**결정 근거**:
- 단일 소스 원칙: 슬롯 계산 로직(LayoutBuilder + chipSize 상수)은 row 위젯 한 곳에서만 수행
- 부모는 sheet 호출 시점에 `_inlineIds` 를 즉시 참조 (rebuild 와 무관)
- ValueNotifier 도입 불필요 — plain mutable field + setState 미호출로 무한 루프 회피
- row 위젯은 StatelessWidget 그대로 유지 (Stateful 변환 부담 없음)

### 2.2 시그니처

**row 위젯 (기존 4개)**:
```dart
class _BoundaryUserPresetRow extends StatelessWidget {
  // ... 기존 파라미터
  final ValueChanged<Set<String>>? onInlineIdsChanged;  // 신규
}

// build → LayoutBuilder 내부, inlinePresets 산출 직후:
if (onInlineIdsChanged != null) {
  final ids = inlinePresets.map((p) => p.id).toSet();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    onInlineIdsChanged!(ids);
  });
}
```

**부모 State**:
```dart
Set<String> _boundaryInlineIds = {};

_BoundaryUserPresetRow(
  // ...
  onInlineIdsChanged: (ids) => _boundaryInlineIds = ids,  // setState 호출 안 함
)
```

### 2.3 동일 패턴 적용 위젯 (3개 추가)

- `_DotUserPresetRow` (in `qr_shape_tab/dot_preset_row.dart`)
- `_CustomEyeRow` (in `qr_shape_tab/eye_row.dart`)
- color tab inline rows: 색상 탭은 solid/gradient 두 row 가 있으므로 각각 별도 콜백

color tab 의 inline row 위젯 위치는 코드 재확인 후 동일 패턴 적용.

---

## 3. 변경 위치별 시그니처 (v2)

### 3.1 모달 위젯 공통 시그니처 변경 (4개 모달)

대상: `_BoundaryGridModal`, `_DotGridModal`, `_EyeGridModal`, `_ColorGridModal`.

```dart
class _BoundaryGridModal extends StatefulWidget {
  final List<UserShapePreset> presets;
  final _BoundaryGridMode mode;
  final String? selectedPresetId;          // v1 — 진입 시 highlight 시드
  final ValueChanged<UserShapePreset> onSelect;  // v2 신규 — 셀 탭 콜백
  ...
}

class _BoundaryGridModalState extends State<_BoundaryGridModal> {
  final _markedForDeletion = <String>{};
  String? _localSelectedId;  // v2 신규 — 시트 안에서 셀 highlight 추적

  @override
  void initState() {
    super.initState();
    _localSelectedId = widget.selectedPresetId;
  }

  // 셀 onTap (view 모드, 즉 isDelete=false):
  // v0: Navigator.pop(context, _BoundaryGridSelectResult(preset))
  // v2:
  setState(() => _localSelectedId = preset.id);
  widget.onSelect(preset);
  // ↑ 시트 그대로 유지

  // 셀 highlight 판정 (isCurrent):
  // v1: !isDelete && preset.id == widget.selectedPresetId
  // v2: !isDelete && preset.id == _localSelectedId

  // onLongPress (편집기 분기) 는 v0 그대로 — Navigator.pop(_XxxGridEditResult(preset))
  // 삭제 모드 분기는 v0 그대로
}
```

색상 탭의 `_ColorGridModal` 도 동일 패턴. 위젯 자체는 이미 selectedPresetId 받음 → onSelect 콜백 추가 + `_localSelectedId` 자체 state 추가 + 셀 onTap 의 `Navigator.pop(_ColorGridSelectResult)` 를 콜백 호출로 교체.

### 3.2 sealed result 정리

`_XxxGridSelectResult` sealed case 는 v2 에서 **사용되지 않음**. 그러나 클래스 정의는 남겨둘지 제거할지 선택:
- **제거** (권장): 클래스 정의·관련 case 분기 모두 삭제. 코드 단순화.
- 유지: 향후 사용 가능성 — but YAGNI 위반. **CLAUDE.md "backward-compat 코드 금지"** 에 따라 제거.

→ **결정: `_XxxGridSelectResult` 정의 + 부모 switch case 모두 제거.**

### 3.3 부모 State — sheet 호출부 패턴 (4개 탭 공통)

```dart
// boundary 예시 — _showBoundaryGridModal
Future<void> _showBoundaryGridModal(BuildContext context, {required _BoundaryGridMode mode}) async {
  if (_boundaryPresets.isEmpty) return;
  final beforeSelectedId = _selectedBoundaryPresetId;  // v2 신규
  final result = await showModalBottomSheet<_BoundaryGridResult?>(
    context: context,
    isScrollControlled: true,
    shape: ...,
    builder: (_) => _BoundaryGridModal(
      presets: _boundaryPresets,
      mode: mode,
      selectedPresetId: _selectedBoundaryPresetId,
      onSelect: _onSheetSelectBoundary,  // v2 신규
    ),
  );

  if (result == null) {
    // v2 신규 — 바깥 탭/dismiss 분기. 마지막 select 검사.
    final after = _selectedBoundaryPresetId;
    if (after != null
        && after != beforeSelectedId
        && !_inlineBoundaryIds.contains(after)) {
      await _datasource?.touchLastUsed(ShapePresetType.boundary, after);
      _loadPresets();
    }
    return;
  }

  switch (result) {
    case _BoundaryGridDeleteResult(:final deletedIds):
      // ... (v0 그대로)
    case _BoundaryGridEditResult(:final preset):
      // ... (v0 그대로 — 편집기 진입)
    // _BoundaryGridSelectResult case 는 v2 에서 삭제
  }
}

// v2 신규 — sheet 안 select 콜백 (inline tap 과 동일한 동작)
void _onSheetSelectBoundary(UserShapePreset p) {
  setState(() => _selectedBoundaryPresetId = p.id);
  ref.read(qrResultProvider.notifier).setBoundaryParams(p.boundaryParams!);
  // touchLastUsed 호출 안 함 — 시트 닫힘-후 분기에서 처리
}
```

### 3.4 dot / eye

dot, eye 도 §3.3 와 완전 동일 패턴. 신규 콜백 함수 2개 추가:
- `_onSheetSelectDot(UserShapePreset)` — `setCustomDotParams` 적용 + `_selectedDotPresetId` 갱신
- `_onSheetSelectEye(UserShapePreset)` — `setCustomEyeParams` 적용 + `_selectedEyePresetId` 갱신

`_showDotGridModal` / `_showEyeGridModal` 의 호출 패턴 / 닫힘-후 분기 동일.

### 3.5 color (solid + gradient)

v1 에서 만든 `_onUserSolidSelectFromSheet` / `_onUserGradientSelectFromSheet` 는 v2 에서 **단순화**:

```dart
// v1: sheet 콜백이 reorder 까지 책임
Future<void> _onUserSolidSelectFromSheet(UserColorPalette p) async {
  ...
  if (!_inlineSolidIds.contains(p.id)) {
    await _datasource?.touchLastUsed(p.id);
    _delayedReloadPresets();
  }
}

// v2: sheet 콜백은 inline 핸들러와 동일. reorder 는 sheet 호출부 닫힘-후 분기로 이동
void _onUserSolidSelectFromSheet(UserColorPalette p) {
  if (p.solidColorArgb == null) return;
  setState(() => _selectedSolidPresetId = p.id);
  _applyGradient(null);
  _applyColor(Color(p.solidColorArgb!));
  // touchLastUsed 호출 안 함
}
```

→ 이 시점에서 v1 의 `_onUserSolidSelect` (inline) 와 v2 의 `_onUserSolidSelectFromSheet` 가 **완전 동일** 해짐. **하나로 통합 가능**:

→ **결정: `_onUserSolidSelectFromSheet` 제거하고 inline 핸들러 `_onUserSolidSelect` 를 sheet 콜백으로도 사용.** gradient 도 동일.

`_showSolidGridModal` / `_showGradientGridModal` 도 §3.3 와 동일 패턴 — 닫힘-후 분기 추가, sealed case `_ColorGridSelectResult` 제거.

### 3.6 모달 위젯 자체 state 의 highlight 동기화

시트 진입 후 사용자가 inline 에서 다른 항목을 선택하는 경우는 없음 (시트가 화면을 덮음). 따라서 `_localSelectedId` 는 시트 안에서만 변동. 시트 닫힘 시 `_localSelectedId` 의 마지막 값 = 부모 `_selectedXxxPresetId` (콜백으로 동기화 됨). 별도 동기화 로직 불필요.

---

## 4. 데이터 흐름 (v2)

### 4.1 inline tap 흐름 (v1 그대로)
```
사용자 탭
  → onUserSelect(preset)
  → setState(_selectedXxxPresetId = preset.id)
  → ref.read(qrResultProvider.notifier).setXxx(preset.params)
  ✗ touchLastUsed 호출 없음 → inline 위치 불변
```

### 4.2 sheet 탐색·결정 흐름 (v2 신규)
```
사용자가 [...] 탭
  → sheet 열림 (modal 의 _localSelectedId = 부모 selectedPresetId)
  → 부모: beforeSelectedId 기록

(시트 안 반복 탭)
  사용자가 셀 A 탭
    → modal: setState(_localSelectedId = A.id)  → 셀 A 에 highlight
    → modal: widget.onSelect(A) 호출
    → 부모 _onSheetSelectXxx(A):
        setState(_selectedXxxPresetId = A.id)
        ref.read(...).setXxx(A.params)         → 미리보기 즉시 반영
        ✗ touchLastUsed 없음
  
  사용자가 셀 B 탭 → 동일 (highlight B 로 이동, 미리보기 B 로 갱신)

(사용자 결정)
  바깥 탭/드래그 다운 → showModalBottomSheet 가 result=null 로 반환

(시트 닫힘-후 처리, 부모 코드 위치)
  if (result == null):
    after := _selectedXxxPresetId
    if (after != null
        && after != beforeSelectedId
        && !_inlineXxxIds.contains(after)):
      touchLastUsed(after)
      _loadPresets() → 다음 build 시 inline 첫 자리에 등장
    else:
      (reorder 없음)
```

### 4.3 sheet 안 long-press → 편집기 흐름 (v0 그대로)
```
시트 안 long-press
  → modal: Navigator.pop(_XxxGridEditResult(preset))
  → 부모 result 분기 → 편집기 진입
  → 편집기 confirm 시 reorder (기존 동작)
  → 시트 닫힘-후 reorder 분기는 result != null 이라 실행 안 됨 (정합)
```

### 4.4 inlineIds 갱신 흐름 (v1 그대로)
```
탭 빌드
  → row 위젯 빌드 (LayoutBuilder)
  → inlinePresets 산출
  → addPostFrameCallback: onInlineIdsChanged(ids)
        → 부모 _inlineXxxIds = ids (setState 없음)
  → 다음 sheet 호출 시 최신값 사용
```

---

## 5. 4-경로 렌더링 영향 (CLAUDE.md §6)

❌ 영향 없음. 프리셋 메타데이터(lastUsedAt) 갱신 시점만 조정. QR 렌더 4-경로(미리보기/확대보기/PNG/SVG) 의 출력 도형/색상 결과는 **모두 동일** — `customization_mapper.dart` 같은 공유 util 거치는 흐름이 변하지 않음.

검증 체크리스트 (불필요하지만 자기 검증용):
- [x] preview 영향: 프리셋 적용 후 QR 도형 — 변경 없음
- [x] zoom 영향: 동일 위젯 재사용 — 변경 없음
- [x] PNG 영향: RepaintBoundary 캡처 — 변경 없음
- [x] SVG 영향: SVG 빌더 — 변경 없음

---

## 6. QR 스펙 영향 (CLAUDE.md §5)

❌ 무관. finder/timing/quiet zone/EC capacity 모두 변경 없음.

---

## 7. 디렉터리 영향 (v2)

```
lib/features/qr_result/tabs/
├── qr_background_tab.dart                   # M (sheet 닫힘-후 reorder 분기, _onSheetSelectBoundary 신규)
├── qr_color_tab.dart                        # M (FromSheet 핸들러 단순화·통합 / 닫힘-후 분기 / SelectResult case 제거)
├── qr_shape_tab.dart                        # M (_onSheetSelectDot/_onSheetSelectEye 신규, 닫힘-후 분기, SelectResult case 제거)
├── qr_shape_tab/
│   ├── boundary_preset_row.dart             # M (_BoundaryGridModal: onSelect + _localSelectedId 추가, SelectResult class 제거)
│   ├── dot_preset_row.dart                  # M (_DotGridModal: onSelect + _localSelectedId, SelectResult class 제거)
│   └── eye_row.dart                         # M (_EyeGridModal: onSelect + _localSelectedId, SelectResult class 제거)
└── qr_color_tab/
    └── color_grid_modal.dart                # M (_ColorGridModal: onSelect + _localSelectedId, SelectResult case 제거)
```

신규 파일 0개. 기존 파일 수정만. v1 에서 추가된 `_inlineXxxIds` 필드, `onInlineIdsChanged` 콜백, modal `selectedPresetId` 파라미터는 v2 에서도 그대로 활용.

---

## 8. 구현 순서 (v2 — Do phase 용)

각 모달·탭마다 동일 패턴이 4곳에 적용됨. 모달 단위로 묶어서:

1. **`_BoundaryGridModal`** (in `boundary_preset_row.dart`)
   - `onSelect` 파라미터 추가
   - `_BoundaryGridModalState` 에 `_localSelectedId` 추가 (initState 시 widget.selectedPresetId 로 시드)
   - 셀 onTap (view 모드): `Navigator.pop(_BoundaryGridSelectResult)` → `setState(_localSelectedId) + widget.onSelect(preset)`
   - isCurrent 판정을 `widget.selectedPresetId` → `_localSelectedId` 로 교체
   - `_BoundaryGridSelectResult` sealed class + 부모 switch case 제거

2. **`qr_background_tab.dart`**
   - `_onSheetSelectBoundary(UserShapePreset)` 신규
   - `_showBoundaryGridModal`: `beforeSelectedId` 캡처, modal 호출에 `onSelect: _onSheetSelectBoundary` 추가
   - sheet 닫힘 후 `result == null` 분기 추가 (after vs before 비교 후 reorder)
   - 기존 `_BoundaryGridSelectResult` case 제거

3. **`_DotGridModal`** + `_EyeGridModal` (in `dot_preset_row.dart`, `eye_row.dart`)
   - 동일 패턴 (onSelect / _localSelectedId / SelectResult 제거)

4. **`qr_shape_tab.dart`**
   - `_onSheetSelectDot`, `_onSheetSelectEye` 신규
   - `_showDotGridModal` / `_showEyeGridModal` — 닫힘-후 분기 추가, SelectResult case 제거

5. **`_ColorGridModal`** (in `color_grid_modal.dart`)
   - 동일 패턴 (onSelect / _localSelectedId / SelectResult case 제거)

6. **`qr_color_tab.dart`**
   - `_onUserSolidSelectFromSheet` 함수 본문 단순화 → 결과적으로 `_onUserSolidSelect` (inline 핸들러) 와 동일해짐 → **`FromSheet` 함수 자체를 제거**하고 모달 onSelect 에 inline 핸들러 직접 연결
   - gradient 도 동일 (FromSheet 제거)
   - `_showSolidGridModal` / `_showGradientGridModal` — 닫힘-후 분기 추가, SelectResult case 제거
   - `_inlineSolidIds`, `_inlineGradientIds` 필드 그대로 활용

각 단계마다 build 가능하도록 점진 변경. 마지막에 flutter analyze pass.

---

## 9. Edge Cases (Plan §6 재확인 + v2 추가)

1. **inline 슬롯 0개**: 모든 프리셋이 sheet-only → 시트 닫힘 시 마지막 선택이 있으면 reorder. ✅
2. **회전 변경**: row LayoutBuilder rebuild → inlineIds 갱신 → 다음 sheet 진입 시 새 폭 기준 판정. ✅
3. **신규 프리셋 직후**: 신규 저장 → reorder → inline 첫 자리. 다음 build 시 `_inlineXxxIds` 포함 → inline tap reorder 없음. ✅
4. **sheet 진입 직후 첫 프레임**: row 첫 build 전이면 `_inlineXxxIds` 빈 set. 안전한 fallback. ✅
5. **dedupe 매칭 (boundary 편집기 confirm)**: 매칭 프리셋 `touchLastUsed` 호출. ✅
6. **(v2) 시트 안에서 동일 항목 재탭**: `_localSelectedId` 그대로. 시트 닫힘 시 진입-전 selectedId 와 비교 — 변동 없으면 reorder 없음. ✅
7. **(v2) 시트 안에서 A → B → A 탭 후 닫음**: 마지막 = A. 진입-전과 비교 후 다르고 sheet-only 면 reorder. ✅
8. **(v2) 시트 안 long-press 로 편집기 진입**: result = `_XxxGridEditResult` → 부모 switch 분기에서 처리. result != null 이라 닫힘-후 reorder 분기는 실행 안 됨. 편집기 confirm 시 reorder. ✅
9. **(v2) 시트 진입 후 빠른 dismiss (탭 없이 바깥 탭)**: result=null, beforeSelectedId == _selectedXxxPresetId → 비교 후 reorder 없음. ✅
10. **(v2) 시트 안 select 후 시스템 dismiss (앱 백그라운드)**: showModalBottomSheet 가 result=null 로 정상 반환. 일반 dismiss 와 동일 처리. ✅
11. **(v2) 삭제 모드 → 일반 선택 모드 전환 시도**: 모달 mode 가 enum 으로 분리됨 (delete/view). 모드 전환 없이 시트 종료 후 재진입 흐름. v2 변경 영향 없음. ✅

---

## 10. 검증 체크리스트 (Plan §8 동기)

### v1 (구현 완료 — 회귀 확인)
- [x] inline tap 으로 동일 프리셋 여러 번 → 옆 프리셋 위치 불변
- [x] sheet 진입 시 현재 사용중 프리셋 highlight 표시
- [x] long-press 편집기 → confirm → 항상 reorder
- [x] 신규 저장 / dedupe 매칭 → 항상 reorder
- [x] 4 종류 동일 정책
- [x] flutter analyze 통과

### v2 (Do/Check 단계 신규 검증)
- [ ] sheet 항목 탭 시 시트 안 닫힘 (미리보기·highlight 즉시 갱신, 시트 유지)
- [ ] sheet 안에서 여러 항목 차례로 탭해도 시트 유지 + 마지막 탭 셀에 highlight
- [ ] sheet 바깥 탭/드래그 다운으로 dismiss 가능
- [ ] sheet dismiss 시점에 마지막 선택이 sheet-only 였으면 reorder 1회 (다음 진입 시 inline 첫 자리)
- [ ] sheet dismiss 시점에 마지막 선택이 inline-visible 또는 진입-전과 동일이면 reorder 없음
- [ ] sheet 안 long-press → 시트 닫힘 + 편집기 진입 (편집기 confirm 시 reorder)
- [ ] 4 종류(boundary, dot, eye, color solid+gradient) 모두 동일 동작
- [ ] `_XxxGridSelectResult` sealed class 4개 모두 제거됨
- [ ] color tab 의 `_onUserSolid/GradientSelectFromSheet` 함수 제거됨 (inline 핸들러 직접 사용)
- [ ] flutter analyze 통과
