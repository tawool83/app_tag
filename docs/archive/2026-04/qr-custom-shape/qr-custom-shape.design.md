# QR Custom Shape Design Document

> **Summary**: CustomPainter 기반 QR 렌더러 + 극좌표 다각형(도트) + Superellipse(눈) + QR 전체 외곽 클리핑(Boundary) + 데이터 영역 애니메이션 + "+" 편집기 UI + Hive 프리셋 저장
>
> **Project**: AppTag
> **Version**: 1.0.0
> **Author**: tawool83
> **Date**: 2026-04-18
> **Status**: Draft
> **Planning Doc**: [qr-custom-shape.plan.md](../../01-plan/features/qr-custom-shape.plan.md)

---

## 1. Overview

### 1.1 Design Goals

- `pretty_qr_code` 의존에서 분리한 독립 CustomPainter QR 렌더러
- 수학적 모델(극좌표 다각형 + Superellipse)로 무한 도트/눈 형태 생성
- QR 전체 외곽을 원형/별/하트/육각형/Superellipse 등으로 클리핑
- AnimationController + 영역 분류기로 데이터 영역 전용 애니메이션
- 색상 탭 맞춤 그라디언트와 동일한 "+" 인라인 편집기 UX 패턴
- Hive 기반 사용자 프리셋 저장/재사용

### 1.2 Design Principles

- **단일 Path 함수**: 도트/눈 각각 하나의 함수로 모든 형태를 생성 (프리셋 = 파라미터 조합)
- **보호 영역 분리**: finder/alignment/timing/format 영역은 절대 변경하지 않음
- **기존 패턴 재사용**: QrColorTab의 편집기 모드 패턴, UserQrTemplate의 Hive 저장 패턴
- **하위 호환**: 기존 QrDotStyle enum → 파라미터 자동 변환, 기존 JSON 복원 가능

---

## 2. Architecture

### 2.1 Component Diagram

```
┌───────────────────────────────────────────────────────────┐
│ QrResultScreen                                            │
│  ├─ QrPreviewSection                                      │
│  │   └─ QrLayerStack                                      │
│  │       └─ CustomQrPainter (NEW)  ← AnimationController  │
│  │           ├─ QrMatrixHelper     ← 영역 분류            │
│  │           ├─ PolarPolygon       ← 도트 Path            │
│  │           ├─ SuperellipsePath   ← 눈 Path              │
│  │           ├─ QrBoundaryClipper  ← 외곽 클리핑          │
│  │           └─ QrAnimationEngine  ← 애니메이션 계산       │
│  └─ QrShapeTab (REDESIGNED)                               │
│      ├─ DotPresetRow      [+] [●] [◆] [사용자1] ...      │
│      ├─ EyeOuterRow       [+] [□] [○] [사용자1] ...      │
│      ├─ EyeInnerRow       [+] [■] [●] [사용자1] ...      │
│      ├─ BoundaryPresetRow [+] [□] [○] [★] [사용자1] ...  │
│      ├─ AnimationRow      [+] [없음] [물결] [사용자1] ... │
│      ├─ DotEditor      (인라인 슬라이더 편집기)            │
│      ├─ EyeEditor      (인라인 슬라이더 편집기)            │
│      ├─ BoundaryEditor  (인라인 슬라이더 편집기)           │
│      └─ AnimEditor      (인라인 슬라이더 편집기)           │
│                                                           │
│ Data Layer                                                │
│  └─ LocalUserShapePresetDatasource (Hive)                 │
│      ├─ Box: 'user_dot_presets'                           │
│      ├─ Box: 'user_eye_presets'                           │
│      ├─ Box: 'user_boundary_presets'                      │
│      └─ Box: 'user_animation_presets'                     │
└───────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
슬라이더 조작
  → QrResultNotifier.setDotParams() / setEyeParams() / setBoundaryParams() / setAnimParams()
  → QrResultState 업데이트
  → CustomQrPainter.shouldRepaint() = true
  → paint() 호출
    → QrBoundaryClipper.clip(canvas, size, params) → 외곽 클리핑
    → QrMatrixHelper.classify(row, col) → protected / animatable
    → PolarPolygon.buildPath(params) → 도트 Path
    → SuperellipsePath.buildPath(params) → 눈 Path
    → QrAnimationEngine.apply(animValue, x, y) → scale/color/opacity
  → Canvas에 렌더링

"+" 편집기 완료
  → LocalUserShapePresetDatasource.save(preset)
  → Hive Box에 영구 저장
  → 프리셋 행에 썸네일 추가
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| `CustomQrPainter` | `qr` 패키지, `PolarPolygon`, `SuperellipsePath`, `QrMatrixHelper`, `QrAnimationEngine` | QR 렌더링 |
| `QrShapeTab` | `QrResultProvider`, `LocalUserShapePresetDatasource` | UI + 프리셋 CRUD |
| `QrLayerStack` | `CustomQrPainter`, `AnimationController` | 레이어 합성 + 애니메이션 구동 |
| `LocalUserShapePresetDatasource` | `Hive` | 사용자 프리셋 영구 저장 |

---

## 3. Data Model

### 3.1 도트 파라미터 모델 (듀얼 모드: 대칭 + 비대칭)

```dart
// lib/features/qr_result/domain/entities/qr_shape_params.dart

/// 도트 모양 모드: 대칭(극좌표 다각형) vs 비대칭(Superformula)
enum DotShapeMode { symmetric, asymmetric }

/// 도트 파라미터 — [대칭/비대칭] 듀얼 모드. 불변 객체.
///
/// 대칭 모드: 극좌표 다각형 (vertices, innerRadius, roundness)
/// 비대칭 모드: Superformula (m, n1, n2, n3, a, b)
/// 공통: rotation, scale
class DotShapeParams {
  final DotShapeMode mode;

  // ── 대칭 전용 ──
  final int vertices;           // 꼭짓점 수: 3~12 (4=사각, 12≈원)
  final double innerRadius;     // 내부 반경: 0.0(첨예)~1.0(볼록)
  final double roundness;       // 둥글기: 0.0(날카로운)~1.0(곡선) — Path 보간

  // ── 비대칭 전용: Superformula (Gielis, 1999) ──
  // r(θ) = ( |cos(mθ/4)/a|^n2 + |sin(mθ/4)/b|^n3 )^(-1/n1)
  final double sfM;             // 대칭 차수: 0~20 (0=원, 4=사각, 5=별, 6=꽃)
  final double sfN1;            // 곡률 1: 0.1~40 (전체 형태 둥글기)
  final double sfN2;            // 곡률 2: 0.1~40 (cos 항 곡률)
  final double sfN3;            // 곡률 3: -5~40 (sin 항 곡률, 음수=비대칭/오목)
  final double sfA;             // X 스케일: 0.5~2.0 (가로 비율)
  final double sfB;             // Y 스케일: 0.5~2.0 (세로 비율)

  // ── 공통 ──
  final double rotation;        // 회전: 0.0~360.0 (도)
  final double scale;           // 크기: 0.5~2.0 (슬라이더 -100%~+100%, 중앙 0%=1.0x, 테스트 후 조정 예정)

