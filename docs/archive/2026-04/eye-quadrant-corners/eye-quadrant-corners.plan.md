# eye-quadrant-corners — Plan

> 사용자 눈모양(Custom Eye) 편집에 **4 모서리 개별 둥글/사각 조절** + **3-finder 방향 회전** 적용.

---

## Executive Summary

| 항목 | 내용 |
|---|---|
| Feature | `eye-quadrant-corners` |
| Created | 2026-04-22 |
| Project Level | Flutter Dynamic × Clean Architecture × R-series |
| Scope | Custom Eye 모델/렌더러/편집기 확장 + 기존 프리셋 wipe |

### Value Delivered (4-perspective)

| Perspective | 내용 |
|---|---|
| **Problem** | 현재 사용자 눈모양은 outerN 하나로 전체 모서리가 동일하게 둥글어지고, 3개 finder 모두 같은 방향으로 렌더링되어 **시각적으로 획일적**. 디자이너 관점에서 "QR 중심을 가리키는 화살표" 같은 역동적 구도를 만들 수 없음. |
| **Solution** | EyeShapeParams 를 4-corner 독립 값으로 재설계하고, 3 finder 위치에 따라 ±90° 회전을 적용해 "각 눈의 Q4 모서리가 QR 중심을 향하는" 방향성 있는 finder 렌더링. |
| **Function / UX Effect** | 사용자 눈 편집기에 Q1/Q2/Q3/Q4 슬라이더 4개 + innerN 슬라이더 1개 = 총 5개 슬라이더. 각 모서리 둥글(0.0) ↔ 사각(1.0) 독립 조절. Q4 방향이 중심을 향하므로 **직관적 편집 시각화** 확보. |
| **Core Value** | 디자인 자유도 대폭 상승 + 3 finder의 시각적 일체감 (모든 눈이 중심을 "바라봄") + QR 인식률 안정 (RRect 기반, superellipse 대비 수학적 단순). |

---

## 1. 배경 (Why)

- 현재 `EyeShapeParams` 는 `outerN` + `innerN` 2 필드 — 둘 다 superellipse `n` (2.0 원 ↔ 20.0 사각).
- 모든 모서리에 동일한 n 적용 → 대칭형만 가능.
- 3개 finder pattern (top-left / top-right / bottom-left) 이 모두 같은 local 방향으로 렌더됨.
- 사용자 요구: **"각 눈의 Q4가 QR 중심을 가리키는" 회전** + **"각 모서리 개별 둥글/사각"**.

---

## 2. 요구사항 (What)

### 2.1 3-Finder 방향 회전

| Finder 위치 | QR 내 사분면 | 적용 회전 | 회전 후 Q4 (local) 방향 |
|---|---|---|---|
| Top-Left | Q2 | **0°** (기준) | bottom-right (자연스럽게 중심 향함) |
| Top-Right | Q1 | **+90° CW** | bottom-left (중심 향함) |
| Bottom-Left | Q3 | **-90° CCW** | top-right (중심 향함) |

**수학 검증** (local eye 좌표계, 중심 원점, 사각 가정):
- Q4 corner at (+1, -1). 90° CW 회전: (x,y)→(y,-x) → (-1, -1) ✓ (bottom-left)
- 90° CCW 회전: (x,y)→(-y,x) → (+1, +1) ✓ (top-right)

**적용 범위**: **customEyeParams 활성 시에만** 적용. 빌트인 enum(QrEyeOuter/Inner)은 기존처럼 회전 없이 렌더.

### 2.2 4-Corner 슬라이더 (Eye Editor)

편집기 내 슬라이더 구성:

| 슬라이더 | 범위 | 의미 | 대상 |
|---|---|---|---|
| Q1 corner | 0.0 ~ 1.0 | 0=둥글 ↔ 1=사각 | local top-right 모서리 |
| Q2 corner | 0.0 ~ 1.0 | 0=둥글 ↔ 1=사각 | local top-left |
| Q3 corner | 0.0 ~ 1.0 | 0=둥글 ↔ 1=사각 | local bottom-left |
| Q4 corner | 0.0 ~ 1.0 | 0=둥글 ↔ 1=사각 | local bottom-right (중심 향함) |
| innerN | 2.0 ~ 20.0 | 내부 fill superellipse n | inner 3×3 (uniform) |

