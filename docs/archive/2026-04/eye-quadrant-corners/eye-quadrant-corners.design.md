# eye-quadrant-corners — Design

> Plan: `docs/01-plan/features/eye-quadrant-corners.plan.md` 기반.
> 본 프로젝트 CLAUDE.md 규약상 3-옵션 아키텍처 비교는 생략. R-series Provider 패턴 내에서 기존 `qr_result` feature 확장.

---

## Executive Summary

| 항목 | 내용 |
|---|---|
| Architecture | R-series Provider 패턴 내 확장 (`qr_result` feature) — neu feature 아님 |
| Entity 변경 | `EyeShapeParams` 2필드 → 5필드 (cornerQ1/Q2/Q3/Q4 + innerN). `outerN` 제거 |
| Renderer 변경 | `SuperellipsePath.paintEye` 시그니처에 `rotationDeg` 추가, outer ring은 `RRect.fromRectAndCorners` |
| State 변경 | 없음 (`QrStyleState.customEyeParams` 는 `EyeShapeParams` 를 그대로 보관) |
| Setter 변경 | 없음 (`setCustomEyeParams` 시그니처 동일) |
| Hive schema 변경 | JSON 키 `outerN` → `cornerQ1/2/3/4`. legacy 발견 시 preset 삭제. 템플릿 customEye 는 fallback to null |
| l10n 변경 | `sliderCornerQ1/Q2/Q3/Q4` 4개 key 추가 + `actionRandomEye/Regenerate` 2개 key 제거 (랜덤 버튼 삭제) |
| 영향 파일 | 8개 수정 (eye_editor, qr_shape_tab, qr_shape_params, superellipse, custom_qr_painter, qr_preview_section, local_user_shape_preset_datasource, customization_mapper), 신규 0개 |

### Value Delivered (reiterated from Plan)

Plan 문서의 Executive Summary 와 동일. Design 단계에서는 기술적 실현 경로만 상세화.

---

## 1. 기존 아키텍처 맥락 (Before)

`qr_result` feature 는 R-series 패턴의 canonical reference (`CLAUDE.md` 명시). 이번 변경은 다음 R-series 구조 내 **점진적 확장**:

```
lib/features/qr_result/
├── qr_result_provider.dart          # library; + part + lifecycle only
├── domain/
│   ├── entities/
│   │   ├── qr_shape_params.dart     ⇐ EyeShapeParams 재작성
│   │   └── ...
│   └── state/
│       └── qr_style_state.dart       (no change)
├── notifier/
│   ├── style_setters.dart            (no change)
│   └── ...
├── utils/
│   ├── superellipse.dart             ⇐ paintEye 시그니처 + per-corner outer 로직
│   └── ...
├── widgets/
│   ├── custom_qr_painter.dart        ⇐ finder 순회 rotation 계산
│   ├── qr_preview_section.dart       ⇐ _EyePreviewPainter + _EyeFinderPattern 리뷰
│   └── qr_layer_stack.dart           (no change)
├── data/
│   └── datasources/
│       └── local_user_shape_preset_datasource.dart  ⇐ legacy eye preset clean
└── tabs/
    └── qr_shape_tab/
        ├── eye_editor.dart           ⇐ 슬라이더 2개 → 5개
        ├── eye_row.dart              (no change)
        └── ...
```

모든 변경은 **기존 파일 내**에서 이뤄지며 신규 파일 생성 없음. R-series 구조는 그대로 유지.

---

## 2. Entity 재설계: `EyeShapeParams`

### 2.1 Before / After 시그니처

**Before** (`lib/features/qr_result/domain/entities/qr_shape_params.dart:195-240`):
```dart
class EyeShapeParams {
  final double outerN; // 2.0 (원) ~ 20.0 (사각)
  final double innerN; // 2.0 (원) ~ 20.0 (사각)
  const EyeShapeParams({ this.outerN = 20.0, this.innerN = 20.0 });
  // square / rounded / circle / squircle / smooth 정적 프리셋
}
```

