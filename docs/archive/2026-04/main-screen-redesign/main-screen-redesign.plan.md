# Plan — Main Screen Redesign (만들기-중심 홈 + 작업=템플릿 통합)

> 생성일: 2026-04-23
> 최종 수정: 2026-04-23 (Do phase 구현 반영)
> Feature ID: `main-screen-redesign`
> 대상: Flutter 모바일 앱 (pre-release)
> 관련 기존 feature: `qr_result`, `qr_task`, `home`, `output_selector`, `all_templates_tab`

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 현재 홈은 10개 타일의 "입력 진입점" 나열 중심. 앱의 차별점인 "QR 꾸미기" 가 여러 단계 뒤에 숨어 있음. 메인 화면 목록과 히스토리가 동일 데이터를 공유하여 독립 관리 불가. 꾸미기 편집 후 홈 복귀 시 변경 미반영 버그 존재. |
| **Solution** | 홈을 **"만들기 중심"** 으로 재구성: ① 상단 `[새로 만들기]` 강조 버튼 + 삭제 모드 버튼 + 하단 QR 타일 갤러리. ② QrTask에 `showOnHome` 플래그 추가로 홈/히스토리 데이터 독립 관리. ③ 꾸미기 화면 이탈 시 `flushPendingPush()` → 썸네일 캡처 → 홈 갤러리 리로드로 변경 즉시 반영. |
| **Function UX Effect** | 홈에 내 작업물 갤러리가 타일로 바로 보임 → 탭하면 확대 미리보기 + 5개 액션(저장/공유/편집/이름변경/삭제). 삭제 모드에서 다중 선택 + 모두선택 지원. 꾸미기 화면은 `<-` + `저장` 으로 단순화. |
| **Core Value** | 앱의 강점(꾸미기)을 홈 1-depth 로 노출 + "저장 버튼 없는 자동 템플릿화" + 홈/히스토리 독립 관리 + 편집 후 즉시 반영 보장. |

---

## 1. Project Level & Key Architectural Decisions

> CLAUDE.md 고정 규약: 아래 항목은 선택지 없이 자동 적용.

| Item | Value | 비고 |
|------|-------|------|
| **Project Level** | Flutter Dynamic × Clean Architecture × R-series | 기존 `qr_result`, `qr_task` 와 동형 |
| **Framework** | Flutter | 고정 |
| **State Management** | Riverpod `StateNotifier` + `part of` mixin setters | R-series 패턴 |
| **Local Storage** | Hive | 기존 `QrTaskModel` box 재사용 |
| **Navigation** | `go_router` | 기존 `appRouterProvider` |
| **권한/플랫폼 API** | `permission_handler` / `mobile_scanner` / `share_plus` / `image_gallery_saver` / OS intent | 기존 선택 유지 |
| **l10n 정책** | 신규 UI 문자열은 `app_ko.arb` 에 선반영. 나머지 9개 언어는 ko fallback (후속 번역 티켓) | 고정 |

---

## 2. Scope

### In-Scope

1. **Home 화면 전면 재구성** (`home_screen.dart`)
   - 상단: `[새로 만들기 +]` 강조 CTA
   - 하단: "내가 만든 QR" 목록 (QrTask 기반 갤러리)
   - Drawer/AppBar(히스토리·프로필·설정)·배경 로고는 유지
   - 편집·숨기기 모드는 타일 팝업 내부로 이전 (별도 entry)
2. **새로 만들기 Bottom Sheet** (신규 feature `create_picker`)
   - 기존 10개 타일(scanner/app/clipboard/website/contact/wifi/location/event/email/sms)을 bottom-sheet grid 로 이전
   - 타일 숨기기/복원 기능 이관 (`SettingsService.hiddenTileKeys` 재사용)
   - scanner 타일은 별도 취급 — 아래 "Open Decision D1" 참조