**렌더링 매핑**:
- `cornerRadius = (1.0 - sliderValue) × (bounds.width / 2)`
  - slider 0 → radius = max → 완전 원형 모서리
  - slider 1 → radius = 0 → 각진 모서리

### 2.3 렌더링 재설계

**Outer ring** (기존 superellipse outerN):
- `RRect.fromRectAndCorners(bounds, topLeft=Q2, topRight=Q1, bottomLeft=Q3, bottomRight=Q4)` 사용
- 구멍: 같은 RRect 로직으로 1모듈 안쪽 rect (evenOdd fill)

**Inner fill** (기존 superellipse innerN):
- **기존과 동일**: `SuperellipsePath.buildPath(innerRect, innerN)` 유지
- 회전은 canvas 단위로 전체 적용되므로 inner 도 함께 회전 (symmetric 하므로 시각적 영향 거의 없음)

**회전 적용**:
```
canvas.save();
canvas.translate(bounds.center.dx, bounds.center.dy);
canvas.rotate(rotationRadians);
canvas.translate(-bounds.center.dx, -bounds.center.dy);
// ... draw outer RRect + inner fill ...
canvas.restore();
```

### 2.4 랜덤 버튼 동작

이전 구현 유지 + 확장:
- Q1/Q2/Q3/Q4 corner: **모두 같은 random 값** (대칭형 눈 보장)
- innerN: **독립 random** (2.0 ~ 20.0)
- 편집기 유지 (이전 버그 수정 반영)

---

## 3. 아키텍처 (How)

### 3.1 Domain Model 변경

**`lib/features/qr_result/domain/entities/qr_shape_params.dart`** — `EyeShapeParams` 재작성:

```dart
class EyeShapeParams {
  final double cornerQ1; // 0.0 (round) ~ 1.0 (square)
  final double cornerQ2;
  final double cornerQ3;
  final double cornerQ4;
  final double innerN;   // 2.0 ~ 20.0

  const EyeShapeParams({
    this.cornerQ1 = 0.0,  // 기본: 모두 둥글 (원형)
    this.cornerQ2 = 0.0,
    this.cornerQ3 = 0.0,
    this.cornerQ4 = 0.0,
    this.innerN = 2.0,    // 기본: 원형 inner
  });

  // 기존 프리셋 매핑 (built-in 참조용으로만 유지)
  static const square   = EyeShapeParams(cornerQ1: 1, cornerQ2: 1, cornerQ3: 1, cornerQ4: 1, innerN: 20);
  static const rounded  = EyeShapeParams(cornerQ1: 0.6, cornerQ2: 0.6, cornerQ3: 0.6, cornerQ4: 0.6, innerN: 20);
  static const circle   = EyeShapeParams(cornerQ1: 0, cornerQ2: 0, cornerQ3: 0, cornerQ4: 0, innerN: 2);
  // ...

  EyeShapeParams copyWith({ ... });
  Map<String, dynamic> toJson() { ... }
  factory EyeShapeParams.fromJson(...) { ... }
  @override bool operator ==(...);
  @override int get hashCode;
}
```

**제거**: `outerN` 필드 (backward-compat 불필요, pre-release).

### 3.2 렌더러 변경

**`lib/features/qr_result/utils/superellipse.dart`** — `paintEye` 시그니처 변경:

```dart
static void paintEye(
  Canvas canvas,
  Rect bounds,
  EyeShapeParams params,
  Paint paint, {
  double rotationDeg = 0.0,  // 신규
}) {
  canvas.save();
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;
  canvas.translate(cx, cy);
  canvas.rotate(rotationDeg * pi / 180);
  canvas.translate(-cx, -cy);

  final m = bounds.width / 7;
  final maxR = bounds.width / 2;

  // Outer ring (RRect 2개: 외곽 + 구멍, evenOdd)
  final outerRadii = _buildCornerRadii(params, maxR);
  final outerRRect = RRect.fromRectAndCorners(bounds, ...outerRadii);
  final holeRect = bounds.deflate(m);
  final holeRadii = _buildCornerRadii(params, maxR - m);  // 모서리 축소
  final holeRRect = RRect.fromRectAndCorners(holeRect, ...holeRadii);

  final ringPath = Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(outerRRect)
    ..addRRect(holeRRect);
  canvas.drawPath(ringPath, paint);

  // Inner fill: 기존 superellipse (innerN)
  final innerRect = bounds.deflate(m * 2);
  canvas.drawPath(buildPath(innerRect, params.innerN), paint);

  canvas.restore();
}
```

