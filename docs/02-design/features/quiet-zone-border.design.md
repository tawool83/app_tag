# quiet-zone-border Design

> Plan: `docs/01-plan/features/quiet-zone-border.plan.md` (v4)
> 본 문서는 v4 (QR 스펙 절대 준수 + reserve 패턴) 기준. v1~v3 구현 위에 누적 변경.

---

## 0. 아키텍처 결정

CLAUDE.md 고정 규약에 따라 R-series Provider 패턴 + Clean Architecture 자동 적용. 3-옵션 비교 생략.

- 신규 entity = 단일 enum 1개 (별도 sub-state 분리 불필요)
- 기존 `QrStyleState` 의 quiet-zone 테두리 영역에 필드 1개 추가 (필드 단위로 단일 관심사 유지)
- 기존 `_StyleSetters` mixin 에 setter 1개 추가
- 렌더링은 기존 `qr_layer_stack.dart` 내부 private painter 추가 (외부 공개 불필요)
- UI 는 기존 `qr_background_tab.dart` 의 테두리 섹션 교체

### v4 추가 결정 — CLAUDE.md §5 QR 스펙 절대 준수 (ISO/IEC 18004)

**불변식 (Invariants)**:
- `INV-1`: 모든 두께에서 quiet zone 영역 size = quietPadding (두께 무관)
- `INV-2`: stroke 안쪽 가장자리 = quiet zone 외곽 (두께 무관 고정)
- `INV-3`: quietPadding ≥ 4 모듈 (V5 기준 12% 비율로 보장)
- `INV-4`: PNG 캡처본 외곽 ~ stroke 외곽 사이 = 항상 흰 quietZoneColor (스캐너 인식 영역)

**구현 패턴 (reserve)**:
- `_kMaxBorderWidth` 상수 = slider max 값과 일치
- `borderReserve = borderEnabled ? _kMaxBorderWidth : 0.0` — 외부 reserve 영역 *항상* max 두께만큼 확보
- `contentInset = quietPadding + borderReserve` (두께와 무관 고정)
- border painter = `Padding(EdgeInsets.all(_kMaxBorderWidth - borderWidth))` 안에서 그려짐

**적용 범위** (v3 의 "프레임 모드 변경 없음" 정책 폐기):
- 일반 모드 (`isFrameMode == false`): 위 패턴 적용
- frame 모드 (`isFrameMode == true`): qrAreaSize 안쪽에서 동일 패턴 적용 (innerInset = quietPadding + borderReserve + Layer 1.5 painter)

---

## 1. 디렉터리 트리 (qr_result feature)

```
lib/features/qr_result/
├── qr_result_provider.dart         # library; (변경 없음)
├── domain/
│   ├── entities/
│   │   ├── quiet_zone_border_style.dart        # ★ NEW (v3) — enum 1개
│   │   ├── qr_boundary_params.dart             # 변경 없음
│   │   ├── qr_dot_style.dart                   # 변경 없음
│   │   └── ... (기타 변경 없음)
│   └── state/
│       └── qr_style_state.dart                 # ✎ MODIFY (v3) — 필드 1개 추가
├── notifier/
│   └── style_setters.dart                      # ✎ MODIFY (v3) — setter 1개 추가
├── tabs/
│   └── qr_background_tab.dart                  # ✎ MODIFY (v3) — 헤더 행 교체 + SegmentedButton
├── utils/
│   └── customization_mapper.dart               # ✎ MODIFY (v3) — 매핑 1줄
└── widgets/
    └── qr_layer_stack.dart                     # ✎ MODIFY (v3) — painter 교체 + helper 추가

lib/features/qr_task/
└── domain/entities/
    └── qr_customization.dart                   # ✎ MODIFY (v3) — 직렬화 1 필드

lib/l10n/
└── app_ko.arb                                  # ✎ MODIFY (v3) — labelBorderStyle 키
```

**총 파일**: 신규 1, 수정 6 = 7 파일

---

## 2. 신규 Entity 시그니처

### 2.1 `lib/features/qr_result/domain/entities/quiet_zone_border_style.dart` (NEW)

