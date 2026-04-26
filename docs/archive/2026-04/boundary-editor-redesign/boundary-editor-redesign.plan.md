# Plan: boundary-editor-redesign — 맞춤 외곽 에디터 UI 재설계

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 외곽 종류가 ChoiceChip 나열로 되어 있어 공간 비효율적이고, 외곽선 스타일/색상·마진 패턴 색상 등 세부 설정이 불가 |
| **Solution** | 외곽 종류를 드롭다운으로 전환, 외곽선 종류(실선/점선 등)+색상 선택기 추가, 마진 패턴에 독립 색상 설정 제공 |
| **Function UX Effect** | 에디터 상단 1행에 외곽+선 종류+선 색을 컴팩트하게 배치, 수직 스크롤 감소 및 세밀한 커스터마이징 가능 |
| **Core Value** | QR 프레임 표현력 대폭 확장 — 외곽선 스타일, 외곽선 색, 패턴 색을 독립 제어 |

---

## 1. 요구사항

### 1.1 사용자 요청 원문
> "맞춤 외각"에 "외각 종류"를 드랍다운으로 변경해주고, 그 우측에 외각 선 종류(실선, 점선, 등등등), 외각선 색, 그 하단에 프레임 크기, "마진 패턴" 도 색상을 설정할 수 있도록 기능을 제공해줘.

### 1.2 기능 분해

| # | 기능 | 현재 | 변경 후 |
|---|------|------|---------|
| F1 | 외곽 종류 선택 | `Wrap<ChoiceChip>` (5개 나열) | `DropdownButton<QrBoundaryType>` |
| F2 | 외곽선 종류 (신규) | 없음 | 실선/점선/파선/일점쇄선/이중선 선택 (드롭다운 or ChoiceChip) |
| F3 | 외곽선 색 (신규) | 없음 (고정 — 배경색과 동일) | 색상 피커 (원형 버튼 → 바텀시트 ColorPicker) |
| F4 | 프레임 크기 | `_SliderRow` (기존 유지) | 위치만 이동 — F1~F3 아래 배치 |
| F5 | 마진 패턴 색상 (신규) | 자동 계산 (`qrColor * 0.4`) | 독립 색상 피커 |

---

## 2. 도메인 모델 변경

### 2.1 신규 enum: `QrBorderStyle`

```dart
// lib/features/qr_result/domain/entities/qr_border_style.dart
enum QrBorderStyle {
  none,        // 외곽선 없음
  solid,       // ────── 실선
  dashed,      // -- -- -- 파선
  dotted,      // ·····  점선
  dashDot,     // -·-·-· 일점쇄선
  double_,     // ══════ 이중선
}
```

### 2.2 `QrBoundaryParams` 필드 추가 (3개)

```dart
// 기존 10개 필드 + 신규 3개
class QrBoundaryParams {
  // ... 기존 필드 ...

  // ── 신규: 외곽선 스타일 ──
  final QrBorderStyle borderStyle;   // 기본: solid
  final int borderColorArgb;         // 기본: 0xFF000000 (검정)
  final double borderWidth;          // 기본: 2.0 (1.0~6.0)

  // ── 신규: 마진 패턴 색상 ──
  final int? patternColorArgb;       // null = 자동 (기존 로직: qrColor * 0.4)
}
```

**설계 결정**:
- 색상은 `int` (ARGB) 로 저장 — Hive JSON 직렬화 용이, `Color(argb)` 변환 단순
- `patternColorArgb` 를 nullable 로 — `null` 이면 기존 자동 계산 유지 (backward compat 불필요하나 합리적 기본값)
- `borderWidth` 추가 — 선 종류와 함께 두께도 제어 가능하면 표현력 증가

### 2.3 `QrBoundaryParams` 변경 상세

| 항목 | 변경 |
|------|------|
| 생성자 | `borderStyle`, `borderColorArgb`, `borderWidth`, `patternColorArgb` 파라미터 추가 |
| `copyWith()` | 4개 필드 추가 + `patternColorArgb` nullable clearing (`clearPatternColor: bool`) |
| `toJson()` | 4개 필드 직렬화 |
| `fromJson()` | 4개 필드 역직렬화 (기존 데이터 호환: 없으면 기본값) |
| `==` / `hashCode` | 4개 필드 포함 |
| 프리셋 상수 | 기존 유지 (신규 필드는 기본값) |

---

