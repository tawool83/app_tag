# qr-scanner-ui-ux Planning Document

> **Summary**: QR 스캐너 기능 신규 도입 + 스캔 결과 Bottom Sheet + History 화면을 [생성이력/스캔이력] 2-탭 구조로 확장 (검색·필터·즐겨찾기·스와이프 삭제 포함).
>
> **Project**: app_tag (Flutter 1.0.0+1)
> **Source**: [Notion 기획안 — QR 코드 스캐너 UI/UX 기획안](https://www.notion.so/tawool/QR-UI-UX-3497ef6352298083b2a3f3135de11d2d)
> **Author**: tawool83
> **Date**: 2026-04-21
> **Status**: Draft

---

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 현재 앱은 QR "생성" 전용이며 스캔 기능이 없어 "스마트폰 앱을 물리적 공간에 연결" 이라는 제품 비전의 역방향(공간→앱) 연결고리가 끊겨 있고, History 화면이 생성이력 단일 리스트라 검색·필터·즐겨찾기 같은 기본 관리 기능이 부재함. |
| **Solution** | `mobile_scanner` 기반 풀스크린 스캐너 + 결과 Bottom Sheet(9종 타입 자동 분류 → 기존 태그 화면으로 값 주입 재사용) + History 2-탭(ScanHistory 별도 Hive 박스) + 공통 관리 위젯(검색바/필터칩/⭐/스와이프). 기존 R-series `composite State + mixin setters via part of` 패턴 준수. |
| **Function/UX Effect** | 홈 그리드 첫 타일로 즉시 스캐너 진입(카메라 프리뷰, 햅틱 피드백, 갤러리 QR 디코드). 스캔 → 태그 화면 재사용 → 기존 꾸미기 플로우로 자연 연결. History는 2탭 전환 + 공통 검색/필터 UX로 관리 일관성 확보. |
| **Core Value** | "빠른 스캔 → 스마트한 기록 관리 → 바로 내 것으로 꾸미기" 의 단일 루프 완성. 스캔 데이터가 기존 9종 태그 파이프라인으로 흘러들어가 기존 qr_result 꾸미기 자산(dot/logo/color/boundary/animation)을 재활용함. |

---

## 1. Overview

### 1.1 Purpose

앱의 핵심 가치("스마트폰 앱을 물리적 공간에 연결") 를 **양방향**으로 확장한다.
- 기존: 사용자 → 앱 생성 → 공간에 QR/NFC 부착
- 신규: 공간의 QR → 스캔 → 기존 태그 작성 플로우 → **내 꾸미기 버전으로 재발행**

### 1.2 Background

- **Notion 기획안** 에서 3가지 축으로 정의됨:
  1. 스캐너 화면 (Full-screen Viewport + Scanning Reticle + Flash/Gallery Control Bar)
  2. 스캔 결과 Bottom Sheet (Data Type Tag + Preview + Primary Actions + "꾸미기" 진입)
  3. History 2-탭 확장 (생성이력 / 스캔이력) + 검색/필터/⭐/스와이프 삭제
- **현 코드 상태**:
  - `mobile_scanner` 미도입, `permission_handler` 미도입 → 신규 의존성 필요
  - `lib/features/history/presentation/screens/history_screen.dart` 는 `qrTaskListNotifierProvider` 단일 리스트만 표시
  - `QrTask` 엔티티에 `favorite` 개념 없음 (스키마 확장 필요)
  - 기존 태그 화면 9종(`clipboard_tag`, `website_tag`, `wifi_tag`, `contact_tag`, `sms_tag`, `email_tag`, `location_tag`, `event_tag`, `app_picker`) 이 모두 존재 → 스캔 결과의 "꾸미기" 흐름에서 재사용 가능

### 1.3 Related Documents

- 원본 기획: [Notion — QR 코드 스캐너 UI/UX 기획안](https://www.notion.so/tawool/QR-UI-UX-3497ef6352298083b2a3f3135de11d2d)
- 아키텍처 패턴: `~/.claude/projects/C--repository-app-tag/memory/feedback_provider_pattern.md` (R-series 검증)
- 의사결정 기준: `~/.claude/projects/C--repository-app-tag/memory/feedback_code_decision_criteria.md` (Claude 가독성 최적화)
- 참조 구현: `lib/features/qr_result/qr_result_provider.dart` (R-series 최종형)

---

## 2. Scope

### 2.1 In Scope

- [ ] **Home 타일 추가** — `scanner` 키의 QR 스캐너 타일을 그리드 **첫 번째 위치** 에 삽입 (9→10개, 2x5)
- [ ] **스캐너 화면** (`/scanner` 라우트)
  - Full-screen 카메라 프리뷰
  - 중앙 사각형 Scanning Reticle (인식 시 애니메이션 피드백)
  - Floating Control Bar: 플래시 토글 + 갤러리 이미지 QR 인식
  - 진입 즉시 카메라 구동 (딜레이 최소화)
  - 인식 성공 시 햅틱(진동) 피드백
- [ ] **카메라 권한 처리** — `permission_handler` 도입, 거부 시 "설정으로 이동" 안내 갈러리 임포트만 허용하는 폴백 UI
- [ ] **스캔 결과 Bottom Sheet**
  - Data Type 자동 분류 (9종): URL / WiFi / Contact(vCard/MECARD) / SMS(SMSTO) / Email(mailto/MATMSG) / Location(geo) / Event(VEVENT) / 앱 딥링크(app_tag 자체 schema) / Text (fallback)
  - Primary Actions 타입별:
    - `URL`: 브라우저 열기 + 링크 복사
    - `WiFi`: 네트워크 자동 연결 (+ SSID/비밀번호 복사)
    - `Text`: 전체 복사 + 공유
    - `Contact/SMS/Email/Location/Event`: 시스템 앱 호출 (OS intent/universal link)
    - `공통`: **"꾸미기"** 버튼 — 유형에 맞는 기존 태그 화면으로 값 주입 후 이동 → 사용자 확인 후 `/qr-result` 도달
  - 아래로 스와이프 시 즉시 스캐너 복귀
- [ ] **ScanHistory 도메인 신설** (R-series 패턴)
  - `lib/features/scan_history/` 신규 모듈
  - 별도 Hive 박스 `scan_history_box` (기존 `qr_task_box` 와 완전 분리)
  - 엔티티: `ScanHistory` (id, scannedAt, rawValue, detectedType, parsedMeta, isFavorite)
- [ ] **History 2-탭 확장**
  - 기존 `history_screen.dart` 를 `TabBar` 2탭(`[생성이력]` / `[스캔이력]`)으로 개편
  - `qr_task` 엔티티에 `isFavorite` 필드 추가 (Hive 스키마 마이그레이션 포함)
  - **공통 관리 UX** 양쪽 탭에 동일 적용:
    - Search Bar (내용/제목/appName 풀텍스트 검색)
    - Filter Chips (전체 / 타입별)
    - 좌측 타입 아이콘 + 중앙 내용·일시 + 우측 ⭐ 토글
    - 왼쪽 스와이프 → 삭제 버튼 노출 (`Dismissible`)
- [ ] **의존성 추가** — `mobile_scanner`, `permission_handler`
- [ ] **Android/iOS 권한 선언** — `AndroidManifest.xml`, `Info.plist` 의 `NSCameraUsageDescription` 등
- [ ] **l10n — ko 선반영** — `app_ko.arb` 에 신규 문자열 추가. `en/fr/de/es/ja/pt/th/vi/zh` 는 ko fallback 유지(티켓 백로그)

### 2.2 Out of Scope

- 다국어 번역본 en/fr/de/es/ja/pt/th/vi/zh 반영 (후속 번역 티켓)
- 스캔 이력의 Supabase 동기화 (현재 `sync` 모듈은 color palette 전용 — 이번엔 로컬 Hive 전용)
- QR 보안 스캔(피싱 URL 경고, 악성 Wi-Fi 탐지 등)
- 스캐너 화면 내 연속 스캔 모드 / 배치 스캔
- NFC 읽기 (본 기획은 QR 카메라 스캔 한정)
- 스캔 결과 → 자동 태그 생성 원클릭 단축 모드 (사용자 확인 경유가 MVP)
- "꾸미기" 흐름의 UI 자체 개편 (기존 `qr_result` 모듈은 건드리지 않음, 파라미터만 전달)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | Home 그리드에 `scanner` 타일을 **첫 번째 위치**(index 0)로 삽입. edit mode hide/restore 대상에 포함. | High | Pending |
| FR-02 | `/scanner` 진입 시 카메라 권한 체크 → 허용 상태면 즉시 `MobileScannerController` 시작, 미결정 상태면 권한 요청, 거부 상태면 "설정으로 이동" + 갤러리 임포트만 허용하는 폴백 UI 노출. | High | Pending |
| FR-03 | 스캐너 화면은 풀스크린 카메라 프리뷰 + 중앙 사각형 Scanning Reticle + 하단 Floating Control Bar(플래시 토글, 갤러리 임포트) 로 구성. | High | Pending |
| FR-04 | QR 인식 성공 시 `HapticFeedback.mediumImpact()` 진동 발생, Reticle에 성공 애니메이션, 즉시 결과 Bottom Sheet 표시. | High | Pending |
| FR-05 | 갤러리에서 선택한 이미지에서도 `MobileScannerController.analyzeImage()` 로 QR 디코드 지원. | High | Pending |
| FR-06 | 스캔된 원문(raw)을 **9종 타입**으로 자동 분류 파서 구현: URL(http/https), WiFi(`WIFI:`), Contact(`BEGIN:VCARD`/`MECARD:`), SMS(`SMSTO:`/`smsto:`), Email(`mailto:`/`MATMSG:`), Location(`geo:`), Event(`BEGIN:VEVENT`), 앱 딥링크(`apptag://` 자체 schema), Text(fallback). | High | Pending |
| FR-07 | 결과 Bottom Sheet는 타입 아이콘+라벨(Data Type Tag) + 원문/제목 프리뷰(Preview Area) + 타입별 Primary Actions 버튼군을 표시. 아래로 스와이프 시 즉시 닫히고 스캐너 재개. | High | Pending |
| FR-08 | `URL` 타입 Primary Actions: "브라우저 열기" (`url_launcher`), "링크 복사" (`Clipboard`). | High | Pending |
| FR-09 | `WiFi` 타입 Primary Actions: "네트워크 자동 연결" (Android: `WifiManager` 또는 `wifi_iot` 패키지 / iOS: `NEHotspotConfiguration`), "SSID 복사", "비밀번호 복사". | Medium | Pending |
| FR-10 | `Text` 타입 Primary Actions: "전체 복사", "공유" (`share_plus`). | High | Pending |
| FR-11 | `Contact/SMS/Email/Location/Event/앱딥링크` 타입 Primary Actions: 해당 OS intent 실행(`url_launcher` + 플랫폼별 scheme). 실패 시 Text 폴백. | Medium | Pending |
| FR-12 | **"꾸미기" 버튼** 공통 제공 — 탭 시 스캔된 값을 해당 타입의 기존 태그 화면으로 값 주입 후 push(`extra` 파라미터). 예: URL → `/website-tag`, WiFi → `/wifi-tag`, Contact → `/contact-tag` 등. 사용자가 해당 화면에서 확인/수정 후 기존대로 `/qr-result` 로 이동. | High | Pending |
| FR-13 | 스캔 1건당 `ScanHistory` 1건을 **자동 저장** (Hive `scan_history_box`). 필드: `id`(uuid), `scannedAt`, `rawValue`, `detectedType`, `parsedMeta`(Map), `isFavorite`. | High | Pending |
| FR-14 | `QrTask` 엔티티에 `isFavorite: bool` 필드 추가. Hive 모델 마이그레이션(schemaVersion bump) 포함. | High | Pending |
| FR-15 | `HistoryScreen` 을 `TabBar` 기반 2탭 구조로 변경: `[생성이력]`(기존 qr_task) / `[스캔이력]`(scan_history). 각 탭 최초 진입 시 해당 notifier 로딩. | High | Pending |
| FR-16 | 양쪽 탭 공통 UI: 상단 Search Bar(실시간 필터) + 그 아래 Filter Chips(전체/URL/WiFi/Contact/…/Text) + 리스트 아이템 `Dismissible`(좌→우 스와이프 시 삭제 확인). 공통 위젯 `HistoryListView<T>` 로 구현. | High | Pending |
| FR-17 | 각 리스트 아이템 우측에 ⭐ 토글(`IconButton`). 토글 즉시 해당 Hive 박스 갱신. | High | Pending |
| FR-18 | Filter Chips 는 현재 탭에 표시된 엔티티의 `detectedType`(스캔) 또는 `meta.tagType`(생성) 로부터 동적으로 생성. "전체" 기본 선택. | Medium | Pending |
| FR-19 | 신규 UI 문자열은 `app_ko.arb` 에만 추가. 타 로케일 arb 에는 "ko fallback" 주석 + 미번역 그대로 유지(후속 티켓). | Medium | Pending |
| FR-20 | 라우트 `/scanner` 를 `lib/core/di/router.dart` 에 등록. 딥링크 경로는 추가하지 않음(내부 네비게이션만). | High | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 홈 타일 탭 → 스캐너 카메라 프리뷰 첫 프레임 표시까지 **< 1.0s** (최근 단말 기준) | 수동 타이밍 + Android Profiler |
| Performance | QR 인식 후 Bottom Sheet 표시까지 **< 300ms** (인식 성공 이벤트 → 시트 애니메이션 시작) | Stopwatch 로그 |
| Stability | 카메라 권한 거부 / 카메라 디바이스 오류 시 크래시 없이 폴백 UI 도달 | 수동 테스트 |
| Persistence | `scan_history_box` 1만건 저장 시 `HistoryScreen` 스캔탭 첫 페인트 **< 500ms** | 대량 fixture 주입 테스트 |
| Architecture | 신규 `scan_history` 모듈이 R-series 패턴 8가지 Hard Rule 100% 준수 | `phase-8-review` 수동 체크리스트 |
| Compatibility | 기존 `qr_task_box` 사용자의 isFavorite 필드 누락 데이터가 기본값 `false` 로 자동 복원 | 기존 데이터 수동 업그레이드 테스트 |
| Accessibility | 모든 IconButton 에 `tooltip` 속성, Bottom Sheet 액션 최소 터치 영역 48x48dp | 수동 점검 |
| Security | WiFi 비밀번호는 복사/연결 외 디스플레이 하지 않고, 최초 프리뷰에서 마스킹(`••••`) | 수동 점검 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] FR-01 ~ FR-20 모두 구현 및 동작 확인
- [ ] Android 실기기 1대 + iOS 시뮬레이터(가능한 한 실기기)에서 스캔/갤러리/권한거부 3개 시나리오 통과
- [ ] `scan_history` 모듈이 R-series 패턴으로 작성되어 참조 구현(`qr_result_provider.dart`)과 구조적으로 동형
- [ ] `QrTask` Hive 스키마 마이그레이션 — 기존 생성이력 데이터 손실 없이 `isFavorite=false` 로 로드
- [ ] 신규 추가/수정 파일에 `part of` + `library;` 선언 올바름, `flutter analyze` 0 errors
- [ ] `docs/02-design/features/qr-scanner-ui-ux.design.md` 작성 (R-series 패턴 고정 적용, 아키텍처 옵션 비교 생략 — `CLAUDE.md` 고정 규약)

### 4.2 Quality Criteria

- [ ] `flutter analyze` 0 errors, warnings는 기존 수준 유지(신규 도입 없음)
- [ ] 파일 크기 가이드 준수: 메인 provider ≤ 200 lines, 각 mixin ≤ 150 lines, 각 sub-state ≤ 150 lines, UI 파트 ≤ 400 lines
- [ ] `CONVENTIONS/naming`: 라우트 `/scanner`, Hive 박스 `scan_history_box`, Hive 어댑터 typeId 신규 번호 충돌 없음
- [ ] 불필요한 backward-compat shim 제로(메모리 `feedback_code_decision_criteria` 준수)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **mobile_scanner 최신 버전 호환** (Flutter 3.x) | High | Medium | Design 단계에서 `^5.x` / `^4.x` 비교. `pretty_qr_code` 와 동일 그래픽 파이프라인 충돌 없는지 확인. `mobile_scanner_platform_interface` API 표면 점검. |
| **iOS WiFi 자동 연결 API 제약** (NEHotspotConfiguration 앱 자격증명 필요) | Medium | High | MVP 는 iOS에서 "SSID/비밀번호 복사"만 지원, 자동 연결은 Android 전용으로 FR-09 범위 축소 가능. Design에서 확정. |
| **ScanHistory Hive 박스 typeId 충돌** | High | Low | 기존 typeId 전수조사 후 > 10 번대 대역에서 할당. 신규 어댑터 등록 시 `hive_config.dart` 에 일괄 선언. |
| **QrTask isFavorite 필드 추가 시 기존 데이터 역직렬화 실패** | High | Medium | Hive `@HiveField(N, defaultValue: false)` 사용 및 `fromPayloadMap` 에서 `map['isFavorite'] ?? false` 방어. 기존 데이터 로드 수동 테스트 필수. |
| **카메라 권한 거부 상태에서 루프 요청** | Medium | Medium | `permission_handler` 의 `openAppSettings()` 안내 + 상태 체크를 route focus마다 리프레시하여 설정 후 복귀 시 자동 반영. |
| **갤러리 QR 이미지 해상도 낮을 때 인식 실패** | Low | Medium | 실패 시 Bottom Sheet 대신 `SnackBar` 로 "인식 실패, 원본 이미지 품질을 확인하세요" 안내. |
| **9종 타입 파서 정규식 복잡도** | Medium | Medium | 파서를 `lib/features/scanner/domain/parser/` 로 단일 책임 모듈화. 각 타입당 1개 함수 + 풍부한 unit test(문자열 fixture). |
| **Home 타일 10개로 증가 시 편집모드 레이아웃 깨짐** | Low | Low | 2x5 그리드 유지, `childAspectRatio` 현재 1.1 유지. 시각 점검. |
| **R-series 패턴 미숙지로 인한 구조 드리프트** | High | Low | Plan/Design 양쪽에 `feedback_provider_pattern.md` 참조 명시, Design 에서 파일 구조 트리 선행 확정. |

---

## 6. Impact Analysis

### 6.1 Changed Resources

| Resource | Type | Change Description |
|----------|------|--------------------|
| `lib/features/history/presentation/screens/history_screen.dart` | Flutter Screen | 단일 리스트 → `TabBar` 2탭 + Search + Filter Chips 구조로 전면 개편 |
| `lib/features/qr_task/domain/entities/qr_task.dart` | Domain Entity | `isFavorite: bool` 필드 추가 (default false) |
| `lib/features/qr_task/data/models/qr_task_model.dart` | Hive Model | `@HiveField` 추가, `defaultValue: false` |
| `lib/features/qr_task/presentation/providers/qr_task_list_notifier.dart` | Riverpod Notifier | `toggleFavorite(id)`, `search(query)`, `filterByType(tagType)` 메서드 추가 |
| `lib/features/home/home_screen.dart` | Flutter Screen | 타일 리스트 `_buildTiles` 에 `scanner` 타일을 **index 0** 으로 삽입 |
| `lib/core/di/router.dart` | Router Config | `/scanner` 경로 추가 (결과 Bottom Sheet는 route 아닌 showModalBottomSheet) |
| `lib/core/di/hive_config.dart` | Hive 초기화 | `scan_history_box` 등록 + `ScanHistoryModelAdapter` 등록 |
| `lib/l10n/app_ko.arb` | 다국어 | 신규 문자열 추가 (tileScanner, scannerPermission*, scanResult*, historyTabCreated, historyTabScanned, actionFavorite, filterAll 등) |
| `pubspec.yaml` | Dependencies | `mobile_scanner`, `permission_handler`, (조건부) `wifi_iot` 또는 `network_info_plus` 추가 |
| `android/app/src/main/AndroidManifest.xml` | Native Manifest | `<uses-permission android:name="android.permission.CAMERA" />` 재확인 |
| `ios/Runner/Info.plist` | Native Plist | `NSCameraUsageDescription` 추가 |

### 6.2 Current Consumers

| Resource | Operation | Code Path | Impact |
|----------|-----------|-----------|--------|
| `qrTaskListNotifierProvider` | READ | `lib/features/history/presentation/screens/history_screen.dart:15` | **Needs verification** — 2탭으로 개편 시 기존 읽기 지점이 생성이력 탭 내부로 이동. 동작 동일하도록 유지. |
| `qrTaskListNotifierProvider` | DELETE | `history_screen.dart` `_confirmDelete`, `clearAll` | **Needs verification** — `Dismissible` + 탭별 `clearAll` 로 확장. 기존 다이얼로그 로직 재사용. |
| `QrTask` entity fields | READ | `lib/features/qr_result/presentation/providers/qr_result_providers.dart`, `lib/features/qr_task/data/models/qr_task_model.dart` 직렬화 | **Needs verification** — 신규 `isFavorite` 필드 추가. `toPayloadMap`/`fromPayloadMap` 에 반영 후 외부 소비자 영향 없음(읽기만). |
| `_buildTiles` | CREATE | `lib/features/home/home_screen.dart:59` | **None** — 리스트에 신규 타일 삽입만. 기존 타일 객체 불변. |
| `_hiddenKeys` (SettingsService) | READ/WRITE | `lib/features/home/home_screen.dart:29,50`, `lib/core/services/settings_service.dart` | **None** — 새 키 `scanner` 가 추가되어 저장소에 쌓일 수 있으나 기존 사용자 데이터는 영향 없음. |
| `/qr-result` 라우트 | NAVIGATE | `history_screen.dart:116`, 각 `*_tag_screen.dart` | **None** — 결과 꾸미기 화면은 이번 Plan에서 미변경, 기존 `extra` 파라미터 계약 그대로. |
| Hive `qr_task_box` | READ/WRITE | `lib/features/qr_task/data/datasources/hive_qr_task_datasource.dart` | **Needs verification** — `isFavorite` 필드 역직렬화 누락 시 기본값 복원 동작 확인. |
| 기존 태그 화면 9종 | NAVIGATE via extra | `lib/core/di/router.dart` 경로 등록부 | **Needs verification** — 스캔 결과 "꾸미기" 경유 시 `extra: { prefill: ... }` 포맷 수용 필요. 현재 해당 화면들이 `extra` 파라미터를 받는지 개별 확인 필요 → Design 단계 상세화. |

### 6.3 Verification

- [ ] 위 모든 consumer 가 변경사항에 대해 동작 검증되었음
- [ ] `isFavorite` 필드 누락 기존 Hive 데이터 로드 성공
- [ ] 신규 `scan_history_box` 의 typeId 가 기존 typeId 와 충돌하지 않음 (`hive_config.dart` 전수 점검)
- [ ] `HistoryScreen` 2탭 개편 후 기존 deep link (`/history`) 여전히 동작
- [ ] 기존 태그 화면 9종 이 모두 `extra: Map<String,dynamic>` 수신 가능한지 확인

---

## 7. Architecture Considerations

### 7.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | 단순 구조 | 정적 사이트 | ☐ |
| **Dynamic** | Feature-based 모듈, BaaS 통합 | SaaS 풀스택 | ☐ |
| **Flutter Dynamic** | **Feature 모듈 + Clean Architecture + Riverpod** | **모바일 앱, 본 프로젝트** | ☑ |
| **Enterprise** | 엄격한 레이어 분리, DI, 마이크로서비스 | 고트래픽 시스템 | ☐ |

> 본 프로젝트는 Flutter 앱이며 bkit 표준 레벨 정의와 1:1 매칭되지 않음. 실질적으로 "Feature 모듈 × Clean Architecture(domain/data/presentation)" 를 채택한 **Dynamic 변형**.

### 7.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Framework | Flutter (기결정) | Flutter 3.10.7+ | 기존 코드베이스 |
| State Management | Riverpod / Bloc / Provider | **Riverpod StateNotifier** | 기존 컨벤션, R-series 검증 패턴 |
| 상태 구조 | flat state / composite state | **composite State + sub-states + mixin setters** (`part of`) | `feedback_provider_pattern.md` 강제 |
| 로컬 저장 | Hive / sqflite / isar | **Hive (별도 박스)** | 기존 `qr_task_box`와 동일 기술, 모듈 격리를 위해 별도 박스 |
| QR 스캔 | mobile_scanner / qr_code_scanner / google_mlkit_barcode_scanning | **mobile_scanner** | Notion 기획안 명시, 활발한 유지보수 |
| 권한 | permission_handler / 네이티브 단순 | **permission_handler** | 설정 이동 다이얼로그 표준 패턴 |
| Form Handling | react-hook-form 유사 / native | Flutter `TextField` + Riverpod state | 스캐너는 폼 중심 아님 |
| Styling | Material 3 기본 테마 | **Material 3** | 기존 테마 유지 |
| 라우팅 | go_router (기결정) | **go_router ^14** | `/scanner` 경로 단일 추가 |
| 파서 | 타입별 switch / 정규식 맵 / Strategy | **타입별 독립 함수 + tryParse 우선순위 체인** | 단위 테스트 용이성 |

### 7.3 Clean Architecture Approach

```
Selected: Flutter Feature Modules × Clean Architecture × R-series Provider 패턴

신규 디렉터리 (R-series 패턴 엄격 준수):

lib/features/scanner/
├── scanner_provider.dart                      # library; + part + ScannerState + Notifier(lifecycle)
├── domain/
│   ├── entities/
│   │   ├── scan_detected_type.dart            # enum (URL, WiFi, Contact, SMS, Email, Location, Event, AppDeepLink, Text)
│   │   ├── scan_result.dart                   # value object (rawValue + detectedType + parsedMeta)
│   │   └── scan_parse_error.dart
│   ├── state/
│   │   ├── scanner_camera_state.dart          # isActive, flashOn, permissionStatus, errorMessage
│   │   └── scanner_result_state.dart          # currentResult, sheetVisible
│   ├── parser/
│   │   ├── url_parser.dart
│   │   ├── wifi_parser.dart
│   │   ├── vcard_parser.dart
│   │   ├── sms_parser.dart
│   │   ├── email_parser.dart
│   │   ├── geo_parser.dart
│   │   ├── vevent_parser.dart
│   │   ├── app_deeplink_parser.dart
│   │   └── scan_payload_parser.dart           # 우선순위 체인 디스패처
│   └── usecases/
│       ├── parse_scan_payload_usecase.dart
│       ├── handle_url_action_usecase.dart
│       ├── handle_wifi_action_usecase.dart
│       └── route_to_tag_screen_usecase.dart   # "꾸미기" 경로 분기
├── data/
│   ├── datasources/
│   │   └── gallery_qr_decoder_datasource.dart # MobileScannerController.analyzeImage 래퍼
│   └── repositories/ (필요 시)
├── notifier/
│   ├── camera_setters.dart                    # mixin _CameraSetters
│   └── result_setters.dart                    # mixin _ResultSetters
└── presentation/
    ├── screens/
    │   └── scanner_screen.dart                # library; + part 로 UI 분할
    ├── widgets/
    │   ├── scanner_screen/                    # part of '../screens/scanner_screen.dart'
    │   │   ├── scanning_reticle.dart
    │   │   ├── control_bar.dart
    │   │   └── permission_fallback.dart
    │   └── result_bottom_sheet/
    │       ├── result_sheet.dart              # (자체 library로 분리 권장)
    │       ├── data_type_tag.dart
    │       ├── preview_area.dart
    │       └── primary_actions.dart
    └── providers/
        └── scanner_providers.dart

lib/features/scan_history/
├── scan_history_provider.dart                 # library; + ScanHistoryState + Notifier(lifecycle)
├── domain/
│   ├── entities/
│   │   └── scan_history.dart                  # id, scannedAt, rawValue, detectedType, parsedMeta, isFavorite
│   ├── state/
│   │   ├── scan_history_list_state.dart       # items, isLoading
│   │   └── scan_history_filter_state.dart     # query, selectedType, sortOrder
│   ├── repositories/
│   │   └── scan_history_repository.dart
│   └── usecases/
│       ├── save_scan_history_usecase.dart
│       ├── list_scan_history_usecase.dart
│       ├── toggle_favorite_usecase.dart
│       └── delete_scan_history_usecase.dart
├── data/
│   ├── models/
│   │   └── scan_history_model.dart            # Hive adapter
│   ├── datasources/
│   │   └── hive_scan_history_datasource.dart
│   └── repositories/
│       └── scan_history_repository_impl.dart
└── notifier/
    ├── list_setters.dart                      # mixin _ListSetters
    └── filter_setters.dart                    # mixin _FilterSetters

수정 영역 (기존 파일):
├── lib/features/home/home_screen.dart                        # _buildTiles 에 scanner 타일 삽입
├── lib/features/history/presentation/screens/history_screen.dart  # TabBar 2탭으로 전면 개편
├── lib/features/history/presentation/widgets/                # (신규) 공통 HistoryListView, SearchBar, FilterChips, HistoryTile
├── lib/features/qr_task/domain/entities/qr_task.dart         # isFavorite 필드 추가
├── lib/features/qr_task/data/models/qr_task_model.dart       # HiveField 추가
├── lib/features/qr_task/presentation/providers/qr_task_list_notifier.dart  # toggleFavorite/search/filter
├── lib/core/di/router.dart                                   # /scanner 라우트 등록
├── lib/core/di/hive_config.dart                              # scan_history_box + Adapter 등록
├── lib/l10n/app_ko.arb                                       # 신규 문자열
├── pubspec.yaml                                              # mobile_scanner + permission_handler
├── android/app/src/main/AndroidManifest.xml                  # CAMERA 권한
└── ios/Runner/Info.plist                                     # NSCameraUsageDescription
```

**R-series Hard Rules (재확인, Design에서 준수 검증 필수)**:
1. No flat fields on composite state — 외부 접근은 `state.camera.flashOn` 같은 복합 경로만
2. No `_sentinel` — `clearXxx: bool` 플래그 사용
3. No backward-compat getters
4. No re-exports — 소비자가 직접 `domain/entities/` import
5. Mixin 은 언더스코어 프리픽스 (`_CameraSetters`)
6. 각 sub-state = 단일 관심사
7. 메인 Notifier 는 lifecycle only (생성자, dispose, 영속성 load/push)
8. 파일 크기: 메인 ≤ 200줄, mixin/sub-state ≤ 150줄, UI part ≤ 400줄

---

## 8. Convention Prerequisites

### 8.1 Existing Project Conventions

- [x] `CLAUDE.md` 있음 (내용 확인 필요 — 현재 1줄로 보임)
- [ ] `docs/01-plan/conventions.md` 없음
- [x] 암묵적 컨벤션 — R-series 패턴이 메모리에 문서화됨 (`feedback_provider_pattern.md`)
- [x] `analysis_options.yaml` 존재 (lint 설정)
- [ ] 프로젝트 루트 `CONVENTIONS.md` 없음
- [x] Clean Architecture (domain/data/presentation) 레이어 규약 적용 중

### 8.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **Naming** | exists (snake_case 파일, camelCase 멤버) | 기존 준수 | High |
| **Folder structure** | exists (feature-based + Clean Architecture) | R-series 패턴 적용 | High |
| **Import order** | 관습적(dart:→package:→상대경로) | 유지 | Medium |
| **Hive typeId 관리** | missing (중앙 레지스트리 없음) | `hive_config.dart` 내 typeId 상수 블록으로 통합 관리 | High |
| **Haptic feedback 정책** | missing | `HapticFeedback.mediumImpact()` 를 스캔 성공 표준으로 | Low |
| **Route naming** | exists (kebab-case: `/qr-result`, `/app-picker`) | `/scanner` 신규 추가 | Medium |
| **l10n fallback 정책** | missing | ko 선반영, 타 로케일은 ko fallback + 번역 티켓 분리 | Medium |

### 8.3 Environment Variables / Build Flags

| Variable | Purpose | Scope | To Be Created |
|----------|---------|-------|:-------------:|
| `NSCameraUsageDescription` | iOS 카메라 권한 안내 문자열 | Info.plist | ☐ |
| `android.permission.CAMERA` | Android 카메라 권한 | AndroidManifest | ☐ (기존 존재 여부 확인 필요) |
| (없음) | 런타임 환경변수 | — | — |

### 8.4 Pipeline Integration

본 프로젝트는 bkit 9-phase Development Pipeline 을 사용하지 않음(Flutter 네이티브 앱). 대신 bkit PDCA 단독 사용:

| Phase | Status | Document Location | Command |
|-------|:------:|-------------------|---------|
| Plan | 🔄 In Progress | `docs/01-plan/features/qr-scanner-ui-ux.plan.md` | `/pdca plan` (current) |
| Design | ☐ | `docs/02-design/features/qr-scanner-ui-ux.design.md` | `/pdca design qr-scanner-ui-ux` |
| Do | ☐ | — | `/pdca do qr-scanner-ui-ux` |
| Check | ☐ | `docs/03-analysis/qr-scanner-ui-ux.analysis.md` | `/pdca analyze qr-scanner-ui-ux` |
| Report | ☐ | `docs/04-report/qr-scanner-ui-ux.report.md` | `/pdca report qr-scanner-ui-ux` |

---

## 9. Next Steps

1. [ ] `/pdca design qr-scanner-ui-ux` — Design 문서 작성 (**R-series 패턴 + Clean Architecture 고정**, 아키텍처 옵션 비교 생략 — `CLAUDE.md` 고정 규약 적용)
   - `lib/features/scanner/` + `lib/features/scan_history/` 디렉터리 트리 상세화
   - 각 sub-state / entity / mixin 세부 시그니처
   - Hive typeId 할당 (자동 결정, 근거 기재)
   - WiFi 자동 연결 iOS 폴백 범위 (자동 결정, 근거 기재)
   - 기존 태그 화면 9종의 `extra` 파라미터 스펙 통일
   - History 공통 위젯 제네릭 시그니처(`HistoryListView<T>`)
2. [ ] Design 승인 후 `/pdca do qr-scanner-ui-ux` 로 구현 착수
3. [ ] 구현 완료 후 `/pdca analyze` 로 Design-구현 Gap 분석 (목표 Match Rate ≥ 90%)
4. [ ] Gap ≥ 90% 도달 시 `/simplify` 실행 → `/pdca report` 로 완료 보고서 생성

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-21 | 초안 작성 — Notion 기획안 기반 + 사용자 Checkpoint 1·2 답변 반영 + R-series 패턴 반영 | tawool83 |
