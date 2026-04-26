# logo-text-unification Design Document

> **Summary**: 독립 텍스트 탭 제거 + 로고 유형="텍스트" 시 상단/중앙/하단 통합 편집기 + 중앙 "띠(band)" 모드 설계
>
> **Project**: app_tag
> **Author**: Claude
> **Date**: 2026-04-26
> **Status**: Draft
> **Planning Doc**: [logo-text-unification.plan.md](../../01-plan/features/logo-text-unification.plan.md)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | "텍스트" 탭과 로고 유형 "텍스트"가 공존하여 사용자 혼란. 상/하단 텍스트가 QR 밖에 배치되고, 중앙 텍스트가 QR 도트를 가림 |
| **Solution** | TextTab 제거 → 로고 유형="텍스트" 시 3-position 편집기 통합 + "띠" 모드로 QR 행 clearing |
| **Function/UX Effect** | 6탭→5탭 단순화, 텍스트 한 곳 관리, QR 내부 렌더링, 스캔 안정적 중앙 텍스트 |
| **Core Value** | 직관적 텍스트 편집 UX + QR 스캔 안정성 확보 |

---

## 1. Overview

### 1.1 Design Goals

1. 텍스트 관련 모든 편집을 로고 탭 하나로 통합
2. 상/하단 텍스트를 QR 코드 레이어 내부에 렌더링
3. 중앙 텍스트 "띠" 모드로 QR 도트 행을 안전하게 clearing
4. 텍스트 유형에서 불필요한 "우하단" 위치 제거

### 1.2 Design Principles

- 기존 logo/image 유형의 동작을 변경하지 않음 (영향 범위 최소화)
- StickerConfig 필드 추가는 기본값으로 기존 데이터 호환 보장
- 텍스트 편집 위젯(`_TextEditor`)을 재활용하여 코드 중복 최소화

---

## 2. Architecture

### 2.1 디렉터리 변경 트리

```
lib/features/qr_result/
├── qr_result_screen.dart                  # [수정] 6탭→5탭
├── tabs/
│   ├── sticker_tab.dart                   # [수정] 텍스트 유형 시 위치 제한
│   ├── text_tab.dart                      # [삭제]
│   └── logo_editors/
│       ├── logo_text_editor.dart          # [삭제]
│       └── logo_text_unified_editor.dart  # [신규] 상단/중앙/하단 통합 편집기
├── domain/entities/
│   └── sticker_config.dart                # [수정] centerTextBand 필드 추가
├── utils/
│   └── logo_clear_zone.dart               # [수정] band ClearZone 함수 추가
├── widgets/
│   ├── qr_layer_stack.dart                # [수정] 텍스트 QR 내부 렌더링 + band
│   └── custom_qr_painter.dart             # [수정] bandClearZone 파라미터 추가
├── notifier/
│   └── logo_setters.dart                  # [수정] setCenterTextBand 추가
└── data/
    └── (qr_task 쪽)
        ├── sticker_spec.dart              # [수정] centerTextBand 직렬화
        └── customization_mapper.dart      # [수정] centerTextBand 매핑
```

### 2.2 Data Flow

```
[사용자] 로고 탭 → 유형="텍스트" 선택
  → StickerTab: IndexedStack index=2 → LogoTextUnifiedEditor 표시
    ├── 상단 텍스트 입력 → notifier.setSticker(sticker.copyWith(topText: ...))
    ├── 중앙 텍스트 입력 → notifier.applyLogoText(text)
    ├── "띠" 토글 → notifier.setCenterTextBand(bool)
    └── 하단 텍스트 입력 → notifier.setSticker(sticker.copyWith(bottomText: ...))

[렌더링] QrLayerStack.build()
  ├── _buildNormalLayout():
  │   └── Stack(size×size):
  │       ├── 배경(quietZoneColor) + QR 도트
  │       ├── 상단 텍스트 Positioned(top: quietPadding-offset)
  │       ├── 중앙 텍스트 (band 배경 + 텍스트)
  │       └���─ 하단 텍스트 Positioned(bottom: quietPadding-offset)
  │
  └── _buildFrameLayout():
      └── Stack(totalSize):
          ├── 프레임 + QR(qrAreaSize)
          ├── 상단 텍스트 (QR 영역 내 상단)
          ├── 중앙 텍스트 (band)
          └── 하단 텍스트 (QR 영역 내 하단)

[CustomQrPainter] clearZone + bandClearZone → 해당 셀 skip
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| LogoTextUnifiedEditor | StickerConfig, StickerText, qrResultProvider | 텍스트 편집 상태 관리 |
| QrLayerStack | StickerConfig.centerTextBand | band 렌더링 판단 |
| CustomQrPainter | ClearZone (band) | QR 도트 행 clearing |
| customization_mapper | StickerSpec.centerTextBand | 직렬화/역직렬화 |

---

## 3. Data Model

### 3.1 StickerConfig 변경

```dart
// domain/entities/sticker_config.dart
class StickerConfig {
  // 기존 필드 모두 유지
  final LogoPosition logoPosition;
  final LogoBackground logoBackground;
  final StickerText? topText;
  final StickerText? bottomText;
  final LogoType? logoType;
  final String? logoAssetId;
  final Uint8List? logoImageBytes;
  final StickerText? logoText;
  final Uint8List? logoAssetPngBytes;
  final Color? logoBackgroundColor;