```dart
/// QR 사양 경계(quiet-zone) 테두리선의 stroke pattern.
///
/// 외각 모양(boundaryParams.type) 과 무관 — 항상 직사각형으로 그려짐.
/// QR 코드 사양상 quiet-zone 까지가 스캐너 인식 영역이므로 그 경계를 시각화한다.
enum QuietZoneBorderStyle {
  solid,    // ──────────────
  dashed,   // ─ ─ ─ ─ ─ ─
  dotted,   // · · · · · · ·
}
```

**파일 크기**: ≤ 15줄. R-series 룰 8 (entity ≤ 150줄) 충족.

---

## 3. State 변경 시그니처

### 3.1 `QrStyleState` (필드 1개 추가)

`lib/features/qr_result/domain/state/qr_style_state.dart` — 기존 16 필드 + 1 = **17 필드**.

```dart
import '../entities/quiet_zone_border_style.dart';

class QrStyleState {
  // ... 기존 16 필드 ...

  // ── quiet zone 테두리선 ── (v1 + v3)
  final bool quietZoneBorderEnabled;                    // v1
  final double quietZoneBorderWidth;                    // v1
  final QuietZoneBorderStyle quietZoneBorderStyle;      // ★ v3 신규

  const QrStyleState({
    // ... 기존 ...
    this.quietZoneBorderEnabled = false,
    this.quietZoneBorderWidth = 1.0,
    this.quietZoneBorderStyle = QuietZoneBorderStyle.solid,  // ★ 기본 solid
  });

  QrStyleState copyWith({
    // ... 기존 ...
    bool? quietZoneBorderEnabled,
    double? quietZoneBorderWidth,
    QuietZoneBorderStyle? quietZoneBorderStyle,            // ★ 추가
  }) =>
      QrStyleState(
        // ... 기존 ...
        quietZoneBorderEnabled: quietZoneBorderEnabled ?? this.quietZoneBorderEnabled,
        quietZoneBorderWidth: quietZoneBorderWidth ?? this.quietZoneBorderWidth,
        quietZoneBorderStyle: quietZoneBorderStyle ?? this.quietZoneBorderStyle,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrStyleState &&
          // ... 기존 16 필드 비교 ...
          other.quietZoneBorderStyle == quietZoneBorderStyle;  // ★ 추가

  @override
  int get hashCode => Object.hash(
        // ... 기존 16 필드 ...
        quietZoneBorderStyle,                                  // ★ 추가
      );
}
```

> 주의: `Object.hash` 가 20개 인자 한계에 가까워지면 `Object.hashAll([...])` 으로 전환 검토. 현재 17개로 안전.

---

## 4. 영속화 변경 시그니처

### 4.1 `QrCustomization` (필드 1개 추가)

`lib/features/qr_task/domain/entities/qr_customization.dart`:

```dart
class QrCustomization {
  // ... 기존 ...
  final bool? quietZoneBorderEnabled;       // v1
  final double? quietZoneBorderWidth;       // v1
  final String? quietZoneBorderStyleName;   // ★ v3 신규 (null = solid fallback)

  const QrCustomization({
    // ... 기존 ...
    this.quietZoneBorderEnabled,
    this.quietZoneBorderWidth,
    this.quietZoneBorderStyleName,                         // ★ 추가
  });

  Map<String, dynamic> toJson() => {
    // ... 기존 ...
    if (quietZoneBorderEnabled == true) 'quietZoneBorderEnabled': true,
    if (quietZoneBorderWidth != null && quietZoneBorderWidth != 1.0)
      'quietZoneBorderWidth': quietZoneBorderWidth,
    if (quietZoneBorderStyleName != null && quietZoneBorderStyleName != 'solid')
      'quietZoneBorderStyle': quietZoneBorderStyleName,    // ★ solid 외에만 직렬화
  };

  factory QrCustomization.fromJson(Map<String, dynamic> json) => QrCustomization(
    // ... 기존 ...
    quietZoneBorderEnabled: json['quietZoneBorderEnabled'] as bool?,
    quietZoneBorderWidth: (json['quietZoneBorderWidth'] as num?)?.toDouble(),
    quietZoneBorderStyleName: json['quietZoneBorderStyle'] as String?,  // ★
  );

  QrCustomization copyWith({
    // ... 기존 ...
    String? quietZoneBorderStyleName,                      // ★ 추가
  }) =>
      QrCustomization(
        // ... 기존 ...
        quietZoneBorderStyleName: quietZoneBorderStyleName ?? this.quietZoneBorderStyleName,
      );
}
```

