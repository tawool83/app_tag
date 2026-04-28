# quiet-zone-border Design

> Plan: `docs/01-plan/features/quiet-zone-border.plan.md`

---

## 1. State 변경

### 1.1 `QrStyleState` (2 필드 추가)

```dart
// lib/features/qr_result/domain/state/qr_style_state.dart

class QrStyleState {
  // ... 기존 14 필드 ...
  final bool quietZoneBorderEnabled;    // 기본 false
  final double quietZoneBorderWidth;    // 기본 1.0, 범위 1.0~4.0

  const QrStyleState({
    // ... 기존 ...
    this.quietZoneBorderEnabled = false,
    this.quietZoneBorderWidth = 1.0,
  });

  QrStyleState copyWith({
    // ... 기존 ...
    bool? quietZoneBorderEnabled,
    double? quietZoneBorderWidth,
  }) => QrStyleState(
    // ... 기존 ...
    quietZoneBorderEnabled: quietZoneBorderEnabled ?? this.quietZoneBorderEnabled,
    quietZoneBorderWidth: quietZoneBorderWidth ?? this.quietZoneBorderWidth,
  );

  // == 에 2 필드 추가
  // hashCode 에 2 필드 추가
}
```

테두리 색상은 별도 필드 없음 — 렌더링 시 `bgColor ?? qrColor` 참조.

---

## 2. 영속화

### 2.1 `QrCustomization` (2 optional 필드 추가)

```dart
// lib/features/qr_task/domain/entities/qr_customization.dart

class QrCustomization {
  // ... 기존 ...
  final bool? quietZoneBorderEnabled;   // null/false = 비활성
  final double? quietZoneBorderWidth;   // null = 기본 1.0

  // toJson: 활성일 때만 기록
  //   if (quietZoneBorderEnabled == true) 'quietZoneBorderEnabled': true,
  //   if (quietZoneBorderWidth != null && quietZoneBorderWidth != 1.0)
  //     'quietZoneBorderWidth': quietZoneBorderWidth,

  // fromJson:
  //   quietZoneBorderEnabled: json['quietZoneBorderEnabled'] as bool?,
  //   quietZoneBorderWidth: (json['quietZoneBorderWidth'] as num?)?.toDouble(),

  // copyWith: 표준 패턴
}
```

### 2.2 `CustomizationMapper` 변경

```dart
// lib/features/qr_result/utils/customization_mapper.dart

// fromState — 추가:
quietZoneBorderEnabled: state.style.quietZoneBorderEnabled ? true : null,
quietZoneBorderWidth: state.style.quietZoneBorderWidth != 1.0
    ? state.style.quietZoneBorderWidth : null,

// 복원 — Notifier 에서 직접 사용:
//   quietZoneBorderEnabled: c.quietZoneBorderEnabled ?? false,
//   quietZoneBorderWidth: c.quietZoneBorderWidth ?? 1.0,
```

---

## 3. Notifier

### 3.1 `style_setters.dart` (2 메서드 추가)

```dart
// lib/features/qr_result/notifier/style_setters.dart

void setQuietZoneBorderEnabled(bool enabled) {
  state = state.copyWith(
    style: state.style.copyWith(quietZoneBorderEnabled: enabled),
  );
  _schedulePush();
}

void setQuietZoneBorderWidth(double width) {
  state = state.copyWith(
    style: state.style.copyWith(quietZoneBorderWidth: width.clamp(1.0, 4.0)),
  );
  _schedulePush();
}
```

---

## 4. 렌더링

### 4.1 `QrLayerStack` 일반 경로 (프레임 모드 제외)

```dart
// lib/features/qr_result/widgets/qr_layer_stack.dart
// _buildNormalLayout 내 qrSquare SizedBox 변경

final borderEnabled = state.style.quietZoneBorderEnabled && !isFrameMode;
final borderColor = state.style.bgColor ?? state.style.qrColor;
final borderWidth = state.style.quietZoneBorderWidth;

final Widget qrSquare = Container(
  width: widget.size,
  height: widget.size,
  decoration: borderEnabled
      ? BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        )
      : null,
  child: Stack(
    clipBehavior: Clip.hardEdge,
    children: [ /* 기존 children 유지 */ ],
  ),
);
```

