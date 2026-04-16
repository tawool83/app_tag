---
template: design
version: 1.2
feature: qr-task-json-storage
date: 2026-04-15
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# qr-task-json-storage Design Document

> **Summary**: Option C (Pragmatic SOT) 채택. `QrTaskPayload` (JSON) 이 영속·재방문 차원의 단일 진실, `QrResultState` 는 런타임 미러. 각 setter 마다 state+payload 동시 갱신, debounced Hive persist. 히스토리 탭 시 payload → state 하이드레이트로 편집 복원.
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Author**: tawool83
> **Date**: 2026-04-15
> **Status**: Draft
> **Planning Doc**: [qr-task-json-storage.plan.md](../../01-plan/features/qr-task-json-storage.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. **영속 SOT = JSON**: 앱 재시작·히스토리 재방문 시 JSON payload 에서 상태 복원.
2. **Hive 스키마 불변**: build_runner 재생성 시 null-cast 재발 불가 구조 (QrTaskModel 은 4개 고정 필드).
3. **UI 성능 유지**: 슬라이더·컬러피커 연속 변경에도 재파싱 없이 빠른 rebuild.
4. **편집 복원 UX**: 히스토리 탭 → QrResultScreen 진입 시 이전 작업 이어서 편집.
5. **확장성**: 새 꾸미기 필드 추가 시 JSON 스키마만 확장, Hive 건드리지 않음.

### 1.2 Design Principles

- **SRP**: QrTaskPayload (직렬화), QrTaskModel (Hive DTO), QrResultState (UI), QrResultNotifier (편집 상태 관리) — 각 1 책임.
- **Payload first, state mirrors**: 양방향이지만 JSON 이 authoritative 저장 포맷.
- **Debounce write**: 500ms — 연속 이벤트 → 1 write.
- **Schema versioning**: `schemaVersion: 1` 고정, 향후 증가 시 migration logic.
- **No legacy compat**: 기존 TagHistory Hive box 폐기.

---

## 2. Architecture Options (확정)

### 2.0 Comparison

| Criteria | A Minimal | B Full JSON-first | C Pragmatic SOT |
|---|:---:|:---:|:---:|
| 구현 기간 | 3-4d | 7-10d | 5-7d |
| JSON SOT (영속) | ☐ | ✅ | ✅ |
| UI 성능 | ✅ | ☐ | ✅ |
| Riverpod 친화 | ✅ | ☐ | ✅ |
| build_runner 재발 위험 | 0 | 0 | 0 |

**Selected**: **Option C — Pragmatic SOT**
**Rationale**: 사용자 의도(JSON 먼저 저장 → JSON 기준 표시) 영속 차원에서 충족 + UI 성능 유지 + 기존 Riverpod 구조 호환.

### 2.1 Component Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                          │
│                                                                 │
│  QrResultScreen / BackgroundTab(제거)/ QrShapeTab/ QrColorTab /  │
│  StickerTab / TextTab / TemplateTab                             │
│                     ↕  (ref.watch)                              │
│  QrResultNotifier (StateNotifier<QrResultState>)                │
│    - 기존 setter 는 그대로 (성능)                                │
│    - 각 setter 끝에서 _pushToPayload() 호출                       │
│    - 500ms debounced → QrTaskRepository.updateCustomization    │
│                                                                 │
│  HistoryListNotifier (StateNotifier<List<QrTask>>)             │
│    - QrTask.list() 구독, 탭 시 editTaskId 전달                    │
└────────────────────────────────────────────────────────────────┘
                            ↕
┌────────────────────────────────────────────────────────────────┐
│                     Domain Layer                                │
│                                                                 │
│  QrTask (Entity)                                                │
│    - id, createdAt, updatedAt, kind, meta, customization       │
│  QrTaskRepository (abstract)                                    │
│    - createNew(meta) / getById / listAll / update / delete     │
│  UseCases (단일 call())                                          │
│    - CreateQrTaskUseCase                                        │
│    - UpdateQrTaskCustomizationUseCase                           │
│    - GetQrTaskByIdUseCase                                       │
│    - ListQrTasksUseCase                                         │
│    - DeleteQrTaskUseCase                                        │
│    - ClearQrTasksUseCase                                        │
└────────────────────────────────────────────────────────────────┘
                            ↕
┌────────────────────────────────────────────────────────────────┐
│                     Data Layer                                  │
│                                                                 │
│  QrTaskPayload (JSON Map 변환 전용 value object)                 │
│  QrTaskModel (Hive DTO, typeId=2)                              │
│    - @HiveField(0) id: String                                   │
│    - @HiveField(1) createdAt: DateTime                          │
│    - @HiveField(2) kind: String  ('qr' | 'nfc')                │
│    - @HiveField(3) payloadJson: String  ← JSON 전체              │
│  toEntity(): JSON decode → QrTaskPayload → QrTask              │
│  fromEntity(): QrTask → payload toJson → String                │
│                                                                 │
│  QrTaskLocalDataSource (abstract) / HiveQrTaskDataSource       │
│  QrTaskRepositoryImpl (Result<Failure,T> 반환)                  │
└────────────────────────────────────────────────────────────────┘
                            ↕
                  Hive box 'qr_tasks' (typeId=2)
```

### 2.2 Data Flow (편집 중 autosave)

```
슬라이더 조작 (roundFactor 변경)
  → QrResultNotifier.setRoundFactor(0.3)
    - state = state.copyWith(roundFactor: 0.3)  (즉시, UI rebuild)
    - _schedulePayloadPush()  (debounce 500ms)
  ... 300ms 뒤 또 변경 (0.4)
    - state = state.copyWith(roundFactor: 0.4)
    - _schedulePayloadPush()  (타이머 reset)
  500ms 후 실행:
    - payload = QrTaskPayload.fromState(state, currentTask)
    - await updateQrTaskCustomizationUseCase(taskId, payload)
      - repo → Hive put(QrTaskModel with payloadJson)
  저장 완료 → 실패 시 silent retry (다음 변경 때 기회)
```

### 2.3 Data Flow (히스토리 탭 → 편집 복원)

```
HistoryScreen 에서 QrTask tap
  → Navigator.push(QrResultScreen, args: { editTaskId })
  → QrResultScreen.initState
    - args['editTaskId'] != null 분기
    - await getQrTaskByIdUseCase(editTaskId)
    - state = QrResultState.fromPayload(task.customization, meta=task.meta)
    - tabController.jumpTo(기본 탭)
  편집 계속 → 같은 taskId 로 debounced update
```

---

## 3. Data Model

### 3.1 JSON Schema v1

```json
{
  "schemaVersion": 1,
  "taskId": "uuid-v4",
  "createdAt": "2026-04-15T12:30:00.000Z",
  "updatedAt": "2026-04-15T12:31:20.000Z",
  "kind": "qr",
  "meta": {
    "appName": "클립보드",
    "deepLink": "text or url ...",
    "platform": "android|ios|universal",
    "packageName": null,
    "appIconBase64": null,
    "tagType": "clipboard"
  },
  "customization": {
    "qrColorArgb": 4278190080,
    "gradient": null,
    "roundFactor": 0.0,
    "eyeOuter": "square",
    "eyeInner": "square",
    "randomEyeSeed": null,
    "quietZoneColorArgb": 4294967295,
    "dotStyle": "square",
    "embedIcon": false,
    "centerEmoji": null,
    "centerIconBase64": null,
    "printSizeCm": 5.0,
    "sticker": {
      "logoPosition": "center",
      "logoBackground": "none",
      "topText": null,
      "bottomText": {
        "content": "...",
        "colorArgb": 4278190080,
        "fontFamily": "sans-serif",
        "fontSize": 14.0
      }
    },
    "activeTemplateId": null
  }
}
```

**규약**
- `schemaVersion`: 최상단 필수. 현재 `1`.
- `Color` → int (ARGB, 예: Colors.black = 4278190080)
- `Enum` → String (name). 파싱 시 unknown → default 로 fallback.
- `DateTime` → ISO 8601.
- 이미지 → `*Base64` 접미사. null 허용.
- 모든 optional 필드: `fromJson` 에서 기본값 제공 → 누락 OK.

### 3.2 Entity / DTO / Value Object

```dart
// lib/features/qr_task/domain/entities/qr_task.dart
class QrTask {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QrTaskKind kind;            // enum (qr, nfc)
  final QrTaskMeta meta;
  final QrCustomization customization;
  const QrTask({...});
}

enum QrTaskKind { qr, nfc }

class QrTaskMeta {
  final String appName;
  final String deepLink;
  final String platform;
  final String? packageName;
  final String? appIconBase64;
  final String? tagType;
  const QrTaskMeta({...});
}

class QrCustomization {
  final int qrColorArgb;
  final QrGradient? gradient;
  final double roundFactor;
  final QrEyeOuter eyeOuter;
  final QrEyeInner eyeInner;
  final int? randomEyeSeed;
  final int quietZoneColorArgb;
  final QrDotStyle dotStyle;
  final bool embedIcon;
  final String? centerEmoji;
  final String? centerIconBase64;
  final double printSizeCm;
  final StickerSpec sticker;
  final String? activeTemplateId;
  const QrCustomization({...});
}

class StickerSpec {
  final LogoPosition logoPosition;
  final LogoBackground logoBackground;
  final StickerText? topText;
  final StickerText? bottomText;
  const StickerSpec({...});
}
```

```dart
// lib/features/qr_task/data/models/qr_task_model.dart
@HiveType(typeId: 2)
class QrTaskModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final DateTime createdAt;
  @HiveField(2) final String kind;          // 'qr' | 'nfc'
  @HiveField(3) final String payloadJson;   // JSON 전체 (meta+customization+schemaVersion+updatedAt)

  QrTaskModel({...});

  QrTask toEntity() {
    final map = jsonDecode(payloadJson) as Map<String, dynamic>;
    return QrTask(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.parse(map['updatedAt'] as String? ?? createdAt.toIso8601String()),
      kind: QrTaskKind.values.byName(kind),
      meta: QrTaskMeta.fromJson(map['meta'] as Map<String, dynamic>),
      customization: QrCustomization.fromJson(map['customization'] as Map<String, dynamic>),
    );
  }

  factory QrTaskModel.fromEntity(QrTask t) => QrTaskModel(
    id: t.id,
    createdAt: t.createdAt,
    kind: t.kind.name,
    payloadJson: jsonEncode({
      'schemaVersion': 1,
      'taskId': t.id,
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': t.updatedAt.toIso8601String(),
      'kind': t.kind.name,
      'meta': t.meta.toJson(),
      'customization': t.customization.toJson(),
    }),
  );
}
```

**Hive 스키마 불변 핵심**: `payloadJson` 은 하나의 String 필드. 내부 구조 변경 시 `@HiveField` 추가 불필요 → `.g.dart` 재생성해도 null-cast 위험 0.

### 3.3 Entity ↔ State 매핑

```dart
// lib/features/qr_result/presentation/providers/qr_result_notifier.dart
extension QrResultStateFromPayload on QrResultState {
  static QrResultState fromPayload(QrCustomization c) => QrResultState(
    qrColor: Color(c.qrColorArgb),
    customGradient: c.gradient,
    roundFactor: c.roundFactor,
    eyeOuter: c.eyeOuter,
    eyeInner: c.eyeInner,
    randomEyeSeed: c.randomEyeSeed,
    quietZoneColor: Color(c.quietZoneColorArgb),
    dotStyle: c.dotStyle,
    embedIcon: c.embedIcon,
    centerEmoji: c.centerEmoji,
    // centerIconBase64 → emojiIconBytes: base64Decode
    printSizeCm: c.printSizeCm,
    sticker: c.sticker.toStickerConfig(),
    activeTemplateId: c.activeTemplateId,
    // background 필드 제거
  );

