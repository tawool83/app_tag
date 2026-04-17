---
template: plan
version: 1.2
feature: clean-architecture-refactor
date: 2026-04-15
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# clean-architecture-refactor Planning Document

> **Summary**: Flutter 앱 `app_tag` 전체(15 features, 58 Dart 파일)를 풀 클린 아키텍처(data/domain/presentation 3-layer)로 점진 마이그레이션. Riverpod DI + Failure/Result 에러 모델 + go_router 도입.
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
| **Problem** | Service/Repository/Model 레이어 경계가 모호하고 `HiveType`이 도메인 엔티티와 혼재 → 테스트 불가, 변경 시 연쇄 파급, 팀 확장·사양 변경에 취약. |
| **Solution** | feature별 3계층(data/domain/presentation) 분리, 의존성 역전(Repository 인터페이스는 domain에, Impl은 data에), Riverpod 기반 DI, `Failure` + `Result<T>` 에러 모델, go_router 도입. 점진 마이그레이션(파일럿: `history`)으로 매 단계 앱 동작 유지. |
| **Function/UX Effect** | 사용자 체감 기능 변화 없음(동일 기능 유지). 개발 측면: 신규 기능 추가 시간 단축, 회귀 감소, 단위 테스트 가능. |
| **Core Value** | "기능 안 바꾸고 구조만 바꿔도 다음 기능 추가 속도가 체감 2배" — 장기 유지보수성·테스트 가능성·신뢰성 확보. |

---

## 1. Overview

### 1.1 Purpose

Flutter 앱 `app_tag`의 현 구조가 기능 성장을 따라오지 못함. Service가 플랫폼 어댑터 + 비즈니스 로직 + UI 헬퍼를 모두 맡고, Hive 모델이 도메인 엔티티로 쓰이며, Repository 추상 인터페이스가 없어 Provider가 구현체에 직결됨. 이를 해소하기 위해 Uncle Bob의 클린 아키텍처를 Flutter에 맞게 적용.

### 1.2 Background

- **현 문제 징후**: QR 관련 template/user_template/qr_readability 등 변경 빈도 높은 영역에서 Service-Repository-Model 간 책임 경계가 무너짐.
- **최근 사고**: `UserQrTemplate` Hive 어댑터의 구 레코드 null 캐스트 오류가 커밋 60808e3에서 수정되었으나 build_runner 재실행 시 날아가 재발 → 생성 코드/도메인/DTO 분리 필요.
- **확장 계획**: 클라우드 동기화(`remoteId`, `syncedToCloud`), in-app 결제, 고급 QR 편집 등 예정 — 지금 구조로는 위험.

### 1.3 Related Documents

- `lib/main.dart` (현 DI 진입점)
- `lib/app/app.dart`, `lib/app/router.dart` (라우팅)
- 기존 feature Plan/Design 문서: `docs/01-plan/features/qr-*.plan.md`

---

## 2. Scope

### 2.1 In Scope

- [ ] `lib/core/` 신설 (error, di, constants, utils)
- [ ] 전체 15개 feature를 data/domain/presentation 3-layer로 재구성
- [ ] Repository 추상 인터페이스(domain) + 구현체(data) 분리
- [ ] Hive `@HiveType` 는 DTO(data/models)에만 남기고, domain/entities는 순수 Dart
- [ ] Service 해체: 플랫폼 adapter는 datasources/, 비즈니스 로직은 usecases/
- [ ] `Failure` sealed class + `Result<T>` 타입 도입
- [ ] go_router 도입 + deep-link 통합
- [ ] Riverpod DI: `main.dart`에서 ProviderScope overrides로 Repository 구현체 주입
- [ ] 파일럿 feature `history` 로 패턴 확정 후 점진 확산
- [ ] UseCase + Repository 단위 테스트 추가 (파일럿 feature부터 커버리지 확보)

### 2.2 Out of Scope

