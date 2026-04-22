# Design: template-data-completeness

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | 템플릿 데이터 완전성 + 버전 관리 |
| Plan 참조 | `docs/01-plan/features/template-data-completeness.plan.md` |
| 작성일 | 2026-04-23 |

---

## 1. Architecture

### 1.1 변경 대상 디렉터리 트리

```
lib/features/qr_result/
├── domain/
│   └── entities/
│       ├── user_qr_template.dart          # [수정] 5필드 추가
│       └── template_engine_version.dart   # [신규] 엔진 버전 상수
├── data/
│   └── models/
│       ├── user_qr_template_model.dart    # [수정] HiveField 38~42
│       └── user_qr_template_model.g.dart  # [재생성] build_runner
├── notifier/
│   └── template_setters.dart              # [수정] applyUserTemplate 3필드 복원
├── tabs/
│   └── my_templates_tab.dart              # [수정] 비호환 템플릿 UI
└── qr_result_screen.dart                  # [수정] 저장 시 3필드+버전 포함
```

### 1.2 데이터 흐름

```
[저장 흐름]
QrResultState.style ──snapshot──→ UserQrTemplate ──Hive DTO──→ UserQrTemplateModel ──persist──→ Hive Box
  .customDotParams?.toJson()       .customDotParamsJson          @HiveField(38)
  .customEyeParams?.toJson()       .customEyeParamsJson          @HiveField(39)
  .boundaryParams.toJson()         .boundaryParamsJson            @HiveField(40)
  (자동 계산)                       .schemaVersion = 2            @HiveField(41)
  (자동 계산)                       .minEngineVersion             @HiveField(42)

[복원 흐름]
Hive Box ──load──→ UserQrTemplateModel.toEntity() ──→ UserQrTemplate ──applyUserTemplate──→ QrResultState
  @HiveField(38) String?     .customDotParamsJson                   DotShapeParams.fromJson()
  @HiveField(39) String?     .customEyeParamsJson                   EyeShapeParams.fromJson()
  @HiveField(40) String?     .boundaryParamsJson                    QrBoundaryParams.fromJson()
  @HiveField(41) int?        .schemaVersion                         (로깅/디버깅용)
  @HiveField(42) int?        .minEngineVersion                      호환성 판단
```

---

## 2. Entity / State / Mixin 세부 시그니처

### 2.1 `template_engine_version.dart` (신규)

```dart
/// 현재 앱이 처리할 수 있는 템플릿 엔진 버전.
/// 템플릿의 minEngineVersion > kTemplateEngineVersion 이면 적용 불가.
const int kTemplateEngineVersion = 2;

/// 현재 스키마 버전 — 새 템플릿 저장 시 기재.
const int kTemplateSchemaVersion = 2;

/// 현재 엔진에서 호환 가능한지 판정.
bool isTemplateCompatible(int? minEngineVersion) =>
    (minEngineVersion ?? 1) <= kTemplateEngineVersion;

/// 현재 스타일 상태로부터 최소 엔진 버전 자동 결정.
int computeMinEngineVersion({
  required bool hasCustomDotParams,
  required bool hasCustomEyeParams,
  required bool hasNonDefaultBoundary,
}) {
  if (hasCustomDotParams || hasCustomEyeParams || hasNonDefaultBoundary) {
    return 2;
  }
  return 1;
}
```

### 2.2 `user_qr_template.dart` 추가 필드

기존 `UserQrTemplate` 클래스에 5필드 추가:

```dart
class UserQrTemplate {
  // ... 기존 필드 (id ~ logoBackgroundColorValue) ...

  // ── 커스텀 파라미터 JSON 스냅샷 (v2) ──
  final String? customDotParamsJson;   // DotShapeParams.toJson() → jsonEncode
  final String? customEyeParamsJson;   // EyeShapeParams.toJson() → jsonEncode
  final String? boundaryParamsJson;    // QrBoundaryParams.toJson() → jsonEncode

  // ── 버전 관리 (v2) ──
  final int schemaVersion;             // 기본 kTemplateSchemaVersion (2)
  final int minEngineVersion;          // 기본 1

  const UserQrTemplate({
    // ... 기존 파라미터 ...
    this.customDotParamsJson,
    this.customEyeParamsJson,
    this.boundaryParamsJson,
    this.schemaVersion = 2,
    this.minEngineVersion = 1,
  });
}
```

### 2.3 `user_qr_template_model.dart` HiveField 추가