  const DotShapeParams({
    this.mode = DotShapeMode.symmetric,
    this.vertices = 4,
    this.innerRadius = 1.0,
    this.roundness = 0.0,
    this.sfM = 0.0,
    this.sfN1 = 1.0,
    this.sfN2 = 1.0,
    this.sfN3 = 1.0,
    this.sfA = 1.0,
    this.sfB = 1.0,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  /// 기존 프리셋 매핑 (대칭)
  static const square = DotShapeParams(vertices: 4, innerRadius: 1.0, roundness: 0.0);
  static const circle = DotShapeParams(vertices: 12, innerRadius: 1.0, roundness: 1.0);
  static const diamond = DotShapeParams(vertices: 4, innerRadius: 1.0, roundness: 0.0, rotation: 45.0);
  static const star = DotShapeParams(vertices: 5, innerRadius: 0.45, roundness: 0.0);

  /// 비대칭 프리셋 (Superformula 파라미터 조합) — 총 5종
  ///
  /// NOTE: 실제 프로덕션 값은 채움률 ≥ 50% 및 시각적 구분성 확보를 위해 재튜닝됨.
  /// 실제 사용 값은 `lib/features/qr_result/domain/entities/qr_shape_params.dart:77~91` 참조.
  /// (Leaf/Butterfly/Diamond/Teardrop 등 추가 프리셋은 폐기됨 — v0.8 결정)
  static const sfCircle = DotShapeParams(mode: DotShapeMode.asymmetric, sfM: 0,  sfN1: 1,   sfN2: 1,   sfN3: 1);
  static const sfSquare = DotShapeParams(mode: DotShapeMode.asymmetric, sfM: 4,  sfN1: 100, sfN2: 100, sfN3: 100);
  static const sfStar   = DotShapeParams(mode: DotShapeMode.asymmetric, sfM: 5,  sfN1: 0.3, sfN2: 0.3, sfN3: 0.3);  // 수학 모델 기준 (프로덕션 튜닝 값 별도)
  static const sfFlower = DotShapeParams(mode: DotShapeMode.asymmetric, sfM: 6,  sfN1: 1,   sfN2: 1,   sfN3: 8);    // 수학 모델 기준 (프로덕션 튜닝 값 별도)
  static const sfHeart  = DotShapeParams(mode: DotShapeMode.asymmetric, sfM: 1,  sfN1: 1,   sfN2: 0.8, sfN3: -0.5); // 수학 모델 기준 (프로덕션 튜닝 값 별도)

  DotShapeParams copyWith({
    DotShapeMode? mode, int? vertices, double? innerRadius, double? roundness,
    double? sfM, double? sfN1, double? sfN2, double? sfN3, double? sfA, double? sfB,
    double? rotation, double? scale,
  });

  Map<String, dynamic> toJson();
  factory DotShapeParams.fromJson(Map<String, dynamic> json);
  // fromJson: squareness 필드 무시 (하위 호환), 기존 ParametricShapeType → sfM/n1/n2/n3 매핑
}
```

### 3.2 눈 파라미터 모델

```dart
/// Superellipse 기반 눈 파라미터.
class EyeShapeParams {
  final double outerN;       // 외곽 superellipse n: 2.0(원)~20.0(사각)
  final double innerN;       // 내부 superellipse n: 2.0(원)~20.0(사각)
  final double rotation;     // 회전: 0.0~360.0
  final double innerScale;   // 내부 크기 비율: 0.3~0.8

  const EyeShapeParams({
    this.outerN = 20.0,      // 기본값 = 사각형(기존 동작)
    this.innerN = 20.0,
    this.rotation = 0.0,
    this.innerScale = 0.43,  // QR 스펙 3/7 ≈ 0.43
  });

  /// 기존 프리셋 매핑
  static const square = EyeShapeParams(outerN: 20.0, innerN: 20.0);
  static const rounded = EyeShapeParams(outerN: 5.0, innerN: 20.0);
  static const circle = EyeShapeParams(outerN: 2.0, innerN: 2.0);
  static const squircle = EyeShapeParams(outerN: 4.0, innerN: 4.0);
  static const smooth = EyeShapeParams(outerN: 3.0, innerN: 3.0);

  DotShapeParams copyWith({...});
  Map<String, dynamic> toJson();
  factory EyeShapeParams.fromJson(Map<String, dynamic> json);
}
```

### 3.3 애니메이션 파라미터 모델

```dart
// lib/features/qr_result/domain/entities/qr_animation_params.dart

enum QrAnimationType { none, wave, rainbow, pulse, sequential, rotationWave }

/// 데이터 영역 전용 애니메이션 파라미터.
class QrAnimationParams {
  final QrAnimationType type;
  final double speed;       // 1.0 = 2초 주기, 0.5 = 4초
  final double amplitude;   // 효과 강도: 0.0~1.0
  final double frequency;   // 위상 차이 주파수: 0.1~2.0

  const QrAnimationParams({
    this.type = QrAnimationType.none,
    this.speed = 1.0,
    this.amplitude = 0.5,
    this.frequency = 0.3,
  });

  /// 기본 프리셋
  static const none = QrAnimationParams();
  static const wave = QrAnimationParams(type: QrAnimationType.wave, amplitude: 0.5, frequency: 0.3);
  static const rainbow = QrAnimationParams(type: QrAnimationType.rainbow, speed: 0.8, frequency: 1.0);
  static const pulse = QrAnimationParams(type: QrAnimationType.pulse, amplitude: 0.3);
  static const sequential = QrAnimationParams(type: QrAnimationType.sequential, speed: 0.5);
  static const rotationWave = QrAnimationParams(type: QrAnimationType.rotationWave, amplitude: 0.4, frequency: 0.5);

  bool get isAnimated => type != QrAnimationType.none;

  Map<String, dynamic> toJson();
  factory QrAnimationParams.fromJson(Map<String, dynamic> json);
}
```

### 3.4 QR 전체 형태(Boundary) 파라미터 모델

```dart
// lib/features/qr_result/domain/entities/qr_boundary_params.dart

enum QrBoundaryType { square, circle, superellipse, star, heart, hexagon, custom }

/// QR 전체 외곽 클리핑 파라미터.
class QrBoundaryParams {
  final QrBoundaryType type;
  final double superellipseN;  // superellipse n값: 2.0(원)~20.0(사각) — type=superellipse 전용
  final int starVertices;      // 별 꼭짓점 수: 5~12 — type=star 전용
  final double starInnerRadius;// 별 내부 반지름 비율: 0.3~0.8 — type=star 전용
  final double rotation;       // 회전: 0.0~360.0
  final double padding;        // quiet zone 패딩: 0.0~0.15 (기본 0.05)
  final double roundness;      // 꼭짓점 둥글기: 0.0~1.0 — star/hexagon 전용

  const QrBoundaryParams({
    this.type = QrBoundaryType.square,
    this.superellipseN = 20.0,
    this.starVertices = 5,
    this.starInnerRadius = 0.5,
    this.rotation = 0.0,
    this.padding = 0.05,
    this.roundness = 0.0,
  });

  /// 기본 프리셋
  static const square = QrBoundaryParams();  // 기본값 = 사각형
  static const circle = QrBoundaryParams(type: QrBoundaryType.circle);
  static const squircle = QrBoundaryParams(type: QrBoundaryType.superellipse, superellipseN: 4.0);
  static const roundedRect = QrBoundaryParams(type: QrBoundaryType.superellipse, superellipseN: 6.0);
  static const star5 = QrBoundaryParams(type: QrBoundaryType.star, starVertices: 5, starInnerRadius: 0.5);
  static const heart = QrBoundaryParams(type: QrBoundaryType.heart);
  static const hexagon = QrBoundaryParams(type: QrBoundaryType.hexagon);

  bool get isDefault => type == QrBoundaryType.square;

  QrBoundaryParams copyWith({...});
  Map<String, dynamic> toJson();
  factory QrBoundaryParams.fromJson(Map<String, dynamic> json);
}
```

### 3.5 사용자 프리셋 모델

```dart
// lib/features/qr_result/domain/entities/user_shape_preset.dart

enum ShapePresetType { dot, eye, boundary, animation }

/// 사용자 저장 프리셋 (Hive 저장 단위).
class UserShapePreset {
  final String id;              // UUID
  final String name;            // 사용자 지정 이름
  final ShapePresetType type;   // dot / eye / boundary / animation
  final DateTime createdAt;
  final DateTime lastUsedAt;    // 최근 사용 시각 (정렬용, fallback: createdAt)
  final int version;            // 마이그레이션용

  // type별로 하나만 non-null
  final DotShapeParams? dotParams;   // mode + 대칭/비대칭 파라미터 포함
  final EyeShapeParams? eyeParams;
  final QrBoundaryParams? boundaryParams;
  final QrAnimationParams? animParams;

  UserShapePreset({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    DateTime? lastUsedAt,
    this.version = 1,
    this.dotParams,
    this.eyeParams,
    this.boundaryParams,
    this.animParams,
  }) : lastUsedAt = lastUsedAt ?? createdAt;

  /// lastUsedAt만 갱신한 복사본 반환.
  UserShapePreset withLastUsed(DateTime at);

  Map<String, dynamic> toJson();
  factory UserShapePreset.fromJson(Map<String, dynamic> json);
}
```

### 3.7 QrResultState 확장

```dart
// qr_result_provider.dart 기존 QrResultState에 추가할 필드

class QrResultState {
  // ... 기존 필드 유지 ...

  // NEW: 커스텀 도트/눈/외곽/애니메이션 파라미터
  final DotShapeParams? customDotParams;       // null = 기존 QrDotStyle enum 사용
  final EyeShapeParams? customEyeParams;       // null = 기존 QrEyeOuter/Inner enum 사용
  final QrBoundaryParams boundaryParams;       // 기본값 = square (기존 동작)
  final QrAnimationParams animationParams;     // 기본값 = none

  // NEW: 편집기 모드 상태
  final bool shapeEditorMode;                  // true 시 하단 액션 버튼 숨김
}
```

---

## 4. 핵심 유틸리티 상세 설계

### 4.1 PolarPolygon — 도트 Path 생성 (듀얼 모드)

```dart
// lib/features/qr_result/utils/polar_polygon.dart

class PolarPolygon {
  PolarPolygon._();

  /// 도트 Path 생성 — 대칭/비대칭 모드 자동 분기.
  static Path buildPath(Offset center, double radius, DotShapeParams params) {
    final rawPath = switch (params.mode) {
      DotShapeMode.symmetric  => _buildSymmetricPath(center, radius, params),
      DotShapeMode.asymmetric => _buildSuperformulaPath(center, radius, params),
    };

    // 공통 roundness 적용 (Path 보간으로 모서리 부드럽게)
    if (params.roundness > 0.001) {
      return _smoothPath(rawPath, params.roundness);
    }
    return rawPath;
  }

  // ── 대칭 모드: 극좌표 다각형 ──

  static Path _buildSymmetricPath(Offset center, double radius, DotShapeParams params) {
    final n = params.vertices;
    final rot = params.rotation * pi / 180;
    final path = Path();

    final vertices = <Offset>[];
    for (int i = 0; i < n * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? radius : radius * params.innerRadius;
      final angle = (i * pi / n) - pi / 2 + rot;
      vertices.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }

    path.moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    return path;
  }

  // ── 비대칭 모드: Superformula (Gielis, 1999) ──

  static Path _buildSuperformulaPath(Offset center, double radius, DotShapeParams params) {
    final rot = params.rotation * pi / 180;
    const steps = 128;

    // Superformula로 극좌표 점 생성
    final rawPoints = <Offset>[];
    for (int i = 0; i < steps; i++) {
      final theta = (i / steps) * 2 * pi;
      final r = _superformula(theta, params.sfM, params.sfN1, params.sfN2, params.sfN3, params.sfA, params.sfB);
      if (r.isNaN || r.isInfinite) continue;
      rawPoints.add(Offset(r * cos(theta), r * sin(theta)));
    }

    if (rawPoints.isEmpty) return Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    // bounding box 정규화 → 셀 크기에 맞춤 → rotation 적용
    final normalizedPoints = _normalizeAndTransform(rawPoints, center, radius, rot);

    final path = Path();
    path.moveTo(normalizedPoints[0].dx, normalizedPoints[0].dy);
    for (int i = 1; i < normalizedPoints.length; i++) {
      path.lineTo(normalizedPoints[i].dx, normalizedPoints[i].dy);
    }
    path.close();
    return path;
  }

  /// Superformula: r(θ) = ( |cos(mθ/4)/a|^n2 + |sin(mθ/4)/b|^n3 )^(-1/n1)
  static double _superformula(double theta, double m, double n1, double n2, double n3, double a, double b) {
    final cosVal = cos(m * theta / 4);
    final sinVal = sin(m * theta / 4);
    final t1 = pow((cosVal / a).abs(), n2);
    final t2 = pow((sinVal / b).abs(), n3);
    final sum = t1 + t2;
    if (sum == 0) return 1.0;
    return pow(sum, -1.0 / n1).toDouble();
  }

  /// 원시 좌표 → bounding box 정규화 → 셀 크기 맞춤 → rotation
  static List<Offset> _normalizeAndTransform(
    List<Offset> points, Offset center, double radius, double rot,
  ) {
    // 1. bounding box 계산
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final p in points) {
      minX = min(minX, p.dx); maxX = max(maxX, p.dx);
      minY = min(minY, p.dy); maxY = max(maxY, p.dy);
    }
    final w = maxX - minX;
    final h = maxY - minY;
    if (w == 0 || h == 0) return points;

    // 2. 정규화 + radius 스케일 + rotation
    final scale = radius / max(w, h) * 2 * 0.9; // 90% fill
    return points.map((p) {
      var x = (p.dx - (minX + maxX) / 2) * scale;
      var y = (p.dy - (minY + maxY) / 2) * scale;
      if (rot != 0) {
        final rx = x * cos(rot) - y * sin(rot);
        final ry = x * sin(rot) + y * cos(rot);
        x = rx; y = ry;
      }
      return Offset(center.dx + x, center.dy + y);
    }).toList();
  }

  /// Path 보간으로 모서리를 부드럽게 (Chaikin subdivision)
  static Path _smoothPath(Path rawPath, double roundness) { /* ... */ }

  /// 채움률 검증: 도형 면적 / 셀 면적 >= threshold
  static double computeFillRatio(Path path, double cellSize) {
    final bounds = path.getBounds();
    // 근사: path bounding box 면적 대비 실제 면적 (픽셀 카운팅 또는 삼각분할)
    // 간단 구현: bounding box area / cell area (보수적 추정)
    return (bounds.width * bounds.height) / (cellSize * cellSize);
  }
}
```

### 4.2 SuperellipsePath — Superellipse Path 생성

```dart
// lib/features/qr_result/utils/superellipse.dart

class SuperellipsePath {
  SuperellipsePath._();

