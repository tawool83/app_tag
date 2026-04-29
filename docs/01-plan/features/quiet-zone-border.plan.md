# quiet-zone-border Plan

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | (v1) quiet zone 경계 부재 → 밝은 배경에서 QR 미구분. (v3) 테두리선의 의미를 명확히: **QR 코드 사양상의 quiet-zone 경계** 를 시각적으로 표시 → 항상 직사각형. (v4) 두께 조절 시 quiet zone 영역을 시각적/실제로 침범 + PNG 저장 시 quiet zone 4 모듈 미달 → 스캐너 인식 위험. CLAUDE.md §5 QR 스펙 절대 준수 위반. |
| **Solution** | (v1) 배경 탭에 quiet-zone 테두리선 토글 + 두께 슬라이더, 색상은 색상탭 bgColor 재사용. (v3) 선 종류 다양화(solid/dashed/dotted) + UI 정리. (v4) **렌더링 순서 명확화 + reserve 영역 도입**: 안쪽→바깥 = QR → quiet zone(12% 비율, 4 모듈 보장) → 테두리(안쪽 가장자리 고정, 두께만큼 바깥 확장) → 배경. `_kMaxBorderWidth(=4.0)` 만큼 외부 reserve 를 항상 확보하여 quiet zone 절대 불변. frame 모드도 동일 정책. |
| **Function UX Effect** | 배경 탭 [테두리선] 옆 토글 ON → QR 코드 외곽에 직사각형 테두리. 두께 슬라이더(1~4px)와 선 종류(가로 SegmentedButton: ─── / ─ ─ / ··· ) 노출. 두께를 늘려도 quiet zone 4 모듈은 절대 보존, **두께 외곽이 배경 영역 방향으로 확장**. PNG 저장 시 외곽 ~ 테두리 사이의 흰 quiet zone 여백 항상 보장. |
| **Core Value** | QR 스펙 준수 (4 모듈 quiet zone 절대 보호) + 인쇄·명함에서 QR 사양 영역의 가독성·신뢰감 향상. 어떤 두께에서도 스캐너 인식률 일관. |

---

## 1. 요구사항

### 1.1 기능 정의 (v1, 적용 완료)
- quiet zone(QR 도트 영역 바깥, 배경색 채워진 여백) 가장자리에 테두리선(border)을 그리는 기능
- 테두리선 활성/비활성 토글
- 테두리선 두께 조절 (1~4px, 기본 1px)
- 테두리선 색상 = 색상 탭 "배경" 모드(`ColorTargetMode.bgOnly`)에서 설정하는 `bgColor`와 동일

### 1.2 의미 정의 — QR 사양 경계 표시 (v3 명시)
- **테두리선 = QR 코드의 사양상 경계 표시**
- QR 스펙 (ISO/IEC 18004): QR 도트 영역 + 4 modules quiet zone = 스캐너가 인식 가능한 최소 영역
- 본 기능은 그 경계를 시각적으로 노출 → "여기까지가 QR 코드 영역" 임을 인쇄·디자인 컨텍스트에서 표현
- 따라서 **항상 직사각형** 이며, 배경의 외각 모양(circle/star/heart 등)과 **무관**

### 1.3 신규 기능 (v3)
- **선 종류 옵션**: `solid` / `dashed` / `dotted` 3종 (사용자 결정)
  - `solid`: 단순 stroke (기본값)
  - `dashed`: 짧은 선분 반복 (dashLength = borderWidth × 4, gapLength = borderWidth × 2)
  - `dotted`: 점 반복 (StrokeCap.round, dashLength = borderWidth, gapLength = borderWidth × 2)

### 1.3.1 v4 — QR 스펙 4 모듈 quiet zone 절대 보호 정책 (CLAUDE.md §5)

**렌더링 순서 (안쪽 → 바깥)** — 사용자 명시:
1. **QR 코드** (모듈 매트릭스)
2. **quiet zone** (4 모듈, 흰색/배경색, **고정**)
3. **테두리** (안쪽 가장자리 = quiet zone 외곽 **고정**, 외곽 가장자리 = 두께만큼 **바깥(배경 방향)** 확장)
4. **배경** (테두리 외곽 너머, quietZoneColor 영역)

