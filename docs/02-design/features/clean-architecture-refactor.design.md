---
template: design
version: 1.2
feature: clean-architecture-refactor
date: 2026-04-15
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# clean-architecture-refactor Design Document

> **Summary**: `app_tag` Flutter 앱을 Full Clean Architecture (Option B) 로 점진 마이그레이션. data/domain/presentation 3-layer, UseCase 예외 없음, Riverpod DI, Failure+Result, go_router. 파일럿: `history` feature.
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Author**: tawool83
> **Date**: 2026-04-15
> **Status**: Draft
> **Planning Doc**: [clean-architecture-refactor.plan.md](../../01-plan/features/clean-architecture-refactor.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. **의존성 역전**: `presentation → domain ← data`. domain 은 외부 의존 0.
2. **AI 이해 최적화**: 예외 없는 규칙, 네이밍으로 역할 선언, grep-친화 구조.
3. **테스트 가능성**: UseCase/Repository 단위 테스트 가능.
4. **Hive 데이터 보존**: typeId/fieldId 불변.
5. **점진 안전성**: 매 Phase 앱 빌드·스모크 통과 유지.

### 1.2 Design Principles

- **단일 책임 원칙 (SRP)**: UseCase 클래스 1개 = 동작 1개, `call()` 단일 메서드, 20줄 이내.
- **의존성 역전 원칙 (DIP)**: Provider/UseCase 는 Repository 추상 타입만 참조.
- **인터페이스 분리 원칙 (ISP)**: Repository 당 메서드 ≤ 7개. 초과 시 분리.
- **YAGNI 보정**: 레이어 구조는 엄격하되, 구현은 최소(ex. 빈 `map()` 메서드는 만들지 않음).
- **예외 없음**: 모든 feature 가 동일한 data/domain/presentation 구조. 단순 CRUD 도 UseCase 작성.

---

## 2. Architecture Options (확정)

### 2.0 Architecture Comparison

| Criteria | Option A: Minimal | Option B: Clean | Option C: Pragmatic |
|----------|:-:|:-:|:-:|
| Approach | 최소 변경 | 풀 클린 3-layer | 3-layer + UseCase 선택 |
| New Files (전체) | ~30 | ~150 | ~90 |
| Modified Files | ~40 | ~58 | ~55 |
| Complexity | Low | High | Medium |
| AI 이해도 | 중 | **상** | 중 |
| Maintainability | Medium | High | High |
| Effort | 2-3주 | 4-6주 | 3-4주 |
| Risk | Low | Medium | Low |
| 예외 없음 | 해당없음 | ✅ | ❌ |

**Selected**: **Option B — Full Clean Architecture**
**Rationale**: AI 이해도·규칙 일관성 최상. UseCase 이름이 의도를 선언해서 grep 1회로 기능 진입점 도달. 단순 CRUD에도 UseCase 를 일괄 적용해 예외 없는 규칙 유지.

### 2.1 Component Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                          │
│  Screen (Widget)  →  Riverpod Provider (Notifier)  →  UseCase   │
└──────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼  (calls)
┌──────────────────────────────────────────────────────────────────┐
│                         Domain Layer                             │
│  UseCase.call() → Repository<abstract> → Entity (pure Dart)     │
└──────────────────────────────────────────────────────────────────┘
                                 ▲  (implements)
                                 │
┌──────────────────────────────────────────────────────────────────┐
│                          Data Layer                              │
│  RepositoryImpl → DataSource (Hive / Supabase / Platform)       │
│                 → Model (DTO, toEntity/fromEntity)               │
└──────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                   ┌──────┬──────┬──────┬────────┐
                   │ Hive │ Supa │ NFC  │ Camera │
                   └──────┴──────┴──────┴────────┘
```

### 2.2 Data Flow (qr_task feature — 레퍼런스 구현)

> **Note (2026-04-16 업데이트)**: 파일럿 feature 를 `history` → `qr_task` 로 변경.
> `qr-task-json-storage` 구현에서 `qr_task` 가 Clean Architecture 첫 완성 피처가 됨.

```
UI (QrResultScreen / HistoryScreen)
  └─ ref.watch(qrTaskListNotifierProvider)
       └─ QrTaskListNotifier
            └─ ListQrTasksUseCase.call()
                 └─ QrTaskRepository.listAll()           [abstract]
                      └─ QrTaskRepositoryImpl.listAll()  [data]
                           └─ HiveQrTaskDataSource.readAll()
                                └─ Hive.box<QrTaskModel>('qr_tasks')
                                     (.toEntity() → QrTask.fromPayloadMap())
                                     ↩ List<QrTaskModel>
                                ↩ List<QrTask> (entity)
                           ↩ Result<Success<List<QrTask>>>
                      ↩ Result<...>
                 ↩ Result<...>
            ↩ AsyncValue<List<QrTask>>
```

### 2.3 Dependencies (DI Graph — qr_task 레퍼런스 구현)

> **Note (2026-04-16 업데이트)**: 실제 구현된 DI 그래프 (`qr_task_providers.dart`) 기준.

| Provider | Type | Provides | Depends On |
|---|---|---|---|
| `qrTaskBoxProvider` | `Provider<Box<QrTaskModel>>` | Hive Box | `hive_config.dart` 에서 박스 오픈 |
| `qrTaskLocalDataSourceProvider` | `Provider<QrTaskLocalDataSource>` | HiveQrTaskDataSource | `qrTaskBoxProvider` |
| `qrTaskRepositoryProvider` | `Provider<QrTaskRepository>` | QrTaskRepositoryImpl (abstract 타입으로 노출) | `qrTaskLocalDataSourceProvider` |
| `createQrTaskUseCaseProvider` | `Provider<CreateQrTaskUseCase>` | UseCase | `qrTaskRepositoryProvider` |
| `listQrTasksUseCaseProvider` | `Provider<ListQrTasksUseCase>` | UseCase | `qrTaskRepositoryProvider` |
| `updateQrTaskCustomizationUseCaseProvider` | `Provider<UpdateQrTaskCustomizationUseCase>` | UseCase | `qrTaskRepositoryProvider` |
| `deleteQrTaskUseCaseProvider` | `Provider<DeleteQrTaskUseCase>` | UseCase | `qrTaskRepositoryProvider` |
| `clearQrTasksUseCaseProvider` | `Provider<ClearQrTasksUseCase>` | UseCase | `qrTaskRepositoryProvider` |
| `qrTaskListNotifierProvider` | `AsyncNotifierProvider<QrTaskListNotifier, List<QrTask>>` | UI state | `listQrTasksUseCaseProvider`, `deleteQrTaskUseCaseProvider`, `clearQrTasksUseCaseProvider` |

**main.dart** 에서 `ProviderScope(overrides: [...])` 로 테스트 시 Repository 대체 가능.

---

## 3. Data Model

### 3.1 Entity Definition (domain, pure Dart)

> **Note (2026-04-16 업데이트)**: `TagHistory` 는 삭제됨. 레퍼런스 엔티티는 `QrTask` 로 교체.
> 구현 파일: `lib/features/qr_task/domain/entities/`

```dart
// lib/features/qr_task/domain/entities/qr_task.dart
/// QR/NFC 1건 작업 기록. 도메인 순수 표현.
class QrTask {
  static const int currentSchemaVersion = 1;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QrTaskKind kind;     // enum: qr | nfc
  final QrTaskMeta meta;     // 앱/링크 메타
  final QrCustomization customization;  // QR 꾸미기 전체
}

// lib/features/qr_task/domain/entities/qr_task_meta.dart
class QrTaskMeta {
  final String appName;
  final String deepLink;
  final String platform;      // 'android' | 'ios' | 'universal'
  final String? packageName;
  final String? appIconBase64; // PNG → Base64
  final String? tagType;       // 'app' | 'clipboard' | ... | 'sms'
}

// lib/features/qr_task/domain/entities/qr_customization.dart
/// QR 꾸미기 상태. 모든 색상은 ARGB int. enum은 String name.
class QrCustomization {
  final int qrColorArgb;           // 0xFF000000
  final QrGradientData? gradient;
  final double roundFactor;        // 0.0~1.0
  final String eyeOuter;           // 'square'|'rounded'|'circle'|'circleRound'|'smooth'
  final String eyeInner;           // 'square'|'circle'|'diamond'|'star'
  final int? randomEyeSeed;
  final int quietZoneColorArgb;    // 0xFFFFFFFF
  final String dotStyle;           // 'square'|'rounded'|'dots'|'classy'|...
  final bool embedIcon;
  final String? centerEmoji;
  final String? centerIconBase64;
  final double printSizeCm;        // 기본 5.0
  final StickerSpec sticker;
  final String? activeTemplateId;

  // toJson() / fromJson() 포함 (dart:core only — 도메인 순수 유지)
}
```

**핵심 설계 원칙** (qr_task 실구현 기준):
- 색상: Flutter `Color` 대신 ARGB int 직접 저장 → 도메인 Flutter 의존 0
- enum: `String name` 저장 → JSON 직렬화 시 외부 패키지 불필요
- `dart:convert` (jsonEncode/Decode) 는 Dart SDK 표준이므로 domain 사용 허용

### 3.2 DTO (data/models, Hive) — JSON-Payload 전략

> **Note (2026-04-16 업데이트)**: `TagHistoryModel` 은 삭제됨. 레퍼런스 DTO는 `QrTaskModel`.
> 구현 파일: `lib/features/qr_task/data/models/qr_task_model.dart`

#### 핵심 설계 결정: 4-필드 Hive + JSON Payload

기존 설계(flat HiveFields)와 달리, 실제 구현은 **JSON payload 전략**을 채택했습니다.

```dart
// lib/features/qr_task/data/models/qr_task_model.dart
@HiveType(typeId: 2)
class QrTaskModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final DateTime createdAt;
  @HiveField(2) final String kind;        // QrTaskKind.name: 'qr' | 'nfc'
  @HiveField(3) final String payloadJson; // 전체 payload JSON 문자열

  // Hive 필드는 4개 고정. 꾸미기 상세는 payloadJson 안에 JSON으로 저장.
  // 향후 새 꾸미기 필드 추가 시 .g.dart 재생성 불필요 → null-cast 위험 0.

  QrTask toEntity() {
    final map = jsonDecode(payloadJson) as Map<String, dynamic>;
    return QrTask.fromPayloadMap(id: id, createdAt: createdAt,
        kind: QrTaskKind.fromName(kind), map: map);
  }

  factory QrTaskModel.fromEntity(QrTask t) => QrTaskModel(
    id: t.id, createdAt: t.createdAt,
    kind: t.kind.name, payloadJson: t.toPayloadJson(),
  );
}
```

**payloadJson 내부 구조** (`schemaVersion: 1`):
```json
{
  "schemaVersion": 1,
  "taskId": "<UUID>",
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601",
  "kind": "qr",
  "meta": { "appName": "...", "deepLink": "...", "platform": "android", ... },
  "customization": { "qrColorArgb": 4278190080, "eyeOuter": "square", ... }
}
```

**이 전략의 장점**:
- Hive 스키마 불변 (필드 4개 고정) → `.g.dart` 재생성 시 기존 레코드 null-cast 위험 0
- 새 꾸미기 필드 추가 = JSON 스키마만 확장, Hive 수정 없음
- `schemaVersion` 으로 마이그레이션 판단 가능 (미래 클라우드 동기화 대비)

**핵심 규칙**:
- DTO는 도메인 Entity의 Hive 직렬화 대응 페어.
- `@HiveType(typeId)`, `@HiveField(N)` 숫자는 기존 값 그대로.
- DTO는 **non-null 기본값을 생성자에 직접 명시**.
- 변환 메서드: `toEntity()`, `fromEntity()`.

### 3.3 전체 Entity–DTO 매핑 표

> **Note (2026-04-16 업데이트)**: TagHistory 삭제됨. QrTask 추가.

| Entity | DTO | Hive typeId | Box name | 상태 |
|---|---|:-:|---|---|
| ~~`TagHistory`~~ | ~~`TagHistoryModel`~~ | ~~0~~ | ~~`tag_history`~~ | **삭제됨** (hive_config에서 box 제거) |
| `UserQrTemplate` | (미이전, `lib/models/`) | 1 | `user_qr_templates` | 레거시, P3 마이그레이션 예정 |
| **`QrTask`** | **`QrTaskModel`** | **2** | **`qr_tasks`** | **완료 (qr-task-json-storage)** |
| `QrTemplate` (default) | (JSON asset) | (none) | assets/default_templates.json | 레거시, P3 에서 domain 이전 예정 |
| `StickerConfig` | (미이전, `lib/models/`) | (none, 값 객체) | — | 레거시, P3 에서 `StickerSpec` 으로 교체됨 |
| `QrDotStyle` | (enum, domain 에 직접) | — | — | 유지 |

---

## 4. Error Handling

### 4.1 Failure 생근타입

```dart
// lib/core/error/failure.dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
class NetworkFailure extends Failure {
  final int? statusCode;
  const NetworkFailure(super.message, {this.statusCode});
}
class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}
class ValidationFailure extends Failure {
  final Map<String, String> fields;
  const ValidationFailure(super.message, {this.fields = const {}});
}
class UnexpectedFailure extends Failure {
  final Object? cause;
  final StackTrace? stackTrace;
  const UnexpectedFailure(super.message, {this.cause, this.stackTrace});
}
```

### 4.2 Result<T> 생근타입

```dart
// lib/core/error/result.dart
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}
class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}