**After**:
```dart
class EyeShapeParams {
  /// 각 모서리 둥글/사각 조절. 0.0 = 완전 둥근(원형), 1.0 = 완전 각진(사각).
  /// 좌표계: local eye (회전 전).
  final double cornerQ1; // top-right
  final double cornerQ2; // top-left
  final double cornerQ3; // bottom-left
  final double cornerQ4; // bottom-right  ← 회전 후 QR 중심 방향
  /// 내부 fill superellipse n. 2.0 (원) ~ 20.0 (사각). uniform.
  final double innerN;

  const EyeShapeParams({
    this.cornerQ1 = 0.0,
    this.cornerQ2 = 0.0,
    this.cornerQ3 = 0.0,
    this.cornerQ4 = 0.0,
    this.innerN = 2.0,
  });

  // ── 내장 빌트인 프리셋 매핑 (참조용 / 내부 기본값) ──
  static const square   = EyeShapeParams(cornerQ1: 1, cornerQ2: 1, cornerQ3: 1, cornerQ4: 1, innerN: 20);
  static const rounded  = EyeShapeParams(cornerQ1: 0.7, cornerQ2: 0.7, cornerQ3: 0.7, cornerQ4: 0.7, innerN: 20);
  static const circle   = EyeShapeParams(cornerQ1: 0, cornerQ2: 0, cornerQ3: 0, cornerQ4: 0, innerN: 2);
  static const squircle = EyeShapeParams(cornerQ1: 0.4, cornerQ2: 0.4, cornerQ3: 0.4, cornerQ4: 0.4, innerN: 4);
  static const smooth   = EyeShapeParams(cornerQ1: 0.2, cornerQ2: 0.2, cornerQ3: 0.2, cornerQ4: 0.2, innerN: 3);

  EyeShapeParams copyWith({
    double? cornerQ1, double? cornerQ2,
    double? cornerQ3, double? cornerQ4,
    double? innerN,
  }) => EyeShapeParams(
    cornerQ1: cornerQ1 ?? this.cornerQ1,
    cornerQ2: cornerQ2 ?? this.cornerQ2,
    cornerQ3: cornerQ3 ?? this.cornerQ3,
    cornerQ4: cornerQ4 ?? this.cornerQ4,
    innerN:   innerN   ?? this.innerN,
  );

  Map<String, dynamic> toJson() => {
    'cornerQ1': cornerQ1,
    'cornerQ2': cornerQ2,
    'cornerQ3': cornerQ3,
    'cornerQ4': cornerQ4,
    'innerN':   innerN,
  };

  /// JSON 역직렬화. legacy(outerN 키 존재, cornerQ* 없음) 는 null 리턴
  /// — 호출자가 preset 을 skip 하도록.
  static EyeShapeParams? fromJsonOrNull(Map<String, dynamic> json) {
    final hasCorner = json.containsKey('cornerQ1');
    final hasLegacyOuter = json.containsKey('outerN') && !hasCorner;
    if (hasLegacyOuter) return null;
    return EyeShapeParams(
      cornerQ1: (json['cornerQ1'] as num?)?.toDouble() ?? 0.0,
      cornerQ2: (json['cornerQ2'] as num?)?.toDouble() ?? 0.0,
      cornerQ3: (json['cornerQ3'] as num?)?.toDouble() ?? 0.0,
      cornerQ4: (json['cornerQ4'] as num?)?.toDouble() ?? 0.0,
      innerN:   (json['innerN']   as num?)?.toDouble() ?? 2.0,
    );
  }

  /// 기존 API 이름 보존 — 내부에서 fromJsonOrNull 실패 시 default 반환
  factory EyeShapeParams.fromJson(Map<String, dynamic> json) =>
      fromJsonOrNull(json) ?? const EyeShapeParams();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeShapeParams &&
          cornerQ1 == other.cornerQ1 &&
          cornerQ2 == other.cornerQ2 &&
          cornerQ3 == other.cornerQ3 &&
          cornerQ4 == other.cornerQ4 &&
          innerN   == other.innerN;

  @override
  int get hashCode => Object.hash(cornerQ1, cornerQ2, cornerQ3, cornerQ4, innerN);

  @override
  String toString() =>
      'EyeShapeParams(Q1:$cornerQ1, Q2:$cornerQ2, Q3:$cornerQ3, Q4:$cornerQ4, innerN:$innerN)';
}
```

