---
template: design
version: 1.0
feature: refactor-qr-result-state
date: 2026-04-20
author: tawool83
project: app_tag
---

# refactor-qr-result-state Design Document

> **Summary**: `QrResultState` 26-field god-state 를 Clean Architecture 기반 5개 sub-state composite 로 재설계. Presentation 계층의 state 를 관심사별로 분리하고, Riverpod `.select()` 기반 렌더 최적화까지 포함.
>
> **Project**: AppTag
> **Planning Doc**: [refactor-qr-result-state.plan.md](../../01-plan/features/refactor-qr-result-state.plan.md)
> **Selected Architecture**: **Option B — Clean Architecture** (사용자 명시 선택)

---

## 1. Overview

### 1.1 Design Goals
- 관심사별 sub-state 완전 분리 (단일 책임)
- 각 sub-state는 독립 파일, 독립 테스트 가능
- 평탄 필드 0개 달성 (composite 만 유지)
- `_sentinel` 수동 패턴 완전 제거
- `ref.watch(provider.select((s) => s.style))` 기반 리빌드 최소화
- 다른 sub-state import 금지 (flat composition)

### 1.2 Design Principles
- **SRP (단일 책임)**: 각 sub-state 는 한 관심사만 표현
- **불변성**: const constructor + copyWith (no setters)
- **값 동등성**: `==`/`hashCode` 모든 sub-state 필수
- **조합 가능성**: 외부(`QrResultState`)에서만 조합, sub-state 간 상호 의존 금지
- **하위 호환**: Hive 영속 JSON 스키마 동일 — 변환은 `CustomizationMapper` 단일 경계

---

## 2. Architecture Options Comparison

| 기준 | Option A — Minimal | **Option B — Clean (선택)** | Option C — Pragmatic |
|------|-------------------|------------------------------|----------------------|
| 구조 | 단일 파일, flat 유지 | **5개 sub-state 독립 파일** | 2~3 묶음 (action+meta / style / logo+template) |
| 파일 수 | 1 (변화 없음) | **+5 파일** | +2~3 파일 |
| `_sentinel` 제거 | ❌ | **✅** | 부분 |
| 테스트 격리 | 어려움 | **쉬움** | 보통 |
| 리빌드 최적화 여지 | 낮음 | **높음** (`select` 잘 작동) | 중간 |
| 작업량 | 2h | **5.5~7h** | 3~4h |
| 유지보수성 | 나쁨 | **우수** | 보통 |
| 회귀 리스크 | 낮음 | 중간(75곳 touch) | 낮음~중간 |

**선택 사유**: 장기 유지보수 + 렌더 성능 + 테스트 격리가 모두 중요한 시점. 75 call-site 마이그레이션 비용 1회 지불하고 영구적 이득 확보.

---

## 3. Sub-State Design

### 3.1 디렉터리 구조

```
lib/features/qr_result/domain/state/          (신규)
├── qr_action_state.dart                      # 5 필드: save/share/print status, error, bytes
├── qr_style_state.dart                       # 12 필드: color/dot/eye/boundary/animation/gradient
├── qr_logo_state.dart                        # 4 필드: embed flag + bytes/emoji
├── qr_template_state.dart                    # 3 필드: active id + template override
└── qr_meta_state.dart                        # 3 필드: tagType, printSize, editorMode flag

lib/features/qr_result/qr_result_provider.dart (축소, ~500줄)
  - QrResultState (composite): 6 필드 (5 sub-state + sticker)
  - QrResultNotifier
```

### 3.2 각 Sub-State 정의

#### 3.2.1 `QrActionState`

```dart
class QrActionState {
  final Uint8List? capturedImage;    // RepaintBoundary 캡처 결과
  final QrActionStatus saveStatus;   // idle / loading / success / error
  final QrActionStatus shareStatus;
  final QrActionStatus printStatus;
  final String? errorMessage;

  const QrActionState({
    this.capturedImage,
    this.saveStatus = QrActionStatus.idle,
    this.shareStatus = QrActionStatus.idle,
    this.printStatus = QrActionStatus.idle,
    this.errorMessage,
  });

  QrActionState copyWith({
    Uint8List? capturedImage,
    QrActionStatus? saveStatus,
    QrActionStatus? shareStatus,
    QrActionStatus? printStatus,
    Object? errorMessage = _sentinel,  // local sentinel 제거 — bool clearError 플래그로 대체
  }) { ... }

  // ==/hashCode: Object.hash(capturedImage, saveStatus, shareStatus, printStatus, errorMessage)
}
```

