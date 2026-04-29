# Plan — 사용자 프리셋 reorder 정책 개선

> 생성일: 2026-04-29
> 갱신일: 2026-04-29 (v2 — 시트 닫기 동작 + reorder 시점 지연)
> Feature ID: `preset-reorder-policy`
> 트리거: inline row 의 프리셋을 단순 선택해도 reorder 가 일어나서 옆 프리셋이 밀려 혼란. bottom sheet 에 현재 사용중 프리셋 표시 부재. sheet 항목 탭 즉시 시트가 닫혀 비교·탐색 어려움.

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | (1) 모양/색상/배경 4개 프리셋에서 inline 에 이미 보이는 프리셋을 선택만 해도 `touchLastUsed` 로 reorder 발생 → 옆 프리셋 위치 흔들림. (2) bottom sheet 진입 시 현재 사용중 프리셋 표시 부재. (3) sheet 항목 탭 시 즉시 시트가 닫혀 여러 프리셋 비교·탐색 불가 + 미리보기 확인 후 다른 항목 시도하려면 시트를 다시 열어야 함. |
| **Solution** | (1) reorder 트리거를 "사용자가 inline 에 없던 프리셋을 새로 끌어올린 행동" 으로 한정. (2) sheet 에 현재 선택 highlight 표시. (3) sheet 항목 탭 시 시트 유지 — 미리보기·선택만 즉시 적용하고 reorder 는 시트가 닫히는 시점에 1회 일괄 처리. 시트는 바깥 탭/드래그 다운으로만 닫힘. |
| **Function UX Effect** | inline 위치 안정 → 근육 기억 보존. sheet 가 "탐색·비교 보드" 역할: 여러 프리셋을 차례로 탭해 미리보기 확인 후 마음에 드는 것에서 바깥 탭으로 닫음. 닫는 순간 최종 선택이 sheet-only 였으면 자연스럽게 inline 첫 자리로 승격. |
| **Core Value** | "선택" / "사용 갱신" / "탐색" 의 의미 분리. 시트 = 탐색 공간, 닫힘 = 결정 시점, reorder = 결정의 결과. UX 계층 명확화. |

---

## 1. 현재 동작

### 1.1 영향 받는 4개 프리셋 종류

| 종류 | Datasource | 탭 파일 |
|------|------------|---------|
| boundary (배경 외각) | `LocalUserShapePresetDatasource` | `qr_background_tab.dart` |
| dot (모양 — 도트) | `LocalUserShapePresetDatasource` | `qr_shape_tab.dart` |
| eye (모양 — finder 눈) | `LocalUserShapePresetDatasource` | `qr_shape_tab.dart` |
| color (색상 팔레트) | `HiveColorPaletteDatasource` | `qr_color_tab.dart` |

### 1.2 reorder 동작

- 모든 선택 경로가 `touchLastUsed(id)` 호출 → `lastUsedAt = DateTime.now()` 갱신
- `_loadPresets()` 가 `lastUsedAt` 내림차순 정렬 → inline row 첫 자리(=[+] 버튼 옆)로 이동

### 1.3 reorder 가 호출되는 4개 경로

| # | 경로 | 현재 동작 |
|---|------|-----------|
| 1 | inline row tap (선택) | reorder ✅ |
| 2 | inline row long-press (편집기 진입) | reorder ✅ |
| 3 | bottom-sheet `[…]` tap (선택) | reorder ✅ |
| 4 | bottom-sheet `[…]` long-press (편집기 진입) | reorder ✅ |

### 1.4 inline row 표시 슬롯 계산

`_BoundaryUserPresetRow.build` 의 `LayoutBuilder` 에서:
```dart
final fixedWidth = chipSize + gap;  // [+] 버튼
final remaining = totalWidth - fixedWidth;
final maxSlots = (remaining / (chipSize + gap)).floor();
final needMore = userPresets.length > maxSlots;
final inlineCount = needMore ? maxSlots - 1 : maxSlots;
final inlinePresets = userPresets.sublist(0, inlineCount);
```
→ 화면 폭에 따라 **inline 에 보이는 개수가 동적**. dot/eye/color 도 유사 패턴.

### 1.5 bottom sheet 의 selection highlight

- boundary/dot/eye: `_xxxGridModal` 위젯에 현재 선택된 프리셋 id 가 전달되지 않음 → 선택 표시 없음
- color: 별도 확인 필요

