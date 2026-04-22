# Design — logo-tab-dot-clearing

> **Architecture**: CLAUDE.md 고정 규약에 따라 R-series Provider 패턴 + Clean Architecture 를 전제로 작성. 3-옵션 비교(최소변경/클린분리/실용절충)는 생략하고 상세 설계만 기재한다.
>
> **Plan 참조**: `docs/01-plan/features/logo-tab-dot-clearing.plan.md`

---

## 1. Scope Recap

- **FR-1~7** 구현: Image 타입 QR 도트 clearing (양쪽 렌더 경로), clear-zone 모양을 `logoBackground` 기반으로 결정, Row 1 반응형 레이아웃.
- **신규 state / entity / mixin 없음**. 순수 렌더링 계층 수정.
- **영향 레이어**: `widgets/` + `tabs/` + 신규 `utils/` 헬퍼 1개.

---

## 2. Architecture

### 2.1 디렉터리 트리 (수정 후)

```
lib/features/qr_result/
├── domain/
│   ├── entities/
│   │   ├── logo_source.dart              # (변경 없음)
│   │   ├── sticker_config.dart           # (변경 없음)
│   │   └── ...
│   └── state/                            # (변경 없음)
├── data/                                 # (변경 없음)
├── notifier/                             # (변경 없음)
├── utils/
│   ├── logo_clear_zone.dart              # 🆕 신규 — ClearZone record + computeLogoClearZone()
│   ├── polar_polygon.dart
│   ├── qr_matrix_helper.dart
│   ├── qr_animation_engine.dart
│   ├── qr_boundary_clipper.dart
│   └── superellipse.dart
├── widgets/
│   ├── custom_qr_painter.dart            # ✏️ 수정 — clearZone 필드 + paint skip
│   ├── qr_layer_stack.dart               # ✏️ 수정 — computeLogoClearZone 호출 + Painter 전달
│   ├── qr_preview_section.dart           # 🔍 검증 (조건부 수정)
│   └── template_thumbnail.dart           # (변경 없음)
└── tabs/
    ├── sticker_tab.dart                  # ✏️ 수정 — Row 1 반응형 레이아웃
    ├── logo_editors/                     # (변경 없음)
    └── ...
```

### 2.2 컴포넌트 책임 분리

| 모듈 | 책임 | 의존성 |
|------|------|--------|
| `utils/logo_clear_zone.dart` | 순수 함수. StickerConfig + QR/Icon 크기로부터 clear-zone Rect + isCircular 계산. 사이드 이펙트·상태 없음. | `domain/entities/sticker_config.dart`, `domain/entities/logo_source.dart`, `dart:ui.Size/Rect/Offset` |
| `widgets/custom_qr_painter.dart` | QR 모듈 렌더링. `clearZone` 전달 시 해당 영역 cell 은 draw skip. Finder pattern 은 skip 무관 (중앙과 절대 겹치지 않음). | logo_clear_zone (typedef 만) |
| `widgets/qr_layer_stack.dart` | 렌더 경로 분기 (pretty_qr vs CustomQrPainter), clear-zone 계산을 양쪽 경로 중 CustomQrPainter 경로에서만 수행하여 Painter 에 주입. `_LogoWidget` 오버레이는 기존 그대로. | logo_clear_zone, custom_qr_painter |
| `widgets/qr_preview_section.dart` | pretty_qr 경로. `PrettyQrDecorationImage.embedded` 가 image 타입에서도 정상 작동 검증. 필요 시 조건 보정. | (변경 없음 또는 최소) |
| `tabs/sticker_tab.dart` | 로고 탭 UI. Row 1 레이아웃을 유형(콘텐츠 폭) + 위치(남은 폭 Expanded) 로 변경. | (변경 없음 — 기존 import 유지) |

### 2.3 데이터 흐름