### 2.2 필드 의미 수학

- corner 값 → RRect corner radius 변환: `radius = cornerValue × (bounds.width / 2)`
  - cornerValue 0.0 → radius 0 (직각 모서리)
  - cornerValue 1.0 → radius bounds.width/2 (완전 원형)

**주의**: 본 문서의 "0=둥글, 1=사각" 초기 설명은 Plan 문서 2.2절 슬라이더 시점의 **사용자 관점**. 내부 field 에서는 **0=둥근, 1=각진** 으로 반전. 즉 슬라이더 UI 값과 field 값이 직접 매핑. **둥글(round) = corner 값 낮음, 사각(square) = corner 값 높음** 혼동 방지:

| 용어 | 슬라이더 UI (왼→오) | field 값 | RRect radius |
|---|---|---|---|
| 둥글 (round, circle corner) | 0.0 | 0.0 | max (bounds.width/2) |
| 사각 (square, sharp corner) | 1.0 | 1.0 | 0 |

**변환 공식**: `cornerRadius = (1.0 - cornerQX) × maxR` where `maxR = bounds.width / 2`.

> 코드 주석에서 이 convention 을 명시: `// 0.0 = round corner (max radius), 1.0 = square corner (0 radius)`

---

## 3. Renderer 재설계: `SuperellipsePath.paintEye`

### 3.1 시그니처 변경

**Before** (`lib/features/qr_result/utils/superellipse.dart:46-64`):
```dart
static void paintEye(Canvas canvas, Rect bounds, EyeShapeParams params, Paint paint);
```

**After**:
```dart
static void paintEye(
  Canvas canvas,
  Rect bounds,
  EyeShapeParams params,
  Paint paint, {
  double rotationDeg = 0.0,  // +90 = CW, -90 = CCW
});
```

### 3.2 구현 의사코드

```dart
static void paintEye(Canvas canvas, Rect bounds, EyeShapeParams params, Paint paint, {double rotationDeg = 0.0}) {
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;

  // 1. canvas 회전 (중심점 기준)
  canvas.save();
  canvas.translate(cx, cy);
  canvas.rotate(rotationDeg * pi / 180);
  canvas.translate(-cx, -cy);

  final m = bounds.width / 7; // QR 스펙 고정: finder pattern = 7 모듈
  final maxR = bounds.width / 2;

  // 2. Outer ring: RRect per-corner radii (evenOdd fill)
  //    topLeft = Q2, topRight = Q1, bottomLeft = Q3, bottomRight = Q4
  final outerRRect = RRect.fromRectAndCorners(
    bounds,
    topLeft:     Radius.circular((1.0 - params.cornerQ2) * maxR),
    topRight:    Radius.circular((1.0 - params.cornerQ1) * maxR),
    bottomLeft:  Radius.circular((1.0 - params.cornerQ3) * maxR),
    bottomRight: Radius.circular((1.0 - params.cornerQ4) * maxR),
  );
  //    구멍 (1모듈 안쪽). maxR-m 으로 축소된 radius 사용
  final holeRect = bounds.deflate(m);
  final holeMaxR = holeRect.width / 2;
  final holeRRect = RRect.fromRectAndCorners(
    holeRect,
    topLeft:     Radius.circular((1.0 - params.cornerQ2) * holeMaxR),
    topRight:    Radius.circular((1.0 - params.cornerQ1) * holeMaxR),
    bottomLeft:  Radius.circular((1.0 - params.cornerQ3) * holeMaxR),
    bottomRight: Radius.circular((1.0 - params.cornerQ4) * holeMaxR),
  );
  final ringPath = Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(outerRRect)
    ..addRRect(holeRRect);
  canvas.drawPath(ringPath, paint);

  // 3. Inner fill: 기존 superellipse (innerN). uniform → 회전 invariant
  final innerRect = bounds.deflate(m * 2);
  canvas.drawPath(buildPath(innerRect, params.innerN), paint);

  canvas.restore();
}
```

### 3.3 Finder 위치별 rotation 매핑

**Rotation 배열** — 호출 측(`custom_qr_painter.dart`, `qr_preview_section.dart`)에서 상수로 정의:

