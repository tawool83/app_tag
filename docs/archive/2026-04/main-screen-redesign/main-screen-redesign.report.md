# Completion Report — main-screen-redesign

> 생성일: 2026-04-23
> Feature ID: `main-screen-redesign`
> PDCA Cycle: Plan → Design → Do → Check → Report

---

## Executive Summary

### 1.1 Overview

| Item | Value |
|------|-------|
| **Feature** | Main Screen Redesign (만들기-중심 홈 + 작업=템플릿 통합) |
| **Started** | 2026-04-23 |
| **Completed** | 2026-04-23 |
| **Duration** | 1 day (single session) |

### 1.2 Results

| Metric | Value |
|--------|-------|
| **Match Rate** | 97% |
| **Implementation Items** | 18/18 (100%) |
| **New Files** | 6 |
| **Modified Files** | ~12 |
| **Deleted Files/Dirs** | ~15 (UserQrTemplate 계층 + output_selector) |
| **l10n Keys Added** | ~20 (app_ko.arb) |
| **Iterations** | 0 (first-pass 97%) |

### 1.3 Value Delivered

| Perspective | Delivered |
|-------------|-----------|
| **Problem** | 홈이 "입력 진입점 10타일 나열"에서 "내 QR 작업물 갤러리" 중심으로 전환. 홈/히스토리 데이터 독립 분리 완료. 편집 후 홈 미반영 버그 해결. debounce 마지막 변경 소실 문제 해결. |
| **Solution** | `[새로 만들기]` CTA + QrTask 갤러리 + 삭제 모드 구현. `showOnHome` 플래그로 홈/히스토리 분리. `flushPendingPush()` + `_recapture()` + `onChanged()` 체인으로 편집 즉시 반영. 미리보기 220px + scale 1.15 여백 제거. |
| **Function UX Effect** | 홈 1-depth에 QR 갤러리 즉시 노출. 탭 → 확대 미리보기 + 5개 액션(저장/공유/편집/이름변경/삭제). 삭제 모드에서 다중/전체 선택 지원. 꾸미기 화면 `←` + `저장` 단순화. |
| **Core Value** | 앱 강점(꾸미기)을 홈 1-depth로 노출 + "저장 버튼 없는 자동 템플릿화" + 홈/히스토리 독립 관리 + 편집 후 즉시 반영 보장 |

---

## 2. PDCA Phase Summary

### 2.1 Plan

- 10개 기능 요구사항(FR-01~FR-09 + 자동 명명) 정의
- 6개 Open Decision (D1~D6) 식별
- QrTask 엔티티 v2 스키마 설계 (name, thumbnailBytes, showOnHome 추가)
- UserQrTemplate 통합 삭제 방침 확정
- 빌트인 프리셋 10종 → 3종 축소 결정

### 2.2 Design

- D1~D6 전체 확정 (스캐너 AppBar 배치, debounce 500ms, off-screen 렌더링, NFC disabled 처리, lazy fallback, 편집 기능 삭제)
- 18개 구현 항목 순서화 (Group A: 데이터/도메인, Group B: 삭제, Group C: UI)
- 파일 크기 준수 계획 (UI ≤ 400줄, entity ≤ 200줄)
- 11개 Edge Case 정의

### 2.3 Do (Implementation)

**구현 완료 항목 (18/18)**:

| Group | Items | Description |
|-------|:-----:|-------------|
| A: 데이터/도메인 | 1~8 | QrTask v2, Repository 확장, UseCase 5개, Provider 5개, flushPendingPush, AppBar, 썸네일 persist, RenameDialog |
| C: UI | 9~14 | QrTaskGalleryTile, QrTaskActionSheet, CreatePickerSheet, HomeScreen rewrite, l10n, 테스트 수정 |
| B: 삭제 | 15~18 | UserQrTemplate 계층 삭제, Hive box 삭제, output_selector 삭제, default_templates.json 축소 |