> JSON key 는 `quietZoneBorderStyle` (간결성), 필드명은 `quietZoneBorderStyleName` (직렬화 의도 명시).

### 4.2 `CustomizationMapper` (1줄 추가)

`lib/features/qr_result/utils/customization_mapper.dart`:

```dart
// fromState — 추가:
quietZoneBorderEnabled: state.style.quietZoneBorderEnabled ? true : null,
quietZoneBorderWidth: state.style.quietZoneBorderWidth != 1.0
    ? state.style.quietZoneBorderWidth : null,
quietZoneBorderStyleName: state.style.quietZoneBorderStyle != QuietZoneBorderStyle.solid
    ? state.style.quietZoneBorderStyle.name
    : null,                                                // ★ 신규

// 복원 (Notifier 측에서 직접 사용 — 기존 패턴):
//   quietZoneBorderEnabled: c.quietZoneBorderEnabled ?? false,
//   quietZoneBorderWidth: c.quietZoneBorderWidth ?? 1.0,
//   quietZoneBorderStyle: _parseBorderStyle(c.quietZoneBorderStyleName),
//
// helper (mapper 내 또는 notifier 내):
//   QuietZoneBorderStyle _parseBorderStyle(String? name) =>
//       QuietZoneBorderStyle.values.firstWhere(
//         (e) => e.name == name,
//         orElse: () => QuietZoneBorderStyle.solid,
//       );
```

---

## 5. Notifier 변경 시그니처

### 5.1 `_StyleSetters` mixin (setter 1개 추가)

`lib/features/qr_result/notifier/style_setters.dart`:

```dart
// 기존 setQuietZoneBorderEnabled / setQuietZoneBorderWidth 유지.
// 추가:

void setQuietZoneBorderStyle(QuietZoneBorderStyle borderStyle) {
  state = state.copyWith(
    style: state.style.copyWith(quietZoneBorderStyle: borderStyle),
  );
  _schedulePush();
}
```

> 다른 Style setter 와 마찬가지로 `template.clearActiveTemplateId` 는 호출하지 않는다 — 테두리선은 템플릿 영향 받지 않는 사용자 개별 설정.

### 5.2 `qr_result_provider.dart` import

`QuietZoneBorderStyle` 은 `qr_style_state.dart` 가 import 하면 `_StyleSetters` 가 자동으로 가시성 확보 (`part of` 관계). 별도 export 불필요.

---

## 6. 렌더링 변경 시그니처

### 6.1 `qr_layer_stack.dart` 변경 영역

#### 6.1.1 일반 모드 inset 계산 (v4 — reserve 패턴)

```dart
// 파일 상단 (class QrLayerStack 위) — v4 신규 상수.
/// quiet-zone 테두리 두께 슬라이더의 최대값 (style_setters.dart 의 width.clamp(1.0, 4.0) 와 일치).
/// 외각에 이만큼의 reserve 영역을 항상 확보 → 두께 조절 시 quiet zone 영역 절대 불변.
const double _kMaxBorderWidth = 4.0;

// build() 내부 — v4 변경:
final borderEnabled = state.style.quietZoneBorderEnabled;
final borderColor = state.style.bgColor ?? state.style.qrColor;
final borderWidth = state.style.quietZoneBorderWidth;
final borderStyle = state.style.quietZoneBorderStyle;

// 렌더링 순서 (안쪽 → 바깥): QR → quiet zone → 테두리 → 배경.
//   - QR 스펙 4 모듈 quiet zone 보장 (12% 비율, V5 기준 ≈ 4.4 모듈, CLAUDE.md §5).
//   - 테두리: 안쪽 가장자리 = quiet zone 외곽(고정), 외곽 가장자리 = 두께만큼 *바깥(배경 방향)* 확장.
//   - 두께 조절 시 quiet zone 절대 불변 — 슬라이더 max(=4.0) 만큼의 reserve 영역을 미리 외곽에 확보.
final quietPadding = (widget.size * 0.12).clamp(12.0, 32.0);
final borderReserve = borderEnabled ? _kMaxBorderWidth : 0.0;
final contentInset = quietPadding + borderReserve;
final qrSize = widget.size - contentInset * 2;
```