```dart
// finder 순서: [top-left (Q2), top-right (Q1), bottom-left (Q3)]
// 각 eye 의 local Q4 가 QR 중심을 향하도록 보정
static const _kEyeRotations = <double>[0.0, 90.0, -90.0];
```

**호출 변경** (`custom_qr_painter.dart:94-97`):

Before:
```dart
for (final bounds in _helper.finderBounds(m, Offset.zero)) {
  SuperellipsePath.paintEye(canvas, bounds, eyeParams, basePaint);
}
```

After:
```dart
final finderRects = _helper.finderBounds(m, Offset.zero);
for (int i = 0; i < finderRects.length; i++) {
  SuperellipsePath.paintEye(
    canvas, finderRects[i], eyeParams, basePaint,
    rotationDeg: _kEyeRotations[i],
  );
}
```

### 3.4 pretty_qr 경로 (`qr_preview_section.dart`) — 회전 대상 아님

`customEyeParams != null` 인 경우 `qr_layer_stack.dart:82` 의 분기로 **항상 `CustomQrPainter` 경로로 라우팅** 된다. 따라서 pretty_qr 어댑터(`_ComboFinderPattern`, `_RandomFinderPattern`) 는 **built-in enum 전용** 이며 회전 적용 대상이 아님.

- pretty_qr 의 `_ComboFinderPattern` 은 대칭적 built-in 모양(Square/Rounded/Circle/Smooth/CircleRound) 을 그리므로 회전해도 시각적 차이 없음.
- Custom Eye rotation 은 §3.3 의 `CustomQrPainter` 경로 **하나만** 건드리면 충분.
- 단, `qr_preview_section.dart` 내의 **1-eye editor preview** (`_EyePreviewPainter`) 는 `paintEye(..., rotationDeg: 0.0)` 로 명시적 로컬 orientation 유지 (§4 참조).

---

## 4. Preview Painter (editor 내부 preview)

`_EyePreviewPainter` (`qr_preview_section.dart:162-184`) — **rotation 0 고정** (local orientation 1-eye preview).

Before:
```dart
SuperellipsePath.paintEye(canvas, bounds, params, paint);
```

After:
```dart
SuperellipsePath.paintEye(canvas, bounds, params, paint, rotationDeg: 0.0);
```

기본값이 0.0 이므로 실제로는 변경 불필요. **명시적으로 0 지정** 하여 "editor는 local 좌표 표시" 의도를 코드상 명시.

Editor UI 상단에 **회전 효과 시각화**를 추가할지? Plan 문서 2.2절에 "직관적 편집 시각화"가 Value 로 언급됐으므로, preview 를 1-eye 대신 "3-eye 미니맵" 으로 업그레이드하면 좋음 → **Out of scope** (Plan 문서 Section 7 확장 대상).

결론: 이번 Design 에서는 preview 1-eye 유지.

---

## 5. Editor UI 재설계

### 5.1 `_EyeEditor` 시그니처

```dart
class _EyeEditor extends StatelessWidget {
  final EyeShapeParams params;
  final ValueChanged<EyeShapeParams> onChanged;
  final VoidCallback onDragStart;
  final ValueChanged<EyeShapeParams> onDragEnd;
  // (랜덤 버튼 제거됨 — 슬라이더 5개만)
}
```

### 5.2 build() 내부 슬라이더 구성

Before: 2개 슬라이더 (outerN, innerN).
After: 5개 슬라이더 (cornerQ1, Q2, Q3, Q4, innerN).

```dart
Column(
  children: [
    _SliderRow(label: l10n.sliderCornerQ1, value: params.cornerQ1, min: 0, max: 1,
      valueLabel: params.cornerQ1.toStringAsFixed(2),
      onChanged: (v) { onDragStart(); onChanged(params.copyWith(cornerQ1: v)); },
      onChangeEnd: (v) => onDragEnd(params.copyWith(cornerQ1: v)),
    ),
    _SliderRow(label: l10n.sliderCornerQ2, /* same pattern */ ),
    _SliderRow(label: l10n.sliderCornerQ3, /* same pattern */ ),
    _SliderRow(label: l10n.sliderCornerQ4, /* same pattern */ ),
    _SliderRow(label: l10n.sliderInnerN, value: params.innerN, min: 2, max: 20,
      valueLabel: params.innerN.toStringAsFixed(1),
      onChanged: (v) { onDragStart(); onChanged(params.copyWith(innerN: v)); },
      onChangeEnd: (v) => onDragEnd(params.copyWith(innerN: v)),
    ),
  ],
)
```

