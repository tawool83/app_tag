# qr-decorative-frame Design Document

> **Summary**: QR 외곽을 클리핑에서 장식 프레임 방식으로 전환 — 엔티티/렌더러/UI 상세 설계
>
> **Project**: app_tag
> **Author**: Claude
> **Date**: 2026-04-22
> **Status**: Draft
> **Planning Doc**: [qr-decorative-frame.plan.md](../../01-plan/features/qr-decorative-frame.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. QR 코드를 정사각형으로 유지하면서 장식 프레임 안에 플로팅 배치 (QR 인식률 100%)
2. 프레임과 QR 사이 마진 영역에 장식 패턴 렌더링 (6종)
3. 프레임 크기 조절 슬라이더 (QR 대비 비율)
4. 기존 `QrBoundaryParams` 확장으로 하위 호환 + Hive 직렬화

### 1.2 Design Principles

- 기존 `CustomQrPainter`의 clipPath 제거, 프레임은 별도 레이어로 분리
- 패턴 Path는 params 변경 시에만 재계산 (60fps 유지)
- `QrBoundaryParams` 확장 필드에 기본값 폴백으로 기존 Hive 데이터 자동 호환

---

## 2. Architecture

### 2.1 렌더링 레이어 구조 변경

**현재 (클리핑)**:
```
QrLayerStack (size × size)
  └─ Container(quietPadding)
       └─ CustomQrPainter
            ├─ canvas.save()
            ├─ QrBoundaryClipper.applyClip()  ← clipPath로 QR 자체 변형
            ├─ finder patterns
            ├─ structural dots
            ├─ data dots
            └─ canvas.restore()
```

**변경 후 (프레임)**:
```
QrLayerStack (frameSize × frameSize)
  └─ Stack
       ├─ DecorativeFramePainter (frameSize × frameSize)
       │    ├─ 1. framePath 외부를 투명으로 clip (프레임 모양 영역만 표시)
       │    ├─ 2. framePath 내부 배경색 fill
       │    ├─ 3. QR 영역(중앙 정사각형 + quietZone) 제외한 마진에 패턴 렌더
       │    └─ 4. (선택) framePath 외곽선 stroke
       │
       ├─ Positioned.center (qrSize × qrSize)
       │    └─ Container(quietPadding)
       │         └─ CustomQrPainter  ← clipPath 제거, 정사각형 QR 그대로
       │              ├─ finder patterns
       │              ├─ structural dots
       │              └─ data dots
       │
       └─ Logo/Sticker (기존 동일)
```

### 2.2 크기 계산 공식

```
입력: widget.size (QrLayerStack의 기존 size 파라미터)
frameScale = boundaryParams.frameScale  // 1.0~2.0, 기본 1.4

if (frameScale <= 1.0 || boundaryParams.isDefault):
  // square 또는 프레임 없음 — 기존 동작 그대로
  frameSize = widget.size
  qrSize = widget.size - quietPadding * 2

else:
  // 프레임 모드
  frameSize = widget.size                    // 전체 할당 영역은 동일
  qrSize = frameSize / frameScale            // QR은 프레임 안에서 축소
  quietPadding = (qrSize * 0.05).clamp(4, 12) // quiet zone
  effectiveQrSize = qrSize - quietPadding * 2
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| `DecorativeFramePainter` | `QrBoundaryClipper.buildFramePath()`, `QrMarginPatternEngine` | 프레임 + 패턴 렌더링 |
| `QrMarginPatternEngine` | `QrBoundaryClipper.buildFramePath()` | 마진 영역 패턴 Path 생성 |
| `QrLayerStack._buildFrameQr()` | `DecorativeFramePainter`, `CustomQrPainter` | 프레임 모드 위젯 조립 |
| `boundary_editor.dart` | `QrMarginPattern` enum | 패턴 선택 UI |

---

## 3. Data Model

### 3.1 `QrMarginPattern` enum (신규)

```dart
// lib/features/qr_result/domain/entities/qr_margin_pattern.dart

/// 프레임 마진 영역 장식 패턴.
enum QrMarginPattern {
  none,      // 단색 배경만
  qrDots,    // QR 도트 패턴 반복 (DotShapeParams 재활용)
  maze,      // 미로 패턴 (재귀 분할)
  zigzag,    // 지그재그 선
  wave,      // 사인 곡선 물결
  grid,      // 격자 점/선
}
```

### 3.2 `QrBoundaryParams` 확장

```dart
// lib/features/qr_result/domain/entities/qr_boundary_params.dart — 필드 추가

class QrBoundaryParams {
  // ── 기존 필드 (변경 없음) ──
  final QrBoundaryType type;
  final double superellipseN;
  final int starVertices;
  final double starInnerRadius;
  final double rotation;
  final double padding;         // 기존 유지하되 frameScale과 역할 분리
  final double roundness;

  // ── 신규 필드 ──
  final double frameScale;           // 프레임 크기 비율: 1.0~2.0 (1.0 = 프레임 없음)
  final QrMarginPattern marginPattern; // 마진 패턴
  final double patternDensity;       // 패턴 밀도: 0.5~2.0 (기본 1.0)

  const QrBoundaryParams({
    this.type = QrBoundaryType.square,
    this.superellipseN = 20.0,
    this.starVertices = 5,
    this.starInnerRadius = 0.5,
    this.rotation = 0.0,
    this.padding = 0.05,
    this.roundness = 0.0,
    // 신규 기본값 — 기존 Hive 데이터에서 누락 시 이 값으로 폴백
    this.frameScale = 1.0,
    this.marginPattern = QrMarginPattern.none,
    this.patternDensity = 1.0,
  });

  // isDefault: square이면서 frameScale 1.0 — 프레임/클리핑 둘 다 없음
  bool get isDefault => type == QrBoundaryType.square && frameScale <= 1.0;

  // 프레임 모드 활성 여부 (type != square && frameScale > 1.0)
  bool get isFrameMode => type != QrBoundaryType.square && frameScale > 1.0;
}
```

**toJson/fromJson 확장**:
```dart
Map<String, dynamic> toJson() => {
  // ... 기존 필드 ...
  'frameScale': frameScale,
  'marginPattern': marginPattern.name,
  'patternDensity': patternDensity,
};

factory QrBoundaryParams.fromJson(Map<String, dynamic> json) {
  // ... 기존 파싱 ...
  // 신규 필드: json에 없으면 기본값 폴백 (기존 Hive 데이터 호환)
  frameScale: (json['frameScale'] as num?)?.toDouble() ?? 1.0,
  marginPattern: _marginPatternFromName(json['marginPattern'] as String?),
  patternDensity: (json['patternDensity'] as num?)?.toDouble() ?? 1.0,
};
```

**copyWith 확장**:
```dart
QrBoundaryParams copyWith({
  // ... 기존 ...
  double? frameScale,
  QrMarginPattern? marginPattern,
  double? patternDensity,
}) => QrBoundaryParams(
  // ... 기존 ...
  frameScale: frameScale ?? this.frameScale,
  marginPattern: marginPattern ?? this.marginPattern,
  patternDensity: patternDensity ?? this.patternDensity,
);
```

**== / hashCode 확장**: 3개 신규 필드 포함.

### 3.3 프리셋 업데이트

```dart
// 기존 프리셋은 frameScale: 1.0 으로 유지 (기존 동작 = 클리핑)
// → 새 프레임 프리셋 추가
static const circleFrame = QrBoundaryParams(
  type: QrBoundaryType.circle,
  frameScale: 1.4,
  marginPattern: QrMarginPattern.qrDots,
);
static const hexagonFrame = QrBoundaryParams(
  type: QrBoundaryType.hexagon,
  frameScale: 1.4,
  marginPattern: QrMarginPattern.zigzag,
);
static const heartFrame = QrBoundaryParams(
  type: QrBoundaryType.heart,
  frameScale: 1.5,
  marginPattern: QrMarginPattern.wave,
);
static const starFrame = QrBoundaryParams(
  type: QrBoundaryType.star,
  frameScale: 1.5,
  marginPattern: QrMarginPattern.grid,
  starVertices: 5,
  starInnerRadius: 0.5,
);
```

### 3.4 `UserShapePreset` 호환

`UserShapePreset.boundaryParams`는 이미 `QrBoundaryParams?` 타입이므로 신규 필드가 자동으로 포함됨. JSON 직렬화도 `QrBoundaryParams.toJson()/fromJson()` 경유로 자동 호환.

---

## 4. 렌더러 상세 설계

### 4.1 `DecorativeFramePainter` (신규)

```dart
// lib/features/qr_result/widgets/decorative_frame_painter.dart

class DecorativeFramePainter extends CustomPainter {
  final QrBoundaryParams boundaryParams;
  final double qrSize;          // 내부 QR 영역 크기
  final Color frameColor;       // 프레임 배경색 (quietZoneColor)
  final Color patternColor;     // 패턴 색상 (qrColor.withOpacity(0.4))
  final DotShapeParams? dotParams; // qrDots 패턴 시 도트 모양 참조

  // 캐시: params 변경 시에만 재생성
  Path? _cachedFramePath;
  Path? _cachedPatternPath;

  @override
  void paint(Canvas canvas, Size size) {
    final framePath = _getFramePath(size);
    if (framePath == null) return; // square = 프레임 없음

    // 1. 프레임 모양 외부를 투명하게 clip
    canvas.save();
    canvas.clipPath(framePath);

    // 2. 프레임 내부 배경 fill
    canvas.drawRect(Offset.zero & size, Paint()..color = frameColor);

    // 3. QR 영역(중앙 사각형 + quiet zone)을 제외한 마진에 패턴
    final qrRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: qrSize, height: qrSize,
    );
    canvas.save();
    // 마진 = framePath - qrRect (차집합 클리핑)
    canvas.clipPath(
      Path.combine(PathOperation.difference, framePath, Path()..addRect(qrRect)),
    );
    _drawPattern(canvas, size);
    canvas.restore();

    // 4. (선택) 프레임 외곽선
    // canvas.drawPath(framePath, Paint()..style = PaintingStyle.stroke..strokeWidth = 1);

    canvas.restore();
  }

  void _drawPattern(Canvas canvas, Size size) {
    switch (boundaryParams.marginPattern) {
      case QrMarginPattern.none: return;
      case QrMarginPattern.qrDots:
        QrMarginPatternEngine.drawQrDots(canvas, size, patternColor, dotParams, boundaryParams.patternDensity);
      case QrMarginPattern.maze:
        QrMarginPatternEngine.drawMaze(canvas, size, patternColor, boundaryParams.patternDensity);
      case QrMarginPattern.zigzag:
        QrMarginPatternEngine.drawZigzag(canvas, size, patternColor, boundaryParams.patternDensity);
      case QrMarginPattern.wave:
        QrMarginPatternEngine.drawWave(canvas, size, patternColor, boundaryParams.patternDensity);
      case QrMarginPattern.grid:
        QrMarginPatternEngine.drawGrid(canvas, size, patternColor, boundaryParams.patternDensity);
    }
  }

  @override
  bool shouldRepaint(DecorativeFramePainter old) =>
      boundaryParams != old.boundaryParams ||
      qrSize != old.qrSize ||
      frameColor != old.frameColor ||
      patternColor != old.patternColor ||
      dotParams != old.dotParams;
}
```

### 4.2 `QrMarginPatternEngine` (신규)

```dart
// lib/features/qr_result/utils/qr_margin_painter.dart