**설계 포인트**:
- `capturedImage`는 Uint8List 참조 equality 만 비교 (deep equality 불필요)
- `errorMessage` null 처리: `clearError: bool` 플래그 도입으로 sentinel 제거

#### 3.2.2 `QrStyleState`

```dart
class QrStyleState {
  final Color qrColor;
  final double roundFactor;
  final QrEyeOuter eyeOuter;
  final QrEyeInner eyeInner;
  final int? randomEyeSeed;
  final QrGradient? customGradient;
  final QrDotStyle dotStyle;
  final DotShapeParams? customDotParams;
  final EyeShapeParams? customEyeParams;
  final QrBoundaryParams boundaryParams;
  final QrAnimationParams animationParams;
  final Color quietZoneColor;

  const QrStyleState({
    this.qrColor = const Color(0xFF000000),
    this.roundFactor = 0.0,
    this.eyeOuter = QrEyeOuter.square,
    this.eyeInner = QrEyeInner.square,
    this.randomEyeSeed,
    this.customGradient,
    this.dotStyle = QrDotStyle.square,
    this.customDotParams,
    this.customEyeParams,
    this.boundaryParams = const QrBoundaryParams(),
    this.animationParams = const QrAnimationParams(),
    this.quietZoneColor = const Color(0xFFFFFFFF),
  });

  QrStyleState copyWith({ ... }); // nullable 필드는 bool clearXxx 플래그 패턴
  // ==/hashCode 포함
}
```

**설계 포인트**:
- 가장 큰 sub-state (12 필드) — 자주 변경되는 핵심 스타일 상태
- `ref.watch(qrResultProvider.select((s) => s.style))` 로 전 QR 미리보기 위젯이 이 sub-state 만 구독하도록 변경 → 다른 sub-state 변경 시 리빌드 제외

#### 3.2.3 `QrLogoState`

```dart
class QrLogoState {
  final bool embedIcon;
  final Uint8List? defaultIconBytes;   // 태그 타입 기본 아이콘
  final String? centerEmoji;
  final Uint8List? emojiIconBytes;

  const QrLogoState({
    this.embedIcon = false,
    this.defaultIconBytes,
    this.centerEmoji,
    this.emojiIconBytes,
  });

  QrLogoState copyWith({ ... });
  // ==/hashCode
}
```

#### 3.2.4 `QrTemplateState`

```dart
class QrTemplateState {
  final String? activeTemplateId;
  final QrGradient? templateGradient;
  final Uint8List? templateCenterIconBytes;

  const QrTemplateState({
    this.activeTemplateId,
    this.templateGradient,
    this.templateCenterIconBytes,
  });

  QrTemplateState copyWith({ ... });
  // ==/hashCode
  
  bool get hasActiveTemplate => activeTemplateId != null;
}
```

#### 3.2.5 `QrMetaState`

```dart
class QrMetaState {
  final String? tagType;
  final double printSizeCm;
  final bool shapeEditorMode;

  const QrMetaState({
    this.tagType,
    this.printSizeCm = 5.0,
    this.shapeEditorMode = false,
  });

  QrMetaState copyWith({ ... });
  // ==/hashCode
}
```

### 3.3 Composite `QrResultState`

```dart
class QrResultState {
  final QrActionState action;
  final QrStyleState style;
  final QrLogoState logo;
  final QrTemplateState template;
  final QrMetaState meta;
  final StickerConfig sticker;

  const QrResultState({
    this.action = const QrActionState(),
    this.style = const QrStyleState(),
    this.logo = const QrLogoState(),
    this.template = const QrTemplateState(),
    this.meta = const QrMetaState(),
    this.sticker = const StickerConfig(),
  });

  factory QrResultState.initial({
    required String? tagType,
    required Color qrColor,
    Uint8List? defaultIconBytes,
    bool embedIcon = false,
  }) => QrResultState(
    style: QrStyleState(qrColor: qrColor),
    logo: QrLogoState(embedIcon: embedIcon, defaultIconBytes: defaultIconBytes),
    meta: QrMetaState(tagType: tagType),
  );

  QrResultState copyWith({
    QrActionState? action,
    QrStyleState? style,
    QrLogoState? logo,
    QrTemplateState? template,
    QrMetaState? meta,
    StickerConfig? sticker,
  }) => QrResultState(
    action: action ?? this.action,
    style: style ?? this.style,
    logo: logo ?? this.logo,
    template: template ?? this.template,
    meta: meta ?? this.meta,
    sticker: sticker ?? this.sticker,
  );

  @override
  bool operator ==(Object o) => identical(this, o) ||
      o is QrResultState && action == o.action && style == o.style &&
      logo == o.logo && template == o.template && meta == o.meta &&
      sticker == o.sticker;

  @override
  int get hashCode => Object.hash(action, style, logo, template, meta, sticker);
}
```

