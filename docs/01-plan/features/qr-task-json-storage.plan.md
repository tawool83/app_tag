---
template: plan
version: 1.2
feature: qr-task-json-storage
date: 2026-04-15
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# qr-task-json-storage Planning Document

> **Summary**: QR/NFC 생성 기록을 `QrTask` 로 통합하고, 꾸미기 상태를 JSON payload (schemaVersion 포함) 로 저장. JSON 을 Single Source of Truth 로 — UI는 JSON을 구독. TagHistory 폐기, 향후 Supabase 동기화 대비.
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Author**: tawool83
> **Date**: 2026-04-15
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | QR 꾸미기 필드가 TagHistory 의 산재 Hive 필드로 저장되어 신규 필드 추가 시 typeId 확장·null-cast 이슈 반복. 향후 클라우드 동기화·편집 복원 기능에 부적합. |
| **Solution** | QR/NFC 작업을 `QrTask` 단일 Entity 로 통합. 꾸미기 상태는 JSON payload (`customization`) 로 저장, `schemaVersion` 포함. JSON 이 UI의 단일 진실. 로고 = Base64 inline, 배경 이미지 기능은 포기. |
| **Function/UX Effect** | 히스토리 탭 시 **편집 화면 완전 복원** 가능. 향후 꾸미기 필드 추가 시 코드만 수정(Hive 스키마 불변). 기존 저장 히스토리 레코드는 폐기(초기화). |
| **Core Value** | "한 번 만든 QR 을 언제든 이어서 편집, 클라우드 동기화 준비". 유지보수성·확장성 대폭 향상. |

---

## 1. Overview

### 1.1 Purpose

사용자가 QR 생성 메뉴에 진입하면 `QrTask` 가 즉시 발급되고, 꾸미기 작업 내용이 JSON payload 로 실시간 저장된다. 히스토리 화면은 이 Task 목록을 보여주는 뷰. 탭 시 해당 Task 로 편집 화면이 완전 복원된다.

### 1.2 Background

- **직전 경험**: `UserQrTemplate` 의 Hive `typeId: 1` 확장 시 구 레코드 null-cast 오류가 3회 발생 (commit 60808e3, 그리고 이번 세션에서 build_runner가 재생성하며 2회 재발).
- **근본 원인**: Hive fieldId 기반 스키마는 nullable 처리·기본값을 어댑터 생성기가 인지 못함. 생성 코드 수동 패치는 build_runner 재실행 시 사라짐.
- **해결 방향**: 꾸미기 상태를 **단일 JSON 문자열 필드**로 저장 → Hive 스키마 불변. JSON 내부 스키마는 `schemaVersion` 으로 관리.
- **추가 동기**: 편집 복원 UX, 클라우드 동기화 자연스러움.

### 1.3 Related Documents

- `docs/01-plan/features/clean-architecture-refactor.plan.md` (P3 qr_result 단계와 연동)
- 현 코드: `lib/features/history/` (P1 완료), `lib/models/user_qr_template.dart`, `lib/features/qr_result/qr_result_provider.dart`
- 참고: `qr_template.dart` 이미 `toJson/fromJson` 패턴 사용 (QrGradient, QrForeground 등)

---

## 2. Scope

### 2.1 In Scope

- [ ] 새 도메인 엔티티 `QrTask` 정의
- [ ] `QrTaskPayload` (JSON customization) 설계 — schemaVersion=1
- [ ] 로컬 저장소: Hive box `qr_tasks` (타입 `QrTaskModel`, typeId=2)
- [ ] `QrResultState` ↔ `QrTaskPayload` 변환 레이어
- [ ] **JSON = Single Source of Truth**: 상태 변경 시 JSON 즉시 갱신 → UI는 JSON을 watch
- [ ] 로고 이미지 (중앙 아이콘): Base64 inline 직렬화
- [ ] QR 생성 메뉴 진입 즉시 QrTask 발급·저장
- [ ] NFC 쓰기도 QrTask 에 통합 (`kind: 'qr' | 'nfc'`)
- [ ] 히스토리 화면 → QrTask 목록 표시
- [ ] 히스토리 탭 시 **편집 화면 완전 복원** (같은 taskId 업데이트)
- [ ] 삭제 / 전체 삭제
- [ ] 기존 TagHistory 관련 코드 제거
- [ ] 단위 테스트 (Payload 직렬화, Repository, UseCase)

### 2.2 Out of Scope