  /// Superellipse |x/a|^n + |y/b|^n = 1 Path 생성.
  /// [rect]: bounding rect, [n]: 형태 파라미터 (2=원, 4=squircle, 20≈사각).
  /// [rotation]: 회전 각도(도).
  static Path buildPath(Rect rect, double n, {double rotation = 0.0}) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final a = rect.width / 2;
    final b = rect.height / 2;
    final rot = rotation * pi / 180;

    final path = Path();
    const steps = 100;
    for (int i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * pi;
      final cosT = cos(t);
      final sinT = sin(t);
      // Superellipse 좌표
      var x = a * cosT.sign * pow(cosT.abs(), 2 / n);
      var y = b * sinT.sign * pow(sinT.abs(), 2 / n);
      // 회전 적용
      if (rot != 0) {
        final rx = x * cos(rot) - y * sin(rot);
        final ry = x * sin(rot) + y * cos(rot);
        x = rx;
        y = ry;
      }
      final px = cx + x;
      final py = cy + y;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    return path;
  }

  /// 눈 프레임 렌더링: 외곽 링(evenOdd) + 내부 채움.
  static void paintEye(Canvas canvas, Rect bounds, EyeShapeParams params, Paint paint) {
    final m = bounds.width / 7;
    final holeRect = bounds.deflate(m);
    final innerRect = bounds.deflate(m * 2);

    // 외곽 링 (evenOdd)
    final ringPath = Path()..fillType = PathFillType.evenOdd;
    ringPath.addPath(buildPath(bounds, params.outerN, rotation: params.rotation), Offset.zero);
    ringPath.addPath(buildPath(holeRect, params.outerN, rotation: params.rotation), Offset.zero);
    canvas.drawPath(ringPath, paint);

    // 내부 채움
    final innerScaled = Rect.fromCenter(
      center: innerRect.center,
      width: innerRect.width * (params.innerScale / 0.43), // 기본 비율 대비 스케일
      height: innerRect.height * (params.innerScale / 0.43),
    );
    canvas.drawPath(buildPath(innerScaled, params.innerN, rotation: params.rotation), paint);
  }
}
```

### 4.3 QrMatrixHelper — QR 영역 분류기

```dart
// lib/features/qr_result/utils/qr_matrix_helper.dart

enum QrModuleType { finder, separator, timing, alignment, formatInfo, versionInfo, data }

class QrMatrixHelper {
  final int moduleCount;  // qrCode.moduleCount
  final int typeNumber;   // QR 버전 (1~40)

  QrMatrixHelper({required this.moduleCount, required this.typeNumber});

  /// QR 스펙 기반 영역 분류.
  QrModuleType classify(int row, int col) {
    // Finder Pattern: 3개 코너 7×7
    if (_isFinderRegion(row, col)) return QrModuleType.finder;
    // Separator: finder 주변 1모듈 갭
    if (_isSeparator(row, col)) return QrModuleType.separator;
    // Timing Pattern: row=6 또는 col=6 (finder 외부)
    if (_isTiming(row, col)) return QrModuleType.timing;
    // Alignment Pattern: 버전별 위치 테이블
    if (_isAlignment(row, col)) return QrModuleType.alignment;
    // Format Info: finder 인접 15비트
    if (_isFormatInfo(row, col)) return QrModuleType.formatInfo;
    // Version Info: v7+ 전용
    if (typeNumber >= 7 && _isVersionInfo(row, col)) return QrModuleType.versionInfo;

    return QrModuleType.data;
  }

