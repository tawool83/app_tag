---
template: design
version: 1.2
feature: color-tab-redesign
date: 2026-04-17
author: tawool83
project: app_tag
---

# color-tab-redesign Design Document

> **Summary**: QR 색상 탭을 단일 스크롤 뷰로 통합하고, Google Slides 스타일 맞춤 그라디언트 편집기를 추가.
>
> **Planning Doc**: [color-tab-redesign.plan.md](../../01-plan/features/color-tab-redesign.plan.md)

---

## 1. 위젯 구조

### 1.1 변경 전

```
QrColorTab (StatefulWidget + TabController)
├── TabBar: [단색] [그라디언트]
└── TabBarView
    ├── _SolidColorView
    │   ├── "추천 색상" label
    │   ├── Wrap(10 color circles)
    │   └── "직접 선택" button → HSV dialog
    └── _GradientView
        ├── "그라디언트 프리셋" label
        └── Wrap(8 gradient rectangles)
```

### 1.2 변경 후

```
QrColorTab (StatefulWidget)  ← TabController 제거
└── SingleChildScrollView
    ├── _SectionHeader("단색")
    ├── Wrap(10 color circles + [+직접 선택] circle)
    │
    ├── SizedBox(height: 20)
    ├── _SectionHeader("그라디언트")
    ├── Wrap(8 gradient rects + [+직접 선택] rect)
    │
    └── if (_showCustomEditor)
        └── _CustomGradientEditor  ← 신규 위젯
            ├── _SectionHeader("맞춤 그라디언트")
            ├── _TypeSelector (선형/방사형)
            ├── if (linear) _AngleSelector (8 chips)
            ├── if (radial) _CenterSelector (5 chips)
            ├── _ColorStopList (stops + add/delete)
            ├── _GradientPreviewBar (미리보기)
            └── _GradientSlider (드래그 핸들)
```

---

## 2. 데이터 모델

### 2.1 맞춤 그라디언트 편집 상태

```dart
class _GradientEditorState {
  String type;          // 'linear' | 'radial'
  double angleDegrees;  // 0, 45, 90, 135, 180, 225, 270, 315
  String center;        // 'center' | 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight'
  List<_ColorStop> stops; // 최소 2, 최대 5
}

class _ColorStop {
  Color color;
  double position; // 0.0 ~ 1.0
}
```

### 2.2 QrGradient 매핑

편집기 상태 → 기존 `QrGradient` 모델로 변환:

```dart
QrGradient(
  type: state.type,           // 'linear' | 'radial'
  colors: stops.map((s) => s.color).toList(),
  stops: stops.map((s) => s.position).toList(),
  angleDegrees: state.angleDegrees,
)
```

---

## 3. 상세 UI 설계

### 3.1 단색 섹션

```
──── 단색 ────────────────────────────────
● ● ● ● ● ● ● ● ● ● [+]
(10색 팔레트)             (직접 선택)
```

- 기존 10색 원형 버튼 유지
- 마지막에 `+` 원형 버튼 (점선 테두리) → HSV 컬러 휠 다이얼로그
- 선택된 색상은 체크마크 오버레이

### 3.2 그라디언트 섹션

```
──── 그라디언트 ──────────────────────────
[■][■][■][■][■][■][■][■][+]
(8개 프리셋)                (직접 선택)
```

- 기존 8개 프리셋 사각 버튼 유지
- 마지막에 `+` 사각 버튼 (점선 테두리) → `_showCustomEditor = true`
- 선택된 프리셋은 체크마크 오버레이

### 3.3 맞춤 그라디언트 편집기

```
──── 맞춤 그라디언트 ────────────────────

유형   [선형]  [방사형]

각도 (선형일 때만)
  [0°] [45°] [90°] [135°] [180°] [225°] [270°] [315°]

가운데 (방사형일 때만)
  [중앙] [왼쪽 상단] [오른쪽 상단] [왼쪽 하단] [오른쪽 하단]

색 지점
  ● #FF0000  [삭제]
  ● #0000FF  [삭제]
  [+ 추가]

[████████████████████████████████████]  ← 미리보기 바
[────●──────────────────●────────]  ← 드래그 슬라이더
```