**슬라이더 순서**: Q1→Q2→Q3→Q4→innerN. 사분면 순서 자연스러움 + 마지막에 내부 fill.

### 5.3 (랜덤 버튼 섹션 삭제됨)

랜덤 눈 생성 기능은 최종 UX 결정으로 제거됨 (2026-04-22). 사용자는 5개 슬라이더를 수동 조작하여 원하는 눈 모양을 구성한다.

관련 l10n 키 (`actionRandomEye`, `actionRandomRegenerate`) 및 관련 코드 (`_RandomEyeButton`, `_onRandomEyeFromEditor`, `onRandomGenerate` 콜백) 모두 제거됨.

---

## 6. Legacy 데이터 처리

### 6.1 사용자 eye preset (Hive box: `user_eye_presets`)

**처리 주체**: `LocalUserShapePresetDatasource._decodeBox` (`lib/features/qr_result/data/datasources/local_user_shape_preset_datasource.dart:44-54`).

**흐름**:
```
1. box.values (JSON string 리스트) 순회
2. 각 JSON 을 UserShapePreset.fromJson 으로 디코드
3. type == eye 이고 eyeParams.fromJsonOrNull → null (legacy 감지) 이면:
   a. 해당 id 로 box.delete(id) 수행
   b. 결과 리스트에서 제외
4. 정상 preset 만 lastUsedAt desc 정렬 후 반환
```

**구현 변경**:
```dart
List<UserShapePreset> _decodeBox(ShapePresetType type) {
  final box = _boxes[type]!;
  final legacyIds = <String>[];
  final presets = <UserShapePreset>[];
  for (final entry in box.toMap().entries) {
    final jsonStr = entry.value;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      // eye 타입 legacy 감지: eyeParams 존재 + EyeShapeParams.fromJsonOrNull == null
      if (type == ShapePresetType.eye) {
        final eyeJson = map['eyeParams'] as Map<String, dynamic>?;
        if (eyeJson != null && EyeShapeParams.fromJsonOrNull(eyeJson) == null) {
          legacyIds.add(entry.key as String);
          continue;
        }
      }
      presets.add(UserShapePreset.fromJson(map));
    } catch (_) {
      legacyIds.add(entry.key as String);  // 디코드 실패도 제거
    }
  }
  // 비동기 cleanup (fire-and-forget, 다음 세션에서는 clean 한 상태)
  if (legacyIds.isNotEmpty) {
    for (final id in legacyIds) { box.delete(id); }
  }
  presets.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  return presets;
}
```

**주의**: `box.delete` 는 `Future` 지만 await 하지 않음 — 다음 load 에서 이미 삭제된 상태이므로 race 문제 없음. 만약 fire-and-forget 문제가 있다면 `readAll()` 을 Future 화 고려.

실용적 접근: `_decodeBox` 는 현재 sync 이고 변경 시 call site 영향이 큼. **fire-and-forget 유지** → 1회 legacy 데이터는 화면에 즉시 노출 안 되지만(null 반환), 실제 box 삭제는 비동기로 처리. 허용.

### 6.2 템플릿 내 customEyeParams (QrResult 상태 load)

**경로**: `customization_mapper.dart:109-112` → `EyeShapeParams.fromJson` 호출.

**변경 후 동작**:
- legacy `outerN` JSON → `fromJson` 이 `fromJsonOrNull` 실패 → default `EyeShapeParams()` 리턴
- 결과: 해당 QR 의 customEyeParams 는 기본값 (모두 둥근 원) 으로 fallback

**대안**: legacy 감지 시 `customEyeParams = null` 로 세팅 (custom 해제). 이 편이 "기존 QR 이 원치 않게 이상한 모양으로 바뀜"을 방지.

