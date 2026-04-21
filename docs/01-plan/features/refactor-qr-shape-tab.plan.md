---
template: plan
version: 1.0
feature: refactor-qr-shape-tab
date: 2026-04-20
author: tawool83
project: app_tag
---

# refactor-qr-shape-tab Planning Document

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | `qr_shape_tab.dart` 파일이 **2101줄**(27개 top-level 클래스/enum)까지 커져 IDE 탐색, 코드 리뷰, Hot Reload 부담이 증가. 단일 파일에 4개 편집기 + 4개 프리셋 행 + 11개 공유 위젯이 혼재. |
| **Solution** | 폴더 단위로 **17개 파일**로 분해 (coordinator 1 + enum 1 + widgets 11 + editors 4). 접두사 `_` 제거해 feature 내부 public 클래스로 승격. **동작 변경 없음** (순수 구조 리팩터). |
| **Function/UX** | 사용자 관점 변화 없음. 개발자 관점에서는 각 편집기/위젯이 독립 파일로 존재해 변경 영향 범위 축소, diff 리뷰 용이. |
| **Core Value** | 장기 유지보수성. 신규 편집기 추가/기존 편집기 수정 시 해당 파일만 터치하면 됨. 추가 단위 테스트 작성도 용이. |

---

## 1. Problem Statement

### 1.1 현재 상태
- **파일**: `lib/features/qr_result/tabs/qr_shape_tab.dart`
- **크기**: 2101줄 (1000줄 이상 파일 중 유일)
- **클래스 수**: 27개 (`QrShapeTab` + State + 25개 private 헬퍼)
- **외부 import**: 1곳 (`qr_result_screen.dart:24`)

### 1.2 문제점
1. **탐색 비용**: 특정 편집기/위젯 찾기 위해 2101줄 스크롤
2. **리뷰 비용**: 한 편집기 수정 시 거대 diff에 묻힘
3. **Hot Reload**: 파일 전체 재컴파일
4. **테스트 작성 어려움**: private 클래스는 단위 테스트 불가
5. **코드 소유권 불명확**: 여러 관심사가 한 파일에 혼재

### 1.3 해결하지 않을 것 (Non-Goals)
- 동작/UI 변경 **없음**
- 새 기능 추가 **없음**
- 위젯 API(prop) 변경 **없음**
- Riverpod/Provider 구조 변경 **없음**
- `QrResultState`/도메인 엔티티 변경 **없음**

---

## 2. Functional Requirements

| # | 요구사항 | 우선순위 | 상태 |
|---|---------|---------|------|
| FR-01 | `qr_shape_tab.dart` 기존 경로 유지 (외부 import 경로 호환) | High | Pending |
| FR-02 | 분할 후 각 파일 ≤ **400줄** | High | Pending |
| FR-03 | 27개 top-level 중 `QrShapeTab` + `QrShapeTabState`만 main 파일에 유지 | High | Pending |
| FR-04 | `_EditorType` enum → 독립 파일 `editor_type.dart` | High | Pending |
| FR-05 | 4개 편집기(Dot/Eye/Boundary/Animation) → `editors/` 하위 4개 파일 | High | Pending |
| FR-06 | 4개 프리셋 Row(Dot/Eye/Boundary/Animation) → `widgets/{name}_preset_row.dart` | High | Pending |
| FR-07 | 공유 UI 조각 9개 → `widgets/` 하위 개별 파일 | High | Pending |
| FR-08 | 접두사 `_` 제거로 feature-내 public 승격 (기본 방침) | High | Pending |
| FR-09 | `DotGridModal` 및 그 Result 서브클래스는 프리셋 Row와 같은 파일에 동거 (강결합) | Medium | Pending |
| FR-10 | `_PresetIconPainter`의 static TextPainter 캐시 유지 (이전 simplify 수정 보존) | High | Pending |
| FR-11 | `_DotEditor`의 `_sliderToScale`/`_scaleToSlider`/`_formatScaleLabel`/`_buildScaleSlider` 헬퍼는 Dot 편집기 파일 안에 유지 | High | Pending |
| FR-12 | `flutter analyze` 에러 0건 (기존 unrelated info/warning 제외) | High | Pending |
| FR-13 | 주요 경로 실기기 스모크 테스트 통과: (1) 도트 편집 (2) 눈 편집 (3) 외곽 편집 (4) 애니메이션 편집 | High | Pending |

---

## 3. Proposed File Structure