// 확장: fold / map / flatMap
extension ResultExt<T> on Result<T> {
  R fold<R>(R Function(T) onSuccess, R Function(Failure) onErr) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Err(:final failure) => onErr(failure),
      };
}
```

### 4.3 Repository 반환 규칙

- **모든 Repository 메서드는 `Future<Result<T>>` 반환** (void 대신 `Result<void>` 는 `Result<Unit>` 로).
- `throw` 금지. Internal exception 은 Repository 경계에서 캐치 → `Failure` 로 변환.
- Provider/Notifier 는 `Result.fold` 로 Riverpod `AsyncValue` 에 매핑.

### 4.4 UI 매핑

```dart
// 관행: Notifier 내부
state = await useCase().let((result) => result.fold(
  (data) => AsyncValue.data(data),
  (failure) => AsyncValue.error(failure, StackTrace.current),
));
```

---

## 5. Routing (go_router)

### 5.1 Router 정의

```dart
// lib/core/di/router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/qr/:tagId', builder: (_, state) => QrResultScreen(...)),
      GoRoute(path: '/nfc/write', builder: (_, __) => const NfcWriterScreen()),
      // ... 15 features
    ],
    redirect: ref.read(deepLinkRedirectProvider),
  );
});
```

### 5.2 Deep Link 통합

- 기존 `lib/shared/constants/deep_link_constants.dart` → `lib/core/constants/deep_link_constants.dart` 이전.
- `GoRouter.redirect` 로 전역 deep link 파싱 처리.

---

## 6. Test Plan

### 6.1 Test Scope

| Type | Target | Tool |
|------|--------|------|
| Unit Test | UseCase | flutter_test |
| Unit Test | Repository (mocked DataSource) | flutter_test + mocktail |
| Unit Test | Model.toEntity/fromEntity | flutter_test |
| Widget Test | 파일럿 feature screen (골든) | flutter_test |
| Integration Test (수동) | 전체 스모크 | 실기기 |

### 6.2 Test Cases (history feature 예시)

**UseCase 레벨**
- [ ] `GetTagHistoryUseCase` — Repository 가 Success 반환 → Success 전달
- [ ] `GetTagHistoryUseCase` — Repository 가 Err 반환 → Err 전달
- [ ] `DeleteTagHistoryUseCase` — 존재하는 id 삭제 성공
- [ ] `DeleteTagHistoryUseCase` — 존재하지 않는 id 시 StorageFailure
- [ ] `ClearTagHistoryUseCase` — 전체 삭제 후 빈 리스트

**Repository 레벨 (mock DataSource)**
- [ ] `getAll` — DataSource List 반환 → Entity List 변환 성공
- [ ] `getAll` — DataSource throw → StorageFailure 변환
- [ ] `save` — DataSource 정상 put → Success(void)
- [ ] 정렬 순서 (createdAt desc) 보장

**Model 레벨**
- [ ] `TagHistoryModel.toEntity()` 왕복 변환 데이터 손실 없음
- [ ] 구 레코드 (일부 필드 null) 읽기 성공 — 기본값 적용

### 6.3 Coverage 목표

- `features/history/domain/` + `features/history/data/`: ≥ 70%
- 나머지 feature: ≥ 50% (확산 단계에서 추가)

---

## 7. Clean Architecture (핵심)

### 7.1 Layer Structure

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | UI 위젯, Riverpod Notifier, 사용자 입력 처리 | `lib/features/{f}/presentation/{screens,widgets,providers}/` |
| **Domain** | Entity, Repository 추상, UseCase | `lib/features/{f}/domain/{entities,repositories,usecases}/` |
| **Data** | Repository Impl, DataSource, DTO | `lib/features/{f}/data/{repositories,datasources,models}/` |
| **Core (Shared)** | Failure/Result, 공통 유틸, DI root, 라우터 | `lib/core/{error,di,constants,utils,widgets}/` |

### 7.2 Dependency Rules

```
┌────────────────────────────────────────────────────────────────┐
│                       의존 방향                                 │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│    Presentation ──→ Domain ←── Data                           │
│          │            ↑                                        │
│          └──→ core/   │                                        │
│                       │                                        │
│    Data ──→ core/                                              │
│                                                                │
│    ❌ Domain 은 그 무엇도 import 하지 않음                      │
│       (Hive, Flutter, HTTP, Riverpod, 다른 feature 전부 금지)   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 7.3 File Import Rules