**선택**: `customization_mapper.eyeParamsFromJson` 을 legacy 감지하도록 수정:

```dart
static EyeShapeParams? eyeParamsFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return EyeShapeParams.fromJsonOrNull(json); // legacy 면 null → customEye 해제
}
```

이렇게 하면 legacy 템플릿은 **빌트인 eye 로 자동 fallback** (customEyeParams == null 이므로 eyeOuter/eyeInner 기반 렌더).

### 6.3 Migration summary

| 데이터 | 경로 | Legacy 처리 |
|---|---|---|
| 사용자 eye preset (Hive `user_eye_presets`) | `_decodeBox` | id 제거 + box.delete (1-time, 화면 미노출) |
| 템플릿 customEyeParams (Hive user_qr_template) | `customization_mapper.eyeParamsFromJson` | null 반환 → 빌트인 eye 로 fallback |

모든 경로에서 **예외 발생 없이** 자연스럽게 migration. 사용자는 "이전 저장된 사용자 눈 프리셋이 사라졌다" 는 현상만 경험. Pre-release + 명시 승인.

---

## 7. 데이터 흐름 (기존 feature 와의 연결)

```
┌────────────────────────────────────────────────────────────────┐
│  사용자 편집기 UI (_EyeEditor 슬라이더 5개)                    │
│    - cornerQ1/Q2/Q3/Q4 (0~1)                                   │
│    - innerN (2~20)                                             │
└────────────────────────────────────────────────────────────────┘
                              │ onChanged / onDragEnd
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  QrShapeTabState (qr_shape_tab.dart)                           │
│    _editEye : EyeShapeParams (local edit buffer)               │
│    ref.read(qrResultProvider.notifier).setCustomEyeParams(p)   │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  QrResultNotifier + _StyleSetters (notifier/style_setters.dart)│
│    setCustomEyeParams(p) →                                     │
│      state.style.copyWith(customEyeParams: p,                  │
│                           clearRandomEyeSeed: true)            │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  QrStyleState (domain/state/qr_style_state.dart)               │
│    customEyeParams : EyeShapeParams?                           │
│    (필드 이름/타입 변경 없음 — entity 내부만 변경)              │
└────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
                    ▼                    ▼
        ┌─────────────────────┐   ┌─────────────────────┐
        │ custom_qr_painter   │   │ qr_preview_section  │
        │ (custom 경로 활성)  │   │ (pretty_qr 경로)    │
        │                     │   │                     │
        │ for i in 0..2:      │   │ for i in 0..2:      │
        │   rot = _kEye       │   │   rot = _kEye       │
        │         Rotations[i]│   │         Rotations[i]│
        │   SuperellipsePath. │   │   SuperellipsePath. │
        │    paintEye(...,    │   │    paintEye(...,    │
        │    rotationDeg:rot) │   │    rotationDeg:rot) │
        └─────────────────────┘   └─────────────────────┘
                    │                    │
                    └────────┬───────────┘
                             ▼
        ┌─────────────────────────────────────────┐
        │ SuperellipsePath.paintEye               │
        │   canvas.rotate(rotationDeg)            │
        │   outer ring: RRect per-corner          │
        │     (1-cornerQX)*maxR → Radius         │
        │   inner fill: buildPath(innerN)         │
        └─────────────────────────────────────────┘
                             │
                             ▼
                     ┌──────────────┐
                     │  Canvas draw │
                     └──────────────┘
```

**중요**: `QrStyleState` / `style_setters.dart` / `QrShapeTabState._editEye` 모두 **타입 시그니처 무변경**. `EyeShapeParams` 는 같은 이름 유지 — **필드만 변경**.

---

## 8. l10n (app_ko.arb 추가)

```json
{
  "sliderCornerQ1": "Q1 모서리",
  "@sliderCornerQ1": { "description": "Eye editor: top-right corner roundness slider" },
  "sliderCornerQ2": "Q2 모서리",
  "sliderCornerQ3": "Q3 모서리",
  "sliderCornerQ4": "Q4 모서리"
}
```

ko 만 추가. `app_en.arb` 등 fallback 유지 (CLAUDE.md 정책).