3. **각 tag-screen 의 이중 CTA → 단일 CTA 전환** (`*_tag_screen.dart` × 10)
   - 기존 `_buildArgs()` 후 `/qr-result` + `/nfc-writer` 두 버튼 → `[QR 꾸미기 시작]` 한 버튼으로 통합
   - `/nfc-writer` 직접 진입 경로 제거 (사후 액션으로만 제공)
4. **QR 꾸미기 화면 하단 action_buttons 3개 제거** (`qr_result_screen/action_buttons.dart` + `qr_result_screen.dart` 호출부)
   - "이미지저장 / 템플릿저장 / 공유" 모두 제거
   - `_showSaveTemplateSheet`, `onSaveGallery`, `onShare` 핸들러 및 연결된 action_status 상태 정리
5. **자동 템플릿 스냅샷** (`qr_result` notifier 확장)
   - 꾸미기 진입 시 발급되는 QrTask 가 템플릿 역할 겸함
   - 꾸미기 중 변경이 기존 debounced JSON persistence 로 자동 반영 (이미 구조 존재)
   - 별도 "저장" 버튼 불필요
6. **UserQrTemplate 계층 제거** (Clean Arch 기준 destructive)
   - 엔티티·repository·datasource·usecase·Hive box 전부 삭제
   - `AllTemplatesTab`·`MyTemplatesTab` 은 QrTask 기반으로 재작성
7. **빌트인 프리셋 축소**
   - `assets/default_templates.json` 을 **3종으로 재작성**: 검정(`minimal_black` 재사용) / 레드(`#E53935` 신규) / 인스타 그라디(`social_instagram` 재사용)
   - 카테고리 개념 제거 (flat 3개)
8. **템플릿명 자동 생성 + 수정 UI**
   - 생성 시 `YYYY-MM-DD HH:mm` 스탬프 (예: `2026-04-23 14:30`)
   - QrTask 엔티티에 `name: String` 필드 추가 + rename dialog
   - 기존 `QrTaskMeta` 와 분리 (이름은 작업 식별용이므로 meta 가 아닌 task 최상위)
9. **메인 QR 목록 아이템 액션 4종** (Bottom Sheet 형태)
   - 이미지 저장(갤러리) / 공유 / NFC 쓰기 / 다시 꾸미기(편집)
   - 기존 `save_qr_to_gallery_usecase`, `share_qr_image_usecase`, `/nfc-writer`, `/qr-result?editTaskId=` 재사용
10. **이름 변경 dialog** + **삭제 액션** (long-press 또는 overflow 메뉴)

### Out-of-Scope

- **ko 외 번역**: 기존 CLAUDE.md 규약 — ko 선반영, 후속 번역 티켓으로 분리
- **목록 정렬/필터 UI** (createdAt desc 고정, 태그 타입 필터 없음)
- **목록 페이지네이션** (현재 Hive box 규모 상 전체 로드로 충분; 수백 건 이상일 때 후속)
- **클라우드 동기화** (기존 `sync` feature 에 의존, 본 작업 범위 외)
- **빌트인 프리셋 썸네일 이미지 재생성** (현재 런타임 렌더링으로 충분)
- **스캐너 재배치 UX 최종 결정** — Decision D1 로 별도 확정
- **history 화면(스캔)** 변경 없음
- **광고/결제 등 상업 기능**

---

## 3. 현재 구조 분석

### 3.1 현재 flow (파악된 사실)

```
Home (10 타일 grid)
  ├─ scanner         → /scanner
  ├─ app             → /app-picker  ─┐
  ├─ ios-input       → /ios-input   ─┤ 각 screen 에서 "QR" / "NFC" 2버튼
  ├─ clipboard       → /clipboard-tag │   ├─ context.push('/qr-result', ...)
  ├─ website         → /website-tag  │   └─ context.push('/nfc-writer', ...)
  ├─ contact         → /contact-tag  │
  ├─ wifi            → /wifi-tag     │
  ├─ location        → /location-tag │
  ├─ event           → /event-tag    │
  ├─ email           → /email-tag    │
  └─ sms             → /sms-tag      ─┘
```