- Hive → sqflite/drift 등 저장소 자체 교체 (별도 PDCA)
- Supabase 스키마/백엔드 변경
- UI/UX 디자인 변경
- 신규 기능 추가 (기능 변화 없음 원칙)
- 릴리즈/배포 파이프라인 변경

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 앱의 모든 기존 기능은 리팩토링 전후로 동일하게 동작해야 한다 (회귀 제로) | High | Pending |
| FR-02 | 기존 Hive 저장 데이터(UserQrTemplate, TagHistory 등)를 마이그레이션 없이 그대로 읽을 수 있어야 한다 | High | Pending |
| FR-03 | 각 feature는 data/domain/presentation 3-layer 구조를 가진다 | High | Pending |
| FR-04 | 모든 Repository는 domain 레이어에 abstract 인터페이스를 가진다 | High | Pending |
| FR-05 | Riverpod Provider는 Repository 추상 타입만 참조한다 (구현체 직결 금지) | High | Pending |
| FR-06 | 에러는 `Failure` sealed class 로 표현, Repository는 `Result<T>` 반환 | Medium | Pending |
| FR-07 | 라우팅은 go_router 기반, deep link 처리 통합 | Medium | Pending |
| FR-08 | 파일럿 feature(`history`) 와 이후 각 feature에 UseCase + Repository 단위 테스트 추가 | Medium | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 앱 콜드 스타트 시간 리팩토링 전 대비 +10% 이내 | 수동 측정 (Android `flutter run --profile`) |
| Backward Compat | 기존 Hive 박스 데이터(`user_qr_templates`, `tag_history`)를 재설치 없이 읽음 | 실기기에서 기존 버전 설치 후 신 버전으로 업그레이드 테스트 |
| Code Quality | `flutter analyze` 경고 0, 순환 의존 0 | `flutter analyze`, `dart_code_metrics` |
| Testability | 파일럿 feature 도메인·데이터 레이어 커버리지 ≥ 70% | `flutter test --coverage` |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] 15개 feature 전부 data/domain/presentation 3-layer로 재구성
- [ ] 낡은 `lib/services/`, `lib/repositories/`, `lib/models/`, `lib/shared/` 제거
- [ ] 모든 Repository 추상 인터페이스 존재
- [ ] `main.dart`에서 ProviderScope overrides 기반 DI
- [ ] go_router 마이그레이션 완료
- [ ] 파일럿 feature 단위 테스트 작성 (코어 UseCase 전부)
- [ ] 앱 빌드 성공 (Android), 기기 수동 스모크 테스트 통과

### 4.2 Quality Criteria

- [ ] `flutter analyze` 0 issues
- [ ] 기존 Hive 데이터 로드 회귀 없음 (UserQrTemplate, TagHistory)
- [ ] Riverpod provider graph 에서 구현체를 직접 import 하는 지점 0

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Hive typeId/fieldId 변경으로 구 레코드 깨짐 | High | Medium | **typeId/fieldId 절대 변경 금지** 원칙. DTO만 분리하고 `@HiveType(typeId: ...)` 숫자는 그대로. 수동 edit된 `.g.dart`는 build_runner 실행 후 패치 재적용 스크립트 or 수동 DTO 어댑터 작성. |
| 점진 마이그레이션 중 구/신 구조 혼재 장기화 | Medium | High | feature 단위 PR(1 feature = 1 PR), main 병합 간격 ≤ 3일, `@Deprecated` 태그 + 완료 타임라인 명시. |
| Riverpod provider graph 재구성 중 앱 크래시 | High | Medium | 파일럿 1개 feature(`history`) 에서 end-to-end 검증 후 패턴 확정, 이후 features는 동일 패턴 복제. |
| go_router 도입으로 deep link 회귀 | High | Low | 기존 `deep_link_constants.dart` 기반 통합 테스트 작성 후 전환. |
| 리팩토링 스콥 과대(15 features × 3 layer × 테스트) → 기간 blow-up | High | High | 각 feature 마이그레이션에 타임박스 설정, 초과 시 스코프 축소. 최소 달성 목표: 파일럿 + core/ + 핵심 3 features (qr_result/nfc_writer/history). |
| build_runner 가 생성한 `.g.dart` 가 수동 패치를 덮어씀 | Medium | High | DTO 파일을 별도로 두고, 생성 adapter는 DTO에만 적용. 수동 null-safe 패치는 **DTO 자체가 non-null 기본값을 가지도록 DTO 클래스 설계** 로 우회. |

---

## 6. Impact Analysis

### 6.1 Changed Resources

| Resource | Type | Change Description |
|----------|------|--------------------|
| `lib/services/*` (8 files) | Dart modules | 해체 → `features/*/data/datasources/` + `features/*/domain/usecases/` 로 분산 |
| `lib/repositories/*` (2 files) | Dart modules | 추상 인터페이스(domain) + Impl(data) 분리 |
| `lib/models/*` (7 files) | Hive models | DTO 로 이전(`data/models/`) + pure Dart Entity 신설(`domain/entities/`) |
| `lib/shared/*` | Dart modules | `lib/core/` 로 이전 |
| `lib/main.dart` | Entry point | static init 제거 → ProviderScope overrides DI |
| `lib/app/router.dart` | Router | `onGenerateRoute` → go_router |
| `lib/features/*/` (15 dirs) | Feature modules | 각 feature 내부에 data/domain/presentation 서브폴더 도입 |

### 6.2 Current Consumers

