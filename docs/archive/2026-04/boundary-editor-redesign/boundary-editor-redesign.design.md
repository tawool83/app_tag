# Design: boundary-editor-redesign — 맞춤 외곽 에디터 UI 재설계

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 외곽 종류가 ChoiceChip 나열로 공간 비효율, 외곽선 스타일 미제공, 배경/QR 색상 독립 제어 불가 |
| **Solution** | 외곽 종류 드롭다운 전환 + 외곽선 종류/두께 추가 + 색상 탭 ColorTargetMode로 QR/배경 독립 색상 제어 |
| **Function UX Effect** | 에디터 상단 1행 컴팩트 배치, 색상 탭에서 동시/QR/배경 칩 선택으로 일괄 색상 적용 |
| **Core Value** | QR 프레임 표현력 확장 — 외곽선 스타일 + 색상 탭 통합 색상 제어 |

---

## 1. 디렉터리 구조

기존 `qr_result` feature 내 확장. 신규 feature 디렉터리 불필요.

```
lib/features/qr_result/
├── domain/entities/
│   ├── qr_border_style.dart          ← 신규: QrBorderStyle enum
│   ├── qr_boundary_params.dart       ← 수정: 4개 필드 추가
│   └── color_target_mode.dart        ← 신규: ColorTargetMode enum
├── domain/state/
│   └── qr_style_state.dart           ← 수정: bgColor, bgGradient 필드 추가
├── tabs/qr_shape_tab/
│   └── boundary_editor.dart          ← 수정: UI 전면 재설계 (색상 피커 제거)
├── tabs/qr_color_tab.dart            ← 수정: ColorTargetMode 칩 + 라우팅
├── tabs/qr_color_tab/shared.dart     ← 수정: _ColorTargetChips, _FrameColorSection 제거
├── widgets/
│   ├── decorative_frame_painter.dart  ← 수정: 외곽선 stroke + shader 필드 추가
│   └── qr_layer_stack.dart           ← 수정: bgColor/bgGradient 독립 색상 + 로고 비율 수정
├── utils/
│   ├── qr_svg_generator.dart         ← 수정: SVG 외곽선 렌더링
│   ├── qr_margin_painter.dart        ← 수정: 패턴 메서드에 Shader? 파라미터 추가
│   └── dash_path_util.dart           ← 신규: Canvas dash path 유틸
├── notifier/
│   └── style_setters.dart            ← 수정: setBgColor, setBgGradient, clearBgOverrides 추가
├── qr_result_provider.dart           ← 수정: colorTargetModeProvider 추가
└── qr_result_screen.dart             ← 수정: QrColorTab onChanged 콜백 단순화
```

---

## 2. Entity 시그니처

### 2.1 `QrBorderStyle` (신규)

```dart
// lib/features/qr_result/domain/entities/qr_border_style.dart

/// QR 프레임 외곽선 스타일.
enum QrBorderStyle {
  none,      // 외곽선 없음
  solid,     // ────── 실선
  dashed,    // -- -- -- 파선
  dotted,    // ·····  점선
  dashDot,   // -·-·-· 일점쇄선
  double_,   // ══════ 이중선
}
```

### 2.2 `QrBoundaryParams` 필드 추가

```dart
// 기존 10개 필드 유지 + 신규 4개 추가 (총 14개)

class QrBoundaryParams {
  // ── 기존 (10개) ──
  final QrBoundaryType type;
  final double superellipseN;
  final int starVertices;
  final double starInnerRadius;
  final double rotation;
  final double padding;
  final double roundness;
  final double frameScale;
  final QrMarginPattern marginPattern;
  final double patternDensity;

  // ── 신규 (4개) ──
  final QrBorderStyle borderStyle;    // 기본: QrBorderStyle.solid
  final int borderColorArgb;          // 기본: 0xFF000000
  final double borderWidth;           // 기본: 2.0 (범위: 1.0~6.0)
  final int? patternColorArgb;        // null = 자동계산 (qrColor * 0.4)

  const QrBoundaryParams({
    // ... 기존 파라미터 ...
    this.borderStyle = QrBorderStyle.solid,
    this.borderColorArgb = 0xFF000000,
    this.borderWidth = 2.0,
    this.patternColorArgb,
  });
}
```