### 3.3 Finder 위치별 회전 계산

**`lib/features/qr_result/widgets/custom_qr_painter.dart`** — `_helper.finderBounds` 순회:

```dart
// finderBounds 순서: [top-left, top-right, bottom-left]
const rotations = [0.0, 90.0, -90.0];
final bounds = _helper.finderBounds(m, Offset.zero);
for (int i = 0; i < bounds.length; i++) {
  SuperellipsePath.paintEye(
    canvas, bounds[i], eyeParams, basePaint,
    rotationDeg: rotations[i],
  );
}
```

**`lib/features/qr_result/widgets/qr_preview_section.dart`** — pretty_qr 경로의 `_EyeFinderPattern` 도 동일 처리.

### 3.4 Editor UI

**`lib/features/qr_result/tabs/qr_shape_tab/eye_editor.dart`** — 슬라이더 5개:

```dart
_SliderRow(label: l10n.sliderCornerQ1, value: params.cornerQ1, min: 0, max: 1, ...)
_SliderRow(label: l10n.sliderCornerQ2, ...)
_SliderRow(label: l10n.sliderCornerQ3, ...)
_SliderRow(label: l10n.sliderCornerQ4, ...)
_SliderRow(label: l10n.sliderInnerN, value: params.innerN, min: 2, max: 20, ...)
const SizedBox(height: 16),
_RandomEyeButton(onGenerate: onRandomGenerate),
```

**`lib/features/qr_result/widgets/qr_preview_section.dart:_EyePreviewPainter`** — 편집기 preview 도 새 paintEye 사용 (회전 0° — local orientation 표시).

### 3.5 랜덤 버튼 로직

**`lib/features/qr_result/tabs/qr_shape_tab.dart:_onRandomEyeFromEditor`**:

```dart
void _onRandomEyeFromEditor() {
  final rng = math.Random();
  final cornerValue = rng.nextDouble(); // 4개 모두 동일
  final randomParams = EyeShapeParams(
    cornerQ1: cornerValue,
    cornerQ2: cornerValue,
    cornerQ3: cornerValue,
    cornerQ4: cornerValue,
    innerN: 2.0 + rng.nextDouble() * 18.0,
  );
  setState(() {
    _editEye = randomParams;
    _editingPresetId = null;
  });
  ref.read(qrResultProvider.notifier).setCustomEyeParams(randomParams);
}
```

### 3.6 레거시 데이터 마이그레이션

**사용자 선택: 기존 프리셋 전체 삭제**.

1. **Hive box clear**: 앱 시작 시 `user_eye_presets` box 를 확인하고, 스키마 버전이 구 버전이면 clear.
   - `LocalUserShapePresetDatasource.init()` 에서 첫 load 시 legacy 판정:
     - preset의 JSON에 `outerN` 키 존재 && `cornerQ1` 키 부재 → legacy → 해당 preset 제거
   - 또는 간단히: "eye" 타입 box 전체 clear (사용자가 리팩 전 eye 프리셋 만든 적 없다고 확인됐음)

2. **템플릿 데이터 (`user_qr_template_model`)의 `customEyeParams` 필드**:
   - Hive 저장 형태는 embedded JSON (string blob 이 아니라면 typeAdapter)
   - fromJson 시 legacy `outerN` 발견 → `customEyeParams = null` 처리 (복구 불가, 기본값으로 fallback)