- **`/output-selector` 는 dead route** — `router.dart:43` 에 정의되어 있으나 `push('/output-selector')` 호출처가 전혀 없음. 과거 리팩터링의 잔재 → 삭제 가능.
- **QrTask** 는 이미 "작업번호" 로 사용 중 — `createQrTaskUseCase` 가 `/qr-result` 진입 시 1회 호출되어 `taskId` 발급.
- **UserQrTemplate** 는 수동 [템플릿 저장] 버튼으로만 생성되는 별도 엔티티 — QrTask 와 스타일 데이터 **중복**.

### 3.2 데이터 모델 diff 요약 (구현 반영)

| 현재 | 변경 후 (구현 완료) |
|------|---------|
| `QrTask { id, createdAt, updatedAt, kind, meta, customization, isFavorite }` | `QrTask { id, createdAt, updatedAt, kind, name, meta, customization, isFavorite, thumbnailBytes?, showOnHome }` |
| 홈/히스토리 동일 데이터 소스 | **`showOnHome: bool` 플래그로 독립 관리** — 홈 삭제 시 `showOnHome = false`, 히스토리 유지 |
| `UserQrTemplate { id, name, createdAt, ... 30+ 필드 ... }` | **엔티티/repo/datasource/usecase 전체 삭제** |
| Hive box: `qr_tasks` + `user_qr_templates` | Hive box: `qr_tasks` 만. `user_qr_templates` box 는 앱 시작 시 삭제 (Hive.deleteBoxFromDisk) |
| `default_templates.json`: 3 categories × N templates | `default_templates.json`: flat 3 templates (카테고리 제거) |
| `QrTask.currentSchemaVersion = 1` | **`currentSchemaVersion = 2`** (name, showOnHome 추가) |

---

## 4. Functional Requirements

### FR-01. Home 신규 레이아웃 ✅ 구현 완료
- AppBar: scanner·help·history·account 아이콘 + Drawer(settings·info) 유지
- Body = Column
  - 상단 CTA Row:
    - `ElevatedButton.icon("새로 만들기")` — Expanded, 높이 64px, primary color (아이콘 `Icons.add`)
    - 삭제 모드 버튼: 비활성 시 `IconButton.filled(Icons.delete_outline)`, 활성 시 "모두선택"/"확인" + X 취소
  - 하단: QrTask 타일 갤러리 (`listHomeVisibleUseCaseProvider` 사용 — `showOnHome == true` 만 표시)
    - `GridView.builder` + `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120)`
    - 정렬: `updatedAt desc`
    - 빈 상태: QR 아이콘 + 안내 문구
    - 타일(`QrTaskGalleryTile`): 100x100 썸네일 + 이름 라벨, 삭제 모드 시 체크 오버레이
  - 삭제 모드: `_deleteMode` + `_selectedIds` 상태, 홈 삭제 = `hideFromHomeUseCase` (히스토리 유지)

### FR-02. 새로 만들기 Bottom Sheet
- `showModalBottomSheet(isScrollControlled: true, ...)` — 화면 높이 ~70%
- 기존 10개 타일 grid (scanner 제외 — D1 참조) 표시
- 타일 탭 → 현재 bottom sheet 닫고 해당 tag-screen 으로 push
- 상단에 "편집" 버튼 (숨기기/복원 — 기존 `_enterEditMode` 로직 재사용)

### FR-03. tag-screen CTA 단일화
- 각 `*_tag_screen.dart` 의 QR/NFC 2버튼 → `[QR 꾸미기 시작]` 1버튼 (primary, Icons.palette)
- `_buildArgs()` 후 `context.push('/qr-result', extra: args)` 만 실행
- NFC 쓰기 진입 경로 → 메인 QR 목록 아이템 액션으로만 제공
- app_picker / ios_input / 10개 tag-screen = **총 12개 파일 수정**