/// 마진 영역 장식 패턴 렌더 엔진. 모든 메서드는 static, 순수 함수.
class QrMarginPatternEngine {
  QrMarginPatternEngine._();

  /// QR 도트 패턴: DotShapeParams 모양을 grid로 반복 배치.
  static void drawQrDots(Canvas canvas, Size size, Color color,
      DotShapeParams? dotParams, double density) {
    final dp = dotParams ?? const DotShapeParams();
    final spacing = (size.width * 0.04 / density).clamp(4.0, 16.0);
    final radius = spacing * 0.35;
    final paint = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        final center = Offset(x, y);
        final path = PolarPolygon.buildPath(center, radius * dp.scale, dp);
        canvas.drawPath(path, paint);
      }
    }
  }

  /// 미로 패턴: 재귀 분할 미로(Recursive Division) 기반 선.
  static void drawMaze(Canvas canvas, Size size, Color color, double density) {
    final cellSize = (size.width * 0.05 / density).clamp(6.0, 20.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    // 간소화: grid 기반 랜덤 벽 패턴 (시드 고정으로 동일 출력)
    final cols = (size.width / cellSize).floor();
    final rows = (size.height / cellSize).floor();
    final rng = _seededRng(cols * rows);
    final path = Path();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * cellSize;
        final y = r * cellSize;
        if (rng.nextBool()) {
          path.moveTo(x, y);
          path.lineTo(x + cellSize, y + cellSize);
        } else {
          path.moveTo(x + cellSize, y);
          path.lineTo(x, y + cellSize);
        }
      }
    }
    canvas.drawPath(path, paint);
  }

  /// 지그재그 선 패턴.
  static void drawZigzag(Canvas canvas, Size size, Color color, double density) {
    final spacing = (size.width * 0.06 / density).clamp(6.0, 20.0);
    final amp = spacing * 0.4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    final path = Path();
    for (double y = 0; y < size.height; y += spacing) {
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += amp) {
        final yOff = ((x / amp).floor().isEven) ? y : y + amp;
        path.lineTo(x + amp, yOff);
      }
    }
    canvas.drawPath(path, paint);
  }

  /// 사인 곡선 물결 패턴.
  static void drawWave(Canvas canvas, Size size, Color color, double density) {
    final spacing = (size.width * 0.06 / density).clamp(8.0, 24.0);
    final amp = spacing * 0.3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    final path = Path();
    for (double y = spacing; y < size.height; y += spacing) {
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 2) {
        path.lineTo(x, y + amp * sin(x / spacing * 2 * pi));
      }
    }
    canvas.drawPath(path, paint);
  }

  /// 격자 점/선 패턴.
  static void drawGrid(Canvas canvas, Size size, Color color, double density) {
    final spacing = (size.width * 0.05 / density).clamp(6.0, 18.0);
    final dotR = spacing * 0.12;
    final paint = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, paint);
      }
    }
  }

  static Random _seededRng(int seed) => Random(seed.hashCode ^ 0xDEADBEEF);
}
```

### 4.3 `QrBoundaryClipper` 변경

```dart
// 기존 applyClip() — 비프레임 모드에서만 사용하도록 분기
// 프레임 모드에서는 호출하지 않음 (CustomQrPainter에서 제거)