| Resource | Operation | Code Path | Impact |
|----------|-----------|-----------|--------|
| `HistoryService.init()` | static call | `main.dart:10` | 제거, Repository DI로 대체 |
| `UserTemplateRepository.init()` | static call | `main.dart:11` | Repository Impl 생성자로 이동, Provider 에서 바인딩 |
| `SupabaseService.initialize()` | static call | `main.dart:12` | core/di 에서 초기화 |
| `QrService` (qr_service.dart) | capture/save/share/print | `features/qr_result/*` | 4개 UseCase로 분할: CaptureQrImageUseCase, SaveQrToGalleryUseCase, ShareQrImageUseCase, PrintQrCodeUseCase |
| Hive `UserQrTemplate` typeId=1 | 로컬 저장 | `user_template_repository.dart`, `*_tab.dart`, `qr_layer_stack.dart` | typeId 유지. DTO로 이전 + Entity 매핑 추가 |
| `TagHistory` Hive | 로컬 저장 | `history_service.dart`, `history_provider.dart` | 동일 — 파일럿에서 선처리 |
| `AppRouter.onGenerateRoute` | 네비게이션 | `app.dart:17`, 다수 Navigator.push | GoRouter로 치환, push 호출부도 `context.go()`/`context.push()` 로 변경 |

### 6.3 Verification

- [ ] 15개 feature 각 화면을 기기에서 수동 스모크 테스트
- [ ] 기존 버전 설치 후 신 버전 업그레이드 시 저장 데이터 정상 로드
- [ ] deep link (NFC tap → URL) 정상 파싱
- [ ] 권한(위치, 카메라, NFC) 요청 흐름 변화 없음

---

## 7. Architecture Considerations

### 7.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| Starter | 단순 구조 | 정적 사이트 | ☐ |
| Dynamic | Feature-based 모듈 | 일반 앱 | ☐ |
| **Enterprise** | 엄격한 레이어 분리, DI | 고복잡도 앱 | ☑ |

리팩토링 대상이 Enterprise 수준 구조(레이어 분리·DI·테스트)로의 승격.

### 7.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Framework | Flutter (고정) | Flutter 3.x | 기존 유지 |
| State Mgmt | Riverpod / Bloc / Provider | **Riverpod** | 기존 채택, ProviderScope overrides로 DI 깔끔 |
| DI | get_it / Riverpod Provider / injectable | **Riverpod Provider** | 추가 의존성 없이 state + DI 통합 |
| Error Model | throw / Result<Failure,T> / dartz Either | **Result<Failure,T>** (sealed) | 명시적 에러 + Riverpod AsyncValue 매핑 자연스러움 |
| Routing | onGenerateRoute / go_router / auto_route | **go_router** | deep link 공식 지원, 타입 안전 |
| Local Storage | Hive (고정) | **Hive 유지** | 데이터 호환성. typeId/fieldId 불변 |
| Testing | flutter_test + mocktail | flutter_test + mocktail | 표준 |
| Naming | suffix 엄격 / 간결 | **엄격 suffix** | 검색·역할 구분 용이 |

### 7.3 Clean Architecture Approach

```
lib/
├── core/
│   ├── error/
│   │   ├── failure.dart           # sealed class Failure
│   │   └── result.dart            # sealed class Result<T>
│   ├── di/
│   │   ├── app_providers.dart     # 공통 Provider root
│   │   └── overrides.dart         # ProviderScope overrides 빌더
│   ├── constants/                 # shared/constants 이전
│   ├── utils/                     # shared/utils 이전
│   └── widgets/                   # shared/widgets 이전 (진짜 공용만)
│
├── features/{feature}/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── {name}_local_datasource.dart     # Hive
│   │   │   ├── {name}_remote_datasource.dart    # Supabase/HTTP
│   │   │   └── {name}_platform_datasource.dart  # NFC/camera 등
│   │   ├── models/                # Hive/JSON DTO + mapper (toEntity/fromEntity)
│   │   └── repositories/          # {Name}RepositoryImpl
│   ├── domain/
│   │   ├── entities/              # pure Dart (Hive import 금지)
│   │   ├── repositories/          # abstract {Name}Repository
│   │   └── usecases/              # {Verb}{Name}UseCase (단일 책임)
│   └── presentation/
│       ├── providers/             # Riverpod Notifier/State
│       ├── screens/
│       └── widgets/
│
└── main.dart                      # runApp(ProviderScope(overrides: [...]))
```

**의존 규칙**:
- `presentation` → `domain`
- `data` → `domain`
- `domain` 은 외부 의존 0 (Hive, Flutter, HTTP 전부 금지)
- feature 간 상호 의존 금지 (공통 필요 시 core/ 로 이동)