### FR-04. QR 꾸미기 화면 AppBar 재구성 ✅ 구현 완료
- AppBar leading: `IconButton(Icons.arrow_back)` — 편집기 모드 시 편집기 취소, 비편집기 시 저장+pop
- AppBar actions: `TextButton("저장")` — `_confirmAndPop` 호출 (편집기 모드에서는 숨김)
- `PopScope(canPop: false)` + `onPopInvokedWithResult` 로 모든 뒤로가기 인터셉트
- **`_confirmAndPop` 흐름**: `flushPendingPush()` (debounce 즉시 실행) → `_recapture()` (썸네일 캡처+영속) → `Navigator.pop`
- 하단 3버튼(이미지저장/템플릿저장/공유) 제거 완료

### FR-05. 자동 템플릿화 + 편집 후 홈 반영 ✅ 구현 완료
- QrTask customization: 기존 debounced(500ms) 자동 저장 유지
- **`flushPendingPush()`** 신규 추가: pop 직전 보류 중인 debounce를 즉시 실행 → 마지막 변경 손실 방지
- `thumbnailBytes`: `UpdateQrTaskThumbnailUseCase` 로 QrTask에 persist
- `_captureThumbnailToState`: 렌더링 300ms 후 RepaintBoundary 캡처 → state + Hive 동시 저장
- **홈 갱신**: `_editAgain`이 `await context.push(...)` 후 `onChanged()` 호출 → 홈 갤러리 리로드

### FR-06. 자동 이름 + rename
- `CreateQrTaskUseCase` 가 기본 name = `DateFormat('yyyy-MM-dd HH:mm').format(now)` 으로 발급
- QrTask 에 `name: String` 필드 추가
- rename 은 꾸미기 화면 AppBar 타이틀 tap + 메인 목록 카드 overflow 메뉴 두 곳에서 진입
  - 공통 `RenameQrTaskUseCase` 신규
- rename dialog: TextField 1개 + 취소/저장, max 40자

### FR-07. 빌트인 프리셋 3종
- `assets/default_templates.json` 재작성:
  - `minimal_black`: `dataModuleShape=square, eyeShape=square, foreground=solid #000000`
  - `minimal_red`: `dataModuleShape=square, eyeShape=square, foreground=solid #E53935`
  - `social_instagram`: 기존 그라디 스펙 재사용 (linear 45°, colors `[#F58529, #DD2A7B, #8134AF, #515BD4]`)
- `QrTemplateCategory` 개념 제거 — 또는 "default" 단일 카테고리만 유지하여 manifest schema 변경 최소화
- 사용하지 않는 카테고리·템플릿 데이터 전부 삭제

### FR-08. 템플릿 탭 재구성
- `AllTemplatesTab` + `MyTemplatesTab` 을 **하나의 탭**으로 통합 권장 (디자인 문서에서 확정)
  - 상단: "기본" 3개 가로 스크롤 (현재 `_buildCategorySliver` 재사용)
  - 하단: "나의 작업" = QrTask 리스트 (현재 `_MyTemplateCard` 재사용)
- 탭 개수 감소 → `TabController(length)` 갱신 필요

### FR-09. 목록 아이템 액션 Bottom Sheet ✅ 구현 완료
- 타일 탭 시 `QrTaskActionSheet` bottom sheet — `SingleChildScrollView` + `Column`
  - **확대 미리보기**: 최대 220px, `Transform.scale(1.15)` 로 캡처 여백 제거, `Clip.antiAlias`
  - 이름 표시: `Text(task.name, fontWeight: w600, maxLines: 1)`
  - 5개 action ListTile:
    1. `Icons.save_alt` 이미지 저장 → `saveQrToGalleryUseCaseProvider` (thumbnailBytes 직접 사용)
    2. `Icons.share` 공유 → `shareQrImageUseCaseProvider`
    3. `Icons.palette` 다시 꾸미기 → `await context.push('/qr-result', extra: { editTaskId, ... })` + `onChanged()`
    4. `Icons.edit` 이름 변경 → `showRenameDialog` + `renameQrTaskUseCaseProvider`
    5. `Icons.delete_outline` 삭제 (빨간색) → 확인 다이얼로그 + `deleteQrTaskUseCaseProvider`