**구현 핵심 (`_kMaxBorderWidth` reserve 패턴)**:
- 슬라이더 max(=4.0)와 일치하는 상수 `_kMaxBorderWidth = 4.0` 정의
- `borderReserve = borderEnabled ? _kMaxBorderWidth : 0.0` — 외부 여백을 *항상* max 두께만큼 확보
- `contentInset = quietPadding + borderReserve` — QR 콘텐츠는 quiet zone + reserve 안쪽
- border painter: `Padding(EdgeInsets.all(_kMaxBorderWidth - borderWidth))` 안에 그려짐
  - **stroke 안쪽 가장자리**: 항상 widget.size 외곽 - kMaxBorderWidth 위치 = quiet zone 외곽 (**불변**)
  - **stroke 외곽 가장자리**: widget.size 외곽 - (kMaxBorderWidth - borderWidth) = 두께만큼 바깥 확장
  - 두께 max(=4) → 외곽이 widget.size 외곽 닿음
  - 두께 < max → 외곽 너머 quietZoneColor "배경" 영역

**quietPadding 비율 12% (5% → 12%)**:
- V5(37 modules) 기준 4 모듈 ≈ 10.8% → 12% 보수적 보장 + min 12 / max 32 px
- 이전 5% 는 V5 기준 약 2 모듈로 QR 스펙 4 모듈 미달 (스펙 위반)

**불변식**:
- ∀ borderWidth ∈ [1, 4]: quiet zone 영역 size 일정 = quietPadding
- ∀ borderWidth: stroke 안쪽 가장자리 위치 동일
- 두께 변화는 **stroke 외곽 ~ widget.size 외곽** 영역만 변동

**Frame 모드 적용** (이전 v3 의 "프레임 모드 변경 없음" 철회):
- `innerInset = quietPadding + borderReserve` 로 Container padding 변경
- `effectiveQrSize = qrAreaSize - 2 * innerInset` 로 QR 영역 축소
- frame 모드 Stack 에 quiet zone border painter 추가 (Layer 1.5):
  - `SizedBox(qrAreaSize) > Padding(_kMaxBorderWidth - borderWidth) > CustomPaint(_QuietZoneBorderPainter)`

### 1.4 UI 변경 (v3)
- **이전 (v1)**: `[테두리선]` 소제목 → `SwitchListTile([테두리선] 라벨 + 토글)` (라벨 중복)
- **이후 (v3)**:
  - 헤더 행: `[테두리선] 소제목 ─── 토글` 한 줄 (중복 라벨 제거)
  - 토글 ON 시: 두께 슬라이더 (기존) + **선 종류 SegmentedButton** (신규) 노출
  - 토글 OFF: 두 컨트롤 모두 숨김

### 1.5 비적용 범위
- **외각 모양(`boundaryParams.type`) 동기화 안 함** — 테두리는 QR 사양 경계 표시이므로 항상 직각 (v2 의 잘못된 이해 철회)
- ~~**프레임 모드** 변경 없음~~ → **v4 에서 적용 추가**: frame 모드도 quiet zone 4 모듈 + border reserve 정책 동일 적용. frame 자체는 외각 장식이고, 테두리는 QR 영역 안쪽의 quiet zone 외곽선 표시.
- 테두리선의 둥근 모서리(rounded corner) 옵션 — 이번 scope 밖

---

## 2. 영향 분석

### 2.1 State 변경 (v3 — 1개 enum + 1개 필드 추가)

**`QrStyleState`** (기존):
- `bool quietZoneBorderEnabled` (v1, 적용 완료)
- `double quietZoneBorderWidth` (v1, 적용 완료)
- **(NEW)** `QuietZoneBorderStyle quietZoneBorderStyle` (기본값: `solid`)

테두리선 색상은 별도 필드 불필요 — 기존 `bgColor ?? qrColor` 를 따름.