- **QR 배경 이미지 기능** — 본 PDCA에서 **제거** (사용자 결정)
- **Supabase 클라우드 동기화** — 별도 PDCA `qr-task-cloud-sync`
- 기존 TagHistory Hive 레코드 자동 마이그레이션 (폐기/초기화 정책)
- `UserQrTemplate` (저장 템플릿) 의 구조 변경 — 독립 유지
- NFC 쓰기 UX 변경 — 데이터 모델만 QrTask 로 통합
- 페이드 인/아웃 애니메이션 등 UI 변경

### 2.3 주요 개념

| 개념 | 역할 | 현재 상태 |
|---|---|---|
| **QrTask** | 1건의 QR/NFC 생성 작업 기록 (이 feature 신규) | 신규 |
| **QrTaskPayload** | Task 의 꾸미기·메타 상태 JSON | 신규 |
| **UserQrTemplate** | "스타일만 저장한 껍데기" — 재사용용 | 기존 유지, 이 feature 와 독립 |
| **QrTemplate** | 서버/asset 기본 템플릿 — 스타일만 | 기존 유지 |

Template(스타일) → QrTask(실제 데이터) 에 적용. Template은 QrTask 에 복사되는 스타일 소스일 뿐, Task 자체가 아님.

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | QR 생성 화면 진입 시 QrTask 즉시 발급·저장 (taskId, createdAt, meta) | High | Pending |
| FR-02 | 꾸미기 상태 변경 → 디바운스 후 JSON payload 갱신 (같은 taskId 업데이트) | High | Pending |
| FR-03 | JSON payload 가 UI 의 Single Source of Truth — Notifier 가 JSON을 구독해 state 파생 | High | Pending |
| FR-04 | NFC 쓰기 플로우도 QrTask 에 `kind: 'nfc'` 로 기록 | High | Pending |
| FR-05 | 히스토리 화면은 QrTask 목록 표시 (최신순) | High | Pending |
| FR-06 | 히스토리 탭 시 QrTask 로부터 편집 화면 완전 복원 (같은 taskId 이어서 편집) | High | Pending |
| FR-07 | 히스토리 단건/전체 삭제 | Medium | Pending |
| FR-08 | 로고 이미지(중앙 아이콘)를 Base64 inline 으로 직렬화 | High | Pending |
| FR-09 | QrTaskPayload 에 `schemaVersion` 필드 포함, 파싱 시 버전 확인 | Medium | Pending |
| FR-10 | 배경 이미지 입력 UI 제거 (설정/탭 포함) | Medium | Pending |
| FR-11 | 기존 TagHistory 관련 코드·데이터 폐기 (자동 migration 없음) | High | Pending |
| FR-12 | QrTask 단위 테스트 (payload 왕복, Repository, UseCase) | Medium | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 꾸미기 상태 변경 → JSON persist 지연 ≤ 600ms (debounce 500ms + write) | 수동 측정 |
| Payload 크기 | 평균 QrTask 크기 ≤ 8KB (로고 Base64 포함) | 실측 |
| Forward Compat | `schemaVersion > 현 앱 지원` 시 최소 표시 + 경고 배너 | 수동 QA |
| Code Quality | `flutter analyze` 0 issues (feature 범위) | CLI |
| Test Coverage | payload + repository 70% 이상 | `flutter test --coverage` |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] QrTask Hive box `qr_tasks` (typeId=2) 도입
- [ ] QrTaskPayload JSON 스키마 문서화 + 코드 직렬화 왕복 테스트
- [ ] QR 화면 진입 즉시 Task 발급 + 꾸미기 중 debounced autosave
- [ ] JSON → UI 단방향 흐름 확인 (Notifier 가 JSON 을 source of truth 로 사용)
- [ ] 히스토리 탭 → 편집 화면 완전 복원 (동일 taskId 업데이트)
- [ ] NFC 도 QrTask 에 기록
- [ ] 배경 이미지 UI 제거
- [ ] 기존 TagHistory 관련 파일 전부 삭제
- [ ] `flutter analyze` 0 issues (feature 범위)
- [ ] 단위 테스트 통과

### 4.2 Quality Criteria