  QrCustomization toCustomization() => QrCustomization(
    qrColorArgb: qrColor.toARGB32(),
    gradient: customGradient,
    roundFactor: roundFactor,
    eyeOuter: eyeOuter,
    eyeInner: eyeInner,
    randomEyeSeed: randomEyeSeed,
    quietZoneColorArgb: quietZoneColor.toARGB32(),
    dotStyle: dotStyle,
    embedIcon: embedIcon,
    centerEmoji: centerEmoji,
    centerIconBase64: emojiIconBytes != null ? base64Encode(emojiIconBytes!) : null,
    printSizeCm: printSizeCm,
    sticker: StickerSpec.fromStickerConfig(sticker),
    activeTemplateId: activeTemplateId,
  );
}
```

**규약**: `state ↔ payload.customization` 양방향 변환 순수함수. 두 방향 왕복 시 무손실 (Uint8List 는 Base64 왕복 허용 — 같은 bytes 복원).

---

## 4. API / Repository

### 4.1 QrTaskRepository

```dart
abstract class QrTaskRepository {
  Future<Result<QrTask>> createNew({
    required QrTaskKind kind,
    required QrTaskMeta meta,
  });
  Future<Result<QrTask?>> getById(String id);
  Future<Result<List<QrTask>>> listAll();  // 최신순
  Future<Result<void>> updateCustomization(String id, QrCustomization c);
  Future<Result<void>> updateMeta(String id, QrTaskMeta meta);
  Future<Result<void>> delete(String id);
  Future<Result<void>> clearAll();
}
```

### 4.2 UseCase 목록

| UseCase | Params | Returns | Notes |
|---|---|---|---|
| `CreateQrTaskUseCase` | `kind, meta` | `Result<QrTask>` | 화면 진입 시 1회 |
| `GetQrTaskByIdUseCase` | `id` | `Result<QrTask?>` | 히스토리 탭 시 복원 |
| `ListQrTasksUseCase` | — | `Result<List<QrTask>>` | 히스토리 화면 |
| `UpdateQrTaskCustomizationUseCase` | `id, QrCustomization` | `Result<void>` | debounced autosave |
| `UpdateQrTaskMetaUseCase` | `id, QrTaskMeta` | `Result<void>` | (향후) 이름 변경 등 |
| `DeleteQrTaskUseCase` | `id` | `Result<void>` | |
| `ClearQrTasksUseCase` | — | `Result<void>` | |

---

## 5. UI/UX Design

### 5.1 화면 변화

- **HistoryScreen**: `TagHistory` → `QrTask` 기반 재구성. 탭 시 `Navigator.pushNamed('/qr-result', arguments: {'editTaskId': task.id})`.
- **QrResultScreen**: `editTaskId` 분기 추가 — 신규 vs 편집 복원.
- **BackgroundTab**: **제거** (탭 바에서 삭제).
- **데이터 폐기 Alert**: 앱 업데이트 최초 실행 시 모달 "이전 히스토리가 삭제되었습니다. 새 JSON 구조로 업그레이드됩니다."

### 5.2 탭 바 재구성

```
Before (6 탭): 템플릿 / 배경 / 모양 / 색상 / 로고 / 텍스트
After  (5 탭): 템플릿 / 모양 / 색상 / 로고 / 텍스트
```

`TabController(length: 6 → 5)`, tabs 리스트에서 background 제거.

### 5.3 History Tile (변경점)

- 탭 시 `/output-selector` 가 아니라 `/qr-result?editTaskId=...` 로 직행.
- `_HistoryTile` 의 `onTap` 만 교체.

---

## 6. Error Handling

- Hive put 실패 → `StorageFailure`.
- JSON 파싱 실패 (schemaVersion 알 수 없음 등) → `UnexpectedFailure` + UI alert "데이터를 읽을 수 없습니다".
- 앞으로 `schemaVersion > 1` 레코드 만나면: 읽기 실패 처리하되 해당 레코드만 스킵, 전체 리스트는 표시.

---

## 7. Test Plan

### 7.1 Test Scope

| Type | Target | Tool |
|---|---|---|
| Unit | `QrTaskPayload.fromJson/toJson` 왕복 | flutter_test |
| Unit | `QrCustomization` ↔ `QrResultState` 왕복 | flutter_test |
| Unit | UseCase 각 (mock Repo) | mocktail |
| Unit | Repository Impl (mock DataSource) | mocktail |
| Integration (수동) | 전체 플로우 (생성→꾸미기→재진입→편집) | 실기기 |

### 7.2 Key Test Cases

- [ ] `QrTaskPayload` 왕복: 모든 필드 포함 → JSON 인코딩/디코딩 결과 동일
- [ ] Unknown enum value → default 로 fallback
- [ ] 누락된 optional 필드 → default 적용
- [ ] `state → customization → state` 왕복 불변
- [ ] Base64 이미지 왕복 (32×32 PNG): bytes 동일
- [ ] Create → getById: 같은 QrTask 반환
- [ ] Update → listAll: updatedAt desc 정렬 반영
- [ ] ClearAll 후 listAll → 빈 리스트

---

## 8. Clean Architecture Layout

### 8.1 File Structure

```
lib/features/
├── qr_task/                               ← 신규 feature (QR + NFC 통합 기록)
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── qr_task_local_datasource.dart    (abstract)
│   │   │   └── hive_qr_task_datasource.dart
│   │   ├── models/
│   │   │   ├── qr_task_model.dart               (@HiveType 2, 4 fields)
│   │   │   └── qr_task_model.g.dart             (generated)
│   │   └── repositories/
│   │       └── qr_task_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── qr_task.dart                      (Entity)
│   │   │   ├── qr_task_meta.dart                 (value object)
│   │   │   ├── qr_customization.dart             (value object + fromJson/toJson)
│   │   │   ├── qr_task_kind.dart                 (enum)
│   │   │   └── sticker_spec.dart                 (value object)
│   │   ├── repositories/
│   │   │   └── qr_task_repository.dart
│   │   └── usecases/
│   │       ├── create_qr_task_usecase.dart
│   │       ├── get_qr_task_by_id_usecase.dart
│   │       ├── list_qr_tasks_usecase.dart
│   │       ├── update_qr_task_customization_usecase.dart
│   │       ├── delete_qr_task_usecase.dart
│   │       └── clear_qr_tasks_usecase.dart
│   └── presentation/
│       ├── providers/
│       │   ├── qr_task_providers.dart            (DI graph)
│       │   └── qr_task_list_notifier.dart        (히스토리용)
│       └── screens/
│           └── (history_screen.dart 재사용 — 새 위치? or 유지)
│
├── history/                               ← 삭제 또는 qr_task 로 합병
│   └── (P1 결과물 → 본 feature 에서 대체)
│
└── qr_result/                             ← Notifier 만 확장
    └── presentation/
        └── providers/
            └── qr_result_notifier.dart
            (- _pushToPayload() debounced
             - fromPayload() 하이드레이트)