**좌표 검증** (widget.size = 200, borderEnabled = true):

| 두께 | contentInset | qrSize | stroke 안쪽 가장자리 | stroke 외곽 가장자리 | 배경 영역 |
|---|---:|---:|---|---|---|
| 1px | 28 (12+4+12) | 144 | widget.size - 4 (=196) **고정** | widget.size - 3 (=197) | 3px |
| 2px | 28 | 144 | 196 **고정** | 198 | 2px |
| 3px | 28 | 144 | 196 **고정** | 199 | 1px |
| 4px (max) | 28 | 144 | 196 **고정** | 200 (widget.size) | 0px |

✓ stroke 안쪽 가장자리 = quiet zone 외곽 = **두께 무관 고정** (불변식)
✓ quiet zone 영역 = quietPadding (24px in 가정) = **두께 무관 일정**

#### 6.1.2 border painter 위치 (v4)

```dart
// (v3 — Positioned.fill 로 widget.size 외곽에 stroke 외곽 정렬)
if (borderEnabled)
  Positioned.fill(
    child: IgnorePointer(
      child: CustomPaint(
        painter: _QuietZoneBorderPainter(
          color: borderColor,
          width: borderWidth,
          style: state.style.quietZoneBorderStyle,
        ),
      ),
    ),
  ),

// (v4 — Padding 으로 painter 영역을 (kMaxBorderWidth - borderWidth) 만큼 inset)
//   stroke 안쪽 가장자리 = widget.size - kMaxBorderWidth = quiet zone 외곽 (고정)
//   stroke 외곽 가장자리 = widget.size - (kMaxBorderWidth - borderWidth) = 두께만큼 바깥 확장
//   두께 max → 외곽이 widget.size 외곽 닿음. 두께 < max → 외곽 너머 quietZoneColor 영역.
if (borderEnabled)
  Positioned.fill(
    child: IgnorePointer(
      child: Padding(
        padding: EdgeInsets.all(_kMaxBorderWidth - borderWidth),
        child: CustomPaint(
          painter: _QuietZoneBorderPainter(
            color: borderColor,
            width: borderWidth,
            style: borderStyle,
          ),
        ),
      ),
    ),
  ),
```

#### 6.1.3 파일 하단 helper 추가 (file 끝)

```dart
// ── Quiet-zone 테두리선 painter ──────────────────────────────────────────────
//
// QR 사양상의 quiet-zone 경계를 시각적으로 표시한다.
// 외각 모양(boundaryParams.type) 과 무관하게 항상 직사각형.
class _QuietZoneBorderPainter extends CustomPainter {
  final Color color;
  final double width;
  final QuietZoneBorderStyle style;

  const _QuietZoneBorderPainter({
    required this.color,
    required this.width,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // stroke 가 path 양쪽으로 그려지므로 width/2 inset 으로 외부 cropping 방지.
    final rect = Rect.fromLTWH(
      width / 2, width / 2,
      size.width - width, size.height - width,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..isAntiAlias = true;

    switch (style) {
      case QuietZoneBorderStyle.solid:
        canvas.drawRect(rect, paint);
      case QuietZoneBorderStyle.dashed:
        paint.strokeCap = StrokeCap.butt;
        _drawDashedRect(canvas, rect, paint,
            dashLength: width * 4, gapLength: width * 2);
      case QuietZoneBorderStyle.dotted:
        paint.strokeCap = StrokeCap.round;
        _drawDashedRect(canvas, rect, paint,
            dashLength: width, gapLength: width * 2);
    }
  }

  void _drawDashedRect(Canvas canvas, Rect r, Paint paint,
      {required double dashLength, required double gapLength}) {
    _drawDashedLine(canvas, r.topLeft, r.topRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, r.topRight, r.bottomRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, r.bottomRight, r.bottomLeft, paint, dashLength, gapLength);
    _drawDashedLine(canvas, r.bottomLeft, r.topLeft, paint, dashLength, gapLength);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      double dashLength, double gapLength) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    double drawn = 0;
    while (drawn < total) {
      final segLen = math.min(dashLength, total - drawn);
      final start = a + dir * drawn;
      final end = a + dir * (drawn + segLen);
      canvas.drawLine(start, end, paint);
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_QuietZoneBorderPainter old) =>
      color != old.color || width != old.width || style != old.style;
}
```