  // [신규]
  final bool centerTextBand;  // 중앙 텍스트 "띠" 모드

  const StickerConfig({
    // ...기존...
    this.centerTextBand = false,  // 기본값 false → 기존 데이터 호환
  });

  // copyWith 에 centerTextBand 추가
  StickerConfig copyWith({
    // ...기존...
    bool? centerTextBand,
  }) => StickerConfig(
    // ...기존...
    centerTextBand: centerTextBand ?? this.centerTextBand,
  );
}
```

### 3.2 StickerSpec 직렬화 변경

```dart
// qr_task/domain/entities/sticker_spec.dart
class StickerSpec {
  // 기존 필드 유지
  final bool centerTextBand;  // [신규]

  const StickerSpec({
    // ...기존...
    this.centerTextBand = false,
  });

  Map<String, dynamic> toJson() => {
    // ...기존...
    if (centerTextBand) 'centerTextBand': true,
  };

  factory StickerSpec.fromJson(Map<String, dynamic> json) => StickerSpec(
    // ...기존...
    centerTextBand: json['centerTextBand'] as bool? ?? false,
  );
}
```

### 3.3 CustomizationMapper 변경

```dart
// utils/customization_mapper.dart
static StickerConfig stickerFromSpec(StickerSpec spec) {
  return StickerConfig(
    // ...기존...
    centerTextBand: spec.centerTextBand,  // [추가]
  );
}

static StickerSpec _stickerToSpec(StickerConfig s) {
  return StickerSpec(
    // ...기존...
    centerTextBand: s.centerTextBand,  // [추가]
  );
}
```

---

## 4. ClearZone 확장: Band 모드

### 4.1 logo_clear_zone.dart 변경

기존 `computeLogoClearZone()`은 그대로 유지. 새로운 `computeBandClearZone()` 함수를 추가.

```dart
/// 중앙 텍스트 "띠(band)" 모드용 가로 스트립 ClearZone 계산.
///
/// centerTextBand == true 이고 logoText 가 비어있지 않을 때만 호출.
/// QR 수직 중앙에 텍스트 높이만큼의 가로 전폭 스트립을 반환.
///
/// [qrSize]: CustomQrPainter 가 그리는 영역(quiet zone 제외) 크기.
/// [fontSize]: logoText.fontSize * scale (미리보기 크기 비례).
ClearZone? computeBandClearZone({
  required Size qrSize,
  required double fontSize,
}) {
  // 텍스트 행 높이 = fontSize * 1.4 (line height + 상하 여유)
  final bandHeight = fontSize * 1.4;
  final rect = Rect.fromCenter(
    center: Offset(qrSize.width / 2, qrSize.height / 2),
    width: qrSize.width,       // 전체 가로
    height: bandHeight,
  );
  return (rect: rect, isCircular: false);
}
```

### 4.2 CustomQrPainter ��경

```dart
class CustomQrPainter extends CustomPainter {
  // 기존 필드
  final ClearZone? clearZone;
  final ClearZone? bandClearZone;  // [신규] 띠 모드용

  CustomQrPainter({
    // ...기존...
    this.bandClearZone,
  });