```dart
@HiveType(typeId: 1)
class UserQrTemplateModel extends HiveObject {
  // ... 기존 @HiveField(0) ~ @HiveField(37) ...

  @HiveField(38)
  String? customDotParamsJson;

  @HiveField(39)
  String? customEyeParamsJson;

  @HiveField(40)
  String? boundaryParamsJson;

  @HiveField(41)
  int? schemaVersion;    // nullable — v1 기존 데이터는 null

  @HiveField(42)
  int? minEngineVersion; // nullable — v1 기존 데이터는 null

  // toEntity() 매핑:
  //   schemaVersion: schemaVersion ?? 1,
  //   minEngineVersion: minEngineVersion ?? 1,
  //   customDotParamsJson: customDotParamsJson,
  //   customEyeParamsJson: customEyeParamsJson,
  //   boundaryParamsJson: boundaryParamsJson,

  // fromEntity() 매핑:
  //   schemaVersion: e.schemaVersion,
  //   minEngineVersion: e.minEngineVersion,
  //   customDotParamsJson: e.customDotParamsJson,
  //   customEyeParamsJson: e.customEyeParamsJson,
  //   boundaryParamsJson: e.boundaryParamsJson,
}
```

**Hive 호환성**: 기존 v1 데이터에서 HiveField 38~42는 자동으로 `null` 반환. `toEntity()`에서 null → 기본값 매핑으로 무손실 마이그레이션.

### 2.4 `template_setters.dart` — `applyUserTemplate()` 수정

```dart
void applyUserTemplate(UserQrTemplate t) {
  // ... 기존 gradient 파싱 ...

  // ── 커스텀 파라미터 복원 (v2) ──
  DotShapeParams? dotParams;
  if (t.customDotParamsJson != null) {
    try {
      dotParams = DotShapeParams.fromJson(jsonDecode(t.customDotParamsJson!));
    } catch (_) {}
  }

  EyeShapeParams? eyeParams;
  if (t.customEyeParamsJson != null) {
    try {
      eyeParams = EyeShapeParams.fromJson(jsonDecode(t.customEyeParamsJson!));
    } catch (_) {}
  }

  QrBoundaryParams? boundary;
  if (t.boundaryParamsJson != null) {
    try {
      boundary = QrBoundaryParams.fromJson(jsonDecode(t.boundaryParamsJson!));
    } catch (_) {}
  }

  state = state.copyWith(
    style: state.style.copyWith(
      // 기존 필드 (qrColor, gradient, roundFactor, dotStyle, eyeOuter, eyeInner, randomEyeSeed, quietZoneColor)
      // ... 동일 ...

      // v2 추가 필드
      customDotParams: dotParams,
      clearCustomDotParams: dotParams == null,
      customEyeParams: eyeParams,
      clearCustomEyeParams: eyeParams == null,
      boundaryParams: boundary ?? const QrBoundaryParams(),
    ),
    // sticker, template: 기존 동일
  );
  _schedulePush();
}
```

### 2.5 `qr_result_screen.dart` — 저장 로직 수정

```dart
final template = UserQrTemplate(
  // ... 기존 필드 동일 ...

  // v2 추가: 커스텀 파라미터 스냅샷
  customDotParamsJson: state.style.customDotParams != null
      ? jsonEncode(state.style.customDotParams!.toJson())
      : null,
  customEyeParamsJson: state.style.customEyeParams != null
      ? jsonEncode(state.style.customEyeParams!.toJson())
      : null,
  boundaryParamsJson: state.style.boundaryParams.isDefault
      ? null  // 기본값이면 저장 불필요
      : jsonEncode(state.style.boundaryParams.toJson()),

  // v2 추가: 버전 관리
  schemaVersion: kTemplateSchemaVersion,
  minEngineVersion: computeMinEngineVersion(
    hasCustomDotParams: state.style.customDotParams != null,
    hasCustomEyeParams: state.style.customEyeParams != null,
    hasNonDefaultBoundary: !state.style.boundaryParams.isDefault,
  ),
);
```

### 2.6 `my_templates_tab.dart` — 비호환 템플릿 표시

```dart
// _apply() 메서드 수정
Future<void> _apply(UserQrTemplate t) async {
  if (!isTemplateCompatible(t.minEngineVersion)) {
    if (mounted) {
      context.showSnack('이 템플릿은 최신 버전의 앱이 필요합니다.');
    }
    return;
  }
  ref.read(qrResultProvider.notifier).applyUserTemplate(t);
  widget.onChanged();
  if (mounted) {
    context.showSnack('「${t.name}」 템플릿이 적용되었습니다.');
  }
}

// _TemplateCard: 비호환 시 오버레이
// isTemplateCompatible(template.minEngineVersion) == false 일 때
// 썸네일 위에 반투명 오버레이 + 자물쇠 아이콘 표시
```