```

### 8.2 History feature 처리

**결정**: P1 의 `features/history/` 는 **삭제**. `features/qr_task/presentation/screens/history_screen.dart` 에서 새로 구현.
- 이유: TagHistory 폐기 → history feature 도 QrTask 기반으로 재작성 필요. 이름은 여전히 "history" 이나 도메인은 QrTask.

### 8.3 Dependency Rules (재확인)

- `presentation` → `domain` + `core`
- `data` → `domain` + `core` + Hive
- `domain` → 외부 의존 0

---

## 9. Coding Convention

### 9.1 Naming

| Kind | Example |
|---|---|
| Entity | `QrTask`, `QrCustomization` |
| DTO | `QrTaskModel` (Hive) |
| UseCase | `CreateQrTaskUseCase`, `UpdateQrTaskCustomizationUseCase` |
| Provider | `qrTaskRepositoryProvider`, `createQrTaskUseCaseProvider` |
| Notifier | `QrTaskListNotifier` |
| JSON key | camelCase (예: `printSizeCm`, `centerIconBase64`) |

### 9.2 JSON 규약 (본 feature 확립)

- `schemaVersion` 필수, 첫 필드
- Enum → `.name` String, 파싱은 `values.asNameMap()[s] ?? defaultValue`
- Color → int (ARGB)
- DateTime → ISO 8601 UTC
- 이미지 → `*Base64`
- 모든 optional → null 허용 + default 있는 `fromJson`

---

## 10. Implementation Order (Plan Roadmap → Design 세부)

| Phase | 산출물 | Key Files |
|---|---|---|
| **P0 — JSON schema + 테스트** | 스키마 문서, `QrCustomization`, `QrTaskMeta`, fromJson/toJson, 왕복 테스트 | `domain/entities/qr_customization.dart`, `test/features/qr_task/domain/...` |
| **P1 — 엔티티/DataSource/Repo/UseCase** | Entity, QrTaskModel (typeId=2), Repo Impl, 6 UseCase, DI graph, hive_config 업데이트 | `features/qr_task/data/*`, `features/qr_task/domain/*`, `presentation/providers/qr_task_providers.dart`, `core/di/hive_config.dart` |
| **P2 — 배경 이미지 UI 제거** | `background_tab.dart` 삭제, `BackgroundConfig` 삭제, `QrResultState.background` 제거, TabController 6→5 | `features/qr_result/tabs/`, `qr_result_provider.dart`, `qr_result_screen.dart`, `qr_layer_stack.dart` |
| **P3 — QrResultNotifier JSON-mirror 통합** | setter 에 `_pushToPayload` 추가, 500ms debounce 저장, `fromPayload` 하이드레이트 | `features/qr_result/presentation/providers/qr_result_notifier.dart` (신규), `qr_result_screen.dart` |
| **P4 — NFC 통합** | `nfc_writer_screen.dart` 에서 `CreateQrTaskUseCase(kind=nfc)` 사용 | `features/nfc_writer/nfc_writer_screen.dart` |
| **P5 — 히스토리 재작성** | `features/history/` 삭제, `features/qr_task/presentation/screens/history_screen.dart` 신설, 탭 시 `/qr-result?editTaskId=...` | `features/qr_task/presentation/*`, `lib/app/router.dart` |
| **P6 — 레거시 정리** | `features/history/` 삭제, TagHistory 관련 파일 삭제, Hive `tag_history` box 삭제 로직, alert UX | `features/history/*` 전부, `core/di/hive_config.dart` |
| **P7 — 통합 QA** | 전체 플로우 수동 QA, 릴리즈 빌드 | — |

각 Phase 종료 시 `flutter analyze` + 단위 테스트 통과.

---

## 11. Risks & Mitigation (설계 단계 보강)

| Risk | Mitigation |
|---|---|
| `state ↔ payload` 미러 불일치 | `toCustomization() → fromPayload()` 왕복 불변 테스트 필수 |
| Debounce 도중 앱 종료로 마지막 편집 유실 | 허용 (UX 허용 범위, 사용자 결정) + 화면 이탈 직전 flush 시도 |
| Hive box 2개 (qr_tasks + user_qr_templates) 공존 | `user_qr_templates` 는 그대로 유지 (독립 feature). typeId 1/2 분리 |
| Base64 로고 누적 용량 | 로고 해상도 256×256 cap, PNG 8KB 이내 권장. 실측 후 필요시 추가 압축 |
| TagHistory 폐기에 대한 사용자 반발 | 업데이트 최초 실행 시 Dialog: "개인화·복원 기능을 위해 이력 저장 구조가 업그레이드되었습니다. 이전 이력은 제거되었습니다." |
| build_runner 재생성이 `qr_task_model.g.dart` 만들 때 문제 | QrTaskModel 은 id/createdAt/kind/payloadJson 4개 단순 필드 — 확장 없음. null-cast 리스크 0 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-15 | Initial draft (Option C 선택 후) | tawool83 |