**구현 위치**:
- `lib/features/qr_result/data/datasources/local_user_shape_preset_datasource.dart` — `init()` 에 legacy eye 정리 로직
- `lib/features/qr_result/domain/entities/qr_shape_params.dart` — `EyeShapeParams.fromJson` 에 legacy 감지 (outerN 있으면 null 리턴하게 factory nullable 래퍼 추가 or defaults fallback)

### 3.7 l10n 신규 키

**`lib/l10n/app_ko.arb`**:
```json
"sliderCornerQ1": "Q1 모서리",
"sliderCornerQ2": "Q2 모서리",
"sliderCornerQ3": "Q3 모서리",
"sliderCornerQ4": "Q4 모서리"
```

다른 언어 (`en/fr/de/es/ja/pt/th/vi/zh`) 는 ko fallback 상태 유지 (CLAUDE.md 정책).

---

## 4. 영향 파일 목록

| 파일 | 변경 유형 | 예상 규모 |
|---|---|---|
| `domain/entities/qr_shape_params.dart` | 수정 (EyeShapeParams 재작성) | ~60줄 |
| `utils/superellipse.dart` | 수정 (paintEye 시그니처) | ~50줄 |
| `widgets/custom_qr_painter.dart` | 수정 (rotation loop) | ~10줄 |
| `widgets/qr_preview_section.dart` | 수정 (pretty_qr 경로) | ~15줄 |
| `tabs/qr_shape_tab/eye_editor.dart` | 수정 (슬라이더 2→5개) | ~40줄 |
| `tabs/qr_shape_tab.dart` | 수정 (random 로직) | ~10줄 |
| `data/datasources/local_user_shape_preset_datasource.dart` | 수정 (legacy clear) | ~15줄 |
| `l10n/app_ko.arb` | 수정 (4 키 추가) | ~8줄 |
| `lib/l10n/app_localizations.dart` (generated) | 재생성 | auto |

**총 예상 변경**: 파일 8개 수정, 신규 생성 0개, ~200줄 변경.

---

## 5. Edge Case / 검증 포인트

| 케이스 | 기대 동작 |
|---|---|
| slider 값 모두 0.0 (완전 둥글) | 4 모서리 완전 원형 → 전체가 원형 finder |
| slider 값 모두 1.0 (완전 사각) | 현재 square 빌트인과 시각적으로 동일 |
| cornerQ4 = 0 + 나머지 = 1 | Q4 만 둥글고 나머지 각진 → 3 finder 에서 "중심 향하는 둥근 모서리" 연출 |
| innerN = 2 (원) + corner 모두 1 (사각) | 네모난 외곽 + 원형 내부 fill (비대칭 조합) |
| legacy preset 포함된 Hive 로드 | legacy 판정 → 해당 preset 제거, 에러 없이 빈 목록으로 시작 |
| 랜덤 눈 재생성 연타 | 매번 새 preset 생성, 중복 dedup 되지 않음 (확률 ~0) |
| 빌트인 enum 선택 (QrEyeOuter.square 등) | 회전 없이 기존처럼 렌더 (dim 해제 경로) |

---

## 6. QR 인식률 고려

- RRect 는 corner radius ≤ width/2 조건 하에서 수학적으로 안정 → 인식기 혼란 없음
- finder pattern 의 **3/7 비율 내부 고정**은 유지 (`bounds.deflate(m*2)` 불변)
- 회전은 각 finder 개별에만 적용 — QR 매트릭스 좌표 변경 아님 → 디코더가 finder 감지하는 데 영향 없음
- 최악 조합(모든 corner = 0, innerN = 2) 에서도 QR 스펙상 검은 사각 덩어리가 충분히 존재 → 인식 가능

---

## 7. 향후 확장 (Out of Scope)

- 8-slider (outer+inner 각각 독립 corner) — 편집기 UI 복잡도 tradeoff
- 빌트인 enum 에도 회전 적용 — 별도 피쳐로 분리
- 회전 각도 사용자 지정 (지금은 0° / +90° / -90° 고정) — 수요 확인 후 고려

---

## Next Step

`/pdca design eye-quadrant-corners` — 설계 문서 작성 (본 프로젝트 CLAUDE.md 규약상 3-옵션 비교 스킵하고 R-series 패턴으로 바로 작성).