---

## 3. JSON 스냅샷 예시

### 3.1 customDotParamsJson (Superformula 하트)

```json
{
  "mode": "asymmetric",
  "vertices": 4,
  "innerRadius": 1.0,
  "roundness": 0.0,
  "sfM": 2,
  "sfN1": 1.5,
  "sfN2": 0.2,
  "sfN3": -1.9,
  "sfA": 1.2,
  "sfB": 0.98,
  "rotation": 244,
  "scale": 1.0
}
```

### 3.2 customEyeParamsJson (비대칭 코너)

```json
{
  "cornerQ1": 0.8,
  "cornerQ2": 0.2,
  "cornerQ3": 0.8,
  "cornerQ4": 0.2,
  "innerN": 4.0
}
```

### 3.3 boundaryParamsJson (하트 프레임)

```json
{
  "type": "heart",
  "superellipseN": 20.0,
  "starVertices": 5,
  "starInnerRadius": 0.5,
  "rotation": 0.0,
  "padding": 0.05,
  "roundness": 0.0,
  "frameScale": 1.5,
  "marginPattern": "wave",
  "patternDensity": 1.0
}
```

---

## 4. 버전 전략 상세

### 4.1 스키마 버전 매트릭스

| schemaVersion | HiveField 범위 | 주요 변경 |
|:---:|:---:|---|
| 1 (null) | 0~37 | 초기 — enum 인덱스 + 색상 + 스티커/로고 |
| **2** | 0~42 | + customDotParams, customEyeParams, boundaryParams, 버전 관리 |

### 4.2 엔진 호환성 매트릭스

| minEngineVersion | 필요 기능 | 판정 기준 |
|:---:|---|---|
| 1 | 기본 enum 도트/눈 + 색상만 | customDot/Eye/Boundary 모두 기본값 |
| 2 | 커스텀 파라미터 사용 | customDotParams != null OR customEyeParams != null OR boundary != default |

### 4.3 하위 호환 동작

```
v1 앱 (kTemplateEngineVersion=1) 이 v2 템플릿 로드:
  → minEngineVersion=1 인 v2 템플릿: 정상 적용 (새 필드 null → 기본값)
  → minEngineVersion=2 인 v2 템플릿: isTemplateCompatible() = false → 적용 차단

v2 앱 (kTemplateEngineVersion=2) 이 v1 템플릿 로드:
  → schemaVersion=null → v1 취급
  → customDotParamsJson=null → 기본값 fallback
  → 기존 dotStyleIndex/eyeOuterIndex/eyeInnerIndex 로 정상 복원
```

---

## 5. 구현 순서 (Checklist)

| # | 파일 | 작업 | 의존성 |
|---|------|------|--------|
| 1 | `domain/entities/template_engine_version.dart` | 신규 생성: 상수 + 유틸 함수 | 없음 |
| 2 | `domain/entities/user_qr_template.dart` | 5필드 추가, 생성자 파라미터 추가 | #1 |
| 3 | `data/models/user_qr_template_model.dart` | HiveField 38~42, toEntity/fromEntity 매핑 | #2 |
| 4 | `build_runner` 실행 | `.g.dart` 재생성 | #3 |
| 5 | `qr_result_screen.dart` | 저장 시 3필드 + 버전 정보 포함 | #1, #2 |
| 6 | `notifier/template_setters.dart` | applyUserTemplate() 3필드 복원 | #2 |
| 7 | `tabs/my_templates_tab.dart` | 비호환 템플릿 적용 차단 + UI 표시 | #1 |

---

## 6. 검증 시나리오

| # | 시나리오 | 기대 결과 |
|---|----------|-----------|
| V1 | 커스텀 도트(Superformula 하트) + 커스텀 눈 + heart 외곽 → 저장 → 로드 → 적용 | 저장 시점과 100% 동일 렌더링 |
| V2 | 기본 enum 도트/눈 + square 외곽 → 저장 | minEngineVersion=1, customDot/Eye/BoundaryJson=null |
| V3 | v1 기존 템플릿 (HiveField 38~42 = null) 로드 → 적용 | 기존 동작 동일 (하위 호환) |
| V4 | minEngineVersion=3 인 템플릿 적용 시도 (미래 시뮬레이션) | 적용 차단 + "앱 업데이트 필요" 안내 |
| V5 | customDotParamsJson에 손상된 JSON → 로드 | try-catch fallback → null → enum dotStyle로 렌더링 |
| V6 | 커스텀 도트 모양 → 사용자 프리셋에서 삭제 → 템플릿 적용 | JSON 스냅샷으로 복원 성공 (원본 삭제 무관) |