#### copyWith 시그니처

```dart
QrBoundaryParams copyWith({
  // ... 기존 10개 ...
  QrBorderStyle? borderStyle,
  int? borderColorArgb,
  double? borderWidth,
  int? patternColorArgb,
  bool clearPatternColor = false,  // nullable 필드 clearing
}) => QrBoundaryParams(
  // ... 기존 ...
  borderStyle: borderStyle ?? this.borderStyle,
  borderColorArgb: borderColorArgb ?? this.borderColorArgb,
  borderWidth: borderWidth ?? this.borderWidth,
  patternColorArgb: clearPatternColor
      ? null
      : (patternColorArgb ?? this.patternColorArgb),
);
```

#### toJson / fromJson

```dart
Map<String, dynamic> toJson() => {
  // ... 기존 10개 ...
  'borderStyle': borderStyle.name,
  'borderColorArgb': borderColorArgb,
  'borderWidth': borderWidth,
  if (patternColorArgb != null) 'patternColorArgb': patternColorArgb,
};

factory QrBoundaryParams.fromJson(Map<String, dynamic> json) {
  // ... 기존 ...
  final borderStyleName = json['borderStyle'] as String?;
  return QrBoundaryParams(
    // ... 기존 ...
    borderStyle: borderStyleName == null
        ? QrBorderStyle.solid
        : QrBorderStyle.values.firstWhere(
            (e) => e.name == borderStyleName,
            orElse: () => QrBorderStyle.solid,
          ),
    borderColorArgb: json['borderColorArgb'] as int? ?? 0xFF000000,
    borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 2.0,
    patternColorArgb: json['patternColorArgb'] as int?,
  );
}
```

#### == / hashCode

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is QrBoundaryParams &&
        // ... 기존 10개 ...
        borderStyle == other.borderStyle &&
        borderColorArgb == other.borderColorArgb &&
        borderWidth == other.borderWidth &&
        patternColorArgb == other.patternColorArgb;

@override
int get hashCode => Object.hash(
      // ... 기존 10개 ...
      borderStyle, borderColorArgb, borderWidth, patternColorArgb,
    );
```

**참고**: `Object.hash` 는 최대 20개 파라미터 지원. 14개는 안전 범위.

---

## 3. UI 재설계: `_BoundaryEditor`

### 3.1 전체 레이아웃

**색상 제어는 boundary editor에서 제거** — 색상 탭의 ColorTargetMode(동시/QR/배경)로 통합.
boundary editor는 **형태와 구조** 파라미터만 담당.

```
┌──────────────────────────────────────────────────┐
│ [외곽 종류 ▼ Dropdown]   [선 종류 ▼]              │  Row 1
├──────────────────────────────────────────────────┤
│ 선 두께 ───────●────── 2.0               │  Row 2 (borderStyle != none)
├──────────────────────────────────────────────────┤
│ 프레임 크기 ──────●──── 1.4x             │  Row 3
├──────────────────────────────────────────────────┤
│ [타입별 슬라이더: N값 / 별 꼭짓점 / 별 깊이]      │  Row 4 (conditional)
├──────────────────────────────────────────────────┤
│ 회전 ────────────●──── 0°                │  Row 5
├──────────────────────────────────────────────────┤
│ 둥글기 ──────────●──── 0.00              │  Row 6 (star/hexagon)
├──────────────────────────────────────────────────┤
│ [마진 패턴 ▼ Dropdown]                           │  Row 7 (isFrameMode)
├──────────────────────────────────────────────────┤
│ 패턴 밀도 ───────●──── 1.0x              │  Row 8 (pattern != none)
├──────────────────────────────────────────────────┤
│ 패딩 ────────────●──── 5%                │  Row 9 (!isFrameMode)
└──────────────────────────────────────────────────┘
```

### 3.2 Row 1: 외곽 종류 + 선 종류

```dart
Row(
  children: [
    // 외곽 종류 드롭다운
    Expanded(
      child: DropdownButtonFormField<QrBoundaryType>(
        initialValue: params.type,
        items: _boundaryTypes.map(...).toList(),
        onChanged: (type) { /* update params */ },
      ),
    ),
    SizedBox(width: 8),
    // 선 종류 드롭다운
    Expanded(
      child: DropdownButtonFormField<QrBorderStyle>(
        initialValue: params.borderStyle,
        items: QrBorderStyle.values.map(...).toList(),
        onChanged: (style) { /* update params */ },
      ),
    ),
  ],
),
```

**`_boundaryTypes`** 목록: `[square, circle, superellipse, star, heart, hexagon]`
- `square` 는 `l10n.boundaryNone` ("없음") 으로 표시 — 프레임 해제 역할

### 3.3 색상 제어: 색상 탭 통합 (별도 색상 피커 없음)

외곽선 색상·패턴 색상은 **색상 탭의 ColorTargetMode** 로 제어.
boundary editor 내 `_ColorDot`, `_openColorPicker` 는 **불필요** — 색상 탭에서:

- **동시** (기본): QR 도트 + 배경 패턴/테두리 동일 색상
- **QR**: QR 도트만 색상 변경
- **배경**: 배경 패턴/테두리만 색상 변경

상세는 **Section 6. 색상 통합 아키텍처** 참조.

### 3.4 마진 패턴 (Row 7)

```dart
// isFrameMode 일 때만 표시
if (params.isFrameMode) ...[
  SizedBox(height: 12),
  DropdownButtonFormField<QrMarginPattern>(
    initialValue: params.marginPattern,
    items: QrMarginPattern.values.map(...).toList(),
    onChanged: (p) {
      final updated = params.copyWith(marginPattern: p);
      onChanged(updated);
      onDragEnd(updated);
    },
  ),
],
```

### 3.5 드롭다운 라벨 매핑

```dart
static String _boundaryTypeLabel(QrBoundaryType t, AppLocalizations l10n) {
  return switch (t) {
    QrBoundaryType.square => l10n.boundaryNone,
    QrBoundaryType.circle => l10n.boundaryCircle,
    QrBoundaryType.superellipse => l10n.boundarySuperellipse,
    QrBoundaryType.star => l10n.boundaryStar,
    QrBoundaryType.heart => l10n.boundaryHeart,
    QrBoundaryType.hexagon => l10n.boundaryHexagon,
    _ => t.name,
  };
}