  /// 애니메이션 적용 가능 여부.
  bool isAnimatable(int row, int col) => classify(row, col) == QrModuleType.data;

  /// 보호 영역 여부 (도트 렌더링에서 finder 제외 판단용).
  bool isProtected(int row, int col) => classify(row, col) != QrModuleType.data;

  /// Finder pattern 3개의 7×7 bounding box 목록.
  List<Rect> finderBounds(double moduleSize, Offset origin) {
    return [
      Rect.fromLTWH(origin.dx, origin.dy, 7 * moduleSize, 7 * moduleSize),                                           // top-left
      Rect.fromLTWH(origin.dx + (moduleCount - 7) * moduleSize, origin.dy, 7 * moduleSize, 7 * moduleSize),          // top-right
      Rect.fromLTWH(origin.dx, origin.dy + (moduleCount - 7) * moduleSize, 7 * moduleSize, 7 * moduleSize),          // bottom-left
    ];
  }

  // ── private helpers ──
  bool _isFinderRegion(int r, int c) {
    return (r < 7 && c < 7) ||                    // top-left
           (r < 7 && c >= moduleCount - 7) ||      // top-right
           (r >= moduleCount - 7 && c < 7);        // bottom-left
  }

  bool _isSeparator(int r, int c) {
    return (r == 7 && c < 8) || (r < 8 && c == 7) ||                          // TL
           (r == 7 && c >= moduleCount - 8) || (r < 8 && c == moduleCount - 8) || // TR
           (r == moduleCount - 8 && c < 8) || (r >= moduleCount - 8 && c == 7);   // BL
  }

  bool _isTiming(int r, int c) {
    return (r == 6 && c >= 8 && c < moduleCount - 8) ||
           (c == 6 && r >= 8 && r < moduleCount - 8);
  }

  // alignment pattern 위치 테이블 (QR 스펙)
  static const _alignmentPositions = <int, List<int>>{
    2: [6, 18], 3: [6, 22], 4: [6, 26], 5: [6, 30], 6: [6, 34],
    7: [6, 22, 38], 8: [6, 24, 42], 9: [6, 26, 46], 10: [6, 28, 50],
    // ... v11~v40 생략, 구현 시 전체 테이블 포함
  };

  bool _isAlignment(int r, int c) {
    final positions = _alignmentPositions[typeNumber];
    if (positions == null) return false;
    for (final pr in positions) {
      for (final pc in positions) {
        // finder 영역과 겹치는 alignment는 제외
        if (_isFinderRegion(pr, pc)) continue;
        if (r >= pr - 2 && r <= pr + 2 && c >= pc - 2 && c <= pc + 2) return true;
      }
    }
    return false;
  }

  bool _isFormatInfo(int r, int c) {
    return (r == 8 && (c < 9 || c >= moduleCount - 8)) ||
           (c == 8 && (r < 9 || r >= moduleCount - 8));
  }

  bool _isVersionInfo(int r, int c) {
    return (r < 6 && c >= moduleCount - 11 && c < moduleCount - 8) ||
           (c < 6 && r >= moduleCount - 11 && r < moduleCount - 8);
  }
}
```

### 4.4 QrAnimationEngine — 애니메이션 계산

```dart
// lib/features/qr_result/utils/qr_animation_engine.dart

/// 애니메이션 프레임에서 각 도트의 변형 값을 계산.
class QrAnimationEngine {
  QrAnimationEngine._();

  /// 도트(row, col)의 애니메이션 변형 계산.
  /// [t]: AnimationController value (0.0~1.0)
  /// [gridSize]: QR 매트릭스 moduleCount
  /// Returns: (scale, colorShift, opacity, rotationRad)
  static DotAnimFrame compute(
    QrAnimationParams params,
    double t,
    int row, int col,
    int gridSize,
  ) {
    if (!params.isAnimated) return DotAnimFrame.identity;

    switch (params.type) {
      case QrAnimationType.wave:
        final phase = (row + col) * params.frequency;
        final scale = sin(t * 2 * pi + phase) * params.amplitude * 0.4 + 0.8;
        return DotAnimFrame(scale: scale.clamp(0.6, 1.2));

      case QrAnimationType.rainbow:
        final hueShift = ((t + col / gridSize) * params.frequency) % 1.0;
        return DotAnimFrame(hueShift: hueShift);

      case QrAnimationType.pulse:
        final scale = sin(t * 2 * pi) * params.amplitude * 0.3 + 0.85;
        return DotAnimFrame(scale: scale.clamp(0.6, 1.2));

      case QrAnimationType.sequential:
        final delay = (row + col * gridSize) / (gridSize * gridSize);
        final opacity = ((t * params.speed - delay) * 3).clamp(0.0, 1.0);
        return DotAnimFrame(opacity: opacity.clamp(0.5, 1.0));

      case QrAnimationType.rotationWave:
        final dist = sqrt(pow(row - gridSize / 2, 2) + pow(col - gridSize / 2, 2));
        final rot = sin(t * 2 * pi + dist * params.frequency) * params.amplitude * pi / 4;
        return DotAnimFrame(rotationRad: rot);

      case QrAnimationType.none:
        return DotAnimFrame.identity;
    }
  }
}

/// 단일 도트의 애니메이션 프레임 값.
class DotAnimFrame {
  final double scale;       // 0.6~1.2
  final double hueShift;    // 0.0~1.0 (HSV hue offset)
  final double opacity;     // 0.5~1.0
  final double rotationRad; // 회전 (라디안)

  const DotAnimFrame({
    this.scale = 1.0,
    this.hueShift = 0.0,
    this.opacity = 1.0,
    this.rotationRad = 0.0,
  });

  static const identity = DotAnimFrame();
}
```

### 4.5 QrBoundaryClipper — QR 전체 외곽 클리핑

```dart
// lib/features/qr_result/utils/qr_boundary_clipper.dart

class QrBoundaryClipper {
  QrBoundaryClipper._();

  /// QR 전체 외곽 클리핑 Path 생성.
  /// [size]: QR 렌더링 영역 크기, [params]: 외곽 형태 파라미터.
  /// square(기본값)는 클리핑 없이 null 반환.
  static Path? buildClipPath(Size size, QrBoundaryParams params) {
    if (params.isDefault) return null; // 사각형 = 클리핑 불요

    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    final rot = params.rotation * pi / 180;

    switch (params.type) {
      case QrBoundaryType.square:
        return null;

      case QrBoundaryType.circle:
        return Path()..addOval(rect);

      case QrBoundaryType.superellipse:
        return SuperellipsePath.buildPath(rect, params.superellipseN, rotation: params.rotation);

      case QrBoundaryType.star:
        return _starPath(center, radius, params.starVertices, params.starInnerRadius, rot, params.roundness);

      case QrBoundaryType.heart:
        return _heartPath(center, radius, rot);

      case QrBoundaryType.hexagon:
        return _regularPolygonPath(center, radius, 6, rot, params.roundness);

      case QrBoundaryType.custom:
        // custom = superellipse + star 파라미터 조합
        return SuperellipsePath.buildPath(rect, params.superellipseN, rotation: params.rotation);
    }
  }

  /// 별 모양 Path. [n]: 꼭짓점 수, [innerR]: 내부 반지름 비율.
  static Path _starPath(Offset center, double radius, int n, double innerR, double rot, double roundness) {
    final path = Path();
    final vertices = <Offset>[];
    for (int i = 0; i < n * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? radius : radius * innerR;
      final angle = (i * pi / n) - pi / 2 + rot;
      vertices.add(Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)));
    }
    if (roundness > 0.001) {
      _addRoundedPolygon(path, vertices, roundness);
    } else {
      path.moveTo(vertices[0].dx, vertices[0].dy);
      for (int i = 1; i < vertices.length; i++) path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    return path;
  }