| From | Can Import | Cannot Import |
|------|-----------|---------------|
| `presentation/` | 같은 feature 의 `domain/`, `core/` | 같은 feature 의 `data/`, 다른 feature |
| `data/` | 같은 feature 의 `domain/`, `core/`, 외부 패키지 (hive, supabase 등) | `presentation/`, 다른 feature |
| `domain/` | (nothing, pure Dart only) | Flutter, Hive, Riverpod, 다른 feature, `data/`, `presentation/` |
| `core/` | Flutter, 외부 패키지 | feature 내부 |

**강제 수단**: 리뷰 체크리스트 + Optional: `dart_code_metrics` 의 `avoid-non-null-assertion`, `no-boolean-literal-compare` 외 custom rule.

### 7.4 Feature Assignment (16 features)

> **Note (2026-04-16 업데이트)**: `qr_task` 추가 (완료). `history` 상태 변경.

모두 동일 3-layer 구조:

```
lib/features/
├── qr_task/           ✅ 완료 (qr-task-json-storage) — Clean Architecture 레퍼런스
├── history/           ⚠ presentation만 존재, domain/data 없음 (HistoryScreen이 qr_task에 cross-feature 의존)
├── qr_result/         🔄 P3 (qr_task 통합 후 재구성 예정)
├── nfc_writer/
├── app_picker/
├── home/
├── clipboard_tag/
├── contact_tag/
├── email_tag/
├── event_tag/
├── help/
├── ios_input/
├── location_tag/
├── output_selector/
├── sms_tag/
├── website_tag/
└── wifi_tag/
```