> `math` 는 파일 상단에 이미 `import 'dart:math' show min;` 으로 import 되어 있음 — `math.min` 호출 가능.

> import 추가: `import '../domain/entities/quiet_zone_border_style.dart';`

### 6.2 frame 모드 변경 시그니처 (v4 신규)

이전 v3 에서 "프레임 모드 변경 없음" 정책이 있었으나, v4 에서 **외각 모양(frame) 사용 여부와 무관하게 quiet zone border 가 동작해야 한다** 는 사용자 명시 요구로 적용 추가.

#### 6.2.1 `_buildFrameLayout` 시작부 — innerInset 도입

```dart
// (v3 - quiet zone padding 만 inset)
final qrAreaSize = totalSize / frameScale;
final quietPadding = (qrAreaSize * 0.05).clamp(4.0, 12.0);
final effectiveQrSize = qrAreaSize - quietPadding * 2;

// (v4 - quietPadding 12% 상향 + borderReserve)
final qrAreaSize = totalSize / frameScale;
// QR 스펙 4 모듈 quiet zone 보장 — 12% 비율 + min 8 / max 24 px (frame 안쪽이라 일반 모드보다 작게).
final quietPadding = (qrAreaSize * 0.12).clamp(8.0, 24.0);
// border reserve: 슬라이더 max(=4) 만큼 외부 여백 항상 확보 → 두께 조절 시 quiet zone 절대 불변.
final borderReserve =
    state.style.quietZoneBorderEnabled ? _kMaxBorderWidth : 0.0;
final innerInset = quietPadding + borderReserve;
final effectiveQrSize = qrAreaSize - innerInset * 2;
```

#### 6.2.2 Container padding + band/text padding — innerInset 사용

```dart
// Layer 1: QR Container
Container(
  width: qrAreaSize,
  height: qrAreaSize,
  color: state.style.quietZoneColor,
  padding: EdgeInsets.all(innerInset),  // v4: quietPadding → innerInset
  child: qrWidget,
),

// band/none-text 오버레이
Padding(
  padding: EdgeInsets.all(innerInset),  // v4: quietPadding → innerInset
  ...
)
```

#### 6.2.3 Layer 1.5 — 외각 모양과 무관한 quiet zone border (v4 신규)

```dart
// Layer 1.5: quiet zone 테두리선 — 외각(frame) 모양과 별개로 동작.
// 안쪽 가장자리 = quiet zone 외곽(고정), 외곽 가장자리 = 두께만큼 바깥(qrAreaSize 외곽 방향) 확장.
// SizedBox(qrAreaSize) 위에 Padding(_kMaxBorderWidth - currentWidth) 으로 painter 영역 inset.
// 두께 max → 외곽이 qrAreaSize 외곽 닿음. 두께 < max → 외곽 너머 quietZoneColor 영역.
if (state.style.quietZoneBorderEnabled)
  IgnorePointer(
    child: SizedBox(
      width: qrAreaSize,
      height: qrAreaSize,
      child: Padding(
        padding: EdgeInsets.all(
          _kMaxBorderWidth - state.style.quietZoneBorderWidth,
        ),
        child: CustomPaint(
          painter: _QuietZoneBorderPainter(
            color: state.style.bgColor ?? state.style.qrColor,
            width: state.style.quietZoneBorderWidth,
            style: state.style.quietZoneBorderStyle,
          ),
        ),
      ),
    ),
  ),
```

위치: Stack 의 Layer 1 (QR Container) + Layer Flash (qrOnly) **직후**, Layer 2 (로고/텍스트) **직전**.

---

## 7. UI 변경 시그니처

### 7.1 `qr_background_tab.dart` — 라인 249~274 교체