// 기존 buildClipPath() → buildFramePath() 로 rename 불필요
// 동일 함수를 DecorativeFramePainter에서도 사용
```

**`CustomQrPainter` 변경**: `boundaryParams.isFrameMode`이면 `applyClip()` 호출 스킵.

```dart
// custom_qr_painter.dart paint() 변경 부분:
canvas.save();
// 프레임 모드에서는 clipPath 하지 않음 — QR 정사각형 유지
if (!boundaryParams.isFrameMode) {
  QrBoundaryClipper.applyClip(canvas, size, boundaryParams);
}
// ... 나머지 렌더링 동일 ...
canvas.restore();
```

### 4.4 `QrLayerStack` 변경

```dart
// qr_layer_stack.dart build() — 프레임 모드 분기 추가

@override
Widget build(BuildContext context) {
  // ... 기존 state/sticker/iconProvider 계산 ...

  final isFrameMode = state.style.boundaryParams.isFrameMode;

  // ── QR 렌더링 위젯 결정 ──
  final Widget qrWidget;
  if (isFrameMode) {
    qrWidget = _buildFrameQr(state, widget.size);
  } else if (useCustom) {
    qrWidget = _buildCustomQr(state, qrSize);
  } else {
    qrWidget = buildPrettyQr(state, deepLink: widget.deepLink, size: qrSize, isDialog: widget.isDialog);
  }
  // ... 나머지 레이아웃 ...
}