**⚠ history feature 아키텍처 결정 필요**:
현재 `history_screen.dart` 는 `qr_task/domain/entities/` 와 `qr_task/presentation/providers/` 를 직접 import (cross-feature 의존). 설계 규칙(7.3) 위반.
옵션: (a) history 를 `qr_task/presentation/screens/` 로 병합, (b) 독립 도메인 유지하되 `core/` 로 공통 엔티티 이전

각 feature 내부:

```
{feature}/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

## 8. Coding Convention

### 8.1 Naming (엄격 suffix)

| Kind | Rule | Example |
|---|---|---|
| Entity | PascalCase (suffix 없음) | `TagHistory`, `UserQrTemplate` |
| DTO | `{Entity}Model` | `TagHistoryModel` |
| DataSource abstract | `{Entity}LocalDataSource`, `{Entity}RemoteDataSource` | `TagHistoryLocalDataSource` |
| DataSource impl | `Hive{Entity}DataSource`, `Supabase{Entity}DataSource` | `HiveTagHistoryDataSource` |
| Repository abstract | `{Entity}Repository` | `TagHistoryRepository` |
| Repository impl | `{Entity}RepositoryImpl` | `TagHistoryRepositoryImpl` |
| UseCase | `{Verb}{Noun}UseCase` | `GetTagHistoryUseCase`, `SaveQrToGalleryUseCase` |
| Provider (DI) | `{name}Provider` (camelCase) | `tagHistoryRepositoryProvider` |
| Notifier | `{Noun}Notifier` | `HistoryListNotifier` |
| Screen | `{Noun}Screen` | `HistoryScreen` |
| Widget | PascalCase | `HistoryListItem` |
| File | snake_case.dart | `get_tag_history_usecase.dart` |

### 8.2 UseCase 패턴

```dart
// 표준 형태
class GetTagHistoryUseCase {
  final TagHistoryRepository _repository;
  const GetTagHistoryUseCase(this._repository);