---

## 2. 변경 사항

### 2.1 reorder 정책 매트릭스 (v2 — 시트 닫힘 시점에 일괄 처리)

| 진입점 | inline 에 보임 | inline 에 안 보임 (sheet-only) |
|---|---|---|
| **inline tap** (선택) | reorder ❌ | (해당 없음) |
| **inline long-press → 편집기** | reorder ✅ (편집 = 사용 갱신) | (해당 없음) |
| **sheet tap (시트 열린 동안)** | 미리보기·선택만 적용, 시트 유지, reorder **보류** | 미리보기·선택만 적용, 시트 유지, reorder **보류** |
| **sheet 닫힘** (바깥 탭 / 드래그 다운 dismiss) | reorder ❌ (마지막 선택이 inline 이면 무시) | reorder ✅ (마지막 선택만 1회) |
| **sheet long-press → 편집기** | 시트 닫힘 + 편집기 진입. 편집기 confirm 시 reorder | 동일 |
| **편집기 confirm (신규 저장)** | reorder ✅ (기존 동작) | reorder ✅ |
| **편집기 confirm (dedupe 매칭)** | reorder ✅ (기존 동작) | reorder ✅ |

### 2.2 핵심 룰 요약

1. **선택 ≠ 사용 갱신.** 단순 선택만으로는 `lastUsedAt` 을 건드리지 않는다.
2. **시트는 탐색 공간, 닫힘이 결정 시점.** sheet 항목 탭은 미리보기·선택만 적용하고 시트는 유지. reorder 는 시트 닫힘 시점에 마지막 선택 1개만 1회 적용.
3. **사용 갱신 트리거**:
   - **시트 닫힘 시 마지막 선택이 sheet-only 였던 경우** — 새로 끌어올린 사용 의도
   - **편집** (long-press → 편집기 → confirm) — 값 변동 여부 무관 항상 갱신
   - **신규 저장 / dedupe 매칭** (기존 그대로)
4. **bottom sheet 진입 시** 현재 사용중 프리셋에 selection highlight. 시트 안에서 다른 항목 탭 시 highlight 도 그 항목으로 즉시 이동.

### 2.3 inline-visible 판정 로직

inline row 위젯이 LayoutBuilder 안에서 `inlinePresets` 계산 → 결과 id 집합을 부모 State 에 callback (`onInlineIdsChanged`) 으로 통보. → **이미 구현됨** (직전 v1 단계).

### 2.4 bottom sheet selection highlight

각 `_xxxGridModal` 위젯에 `selectedPresetId: String?` 파라미터 추가, 셀이 해당 id 일 때 highlight. → **이미 구현됨** (직전 v1 단계). 단 v2 에서는 sheet 내부 select 도 시트 닫지 않고 highlight 만 갱신해야 하므로 modal 위젯이 *자체 state* 로 highlight 를 추적해야 함 (design phase 확정).

### 2.5 시트 인터랙션 변경 (v2 신규)

#### 동작 흐름
```
사용자가 [...] 탭 → 시트 열림 (현재 사용중 프리셋 highlight)
   ↓
사용자가 항목 A 탭 → 미리보기 즉시 적용, 시트 안의 highlight 가 A 로 이동, 시트는 그대로 열림
   ↓
사용자가 항목 B 탭 → 미리보기 B 로 갱신, highlight B 로 이동
   ↓ (사용자가 마음에 들면)
바깥 탭 / 드래그 다운 → 시트 dismiss
   ↓
부모: 시트 진입 전 _selectedXxxPresetId 와 비교
   - 동일: reorder 없음 (탐색만 하고 결정 없이 닫음)
   - 다름:
       - 마지막 선택이 inline-visible: reorder 없음 (이미 보이는 거였음)
       - 마지막 선택이 sheet-only: touchLastUsed + _loadPresets() 로 reorder 1회
```

#### sheet long-press 와의 분기
시트 안에서 long-press 는 즉시 시트 닫고 편집기 진입. 이 경로는 result 로 `_XxxGridEditResult(preset)` 반환 → 시트가 정상 닫힘 result 보유. 편집기 confirm 시점에 reorder 가 발생 (기존 동작 그대로).