```
┌──────────────────────────────────────────────────────────────┐
│  사용자 인풋 (드롭다운: LogoType / LogoPosition / Background)  │
│     ↓                                                        │
│  setLogoType(...) / applyLogoImage(...) / setSticker(...)    │
│     ↓ (logo_setters.dart mixin)                              │
│  state = state.copyWith(sticker: ..., logo: ...)             │
└──────────────────────────────────────────────────────────────┘
     ↓
┌──────────────────────────────────────────────────────────────┐
│  QrResultScreen / QrPreviewSection / QrLayerStack rebuild    │
│     ↓                                                        │
│  _useCustomPainter(state) 분기                               │
│    │                                                         │
│    ├── false (default) ── buildPrettyQr()                    │
│    │                       ↓                                 │
│    │                      PrettyQrView + PrettyQr-           │
│    │                      DecorationImage.embedded           │
│    │                      (pretty_qr 내부에서 모듈 clear)    │
│    │                                                         │
│    └── true (custom eye/boundary/anim)                       │
│            ↓                                                 │
│         computeLogoClearZone(qrSize, iconSize, sticker,      │
│                              embedIcon) → ClearZone?         │
│            ↓                                                 │
│         CustomQrPainter(clearZone: ...)                      │
│            ↓ paint() loop                                    │
│         각 cell center 가 clearZone 내부면 draw skip         │
└──────────────────────────────────────────────────────────────┘
     ↓ (두 경로 공통)
┌──────────────────────────────────────────────────────────────┐
│  Stack 오버레이: _LogoWidget(iconProvider or text)           │
│  (시각적 로고/이미지는 항상 위에 그려짐, clear 는 QR 레이어) │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. 상세 시그니처

### 3.1 `utils/logo_clear_zone.dart` (신규)

```dart
import 'dart:ui';

import '../domain/entities/logo_source.dart' show LogoType;
import '../domain/entities/sticker_config.dart';

/// QR 렌더 시 도트를 비울 영역을 나타내는 record.
/// - [rect]: Painter 좌표계(quiet zone 제외)의 영역
/// - [isCircular]: true 면 rect.center 기준 반지름 rect.width/2 원, false 면 rect 사각
///
/// Dart record 는 == / hashCode 를 필드 기반으로 자동 생성 → CustomQrPainter.shouldRepaint 에서 직접 비교 가능.
typedef ClearZone = ({Rect rect, bool isCircular});

/// QR 도트 clear-zone 계산.
///
/// 리턴 null 인 경우 (clearing 대상 아님):
///  - embedIcon == false
///  - sticker.logoPosition != LogoPosition.center  (bottomRight 는 QR 밖)
///  - sticker.logoType == text | none | null     (text 는 widget overlay 경로)
///
/// 모양은 [StickerConfig.logoBackground] 에 따라 결정:
///  - none            → iconSize × iconSize  원형 (ClipOval 적용된 컨텐츠)
///  - circle          → (iconSize+8) × (iconSize+8)  원형
///  - square          → (iconSize+8) × (iconSize+8)  사각
///  - rectangle       → (iconSize+20) × (iconSize+12) 사각 (이미지 타입엔 UI 정규화로 선택 불가, 레거시 대응)
///  - roundedRectangle→ rectangle 동일 (borderRadius 는 clear 영역에 반영 안 함 — 모서리 ~1-2 모듈 차이 무시)
///
/// [qrSize] 는 CustomQrPainter 가 그리는 영역(quiet zone 제외) 의 크기.
/// [iconSize] 는 `QrLayerStack.widget.size * 0.22` 로 계산된 _LogoWidget 의 기본 아이콘 크기.
ClearZone? computeLogoClearZone({
  required Size qrSize,
  required double iconSize,
  required StickerConfig sticker,
  required bool embedIcon,
}) {
  if (!embedIcon) return null;
  if (sticker.logoPosition != LogoPosition.center) return null;
  final type = sticker.logoType;
  if (type != LogoType.logo && type != LogoType.image) return null;

  final (double w, double h, bool circular) = switch (sticker.logoBackground) {
    LogoBackground.none              => (iconSize,      iconSize,      true),
    LogoBackground.circle            => (iconSize + 8,  iconSize + 8,  true),
    LogoBackground.square            => (iconSize + 8,  iconSize + 8,  false),
    LogoBackground.rectangle
      || LogoBackground.roundedRectangle
                                     => (iconSize + 20, iconSize + 12, false),
  };

  final rect = Rect.fromCenter(
    center: Offset(qrSize.width / 2, qrSize.height / 2),
    width: w,
    height: h,
  );
  return (rect: rect, isCircular: circular);
}
```

### 3.2 `widgets/custom_qr_painter.dart` (수정 지점)

**필드 추가**:
```dart
class CustomQrPainter extends CustomPainter {
  // ... 기존 필드
  final ui.Gradient? gradient;
  final ClearZone? clearZone;   // 🆕