**프레임 경로**: 변경 없음 (`DecorativeFramePainter`가 외곽 담당).

---

## 5. UI

### 5.1 배경 탭 (`qr_background_tab.dart`) — 프리셋 영역 아래 추가

```dart
// build() 메서드, Column children 끝에 추가:

// ── 테두리선 섹션 ──
const SizedBox(height: 8),
_sectionLabel(l10n.labelQuietZoneBorder),
const SizedBox(height: 8),
SwitchListTile(
  title: Text(l10n.labelQuietZoneBorder, style: TextStyle(fontSize: 14)),
  value: state.style.quietZoneBorderEnabled,
  dense: true,
  contentPadding: EdgeInsets.zero,
  onChanged: (v) => ref.read(qrResultProvider.notifier)
      .setQuietZoneBorderEnabled(v),
),
if (state.style.quietZoneBorderEnabled)
  _SliderRow(
    label: l10n.labelBorderWidth,
    value: state.style.quietZoneBorderWidth,
    min: 1.0,
    max: 4.0,
    divisions: 6,
    valueLabel: '${state.style.quietZoneBorderWidth.toStringAsFixed(1)}px',
    onChanged: (v) => ref.read(qrResultProvider.notifier)
        .setQuietZoneBorderWidth(v),
  ),
```

### 5.2 색상 탭

변경 없음. 기존 `ColorTargetMode.bgOnly` 에서 `setBgColor()` 호출 → `bgColor` 변경 → 테두리 색상 자동 연동.

---

## 6. l10n

### 6.1 `app_ko.arb` 추가 키

```json
"labelQuietZoneBorder": "테두리선",
"labelBorderWidth": "두께"
```

---

## 7. 데이터 흐름

```
[배경 탭] SwitchListTile → setQuietZoneBorderEnabled(bool)
                            → QrStyleState.quietZoneBorderEnabled
[배경 탭] _SliderRow       → setQuietZoneBorderWidth(double)
                            → QrStyleState.quietZoneBorderWidth
[색상 탭] bgOnly 색상 변경 → setBgColor(Color)
                            → QrStyleState.bgColor

         ↓ ref.watch(qrResultProvider)

[QrLayerStack] build()
  borderEnabled = style.quietZoneBorderEnabled && !isFrameMode
  borderColor   = style.bgColor ?? style.qrColor
  borderWidth   = style.quietZoneBorderWidth
  → Container(decoration: BoxDecoration(border: Border.all(...)))

         ↓ _schedulePush()

[CustomizationMapper.fromState]
  → QrCustomization(quietZoneBorderEnabled, quietZoneBorderWidth)
  → Hive 저장
```

---

## 8. 구현 순서

| 순서 | 파일 | 작업 |
|------|------|------|
| 1 | `domain/state/qr_style_state.dart` | 2 필드 + copyWith + == + hashCode |
| 2 | `qr_customization.dart` | 2 필드 + toJson + fromJson + copyWith |
| 3 | `customization_mapper.dart` | fromState 매핑 |
| 4 | `notifier/style_setters.dart` | setter 2개 |
| 5 | `widgets/qr_layer_stack.dart` | 테두리 렌더링 (일반 경로) |
| 6 | `tabs/qr_background_tab.dart` | 토글 + 슬라이더 UI |
| 7 | `app_ko.arb` | l10n 2 키 |

---

## 9. 비적용 범위

- 프레임 모드: `DecorativeFramePainter`가 외곽 담당, 별도 테두리 불필요
- SVG 내보내기: quiet zone 관련 코드 없음, 별도 처리 불필요
- 테두리 모양(둥근 모서리): 이번 scope 밖