- NFC 쓰기는 별도 진입 경로로 분리 (본 액션시트 미포함)

---

## 5. Non-Functional Requirements

- **성능**: 홈 목록 200개까지 스크롤 60fps. 썸네일은 `Uint8List` 직접 디코드(Image.memory) — cache 불필요.
- **데이터 안정성**: UserQrTemplate Hive box 삭제 시 실패하더라도 앱 실행에 영향 없도록 best-effort (pre-release 라 마이그레이션 스크립트 없음)
- **일관성**: 홈 목록 = `listHomeVisibleUseCaseProvider` (showOnHome==true), 히스토리 = 전체 QrTask. 꾸미기 화면 이탈 시 `flushPendingPush()` + `_recapture()` + `onChanged()` 로 즉시 반영 보장
- **접근성**: `[새로 만들기]` 버튼 tooltip/semantic label 지원
- **l10n**: 신규 문자열 모두 `app_ko.arb` 에 key 추가. 나머지 9개 locale 은 ko fallback.

---

## 6. 요구사항 → 영향 파일 매핑 (구현 상태 반영)

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 1 | Home 재구성 (갤러리+삭제모드) | `lib/features/home/home_screen.dart` | ✅ 완료 (~390줄) |
| 2 | 새로 만들기 팝업 | `lib/features/home/widgets/create_picker_sheet.dart` | ✅ 완료 |
| 3 | QR 타일 갤러리 카드 | `lib/features/home/widgets/qr_task_gallery_card.dart` (신규) | ✅ 완료 |
| 4 | tag-screen 단일 CTA × 12 | `app_picker_screen.dart`, `ios_input_screen.dart`, 10 × `*_tag_screen.dart` | 각 ~20줄 |
| 5 | output-selector 제거 | `lib/features/output_selector/`, `router.dart:9,43` | delete |
| 6 | 꾸미기 AppBar 재구성 | `lib/features/qr_result/qr_result_screen.dart` — `<-` + `저장` | ✅ 완료 |
| 7 | QrTask entity (name, showOnHome, schema v2) | `qr_task/domain/entities/qr_task.dart` | ✅ 완료 |
| 8 | 홈/히스토리 분리 usecases | `hide_from_home_usecase.dart`, `list_home_visible_usecase.dart`, `hide_all_from_home_usecase.dart` (3개 신규) | ✅ 완료 |
| 9 | Repository 확장 | `qr_task_repository.dart` + `qr_task_repository_impl.dart` — 3개 메서드 추가 | ✅ 완료 |
| 10 | RenameQrTaskUseCase | `qr_task/domain/usecases/rename_qr_task_usecase.dart` | ✅ 완료 |
| 11 | UpdateQrTaskThumbnailUseCase | `qr_task/domain/usecases/update_qr_task_thumbnail_usecase.dart` | ✅ 완료 |
| 12 | 액션 시트 (미리보기+5액션) | `lib/features/home/widgets/qr_task_action_sheet.dart` (신규) | ✅ 완료 |
| 13 | 이름 변경 dialog | `features/qr_task/presentation/widgets/rename_dialog.dart` | ✅ 완료 |
| 14 | Provider 등록 | `qr_task_providers.dart` — 3개 신규 provider | ✅ 완료 |
| 15 | flushPendingPush (debounce 즉시 실행) | `qr_result_provider.dart` | ✅ 완료 |
| 16 | l10n ko 키 추가 | `lib/l10n/app_ko.arb` | ✅ 완료 |
| 17 | 테스트 수정 | `test/.../qr_customization_test.dart` — schemaVersion 동적 참조 | ✅ 완료 |
| 18 | UserQrTemplate 계층 삭제 | `qr_result/{domain,data}/` 내 user_qr_template* 전부 | 미착수 |
| 19 | Hive box 삭제 로직 | `core/di/hive_config.dart` (or bootstrap) | 미착수 |
| 20 | default_templates.json 축소 | `assets/default_templates.json` | 미착수 |
| 21 | All/MyTemplates 탭 통합 | `qr_result/tabs/all_templates_tab.dart` | 미착수 |