**크기**: ~30줄 (이전 ~150줄 대비 80% 감소)

---

## 4. Migration Strategy (3 Phase)

### 4.1 Phase A — Sub-state 정의 + Bridge getter

**목표**: 기존 빌드 깨뜨리지 않고 신규 sub-state 사용 가능하게

1. `lib/features/qr_result/domain/state/` 디렉터리 생성
2. 5개 sub-state 파일 작성 (const class + copyWith + ==/hashCode)
3. 기존 `QrResultState` 에 **getter bridge** 추가:
   ```dart
   class QrResultState {
     // 기존 26개 flat 필드 그대로 유지
     final QrActionStatus saveStatus;
     // ...
     
     // 신규: composite view 제공 (bridge)
     QrActionState get action => QrActionState(
       capturedImage: capturedImage,
       saveStatus: saveStatus,
       shareStatus: shareStatus,
       printStatus: printStatus,
       errorMessage: errorMessage,
     );
     QrStyleState get style => QrStyleState(qrColor: qrColor, ...);
     QrLogoState get logo => QrLogoState(...);
     QrTemplateState get template => QrTemplateState(...);
     QrMetaState get meta => QrMetaState(...);
   }
   ```
4. **검증**: `flutter analyze` 통과 — 기존 code 정상 동작, 신규 코드는 `state.style.qrColor` 사용 가능

**산출**: 6개 신규 파일 + `qr_result_provider.dart` 에 5개 getter 추가. **기존 75 call-site 영향 없음.**

### 4.2 Phase B — Read-site 점진 마이그레이션

**목표**: 모든 `state.xxx` → `state.subState.xxx` 변환

파일 단위로 순차 진행 (각 파일 완료 후 커밋 권장):

| 순서 | 파일 | 예상 변경 | 이유 |
|----|------|----------|------|
| 1 | `customization_mapper.dart` | 내부 매핑만 | 가장 집중된 단일 책임, 바닥 계층 |
| 2 | `logo_editors/logo_*.dart` | 2~3곳 | 작은 범위, 독립적 |
| 3 | `text_tab.dart` | 소수 | 스티커 텍스트 전용 |
| 4 | `sticker_tab.dart` | 중간 | `sticker`/`logo`/`meta` 접근 |
| 5 | `qr_color_tab.dart` | 중간 | `style.customGradient`, `style.qrColor` |
| 6 | `qr_shape_tab.dart` + 10 parts | 다수 | `style.*` 집중 |
| 7 | `qr_preview_section.dart` | 다수 | 렌더 핵심 — ValueKey도 sub-state 기반 |
| 8 | `qr_layer_stack.dart` | 중간 | 렌더 핵심 |
| 9 | `qr_result_screen.dart` + 2 parts | 다수 | 화면 진입점 |
| 10 | `all_templates_tab.dart`, `my_templates_tab.dart` | 소수 | 템플릿 관련 |

**검증**: 각 파일 완료마다 `flutter analyze`. Phase B 전체 완료 후 실기기 스모크 1회.

### 4.3 Phase C — Flat 필드 제거 + Notifier 재작성

**목표**: `QrResultState` 를 6-field composite 로 축소, setter 내부 재구현

1. `QrResultState` 의 기존 26개 flat 필드 및 bridge getter **삭제**
2. 생성자를 composite 기반으로 교체 (§3.3)
3. `QrResultNotifier` 의 모든 setter 를 sub-state touch 로 교체:
   ```dart
   // Before
   void setQrColor(Color c) {
     state = state.copyWith(qrColor: c);
   }
   
   // After
   void setQrColor(Color c) {
     state = state.copyWith(style: state.style.copyWith(qrColor: c));
   }
   ```