### 2.2 신규 entity 파일 (R-series 패턴)

**경로**: `lib/features/qr_result/domain/entities/quiet_zone_border_style.dart`

```dart
/// QR 사양 경계(quiet-zone) 테두리선의 stroke pattern.
enum QuietZoneBorderStyle {
  solid,   // ─────────
  dashed,  // ─ ─ ─ ─ ─
  dotted,  // · · · · ·
}
```

### 2.3 영속화 변경

**`QrCustomization`** (도메인 직렬화):
- `String? quietZoneBorderStyleName` (null = `solid` fallback)

**`CustomizationMapper`**: `fromState` / 복원 시 enum ↔ name 매핑 추가.

### 2.4 렌더링 변경

**`QrLayerStack` 일반 경로** (`qr_layer_stack.dart` lines 262~272):

기존 (v1):
```dart
if (borderEnabled)
  Positioned.fill(
    child: IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      ),
    ),
  ),
```

변경 후 (v3):
```dart
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
```

신규 painter 사양 (`qr_layer_stack.dart` 파일 하단 helper 영역):

```dart
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
    // QR 사양상의 quiet-zone 경계 — 항상 직사각형.
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

**프레임 모드 경로**: 변경 없음.

**왜 외각 모양 동기화 안 하나** (v2 철회 사유):
- 사용자 의도 = "QR 코드 사양 경계 표시" 이므로 외각 디자인과 독립
- 외각 모양 = circle 이어도 QR 사양 영역은 정사각형 (도트 매트릭스 + quiet-zone)
- 테두리선이 QR 영역의 약속(스캐너 인식 영역)을 시각화하는 것이므로 직각이 정확함

**왜 두께 변경 시 quiet-zone 침범 안 하나** (v4 정책):

v3 의 `borderInset = borderWidth` 가변 정책은 **두께 변화에 따라 quiet zone 위치가 미묘하게 이동** 하는 부작용 + **PNG 캡처 시 흑색 stroke 가 캡처본 가장자리에 닿아** quiet zone 외곽 흰 여백 0 → 스캐너 인식 위험.

v4 정책:
- `borderReserve = _kMaxBorderWidth (=4.0 고정)` — slider max 만큼 외부 reserve 항상 확보
- `contentInset = quietPadding + borderReserve` (두께와 무관 고정)
- border painter 위치 = `Padding(_kMaxBorderWidth - borderWidth)` 안
  - stroke 안쪽 가장자리 = widget.size 외곽 - kMaxBorderWidth 위치 = quiet zone 외곽 = **두께 무관 불변**
  - stroke 외곽 가장자리 = stroke 안쪽 + borderWidth = widget.size 외곽 - (kMaxBorderWidth - borderWidth) → 두께 ↑ 시 외곽이 widget.size 외곽 방향(배경 방향)으로 이동
- 두께 max(=4) 일 때 외곽 = widget.size 외곽. 두께 < max 일 때 외곽 너머 quietZoneColor 영역 (배경)
- quiet zone 영역(quietPadding=12%) 자체는 **모든 두께에서 동일**

**또한 quietPadding 비율 5% → 12%**:
- V5(37 modules) 기준 5% ≈ 1.85 모듈 → 12% ≈ 4.4 모듈 (QR 스펙 4 모듈 충족)
- min 12 / max 32 px (이전 min 8 / max 20)

### 2.5 UI 변경

**배경 탭 (`qr_background_tab.dart`)** lines 249~274:

기존 (v1):
```dart
_sectionLabel(l10n.labelQuietZoneBorder),
const SizedBox(height: 8),
SwitchListTile(
  title: Text(l10n.labelQuietZoneBorder, ...),
  value: state.style.quietZoneBorderEnabled,
  ...
),
if (state.style.quietZoneBorderEnabled)
  _SliderRow(...),