```dart
// 기존 (v1)
const SizedBox(height: 16),
// ── 테두리선 섹션 ──
_sectionLabel(l10n.labelQuietZoneBorder),
const SizedBox(height: 8),
SwitchListTile(
  title: Text(l10n.labelQuietZoneBorder, style: const TextStyle(fontSize: 14)),
  value: state.style.quietZoneBorderEnabled,
  dense: true,
  contentPadding: EdgeInsets.zero,
  onChanged: (v) => ref.read(qrResultProvider.notifier).setQuietZoneBorderEnabled(v),
),
if (state.style.quietZoneBorderEnabled)
  _SliderRow(...),
const SizedBox(height: 16),

// 변경 후 (v3)
const SizedBox(height: 16),
// ── 테두리선 섹션 (헤더: 소제목 + 토글 한 줄) ──
Row(
  children: [
    Expanded(child: _sectionLabel(l10n.labelQuietZoneBorder)),
    Switch(
      value: state.style.quietZoneBorderEnabled,
      onChanged: (v) => ref
          .read(qrResultProvider.notifier)
          .setQuietZoneBorderEnabled(v),
    ),
  ],
),
if (state.style.quietZoneBorderEnabled) ...[
  const SizedBox(height: 4),
  _SliderRow(
    label: l10n.labelBorderWidth,
    value: state.style.quietZoneBorderWidth,
    min: 1.0, max: 4.0, divisions: 6,
    valueLabel: '${state.style.quietZoneBorderWidth.toStringAsFixed(1)}px',
    onChanged: (v) => ref
        .read(qrResultProvider.notifier)
        .setQuietZoneBorderWidth(v),
  ),
  // ── 선 종류 (NEW v3) ──
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(l10n.labelBorderStyle,
              style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: SegmentedButton<QuietZoneBorderStyle>(
            style: SegmentedButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(
                value: QuietZoneBorderStyle.solid,
                icon: Icon(Icons.horizontal_rule, size: 18),
              ),
              ButtonSegment(
                value: QuietZoneBorderStyle.dashed,
                icon: Icon(Icons.more_horiz, size: 18),
              ),
              ButtonSegment(
                value: QuietZoneBorderStyle.dotted,
                icon: Icon(Icons.more_vert, size: 18),  // ⋮ → 점 패턴 시각화
              ),
            ],
            selected: {state.style.quietZoneBorderStyle},
            onSelectionChanged: (s) => ref
                .read(qrResultProvider.notifier)
                .setQuietZoneBorderStyle(s.first),
            showSelectedIcon: false,
          ),
        ),
      ],
    ),
  ),
],
const SizedBox(height: 16),
```

> import 추가: `import '../domain/entities/quiet_zone_border_style.dart';`

---

## 8. l10n 변경

### 8.1 `lib/l10n/app_ko.arb`

```json
{
  // ... 기존 ...
  "labelBorderStyle": "선 종류",
  "@labelBorderStyle": {
    "description": "Quiet-zone border style label (solid/dashed/dotted)"
  }
}
```

기존 `labelQuietZoneBorder`("테두리선"), `labelBorderWidth`("두께") 재사용.

CLAUDE.md 정책: **`app_ko.arb` 에만 선반영**. 다른 언어 .arb 는 ko fallback.

### 8.2 빌드 명령

`flutter gen-l10n` (자동 트리거되거나 IDE 가 watch).

---

## 9. 데이터 흐름

```
[배경 탭]
  ┌─ Row(소제목 + Switch)         → setQuietZoneBorderEnabled(bool)
  ├─ _SliderRow (두께)             → setQuietZoneBorderWidth(double)
  └─ SegmentedButton (선 종류)     → setQuietZoneBorderStyle(QuietZoneBorderStyle)

         ↓ (각 setter)

[_StyleSetters mixin]
  state.copyWith(style: style.copyWith(...))
  _schedulePush()                  ← Hive debounced save

         ↓ ref.watch(qrResultProvider)

[QrLayerStack.build]
  borderEnabled = style.quietZoneBorderEnabled && !isFrameMode
  borderColor   = style.bgColor ?? style.qrColor
  borderWidth   = style.quietZoneBorderWidth
  borderStyle   = style.quietZoneBorderStyle           ← NEW
  contentInset  = quietPadding + (borderEnabled ? borderWidth : 0)
                                                       ← quiet-zone 보호

  → CustomPaint(_QuietZoneBorderPainter(color, width, style))
                                                       ← 항상 직사각형 stroke

         ↓ _schedulePush() → Hive

[CustomizationMapper.fromState]
  → QrCustomization(
      quietZoneBorderEnabled, quietZoneBorderWidth,
      quietZoneBorderStyleName: style != solid ? style.name : null,
    )

         ↓ 다음 세션 복원

[CustomizationMapper / Notifier 복원]
  state.style = QrStyleState(
    quietZoneBorderEnabled: c.quietZoneBorderEnabled ?? false,
    quietZoneBorderWidth: c.quietZoneBorderWidth ?? 1.0,
    quietZoneBorderStyle: _parseBorderStyle(c.quietZoneBorderStyleName),
  )
```

