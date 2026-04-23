# svg-save Design Document

> **Summary**: QR 액션 바텀시트에 "SVG 저장" 메뉴 추가 + QrSvgGenerator 유틸로 벡터 QR 파일 생성·공유
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Author**: Claude
> **Date**: 2026-04-23
> **Status**: Draft
> **Planning Doc**: [svg-save.plan.md](../../01-plan/features/svg-save.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. `CustomQrPainter`의 렌더링 로직과 **시각적으로 동일한** SVG 출력 생성
2. 기존 Clean Architecture 계층(UseCase → Repository) 준수
3. 외부 패키지 **무추가** — 수학 로직 자체 구현으로 SVG path data 문자열 생성
4. `QrTask.customization` 에 저장된 스타일 데이터만으로 SVG 생성 (추가 state 주입 불필요)

### 1.2 Design Principles

- **Single Responsibility**: `QrSvgGenerator` = SVG 문자열 생성만 담당, I/O는 Repository
- **DRY-within-boundary**: PolarPolygon/SuperellipsePath의 수학 공식을 SVG path data 문자열로 재현 (Flutter `Path` API 미사용 — dart:ui 의존 제거)
- **Graceful Degradation**: `customDotParams`/`customEyeParams` 없는 구 데이터 → 기본값 fallback

---

## 2. Architecture

### 2.1 디렉터리 트리 (변경분)

```
lib/features/qr_result/
├── utils/
│   └── qr_svg_generator.dart              # NEW ≤400줄
├── domain/
│   ├── repositories/
│   │   └── qr_output_repository.dart      # MODIFY: +saveAsSvg
│   └── usecases/
│       └── save_qr_as_svg_usecase.dart    # NEW ≤30줄
├── data/
│   └── repositories/
│       └── qr_output_repository_impl.dart # MODIFY: +saveAsSvg 구현
└── presentation/
    └── providers/
        └── qr_result_providers.dart       # MODIFY: +saveQrAsSvgUseCaseProvider

lib/features/home/
└── widgets/
    └── qr_task_action_sheet.dart           # MODIFY: +ListTile, +_saveAsSvg()
```

### 2.2 데이터 흐름

```
QrTaskActionSheet._saveAsSvg(context, ref)
  │
  ├─ 1. QrTask.meta.deepLink → QrCode(deepLink, ecLevel) → QrImage
  │     (qr 패키지, 기존 의존성)
  │
  ├─ 2. QrTask.customization → DotShapeParams, EyeShapeParams,
  │     QrBoundaryParams, 색상/그라디언트 추출
  │
  ├─ 3. QrSvgGenerator.generate(qrImage, dotParams, eyeParams,
  │       boundaryParams, colorArgb, gradient?) → String (SVG)
  │
  └─ 4. ref.read(saveQrAsSvgUseCaseProvider)(svgString, appName)
        → QrOutputRepository.saveAsSvg(svgString, appName)
          → 임시 .svg 파일 → share_plus 공유 시트
```

---

## 3. Detailed Signatures

### 3.1 `QrSvgGenerator` (New — `utils/qr_svg_generator.dart`)

순수 함수 유틸. Flutter dart:ui **비의존** (dart:math만 사용).

```dart
import 'dart:math';
import 'package:qr/qr.dart';
import '../domain/entities/qr_shape_params.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../../qr_task/domain/entities/qr_gradient_data.dart';

class QrSvgGenerator {
  QrSvgGenerator._();

  /// QR 데이터 + 스타일 → SVG 문자열.
  ///
  /// [cellSize] SVG 내 각 모듈 크기(px). 기본 10.
  /// [ecLevel] 오류 수정 레벨 (0=L, 1=M, 2=Q, 3=H).
  static String generate({
    required String data,
    int ecLevel = 2,
    DotShapeParams dotParams = const DotShapeParams(),
    EyeShapeParams eyeParams = const EyeShapeParams(),
    QrBoundaryParams boundaryParams = const QrBoundaryParams(),
    int colorArgb = 0xFF000000,
    QrGradientData? gradient,
    double cellSize = 10.0,
  });
}
```

**내부 구현 세부**:

| 메서드 (private) | 책임 |
|---|---|
| `_buildDotPathData(center, radius, params)` | PolarPolygon 수학 재현 → SVG path `d` 문자열 |
| `_buildSuperformulaPathData(center, radius, params)` | Superformula 재현 → SVG path `d` 문자열 |
| `_buildSuperellipsePathData(rect, n, rotation)` | Superellipse 재현 → SVG path `d` 문자열 |
| `_buildEyeSvg(bounds, eyeParams, rotDeg)` | Finder pattern SVG: outer RRect ring (fill-rule=evenodd) + inner superellipse |
| `_buildClipPathSvg(size, boundaryParams)` | Boundary 클리핑 → SVG `<clipPath>` + `<defs>` |
| `_buildGradientDefs(gradient, size)` | QrGradientData → SVG `<linearGradient>` / `<radialGradient>` / `<sweepGradient>` |
| `_colorToSvg(int argb)` | ARGB int → `#RRGGBB` + opacity attribute |
| `_fmt(double v)` | 소수점 2자리 포맷 (SVG 파일 크기 최적화) |

**QR 데이터 생성**: `qr` 패키지의 `QrCode.fromData(data: data, errorCorrectLevel: ecLevel)` → `QrImage` 사용. 이 패키지는 기존 의존성이며 dart:ui에 의존하지 않음.

**모듈 분류**: `QrMatrixHelper` 사용하여 finder/separator/timing/alignment/formatInfo/versionInfo/data 분류. `QrMatrixHelper`는 dart:ui `Rect`/`Offset`을 `finderBounds()`에서만 사용하므로, SVG Generator에서는 분류 로직(`classify`, `isAnimatable`)만 호출하고 bounds는 직접 계산.

> **dart:ui 의존성 이슈**: `QrMatrixHelper.finderBounds()`는 `Rect`를 반환하므로 dart:ui 필요. 두 가지 선택:
> 1. `QrSvgGenerator`에서 `QrMatrixHelper`를 import하되 `finderBounds()` 대신 직접 좌표 계산
> 2. `QrMatrixHelper`의 `classify()` 만 사용 (이는 int row/col → enum 반환, dart:ui 불필요)
>
> **결정**: 옵션 2. `classify()`만 import. finder bounds 좌표는 QR 스펙 고정(0,0 / n-7,0 / 0,n-7 각 7×7)이므로 직접 계산.

### 3.2 SVG 출력 구조

```xml
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 {totalSize} {totalSize}"
     width="{totalSize}" height="{totalSize}">
  <defs>
    <!-- 그라디언트 (있는 경우) -->
    <linearGradient id="qr-grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#..." />
      <stop offset="100%" stop-color="#..." />
    </linearGradient>
    <!-- 클리핑 (boundary != square) -->
    <clipPath id="qr-clip">
      <path d="..." />
    </clipPath>
  </defs>

  <g clip-path="url(#qr-clip)" fill="{fillColor|url(#qr-grad)}">
    <!-- Finder patterns (3개) -->
    <g transform="rotate(0, cx, cy)">
      <path d="..." fill-rule="evenodd" />  <!-- outer ring -->
      <path d="..." />                       <!-- inner fill -->
    </g>
    <!-- ... finder 2, 3 -->

    <!-- Data + structural dots (각각 <path>) -->
    <path d="..." />
    <path d="..." />
    <!-- ... -->
  </g>
</svg>
```

**totalSize** = `moduleCount * cellSize` (예: 33모듈 × 10px = 330px viewBox)

### 3.3 `QrOutputRepository` 변경 (Modify)

```dart
// domain/repositories/qr_output_repository.dart
abstract class QrOutputRepository {
  Future<Result<bool>> saveToGallery(Uint8List imageBytes, String appName);
  Future<Result<void>> shareImage(Uint8List imageBytes, String appName);
  Future<Result<void>> printQrCode({...});
  Future<Result<void>> saveAsSvg(String svgString, String appName); // NEW
}
```

### 3.4 `QrOutputRepositoryImpl.saveAsSvg` 구현 (Modify)

```dart
@override
Future<Result<void>> saveAsSvg(String svgString, String appName) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/apptag_${appName.replaceAll(' ', '_')}_qr.svg',
    );
    await file.writeAsString(svgString);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/svg+xml')],
      text: 'AppTag: $appName QR (SVG)',
    );
    return const Success(null);
  } catch (e, st) {
    return Err(UnexpectedFailure('SVG 저장 실패: $e',
        cause: e, stackTrace: st));
  }
}
```

### 3.5 `SaveQrAsSvgUseCase` (New)

```dart
class SaveQrAsSvgUseCase {
  final QrOutputRepository _repository;
  const SaveQrAsSvgUseCase(this._repository);

  Future<Result<void>> call(String svgString, String appName) =>
      _repository.saveAsSvg(svgString, appName);
}
```

### 3.6 Provider 등록 (Modify — `qr_result_providers.dart`)

```dart
import '../../domain/usecases/save_qr_as_svg_usecase.dart';

final saveQrAsSvgUseCaseProvider = Provider<SaveQrAsSvgUseCase>((ref) {
  return SaveQrAsSvgUseCase(ref.watch(qrOutputRepositoryProvider));
});
```

### 3.7 `QrTaskActionSheet` UI 변경 (Modify)

```dart
// "갤러리 저장" ListTile 바로 아래 추가 (line ~79)
ListTile(
  leading: const Icon(Icons.image_outlined),  // SVG 아이콘
  title: Text(l10n.actionSaveSvg),
  onTap: () => _saveAsSvg(context, ref),
),
```

**`_saveAsSvg` 메서드**:

```dart
void _saveAsSvg(BuildContext context, WidgetRef ref) {
  Navigator.pop(context);

  // 1. customization에서 파라미터 추출
  final c = task.customization;
  final dotParams = c.customDotParams != null
      ? DotShapeParams.fromJson(c.customDotParams!)
      : const DotShapeParams();
  final eyeParams = c.customEyeParams != null
      ? EyeShapeParams.fromJson(c.customEyeParams!)
      : const EyeShapeParams();
  final boundaryParams = c.boundaryParams != null
      ? QrBoundaryParams.fromJson(c.boundaryParams!)
      : const QrBoundaryParams();

  // 2. SVG 생성
  final svgString = QrSvgGenerator.generate(
    data: task.meta.deepLink,
    dotParams: dotParams,
    eyeParams: eyeParams,
    boundaryParams: boundaryParams,
    colorArgb: c.qrColorArgb,
    gradient: c.gradient,
  );

  // 3. 공유
  ref.read(saveQrAsSvgUseCaseProvider)(svgString, task.name);
}
```

---

## 4. SVG Path Data 생성 상세

### 4.1 대칭 도트 (PolarPolygon 재현)

PolarPolygon._buildSymmetricPath 수학 로직을 SVG `d` 문자열로 변환:

```
vertices 생성: outer/inner 교대
  for i in 0..<n*2:
    isOuter = i.isEven
    r = isOuter ? radius : radius * innerRadius
    angle = (i * π / n) - π/2 + rotation
    x = center.x + r * cos(angle)
    y = center.y + r * sin(angle)

innerRadius >= 0.999 → collapse (짝수 인덱스만)

roundness <= 0.001:
  → SVG: M x0,y0 L x1,y1 L x2,y2 ... Z

roundness > 0:
  → SVG: M first.x,first.y
    for each vertex:
      L p1.x,p1.y Q curr.x,curr.y p2.x,p2.y
    Z
```

### 4.2 비대칭 도트 (Superformula 재현)

Superformula `r(θ) = (|cos(mθ/4)/a|^n2 + |sin(mθ/4)/b|^n3)^(-1/n1)`:

```
128 steps, 정규화(bounding box → cell 크기), rotation 적용
→ SVG: M x0,y0 L x1,y1 ... L x127,y127 Z
```

### 4.3 눈 (Finder Pattern)

Superellipse paintEye 로직 재현:

```
외곽 ring:
  SVG RRect → 4개 arc 조합
  outer RRect: radius[Q] = (1 - cornerQ[i]) * maxR
  hole RRect: deflate(m), 같은 corner 비율
  → <path d="outer + hole" fill-rule="evenodd" />

내부 fill:
  Superellipse |x/a|^n + |y/b|^n = 1
  → 100-step polyline
  → <path d="M ... L ... Z" />
```

**RRect → SVG path 변환**:
SVG에는 native RRect 없으므로 4변 + 4 arc로 분해:
```
M (left+tlRadius, top)
L (right-trRadius, top)
A trRadius trRadius 0 0 1 (right, top+trRadius)
L (right, bottom-brRadius)
A brRadius brRadius 0 0 1 (right-brRadius, bottom)
L (left+blRadius, bottom)
A blRadius blRadius 0 0 1 (left, bottom-blRadius)
L (left, top+tlRadius)
A tlRadius tlRadius 0 0 1 (left+tlRadius, top)
Z
```

### 4.4 Boundary 클리핑

| type | SVG 변환 |
|------|---------|
| square | 클리핑 없음 |
| circle | `<circle cx cy r />` 또는 `<ellipse />` |
| superellipse | 100-step polyline (SuperellipsePath 재현) |
| star | PolarPolygon과 동일 구조 (outer/inner 교대) |
| heart | cubicTo → SVG `C` 커맨드 |
| hexagon | 6각형 정다각형 |

### 4.5 그라디언트

| QrGradientData.type | SVG |
|---|---|
| `linear` | `<linearGradient>` — angleDegrees → x1/y1/x2/y2 변환 |
| `radial` | `<radialGradient>` — center → cx/cy |
| `sweep` | SVG 미지원 → linear fallback |

**angle → SVG 좌표 변환**:
```dart
final rad = angleDegrees * π / 180;
x1 = 50 - cos(rad) * 50  // %
y1 = 50 - sin(rad) * 50
x2 = 50 + cos(rad) * 50
y2 = 50 + sin(rad) * 50
```

---

## 5. Edge Cases

| Case | 처리 |
|------|------|
| `customDotParams` null (구 데이터) | `DotShapeParams()` 기본값 (사각 도트) |
| `customEyeParams` null 또는 legacy (outerN만) | `EyeShapeParams()` 기본값 |
| `gradient` null | 단색 `fill="#RRGGBB"` |
| `gradient.colorsArgb` 빈 리스트 | 단색 fallback |
| `boundaryParams.isFrameMode == true` | 프레임 모드 SVG 미지원 → clipPath 모드로 fallback (QR만 출력) |
| `deepLink` 빈 문자열 | 스낵바 에러 ("QR 데이터 없음") |
| 알파 채널 있는 색상 (0x80FF0000) | SVG `fill-opacity` 속성 반영 |

---

## 6. l10n

### `app_ko.arb` 추가 키

```json
"actionSaveSvg": "SVG 저장",
"msgSvgSaved": "SVG 파일이 공유 시트에 준비되었습니다"
```

ko 이외 언어는 ko fallback (정책 준수).

---

## 7. Implementation Order

| Step | Task | File | Est. Lines |
|------|------|------|-----------|
| 1 | `QrSvgGenerator` 구현 | `utils/qr_svg_generator.dart` | ~350 |
| 2 | `QrOutputRepository.saveAsSvg` 인터페이스 추가 | `domain/repositories/qr_output_repository.dart` | +1 |
| 3 | `QrOutputRepositoryImpl.saveAsSvg` 구현 | `data/repositories/qr_output_repository_impl.dart` | +15 |
| 4 | `SaveQrAsSvgUseCase` 생성 | `domain/usecases/save_qr_as_svg_usecase.dart` | ~12 |
| 5 | `saveQrAsSvgUseCaseProvider` 등록 | `presentation/providers/qr_result_providers.dart` | +5 |
| 6 | `QrTaskActionSheet` UI + `_saveAsSvg()` | `home/widgets/qr_task_action_sheet.dart` | +30 |
| 7 | l10n 키 추가 + gen | `lib/l10n/app_ko.arb` + generated | +2 |

**의존 순서**: 1 → 2 → 3 → 4 → 5 → 6 → 7 (순차)

---

## 8. FR Traceability

| FR | Design Section | Verification |
|----|---------------|-------------|
| FR-01 | 3.7 QrTaskActionSheet UI | ListTile 위치 확인 |
| FR-02 | 3.1 QrSvgGenerator, 4.1~4.5 | SVG 브라우저 렌더 비교 |
| FR-03 | 3.4 saveAsSvg | share_plus 공유 시트 |
| FR-04 | 5. Edge Cases (clearZone) | 로고 영역 비어있음 확인 |
| FR-05 | 3.2 SVG 출력 구조 | viewBox 크기 검증 |
| FR-06 | 4.5 그라디언트 | SVG gradient 렌더 확인 |
| FR-07 | 4.4 Boundary 클리핑 | clipPath 적용 확인 |