static String _borderStyleLabel(QrBorderStyle s, AppLocalizations l10n) {
  return switch (s) {
    QrBorderStyle.none => l10n.borderNone,
    QrBorderStyle.solid => l10n.borderSolid,
    QrBorderStyle.dashed => l10n.borderDashed,
    QrBorderStyle.dotted => l10n.borderDotted,
    QrBorderStyle.dashDot => l10n.borderDashDot,
    QrBorderStyle.double_ => l10n.borderDouble,
  };
}
```

---

## 4. 렌더링: Canvas (`DecorativeFramePainter`)

### 4.1 현재 `paint()` 흐름

```
1. buildClipPath → framePath
2. canvas.clipPath(framePath)
3. canvas.drawRect(배경색 fill)
4. marginClip = framePath - qrRect (차집합)
5. canvas.clipPath(marginClip) → 패턴 렌더
```

### 4.2 추가할 외곽선 렌더링

```
6. 외곽선 stroke (borderStyle != none)
   → framePath 를 borderStyle/borderColor/borderWidth 로 stroke
```

### 4.3 `DecorativeFramePainter` 필드 구조

```dart
class DecorativeFramePainter extends CustomPainter {
  // ── 기존 필드 ──
  final QrBoundaryParams boundaryParams;
  final double qrAreaSize;
  final Color frameColor;
  final Color patternColor;

  // ── 신규 필드 ──
  final Shader? patternShader;   // 배경 그라디언트 → 패턴에 적용
  final Color borderColor;       // 외곽선 색상 (bgColor ?? qrColor)
  final Shader? borderShader;    // 배경 그라디언트 → 외곽선에 적용
  final DotShapeParams dotParams; // QR dot 패턴에서 재사용 (qrDots 마진 패턴용)
}
```

**설계 결정**: 외곽선 스타일(`borderStyle`, `borderWidth`)은 `boundaryParams` 에서 직접 읽고,
색상/그라디언트는 `qr_layer_stack.dart` 에서 bgColor/bgGradient 시스템으로 계산하여 별도 필드로 전달.
`Paint.shader` 가 설정되면 `Paint.color` 를 override 하므로, 단색/그라디언트 분기를 caller 에서 처리.

### 4.4 Dash Path 구현: `dash_path_util.dart`

외부 패키지(`path_drawing`) 대신 경량 유틸 자체 구현. dash path 기능만 필요하므로 의존성 추가 불필요.

```dart
// lib/features/qr_result/utils/dash_path_util.dart