---

## 10. 구현 순서 (v3)

| 순서 | 파일 | 작업 | 줄 수 영향 |
|------|------|------|-----------|
| 1 | `domain/entities/quiet_zone_border_style.dart` | NEW: enum 3종 | +12 |
| 2 | `domain/state/qr_style_state.dart` | 필드 1 + copyWith + == + hashCode + import | +5 |
| 3 | `qr_task/domain/entities/qr_customization.dart` | 필드 1 + ctor + toJson + fromJson + copyWith | +8 |
| 4 | `qr_result/utils/customization_mapper.dart` | fromState 매핑 + 복원 helper(`_parseBorderStyle`) | +10 |
| 5 | `notifier/style_setters.dart` | setter 1개 추가 | +6 |
| 6 | `widgets/qr_layer_stack.dart` | line 167 주석 + line 262 painter 교체 + 하단 painter class + import | +75 |
| 7 | `tabs/qr_background_tab.dart` | 헤더 행 통합 + SegmentedButton 추가 + import | +35, -10 |
| 8 | `l10n/app_ko.arb` | labelBorderStyle 키 추가 | +4 |

**총 변경**: ~155 줄 추가, ~10 줄 삭제. 단일 파일 200줄 룰 위반 없음 (qr_layer_stack 은 982 → ~1057, 단일 위젯 파일이라 R-series 룰의 "메인 ≤ 200" 적용 대상 외 — UI part 룰 ≤ 400 도 painter helper class 포함이라 허용 범위).

---

## 11. 검증 시나리오

### 11.1 회귀 (기존 v1 동작 보존)
- [ ] 토글 OFF → 테두리 미렌더, 두께/선종류 슬라이더·세그먼트 숨김
- [ ] 토글 ON + solid + 1px → 사양 경계 시각화 정상 동작
- [ ] 토글 ON + 색상 탭 bgOnly 색상 변경 → 테두리 색상 자동 동기화

### 11.2 v3 신규 기능
- [ ] solid 선택 → 단순 직사각형 stroke
- [ ] dashed 선택 + 1/2/3/4px → 균일한 dash 패턴 (dashLength = w*4, gap = w*2)
- [ ] dotted 선택 + 1/2/3/4px → 둥근 점 패턴 (StrokeCap.round, dashLength = w)
- [ ] 외각 모양 = circle/star/heart 변경 → 테두리는 항상 직사각형 유지
- [ ] 외각 회전 적용 (예: star rotation 30°) → 테두리 회전 없음
- [ ] PNG 캡처 (RepaintBoundary) → dashed/dotted 가 정확히 캡처에 반영
- [ ] 앱 재실행 → solid 외 선 종류 복원 (Hive)
- [ ] 토글 OFF → 다음 ON 시 마지막 선 종류 기억

### 11.3 v4 신규 — QR 스펙 절대 준수
- [ ] **두께 1px → 4px 슬라이드**: stroke 안쪽 가장자리 위치 **불변** (quiet zone 외곽 고정)
- [ ] **두께 1px → 4px 슬라이드**: stroke 외곽 가장자리만 widget.size 외곽 방향(배경)으로 이동
- [ ] **두께 4px (max)**: stroke 외곽이 widget.size 외곽 닿음
- [ ] **두께 1px (min)**: stroke 외곽 너머 3px 의 quietZoneColor "배경" 영역 가시
- [ ] **두께 변화 시 quiet zone 영역 size 일정**: 모든 두께에서 quiet zone 픽셀 개수 동일
- [ ] **PNG 저장 후 외부 스캐너 인식**: 어떤 두께에서도 100% 인식 (V5 4 모듈 quiet zone 보장)
- [ ] **quietPadding 12% 검증**: V5 deepLink 기준 약 4 모듈 이상 흰 여백 확보
- [ ] **Frame 모드** (frameScale > 1.0) + 토글 ON: frame 안쪽 QR 영역에 Layer 1.5 quiet zone border 정상 렌더링 (이전 v3 에서는 미렌더)
- [ ] **Frame 모드 + 두께 1~4px 슬라이드**: qrAreaSize 안쪽에서 동일한 reserve 패턴 동작