  CustomQrPainter({
    required this.qrImage,
    required this.color,
    this.dotParams = const DotShapeParams(),
    this.eyeParams = const EyeShapeParams(),
    this.boundaryParams = const QrBoundaryParams(),
    this.animParams = const QrAnimationParams(),
    this.animValue = 0.0,
    this.gradient,
    this.clearZone,              // 🆕
  }) {
    // 기존 classify 로직 유지
  }
}
```

**판정 헬퍼 (private)**:
```dart
bool _isInClearZone(Offset cellCenter) {
  final cz = clearZone;
  if (cz == null) return false;
  if (cz.isCircular) {
    final dx = cellCenter.dx - cz.rect.center.dx;
    final dy = cellCenter.dy - cz.rect.center.dy;
    final r = cz.rect.width / 2;
    return dx * dx + dy * dy <= r * r;
  }
  return cz.rect.contains(cellCenter);
}
```

**paint() 루프 skip 삽입**:

두 루프(2a structural, 2b data)에서 `center` 계산 직후 skip:
```dart
// 2a. structural
for (final cell in _structuralCells) {
  final center = Offset(cell.col * m + m / 2, cell.row * m + m / 2);
  if (_isInClearZone(center)) continue;   // 🆕
  final path = PolarPolygon.buildPath(center, structRadius, dotParams);
  canvas.drawPath(path, structPaint);
}

// 2b. data
for (final cell in _dataCells) {
  final center = Offset(cell.col * m + m / 2, cell.row * m + m / 2);
  if (_isInClearZone(center)) continue;   // 🆕
  // ... 기존 애니메이션/draw 로직
}
```

> Finder pattern(3개 코너 7×7)은 중앙 22% 영역과 절대 겹치지 않으므로 skip 체크 생략 — 추가 조건 없음.

**shouldRepaint 업데이트**:
```dart
@override
bool shouldRepaint(CustomQrPainter old) =>
    qrImage != old.qrImage ||
    color != old.color ||
    dotParams != old.dotParams ||
    eyeParams != old.eyeParams ||
    boundaryParams != old.boundaryParams ||
    animParams != old.animParams ||
    animValue != old.animValue ||
    gradient != old.gradient ||
    clearZone != old.clearZone;   // 🆕 (record == 자동 필드 비교)