import 'dart:ui';

/// Path 를 dash array 패턴으로 변환.
///
/// [dashArray] 는 [on, off, on, off, ...] 패턴.
/// 예: [8, 4] → 8px 선, 4px 간격 반복.
Path dashPath(Path source, List<double> dashArray) {
  final result = Path();
  if (dashArray.isEmpty) return result;

  for (final metric in source.computeMetrics()) {
    double distance = 0.0;
    int idx = 0;
    bool draw = true;

    while (distance < metric.length) {
      final len = dashArray[idx % dashArray.length];
      final next = (distance + len).clamp(0.0, metric.length);
      if (draw) {
        result.addPath(
          metric.extractPath(distance, next),
          Offset.zero,
        );
      }
      distance = next;
      idx++;
      draw = !draw;
    }
  }
  return result;
}
```

### 4.5 `paint()` 에 외곽선 추가 (의사코드)

```dart
@override
void paint(Canvas canvas, Size size) {
  final framePath = QrBoundaryClipper.buildClipPath(size, boundaryParams);
  if (framePath == null) return;

  canvas.save();
  canvas.clipPath(framePath);

  // 배경 fill
  canvas.drawRect(Offset.zero & size, Paint()..color = frameColor);

  // 마진 패턴
  if (boundaryParams.marginPattern != QrMarginPattern.none) {
    // ... 기존 로직 ...
  }

  canvas.restore();

  // ── 신규: 외곽선 stroke ──
  _drawBorder(canvas, size, framePath);
}

void _drawBorder(Canvas canvas, Size size, Path framePath) {
  final style = boundaryParams.borderStyle;
  if (style == QrBorderStyle.none) return;

  final borderPaint = Paint()
    ..color = borderColor        // qr_layer_stack 에서 bgColor ?? qrColor 로 계산
    ..style = PaintingStyle.stroke
    ..strokeWidth = boundaryParams.borderWidth
    ..isAntiAlias = true;
  if (borderShader != null) borderPaint.shader = borderShader; // 그라디언트 우선

  switch (style) {
    case QrBorderStyle.solid:
      canvas.drawPath(framePath, borderPaint);
    case QrBorderStyle.dashed:
      canvas.drawPath(dashPath(framePath, [8, 4]), borderPaint);
    case QrBorderStyle.dotted:
      borderPaint.strokeCap = StrokeCap.round;
      canvas.drawPath(dashPath(framePath, [2, 3]), borderPaint);
    case QrBorderStyle.dashDot:
      canvas.drawPath(dashPath(framePath, [8, 4, 2, 4]), borderPaint);
    case QrBorderStyle.double_:
      borderPaint.strokeWidth = boundaryParams.borderWidth * 0.4;
      canvas.drawPath(framePath, borderPaint);
      // 내부 축소 path
      final scale = 1.0 - (boundaryParams.borderWidth * 3 / size.width);
      final matrix = Matrix4.identity()
        ..translate(size.width / 2, size.height / 2)
        ..scale(scale, scale)
        ..translate(-size.width / 2, -size.height / 2);
      final innerPath = framePath.transform(matrix.storage);
      canvas.drawPath(innerPath, borderPaint);
    case QrBorderStyle.none:
      break;
  }
}
```

### 4.6 `shouldRepaint` 업데이트

`boundaryParams` 비교에 더해, 신규 필드들도 비교에 포함:

```dart
@override
bool shouldRepaint(DecorativeFramePainter old) =>
    boundaryParams != old.boundaryParams ||
    patternColor != old.patternColor ||
    patternShader != old.patternShader ||
    borderColor != old.borderColor ||
    borderShader != old.borderShader ||
    dotParams != old.dotParams ||
    // ... 기존 비교 ...