**세션 중 발견 & 수정한 버그 3건**:

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| 꾸미기 편집 후 홈 미반영 | `_editAgain`이 sync push + onChanged 미호출 | `await context.push()` + `onChanged()` |
| 마지막 커스터마이제이션 소실 | `autoDispose` → debounce timer 취소 → flush 없음 | `flushPendingPush()` 메서드 추가, `_confirmAndPop`에서 호출 |
| 이름 변경 dialog 미표시 | `Navigator.pop` → context 무효화 → dialog 렌더 실패 | dialog 먼저, pop 나중 순서 교환 |

### 2.4 Check (Gap Analysis)

| Category | Score |
|----------|:-----:|
| Design Match | 95% |
| Architecture Compliance | 100% |
| Convention Compliance | 98% |
| **Overall** | **97%** |

**경미한 차이 (3건)**: 갤러리 타일 fontSize 11→12, border 0.5→1px, gap 4→6 — 의도적 UI 미세 조정으로 판단.

**파일 크기 경고 (1건)**: `home_screen.dart` 433줄 (제한 400줄) — `_LegalLinkTile` + drawer 추출로 해소 가능.

---

## 3. Architecture Decisions

| Decision | Value | Rationale |
|----------|-------|-----------|
| 데이터 통합 | QrTask 단일 (UserQrTemplate 삭제) | 중복 엔티티 제거, 단일 Hive box |
| 홈/히스토리 분리 | `showOnHome: bool` 플래그 | 홈 삭제 시 히스토리 유지, 최소 스키마 변경 |
| 스캐너 배치 | AppBar 아이콘 (D1 안A) | "읽기"와 "만들기" 기능 분리 |
| 썸네일 저장 | debounce 500ms 동기화 (D2 안A) | 기존 `_schedulePush`와 동일 주기 |
| 이미지 저장/공유 | thumbnailBytes 직접 사용 (D3 안A 변형) | off-screen 렌더링 불필요, 저해상도 충분 |
| 편집(숨기기) 기능 | 삭제 (D6) | pre-release, 사용 빈도 극히 낮음 |
| 미리보기 크기 | 220px + Transform.scale(1.15) | 캡처 12px padding 크롭, 메뉴 스크롤 방지 |
| debounce flush | `flushPendingPush()` 패턴 | pop 직전 보류 중인 변경 즉시 영속 |

---

## 4. File Inventory

### 4.1 New Files (6)

| File | Lines | Purpose |
|------|------:|---------|
| `lib/features/home/widgets/create_picker_sheet.dart` | 163 | 새로 만들기 bottom sheet |
| `lib/features/home/widgets/qr_task_action_sheet.dart` | 177 | 확대 미리보기 + 5개 액션 sheet |
| `lib/features/home/widgets/qr_task_gallery_card.dart` | 95 | 갤러리 타일 위젯 (삭제 모드 지원) |
| `lib/features/qr_task/presentation/widgets/rename_dialog.dart` | 37 | 이름 변경 AlertDialog |
| `lib/features/qr_task/domain/usecases/rename_qr_task_usecase.dart` | ~20 | 이름 변경 UseCase |
| `lib/features/qr_task/domain/usecases/update_qr_task_thumbnail_usecase.dart` | ~20 | 썸네일 업데이트 UseCase |

### 4.2 Key Modified Files

| File | Lines | Change |
|------|------:|--------|
| `home_screen.dart` | 433 | 전면 재작성: CTA + 갤러리 + 삭제 모드 + drawer |
| `qr_task.dart` | 112 | +name, +thumbnailBytes, +showOnHome, schema v2 |
| `qr_result_provider.dart` | — | +flushPendingPush() |
| `qr_result_screen.dart` | — | AppBar 재구성, _confirmAndPop, action_buttons 제거 |
| `qr_task_providers.dart` | — | +5 provider (rename, thumbnail, hide×3) |
| `qr_task_repository.dart` | — | +3 메서드 (update, hideFromHome, listHomeVisible, hideAllFromHome) |