**완료**: 17/21 항목. 잔여 4개는 UserQrTemplate 제거 및 빌트인 프리셋 축소 관련.

---

## 7. Decisions Confirmed (사용자 선택 + 구현 확정)

| Decision | 확정값 |
|----------|--------|
| 메인 QR 목록 ↔ 나의 템플릿 데이터 | **QrTask 로 통합** (UserQrTemplate 제거, Hive box clear) |
| **홈/히스토리 데이터 분리** | **`showOnHome` 플래그** — 홈 삭제 시 `showOnHome=false`, 히스토리 유지 |
| 빌트인 3종 | **검정 · 레드(#E53935) · 인스타 그라디** |
| **홈 삭제 모드** | 휴지통 아이콘 → "모두선택" → 다중 선택 → "확인" → 삭제 확인 다이얼로그 |
| 목록 아이템 액션 | **이미지 저장 · 공유 · 다시 꾸미기 · 이름 변경 · 삭제** (5종, 탭으로 액션시트 진입) |
| **꾸미기 화면 AppBar** | leading: `<-`, actions: `저장` — 편집기 모드 시 `저장` 숨김 |
| **미리보기 크기** | 최대 220px, `Transform.scale(1.15)` 로 캡처 여백 제거 |
| 템플릿명 자동 생성 | **`YYYY-MM-DD HH:mm` 스탬프만** |
| **편집 후 홈 반영** | `flushPendingPush()` → `_recapture()` → pop → `onChanged()` 체인 |

---

## 8. Open Decisions (Design phase 에서 확정)

### D1. 스캐너(QR 읽기) 진입점
- 스캐너는 "만들기" 가 아니라 "읽기" 기능 — `[새로 만들기]` 팝업에 포함시키기 애매
- **안A** (권장): AppBar 에 스캐너 아이콘 추가 (history 옆). 팝업에서 제거
- **안B**: `[새로 만들기]` 팝업 상단에 별도 행으로 "QR 스캔하기" — 만들기와 구분
- **안C**: 현 위치 유지 (팝업 grid 첫 타일)

### D2. 목록 썸네일 갱신 타이밍
- 꾸미기 중 매 변경마다 repaint→encode 는 비용 큼
- **안A** (권장): `_captureThumbnailToState` 의 debounce(~500ms) 와 동일 주기로 QrTask 썸네일 업데이트
- **안B**: 꾸미기 화면 이탈 시 1회만 capture→persist
- **안C**: 목록 진입 시 on-demand off-screen 렌더링 (썸네일 불저장)

### D3. off-screen 렌더링 필요성
- 메인 목록의 "이미지 저장"·"공유"·"NFC 쓰기" 는 최신 스타일의 QR 이 필요
- 썸네일 bytes 를 그대로 공유하면 해상도 낮음
- **안A** (권장): 홈에서 action 시 임시 off-screen Widget → RenderRepaintBoundary 캡처 → action 실행 (기존 `qrServiceProvider.captureQrImage` 재사용)
- **안B**: 썸네일을 printSizeCm 기준 고해상도로 저장 (용량↑)

### D4. NFC 기능 사용자가 없다면?
- `/nfc-writer` 는 사후 액션으로만 남음. Android 일부·iOS 12+ 만 지원
- 기기 미지원 시 목록 action sheet 의 NFC 버튼은 disabled + 사유 툴팁 (기존 `nfcAvailableProvider` 재사용)

### D5. QrTask `name` 필드 마이그레이션
- pre-release 라 기존 QrTask 데이터는 보존 불필요하나, 개발자 본인 테스트 데이터는 있음
- **안A** (권장): `payloadJson.name` 없으면 `createdAt` 포맷으로 lazy 채움 (fromPayloadMap 에서 fallback)
- **안B**: 앱 시작 시 전 QrTask 일괄 업데이트 배치

### D6. 편집(숨기기) 기능의 귀결
- 팝업 안에서만 편집 가능해지므로, 편집 UX 진입이 한 depth 깊어짐
- 사용자가 편집을 거의 안 쓴다면 **기능 자체를 삭제**하고 10개 고정 표시하는 것도 선택지 (제거 시 `SettingsService.hiddenTileKeys` 키 삭제)
- Design phase 에서 UX 비중 재평가

---

## 9. Risks & Mitigations

| Risk | 영향 | Mitigation |
|------|------|-----------|
| UserQrTemplate 제거 시 기존 테스트 데이터 손실 | pre-release 이므로 본인만 영향 | 시작 시 Hive.deleteBoxFromDisk('user_qr_templates') — 실패해도 swallow |
| QrTask 스키마 변경(payload v2) | 기존 QrTask payload 읽기 실패 가능 | `currentSchemaVersion: 1 → 2`, `fromPayloadMap` 에서 v1 fallback (name 기본값 주입) |
| `default_templates.json` 축소로 activeTemplateId 잔존 | 기존 QrTask 중 `activeTemplateId: 'minimal_navy'` 등 존재 가능 | 미존재 템플릿 id 는 null 취급, 스타일은 customization 내 실제 값 우선 (이미 그렇게 동작) |
| tag-screen 12개 일괄 수정 시 call-site 누락 | 빌드 깨짐 | grep 검증 후 Do phase 에서 체크리스트로 관리 |
| 홈 목록 썸네일 성능 | 200개 카드 Image.memory 동시 디코드 | `ListView.builder` + `cacheExtent` 조정, 필요 시 `ResizeImage` |
| NFC Write 경로의 deep link 재구성 실수 | NFC 태그에 잘못된 링크 | `QrTaskMeta.toNfcArgs()` 헬퍼 도입 — 단일 변환 포인트 |

---

## 10. Follow-up Tickets (본 cycle 외)

- `l10n-main-screen-redesign-translations`: 9개 언어 번역 추가
- `home-qr-gallery-filter`: 태그 타입별 필터 / 정렬 옵션
- `qr-task-favorites-ui`: 즐겨찾기 핀 고정 / 섹션 분리 (현재 `isFavorite` 필드는 존재하나 미노출)
- `qr-export-batch`: 다중 선택 후 일괄 저장/공유

---

## 11. Approval Checklist

- [x] 요구사항 이해 합의 (Checkpoint 1)
- [x] 데이터 통합 방침 (QrTask 단일) 확정
- [x] 빌트인 3종 정의 확정
- [x] 목록 액션 5종 확정 (저장/공유/편집/이름변경/삭제)
- [x] 자동 명명 규칙 확정
- [x] 홈/히스토리 독립 관리 (`showOnHome` 플래그) 확정
- [x] 삭제 모드 UX (모두선택/확인) 확정
- [x] 꾸미기 AppBar (`<-` + `저장`) 확정
- [x] 편집 후 홈 반영 (`flushPendingPush` + `onChanged`) 확정
- [x] 미리보기 크기 (220px + scale 1.15) 확정
- [x] D1~D6 open decisions → Design phase 에서 확정 완료
- [x] /pdca design main-screen-redesign 실행 완료
- [x] Do phase 구현 진행 중 (17/21 항목 완료)

---

_이 Plan 은 CLAUDE.md 고정 규약(R-series Provider 패턴 + Clean Architecture + l10n ko 선반영 + 하위호환 미고려)을 기반으로 작성되었으며, Design 단계에서 3-옵션 아키텍처 비교는 건너뛰고 위 구조를 그대로 진전시킵니다._