### 3.4 드래그 슬라이더 구현

- `CustomPainter` + `GestureDetector` 로 구현
- 가로 바: 현재 그라디언트를 `LinearGradient`로 렌더링
- 각 stop 위치에 원형 핸들(16px) 표시
- 핸들 드래그 시 `position` 값 업데이트 (0.0~1.0 clamped)
- 첫 번째 핸들은 0.0, 마지막 핸들은 1.0 고정 (드래그 불가)
- 중간 핸들은 이전/다음 핸들 사이에서만 이동 가능
- 실시간 미리보기 갱신

---

## 4. 구현 순서

| Step | 작업 | 비고 |
|:----:|------|------|
| S1 | 기존 TabBar/TabBarView 제거 → SingleChildScrollView | qr_color_tab.dart |
| S2 | 단색 섹션: "단색" 헤더 + 팔레트 + 직접 선택 원형 버튼 | 기존 코드 재배치 |
| S3 | 그라디언트 섹션: "그라디언트" 헤더 + 프리셋 + 직접 선택 버튼 | 기존 코드 재배치 |
| S4 | _CustomGradientEditor 위젯 스켈레톤 | StatefulWidget |
| S5 | _TypeSelector (SegmentedButton) | 선형/방사형 |
| S6 | _AngleSelector (ChoiceChip Wrap) | 8개 각도 |
| S7 | _CenterSelector (ChoiceChip Wrap) | 5개 가운데 위치 |
| S8 | _ColorStopList (ListView + 추가/삭제) | HSV 피커 연동 |
| S9 | _GradientPreviewBar (CustomPainter) | 미리보기 |
| S10 | _GradientSlider (CustomPainter + GestureDetector) | 드래그 핸들 |
| S11 | 편집기 → QrGradient 변환 → QrResultNotifier 반영 | 실시간 반영 |
| S12 | ARB 10개 파일 새 키 추가 | 다국어 |

---

## 5. ARB 키 목록

| 키 | ko | en |
|---|------|------|
| `labelSolidColor` | 단색 | Solid |
| `labelGradient` | 그라디언트 | Gradient |
| `labelCustomGradient` | 맞춤 그라디언트 | Custom Gradient |
| `labelGradientType` | 유형 | Type |
| `optionLinear` | 선형 | Linear |
| `optionRadial` | 방사형 | Radial |
| `labelAngle` | 각도 | Angle |
| `labelCenter` | 가운데 | Center |
| `optionCenterCenter` | 중앙 | Center |
| `optionCenterTopLeft` | 왼쪽 상단 | Top Left |
| `optionCenterTopRight` | 오른쪽 상단 | Top Right |
| `optionCenterBottomLeft` | 왼쪽 하단 | Bottom Left |
| `optionCenterBottomRight` | 오른쪽 하단 | Bottom Right |
| `labelColorStops` | 색 지점 | Color Stops |
| `actionAddStop` | 추가 | Add |
| `actionDeleteStop` | 삭제 | Delete |

---

## 6. 검증 기준

| # | 항목 | 방법 |
|---|------|------|
| 1 | 서브탭 제거, 단일 스크롤 뷰 | UI 확인 |
| 2 | 단색 직접 선택 → HSV 피커 동작 | 색상 변경 확인 |
| 3 | 그라디언트 직접 선택 → 편집기 표시 | UI 확인 |
| 4 | 유형 전환 시 각도/가운데 UI 토글 | 선형↔방사형 전환 |
| 5 | 색 지점 추가/삭제 (2~5개 범위) | 버튼 동작 |
| 6 | 드래그 슬라이더로 stop 위치 변경 | 실시간 미리보기 반영 |
| 7 | 편집 결과가 QR 미리보기에 반영 | 실시간 확인 |
| 8 | dart analyze 에러 0 | CLI |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-17 | Initial design | tawool83 |