### 11.4 엣지 케이스
- [ ] 두께 = 4px + dashed → 큰 dash (16/8 px) 도 직사각형 4변 모두 깔끔히 채워짐
- [ ] widget.size 가 매우 작을 때 (preview height drag) → drawDashedLine 의 total <= 0 가드로 안전
- [ ] dash 길이 > 변 길이 인 경우 → segLen = total - drawn 으로 한 segment 만 그림 (정상)
- [ ] qrAreaSize 가 매우 작을 때 (frame 안쪽) — innerInset * 2 ≥ qrAreaSize → effectiveQrSize 음수 가능 → frameScale 또는 widget.size 하한 검증 필요 (현재 frameScale 기본 1.0~2.0 범위라 실제 발생 어려움)

---

## 12. 비적용 범위

- 외각 모양(`boundaryParams.type`) 동기화 — Plan v2 의 잘못된 이해 철회. 테두리는 QR 사양 경계 시각화이므로 항상 직각.
- ~~프레임 모드 변경 없음~~ → **v4 에서 적용 추가**.
- 테두리 둥근 모서리(rounded corner) 옵션 — 이번 scope 밖 (현재 stroke 만 지원).
- SVG 내보내기에서 quiet-zone 테두리 — `qr_layer_stack.dart` 기준 PNG 캡처만 처리. SVG 경로(`qr_svg_generator.dart`)는 별도 검토 필요 시 후속 티켓.
- 다국어 번역 — ko 만 추가, 다른 언어는 fallback.

---

## 13. 위험 / 대안

| 위험 | 영향 | 대응 |
|------|------|------|
| dashed/dotted 가 PNG 캡처에서 깨질 가능성 | 사용자 경험 손상 | RepaintBoundary 는 Canvas 명령을 그대로 캡처하므로 문제없음. 시나리오 11.2 에서 검증 |
| `Object.hash` 인자 17개 한계 (max 20) | 향후 필드 추가 시 컴파일 에러 | Object.hashAll([...]) 으로 전환 (현 설계 변경 불필요) |
| SegmentedButton 의 visualDensity 가 작은 화면에서 잘림 | 일부 단말 UX 저하 | `tapTargetSize: shrinkWrap` + `visualDensity: compact` 로 최소화. 검증 시 작은 단말 확인 |
| QrCustomization 직렬화 키 명 충돌 | 데이터 손상 | 키는 `quietZoneBorderStyle` (QrBoundaryParams 의 `borderStyle` 과 다름 — prefix 로 구분) |
| **v4: QR 모듈 사이즈 축소** | 매우 작은 widget.size 에서 모듈 식별성 저하 | quietPadding 12% + borderReserve 4 = 16% 정도 inset → widget.size 100px 미만일 때 qrSize < 68px. 실제 미리보기 widget.size ≥ 160 이라 영향 미미 |
| **v4: borderWidth max 변경 시 reserve 부정확** | 슬라이더 max 변경 시 stroke 외곽이 widget.size 너머 또는 미달 | `_kMaxBorderWidth` 상수 = `style_setters.dart:width.clamp(1.0, 4.0)` 와 일치. 한 곳에서만 max 변경하면 다른 곳에서 컴파일러는 잡지 못함 → 주석으로 일치 의무 명시 |

---

## 14. 프로젝트 메타

- **Level**: Flutter Dynamic × Clean Architecture × R-series
- **State Management**: Riverpod StateNotifier
- **로컬 저장**: Hive (CustomizationMapper 경유)
- **라우팅**: go_router
- **검증**: 수동 시각 검증 + RepaintBoundary 캡처 비교