  /// 정다각형 Path. [sides]: 변 수 (6=육각형).
  static Path _regularPolygonPath(Offset center, double radius, int sides, double rot, double roundness) {
    final path = Path();
    final vertices = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2 + rot;
      vertices.add(Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)));
    }
    if (roundness > 0.001) {
      _addRoundedPolygon(path, vertices, roundness);
    } else {
      path.moveTo(vertices[0].dx, vertices[0].dy);
      for (int i = 1; i < vertices.length; i++) path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    return path;
  }

  static Path _heartPath(Offset center, double radius, double rot) { /* 하트 Bezier Path */ }
  static void _addRoundedPolygon(Path path, List<Offset> verts, double roundness) { /* cubicTo 보간 */ }

  /// Canvas에 외곽 클리핑 적용. paint() 시작 시 호출.
  /// 배경(quiet zone 포함) + 클리핑을 한번에 처리.
  static void applyClip(Canvas canvas, Size size, QrBoundaryParams params, {Color? bgColor}) {
    final clipPath = buildClipPath(size, params);
    if (clipPath == null) return; // square = no clip

    // 배경 채우기 (클리핑된 영역만)
    if (bgColor != null) {
      canvas.drawPath(clipPath, Paint()..color = bgColor);
    }
    canvas.clipPath(clipPath);
  }
}
```

### 4.6 CustomQrPainter — 통합 렌더러

```dart
// lib/features/qr_result/widgets/custom_qr_painter.dart

class CustomQrPainter extends CustomPainter {
  final QrCode qrCode;              // qr 패키지 매트릭스
  final Color color;
  final DotShapeParams dotParams;
  final EyeShapeParams eyeParams;
  final QrBoundaryParams boundaryParams;
  final QrAnimationParams animParams;
  final double animValue;            // 0.0~1.0 from AnimationController
  final QrMatrixHelper _helper;

  CustomQrPainter({
    required this.qrCode,
    required this.color,
    required this.dotParams,
    required this.eyeParams,
    this.boundaryParams = const QrBoundaryParams(),
    this.animParams = const QrAnimationParams(),
    this.animValue = 0.0,
  }) : _helper = QrMatrixHelper(
         moduleCount: qrCode.moduleCount,
         typeNumber: qrCode.typeNumber,
       ),
       super(repaint: null); // AnimatedBuilder가 repaint 관리

  @override
  void paint(Canvas canvas, Size size) {
    final n = qrCode.moduleCount;
    final m = size.width / n;  // 모듈 크기
    final paint = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;

    // 0. QR 전체 외곽 클리핑 (Boundary)
    canvas.save();
    QrBoundaryClipper.applyClip(canvas, size, boundaryParams);

    // 1. Finder Pattern 렌더링 (Superellipse)
    for (final bounds in _helper.finderBounds(m, Offset.zero)) {
      SuperellipsePath.paintEye(canvas, bounds, eyeParams, paint);
    }

    // 2. 데이터 도트 렌더링 (극좌표 다각형 + 애니메이션)
    for (int row = 0; row < n; row++) {
      for (int col = 0; col < n; col++) {
        if (!qrCode.isDark(row, col)) continue;
        if (_helper.classify(row, col) != QrModuleType.data &&
            _helper.classify(row, col) != QrModuleType.timing &&
            _helper.classify(row, col) != QrModuleType.alignment) continue;

        final center = Offset(col * m + m / 2, row * m + m / 2);
        final radius = m / 2;

        // 애니메이션 프레임 계산
        final frame = _helper.isAnimatable(row, col)
            ? QrAnimationEngine.compute(animParams, animValue, row, col, n)
            : DotAnimFrame.identity;

        // 변형 적용
        canvas.save();
        if (frame.rotationRad != 0) {
          canvas.translate(center.dx, center.dy);
          canvas.rotate(frame.rotationRad);
          canvas.translate(-center.dx, -center.dy);
        }

        final animPaint = Paint()
          ..color = _applyHueShift(color, frame.hueShift).withValues(alpha: frame.opacity)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        final dotPath = PolarPolygon.buildPath(center, radius * frame.scale, dotParams);
        canvas.drawPath(dotPath, animPaint);
        canvas.restore();
      }
    }

    // 3. 외곽 클리핑 복원
    canvas.restore();
  }

  Color _applyHueShift(Color base, double shift) {
    if (shift == 0) return base;
    final hsv = HSVColor.fromColor(base);
    return hsv.withHue((hsv.hue + shift * 360) % 360).toColor();
  }

  @override
  bool shouldRepaint(CustomQrPainter old) =>
      qrCode != old.qrCode ||
      color != old.color ||
      dotParams != old.dotParams ||
      eyeParams != old.eyeParams ||
      boundaryParams != old.boundaryParams ||
      animParams != old.animParams ||
      animValue != old.animValue;
}
```

---

## 5. UI/UX Design

### 5.1 모양 탭 레이아웃

```
┌────────────────────────────────────────────────────┐
│ [모양 탭 — 기본 모드]                                │
├────────────────────────────────────────────────────┤
│                                                    │
│ ■ 도트 모양                                        │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐              │
│ │+ │ │■ │ │● │ │◆ │ │♥ │ │★ │ │U1│ →(스크롤)     │
│ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘              │
│                                                    │
│ ■ 눈 외곽                                          │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                   │
│ │+ │ │□ │ │◎ │ │○ │ │◐ │ │U1│ →(스크롤)          │
│ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘                   │
│                                                    │
│ ■ 눈 내부                                          │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                   │
│ │+ │ │■ │ │● │ │◇ │ │★ │ │U1│ →(스크롤)          │
│ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘                   │
│                                                    │
│ ■ QR 전체 형태                                     │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐              │
│ │+ │ │□ │ │○ │ │◐ │ │★ │ │♥ │ │U1│ →(스크롤)     │
│ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘              │
│                                                    │
│ ■ 애니메이션                                       │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                   │
│ │+ │ │⊘ │ │〜│ │🌈│ │◉ │ │U1│ →(스크롤)          │
│ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘                   │
│                                                    │
│ ┌──────────────────┐ ┌──────────┐                 │
│ │ 🎲 랜덤 스타일    │ │  초기화   │                 │
│ └──────────────────┘ └──────────┘                 │
└────────────────────────────────────────────────────┘
```

### 5.2 미리보기 전략

**원칙: 드래그 중 = 모양 전용 미리보기, 손 떼면 = QR 코드 전체 미리보기**

슬라이더를 드래그하는 동안에는 QR 미리보기 영역이 **편집 중인 모양만 단독으로 확대** 표시한다.
슬라이더에서 손을 떼면(`onChangeEnd`) 전체 QR 코드에 파라미터를 적용하여 최종 결과를 보여준다.

이 방식의 장점:
- 드래그 중 전체 QR repaint 부하 없음 → 60fps 슬라이더 응답 보장
- 모양 형태를 크게 확대하여 세밀한 조정 가능
- 손을 떼면 실제 QR에서 최종 결과 확인 → 직관적 피드백 루프

#### 슬라이더 이벤트 매핑

```dart
Slider(
  value: _currentValue,
  onChanged: (v) {
    // 드래그 중: 모양 전용 미리보기만 갱신 (가벼운 단일 Path 렌더링)
    setState(() => _currentValue = v);
    // QrPreviewSection → 전용 미리보기 모드 활성화
    ref.read(shapePreviewModeProvider.notifier).state =
        ShapePreviewMode.dedicated;
  },
  onChangeEnd: (v) {
    // 손 뗌: QR 코드 전체에 적용
    ref.read(qrResultProvider.notifier).setDotParams(
      currentParams.copyWith(vertices: v.round()),
    );
    // QR 미리보기 복귀
    ref.read(shapePreviewModeProvider.notifier).state =
        ShapePreviewMode.fullQr;
  },
)
```

#### 미리보기 모드 상태

```dart
enum ShapePreviewMode { fullQr, dedicatedDot, dedicatedEye, dedicatedBoundary, dedicatedAnim }

