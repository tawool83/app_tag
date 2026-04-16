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

### 2.2 Data Flow (history feature 예시)

```
UI (HistoryScreen)
  └─ ref.watch(historyListProvider)
       └─ historyListNotifierProvider
            └─ GetTagHistoryUseCase.call()
                 └─ TagHistoryRepository.getAll()      [abstract]
                      └─ TagHistoryRepositoryImpl.getAll()  [data]
                           └─ HiveTagHistoryDataSource.readAll()
                                └─ Hive.box<TagHistoryModel>
                                     (읽기 후 .toEntity() 변환)
                                     ↩ List<TagHistoryModel>
                                ↩ List<TagHistory> (entity)
                           ↩ Result<Success<List<TagHistory>>>
                      ↩ Result<...>
                 ↩ Result<...>
            ↩ AsyncValue<List<TagHistory>>
       ↩ build(TagHistory items)
```

### 2.3 Dependencies (DI Graph)

| Provider | Type | Provides | Depends On |
|---|---|---|---|
| `hiveProvider` | `Provider<HiveInterface>` | Hive 인스턴스 | — |
| `supabaseClientProvider` | `Provider<SupabaseClient>` | Supabase | — |
| `tagHistoryLocalDataSourceProvider` | `Provider<TagHistoryLocalDataSource>` | Local DS | hiveProvider |
| `tagHistoryRepositoryProvider` | `Provider<TagHistoryRepository>` | RepoImpl (abstract 타입으로 노출) | tagHistoryLocalDataSourceProvider |
| `getTagHistoryUseCaseProvider` | `Provider<GetTagHistoryUseCase>` | UseCase | tagHistoryRepositoryProvider |
| `historyListNotifierProvider` | `StateNotifierProvider<HistoryListNotifier, AsyncValue<...>>` | UI state | getTagHistoryUseCaseProvider, deleteTagHistoryUseCaseProvider, clearTagHistoryUseCaseProvider |

**main.dart** 에서 `ProviderScope(overrides: [...])` 로 테스트 시 Repository 대체 가능.

---

## 3. Data Model

### 3.1 Entity Definition (domain, pure Dart)

```dart
// lib/features/history/domain/entities/tag_history.dart
import 'dart:typed_data';

/// 도메인 엔티티. Hive/JSON 무관. 비즈니스 의미만 보유.
class TagHistory {
  final String id;
  final String appName;
  final String deepLink;
  final TagPlatform platform;    // enum
  final TagOutputType outputType; // enum
  final DateTime createdAt;
  final String? packageName;
  final Uint8List? appIconBytes;
  final QrCustomization? qr;     // 값 객체로 묶음
  final double? printSizeCm;
  final TagType? tagType;        // enum

  const TagHistory({
    required this.id,
    required this.appName,
    required this.deepLink,
    required this.platform,
    required this.outputType,
    required this.createdAt,
    this.packageName,
    this.appIconBytes,
    this.qr,
    this.printSizeCm,
    this.tagType,
  });
}

enum TagPlatform { android, ios }
enum TagOutputType { qr, nfc }
enum TagType { app, clipboard, website, contact, wifi, location, event, email, sms }

class QrCustomization {
  final String? label;
  final int? color;
  final String? eyeShape;
  final String? dataModuleShape;
  final bool? embedIcon;
  final String? centerEmoji;
  final double? roundFactor;
  const QrCustomization({...});
}
```

### 3.2 DTO (data/models, Hive)