result 분기:
- `result == null` (바깥 탭/dismiss) → "탐색만 한 후 닫음" 분기 → 위 reorder 판정
- `result is _XxxGridEditResult` → 편집기 진입 (시트 안에서 select 했더라도 마지막 select 는 무시, 편집 항목 우선)
- `result is _XxxGridDeleteResult` → 삭제 모드 결과 처리 (기존)
- `_XxxGridSelectResult` 케이스는 v2 에서 **제거** (select 는 더 이상 result 로 반환 안 함, 콜백으로만 통보)

#### 모달 위젯 시그니처 변경 (high-level)
- 신규 콜백 `onSelect: ValueChanged<UserShapePreset>` 추가 — sheet 내부 셀 탭 시 호출
- 모달 내부 state 에 `_localSelectedId` 추가 — 셀 highlight 가 사용자 탭 따라 즉시 갱신되도록
- 셀 onTap 핸들러: `Navigator.pop` 대신 `setState(_localSelectedId = preset.id)` + `widget.onSelect(preset)`
- onLongPress (편집기) 분기는 그대로 `Navigator.pop(_XxxGridEditResult(preset))`
- 삭제 모드 분기 그대로

#### 부모 State 변경 (high-level)
```dart
// 시트 호출부 (boundary 예시)
final beforeSelectedId = _selectedBoundaryPresetId;
final result = await showModalBottomSheet<_BoundaryGridResult>(
  ...
  builder: (_) => _BoundaryGridModal(
    presets: _boundaryPresets,
    mode: mode,
    selectedPresetId: _selectedBoundaryPresetId,
    onSelect: _onSheetSelectBoundary,  // 신규
  ),
);

// 시트 닫힘 후
if (result == null) {
  // 바깥 탭/dismiss — 마지막 선택 검사
  final after = _selectedBoundaryPresetId;
  if (after != null && after != beforeSelectedId
      && !_inlineBoundaryIds.contains(after)) {
    await _datasource?.touchLastUsed(ShapePresetType.boundary, after);
    _loadPresets();
  }
} else {
  switch (result) {
    case _BoundaryGridDeleteResult: ... (기존)
    case _BoundaryGridEditResult: ... (기존)
    // _BoundaryGridSelectResult 제거
  }
}

void _onSheetSelectBoundary(UserShapePreset p) {
  setState(() => _selectedBoundaryPresetId = p.id);
  ref.read(qrResultProvider.notifier).setBoundaryParams(p.boundaryParams!);
  // touchLastUsed 호출 안 함 — 시트 닫힐 때 처리
}
```

같은 패턴을 dot, eye, color(solid), color(gradient) 4개 종류에 적용. v1 의 `_onUserSolidSelectFromSheet` / `_onUserGradientSelectFromSheet` 는 v2 에서 시트 닫힘-후 처리 분기로 흡수 (touchLastUsed 호출 위치만 이동).

---

## 3. Architecture (CLAUDE.md 고정)

### 3.1 Project Level
**Flutter Dynamic × Clean Architecture × R-series**

### 3.2 Key Architectural Decisions
| 항목 | 값 |
|------|---|
| Framework | Flutter |
| State Management | Riverpod StateNotifier (이번 변경은 탭 위젯 로컬 State 만 건드림 — provider 신규 없음) |
| Persistence | Hive (기존 `LocalUserShapePresetDatasource` / `HiveColorPaletteDatasource` 그대로) |
| Router | go_router (영향 없음) |

### 3.3 변경 위치
- `lib/features/qr_result/tabs/qr_background_tab.dart` (boundary)
- `lib/features/qr_result/tabs/qr_shape_tab.dart` (dot, eye)
- `lib/features/qr_result/tabs/qr_color_tab.dart` (color)
- 각 탭의 inline row / bottom-sheet modal 위젯 (`_BoundaryUserPresetRow`, `_BoundaryGridModal`, dot/eye/color 대응 위젯)

신규 entity / sub-state / mixin 없음. 모두 기존 파일 내부 변경.

### 3.4 단일 소스 원칙
"inline 에 보이는 프리셋 id 집합" 은 inline row 위젯 한 곳에서만 계산하고 callback 으로 노출. 탭 State 와 bottom-sheet 호출 양쪽이 같은 소스를 본다.

---

## 4. 4-경로 렌더링 영향 (CLAUDE.md §6)