## 3. UI 레이아웃 변경

### 3.1 `_BoundaryEditor` 새 레이아웃

```
┌─────────────────────────────────────────────────┐
│ Row 1: [외곽 종류 ▼ Dropdown] [선 종류 ▼] [● 색] │
├─────────────────────────────────────────────────┤
│ Row 2: 선 두께 슬라이더 (borderStyle != none)     │
├─────────────────────────────────────────────────┤
│ Row 3: 프레임 크기 슬라이더 (type != square)       │
├─────────────────────────────────────────────────┤
│ Row 4: 타입별 슬라이더 (superellipseN / star / 등) │
├─────────────────────────────────────────────────┤
│ Row 5: 회전 슬라이더                              │
├─────────────────────────────────────────────────┤
│ Row 6: 둥글기 슬라이더 (star/hexagon)             │
├─────────────────────────────────────────────────┤
│ Row 7: [마진 패턴 ▼ Dropdown] [● 패턴 색]         │
│         (isFrameMode)                            │
├─────────────────────────────────────────────────┤
│ Row 8: 패턴 밀도 슬라이더 (pattern != none)       │
├─────────────────────────────────────────────────┤
│ Row 9: 패딩 슬라이더 (!isFrameMode)               │
└─────────────────────────────────────────────────┘
```

### 3.2 Row 1 상세 (핵심 변경)

```
[외곽 종류          ▼] [선 종류    ▼] [●]
 DropdownButton          Dropdown     ColorButton
 (circle/super/          (solid/      → 바텀시트
  star/heart/hex)         dashed/      ColorPicker
                          dotted/...)
```

- **외곽 종류 드롭다운**: `DropdownButton<QrBoundaryType>` — square/custom 제외한 5종
- **선 종류 드롭다운**: `DropdownButton<QrBorderStyle>` — 6종 (none 포함)
- **외곽선 색 버튼**: 원형 `Container` (현재 색상 표시) → tap 시 색상 피커 바텀시트

### 3.3 마진 패턴 색상 (Row 7)

마진 패턴도 드롭다운으로 전환 + 우측에 색상 버튼 추가:
```
[마진 패턴        ▼]  [●]
 DropdownButton       패턴색
 (없음/도트/미로/
  지그재그/물결/격자)
```

---

## 4. 렌더링 변경

### 4.1 Canvas 렌더링 (`DecorativeFramePainter`)

현재: `QrBoundaryClipper.buildClipPath()` → clip + fill
변경: clip + fill 후, **외곽선 Path를 `borderStyle` 에 따라 stroke**

```dart
// DecorativeFramePainter.paint() 에 추가할 로직
if (borderStyle != QrBorderStyle.none) {
  final borderPaint = Paint()
    ..color = Color(borderColorArgb)
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth;

  // dashPath 적용 (dashed/dotted/dashDot)
  if (borderStyle == QrBorderStyle.solid) {
    canvas.drawPath(framePath, borderPaint);
  } else if (borderStyle == QrBorderStyle.double_) {
    // 이중선: 바깥 + 안쪽 (offset)
    canvas.drawPath(framePath, borderPaint);
    // inner path (scale 0.95)
    canvas.drawPath(innerFramePath, borderPaint);
  } else {
    // dashed/dotted/dashDot → path_drawing 패키지 or 수동 dash
    final dashedPath = dashPath(framePath, dashArray);
    canvas.drawPath(dashedPath, borderPaint);
  }
}
```

**점선/파선 구현 옵션**: `path_drawing` 패키지 (pub.dev) 사용 or Canvas dashPathEffect 수동 구현. `path_drawing` 이 더 간결.

### 4.2 SVG 렌더링 (`QrSvgGenerator`)

SVG에서는 CSS `stroke-dasharray` 속성으로 간단 구현:
```xml
<path d="..." stroke="#000000" stroke-width="2"
      stroke-dasharray="8,4"  fill="none" />
```

| QrBorderStyle | stroke-dasharray |
|--------------|-----------------|
| solid | (없음) |
| dashed | "8,4" |
| dotted | "2,2" |
| dashDot | "8,4,2,4" |
| double_ | 두 개 path (outer + inner) |

### 4.3 마진 패턴 색상

현재 `patternColor` 는 `qr_layer_stack.dart:263-265` 에서 자동 계산:
```dart
final patternColor = activeGradient != null
    ? Colors.black.withValues(alpha: 0.4)
    : state.style.qrColor.withValues(alpha: 0.4);
```