/// QrPreviewSection 내부 분기
Widget build(BuildContext context) {
  final previewMode = ref.watch(shapePreviewModeProvider);
  return switch (previewMode) {
    ShapePreviewMode.fullQr          => _buildFullQrPreview(),
    ShapePreviewMode.dedicatedDot    => _DotShapePreview(params: dotParams),
    ShapePreviewMode.dedicatedEye    => _EyeShapePreview(params: eyeParams),
    ShapePreviewMode.dedicatedBoundary => _BoundaryShapePreview(params: boundaryParams),
    ShapePreviewMode.dedicatedAnim   => _buildFullQrPreview(), // 애니메이션은 항상 전체 QR
  };
}
```

#### 전용 미리보기 렌더링 내용

| 편집 대상 | 전용 미리보기 표시 | 크기 |
|----------|------------------|------|
| 도트 | 단일 도트 Path 확대 (현재 파라미터 기반) | 미리보기 영역 80% |
| 눈 | 단일 finder pattern (외곽 링 + 내부) 확대 | 미리보기 영역 80% |
| 외곽 (Boundary) | 외곽 클리핑 윤곽선 + 내부에 축소 그리드 패턴 | 미리보기 영역 90% |
| 애니메이션 | 항상 전체 QR (전체 맥락에서 봐야 효과가 보이므로) | 기존 160px |

> 애니메이션 편집은 예외적으로 항상 전체 QR에서 미리보기한다.
> 드래그 중에도 `onChanged`로 animValue를 실시간 갱신하여 전체 QR에 반영.

### 5.3 편집기 모드 레이아웃 (듀얼 모드)

```
┌────────────────────────────────────────────────────┐
│ [상단: 미리보기 영역 (184px 고정)]                    │
│ ┌────────────────────────────────────────────────┐ │
│ │                                                │ │
│ │   드래그 중: ★ 도트 모양 단독 확대 미리보기       │ │
│ │   손 뗌:    ▦ 전체 QR 코드 미리보기              │ │
│ │                                                │ │
│ └────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────┤
│ [하단: 도트 편집기 모드 — "+" 버튼 탭 시]             │
│                                                    │
│ ← 도트 모양 편집기                                  │
│                                                    │
│ ┌────────────────────────────────────┐             │
│ │  [■ 대칭]        [♥ 비대칭]        │  ← 토글     │
│ └────────────────────────────────────┘             │
│                                                    │
│ ── [대칭 모드 선택 시] ──────────────────            │
│                                                    │
│ 꼭짓점 수                                          │
│ ────────●──── 5                                   │
│                                                    │
│ 내부 반경                                          │
│ ──────────●── 0.7                                 │
│                                                    │
│ 둥글기 (공통)                                      │
│ ─●────────── 0.2                                  │
│                                                    │
│ 회전 (공통)                                        │
│ ──────●───── 45°                                  │
│                                                    │
│ ── [비대칭 모드 선택 시] ────────────────            │
│                                                    │
│ Superformula 프리셋 (5종):                         │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                          │
│ │● │ │■ │ │★ │ │❀ │ │♥ │                          │
│ └──┘ └──┘ └──┘ └──┘ └──┘                          │
│ 원  사각 별  꽃  하트                              │
│                                                    │
│ m (대칭 차수)                                      │
│ ──────●───── 5.0                                  │
│                                                    │
│ n1 (곡률 1)                                        │
│ ─●────────── 0.3                                  │
│                                                    │
│ n2 (곡률 2)                                        │
│ ─●────────── 0.3                                  │
│                                                    │
│ n3 (곡률 3)                                        │
│ ─●────────── 0.3                                  │
│                                                    │
│ a (X 스케일)                                       │
│ ─────●────── 1.0                                  │
│                                                    │
│ b (Y 스케일)                                       │
│ ─────●────── 1.0                                  │
│                                                    │
│ 회전 (공통)                                        │
│ ──────●───── 45°                                  │
│                                                    │
│ ⚠️ 채움률 42% — 인식률이 낮을 수 있습니다 (≥50% 권장) │
│                                                    │
│        ┌─────────┐    ┌─────────┐                 │
│        │  취소    │    │  확인    │                 │
│        └─────────┘    └─────────┘                 │
└────────────────────────────────────────────────────┘
```

### 5.4 User Flow

```
[모양 탭 진입]
  ├─ 기본 프리셋 선택 → 즉시 QR 반영
  │
  ├─ "+" 버튼 탭 (새 프리셋 생성 모드)
  │   ├─ 편집기 모드 전환 (인라인, 상단 미리보기 유지)
  │   ├─ 하단 액션 버튼(저장/공유) 숨김, 탭 스와이프 차단
  │   ├─ AppBar: [<] + "도트 모양 편집기" + [저장 FilledButton]
  │   ├─ [대칭/비대칭] 토글 선택
  │   │   ├─ [대칭] → 꼭짓점, 내부 반경 슬라이더
  │   │   └─ [비대칭] → Superformula 프리셋 5종 + m/n1/n2/n3/a/b 슬라이더 6개
  │   ├─ 공통 슬라이더: 회전, 크기(Scale 0.5~2.0, 중앙 0%=1.0x, -100%=0.5x, +100%=2.0x)
  │   │   └─ 슬라이더 내부 범위 -1.0~+1.0 (선형), scale 매핑: s≥0 → 1+s, s<0 → 1+s*0.5
  │   ├─ 슬라이더 드래그 중 → 도트 모양 단독 확대 미리보기
  │   ├─ 슬라이더에서 손 뗌 → 전체 QR 코드에 적용
  │   ├─ [저장 버튼] → 동일 파라미터 프리셋 있으면 기존 선택, 없으면 새로 Hive 저장
  │   ├─ [<] 뒤로가기 → "저장/취소" 다이얼로그 표시
  │   │   ├─ "저장" → 프리셋 생성 + 편집기 닫기
  │   │   ├─ "취소" → 변경 폐기 + 편집기 닫기
  │   │   └─ (다이얼로그 dismiss) → 편집기 유지
  │   └─ 채움률 < 50% → 경고 텍스트 표시
  │
  ├─ 사용자 프리셋 탭 → 즉시 QR 반영 + 선택 표시(primary 테두리 + check)
  │   └─ lastUsedAt 갱신 → 100ms 딜레이 후 AnimatedSwitcher 재정렬
  │
  ├─ 사용자 프리셋 롱프레스 (기존 프리셋 수정 모드)
  │   ├─ 편집기 모드 전환 (_editingPresetId = preset.id)
  │   ├─ [<] 뒤로가기 → 자동 저장 (기존 프리셋 덮어쓰기) + 편집기 닫기
  │   └─ [저장 버튼] → 기존 프리셋 업데이트 + 편집기 닫기
  │
  ├─ "전체보기" → 그리드 모달 BottomSheet
  │   ├─ 뷰 모드: 탭 → 선택, 롱프레스 → 편집 진입
  │   └─ 삭제 모드: 휴지통 아이콘 → 삭제 모드 전환 → 체크 후 삭제
  │
  └─ 랜덤 스타일 → 도트+눈+외곽+애니메이션 동시 랜덤 생성
```

### 5.5 Component List

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `QrShapeTab` | `tabs/qr_shape_tab.dart` | 모양 탭 전체 (프리셋 행 + 편집기 모드 전환) |
| `_DotPresetRow` | (QrShapeTab 내부) | 도트 프리셋 가로 스크롤 행 ("+" 포함) |
| `_EyePresetRow` | (QrShapeTab 내부) | 눈 프리셋 가로 스크롤 행 ("+" 포함) |
| `_BoundaryPresetRow` | (QrShapeTab 내부) | QR 전체 형태 프리셋 가로 스크롤 행 ("+" 포함) |
| `_AnimPresetRow` | (QrShapeTab 내부) | 애니메이션 프리셋 가로 스크롤 행 ("+" 포함) |
| `_DotEditor` | (QrShapeTab 내부) | [대칭/비대칭] 토글 + 대칭: 꼭짓점/내부반경/둥글기, 비대칭: Superformula 6슬라이더 + 프리셋 9종, 공통: 회전, 크기(Scale) |
| `_DotGridModal` | (QrShapeTab 내부) | 프리셋 전체보기 BottomSheet (뷰/삭제 모드, 롱프레스 편집) |
| `_PresetChip` | (QrShapeTab 내부) | 개별 프리셋 칩 (isSelected → primary 테두리 + check_circle) |
| `_SliderRow` | (QrShapeTab 내부) | 공용 슬라이더 위젯 (라벨 + 값 표시 + onChanged/onChangeEnd) |
| `_EyeEditor` | (QrShapeTab 내부) | 눈 파라미터 슬라이더 4개 (QR에 직접 반영) |
| `_BoundaryEditor` | (QrShapeTab 내부) | 외곽 형태 슬라이더 4개 — type, n/vertices, rotation, roundness (QR에 직접 반영) |
| `_AnimEditor` | (QrShapeTab 내부) | 애니메이션 파라미터 슬라이더 3개 + 타입 선택 (QR에 직접 반영) |
| `_ShapePresetButton` | (공용 위젯) | 프리셋 버튼 (선택 상태 + CustomPaint 썸네일) |
| `CustomQrPainter` | `widgets/custom_qr_painter.dart` | QR 전체 렌더링 (도트 + 눈 + 외곽 + 애니메이션) |

### 5.6 사용자 도트 프리셋 상태 관리 상세

#### QrShapeTabState 주요 상태 필드

```dart
class QrShapeTabState extends ConsumerState<QrShapeTab> {
  _EditorType? _activeEditor;       // 현재 열린 편집기 (null = 닫힘)
  String? _editingPresetId;         // 수정 중인 기존 프리셋 ID (null = 새 프리셋 생성)
  String? _selectedDotPresetId;     // 선택된 프리셋 ID (빌트인 = null)
  Timer? _reorderTimer;             // 선택→재정렬 딜레이 타이머 (100ms)