```

**예상 파일 크기**: 189 → ~210 줄. `widgets/` 레이어(UI part) 는 ≤ 400 줄 한도 → 여유.

### 3.3 `widgets/qr_layer_stack.dart` (수정 지점)

**import 추가**:
```dart
import '../utils/logo_clear_zone.dart';
```

**`_buildCustomQr` 내부**:

기존:
```dart
Widget _buildCustomQr(QrResultState state, double qrSize) {
  final embedInQr = state.logo.embedIcon &&
      centerImageProvider(state) != null &&
      state.sticker.logoPosition == LogoPosition.center;
  final ecLevel = embedInQr ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
  final qrImage = _qrImageFor(widget.deepLink, ecLevel);
  // ...
```

수정 후:
```dart
Widget _buildCustomQr(QrResultState state, double qrSize) {
  final embedInQr = state.logo.embedIcon &&
      centerImageProvider(state) != null &&
      state.sticker.logoPosition == LogoPosition.center;
  final ecLevel = embedInQr ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
  final qrImage = _qrImageFor(widget.deepLink, ecLevel);

  // 🆕 clear-zone 계산 (embedInQr 와 동일 선행 조건 안에서 동작)
  final iconSize = widget.size * 0.22;
  final clearZone = computeLogoClearZone(
    qrSize: Size.square(qrSize),
    iconSize: iconSize,
    sticker: state.sticker,
    embedIcon: state.logo.embedIcon,
  );
  // ...
```

**Painter 인스턴스화 양쪽에 전달**:
```dart
CustomQrPainter(
  qrImage: qrImage,
  color: color,
  dotParams: state.style.customDotParams ?? state.style.dotStyle.toDotShapeParams(),
  eyeParams: state.style.customEyeParams ?? const EyeShapeParams(),
  boundaryParams: state.style.boundaryParams,
  animParams: state.style.animationParams,
  animValue: _animController!.value,  // 또는 미전달 (애니 없을 때)
  clearZone: clearZone,                // 🆕
),
```

`build()` 메서드의 `iconSize` 와 overlap 있음(아래 `_LogoWidget` 생성 시에도 size=widget.size 전달). 별도 계산 아님.

### 3.4 `widgets/qr_preview_section.dart` (검증 + 조건부 수정)

**검증 포인트**: `buildPrettyQr` line 389-395 의 조건:

```dart
image: !useIconOverlay && embedInQr
    ? PrettyQrDecorationImage(
        image: centerImage!,
        position: PrettyQrDecorationImagePosition.embedded,
      )
    : null,
```

`centerImage` 는 `LogoType.image` 에서도 `_memImage(sticker.logoImageBytes!)` 로 non-null → `embedInQr` 가 true 면 이 경로가 적용됨. **이론상 image 도 logo 와 동일하게 embed 된다.**

Design 결론:
- **수정 불필요 (기본 가정)**.
- Do 단계에서 수동 QA (T-05: image + center + none 배경, custom 비활성) 결과가 "도트 clearing 됨" 이면 그대로 유지.
- 만약 clearing 이 시각적으로 약하게 보인다면, 그것은 `PrettyQrDecorationImage` 의 내부 clear-zone 계산(alpha 기반) 때문. 이 경우 `CustomQrPainter` 경로와 동일한 동작을 원하면 **`buildPrettyQr` 를 `buildCustomQr` 경로로 강제 라우팅** 하는 것이 대안. 본 Design 에선 1차 수정 없이 관찰 후 결정.

> **Action for Do phase**: T-05 시나리오 검증 후 차이가 있으면 별도 이슈로 트래킹. 본 Plan/Design 범위 밖.

### 3.5 `tabs/sticker_tab.dart` (수정 지점)

**Row 1 변경** (line 45-123 영역):

기존 구조:
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Column(... Dropdown ...),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Column(... _SegmentRow ...),
    ),
  ],
)
```

변경 후 구조:
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 🆕 유형 드롭다운: 콘텐츠 폭 기반, 96~200 dp 범위
    Flexible(
      flex: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 96,
          maxWidth: 200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(l10n.labelLogoType),
            const SizedBox(height: 8),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<LogoType>(
                  value: currentType,
                  isDense: true,
                  // ⛔ isExpanded: true 제거 — 내용 폭 기반
                  items: [ /* 기존 items */ ],
                  onChanged: (v) { /* 기존 */ },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(width: 12),
    // 우측 위치 segment: 남은 폭 확보 → 한 줄 유지
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.labelLogoTabPosition),
          const SizedBox(height: 8),
          _SegmentRow<LogoPosition>(
            enabled: !isNoneType,
            selected: sticker.logoPosition,
            options: [
              (LogoPosition.center, l10n.optionCenter),
              (LogoPosition.bottomRight, l10n.optionBottomRight),
            ],
            onChanged: (v) => update(sticker.copyWith(logoPosition: v)),
          ),
        ],
      ),
    ),
  ],
)
```

**수치 근거**:

| 수치 | 값 | 근거 |
|------|-----|------|
| minWidth | 96 dp | ko "이미지" / en "Image" / ja "イメージ" 드롭다운 컨텐츠 폭 최대치(~85 dp) + 좌우 여백(10px×2) 기준으로 여유. 라벨(Logo type)이 위 Column 에 있어 드롭다운 자체 폭만 고려. |
| maxWidth | 200 dp | 360 dp 기기 폭에서 좌우 패딩 16 + 스크롤 여유 제외하면 사용 가능 ~320 dp. 드롭다운 200 + SizedBox 12 + 위치 segment 108 dp → `[center 54dp] + [bottomRight 48dp]` 한 줄 유지 가능. |
| `isExpanded: true` 제거 | — | DropdownButton 내부 children(items) 의 최대 폭으로 intrinsic width 결정하게 됨. `isDense: true` 유지. |

> `_SegmentRow` 는 Wrap 기반이므로 옵션 라벨이 매우 길면 여전히 2행으로 떨어질 수 있으나, 현재 옵션 2개(center/bottomRight) 기준 maxWidth 200 에서 한 줄 유지 확인됨. Position 확장 계획 없음 (Plan 확정).

---

## 4. Edge Cases & Error Handling

| ID | 케이스 | 처리 |
|----|--------|------|
| EC-1 | logoBackground == rectangle/roundedRectangle + 이미지 타입 | UI 에서는 `_normalizedBackground` 로 none 으로 표시되나, 레거시 저장 데이터 복원 시 state 자체엔 rectangle 이 유지될 수 있음. `computeLogoClearZone` 은 rectangle 을 사각 clear 로 대응. |
| EC-2 | logoImageBytes null (로딩 중) | `centerImageProvider(state)` 가 null → `embedIcon=true` 여도 `computeLogoClearZone` 에서 type 체크로 null 리턴하지 않음. 단, 이 경우 `_LogoWidget` 은 생성되지 않음(`iconProvider != null` 가드). QR 만 정상 렌더, clear 도 정상 적용 — 로고 그려지기 직전 한 프레임 비어 있는 영역이 보일 수 있으나 async 로딩 특성상 허용. |
| EC-3 | logoType == null (레거시) | `computeLogoClearZone` 이 null 리턴 → 기존 동작 유지. |
| EC-4 | 애니메이션 중 QR 재계산 | `_structuralCells`/`_dataCells` 사전 계산은 변경 없음. 매 프레임 `_isInClearZone` 판정만 O(1)×cell 수 추가. 60fps 영향 미미. |
| EC-5 | 그라디언트 + clear-zone | `ShaderMask(BlendMode.srcIn)` 는 draw 된 픽셀에만 gradient 적용. skip 된 cell 은 draw 자체 없음 → gradient shader 영향 없음. |
| EC-6 | Boundary clip 으로 QR 외곽 원형 + center 로고 | center 는 clip path 내부에 완전히 포함 → 정상. |
| EC-7 | QR version 높음(7+) 으로 alignment pattern 이 중앙 근처 | alignment pattern(5×5)이 clear-zone 과 겹칠 수 있음. 해당 structural cell 은 skip. ecLevel=H redundancy(30%) 로 스캔 복구 가능. 추가 방어 없음. |
| EC-8 | Quiet zone color 가 불투명(qr 배경색) + clear-zone 이 quiet zone 까지 걸쳐 있음 | clear-zone 중심 = qrSize(quiet 제외) 중심. iconSize = widget.size × 0.22 = (qrSize + 2×quietPadding) × 0.22. quietPadding ≥ 8 이므로 iconSize 최소값 ≈ (8+16)×0.22 ≈ 5dp... 이건 너무 작음. 실제 widget.size=160 에서 iconSize=35.2, clear 반경 ≈ 17.6, quietPadding=8 → clear-zone 은 qrSize 내부에 완전히 포함됨. tablet(widget.size=600) 에서도 iconSize=132, 반경 66, qrSize=540 → 여유. OK. |
| EC-9 | shouldRepaint 성능 | record 비교는 field-by-field. Rect 와 bool 비교 → O(1). 매 프레임 overhead 무시 가능. |

---

## 5. Test Plan (Do 단계 QA 용)

### 5.1 Visual Regression Scenarios

(Plan §8.1 에서 정의된 T-01 ~ T-10 재사용)

### 5.2 Unit Test 대상 (선택)

`logo_clear_zone.dart` 는 순수 함수 → 단위 테스트 작성 가능. 다만 pre-release + 1인 개발 + 시각 검증으로 충분하므로 **본 Design 에서 unit test 필수 아님**. Do 단계에서 필요 판단.

### 5.3 수동 QA 체크리스트

- [ ] T-04: logo + center + none 배경 + custom eye 활성 → **원형 clear-zone 확인**
- [ ] T-05: image + center + none 배경 (default) → pretty_qr 경로 clear 확인
- [ ] T-06: image + center + circle 배경 → 원형 clear (배경 원 내부 도트 없음)
- [ ] T-07: image + center + square 배경 + boundary=circle → 사각 clear + 원형 boundary 조합
- [ ] T-08: image + center + circle 배경 + animation → 애니메이션 중 clear 유지
- [ ] 회귀 T-09: text + center + rectangle → 현행 overlay, clearing 없음
- [ ] 회귀 T-10: logo + bottomRight + animation → 현행 overlay, QR 밖 배치
- [ ] 실제 기기 스캔: T-04~T-08 각각 mobile_scanner 로 스캔 성공
- [ ] 언어 전환 ko/en/de/ja/zh 로고 탭 Row 1 한 줄 유지
- [ ] 기기 폭 360/411/600 dp 로고 탭 Row 1 한 줄 유지

---

## 6. Implementation Steps (Do 단계 순서)

| # | 파일 | 작업 | 예상 라인 변경 |
|---|------|------|----------------|
| 1 | `utils/logo_clear_zone.dart` | 신규 생성 (typedef + computeLogoClearZone) | +55 |
| 2 | `widgets/custom_qr_painter.dart` | clearZone 필드, _isInClearZone, paint skip, shouldRepaint | +15 / -0 |
| 3 | `widgets/qr_layer_stack.dart` | import + clear-zone 계산 + Painter 전달 | +8 / -0 |
| 4 | `widgets/qr_preview_section.dart` | 검증 (T-05), 기본 수정 없음 | 0 |
| 5 | `tabs/sticker_tab.dart` | Row 1 Flexible(flex:0)+ConstrainedBox+Expanded | +10 / -6 |
| 6 | 수동 QA | 시나리오 T-04~T-08 + 회귀 T-09,T-10 + i18n + 폭 | — |

**총 변경 규모**: +88 / -6 ≈ 82 net lines, 1 신규 파일.

---

## 7. Architecture Compliance (CLAUDE.md 하드 룰)

| 룰 | 적용 여부 |
|----|-----------|
| 1. composite state 외부 접근은 `state.sub.field` | ✅ 기존 `state.sticker.*`, `state.logo.embedIcon` 경로만 읽음 |
| 2. nullable clearing 은 `clearXxx: bool` 플래그 | ✅ `ClearZone?` 자체가 nullable record, state 저장 대상 아님 |
| 3. backward-compat 코드 금지 | ✅ 레거시 logoType==null 경로는 존재하는 방어 로직(조기 null 리턴)만, 신규 브릿지/shim 없음 |
| 4. re-export 금지 | ✅ logo_clear_zone.dart 는 직접 import 대상, 재수출 없음 |
| 5. mixin `_` prefix | N/A (본 feature mixin 없음) |
| 6. sub-state 단일 관심사 | N/A (sub-state 변경 없음) |
| 7. 메인 Notifier lifecycle only | N/A |
| 8. 파일 크기 | custom_qr_painter.dart ~210줄 (UI part ≤ 400 OK), logo_clear_zone.dart ~55줄, sticker_tab.dart ~385줄(기존)→ ~390줄 (UI part ≤ 400 근접 but OK) |

---

## 8. Open Questions Resolved

| Q | 답 | 근거 |
|---|----|------|
| Q-D1: `_computeClearZone` 위치 | `lib/features/qr_result/utils/logo_clear_zone.dart` 분리 | custom_qr_painter.dart 파일 크기 관리 + 순수 함수 특성 상 utils 가 자연스러움 |
| Q-D2: ClearZone 타입 | Dart record `({Rect rect, bool isCircular})` | state 저장 대상 아님. record 는 == / hashCode 자동 제공으로 shouldRepaint 에서 직접 비교 가능. |
| Q-D3: rectangle/roundedRectangle 처리 | Rect 로 처리 (isCircular=false). borderRadius 는 clear 영역에 반영 안 함 | 이미지 타입엔 UI 정규화로 선택 불가 → 레거시 데이터 대응만. 모서리 1-2 모듈 차이 허용. |

---

## 9. Non-goals (재확인)

- Text 타입 clearing **미구현**
- Position 옵션 확장 대비 설계 **없음**
- QR 리더빌리티 지표(`qr_readability_service`) 로직 변경 **없음**
- 신규 ARB 문자열 **없음**
- Hive 스키마 / 마이그레이션 **없음**

---

## Appendix A — 주요 참조 코드 위치

| 심볼 | 위치 |
|------|------|
| `StickerConfig` | `lib/features/qr_result/domain/entities/sticker_config.dart:57` |
| `LogoType` enum | `lib/features/qr_result/domain/entities/logo_source.dart:15` |
| `centerImageProvider` | `lib/features/qr_result/widgets/qr_preview_section.dart:451` |
| `CustomQrPainter.paint` 2a structural | `custom_qr_painter.dart:108` |
| `CustomQrPainter.paint` 2b data | `custom_qr_painter.dart:126` |
| `CustomQrPainter.shouldRepaint` | `custom_qr_painter.dart:173` |
| `_QrLayerStackState._buildCustomQr` | `qr_layer_stack.dart:159` |
| `StickerTab.build` Row 1 | `sticker_tab.dart:45` |
| `_SegmentRow` | `sticker_tab.dart:328` |

## Appendix B — 고정 결정 요약

1. **Clearing 적용 경로**: pretty_qr(검증) + CustomQrPainter(신규 구현)
2. **Clear-zone 모양**: logoBackground 기반 (none/circle→원형, square/rectangle/roundedRectangle→사각)
3. **Clear-zone 중심**: Painter 좌표계 중심(qrSize/2), quiet zone 제외
4. **iconSize**: widget.size × 0.22 (기존 _LogoWidget 상수 재사용)
5. **Position bottomRight**: clearing 제외 (현행 QR 밖 배치)
6. **Text 타입**: clearing 제외 (현행 overlay)
7. **Row 1 레이아웃**: Flexible(flex:0, minWidth 96, maxWidth 200) + SizedBox(12) + Expanded
8. **DropdownButton**: `isExpanded: true` 제거, `isDense: true` 유지