```

---

## 5. 렌더링: SVG (`QrSvgGenerator`)

### 5.1 현재 상태

SVG 생성기는 **프레임 모드를 지원하지 않음** (clipPath 모드만). 외곽선 렌더링은 clipPath 모드에서만 의미 있음.

### 5.2 SVG 외곽선 추가

`_buildClipPathDefs` 근처에서 clipPath 와 별개로 외곽선 `<path>` 를 추가:

```dart
// clip-path 모드일 때 외곽선 렌더
if (hasClip && boundaryParams.borderStyle != QrBorderStyle.none) {
  buf.write(_buildBorderStroke(totalSize, boundaryParams));
}
```

```dart
static String _buildBorderStroke(double size, QrBoundaryParams params) {
  final pathData = _boundaryPathData(size, params);  // 기존 clipPath data 재사용
  final color = _colorHex(params.borderColorArgb);
  final width = params.borderWidth;

  final dashAttr = switch (params.borderStyle) {
    QrBorderStyle.solid => '',
    QrBorderStyle.dashed => ' stroke-dasharray="8,4"',
    QrBorderStyle.dotted => ' stroke-dasharray="2,2" stroke-linecap="round"',
    QrBorderStyle.dashDot => ' stroke-dasharray="8,4,2,4"',
    QrBorderStyle.double_ => '',  // 이중선은 별도 처리
    QrBorderStyle.none => '',
  };

  if (params.borderStyle == QrBorderStyle.double_) {
    final w = width * 0.4;
    final scale = 1.0 - (width * 3 / size);
    return '    <path d="$pathData" fill="none" stroke="$color" stroke-width="${_f(w)}"/>\n'
           '    <path d="$pathData" fill="none" stroke="$color" stroke-width="${_f(w)}"'
           ' transform="translate(${_f(size/2)},${_f(size/2)}) scale(${_f(scale)}) translate(${_f(-size/2)},${_f(-size/2)})"/>\n';
  }

  return '    <path d="$pathData" fill="none" stroke="$color" stroke-width="${_f(width)}"$dashAttr/>\n';
}
```

---

## 6. 색상 통합 아키텍처: ColorTargetMode + bgColor/bgGradient

### 6.1 ColorTargetMode enum (신규)

```dart
// lib/features/qr_result/domain/entities/color_target_mode.dart
enum ColorTargetMode { both, qrOnly, bgOnly }
```

`colorTargetModeProvider` (StateProvider) — 색상 탭 전용 UI 상태. 프레임 모드일 때만 칩 표시.

### 6.2 QrStyleState 확장

```dart
// domain/state/qr_style_state.dart — 기존 필드에 추가
final Color? bgColor;        // null = qrColor 따라감
final QrGradient? bgGradient; // null = customGradient 따라감
```

`copyWith` 에 `clearBgColor`, `clearBgGradient` bool 플래그.

### 6.3 style_setters.dart 추가 메서드

```dart
void setBgColor(Color c) {
  state = state.copyWith(style: state.style.copyWith(bgColor: c));
  _schedulePush();
}
void setBgGradient(QrGradient? g) {
  state = state.copyWith(style: state.style.copyWith(
    bgGradient: g, clearBgGradient: g == null,
  ));
  _schedulePush();
}
void clearBgOverrides() {
  state = state.copyWith(style: state.style.copyWith(
    clearBgColor: true, clearBgGradient: true,
  ));
  _schedulePush();
}
```

### 6.4 색상 탭 라우팅 (`qr_color_tab.dart`)

```dart
void _applyColor(Color color) {
  final notifier = ref.read(qrResultProvider.notifier);
  switch (ref.read(colorTargetModeProvider)) {
    case ColorTargetMode.both:
      notifier.setQrColor(color);
      notifier.clearBgOverrides();   // bg = QR 따라감
    case ColorTargetMode.qrOnly:
      notifier.setQrColor(color);
    case ColorTargetMode.bgOnly:
      notifier.setBgColor(color);
      notifier.setBgGradient(null);  // 단색 선택 → 그라디언트 해제
  }
}