4. `_sentinel` 패턴 제거 — nullable clear 는 `bool clearXxx` 플래그로 (§3.2.1)
5. `CustomizationMapper.fromState/loadFromCustomization` 내부 필드 경로 재매핑

**검증**: `flutter analyze` 통과 + Gap 분석 ≥ 90%.

### 4.4 Phase D — Performance `select` 전환 (선택)

**목표**: 주요 소비자 위젯이 필요한 sub-state 만 구독

대상 우선순위:
1. `qr_preview_section.dart` → `ref.watch(qrResultProvider.select((s) => s.style))`
2. `qr_layer_stack.dart` → `ref.watch(qrResultProvider.select((s) => (s.style, s.logo)))`
3. `qr_shape_tab.dart` → `ref.watch(qrResultProvider.select((s) => s.style))`
4. `qr_color_tab.dart` → `ref.watch(qrResultProvider.select((s) => s.style.customGradient))`
5. `_ActionButtons` → `ref.watch(qrResultProvider.select((s) => s.action))`

**측정 지표** (NFR-02):
- 애니메이션 QR 편집 중 `qr_preview_section` 빌드 횟수 before/after
- 목표: 50% 이상 감소

---

## 5. Cross-cutting Concerns

### 5.1 JSON 영속 호환 (FR-06)

**불변 원칙**: Hive 저장 스키마 (`customizationJson`, `qr_templates_cache` box 등) 는 **변경 없음**.

변환 경계:
- `CustomizationMapper.fromState(QrResultState state)`:
  ```dart
  // Before
  Customization(qrColor: state.qrColor.toARGB32(), ...)
  // After
  Customization(qrColor: state.style.qrColor.toARGB32(), ...)
  ```
- `QrResultNotifier.loadFromCustomization(Customization c)`:
  ```dart
  // Before
  state = state.copyWith(qrColor: Color(c.qrColorArgb), eyeOuter: ..., ...);
  // After
  state = state.copyWith(style: state.style.copyWith(qrColor: Color(c.qrColorArgb), eyeOuter: ...));
  ```

### 5.2 Null 처리 — Sentinel 제거 (FR-07)

**Before** (global `_sentinel`):
```dart
static const _sentinel = Object();
QrResultState copyWith({ Object? errorMessage = _sentinel, ... }) {
  return QrResultState(
    errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
    ...
  );
}
```

**After** (clear 플래그):
```dart
QrActionState copyWith({
  Uint8List? capturedImage,
  QrActionStatus? saveStatus,
  QrActionStatus? shareStatus,
  QrActionStatus? printStatus,
  String? errorMessage,
  bool clearError = false,
}) => QrActionState(
  capturedImage: capturedImage ?? this.capturedImage,
  saveStatus: saveStatus ?? this.saveStatus,
  shareStatus: shareStatus ?? this.shareStatus,
  printStatus: printStatus ?? this.printStatus,
  errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
);
```

사용처:
```dart
// 에러 기록
state = state.copyWith(action: state.action.copyWith(errorMessage: 'Failed'));
// 에러 클리어
state = state.copyWith(action: state.action.copyWith(clearError: true));
```

### 5.3 `==` / `hashCode` 구현

각 sub-state:
```dart
@override
bool operator ==(Object o) => identical(this, o) ||
    o is QrStyleState &&
    o.qrColor == qrColor && o.roundFactor == roundFactor &&
    // ... 모든 필드
    ;

@override
int get hashCode => Object.hash(
  qrColor, roundFactor, eyeOuter, eyeInner, randomEyeSeed,
  customGradient, dotStyle, customDotParams, customEyeParams,
  boundaryParams, animationParams, quietZoneColor,
);
```

`Uint8List` 필드는 참조 equality 만 — 렌더링 경로에서 이미 Expando 캐시가 처리.

### 5.4 ValueKey 재구성

`qr_preview_section.dart:357` 의 `Object.hash(isDialog, deepLink, state.dotStyle, state.customDotParams, ...)` 를 sub-state 기반으로 교체:

```dart
// Before
final qrKey = ValueKey(Object.hash(
  isDialog, deepLink,
  state.dotStyle, state.customDotParams, state.eyeOuter,
  state.eyeInner, state.randomEyeSeed, state.qrColor,
  state.embedIcon, centerImage != null,
  state.templateGradient, state.customGradient, state.activeTemplateId,
));

// After (더 단순)
final qrKey = ValueKey(Object.hash(
  isDialog, deepLink, centerImage != null,
  state.style, state.template, state.logo.embedIcon,
));
```

`QrStyleState` 자체의 `hashCode` 가 모든 style 필드를 반영하므로 개별 나열 불필요.

---

## 6. Testing Strategy

### 6.1 Unit Tests (신규)

각 sub-state 최소 테스트:
- `copyWith` 동일 값 → `==` 반환
- `copyWith` 한 필드만 변경 → 다른 필드 보존
- nullable clear 플래그 동작
- `hashCode` consistency with `==`

파일: `test/features/qr_result/domain/state/{name}_state_test.dart`

### 6.2 Integration / Regression (FR-11)

실기기 스모크 7종 (Plan §6):
1. 도트 모양 편집
2. 눈 모양 랜덤
3. 외곽 모양 편집
4. 애니메이션 편집
5. 색상 그라디언트
6. 로고 embed
7. 템플릿 저장 후 복원

### 6.3 Performance (NFR-02)

개발 모드에서 `qr_preview_section` 빌드 카운트 측정:
```dart
@override
Widget build(...) {
  debugPrint('[rebuild] qr_preview_section ${++_rebuildCount}');
  ...
}
```

Before 베이스라인 측정 → Phase D 후 재측정 → 50% 이상 감소 확인.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Phase A getter 가 매번 sub-state 인스턴스 생성 → 과도한 GC | 일시적 — Phase C 에서 완전 제거됨. 측정상 문제없으면 무시 |
| Phase B 중 일부 call-site 누락 | `flutter analyze` 로 타입 에러 검출, 파일 단위 grep 체크리스트 |
| Hive 스키마 호환 실패 | `CustomizationMapper` 단일 경계 유지 + 기존 저장 데이터 복원 테스트 |
| Sub-state 내 하나에 다른 sub-state 참조 유혹 | Code review 체크리스트: `import '../state/qr_*.dart';` 가 동일 파일 내 1줄인지 확인 |
| `select` 전환 시 예상치 못한 리빌드 누락 (기능 오류) | Phase D 는 선택 단계. 문제 발견 시 바로 `ref.watch` 전체로 복귀 |

---

## 8. File List Summary

### 8.1 신규 파일 (6)
| 파일 | 예상 크기 |
|------|----------|
| `domain/state/qr_action_state.dart` | ~60줄 |
| `domain/state/qr_style_state.dart` | ~130줄 |
| `domain/state/qr_logo_state.dart` | ~55줄 |
| `domain/state/qr_template_state.dart` | ~50줄 |
| `domain/state/qr_meta_state.dart` | ~50줄 |
| `qr_result_provider.dart` (축소) | ≤500줄 (현 ~650줄) |

### 8.2 수정 파일 (10+)
Phase B 대상 (§4.2 표):
- `customization_mapper.dart`
- `logo_editors/logo_image_editor.dart`, `logo_library_editor.dart`
- `text_tab.dart`, `sticker_tab.dart`, `qr_color_tab.dart`
- `qr_shape_tab.dart` + 10 parts
- `qr_preview_section.dart`, `qr_layer_stack.dart`
- `qr_result_screen.dart` + 2 parts
- `all_templates_tab.dart`, `my_templates_tab.dart`

---

## 9. Success Criteria (Plan 재확인)

- [ ] 6 신규 파일 생성, 각 sub-state 독립
- [ ] `QrResultState` composite 6필드로 축소
- [ ] `qr_result_provider.dart` ≤ 500줄
- [ ] 75 read-site 전부 마이그레이션 (`state.xxx` flat 접근 0개)
- [ ] `_sentinel` 전역 상수 제거
- [ ] 모든 sub-state `==`/`hashCode` 보유
- [ ] Hive JSON 스키마 동일 유지
- [ ] `flutter analyze` 에러 0건
- [ ] 실기기 7종 스모크 테스트 통과
- [ ] Gap 분석 Match Rate ≥ 90%
- [ ] (선택 D) 5곳 이상 `select` 전환

---

## 10. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-04-20 | Initial design — Option B (Clean Architecture) 선택, 5 sub-state 분해 + 3-phase migration 상세화 | tawool83 |