- [ ] 꾸미기 필드 N개 추가 시 Hive 스키마 변경 0 (JSON schemaVersion만 bump)
- [ ] 기존 Hive `tag_history` box 파일 폐기 스크립트/로직 확인
- [ ] 데이터 손실 경고 UX — 앱 업데이트 최초 실행 시 alert

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 기존 사용자 이력 삭제로 불만 | Medium | High | 업데이트 최초 실행 시 명확한 alert. **릴리즈 노트에 명시**. 사용자가 적다면 수용 가능. |
| JSON 직렬화 누락 필드 | High | Medium | 왕복 테스트 전체 필드 커버. `copyWith` 정의된 모든 필드를 JSON schema 에 포함. |
| 로고 Base64 누적 → 저장소 비대 | Medium | Low | 로고는 통상 작은 emoji/icon. 디바이스 저장소 걱정 시 로고 해상도 cap. |
| Debounce 500ms 사이 앱 강제 종료 → 미저장 상태 날아감 | Low | Low | 마지막 저장 시점 timestamp 노출. 사용자 체감 허용 범위. |
| `schemaVersion` 올라간 JSON 을 구 앱이 읽는 시나리오 | Medium | Low | 본 PDCA 범위는 v1만. 이후 migration 로직 설계는 schemaVersion 이 증가할 때 별도 PDCA. |
| Riverpod Provider graph 에 write-through 추가로 순환 의존 | Medium | Medium | `QrResultNotifier` 이 `QrTaskRepository` 로 단방향 write, repository는 Notifier 를 모름. |
| build_runner 재실행으로 `.g.dart` 수동 패치 재발 | High | High | **QrTaskModel 은 단일 필드(JSON string) + id/createdAt/kind 만 @HiveField**. 과거 이슈가 재발 불가능한 구조. |

---

## 6. Impact Analysis

### 6.1 Changed Resources

| Resource | Type | Change |
|---|---|---|
| `lib/features/history/*` (P1 결과물) | Dart modules | TagHistory → QrTask 로 엔티티 교체, payload JSON 필드 추가 |
| Hive box `tag_history` (typeId=0) | 저장소 | **폐기** — 앱 최초 실행 시 삭제 |
| `lib/features/qr_result/qr_result_provider.dart` | Riverpod state | QrResultState 가 QrTaskPayload 로부터 파생되는 구조로 변경 |
| `lib/features/qr_result/qr_result_screen.dart` | UI | `_captureAndSaveHistory` → `_ensureQrTask` (진입 시 발급) + 꾸미기 변경 훅 |
| `lib/features/nfc_writer/nfc_writer_screen.dart` | UI | `saveTagHistoryUseCase` → `createQrTaskUseCase` (kind='nfc') |
| `lib/features/qr_result/tabs/background_tab.dart` | UI | **제거** 또는 빈 안내 탭으로 축소 |
| `lib/models/background_config.dart` | Model | **제거** 또는 로고 전용으로 축소 |
| `lib/core/di/hive_config.dart` | DI | typeId=2 QrTaskModel 등록, typeId=0 레거시 정리 |

### 6.2 Current Consumers

| Resource | Operation | Code Path | Impact |
|----------|-----------|-----------|--------|
| `SaveTagHistoryUseCase` | QR 저장 | `qr_result_screen.dart:237` | 대체됨 → `CreateQrTaskUseCase` / `UpdateQrTaskUseCase` |
| `SaveTagHistoryUseCase` | NFC 저장 | `nfc_writer_screen.dart:68` | 동일 대체 |
| `historyListNotifierProvider` | 히스토리 리스트 | `history_screen.dart` | 내부 엔티티만 QrTask 로 교체, Notifier API 유사 유지 |
| `BackgroundConfig`, `BackgroundTab` | 배경 이미지 | `qr_result_provider.dart`, `background_tab.dart`, `qr_layer_stack.dart` | **제거** (UI 및 state 양쪽) |
| `UserQrTemplate.applyUserTemplate()` | 템플릿 적용 | `qr_result_provider.dart:292` | 배경 관련 필드만 삭제, 나머지 유지 |

### 6.3 Verification

- [ ] QR 생성 → JSON payload 디스크 저장 확인 (Hive inspector)
- [ ] 히스토리 → 탭 → 편집 복원 → 저장 → 동일 taskId 업데이트
- [ ] NFC 쓰기 → QrTask kind='nfc' 기록
- [ ] 기존 tag_history box 파일 polar (폐기) 확인
- [ ] 배경 탭 제거 및 관련 state 정리 후 앱 크래시 없음

---

## 7. Architecture Considerations

### 7.1 Project Level

Dynamic / Enterprise 혼재 프로젝트. 본 feature 는 clean-architecture-refactor 정책에 따라 data/domain/presentation 3-layer 준수.

### 7.2 Key Architectural Decisions