  bool _isInClearZone(Offset cellCenter) {
    final cz = clearZone;
    if (cz != null) {
      if (cz.isCircular) {
        final dx = cellCenter.dx - cz.rect.center.dx;
        final dy = cellCenter.dy - cz.rect.center.dy;
        final r = cz.rect.width / 2;
        if (dx * dx + dy * dy <= r * r) return true;
      } else {
        if (cz.rect.contains(cellCenter)) return true;
      }
    }
    // [추가] band ClearZone 체크
    final bz = bandClearZone;
    if (bz != null && bz.rect.contains(cellCenter)) return true;
    return false;
  }

  @override
  bool shouldRepaint(CustomQrPainter old) =>
      // ...기존...
      clearZone != old.clearZone ||
      bandClearZone != old.bandClearZone;
}
```

### 4.3 Band 모드 시 Error Correction 강제

```dart
// QrLayerStack 내부
// band 모드 활성 시 ecLevel = H 강제 (기존 logo embed 로직과 동일 패턴)
final hasBand = sticker.centerTextBand &&
    sticker.logoText != null &&
    !sticker.logoText!.isEmpty;
final embedInQr = state.logo.embedIcon && ...;
final ecLevel = (embedInQr || hasBand)
    ? QrErrorCorrectLevel.H
    : QrErrorCorrectLevel.M;