  DotShapeParams _editDot;          // 편집기 임시 파라미터
  List<UserShapePreset> _dotPresets; // Hive에서 로드, lastUsedAt 내림차순
}
```

#### 편집기 진입 분기

```dart
// + 버튼: 새 프리셋 생성 모드
_openEditor(_EditorType.dot);                    // editingId = null

// 롱프레스: 기존 프리셋 수정 모드
_openEditor(_EditorType.dot, editingId: p.id);   // editingId = preset ID

// 그리드 모달 편집: 기존 프리셋 수정 모드
_openEditor(_EditorType.dot, editingId: preset.id);
```

#### 뒤로가기(cancelAndCloseEditor) 동작

```dart
Future<bool> cancelAndCloseEditor() async {
  if (_editingPresetId != null) {
    // 수정 모드: 자동 저장 (기존 프리셋 파라미터 덮어쓰기)
    await _updateExistingPreset();
    _confirmEditor();
    return true;
  }
  // 생성 모드: 저장/취소 다이얼로그
  final result = await showDialog<bool>(...);
  if (result == true) { await _saveCurrentAsPreset(); _confirmEditor(); return true; }
  if (result == false) { _cancelEditor(); return true; }
  return false; // dismiss → 에디터 유지
}
```

#### 프리셋 선택 시 재정렬 시퀀스

```
1. 사용자 프리셋 탭
2. setState(() => _selectedDotPresetId = p.id)  ← 즉시 선택 표시
3. touchLastUsed(type, id)                       ← Hive lastUsedAt 갱신
4. _delayedReloadPresets()                       ← 100ms 타이머 시작
5. (100ms 후) _loadPresets()                     ← lastUsedAt 내림차순 재정렬
6. AnimatedSwitcher(300ms, crossfade)            ← 부드러운 전환 애니메이션
```

#### 프리셋 중복 방지 로직

```dart
// _saveCurrentAsPreset() 내부
if (_activeEditor == _EditorType.dot) {
  final existing = _dotPresets.where((p) => p.dotParams == _editDot).firstOrNull;
  if (existing != null) {
    // 동일 파라미터 프리셋 존재 → 새로 만들지 않고 기존 선택
    setState(() => _selectedDotPresetId = existing.id);
    await _datasource!.touchLastUsed(ShapePresetType.dot, existing.id);
    return;
  }
}
```

---

## 6. Error Handling

### 6.1 에러 시나리오

| Scenario | Handling |
|----------|----------|
| QR 데이터가 너무 길어 매트릭스가 큼 → 렌더링 느림 | moduleCount > 60이면 애니메이션 자동 비활성화 + 경고 |
| 편집기 슬라이더 드래그 시 QR repaint 부하 | 드래그 중 모양 ���용 미���보기(가벼운 단일 Path), onChangeEnd에서만 전체 QR 적용 |
| 극단적 파라미터로 스캔 불가 QR 생성 | QrReadabilityService 임계값 경고 SnackBar |
| 비대칭 도형 채움률 < 50% | 편집기 하단에 경고 텍스트 표시 + SnackBar. `PolarPolygon.computeFillRatio()` 실시간 계산 |
| 외곽 클리핑으로 finder pattern 잘림 → 스캔 불가 | 클리핑 시 quiet zone 패딩(5%) 보장 + 극단적 형태(별 innerR < 0.4 등)에 경고 |
| Hive 프리셋 저장 실패 | try-catch + SnackBar 에러 메시지 |
| 기존 JSON에 새 파라미터 필드 없음 | null 기본값 → 기존 enum 기반 렌더링으로 폴백 |
| AnimationController dispose 누락 | QrLayerStack에서 StatefulWidget으로 래핑, dispose 보장 |

---

## 7. Security Considerations

- [x] 사용자 프리셋은 로컬 Hive 전용 — 네트워크 전송 없음
- [x] QR 데이터(deepLink)는 기존 validateQrData()로 검증 완료
- [x] 파라미터 범위 clamp로 메모리 폭발 방지 (vertices ≤ 12, steps ≤ 100)
- N/A: 인증/인가 없음 (로컬 전용 기능)

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Method |
|------|--------|--------|
| Unit | PolarPolygon 대칭 Path | 극좌표 다각형 파라미터 조합별 Path 유효성 |
| Unit | PolarPolygon Superformula Path | Superformula 5 프리셋(원/사각/별/꽃/하트) Path 유효성 |
| Unit | PolarPolygon 채움률 | computeFillRatio() 반환값이 도형별 예상 범위 내인지 |
| Unit | SuperellipsePath 좌표 | n=2(원), n=4(squircle), n=20(≈사각) 비교 |
| Unit | QrMatrixHelper 영역 분류 | QR v1~v10에서 finder/alignment 영역 정확성 |
| Unit | QrBoundaryClipper Path | circle/star/hexagon 등 클리핑 Path 유효성 |
| Unit | QrAnimationEngine 범위 | scale/opacity 가 안전 범위 내인지 |
| Integration | CustomQrPainter 렌더링 | Golden test (기존 pretty_qr 출력과 비교) |
| Manual | 실기기 스캔 | 애니메이션 중 + 극단적 파라미터에서 스캔 테스트 |
| Manual | 프리셋 저장/복원 | 앱 재시작 후 Hive 데이터 유지 확인 |

### 8.2 Test Cases (Key)

- [ ] 기본 파라미터(square)로 기존 pretty_qr 출력과 동일한 QR 생성
- [ ] vertices=5, innerRadius=0.45 → 별 모양 도트 확인
- [ ] outerN=2.0 → 원형 눈, outerN=20.0 → 사각형 눈
- [ ] boundaryType=circle → QR이 원형으로 클리핑, finder pattern 보존
- [ ] boundaryType=star, innerR=0.3 → 경고 SnackBar 표시
- [ ] 애니메이션 wave 적용 시 finder pattern은 정적 유지
- [ ] Superformula sfHeart(m=1,n1=1,n2=0.8,n3=-0.5) → 하트 모양 도트 확인, 채움률 ≥ 50%
- [ ] Superformula sfStar(m=5,n1=0.3,n2=0.3,n3=0.3) → 별 모양 도트 확인
- [ ] Superformula sfFlower(m=6,n1=1,n2=1,n3=8) → 꽃 모양 도트 확인
- [ ] Superformula 극단 파라미터(n3=-5) → 채움률 < 50% 시 경고 표시
- [ ] [대칭]↔[비대칭] 토글 시 슬라이더 세트가 올바르게 전환
- [ ] 채움률 < 50% 시 경고 텍스트 표시
- [ ] "+" → 편집기 → 확인 → 프리셋 행에 추가 → 탭 시 적용

---

## 9. Clean Architecture

### 9.1 Layer Structure

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | QrShapeTab, CustomQrPainter, 편집기 UI | `tabs/`, `widgets/` |
| **Domain** | DotShapeParams, EyeShapeParams, QrAnimationParams, UserShapePreset | `domain/entities/` |
| **Infrastructure** | LocalUserShapePresetDatasource (Hive) | `data/datasources/` |
| **Utils** | PolarPolygon, SuperellipsePath, QrMatrixHelper, QrAnimationEngine | `utils/` |

### 9.2 This Feature's Layer Assignment

| Component | Layer | Location |
|-----------|-------|----------|
| `DotShapeParams` | Domain | `domain/entities/qr_shape_params.dart` |
| `EyeShapeParams` | Domain | `domain/entities/qr_shape_params.dart` |
| `QrAnimationParams` | Domain | `domain/entities/qr_animation_params.dart` |
| `QrBoundaryParams` | Domain | `domain/entities/qr_boundary_params.dart` |
| `UserShapePreset` | Domain | `domain/entities/user_shape_preset.dart` |
| `PolarPolygon` | Utils | `utils/polar_polygon.dart` |
| `SuperellipsePath` | Utils | `utils/superellipse.dart` |
| `QrBoundaryClipper` | Utils | `utils/qr_boundary_clipper.dart` |
| `QrMatrixHelper` | Utils | `utils/qr_matrix_helper.dart` |
| `QrAnimationEngine` | Utils | `utils/qr_animation_engine.dart` |
| `CustomQrPainter` | Presentation | `widgets/custom_qr_painter.dart` |
| `QrShapeTab` | Presentation | `tabs/qr_shape_tab.dart` |
| `LocalUserShapePresetDatasource` | Infrastructure | `data/datasources/local_user_shape_preset_datasource.dart` |

---

## 10. Coding Convention Reference

### 10.1 This Feature's Conventions

| Item | Convention Applied |
|------|-------------------|
| 파라미터 모델 | 불변 클래스 + const constructor + copyWith + toJson/fromJson |
| CustomPainter | shouldRepaint에서 모든 파라미터 비교, operator== + hashCode |
| 편집기 모드 | QrColorTab의 `_showCustomEditor` + `onEditorModeChanged` 패턴 동일 적용 |
| Hive 저장 | UserQrTemplate 패턴: JSON Map → Hive Box put/get |
| 상태 관리 | QrResultNotifier에 set 메서드 추가, copyWith로 상태 갱신 |
| i18n | 새 문자열은 모든 ARB 파일에 추가 |

---

## 11. Implementation Guide

### 11.1 File Structure

```
lib/features/qr_result/
├── domain/entities/
│   ├── qr_shape_params.dart          # DotShapeParams + EyeShapeParams
│   ├── qr_boundary_params.dart      # QrBoundaryParams + QrBoundaryType
│   ├── qr_animation_params.dart      # QrAnimationParams + QrAnimationType
│   └── user_shape_preset.dart        # UserShapePreset + ShapePresetType
├── data/datasources/
│   └── local_user_shape_preset_datasource.dart  # Hive CRUD
├── utils/
│   ├── polar_polygon.dart            # 극좌표 다각형 Path
│   ├── superellipse.dart             # Superellipse Path
│   ├── qr_boundary_clipper.dart      # 외곽 클리핑
│   ├── qr_matrix_helper.dart         # 영역 분류기
│   └── qr_animation_engine.dart      # 애니메이션 계산
├── widgets/
│   ├── custom_qr_painter.dart        # CustomPainter 통합 렌더러
│   ├── qr_preview_section.dart       # UPDATE: 새 렌더러 연동
│   └── qr_layer_stack.dart           # UPDATE: AnimatedBuilder 래핑
├── tabs/
│   └── qr_shape_tab.dart             # REDESIGN: 프리셋 행 + 편집기
├── qr_result_provider.dart           # UPDATE: 새 파라미터 상태
└── qr_result_screen.dart             # UPDATE: shapeEditorMode
```

### 11.2 Implementation Order

> 도트 → 눈 → 외곽(Boundary) → 애니메이션 순차 완성

| Step | 파일 | 설명 | FR |
|------|------|------|----|
| 1 | `qr_shape_params.dart` | DotShapeParams + EyeShapeParams 모델 정의 | FR-01,02 |
| 2 | `qr_boundary_params.dart` | QrBoundaryParams + QrBoundaryType 모델 정의 | FR-03 |
| 3 | `qr_animation_params.dart` | QrAnimationParams 모델 정의 | FR-10 |
| 4 | `polar_polygon.dart` | 극좌표 다각형 Path 생성 유틸 | FR-01 |
| 5 | `superellipse.dart` | Superellipse Path 생성 유틸 | FR-02 |
| 6 | `qr_boundary_clipper.dart` | QR 전체 외곽 클리핑 유틸 (SuperellipsePath 재사용) | FR-03 |
| 7 | `qr_matrix_helper.dart` | QR 영역 분류기 | FR-11 |
| 8 | `qr_animation_engine.dart` | 애니메이션 계산 엔진 | FR-10,12 |
| 9 | `custom_qr_painter.dart` | CustomPainter 통합 렌더러 (외곽 클리핑 포함) | FR-04 |
| 10 | `qr_result_provider.dart` | QrResultState에 새 필드 + Notifier 메서드 | FR-05 |
| 11 | `qr_layer_stack.dart` | 새 렌더러 교체 + AnimatedBuilder 래핑 | FR-04,10 |
| 12 | `qr_preview_section.dart` | buildPrettyQr → CustomQrPainter 교체 | FR-04,08 |
| 13 | `user_shape_preset.dart` | 프리셋 모델 (boundary 타입 포함) | FR-14 |
| 14 | `local_user_shape_preset_datasource.dart` | Hive CRUD (user_boundary_presets 박스 추가) | FR-14,15 |
| 15 | `qr_shape_tab.dart` | 프리셋 행 4종 + "+" 편집기 4종 UI 전면 재설계 | FR-05,13 |
| 16 | `qr_result_screen.dart` | shapeEditorMode + 탭 전환 확인 | FR-13 |
| 17 | `customization_mapper.dart` | 새 파라미터 직렬화 + 하위 호환 | FR-07 |
| 18 | `qr_dot_style.dart` | 기존 enum → DotShapeParams 매핑 | FR-06 |
| 19 | i18n ARB 파일 (10개 언어) | 새 문자열 추가 (외곽 형태 관련) | - |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-18 | Initial draft | tawool83 |
| 0.2 | 2026-04-18 | QR 전체 형태(Boundary) 기능 추가: QrBoundaryParams 모델, QrBoundaryClipper 유틸, UI 섹션 | tawool83 |
| 0.3 | 2026-04-18 | 미리보기 전략: 드래그 중 = 모양 전용 확대 미리보기, 손 뗌 = 전체 QR 적용 (onChanged/onChangeEnd 분리) | tawool83 |
| 0.4 | 2026-04-18 | squareness 제거 → [대칭/비대칭] 듀얼 모드 + Superformula(Gielis) 도입. DotShapeParams: ParametricShapeType enum 삭제 → sfM/sfN1/sfN2/sfN3/sfA/sfB 6개 파라미터로 교체. PolarPolygon: 개별 매개변수 방정식 5종 → 단일 _superformula() 함수로 통합. 편집기 UI: Superformula 프리셋 5종 + 슬라이더 6개 + 채움률 검증 | tawool83 |
| 0.5 | 2026-04-20 | 사용자 도트 프리셋 UX 상세 설계 반영: DotShapeParams.scale(0.8~1.15) 추가, UserShapePreset.lastUsedAt 정렬 + withLastUsed(), 편집기 뒤로가기 동작 분기(자동저장/다이얼로그), ID 기반 선택 표시(_selectedDotPresetId), AnimatedSwitcher 전환, 중복 방지, _DotGridModal/\_PresetChip/\_SliderRow 위젯 추가, User Flow 전면 재작성 | tawool83 |
| 0.6 | 2026-04-20 | 도트 크기 슬라이더 범위 확장: scale 0.8~1.15 → 0.5~2.0. 슬라이더 UX를 -100%~+100%(중앙 0%) 비선형 매핑으로 변경하여 ±100%에서 각각 절반/2배 크기. QR 인식 한계 값은 추후 테스트로 결정. | tawool83 |
| 0.7 | 2026-04-20 | Gap 분석 결과 반영: (1) Superformula 프리셋 표에 "수학 모델 기준 / 프로덕션 튜닝 값 별도 / 미구현" 주석 추가. (2) scale 렌더링 누락 버그 4곳(qr_dot_style, custom_qr_painter, qr_preview_section, qr_shape_tab) 수정 완료 명시. Match Rate 94%. | tawool83 |
| 0.8 | 2026-04-20 | 미구현 프리셋 4종(Leaf/Butterfly/Diamond/Teardrop) 완전 폐기 결정. Superformula 프리셋을 Circle/Square/Star/Flower/Heart **5종으로 확정**. 관련 설계 기술(3.1, 4.1, 6.3, Testing) 모두 5종 기준으로 갱신. | tawool83 |
