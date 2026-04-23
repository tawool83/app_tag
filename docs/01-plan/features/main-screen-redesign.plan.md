# Plan — Main Screen Redesign (만들기-중심 홈 + 작업=템플릿 통합)

> 생성일: 2026-04-23
> Feature ID: `main-screen-redesign`
> 대상: Flutter 모바일 앱 (pre-release)
> 관련 기존 feature: `qr_result`, `qr_task`, `home`, `output_selector`, `all_templates_tab`

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 현재 홈은 10개 타일의 "입력 진입점" 나열 중심. 앱의 차별점인 "QR 꾸미기" 가 여러 단계(타일→입력→output-selector→꾸미기) 뒤에 숨어 있음. 템플릿 저장/이미지저장/공유가 꾸미기 화면에 섞여 UX 혼선 유발. |
| **Solution** | 홈을 **"만들기 중심"** 으로 재구성: ① 상단 `[새로 만들기 +]` 강조 버튼 + 하단 "내가 만든 QR" 목록. ② 타일 메뉴를 bottom-sheet 팝업으로 이전 후 입력 완료 시 `[QR 꾸미기 시작]` 하나로 바로 꾸미기 진입(output-selector 제거). ③ **QrTask = UserQrTemplate** 통합으로 "작업 = 템플릿" 의도 실현 — 꾸미는 중 변경이 실시간 스냅샷으로 저장. |
| **Function UX Effect** | 홈에 내 작업물 갤러리가 바로 보임 → 재사용/재편집 빈도↑. 꾸미기 화면 하단 3버튼 제거로 작업 집중도↑. 이미지저장/공유/NFC쓰기는 "완성된 QR 목록 아이템 액션" 으로 이동 — 만들기-결과 맥락 분리. |
| **Core Value** | 앱의 강점(꾸미기)을 홈 1-depth 로 노출 + "저장 버튼 없는 자동 템플릿화" 로 이탈 부담 제거 + 작업물 갤러리 UX 정착. |

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

### 3.2 데이터 모델 diff 요약

| 현재 | 변경 후 |
|------|---------|
| `QrTask { id, createdAt, updatedAt, kind, meta, customization, isFavorite }` | `QrTask { id, createdAt, updatedAt, kind, name, meta, customization, isFavorite, thumbnailBytes? }` |
| `UserQrTemplate { id, name, createdAt, ... 30+ 필드 ... }` | **엔티티/repo/datasource/usecase 전체 삭제** |
| Hive box: `qr_tasks` + `user_qr_templates` | Hive box: `qr_tasks` 만. `user_qr_templates` box 는 앱 시작 시 삭제 (Hive.deleteBoxFromDisk) |
| `default_templates.json`: 3 categories × N templates | `default_templates.json`: flat 3 templates (카테고리 제거) |

---

## 4. Functional Requirements

### FR-01. Home 신규 레이아웃
- AppBar (help·history·account) 및 Drawer(settings·info) 유지
- Body = Column
  - 상단: `ElevatedButton.icon(Icons.add, "새로 만들기")` — full-width, 높이 ≥ 64px, primary color
  - 하단: QrTask 리스트 (`listQrTasksUseCase` + `qrTaskListNotifierProvider` 재사용)
    - 정렬: `updatedAt desc`
    - 빈 상태: 일러스트 + "첫 QR 을 만들어 보세요" 문구
    - 카드: 썸네일 + 이름(`YYYY-MM-DD HH:mm`) + 태그 타입 라벨
- 편집 모드(타일 숨기기)는 팝업 내부로 이전

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

### FR-04. QR 꾸미기 하단 버튼 제거
- `_ActionButtons` 위젯 제거
- `qr_result_screen.dart` 에서 `onSaveGallery` / `onSaveTemplate` / `onShare` 핸들러 및 관련 state (`action.saveStatus`, `action.shareStatus`) 제거
- `QrActionState` 의 save/share 관련 필드 정리 (readability alert 는 유지)
- 뒤로가기 시 기존 persistence 가 이미 작동하므로 "나가면 저장됨" UX 유지

### FR-05. 자동 템플릿화
- 별도 로직 추가 불요 — 현재 이미 QrTask 의 customization 이 debounced 자동 저장 중
- 단, **thumbnailBytes** 를 QrTask 에 직접 보관 필요 (홈 목록 썸네일 표시용)
  - `QrTask` 에 `thumbnailBytes: Uint8List?` 필드 추가
  - `qr_result_screen` 의 `_captureThumbnailToState` 훅에서 QrTask 로 persist
  - 또는 별도 `UpdateQrTaskThumbnailUseCase` 추가 (권장)

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

### FR-09. 목록 아이템 액션 Bottom Sheet
- 탭 시 bottom sheet 오픈 — 4개 action ListTile
  1. `Icons.save_alt` 이미지 저장 → `SaveQrToGalleryUseCase` (주의: QR 위젯을 목록 맥락에서 렌더링·캡처 필요 → 기존 `qrServiceProvider.captureQrImage` 를 **off-screen 렌더링** 으로 호출, 디자인 문서에서 상세)
  2. `Icons.share` 공유 → `ShareQrImageUseCase`
  3. `Icons.nfc` NFC 쓰기 → `context.push('/nfc-writer', extra: { ...task.meta.toArgs(), editTaskId })` — deep link 재구성
  4. `Icons.palette` 다시 꾸미기 → `context.push('/qr-result', extra: { editTaskId })`