void _applyGradient(QrGradient? grad) {
  final notifier = ref.read(qrResultProvider.notifier);
  switch (ref.read(colorTargetModeProvider)) {
    case ColorTargetMode.both:
      notifier.setCustomGradient(grad);
      notifier.clearBgOverrides();
    case ColorTargetMode.qrOnly:
      notifier.setCustomGradient(grad);
    case ColorTargetMode.bgOnly:
      notifier.setBgGradient(grad);
  }
}
```

### 6.5 `_ColorTargetChips` (색상 탭 shared.dart)

프레임 모드(`!boundaryParams.isDefault`)일 때만 칩 표시. "동시" → "QR"/"배경" 전환 시 bgColor/bgGradient를 현재 QR 값으로 포크하여 갑작스런 색상 변경 방지.

### 6.6 `qr_layer_stack.dart` 배경 색상 계산

```dart
// 배경 그라디언트: bgGradient → (bgColor 명시 시 null) → activeGradient fallback
final bgGradient = state.style.bgGradient
    ?? (state.style.bgColor != null ? null : activeGradient);
final patternColor = state.style.bgColor ?? state.style.qrColor;
final Shader? bgShader = bgGradient != null
    ? buildQrGradientShader(bgGradient, frameBounds)
    : null;
```

**핵심 규칙**: `bgColor`가 명시되면 `bgGradient` fallback 차단 → `bgShader = null` → `Paint.color` 가 우선.

### 6.7 프레임 모드 로고 비율 유지

```dart
// 로고 크기는 qrAreaSize 기준 (frameScale 변경 시 QR 대비 비율 일정)
_LogoWidget(sticker: sticker, iconProvider: iconProvider, size: qrAreaSize)
// clearZone 도 동일 기준
iconSize: qrAreaSize * 0.22
```

### 6.8 그라디언트 패턴 파이프라인 (`qr_margin_painter.dart`)

5개 패턴 메서드 모두 `{Shader? shader}` named param 추가:

```dart
static void drawQrDots(..., {Shader? shader}) {
  final paint = Paint()..color = color;
  if (shader != null) paint.shader = shader;  // shader 가 color 를 override
  // ... 기존 렌더링 ...
}
```

`DecorativeFramePainter._drawPattern()` 에서 `shader: patternShader` 로 전달.

---

## 7. l10n 키 (app_ko.arb)

```json
"labelBorderStyle": "선 종류",
"labelBorderColor": "선 색상",
"sliderBorderWidth": "선 두께",
"labelPatternColor": "패턴 색상",
"borderNone": "없음",
"borderSolid": "실선",
"borderDashed": "파선",
"borderDotted": "점선",
"borderDashDot": "일점쇄선",
"borderDouble": "이중선",
"boundaryNone": "없음",
"boundaryCircle": "원형",
"boundarySuperellipse": "슈퍼타원",
"boundaryStar": "별",
"boundaryHeart": "하트",
"boundaryHexagon": "육각형",
"colorTargetBoth": "동시",
"colorTargetQr": "QR",
"colorTargetBg": "배경"
```

기존 키(`labelBoundaryType`, `sliderFrameScale`, `labelMarginPattern` 등)는 그대로 재사용.

---

## 8. 데이터 흐름

### 8.1 형태 파라미터 (boundary_editor.dart → boundaryParams)

```
User interaction (boundary_editor.dart)
  │
  ├─ DropdownButton<QrBoundaryType> 변경
  │   → onChanged(params.copyWith(type: ...))
  │
  ├─ DropdownButton<QrBorderStyle> 변경
  │   → onChanged(params.copyWith(borderStyle: ...))
  │
  ├─ _SliderRow (선 두께)
  │   → onChanged(params.copyWith(borderWidth: v))
  │
  └─ (기존: frameScale, rotation, roundness, patternDensity 등)

          ↓ onChanged callback

QrBackgroundTabState._editBoundary = updated params
  ├─ ref.read(qrResultProvider.notifier).setBoundaryParams(params)
  └─ setState() → UI rebuild
```

### 8.2 색상 (qr_color_tab.dart → bgColor/bgGradient)

```
User interaction (qr_color_tab.dart)
  │
  ├─ _ColorTargetChips: 동시 / QR / 배경 선택
  │   → colorTargetModeProvider 업데이트
  │   → "동시"→"QR"/"배경" 전환 시 bgColor/bgGradient 포크
  │
  ├─ 단색 선택 → _applyColor(color)
  │   → switch(mode):
  │     both: setQrColor + clearBgOverrides
  │     qrOnly: setQrColor
  │     bgOnly: setBgColor + setBgGradient(null)
  │
  └─ 그라디언트 선택 → _applyGradient(grad)
      → switch(mode):
        both: setCustomGradient + clearBgOverrides
        qrOnly: setCustomGradient
        bgOnly: setBgGradient

          ↓ state 변경