변경: `boundaryParams.patternColorArgb != null` 이면 해당 색상 사용:
```dart
final patternColor = state.style.boundaryParams.patternColorArgb != null
    ? Color(state.style.boundaryParams.patternColorArgb!)
    : (activeGradient != null
        ? Colors.black.withValues(alpha: 0.4)
        : state.style.qrColor.withValues(alpha: 0.4));
```

---

## 5. 변경 파일 목록

### 5.1 신규 파일

| 파일 | 설명 |
|------|------|
| `domain/entities/qr_border_style.dart` | `QrBorderStyle` enum |

### 5.2 수정 파일

| 파일 | 변경 내용 |
|------|-----------|
| `domain/entities/qr_boundary_params.dart` | 4개 필드 추가 (`borderStyle`, `borderColorArgb`, `borderWidth`, `patternColorArgb`) + copyWith/toJson/fromJson/==/hashCode |
| `tabs/qr_shape_tab/boundary_editor.dart` | UI 전면 재설계 — 드롭다운 + 선 종류 + 색상 피커 + 패턴 색상 |
| `widgets/decorative_frame_painter.dart` | 외곽선 stroke 렌더링 추가 (borderStyle/borderColor/borderWidth) |
| `widgets/qr_layer_stack.dart` | patternColor 계산 로직 변경 (사용자 지정 색 우선) |
| `utils/qr_svg_generator.dart` | SVG 외곽선 stroke + stroke-dasharray 렌더링 추가 |
| `utils/qr_boundary_clipper.dart` | (변경 없을 수 있음 — 기존 buildClipPath 재사용) |
| `l10n/app_ko.arb` | 신규 키 8개 추가 |

### 5.3 의존성 검토

| 패키지 | 용도 | 필요 여부 |
|--------|------|-----------|
| `path_drawing` | Canvas dashed path | 검토 필요 — 수동 구현도 가능 |
| `flex_color_picker` or 기존 색상 피커 | 색상 선택 바텀시트 | 기존 색상 탭에서 사용 중인 피커 재사용 |

---

## 6. l10n 추가 키

```json
{
  "labelBorderStyle": "선 종류",
  "labelBorderColor": "선 색상",
  "sliderBorderWidth": "선 두께",
  "labelPatternColor": "패턴 색상",
  "borderNone": "없음",
  "borderSolid": "실선",
  "borderDashed": "파선",
  "borderDotted": "점선",
  "borderDashDot": "일점쇄선",
  "borderDouble": "이중선"
}
```

---

## 7. 아키텍처

- **Project Level**: Flutter Dynamic x Clean Architecture x R-series
- **State Management**: Riverpod StateNotifier
- **로컬 저장**: Hive (JSON 직렬화)
- **라우팅**: go_router

`QrBoundaryParams` 는 기존 value object 에 필드를 추가하는 확장이므로 새 sub-state 불필요.
`_BoundaryEditor` 는 기존 `part of` 구조 유지하며 build 메서드만 재구성.

---

## 8. 구현 순서

1. `qr_border_style.dart` — enum 생성
2. `qr_boundary_params.dart` — 4개 필드 추가 + copyWith/toJson/fromJson/==/hashCode
3. `boundary_editor.dart` — UI 재설계 (드롭다운 + 선 종류 + 색상 버튼 + 패턴 색상)
4. `decorative_frame_painter.dart` — 외곽선 stroke 렌더링
5. `qr_layer_stack.dart` — patternColor 로직 변경
6. `qr_svg_generator.dart` — SVG 외곽선 렌더링
7. `app_ko.arb` — l10n 키 추가
8. `flutter analyze --no-pub` 검증

---

## 9. 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| borderStyle=none 일 때 | 외곽선 비표시, 색상/두께 UI 숨김 |
| type=square (비프레임) | 외곽선 의미 없음 — 선 종류/색 UI 숨김 |
| patternColorArgb=null | 기존 자동 계산 로직 유지 |
| 기존 저장 데이터에 신규 필드 없음 | fromJson 에서 기본값 할당 (solid, 0xFF000000, 2.0, null) |
| double_ 이중선 + 복잡한 shape (star) | 내부 path를 약간 축소한 버전으로 렌더 |
| 색상 피커 UX | 기존 색상 탭에서 사용하는 ColorPicker 위젯 재사용 |