```

변경 후 (v3):
```dart
// 헤더 행: 소제목 + 토글
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
  // 두께 슬라이더 (기존 유지)
  _SliderRow(
    label: l10n.labelBorderWidth,
    value: state.style.quietZoneBorderWidth,
    min: 1.0, max: 4.0, divisions: 6,
    valueLabel: '${state.style.quietZoneBorderWidth.toStringAsFixed(1)}px',
    onChanged: (v) => ref
        .read(qrResultProvider.notifier)
        .setQuietZoneBorderWidth(v),
  ),
  // 선 종류 (NEW) — 가로 SegmentedButton
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
            segments: const [
              ButtonSegment(value: QuietZoneBorderStyle.solid,
                  icon: Icon(Icons.remove)),  // ───
              ButtonSegment(value: QuietZoneBorderStyle.dashed,
                  icon: Icon(Icons.more_horiz)),  // ─ ─
              ButtonSegment(value: QuietZoneBorderStyle.dotted,
                  icon: Icon(Icons.more_vert)),  // ···
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
```

> 아이콘은 placeholder. 실제 구현 시 더 정확한 stroke 패턴 아이콘 사용 (Material symbols 또는 custom).

### 2.6 Notifier 변경

**`style_setters.dart`** (mixin):
- **(NEW)** `setQuietZoneBorderStyle(QuietZoneBorderStyle)`

기존 `setQuietZoneBorderEnabled(bool)`, `setQuietZoneBorderWidth(double)` 재사용.

### 2.7 l10n

**`app_ko.arb`** 추가:
- `labelBorderStyle`: "선 종류"

기존 `labelQuietZoneBorder`("테두리선"), `labelBorderWidth`("두께") 재사용.

---

## 3. 구현 순서 (v3)

1. **신규 entity**: `lib/features/qr_result/domain/entities/quiet_zone_border_style.dart` 생성 (enum)
2. **`QrStyleState`** 에 `quietZoneBorderStyle` 필드 추가 + `copyWith` / `==` / `hashCode`
3. **`QrCustomization`** 에 `quietZoneBorderStyleName` 필드 추가 + `toJson` / `fromJson` / `copyWith`
4. **`CustomizationMapper`** `fromState` / 복원 매핑 추가
5. **`style_setters.dart`** 에 `setQuietZoneBorderStyle(QuietZoneBorderStyle)` 추가
6. **`qr_layer_stack.dart`**:
   - 라인 167~169 의 `borderInset` 계산 부분에 quiet-zone 보호 의도 주석 추가
   - 라인 262~272 의 `Container(BoxDecoration.border)` 를 `CustomPaint(_QuietZoneBorderPainter)` 로 교체
   - 파일 하단에 `_QuietZoneBorderPainter` 클래스 + `_drawDashedLine` 헬퍼 추가
7. **`qr_background_tab.dart`**:
   - 라인 249~261 의 `_sectionLabel` + `SwitchListTile` 을 `Row(소제목 + Switch)` 로 교체
   - 토글 ON 분기에 SegmentedButton 추가
8. **`app_ko.arb`** 에 `labelBorderStyle` 추가 + `flutter gen-l10n`
9. 빌드 / 수동 테스트:
   - solid / dashed / dotted 각각 1px / 2px / 3px / 4px 조합 확인
   - 외각 모양 = circle/star 등으로 변경해도 테두리는 항상 직사각형 유지 (회귀 검증)
   - 프레임 모드 → 테두리 미적용 유지 (회귀 검증)
   - 두께 4px + dashed → quiet-zone 침범 없는지 시각 확인
   - PNG 캡처 → dashed/dotted 가 캡처에도 정확히 반영되는지 확인

---

## 4. 기술 결정 (v3)

| 항목 | 결정 | 근거 |
|------|------|------|
| 테두리 모양 | 항상 직사각형 | QR 사양상의 quiet-zone 경계 의미 — 외각 디자인과 독립 |
| 외각 모양 동기화 | **하지 않음** (v2 철회) | 사용자 의도 명확화 — 테두리는 사양 경계 표시이지 외각 장식 아님 |
| 선 종류 옵션 | solid / dashed / dotted (3종) | UI 세그먼트 한 줄 충분, 구현 단순 (사용자 결정) |
| 두께 범위 | 1~4px (v1 유지) | quiet-zone 보호 + 시각적 가독성 균형 (사용자 결정) |
| ~~두께 변경 시 quiet-zone 보호~~ (v3) | ~~`borderInset = borderWidth` 로 외부 여백 추가~~ | v4 에서 폐기 — PNG 캡처본 quiet zone 부족 문제 |
| 두께 변경 시 quiet-zone 보호 (v4) | `borderReserve = _kMaxBorderWidth (4.0 고정)` + painter `Padding(_kMaxBorderWidth - borderWidth)` | 안쪽 가장자리 고정 + 외곽이 배경 방향으로 확장. quiet zone 영역 절대 불변 (INV-1) |
| quietPadding 비율 (v4) | 5% → 12%, min 8→12 / max 20→32 | V5 기준 4 모듈 quiet zone 보장 (CLAUDE.md §5 ISO/IEC 18004) |
| frame 모드 적용 (v4) | innerInset = quietPadding + borderReserve + Layer 1.5 painter 추가 | 외각 모양과 무관하게 quiet zone border 동작 (사용자 명시) |
| dashed/dotted 구현 | 4변 각각 line drawing (PathMetric 미사용) | 직사각형 한정이라 segment 기반 단순 알고리즘으로 충분. 외부 패키지 불필요 |
| dashed 비율 | dashLength = w×4, gapLength = w×2 | 일반적 dashed 비율. 두께 비례 → 어느 두께에서도 균일감 |
| dotted 비율 | StrokeCap.round, dashLength = w, gapLength = w×2 | 점 모양은 두께 = 점 직경. 둥근 cap |
| UI 위젯 | SegmentedButton (가로) | 다른 탭과 일관성, 3종 한 줄 fit (사용자 결정) |
| Container vs CustomPaint | CustomPaint 로 통일 | dashed/dotted 는 BoxDecoration.border 로 표현 불가 |
| 라벨 중복 제거 | SwitchListTile → Row(소제목 + Switch) | UX 정리 (사용자 명시) |

---

## 5. 프로젝트 메타

- **Level**: Flutter Dynamic × Clean Architecture × R-series
- **State Management**: Riverpod StateNotifier
- **로컬 저장**: Hive (직렬화는 v1 에서 완료, v3 에서 1개 필드 추가)
- **라우팅**: go_router

---

## 6. Revision History

| 버전 | 날짜 | 변경 내용 |
|------|------|-----------|
| v1 | 2026-04-28 | quiet-zone 테두리선 토글 + 두께 슬라이더 + bgColor 재사용. 항상 직사각형 (Container.BoxDecoration.border). |
| v2 | 2026-04-29 (철회) | 외각 모양 동기화 추가 (잘못된 이해) — 사용자 명확화로 철회. |
| v3 | 2026-04-29 | (1) 의미 정의 명확화: QR 사양 경계 표시 → 항상 직사각형. (2) 선 종류 신규: solid / dashed / dotted (SegmentedButton). (3) UI 정리: 소제목 옆 토글 1개로 통합. (4) 두께 변경 시 quiet-zone 보호 알고리즘 명시화 (borderInset = borderWidth 정책). |
| v4 | 2026-04-29 | **CLAUDE.md §5 QR 스펙 절대 준수 정책 적용**. (1) 렌더링 순서 명시: QR → quiet zone → 테두리 → 배경. (2) `_kMaxBorderWidth = 4.0` reserve 패턴 도입 — 두께 변경 시 quiet zone 절대 불변, stroke 외곽만 배경 영역으로 확장. (3) quietPadding 5%→12% (V5 기준 4 모듈 보장). (4) frame 모드도 동일 정책 적용 (innerInset = quietPadding + borderReserve + Layer 1.5 border painter). (5) v3 의 가변 borderInset 정책 폐기 (PNG 캡처본 quiet zone 부족 문제 해결). |