이 변경은 프리셋 메타데이터(lastUsedAt) 의 갱신 시점만 조정. **QR 렌더링 4-경로(미리보기/확대보기/PNG/SVG) 영향 없음**. 프리셋이 적용된 후의 QR 도형/색상은 동일 util(`customization_mapper.dart`) 을 그대로 거치므로 출력 일치 자동 유지.

---

## 5. QR 스펙 영향 (CLAUDE.md §5)

영향 없음. finder/timing/quiet zone/EC 모두 무관.

---

## 6. Edge Cases & 주의

1. **inline 슬롯 0 개 (극단적으로 좁은 화면)**: 모든 프리셋이 sheet-only → 시트 닫힘 시 마지막 선택이 있으면 항상 reorder. 자연스러움.
2. **회전(orientation) 변경**: 화면 폭 변동으로 inline 슬롯 수 바뀜. 회전 후 sheet 진입 시 새 inline 기준으로 판정 — 의도대로 동작.
3. **신규 프리셋 직후**: 신규는 항상 reorder 되어 inline 첫 자리. inline 에 보이게 되므로 다음 선택 시 reorder 안 함 — 정합.
4. **dedupe 매칭 (boundary-tab dedupe)**: 매칭된 기존 프리셋의 `touchLastUsed` 는 그대로 호출 (편집기 confirm = 사용 갱신).
5. **삭제 후 재선택**: 삭제는 `_cache` 무효화. 영향 없음.
6. **시트 안에서 동일 항목 재탭**: `_localSelectedId` 가 그대로. 시트 닫힘 시 진입 전 selectedId 와 비교 — 변동 없으면 reorder 없음.
7. **시트 안에서 A → B → A 순으로 탭 후 닫음**: 마지막 = A. 시트 진입 전 selectedId 와 A 가 다르고 sheet-only 면 reorder. 동일하면 reorder 없음.
8. **시트 진입 후 long-press 로 편집기 진입**: 시트 안에서 select 했던 항목은 무시되고 편집 항목만 처리. select 흔적은 부모 `_selectedXxxPresetId` 에 남지만, 편집기 confirm 시점에 편집 항목으로 다시 갱신됨.
9. **시트 안 select 후 시스템 dismiss (앱 백그라운드 등)**: sheet builder 가 dispose 되며 result=null. 닫힘-후 처리가 일반 dismiss 와 동일하게 작동. 안전.
10. **시트 진입 → 빠른 더블 탭 → dismiss**: 마지막 탭만 기록. 일반 동작.

---

## 7. Out of Scope

- inline row 슬롯 수 조절 (화면 폭별 max 제한 등)
- 정렬 기준 변경 (lastUsedAt 외에 createdAt, name 등)
- 프리셋 그룹화·태깅
- 컬러 탭의 solid/gradient 외 다른 종류 추가

---

## 8. 검증 체크리스트 (Do/Check 단계용)

### v1 (이미 검증)
- [x] inline tap 으로 동일 프리셋을 여러 번 눌러도 다른 프리셋 위치 불변
- [x] sheet 진입 시 현재 사용중 프리셋에 highlight 표시
- [x] long-press 편집기 → confirm → 항상 reorder
- [x] 신규 저장 / dedupe 매칭 → 항상 reorder
- [x] 4 종류(boundary, dot, eye, color) 동일 정책 적용

### v2 (신규)
- [ ] 시트 항목 탭 시 시트 안 닫힘 (미리보기·highlight 만 즉시 갱신)
- [ ] 시트 안에서 여러 항목을 차례로 탭해도 시트 유지 + 마지막 탭한 셀 highlight
- [ ] 시트 바깥 탭/드래그 다운으로 dismiss 됨
- [ ] 시트 dismiss 시점에 마지막 선택이 sheet-only 였으면 reorder 1회 적용 (다음 시트 진입 시 inline 첫 자리)
- [ ] 시트 dismiss 시점에 마지막 선택이 inline-visible 이거나 진입 전과 동일하면 reorder 없음
- [ ] 시트 안에서 long-press → 편집기 진입은 시트 닫힘 + 편집기. 편집기 confirm 시 reorder
- [ ] 4 종류(boundary, dot, eye, color solid+gradient) 전부 동일 동작
- [ ] flutter analyze 통과