`flutter gen-l10n` 실행 (또는 자동 generate 옵션 — pubspec.yaml `generate: true` 확인됨).

---

## 9. 구현 순서 (Do phase)

1. **Entity 재작성**: `qr_shape_params.dart` 의 `EyeShapeParams` 전체 교체
2. **Renderer 시그니처 변경**: `superellipse.dart` 의 `paintEye` 에 `rotationDeg` 추가 + RRect 구현
3. **Finder 순회 수정**:
   - `custom_qr_painter.dart` paint() 내 finder loop
   - `qr_preview_section.dart` 의 Custom Eye 경로 (pretty_qr 어댑터)
4. **Editor UI 재작성**: `eye_editor.dart` 슬라이더 5개 (랜덤 버튼 없음)
5. **Legacy preset cleanup**: `local_user_shape_preset_datasource.dart:_decodeBox`
6. **템플릿 fallback**: `customization_mapper.dart:eyeParamsFromJson`
7. **l10n 키 추가 + gen-l10n**: `app_ko.arb` (+ `actionRandomEye/Regenerate` 제거)
8. **`flutter analyze`** — 타입 에러 확인 (outerN 참조 잔재 스캔)
9. **수동 테스트**:
    - 기본 사용자 눈 생성 → corner 슬라이더 조절 → 3 finder 방향성 확인
    - 빌트인 eye (square 등) 선택 → 회전 없이 기존처럼 렌더 확인
    - 앱 재시작 후 legacy 데이터 있을 시 (수동 설치 후) → 빈 eye 목록 + 에러 없음

---

## 10. 검증 (Gap Analysis 대비 체크포인트)

| 항목 | 검증 방법 |
|---|---|
| EyeShapeParams 필드 정확 | `grep outerN lib/features/qr_result` → 결과 없어야 함 (static 빌트인 매핑만 예외) |
| 3-rotation 적용 | 렌더된 QR 스크린샷 시각 검증 — 각 eye의 Q4가 중심 향함 |
| 인식률 | 실기기에서 스캔 테스트 — 수치화 어려우면 Gap analysis 시 수동 |
| 슬라이더 동작 | 각 슬라이더 drag → preview 즉시 갱신 + onDragEnd 후 state 저장 |
| 빌트인 회전 제외 | 빌트인 eye 로드 시 3 finder 가 대칭 (회전 없음) |
| Legacy cleanup | Hive inspector 또는 debug log 로 `user_eye_presets` legacy id 삭제 확인 |

---

## 11. Risks & Mitigations

| Risk | 영향 | 완화 |
|---|---|---|
| RRect corner radius > bounds/2 | Flutter 는 clamp 하지만 시각적 왜곡 가능성 | `(1-cornerQX) × maxR` 보장 — cornerQX 가 [0,1] 이므로 radius ∈ [0, maxR] 안전 |
| 홀 RRect radius 가 너무 작음 (corner 값 ~1) | outer 은 사각인데 hole 은 살짝 둥글게 남을 수 있음 | hole radius 도 같은 `(1-cornerQX) × holeMaxR` 사용 — 시각적 일관 |
| legacy `outerN` 템플릿 로드 시 예외 | 앱 크래시 | `fromJsonOrNull` + customization_mapper null fallback |
| `_decodeBox` sync 내 비동기 delete | race on next readAll | fire-and-forget 허용 (다음 load 시 어차피 재검증) |
| 사용자 QR 스캐너 인식률 저하 | 상품성 | 수동 기기 테스트 필수 — Gap phase 에서 체크 |

---

## 12. Future Work (Out of Scope)

- Per-corner inner fill (cornerQ 별 내부 fill 독립 조절) — 현재 innerN uniform
- 사용자 회전 각도 지정 (0/90/-90 고정 아님)
- 빌트인 eye 에도 회전 적용
- 3-eye preview 미니맵 (editor 내부에서 회전 시각화)
- 회전 보간 애니메이션 (editor 진입 시 회전 효과 드러내기)

---

**Plan 참조**: `docs/01-plan/features/eye-quadrant-corners.plan.md`
**Next**: `/pdca do eye-quadrant-corners` — 구현 승인 및 실행.