### 4.3 Deleted Files (~15)

- `lib/features/output_selector/` (전체)
- `lib/features/qr_result/domain/entities/user_qr_template.dart`
- `lib/features/qr_result/data/models/user_qr_template_model.dart` + `.g.dart`
- `lib/features/qr_result/data/datasources/hive_user_template_datasource.dart`
- `lib/features/qr_result/data/datasources/user_template_local_datasource.dart`
- `lib/features/qr_result/data/repositories/user_template_repository_impl.dart`
- `lib/features/qr_result/domain/usecases/save_user_template_usecase.dart`
- `lib/features/qr_result/domain/usecases/get_user_templates_usecase.dart`
- `lib/features/qr_result/domain/usecases/delete_user_template_usecase.dart`
- `lib/features/qr_result/domain/usecases/clear_user_templates_usecase.dart`
- `lib/features/qr_result/tabs/my_templates_tab.dart`
- `lib/features/qr_result/qr_result_screen/action_buttons.dart`
- `lib/core/widgets/output_action_buttons.dart`

---

## 5. Lessons Learned

### 5.1 Technical Insights

1. **debounce + autoDispose 조합의 함정**: `StateNotifier`가 `autoDispose`로 관리될 때, 화면 이탈 시 dispose가 debounce timer를 취소하여 마지막 변경이 소실될 수 있다. `flushPendingPush()` 같은 명시적 flush 메서드를 pop 직전에 호출하는 패턴이 필수.

2. **Navigator.pop과 context 유효성**: Bottom sheet 내에서 `Navigator.pop(context)` 호출 후 동일 context로 dialog를 띄우면 실패한다. Dialog를 먼저 띄우고 결과를 받은 후 pop하는 순서가 안전하다.

3. **Transform.scale + Clip으로 캡처 여백 제거**: 썸네일 캡처 시 불가피한 padding은 표시 단계에서 `Transform.scale` + `Clip.antiAlias`로 시각적으로 크롭할 수 있다. 캡처 로직 수정 없이 UI 레벨에서 해결.

4. **await context.push + callback 패턴**: 자식 화면에서 데이터 변경 후 부모로 복귀할 때, `await context.push(...)` + 완료 후 `onChanged()` 콜백으로 부모 화면 갱신을 보장할 수 있다.

### 5.2 Process Insights

- 단일 세션 내 Plan → Design → Do → Check → Report 전 cycle 완수
- Do phase에서 실 사용 중 발견된 버그 3건을 즉시 수정하고 Design/Plan 문서에 소급 반영
- Gap Analysis 97% — 첫 시도에서 높은 일치율 달성 (iteration 불필요)

---

## 6. Follow-up Recommendations

### 즉시 (Priority)

1. **`home_screen.dart` 분할**: 433줄 → `_LegalLinkTile` + `_buildDrawer`/`_showAppInfoDialog`를 `widgets/home_drawer.dart`로 추출 (400줄 제한 준수)
2. **Design 문서 15~18번 상태 업데이트**: "미착수" → "완료"로 갱신 (analysis에서 지적됨)

### 선택 (Optional)

3. 갤러리 타일 미세 조정 (fontSize 11 vs 12, border 0.5 vs 1px) — 구현 중 의도적 조정일 수 있음
4. 액션시트의 영구 삭제 vs 홈 숨기기 구분을 Design에 명시

### 후속 티켓 (Out-of-Scope)

- `l10n-main-screen-redesign-translations`: 9개 언어 번역 추가
- `home-qr-gallery-filter`: 태그 타입별 필터/정렬 옵션
- `qr-task-favorites-ui`: 즐겨찾기 핀 고정/섹션 분리
- `qr-export-batch`: 다중 선택 후 일괄 저장/공유

---

_Match Rate 97% — PDCA cycle 완료. `/pdca archive main-screen-redesign` 실행 가능._