| Decision | Selected | Rationale |
|---|---|---|
| Storage | Hive box `qr_tasks` (typeId=2) | 기존 Hive 유지, sqflite 로 교체는 별도 PDCA |
| Persistence Shape | 단일 JSON string 필드 (+ id/createdAt/kind 만 Hive 필드) | typeId 확장 불필요, schemaVersion 으로 스키마 진화 |
| JSON Codec | `dart:convert` + 수동 `toJson`/`fromJson` | 외부 의존 최소, 기존 `QrGradient.toJson` 패턴 재사용 |
| Single Source of Truth | JSON payload (Hive 저장본) | 꾸미기 변경 → JSON 업데이트 → UI rebuild |
| State Write Debounce | 500ms | 슬라이더 등 고주파 이벤트 IO 폭주 방지 |
| 이미지 정책 | 배경 제거, 로고는 Base64 inline | 스코프 축소 + 단순성 |
| Data Migration | 기존 TagHistory 폐기 (초기화) | 사용자 결정 — 복잡도 제거 |
| NFC Integration | QrTask 로 통합 (`kind` 필드) | 히스토리 통합 뷰, 하나의 저장소 |

### 7.3 JSON Schema (v1) 초안

```json
{
  "schemaVersion": 1,
  "taskId": "uuid-v4",
  "createdAt": "2026-04-15T12:30:00Z",
  "updatedAt": "2026-04-15T12:31:20Z",
  "kind": "qr",                    // "qr" | "nfc"
  "meta": {
    "appName": "클립보드",
    "deepLink": "https://...",
    "platform": "android",
    "packageName": null,
    "appIconBase64": null,          // Base64, nullable
    "tagType": "clipboard"
  },
  "customization": {
    "qrColorArgb": 4278190080,
    "gradient": { ... },            // QrGradient.toJson()
    "roundFactor": 0.0,
    "eyeOuter": "square",
    "eyeInner": "square",
    "randomEyeSeed": null,
    "quietZoneColorArgb": 4294967295,
    "dotStyle": "square",
    "embedIcon": false,
    "centerEmoji": null,
    "centerIconBase64": null,       // 로고 Base64
    "printSizeCm": 5.0,
    "sticker": {
      "logoPosition": "center",
      "logoBackground": "none",
      "topText": null,
      "bottomText": {
        "content": "...",
        "colorArgb": 4278190080,
        "fontFamily": "sans-serif",
        "fontSize": 14
      }
    }
  }
}
```

**주요 원칙**:
- Color → int (ARGB)
- Enum → String (name)
- 이미지 bytes → Base64 string (nullable)
- 모든 optional 필드 → nullable + fromJson 에서 기본값 제공
- `schemaVersion` 항상 첫 필드, 파서는 >1 일 때 graceful degradation

---

## 8. Convention Prerequisites

### 8.1 Existing Project Conventions

- [x] `flutter_lints` 6.0
- [x] P1 패턴: Entity / DTO / UseCase / Repository / Result<Failure,T>
- [ ] JSON schema 버전 관리 규약 — 본 feature 에서 확립

### 8.2 JSON Directives (본 feature)

| Rule | Note |
|---|---|
| 모든 payload 최상단에 `schemaVersion: int` | 필수 |
| `fromJson` 은 누락 필드 기본값으로 복원 | 구 버전 호환 |
| Enum 은 String(name) — `values.byName`, unknown 은 fallback | |
| DateTime 은 ISO 8601 문자열 | |
| Color 는 int (ARGB) | |
| 이미지는 `imageBase64` 접미사 필드 | null = 없음 |

### 8.3 Pipeline Integration

해당 없음.

---

## 9. Roadmap

| Phase | 기간 | 산출물 |
|---|:---:|---|
| P0 | 1일 | JSON schema 문서화 (design step), QrTaskPayload + fromJson/toJson + 왕복 테스트 |
| P1 | 1-2일 | QrTask 엔티티, QrTaskModel DTO, Repository, UseCase 전체 |
| P2 | 1일 | 배경 이미지 UI 제거 (background_tab, BackgroundConfig) |
| P3 | 2-3일 | qr_result_screen / qr_result_provider 를 JSON-first 로 재구성, debounce 500ms |
| P4 | 1일 | NFC 통합 (`kind='nfc'`) |
| P5 | 1일 | 히스토리 화면 QrTask 전환 + 탭 시 편집 복원 |
| P6 | 1일 | 기존 TagHistory 코드/box 폐기, Hive box `tag_history` 삭제 로직 |
| P7 | 1일 | 통합 QA, 데이터 폐기 alert UX |

**총 예상**: 8-11 영업일 (2주 내).

---

## 10. Next Steps

1. [ ] Plan 승인 → `/pdca design qr-task-json-storage`
2. [ ] Design 단계에서 3가지 옵션 비교 (Option A 최소 변경 / B 풀 클린 / C 실용적 절충)
3. [ ] Design 확정 후 `/pdca do` 로 Phase 단위 진행

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-15 | Initial draft (Checkpoint 1/2 완료) | tawool83 |