qr_layer_stack.dart
  ├─ QR 도트: ShaderMask(activeGradient) or qrColor
  ├─ 배경 색상 계산:
  │   bgGradient = bgGradient ?? (bgColor != null ? null : activeGradient)
  │   patternColor = bgColor ?? qrColor
  │   bgShader = bgGradient → buildQrGradientShader()
  └─ DecorativeFramePainter(patternColor, patternShader: bgShader,
                             borderColor: patternColor, borderShader: bgShader)
```

---

## 9. 구현 순서

| # | 파일 | 작업 | 예상 줄수 |
|---|------|------|----------|
| 1 | `domain/entities/qr_border_style.dart` | enum 생성 | ~10줄 |
| 2 | `domain/entities/qr_boundary_params.dart` | 4필드 추가 + copyWith/json/==/hash | ~40줄 추가 |
| 3 | `domain/entities/color_target_mode.dart` | ColorTargetMode enum | ~3줄 |
| 4 | `domain/state/qr_style_state.dart` | bgColor, bgGradient 필드 추가 | ~20줄 추가 |
| 5 | `notifier/style_setters.dart` | setBgColor/setBgGradient/clearBgOverrides | ~20줄 추가 |
| 6 | `utils/dash_path_util.dart` | Canvas dash path 유틸 | ~30줄 |
| 7 | `utils/qr_margin_painter.dart` | 5개 메서드에 Shader? param 추가 | ~10줄 추가 |
| 8 | `widgets/decorative_frame_painter.dart` | shader 필드 + `_drawBorder()` | ~60줄 추가 |
| 9 | `tabs/qr_shape_tab/boundary_editor.dart` | UI 재설계 (색상 피커 제외) | ~200줄 |
| 10 | `tabs/qr_color_tab.dart` | ColorTargetMode 라우팅 + 칩 UI | ~50줄 추가 |
| 11 | `tabs/qr_color_tab/shared.dart` | _ColorTargetChips + _FrameColorSection 제거 | ~40줄 변경 |
| 12 | `widgets/qr_layer_stack.dart` | bgColor/bgGradient 계산 + 로고 비율 | ~15줄 변경 |
| 13 | `utils/qr_svg_generator.dart` | `_buildBorderStroke()` 추가 | ~30줄 추가 |
| 14 | `l10n/app_ko.arb` | 19개 키 추가 | ~19줄 |
| 15 | `flutter analyze --no-pub` | 검증 | - |

---

## 10. 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| `borderStyle=none` | 외곽선 비표시, 선 두께 UI 숨김 |
| `type=square` | 드롭다운에 "없음" 으로 표시 — 프레임 해제 역할 |
| "동시"→"QR" 모드 전환 | bgColor 가 null 이면 현재 qrColor 로 포크 (색상 점프 방지) |
| "동시"→"배경" 모드 전환 | bgGradient 가 null 이면 activeGradient 로 포크 |
| "배경" 모드 단색 선택 | setBgColor + setBgGradient(null) → bgShader null → Paint.color 우선 |
| bgColor/bgGradient 둘 다 null | QR 색상/그라디언트 fallback (`bgColor ?? qrColor`, `bgGradient ?? activeGradient`) |
| bgColor 설정 + bgGradient null | gradient fallback 차단 → 단색 배경 보장 |
| 기존 JSON 데이터 (신규 필드 없음) | `fromJson` 기본값: solid, 0xFF000000, 2.0, null |
| `double_` 이중선 + 복잡 shape | 내부 path를 scale 축소 |
| `dotted` + 곡선 path (circle) | `strokeCap = StrokeCap.round` 으로 둥근 점 |
| 프레임 모드 아닐 때 ColorTargetMode 칩 | `boundaryParams.isDefault` 이면 칩 비표시 (프레임 없으면 배경 색상 무의미) |
| 프레임 크기(frameScale) 변경 시 로고 | 로고 size = qrAreaSize 기준 → QR 대비 비율 일정 유지 |
| SVG 프레임 모드 미지원 | SVG는 clipPath 모드에서만 외곽선 렌더 |