/// 프레임 모드: DecorativeFramePainter + CustomQrPainter 레이어 조합
Widget _buildFrameQr(QrResultState state, double totalSize) {
  final frameScale = state.style.boundaryParams.frameScale;
  final qrSize = totalSize / frameScale;
  final quietPadding = (qrSize * 0.05).clamp(4.0, 12.0);
  final effectiveQrSize = qrSize - quietPadding * 2;

  // QR 매트릭스 생성 (기존 로직 재사용)
  final embedInQr = state.logo.embedIcon &&
      centerImageProvider(state) != null &&
      state.sticker.logoPosition == LogoPosition.center;
  final ecLevel = embedInQr ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
  final qrImage = _qrImageFor(widget.deepLink, ecLevel);

  final clearZone = computeLogoClearZone(
    qrSize: Size.square(effectiveQrSize),
    iconSize: totalSize * 0.22,
    sticker: state.sticker,
    embedIcon: state.logo.embedIcon,
  );

  final activeGradient = state.template.templateGradient ?? state.style.customGradient;
  final color = activeGradient != null ? Colors.black : state.style.qrColor;
  final patternColor = (activeGradient != null ? Colors.black : state.style.qrColor).withOpacity(0.4);

  // QR CustomPainter (clipPath 없음)
  Widget qrPainter = CustomPaint(
    size: Size.square(effectiveQrSize),
    painter: CustomQrPainter(
      qrImage: qrImage,
      color: color,
      dotParams: state.style.customDotParams ?? state.style.dotStyle.toDotShapeParams(),
      eyeParams: state.style.customEyeParams ?? const EyeShapeParams(),
      boundaryParams: state.style.boundaryParams, // isFrameMode → clipPath 스킵
      animParams: state.style.animationParams,
      animValue: _animController?.value ?? 0.0,
      clearZone: clearZone,
    ),
  );

  // 그라디언트 적용
  if (activeGradient != null) {
    qrPainter = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => buildQrGradientShader(activeGradient, bounds),
      child: qrPainter,
    );
  }

  return SizedBox(
    width: totalSize,
    height: totalSize,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Layer 0: 장식 프레임 + 마진 패턴
        CustomPaint(
          size: Size.square(totalSize),
          painter: DecorativeFramePainter(
            boundaryParams: state.style.boundaryParams,
            qrSize: qrSize,
            frameColor: state.style.quietZoneColor,
            patternColor: patternColor,
            dotParams: state.style.customDotParams ?? state.style.dotStyle.toDotShapeParams(),
          ),
        ),
        // Layer 1: QR 코드 (정사각형, 중앙)
        Container(
          width: qrSize,
          height: qrSize,
          color: state.style.quietZoneColor,
          padding: EdgeInsets.all(quietPadding),
          child: qrPainter,
        ),
      ],
    ),
  );
}
```

---

## 5. UI/UX Design

### 5.1 Boundary Editor 확장

```
┌────────────────────────────────────────────┐
│ 외곽 타입                                   │  ← 기존
│ [■] [●] [◆] [★] [♥] [⬡]                  │
├────────────────────────────────────────────┤
│ 프레임 크기     ──●──────────   1.4x        │  ← 신규 (FR-04)
├────────────────────────────────────────────┤
│ 마진 패턴                                   │  ← 신규 (FR-03)
│ [없음] [도트] [미로] [지그재그] [물결] [격자] │
├────────────────────────────────────────────┤
│ 패턴 밀도       ─────●──────   1.0x        │  ← 신규
├────────────────────────────────────────────┤
│ 회전            ─────●──────   0°          │  ← 기존
│ (타입별 추가 슬라이더)                       │  ← 기존
└────────────────────────────────────────────┘
```

- 프레임 크기 슬라이더: `type != square` 일 때만 표시
- 마진 패턴 선택: `frameScale > 1.0` 일 때만 표시 (마진 없으면 패턴 의미 없음)
- 패턴 밀도 슬라이더: `marginPattern != none` 일 때만 표시

### 5.2 Boundary Preview 확장

`_BoundaryShapePreview`에 프레임 모드 미리보기 반영:
- 프레임 모양 + 마진 패턴을 120px 미리보기에서 렌더
- 중앙에 미니 QR 사각형 표시 (실제 QR 아닌 placeholder)

### 5.3 Preset Row 변경

기존 builtin 프리셋은 유지 (clipPath 모드 — frameScale 1.0).
새로운 프레임 프리셋은 `_BoundaryPresetRow._builtinTypes` 이후에 `_framePresets` 섹션으로 추가.

```
[+] [■] [●] [◆] [★] [♥] [⬡] | [●F] [⬡F] [♥F] [★F]   (사용자 프리셋...)
                                 └─ Frame presets (F suffix 아이콘)