- long-press 또는 overflow `⋮` → 삭제 / 이름 변경 / 즐겨찾기 토글

---

## 5. Non-Functional Requirements

- **성능**: 홈 목록 200개까지 스크롤 60fps. 썸네일은 `Uint8List` 직접 디코드(Image.memory) — cache 불필요.
- **데이터 안정성**: UserQrTemplate Hive box 삭제 시 실패하더라도 앱 실행에 영향 없도록 best-effort (pre-release 라 마이그레이션 스크립트 없음)
- **일관성**: 홈 목록과 꾸미기 탭 하단 "나의 작업" 은 같은 `qrTaskListNotifierProvider` 를 구독 → 변경 즉시 양쪽 반영
- **접근성**: `[새로 만들기]` 버튼 tooltip/semantic label 지원
- **l10n**: 신규 문자열 모두 `app_ko.arb` 에 key 추가. 나머지 9개 locale 은 ko fallback.

---

## 6. 요구사항 → 영향 파일 매핑

| # | 작업 | 파일 | 추정 변경 |
|---|------|------|-----------|
| 1 | Home 재구성 | `lib/features/home/home_screen.dart` | rewrite (~150줄) |
| 2 | 새로 만들기 팝업 | `lib/features/home/widgets/create_picker_sheet.dart` (신규) | +200줄 |
| 3 | 타일 편집 기능 이전 | `lib/features/home/home_screen.dart` → sheet 내부 | move |
| 4 | tag-screen 단일 CTA × 12 | `app_picker_screen.dart`, `ios_input_screen.dart`, 10 × `*_tag_screen.dart` | 각 ~20줄 |
| 5 | output-selector 제거 | `lib/features/output_selector/`, `router.dart:9,43` | delete |
| 6 | 꾸미기 하단 버튼 제거 | `lib/features/qr_result/qr_result_screen/action_buttons.dart`, `qr_result_screen.dart` | -150줄 |
| 7 | QrAction 상태 정리 | `domain/state/qr_action_state.dart`, `notifier/action_setters.dart` | -50줄 (readability 유지) |
| 8 | QrTask entity + name + thumbnailBytes | `qr_task/domain/entities/qr_task.dart`, `data/models/qr_task_model.dart` + `.g.dart` regen | +40줄 |
| 9 | RenameQrTaskUseCase 신규 | `qr_task/domain/usecases/rename_qr_task_usecase.dart` | +30줄 |
| 10 | UpdateQrTaskThumbnail usecase | `qr_task/domain/usecases/update_qr_task_thumbnail_usecase.dart` | +30줄 |
| 11 | UserQrTemplate 계층 삭제 | `qr_result/{domain,data}/` 내 user_qr_template* 전부 | -800줄 |
| 12 | Hive box 삭제 로직 | `core/di/hive_config.dart` (or bootstrap) | +15줄 |
| 13 | default_templates.json 축소 | `assets/default_templates.json` | rewrite (~50줄) |
| 14 | All/MyTemplates 탭 통합 | `qr_result/tabs/all_templates_tab.dart`, `my_templates_tab.dart` 또는 신규 `templates_tab.dart` | rewrite ~250줄 |
| 15 | 탭 인덱스/컨트롤러 업데이트 | `qr_result_screen.dart` TabBar 정의부 | ~20줄 |
| 16 | 목록 액션 sheet | `features/home/widgets/qr_task_action_sheet.dart` (신규) | +150줄 |
| 17 | 이름 변경 dialog | `features/qr_task/presentation/widgets/rename_dialog.dart` (신규) | +80줄 |
| 18 | l10n ko 키 추가 | `lib/l10n/app_ko.arb` | +20 keys |
| 19 | l10n regen | `lib/l10n/app_localizations*.dart` (flutter gen-l10n) | auto |
| 20 | 신규 UseCase provider 등록 | `qr_task_providers.dart` | +10줄 |

**합계**: 신규 ~800줄, 삭제 ~1100줄 → **net -300줄**. 구조 단순화 효과.

---

## 7. Decisions Confirmed (사용자 선택)

| Decision | 확정값 |
|----------|--------|
| 메인 QR 목록 ↔ 나의 템플릿 데이터 | **QrTask 로 통합** (UserQrTemplate 제거, Hive box clear) |
| 빌트인 3종 | **검정 · 레드(#E53935) · 인스타 그라디** |
| 목록 아이템 액션 | **이미지 저장 · 공유 · NFC 쓰기 · 다시 꾸미기** (4종, 삭제/이름변경은 long-press / overflow) |
| 템플릿명 자동 생성 | **`YYYY-MM-DD HH:mm` 스탬프만** |

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

## 11. Approval Checklist (Design phase 시작 조건)

- [x] 요구사항 이해 합의 (Checkpoint 1)
- [x] 데이터 통합 방침 (QrTask 단일) 확정
- [x] 빌트인 3종 정의 확정
- [x] 목록 액션 4종 확정
- [x] 자동 명명 규칙 확정
- [ ] D1~D6 open decisions → Design phase 에서 확정
- [ ] /pdca design main-screen-redesign 실행

---

_이 Plan 은 CLAUDE.md 고정 규약(R-series Provider 패턴 + Clean Architecture + l10n ko 선반영 + 하위호환 미고려)을 기반으로 작성되었으며, Design 단계에서 3-옵션 아키텍처 비교는 건너뛰고 위 구조를 그대로 진전시킵니다._