  Future<Result<List<TagHistory>>> call() => _repository.getAll();
}
```

**룰**:
- 단일 `call()` 메서드.
- 파라미터는 값 객체 또는 positional. 3개 이상이면 `Params` 클래스.
- 본문 ≤ 20줄.
- Side-effect 순수 — Repository/다른 UseCase 만 호출.

### 8.3 Import Order (Dart)

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:typed_data';

// 2. Flutter / 외부 패키지
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// 3. core (앱 내부, 절대 경로)
import 'package:app_tag/core/error/result.dart';

// 4. 같은 feature 내부 (절대 경로 권장)
import 'package:app_tag/features/history/domain/entities/tag_history.dart';

// 5. 상대 경로 (부득이한 경우)
import '../models/tag_history_model.dart';
```

### 8.4 Environment / Secrets

| Item | Location | Note |
|---|---|---|
| Supabase URL/AnonKey | `lib/core/di/supabase_config.dart` (dart-define 주입) | 현재 하드코드 가능성, 검증 필요 |
| Default templates | `assets/default_templates.json` | 그대로 유지 |

---

## 9. Implementation Guide

### 9.1 파일 구조 (파일럿 history 완성 시)

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_config.dart
│   │   └── deep_link_constants.dart
│   ├── di/
│   │   ├── app_providers.dart      # 공통 Provider root
│   │   ├── hive_config.dart        # Hive 초기화
│   │   ├── supabase_config.dart
│   │   └── router.dart             # GoRouter
│   ├── error/
│   │   ├── failure.dart
│   │   └── result.dart
│   ├── utils/
│   │   └── tag_payload_encoder.dart
│   └── widgets/
│       └── output_action_buttons.dart
│
├── features/
│   └── history/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── tag_history_local_datasource.dart   (abstract)
│       │   │   └── hive_tag_history_datasource.dart    (impl)
│       │   ├── models/
│       │   │   ├── tag_history_model.dart              (@HiveType 0)
│       │   │   └── tag_history_model.g.dart            (generated)
│       │   └── repositories/
│       │       └── tag_history_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── tag_history.dart                    (pure Dart)
│       │   ├── repositories/
│       │   │   └── tag_history_repository.dart         (abstract)
│       │   └── usecases/
│       │       ├── get_tag_history_usecase.dart
│       │       ├── save_tag_history_usecase.dart
│       │       ├── delete_tag_history_usecase.dart
│       │       └── clear_tag_history_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── history_providers.dart              (DI graph)
│           │   └── history_list_notifier.dart
│           ├── screens/
│           │   └── history_screen.dart
│           └── widgets/
│               └── history_list_item.dart
│
└── main.dart
```

### 9.2 Implementation Order (Phase 단위)

#### P0 — 기반 ✅ 완료

1. [x] `lib/core/error/failure.dart` — Failure sealed class
2. [x] `lib/core/error/result.dart` — Result<T> sealed class + fold/map/flatMap extension
3. [x] `lib/core/di/app_providers.dart` — 공통 Provider root
4. [x] `lib/core/di/hive_config.dart` — `initHive()` (Hive.initFlutter + adapter 등록)
5. [x] `lib/core/di/supabase_config.dart` — SupabaseClient Provider
6. [x] `lib/shared/*` → `lib/core/{constants,utils,widgets}/` 이전
7. [x] `main.dart` 리팩토링 — ProviderScope overrides 패턴 적용
8. [x] `flutter analyze` 통과
9. [x] 기기 스모크 테스트

#### P1 — 파일럿 qr_task ✅ 완료 (qr-task-json-storage 로 구현됨)

> **Note**: 파일럿 feature 가 `history` → `qr_task` 로 변경됨 (2026-04-16).
> `history` 는 presentation-only 레이어로 남겨두고 `qr_task` 엔티티를 재사용.

10. [x] `features/qr_task/domain/entities/` — QrTask, QrTaskMeta, QrCustomization, QrGradientData, StickerSpec, QrTaskKind
11. [x] `features/qr_task/domain/repositories/qr_task_repository.dart` — abstract (6개 메서드)
12. [x] `features/qr_task/domain/usecases/` — Create/GetById/List/UpdateCustomization/Delete/Clear (6개)
13. [x] `features/qr_task/data/datasources/qr_task_local_datasource.dart` — abstract
14. [x] `features/qr_task/data/datasources/hive_qr_task_datasource.dart` — Hive impl
15. [x] `features/qr_task/data/models/qr_task_model.dart` — @HiveType(2), JSON payload 전략
16. [x] `build_runner build` → `qr_task_model.g.dart` 생성
17. [x] `features/qr_task/data/repositories/qr_task_repository_impl.dart`
18. [x] `features/qr_task/presentation/providers/qr_task_providers.dart` — DI graph
19. [x] `features/qr_task/presentation/providers/qr_task_list_notifier.dart`
20. [x] `features/qr_result/qr_result_provider.dart` — debounced autosave 통합
21. [x] `lib/features/qr_result/utils/customization_mapper.dart` — QrResultState ↔ QrCustomization
22. [x] 실기기: QrTask 저장/복원 동작 확인

#### P2 — go_router ✅ 완료

25. [x] `go_router` 의존성 추가 (pubspec.yaml)
26. [x] `lib/core/di/router.dart` — GoRouter 정의 (16 route, qr_task 포함)
27. [x] `main.dart`: `MaterialApp.router(routerConfig: ref.watch(appRouterProvider))`
28. [x] 모든 `Navigator.push` → `context.push()` / `context.go()` 치환
29. [x] deep link redirect 로직 통합
30. [x] `lib/app/router.dart` 삭제

#### P3 — qr_result ✅ 완료

31. [x] Entity 추출: `UserQrTemplate` (domain/entities)
32. [x] DTO: `UserQrTemplateModel` (**@HiveType(1) 유지**, data/models)
33. [x] Repository 인터페이스 + Impl: `UserTemplateRepository`, `DefaultTemplateRepository`, `QrOutputRepository`
34. [x] UseCase 해체:
  - `GetUserTemplatesUseCase`, `SaveUserTemplateUseCase`, `DeleteUserTemplateUseCase`
  - `GetDefaultTemplatesUseCase`, `LoadTemplateImageUseCase`
  - `SaveQrToGalleryUseCase`, `ShareQrImageUseCase`, `PrintQrCodeUseCase`
35. [x] presentation/providers: 6 data + 9 usecase + 1 FutureProvider
36. [x] 기존 `template_service.dart`, `user_template_repository.dart`, `template_repository.dart`, `user_qr_template.dart`, `user_qr_template.g.dart` 삭제
37. [x] `qr_result_provider.dart`, `qr_result_screen.dart`, `all_templates_tab.dart`, `my_templates_tab.dart` — usecase 기반으로 전환

#### P4 — nfc_writer ✅ 완료

38. [x] Entity: `NfcWriteResult` (domain/entities)
39. [x] DataSource: `NfcDataSource` (abstract) + `NfcManagerDataSource` (nfc_manager 래핑)
40. [x] Repository: `NfcRepository` (abstract) + `NfcRepositoryImpl` (Completer 패턴으로 callback→async 변환)
41. [x] UseCase: `WriteNfcTagUseCase`, `CheckNfcAvailabilityUseCase`
42. [x] `ndef_record_helper.dart` → `nfc_writer/data/` 로 이동
43. [x] `nfc_writer_provider.dart` — Ref 기반 usecase 호출로 전환
44. [x] presentation/providers: 5 providers (dataSource, repository, 2 usecases)

#### P5 — 나머지 features ✅ 완료

> **실 대상**: app_picker, home, output_selector (3개 실질 리팩터링).
> 나머지 9개 form screens (clipboard, contact, email, event, help, ios_input, location, sms, website, wifi)는
> 이미 레거시 서비스/모델 의존 없이 깔끔한 상태 — 변경 불필요.
> `history`는 qr_task CA 레이어를 직접 import하여 이미 정리됨.

45. [x] `app_picker/` — Full CA: domain/entities/app_info.dart, domain/repositories/, domain/usecases/get_installed_apps_usecase.dart, data/datasources/app_list_datasource.dart (device_apps 래핑), data/repositories/app_picker_repository_impl.dart, presentation/providers/app_picker_providers.dart
46. [x] `app_picker/` — NFC availability providers: nfc_writer CA 레이어 재사용 (`nfcAvailableProvider`, `nfcWriteSupportedProvider`)
47. [x] `home/` — `SettingsService` 를 `core/services/settings_service.dart` 로 이동
48. [x] `output_selector/` — import를 app_picker 새 CA providers로 변경
49. [x] `qr_result/qr_result_screen.dart`, `tabs/sticker_tab.dart` — SettingsService import 업데이트
50. [x] 레거시 파일 삭제: `lib/services/nfc_service.dart`, `lib/models/app_info.dart`, `lib/services/settings_service.dart`
51. [x] `flutter analyze lib/` — 0 errors (info/warning only, 모두 기존)

#### P6 — 정리 ✅ 완료

> 모든 레거시 파일을 CA 구조로 이동 완료.

56. [x] `lib/models/` 3개 파일 → `features/qr_result/domain/entities/` 이동: qr_template.dart, qr_dot_style.dart, sticker_config.dart
57. [x] `lib/services/qr_service.dart`, `qr_readability_service.dart` → `features/qr_result/data/services/` 이동
58. [x] `lib/services/supabase_service.dart` → `core/services/` 이동
59. [x] 레거시 디렉토리 전부 삭제: `lib/services/`, `lib/models/`, `lib/repositories/`, `lib/shared/`
60. [x] 전체 import 업데이트 (20+ 파일)
61. [x] `flutter analyze` 0 errors (10 pre-existing info/warnings only)

#### P7 — 검증 (1-2일)

61. [ ] 실기기 업그레이드 테스트 (기존 버전 → 신 버전, 데이터 유지)
62. [ ] 릴리즈 빌드 성공 (Android)
63. [ ] 15개 화면 수동 스모크

### 9.3 의존성 추가

```yaml
# pubspec.yaml (추가)
dependencies:
  go_router: ^14.0.0       # P2

dev_dependencies:
  mocktail: ^1.0.3          # P1 (테스트)
```

---

## 10. Risks & Mitigation (설계 단계 보강)

| Risk | Mitigation (설계 차원) |
|---|---|
| DTO 생성 어댑터가 manual patch 덮어씀 | DTO 클래스에 **non-null 필드 + 생성자 기본값** 명시. 구 레코드에서 해당 필드가 없어도 Hive 가 생성자 기본값 사용. (현 `UserQrTemplate` 의 생성자 default 은 있으나 `.g.dart` 가 `as double` 로 재캐스트하므로 fail — DTO 전환 후 필드 타입을 nullable 로 바꾸거나 `dynamic?? default` 패턴 적용) |
| Entity enum 변환 실패 (구 데이터의 platform 문자열이 enum 에 없음) | `TagPlatform.values.byName()` 대신 `_parsePlatform(String)` 함수 + unknown 시 `android` fallback |
| Riverpod provider graph 변경 중 무한 루프 / 초기화 순서 오류 | `ProviderScope` overrides 로만 DI. Hive 초기화는 `FutureProvider` 로 래핑, UI 는 `ref.watch(hiveInitProvider).when(...)` |
| feature 간 전이 의존 (예: history → qr_result) | 공통 Entity (TagHistory) 는 `core/` 이관하거나, feature 경계 재정의. P1 파일럿 중 이 경우 감지되면 Design 보강 |
| `qr_result` 의 5개 탭이 qr_result/presentation 에 몰려 비대 | 탭별 sub-widget 폴더 `presentation/widgets/tabs/` 로 분리 |

---

## 11. Migration Checklist (feature 당 반복)

각 feature 마이그레이션 시 적용:

- [ ] domain/entities 생성 (pure Dart)
- [ ] domain/repositories 추상 작성
- [ ] domain/usecases N개 작성 (모든 동작 1:1)
- [ ] data/models DTO 생성 (@HiveType 숫자 유지)
- [ ] data/datasources abstract + impl 분리
- [ ] data/repositories Impl (`Result<T>` 반환, exception → Failure 변환)
- [ ] presentation/providers DI graph (Repository 추상 타입으로 노출)
- [ ] presentation/providers Notifier (UseCase 만 의존)
- [ ] presentation/screens 이전
- [ ] 단위 테스트 (최소 UseCase 1개 + Repository 1개)
- [ ] 기존 service/repository/model 파일 삭제
- [ ] 기기 스모크 테스트

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-15 | Initial draft (Option B 선택 후) | tawool83 |
| 0.2 | 2026-04-16 | qr-task-json-storage 구현 반영: 파일럿 history→qr_task 교체, TagHistory 삭제, QrTaskModel JSON-payload 전략 문서화, DI 그래프 업데이트, 구현 순서 P0/P1 완료 처리, 피처 목록에 qr_task 추가 | tawool83 |
| 0.3 | 2026-04-17 | P2~P5 완료 반영: go_router 도입, qr_result 3-layer + usecase 해체, nfc_writer CA(Completer 패턴), app_picker CA(device_apps DS), SettingsService core/ 이전, 레거시 파일 삭제(nfc_service, app_info, settings_service, ndef_record_helper, template files) | tawool83 |
| 0.4 | 2026-04-17 | P6 완료: 잔여 레거시 6개 파일 CA 이동(qr_template/qr_dot_style/sticker_config → domain/entities, qr_service/qr_readability_service → data/services, supabase_service → core/services). lib/services/, lib/models/, lib/repositories/ 전부 삭제. flutter analyze 0 errors | tawool83 |