**네이밍 규칙** (엄격 suffix):
- Entity: `TagHistory` (suffix 없음)
- DTO: `TagHistoryModel` (Hive/JSON)
- DataSource: `HiveTagHistoryDataSource`
- UseCase: `GetTagHistoryUseCase`, `SaveTagHistoryUseCase`
- Repo 추상: `TagHistoryRepository`
- Repo 구현: `TagHistoryRepositoryImpl`

---

## 8. Convention Prerequisites

### 8.1 Existing Project Conventions

- [x] `flutter_lints` 설정 (pubspec.yaml)
- [ ] `CLAUDE.md` 부재 — 리팩토링 중 작성 (선택)
- [ ] layer-import 규칙 (도메인이 data/presentation 참조 금지) — 수동 규칙 + `dart_code_metrics` 검증

### 8.2 Conventions to Define/Verify

| Category | Current | To Define | Priority |
|----------|---------|-----------|:--------:|
| Naming | 암묵적 | 엄격 suffix (§7.3) | High |
| Folder | feature-first | feature × layer 2차원 | High |
| Import | 암묵적 | `package:app_tag/core/...` > `package:app_tag/features/...` > `package:flutter/...` 순 | Medium |
| Error | throw | `Result<Failure,T>` + UI 에서 AsyncValue 변환 | High |
| Test | 없음 | 파일럿부터 usecase/repository 테스트 의무 | Medium |

### 8.3 Environment Variables Needed

| Variable | Purpose | Scope | To Be Created |
|----------|---------|-------|:-------------:|
| (없음) | 현 Supabase 키는 `supabase_service.dart` 하드코드 여부 확인 필요 | | ☐ 검토 |

### 8.4 Pipeline Integration

해당 없음 (별도 9-phase pipeline 미사용).

---

## 9. Roadmap (점진 마이그레이션)

| Phase | 기간 (영업일) | 산출물 | 종료 조건 |
|-------|:---:|---|---|
| **P0. 기반** | 2-3 | `core/` 생성, `Failure`/`Result`, Riverpod DI 루트, `shared/` → `core/` 이전 | `flutter analyze` 통과, 기존 앱 정상 동작 |
| **P1. 파일럿: history** | 2-3 | `features/history/{data,domain,presentation}/` 완전 분리, UseCase 3-5개, 단위 테스트 | 히스토리 화면 기능 동일, 테스트 통과 |
| **P2. go_router 도입** | 1-2 | `core/di/router.dart` (GoRouter), 기존 Navigator.push 치환, deep link 통합 | 모든 화면 이동 동작, deep link 검증 |
| **P3. qr_result** | 3-5 | QrService 해체(4 UseCase), UserQrTemplate DTO/Entity 분리, 5개 탭 presentation 정리 | QR 생성/저장/공유/프린트/템플릿 동작 |
| **P4. nfc_writer** | 2 | NFC 플랫폼 어댑터 분리 | NFC 쓰기 동작 |
| **P5. 나머지 features (12개)** | 7-10 | app_picker, clipboard_tag, contact_tag, email_tag, event_tag, help, home, ios_input, location_tag, output_selector, sms_tag, website_tag, wifi_tag | 각 화면 수동 스모크 |
| **P6. 정리** | 1-2 | 낡은 `lib/services/`, `lib/repositories/`, `lib/models/`, `lib/shared/` 삭제. import 정리. build_runner 재생성 + DTO 수동 null-safe 패치 재적용 | 낡은 디렉토리 0개, 컴파일 성공 |
| **P7. 검증** | 1-2 | 실기기 업그레이드 테스트(기존 데이터 유지), 릴리즈 빌드 | 회귀 0 |

**총 예상**: 약 19-29 영업일 (4-6주). 각 Phase 종료 시 별도 `/pdca` 체크포인트.

---

## 10. Next Steps

1. [ ] Plan 승인 → `/pdca design clean-architecture-refactor`
2. [ ] Design 단계: 3가지 아키텍처 옵션 중 선택 (이 Plan이 Option B=풀 클린아키 로 이미 기울어짐), 상세 folder tree, DI 그래프, 매핑 규칙 확정
3. [ ] P0 구현 시작 (core/ + DI + Failure/Result)
4. [ ] P1 파일럿 feature history 진행 → 패턴 확정
5. [ ] 주간 `/pdca status` 로 진행률 모니터링

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-15 | 초기 작성 (Checkpoint 1/2 완료 후) | tawool83 |
| 0.2 | 2026-04-17 | P0~P5 구현 완료 반영. P6(잔여 레거시 정리)/P7(검증) 남음 | tawool83 |