```dart
// lib/features/history/data/models/tag_history_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/tag_history.dart';

part 'tag_history_model.g.dart';

@HiveType(typeId: 0)  // ⚠ 기존 typeId 유지
class TagHistoryModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String appName;
  @HiveField(2) final String deepLink;
  @HiveField(3) final String platform;
  @HiveField(4) final String outputType;
  @HiveField(5) final DateTime createdAt;
  @HiveField(6) final String? packageName;
  @HiveField(7) final Uint8List? appIconBytes;
  @HiveField(8) final String? qrLabel;
  @HiveField(9) final int? qrColor;
  @HiveField(10) final double? printSizeCm;
  @HiveField(11) final String? tagType;
  @HiveField(12) final String? qrEyeShape;
  @HiveField(13) final String? qrDataModuleShape;
  @HiveField(14) final bool? qrEmbedIcon;
  @HiveField(15) final String? qrCenterEmoji;
  @HiveField(16) final double? qrRoundFactor;

  TagHistoryModel({...});

  // Entity 변환
  TagHistory toEntity() => TagHistory(
    id: id,
    appName: appName,
    deepLink: deepLink,
    platform: TagPlatform.values.byName(platform),
    outputType: TagOutputType.values.byName(outputType),
    createdAt: createdAt,
    packageName: packageName,
    appIconBytes: appIconBytes,
    qr: _hasQrCustomization ? QrCustomization(...) : null,
    printSizeCm: printSizeCm,
    tagType: tagType == null ? null : TagType.values.byName(tagType!),
  );

  factory TagHistoryModel.fromEntity(TagHistory e) => TagHistoryModel(...);
}
```

**핵심 규칙**:
- DTO는 도메인 Entity의 Hive 직렬화 대응 페어.
- `@HiveType(typeId)`, `@HiveField(N)` 숫자는 기존 값 그대로.
- DTO는 **non-null 기본값을 생성자에 직접 명시** (생성 어댑터가 재생성되어도 null-cast 안 터지도록).
- 변환 메서드: `toEntity()`, `fromEntity()`.

### 3.3 전체 Entity–DTO 매핑 표

| Entity | DTO | Hive typeId | Box name |
|---|---|:-:|---|
| `TagHistory` | `TagHistoryModel` | 0 | `tag_history` |
| `UserQrTemplate` | `UserQrTemplateModel` | 1 | `user_qr_templates` |
| `QrTemplate` (default) | `QrTemplateModel` | (none, JSON asset) | assets/default_templates.json |
| `AppInfo` | `AppInfoModel` | (none, runtime) | — |
| `StickerConfig` | `StickerConfigModel` | (none, 값 객체) | — |
| `BackgroundConfig` | `BackgroundConfigModel` | (none, 값 객체) | — |
| `QrDotStyle` | (enum, domain 에 직접) | — | — |

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

### 7.4 Feature Assignment (15 features)

모두 동일 3-layer 구조:

```
lib/features/
├── history/           (파일럿)
├── qr_result/
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

#### P0 — 기반 (2-3일)

1. [ ] `lib/core/error/failure.dart` — Failure sealed class
2. [ ] `lib/core/error/result.dart` — Result<T> sealed class + fold extension
3. [ ] `lib/core/di/app_providers.dart` — 공통 Provider root
4. [ ] `lib/core/di/hive_config.dart` — `initHive()` (Hive.initFlutter + adapter 등록)
5. [ ] `lib/core/di/supabase_config.dart` — SupabaseClient Provider
6. [ ] `lib/shared/*` → `lib/core/{constants,utils,widgets}/` 이전 (import 경로 업데이트)
7. [ ] `main.dart` 리팩토링 — ProviderScope overrides 패턴 적용 (Hive/Supabase init 을 core/di 로 이동)
8. [ ] `flutter analyze` 통과
9. [ ] 기기 스모크 테스트

#### P1 — 파일럿 history (2-3일)

10. [ ] `features/history/domain/entities/tag_history.dart` — pure Dart Entity + enums
11. [ ] `features/history/domain/repositories/tag_history_repository.dart` — abstract
12. [ ] `features/history/domain/usecases/` 4개: Get/Save/Delete/Clear
13. [ ] `features/history/data/datasources/tag_history_local_datasource.dart` — abstract
14. [ ] `features/history/data/datasources/hive_tag_history_datasource.dart` — Hive impl
15. [ ] `features/history/data/models/tag_history_model.dart` — @HiveType(0), toEntity/fromEntity
16. [ ] `build_runner build` → `tag_history_model.g.dart` 생성
17. [ ] `features/history/data/repositories/tag_history_repository_impl.dart`
18. [ ] `features/history/presentation/providers/history_providers.dart` — DI graph
19. [ ] `features/history/presentation/providers/history_list_notifier.dart`
20. [ ] `features/history/presentation/screens/history_screen.dart` (기존에서 이전)
21. [ ] `lib/services/history_service.dart` 삭제, 호출부 교체
22. [ ] `lib/models/tag_history.dart` 삭제 (DTO 로 이관 완료)
23. [ ] 단위 테스트 작성 (`test/features/history/`)
24. [ ] 실기기: 기존 데이터 정상 로드 + 삭제/클리어 동작 확인

#### P2 — go_router (1-2일)

25. [ ] `go_router` 의존성 추가
26. [ ] `lib/core/di/router.dart` — GoRouter 정의 (15 route)
27. [ ] `main.dart`: `MaterialApp.router(routerConfig: ref.watch(appRouterProvider))`
28. [ ] 모든 `Navigator.push` → `context.push()` / `context.go()` 치환
29. [ ] deep link redirect 로직 통합
30. [ ] `lib/app/router.dart` 삭제

#### P3 — qr_result (3-5일)

31. [ ] Entity 추출: `UserQrTemplate`, `QrTemplate`, `StickerConfig`, `BackgroundConfig`, `QrDotStyle`
32. [ ] DTO: `UserQrTemplateModel` (**@HiveType(1) 유지**)
33. [ ] Repository 인터페이스 + Impl (user template, default template)
34. [ ] UseCase 해체:
  - `GetUserTemplatesUseCase`, `SaveUserTemplateUseCase`, `DeleteUserTemplateUseCase`
  - `GetDefaultTemplatesUseCase`
  - `CaptureQrImageUseCase` (QrService 에서 분리)
  - `SaveQrToGalleryUseCase`
  - `ShareQrImageUseCase`
  - `PrintQrCodeUseCase`
  - `AnalyzeQrReadabilityUseCase` (qr_readability_service 에서)
35. [ ] presentation: 5개 탭 (shape/color/background/sticker/text) 정리
36. [ ] 기존 `qr_service.dart`, `template_service.dart`, `user_template_repository.dart`, `qr_template.dart`, `user_qr_template.dart` 삭제
37. [ ] 실기기: 템플릿 저장/로드, 기존 데이터 마이그레이션, QR 저장/공유/프린트 검증

#### P4 — nfc_writer (2일)

38. [ ] Entity: `NfcTag` (if needed)
39. [ ] DataSource: `NfcPlatformDataSource` (nfc_manager 래핑)
40. [ ] UseCase: `WriteNfcTagUseCase`, `CheckNfcAvailabilityUseCase`
41. [ ] 기존 `nfc_service.dart`, `ndef_record_helper.dart` 제거
42. [ ] 기기: NFC 쓰기 검증

#### P5 — 나머지 12 features (7-10일)

각 feature 1 PR:
43. [ ] `app_picker/` (device_apps 플랫폼 DS)
44. [ ] `home/`
45. [ ] `clipboard_tag/`
46. [ ] `contact_tag/` (flutter_contacts 플랫폼 DS)
47. [ ] `email_tag/`
48. [ ] `event_tag/`
49. [ ] `help/`
50. [ ] `ios_input/`
51. [ ] `location_tag/` (flutter_map, geolocator 플랫폼 DS)
52. [ ] `output_selector/`
53. [ ] `sms_tag/`
54. [ ] `website_tag/`
55. [ ] `wifi_tag/`

#### P6 — 정리 (1-2일)

56. [ ] 낡은 디렉토리 삭제: `lib/services/`, `lib/repositories/`, `lib/models/`, `lib/shared/`
57. [ ] 남은 import 정리
58. [ ] `build_runner build --delete-conflicting-outputs`
59. [ ] DTO non-null 기본값 검증 (구 레코드 null cast 회귀 없음)
60. [ ] `flutter analyze` 0 issues

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