```

---

## 5. UI/UX Design

### 5.1 탭 구조 변경

**Before (6탭)**:
```
[템플릿] [모양] [배경] [색상] [로고] [텍스트]
```

**After (5���)**:
```
[템플릿] [모양] [배경] [색상] [로고]
```

### 5.2 로고 탭: 유형="텍스트" 선택 시 UI

```
┌─────────────────────────────────────────┐
│ 유형: [텍스트 ▾]    위치: [중앙]          │
├─────────────────────────────────────────┤
│ 배경: [없음] [사각] [원형]   색상: ●       │
├─────────────────────────────────────────┤
│ ─── 상단 텍스트 ───────────────────────  │
│ [________________] 색상●  Sans▾  14sp   │
│                                         │
│ ─── 중앙 텍스트 ───────────────────────  │
│ [________________] 색상●  Sans▾  20sp   │
│ □ 띠(Band) 모드                          │
│                                         │
│ ─── 하단 텍스트 ───────────────────────  │
│ [________________] 색상●  Sans▾  14sp   │
└���────────────────────────────────────────┘
```

**위치 옵션**: 텍스트 유형일 때 `[중앙]`만 표시 (우하단 제거).

### 5.3 QR 미리보기: 텍스트 렌더링 위치

**일반 모드** (경계 없음):
```
┌──────────────────────┐
│ ┌──────────────────┐ │ ← quiet zone
│ │  상단 텍스트       │ │ ← QR 레이어 내 상단
│ │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│ │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│ │  ▓▓▓ BAND ▓▓▓▓▓  │ │ ← 띠 모드: QR 도트 clearing + 텍스트
│ ���  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│ │  ▓▓▓▓▓▓▓▓��▓▓▓▓▓  │ │
│ │  하단 텍스트       │ │ ← QR 레이어 내 하단
│ └──────────────────┘ │
└──────────────────────┘
```

**프레임 모드** (외곽 프레임):
```
┌──────────────────────────┐
│  ░░░░░ 프레임 패턴 ░░░░░   │
│  ░░┌──────────────┐░░░   │
│  ░░│ 상단 텍스트    │░░░   │ ← QR 영역 내부
│  ░░│ ▓▓▓▓▓▓▓▓▓▓▓▓ │░░░   │
│  ░░│ ▓▓ BAND ▓▓▓▓ │░░░   │
│  ░░│ ���▓▓▓▓▓▓▓▓▓▓▓ │░░░   │
│  ░░│ 하단 텍스트    │░░░   │
│  ░░└──────────────┘░░░   │
│  ░░░░░░░░░░░░░░░░░░░░░   │
└──────────────────────────┘
```

### 5.4 중앙 텍스트 Auto-Sizing

텍스트가 QR 폭의 80%를 초과하면 fontSize를 자동 축소:

```dart
// QrLayerStack 내부 band 텍스트 렌더링
Widget _buildBandText(StickerText text, double qrSize, double scale) {
  final maxWidth = qrSize * 0.8;
  return SizedBox(
    width: maxWidth,
    child: FittedBox(
      fit: BoxFit.scaleDown,   // 넘치면 축소, 작으면 원본 크기 유지
      child: Text(
        text.content,
        maxLines: 1,
        style: TextStyle(
          color: text.color,
          fontFamily: text.fontFamily,
          fontSize: text.fontSize * scale,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
```

비-band 중앙 텍스트(기존 logoText 오버레이)도 동일한 auto-sizing 적용.

---

## 6. 파일별 상세 변경 사항

### 6.1 [삭제] `tabs/text_tab.dart`

완전 삭제. `_TextEditor`, `_StepButton` 위젯은 `logo_text_unified_editor.dart`에 재구현.

### 6.2 [삭제] `tabs/logo_editors/logo_text_editor.dart`

완전 삭제. 중앙 텍스트 편집은 `LogoTextUnifiedEditor`의 일부로 통합.

### 6.3 [신규] `tabs/logo_editors/logo_text_unified_editor.dart`

```dart
/// 로고 유형="텍스트" 선택 시 표시되는 통합 텍스트 편집기.
/// 상단 / 중앙 / 하단 3-position 텍스트 편집 + 중앙 "띠" 토글.
class LogoTextUnifiedEditor extends ConsumerStatefulWidget {
  final VoidCallback onChanged;
  const LogoTextUnifiedEditor({super.key, required this.onChanged});
  @override
  ConsumerState<LogoTextUnifiedEditor> createState() => _LogoTextUnifiedEditorState();
}

class _LogoTextUnifiedEditorState extends ConsumerState<LogoTextUnifiedEditor> {
  // 상단/하단: StickerConfig.topText/bottomText → setSticker()
  // 중앙: StickerConfig.logoText → applyLogoText()
  // 띠 토글: StickerConfig.centerTextBand → setCenterTextBand()
}
```

**내부 위젯**:
- `_TextSection` — 라벨 + TextField + 색상/폰트/크기 (text_tab의 `_TextEditor` 재구현)
- `_StepButton` — 크기 +/- 버튼 (text_tab과 동일)
- `_BandToggle` — "띠" 체크박스 (중앙 섹션에만 표시)

**텍스트 제한**:
- 상단: max 40자 (text_tab과 동일)
- 중앙: max 20자 (기존 6자에서 확대 — band 모드에서 가로 전체 활용)
- 하단: max 40자

### 6.4 [수정] `tabs/sticker_tab.dart`

**변경 1**: 위치 세그먼트 — 텍스트 유형 시 중앙만

```dart
// 기존
_SegmentRow<LogoPosition>(
  options: [
    (LogoPosition.center, l10n.optionCenter),
    (LogoPosition.bottomRight, l10n.optionBottomRight),
  ],
  ...
),

// 변경
_SegmentRow<LogoPosition>(
  options: isTextType
      ? [(LogoPosition.center, l10n.optionCenter)]
      : [
          (LogoPosition.center, l10n.optionCenter),
          (LogoPosition.bottomRight, l10n.optionBottomRight),
        ],
  ...
),
```

**변경 2**: IndexedStack — LogoTextEditor → LogoTextUnifiedEditor

```dart
// 기존
IndexedStack(
  index: currentType.index - 1,
  children: [
    LogoLibraryEditor(onChanged: onChanged),
    LogoImageEditor(onChanged: onChanged),
    LogoTextEditor(onChanged: onChanged),     // 삭제 대상
  ],
),

// 변경
IndexedStack(
  index: currentType.index - 1,
  children: [
    LogoLibraryEditor(onChanged: onChanged),
    LogoImageEditor(onChanged: onChanged),
    LogoTextUnifiedEditor(onChanged: onChanged),  // 통합 편집기
  ],
),
```

**변경 3**: 텍스트 유형 전환 시 logoPosition 자동 center 설정

```dart
onChanged: (v) {
  if (v != null) {
    ref.read(qrResultProvider.notifier).setLogoType(v);
    // 텍스트 유형 선택 시 자동으로 center 위치 설정
    if (v == LogoType.text && sticker.logoPosition != LogoPosition.center) {
      ref.read(qrResultProvider.notifier).setSticker(
        sticker.copyWith(logoPosition: LogoPosition.center),
      );
    }
    onChanged();
  }
},
```

### 6.5 [수정] `qr_result_screen.dart`

```dart
// 변경 1: TabController length 6 → 5
_tabController = TabController(length: 5, vsync: this);

// 변경 2: 탭 목록에서 TextTab 제거
// import 'tabs/text_tab.dart'; ← 삭제

// 변경 3: TabBar 아이템 5개
// Tab(icon: text_icon, text: l10n.tabText) 제거

// 변경 4: TabBarView children 5개
// TextTab(onChanged: ...) 제거
```

### 6.6 [수정] `widgets/qr_layer_stack.dart`

**핵심 변경**: 상/하단 텍스트를 Column 밖에서 Stack 내부로 이동.

#### 6.6.1 일반 모드 `_buildNormalLayout()` 변경

```dart
// 기존: Column([ topText, qrAndLogo, bottomText ])
// 변경: qrAndLogo Stack 내부에 텍스트 배치

final Widget qrAndLogo = SizedBox(
  width: widget.size,
  height: widget.size,
  child: Stack(
    clipBehavior: Clip.hardEdge,
    children: [
      // Layer 0: 배경 + QR
      Positioned.fill(
        child: Container(
          color: state.style.quietZoneColor,
          padding: EdgeInsets.all(quietPadding),
          child: qrWidget,
        ),
      ),
      // 플래시 오버레이 (기존 유지)
      ...

      // [추가] 상단 텍스트 — QR 레이어 내 상단
      if (sticker.hasTopText)
        Positioned(
          top: 2,
          left: 0,
          right: 0,
          child: _StickerTextWidget(text: sticker.topText!, width: widget.size),
        ),

      // 로고 (기존 유지)
      ...

      // [추가] 중앙 band 텍스트
      if (hasBand)
        Positioned.fill(
          child: Center(
            child: _buildBandText(sticker.logoText!, widget.size),
          ),
        ),

      // [추가] 하단 텍스트 — QR 레이어 내 하단
      if (sticker.hasBottomText)
        Positioned(
          bottom: 2,
          left: 0,
          right: 0,
          child: _StickerTextWidget(text: sticker.bottomText!, width: widget.size),
        ),
    ],
  ),
);

// Column wrapper 제거 — 상/하단 텍스트가 Stack 내부로 이동했으므로
return qrAndLogo;
```

#### 6.6.2 프레임 모드 `_buildFrameLayout()` 변경

동일 패턴으로 QR 영역(qrAreaSize) 내부 Stack에 상/하단 텍스트 배치:

```dart
// 기존 Column wrapper 제거
// 상/하단 텍스트를 QR 영역 SizedBox+Stack 내부로 이동

// QR 영역 내부에 상단/하단 텍스트 + band 텍스트 추가
SizedBox(
  width: qrAreaSize,
  height: qrAreaSize,
  child: Stack(
    children: [
      // QR 도트 (기존)
      ...
      // 상단 텍스트
      if (sticker.hasTopText) Positioned(top: 2, left: 0, right: 0, ...),
      // band 텍스트
      if (hasBand) Positioned.fill(child: Center(child: ...)),
      // 하단 텍스트
      if (sticker.hasBottomText) Positioned(bottom: 2, left: 0, right: 0, ...),
    ],
  ),
),
```

#### 6.6.3 Band ClearZone 전달

```dart
// _buildCustomQr() 및 _buildFrameQrPainter() 내부
final hasBand = sticker.centerTextBand &&
    sticker.logoText != null && !sticker.logoText!.isEmpty;

final bandCZ = hasBand
    ? computeBandClearZone(
        qrSize: Size.square(qrSize),
        fontSize: sticker.logoText!.fontSize * (widget.size * 0.22 / 35.2),
      )
    : null;

// CustomQrPainter 생성 시
CustomQrPainter(
  // ...기존...
  clearZone: clearZone,
  bandClearZone: bandCZ,  // [추가]
),
```

#### 6.6.4 Band 모드 배경 띠 렌더링

```dart
/// 중앙 텍스트 band 모드 렌더링: quietZoneColor 배경 + 텍스트
Widget _buildBandWidget(StickerText text, double qrSize) {
  final scale = qrSize * 0.22 / 35.2;
  final bandHeight = text.fontSize * scale * 1.4;
  return Container(
    width: qrSize * 0.9,
    height: bandHeight,
    decoration: BoxDecoration(
      // band 배경은 quietZoneColor 와 동일 (QR 도트가 clearing 되어 있으므로)
    ),
    alignment: Alignment.center,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text.content,
        maxLines: 1,
        style: TextStyle(
          color: text.color,
          fontFamily: text.fontFamily,
          fontSize: text.fontSize * scale,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
```

### 6.7 [수정] `notifier/logo_setters.dart`

```dart
mixin _LogoSetters on StateNotifier<QrResultState> {
  // 기존 메서드 유지

  // [추가]
  void setCenterTextBand(bool enabled) {
    state = state.copyWith(
      sticker: state.sticker.copyWith(centerTextBand: enabled),
    );
    _schedulePush();
  }
}
```

### 6.8 [수정] `domain/entities/sticker_config.dart`

```dart
class StickerConfig {
  // 기존 필드 모두 유지
  final bool centerTextBand;  // [신규]

  const StickerConfig({
    // ...기존...
    this.centerTextBand = false,
  });

  // copyWith 에 centerTextBand 추가
  // _stickerSentinel 패턴 불필요 (bool 은 non-nullable)
}
```

---

## 7. Implementation Order

### Phase 1: Entity + Serialization (의존성 없는 기반)

1. [ ] `sticker_config.dart` — `centerTextBand` 필드 추가 + copyWith
2. [ ] `sticker_spec.dart` — `centerTextBand` 직렬화
3. [ ] `customization_mapper.dart` — centerTextBand 매핑
4. [ ] `logo_setters.dart` — `setCenterTextBand()` 추가

### Phase 2: ClearZone + Painter (렌더링 기반)

5. [ ] `logo_clear_zone.dart` — `computeBandClearZone()` 함수 추가
6. [ ] `custom_qr_painter.dart` — `bandClearZone` 파라미터 추가, `_isInClearZone` 확장

### Phase 3: QrLayerStack 렌더링 변���

7. [ ] `qr_layer_stack.dart` — 상/하단 텍스트 QR 내부 이동 (Column→Stack)
8. [ ] `qr_layer_stack.dart` — band ClearZone 전달 + band 텍스트 렌더링
9. [ ] `qr_layer_stack.dart` — ecLevel 로직 (band 시 H 강제)

### Phase 4: UI 탭 변경

10. [ ] `logo_text_unified_editor.dart` — 신규 통합 편집기 생성
11. [ ] `sticker_tab.dart` — IndexedStack 교체 + 위치 제한 + 타입 전환 로직
12. [ ] `qr_result_screen.dart` — 6탭→5탭
13. [ ] `text_tab.dart` 삭제, `logo_text_editor.dart` 삭제

### Phase 5: l10n

14. [ ] `app_ko.arb` — 신규 키 추가 (bandModeLabel 등)

---

## 8. l10n 신규 키

```json
{
  "labelCenterText": "중앙 텍스트",
  "labelBandMode": "띠 모드",
  "bandModeDescription": "QR 중앙에 텍스트 띠를 표시합니다"
}
```

기존 키 재활용:
- `labelTopText`, `labelBottomText` — 기존 text_tab에서 사용하던 키
- `hintEnterText` — 기존 text_tab 힌트
- `labelFontFamily` — 기존 폰트 라벨

---

## 9. Test Plan

### 9.1 Test Cases

- [ ] 로고 탭에서 유형="텍스트" 선택 시 3-position 편집기 표시 확인
- [ ] 상단/하단 텍스트 입력 → QR 레이어 **내부**에 렌더링 확인
- [ ] 중앙 텍스트 입력 → QR 중앙에 오버레이 확인
- [ ] "띠" 토글 ON → QR 도트 행 clearing + 텍스트 가로 표시 확인
- [ ] "띠" 모드에서 QR 스캔 성공 확인
- [ ] 텍스트 유형 시 위치 옵션에서 "우하단" 미노출 확인
- [ ] 유형 logo/image 전환 시 위치 옵션 "우하단" 다시 노출 확인
- [ ] 5탭 구성 확인 (텍스트 탭 미노출)
- [ ] 기존 저장 데이터(centerTextBand 없음) 로드 시 정상 동작 확인
- [ ] 프레임 모드에서 상/하단 + band 텍스트 정상 렌더링 확인
- [ ] 중앙 텍스트 auto-sizing: 긴 텍스트 시 폰트 축소 확인

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-26 | Initial draft | Claude |