```
lib/features/qr_result/tabs/
├── qr_shape_tab.dart                    # (유지) facade: export 'qr_shape_tab/qr_shape_tab_screen.dart'
│                                        #   → 외부 import 호환성 보존 (FR-01)
└── qr_shape_tab/
    ├── qr_shape_tab_screen.dart         # QrShapeTab + State (~560줄)
    ├── editor_type.dart                 # EditorType enum
    ├── editors/
    │   ├── dot_editor.dart              # DotEditor + ModeToggleButton + 슬라이더 헬퍼 (~270줄)
    │   ├── eye_editor.dart              # EyeEditor (~70줄)
    │   ├── boundary_editor.dart         # BoundaryEditor (~125줄)
    │   └── animation_editor.dart        # AnimationEditor (~55줄)
    └── widgets/
        ├── dot_preset_row.dart          # DotPresetRow + DotChip + DotGridModal + Result 클래스들 (~350줄)
        ├── eye_preset_row.dart          # CustomEyeRow + RandomEyeButton (~80줄)
        ├── boundary_preset_row.dart     # BoundaryPresetRow (~75줄)
        ├── animation_preset_row.dart    # AnimationPresetRow (~70줄)
        ├── add_button.dart              # AddButton (~30줄)
        ├── preset_chip.dart             # PresetChip (~60줄)
        ├── preset_icon_painter.dart     # PresetIconPainter (~65줄, static 캐시 포함)
        ├── slider_row.dart              # SliderRow (~65줄)
        ├── shape_row.dart               # OuterShapeRow + InnerShapeRow + ShapeButton (~110줄)
        └── shape_icon_painter.dart      # OuterIconPainter + InnerIconPainter (~90줄)
```

**분할 후 예상 크기**:
- 가장 큰 파일: `dot_preset_row.dart` (~350줄)
- 가장 작은 파일: `editor_type.dart` (1줄 enum)
- 평균: ~150줄

---

## 4. Migration Strategy

### 4.1 단계별 접근 (Safe-Refactor)
1. **Phase A — 스캐폴딩**: 새 폴더 `qr_shape_tab/` 생성
2. **Phase B — 공유 위젯 이동**: SliderRow, ShapeButton, IconPainter 등 공유 조각 먼저 (의존성 바닥 계층)
3. **Phase C — 편집기 4종 이동**: DotEditor, EyeEditor, BoundaryEditor, AnimationEditor
4. **Phase D — 프리셋 Row 4종 이동**: DotPresetRow (+DotGridModal), EyePresetRow, BoundaryPresetRow, AnimationPresetRow
5. **Phase E — Screen 이동 + facade**: `QrShapeTab`/`QrShapeTabState`를 `qr_shape_tab_screen.dart`로 이동, 기존 `qr_shape_tab.dart`는 1줄 re-export facade로 변경
6. **Phase F — 검증**: `flutter analyze` + 실기기 스모크 테스트

각 Phase 완료마다 `flutter analyze` 통과 확인 → 단위별 커밋 가능.

### 4.2 Privacy 처리
- 접두사 `_` 제거 → **public** 승격 (예: `_DotEditor` → `DotEditor`)
- 새 폴더 내부에서만 import되므로 실질적 노출 위험 없음
- 예외: `_DotGridResult` 클래스 계층은 파일-내 private 유지 (단일 파일 안에서만 사용)

### 4.3 risk & mitigation
| Risk | 영향 | 완화 |
|------|------|------|
| 의존성 그래프 순환 발생 | 컴파일 실패 | 바닥 계층(공유 위젯)부터 이동 (Phase B 우선) |
| 외부 import 경로 파괴 | `qr_result_screen` 빌드 실패 | 기존 `qr_shape_tab.dart`를 facade로 유지 (FR-01) |
| private → public 노출 확장 | 의도치 않은 사용 | 네이밍 컨벤션: feature 폴더 밖에서 import 금지 (린트 추가는 범위 외) |
| 실기기 회귀 | 편집 UX 파손 | Phase F 스모크 테스트 4개 시나리오 필수 |

---

## 5. Success Criteria

- [ ] `qr_shape_tab.dart` 기존 경로 유지 + 모든 기존 import 호환 (FR-01)
- [ ] 신규 파일 모두 ≤ 400줄 (FR-02)
- [ ] 기존 `qr_shape_tab.dart` facade는 ≤ 10줄 (single re-export)
- [ ] `flutter analyze` 에러 0건 (FR-12)
- [ ] 실기기에서 4개 편집 경로 정상 동작 (FR-13)
- [ ] 분할 후 `git diff --stat`: 신규 17개 파일 + 기존 1개 파일 축소
- [ ] PDCA Check 단계 Match Rate ≥ 90%

---

## 6. Out of Scope (별도 PDCA 사이클)

- R2: `QrResultState` 26-field 재설계 (touch files 10+)
- R3: `qr_result_screen.dart` 730줄 God screen 분해
- R4: `SettingsService` SharedPreferences 인스턴스 캐시
- U3: TagFormScaffold (7 tag input 화면 스캐폴드 공통화)

---

## 7. Effort Estimate

| Phase | 예상 작업 시간 |
|-------|-------------|
| A. 스캐폴딩 | 5분 |
| B. 공유 위젯 이동 (9개 파일) | 30분 |
| C. 편집기 이동 (4개 파일) | 25분 |
| D. 프리셋 Row 이동 (4개 파일) | 35분 |
| E. Screen 이동 + facade | 15분 |
| F. 검증 (analyze + 스모크) | 20분 |
| **총** | **~2시간** |

---

## 8. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-04-20 | Initial plan — R1 (qr_shape_tab.dart 2101줄 → 17개 파일 분해, 순수 구조 리팩터) | tawool83 |