```

---

## 6. Data Flow

### 6.1 상태 변경 흐름

```
User adjusts frameScale slider
  → boundary_editor.dart: onChanged(params.copyWith(frameScale: v))
  → qr_shape_tab.dart: _editBoundary = updated params (실시간 미리보기)
  → onDragEnd: ref.read(qrResultProvider.notifier).setBoundaryParams(params)
  → style_setters.dart: state = state.copyWith(style: state.style.copyWith(boundaryParams: params))
  → _schedulePush() → Hive 저장 (CustomizationMapper.toSpec → payloadJson)
  → QrLayerStack rebuilds → isFrameMode 분기 → DecorativeFramePainter + CustomQrPainter
```

### 6.2 Hive 직렬화 흐름

```
저장: QrBoundaryParams.toJson()
  → { type, superellipseN, ..., frameScale, marginPattern, patternDensity }
  → CustomizationMapper.toSpec()
  → Hive payloadJson

복원: QrBoundaryParams.fromJson()
  → 신규 필드 없으면 기본값 폴백 (frameScale: 1.0, marginPattern: none)
  → 기존 데이터: 자동으로 clipPath 모드 유지 (isFrameMode = false)
```

---

## 7. Error Handling

| Scenario | Handling |
|----------|---------|
| 기존 Hive 데이터에 `frameScale` 없음 | `fromJson()` 기본값 1.0 → clipPath 모드 유지 |
| `frameScale` > 2.0 입력 | `clamp(1.0, 2.0)` in slider |
| 패턴 렌더링 프레임 드롭 | shouldRepaint에서 params 변경 시에만 재렌더 |
| 내보내기 시 프레임 잘림 | RepaintBoundary가 SizedBox(totalSize) 를 감싸므로 프레임 포함 |

---

## 8. Test Plan

### 8.1 QR 인식률 테스트

- [ ] 모든 프레임 모양(6종) × frameScale(1.2, 1.4, 1.8) 조합에서 QR 스캐너 인식 성공
- [ ] 패턴 밀도 최대(2.0)에서도 QR 인식 성공 (패턴은 마진 영역에만, QR 영역 침범 없음)
- [ ] square 타입은 기존 동작과 동일 (프레임 없음)

### 8.2 UI 테스트

- [ ] 프레임 크기 슬라이더 드래그 시 실시간 미리보기 업데이트
- [ ] 마진 패턴 전환 시 즉시 반영
- [ ] 프리셋 선택/저장/복원 동작

### 8.3 데이터 호환 테스트

- [ ] 기존 Hive 데이터 로드 시 frameScale=1.0 폴백 → clipPath 모드 유지
- [ ] 프레임 프리셋 저장 후 앱 재시작 → 복원 성공

---

## 9. Directory Structure

```
lib/features/qr_result/
├── domain/
│   └── entities/
│       ├── qr_boundary_params.dart      ── 수정: +3 필드 (frameScale, marginPattern, patternDensity)
│       ├── qr_margin_pattern.dart        ── 신규: enum QrMarginPattern
│       └── qr_shape_params.dart          ── 변경 없음
├── utils/
│   ├── qr_boundary_clipper.dart          ── 변경 없음 (buildClipPath 재사용)
│   └── qr_margin_painter.dart            ── 신규: QrMarginPatternEngine (5종 static 메서드)
├── widgets/
│   ├── custom_qr_painter.dart            ── 수정: isFrameMode일 때 clipPath 스킵
│   ├── decorative_frame_painter.dart     ── 신규: CustomPainter (프레임 + 마진 패턴)
│   ├── qr_layer_stack.dart               ── 수정: _buildFrameQr() 추가
│   └── qr_preview_section.dart           ── 수정: _BoundaryShapePreview 프레임 미리보기
├── tabs/qr_shape_tab/
│   ├── boundary_editor.dart              ── 수정: 프레임 크기/패턴/밀도 슬라이더 추가
│   └── boundary_preset_row.dart          ── 수정: 프레임 프리셋 아이콘 추가
└── notifier/
    └── style_setters.dart                ── 변경 없음 (setBoundaryParams 그대로)
```

---

## 10. Implementation Order

1. [ ] `qr_margin_pattern.dart` — enum 생성
2. [ ] `qr_boundary_params.dart` — 3개 필드 추가 + 프레임 프리셋 + toJson/fromJson/copyWith/==/hashCode
3. [ ] `qr_margin_painter.dart` — QrMarginPatternEngine 5종 패턴 static 메서드
4. [ ] `decorative_frame_painter.dart` — DecorativeFramePainter CustomPainter
5. [ ] `custom_qr_painter.dart` — isFrameMode일 때 clipPath 스킵
6. [ ] `qr_layer_stack.dart` — _buildFrameQr() + build() 분기
7. [ ] `boundary_editor.dart` — 프레임 크기/패턴/밀도 UI
8. [ ] `boundary_preset_row.dart` — 프레임 프리셋
9. [ ] `qr_preview_section.dart` — 프레임 미리보기
10. [ ] 통합 테스트: QR 인식 + 내보내기 + Hive 호환

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-22 | Initial draft | Claude |
