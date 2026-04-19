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
QrColorTab (ConsumerStatefulWidget, key: GlobalKey<QrColorTabState>)
├── onEditorModeChanged 콜백 → 부모에 편집기 모드 알림
│
├── [일반 모드] SingleChildScrollView
│   ├── _SectionHeader("단색")              ← tabColorSolid 재사용
│   ├── Wrap(10 color circles + [+] circle)
│   ├── SizedBox(height: 20)
│   ├── _SectionHeader("그라디언트")         ← tabColorGradient 재사용
│   └── Wrap(8 gradient rects + [+] rect)
│
└── [편집기 모드] (_showCustomEditor == true)
    │   ※ 팔레트 숨김, 하단 액션버튼 → 확인/취소로 교체
    ├── _buildTypeAndOptionRow (드롭다운 한 행)
    │   ├── 유형 DropdownButtonFormField (선형/방사형)
    │   └── 선형→각도 / 방사형→가운데 DropdownButtonFormField
    ├── _buildColorStopList (stops 2~5, add/delete)
    ├── _GradientSliderBar (미리보기 + 드래그 슬라이더 통합)
    │   └── CustomPainter: 그라디언트 바 + 하단 경계 핸들
    └── [확인] [취소] 버튼
        ├── 확인: 그라디언트 적용, 편집기 닫기
        └── 취소: _gradientBeforeEdit 복원, 편집기 닫기

부모(QrResultScreen):
├── _colorEditorMode 상태 → 하단 액션버튼 visibility 제어
├── TabController.addListener(_onTabChanged)
│   └── 탭 전환 시 _colorTabKey.currentState?.confirmAndCloseEditor()
└── dispose에서 listener 해제
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
  center: state.center,       // 'center' | 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight'
)
```

### 2.3 모델 변경 (center 필드 추가)

| 클래스 | 추가 필드 | 용도 |
|--------|----------|------|
| `QrGradient` (presentation) | `String? center` | Flutter Color 기반, UI 렌더링 |
| `QrGradientData` (domain) | `String? center` | ARGB int 기반, 직렬화 |
| `CustomizationMapper` | center 양방향 매핑 | presentation ↔ domain 변환 |

### 2.4 방사형 렌더링 보정

```dart
// qr_preview_section.dart
final align = _gradientCenter(gradient.center); // String → Alignment
final radius = (align == Alignment.center) ? 0.5 : 1.4; // 비중앙은 큰 radius
RadialGradient(center: align, radius: radius, colors: colors, stops: stops)
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

편집기 진입 시 단색/그라디언트 팔레트 숨김, 하단 액션버튼 → 확인/취소로 교체.

```
[유형 ▾ 선형 ] [각도 ▾ 45°  ]     ← 드롭다운 한 행
                                    (방사형이면 [가운데 ▾ 중앙])

색 지점
  ● #FF0000  [삭제]
  ● #0000FF  [삭제]
  [+ 추가]

[██████●████████████████████●█████]  ← 통합 미리보기+슬라이더
  (그라디언트 바 위에 핸들 직접 배치)

          [취소]  [확인]
```

### 3.4 통합 미리보기+드래그 슬라이더 (`_GradientSliderBar`)

- `CustomPainter` + `GestureDetector` 단일 컴포넌트
- 그라디언트 바 (높이 36px, 라운드 8px) 위에 핸들이 바 하단 경계에 위치
- 핸들: 흰색 배경 + 색상 원 + 테두리 (반경 9px, 활성 시 11px)
- 드래그 시 핸들 확대 + 파란 테두리 활성화
- 첫/마지막 핸들은 0.0/1.0 고정 (드래그 불가)
- 중간 핸들은 이전/다음 핸들 사이에서만 이동 가능
- 실시간 미리보기 갱신

### 3.5 편집기 모드 격리

- `onEditorModeChanged` 콜백: 부모(QrResultScreen)에 편집기 on/off 알림
- 부모: `_colorEditorMode` 상태 → `if (!_colorEditorMode) _ActionButtons(...)` 로 하단 버튼 제어
- 편집 시작 시 현재 그라디언트를 `_gradientBeforeEdit` 에 백업
- 취소 시 `onGradientChanged(_gradientBeforeEdit)` 로 복원

### 3.6 탭 전환 자동 확인

- `QrColorTabState` (public) + `GlobalKey<QrColorTabState>` 패턴
- 부모: `_tabController.addListener(_onTabChanged)`
- 색상 탭(index 2) 이외로 이동 시 `_colorTabKey.currentState?.confirmAndCloseEditor()` 호출
- `confirmAndCloseEditor()`: 편집기 열려있으면 확인(적용) 처리 후 닫기

---

## 4. 구현 순서

| Step | 작업 | 비고 |
|:----:|------|------|
| S1 | 기존 TabBar/TabBarView 제거 → SingleChildScrollView | qr_color_tab.dart |
| S2 | 단색 섹션: 헤더 + 팔레트 + 직접 선택 원형 버튼 | tabColorSolid 키 재사용 |
| S3 | 그라디언트 섹션: 헤더 + 프리셋 + 직접 선택 버튼 | tabColorGradient 키 재사용 |
| S4 | 편집기 스켈레톤 (`_buildCustomEditor` 메서드) | 별도 위젯 대신 메서드 |
| S5 | 유형+옵션 드롭다운 한 행 (`_buildTypeAndOptionRow`) | DropdownButtonFormField |
| S6 | 각도 드롭다운 (8개: 0~315) | 선형 시 표시 |
| S7 | 가운데 드롭다운 (5개) | 방사형 시 표시 |
| S8 | 색 지점 목록 (추가/삭제, 2~5개) | HSV 피커 연동 |
| S9+S10 | `_GradientSliderBar` 통합 컴포넌트 | 미리보기 바 + 드래그 핸들 |
| S11 | 편집기 → QrGradient 변환 → QrResultNotifier 반영 | center 필드 포함 |
| S12 | ARB 10개 파일, 14개 새 키 + 2개 기존 재사용 | 다국어 |
| S13 | 편집기 모드 격리 (팔레트 숨김 + 확인/취소) | onEditorModeChanged 콜백 |
| S14 | QrGradient/QrGradientData에 center 필드 추가 | 모델 + 매퍼 + 직렬화 |
| S15 | 방사형 비중앙 radius 1.4 보정 | qr_preview_section.dart |
| S16 | 탭 전환 자동 확인 (GlobalKey 패턴) | qr_result_screen.dart |

---

## 5. ARB 키 목록

| 키 | ko | en |
|---|------|------|
| `tabColorSolid` | 단색 | Solid | (기존 키 재사용) |
| `tabColorGradient` | 그라디언트 | Gradient | (기존 키 재사용) |
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
| `labelCenter` | 가운데 | Center |
| `optionCenterCenter` | 중앙 | Center |
| `optionCenterTopLeft` | 왼쪽 상단 | Top Left |
| `optionCenterTopRight` | 오른쪽 상단 | Top Right |
| `optionCenterBottomLeft` | 왼쪽 하단 | Bottom Left |
| `optionCenterBottomRight` | 오른쪽 하단 | Bottom Right |

---

## 6. 변경 파일 목록

| 파일 | 변경 |
|------|------|
| `lib/features/qr_result/tabs/qr_color_tab.dart` | 전면 재작성 |
| `lib/features/qr_result/qr_result_screen.dart` | 편집기 모드 + 탭 전환 자동 확인 |
| `lib/features/qr_result/domain/entities/qr_template.dart` | QrGradient center 필드 |
| `lib/features/qr_task/domain/entities/qr_gradient_data.dart` | QrGradientData center 필드 |
| `lib/features/qr_result/utils/customization_mapper.dart` | center 양방향 매핑 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | 방사형 center + radius 보정 |
| `lib/features/qr_result/data/datasources/local_default_template_datasource.dart` | center JSON 직렬화 |
| `lib/l10n/app_*.arb` (10개) | 14개 새 키 |

---

## 7. 검증 기준

| # | 항목 | 방법 |
|---|------|------|
| 1 | 서브탭 제거, 단일 스크롤 뷰 | UI 확인 |
| 2 | 단색 직접 선택 → HSV 피커 동작 | 색상 변경 확인 |
| 3 | 그라디언트 직접 선택 → 편집기 표시 | UI 확인 |
| 4 | 유형 전환 시 각도/가운데 드롭다운 토글 | 선형↔방사형 전환 |
| 5 | 색 지점 추가/삭제 (2~5개 범위) | 버튼 동작 |
| 6 | 통합 슬라이더바에서 stop 위치 드래그 | 실시간 미리보기 반영 |
| 7 | 편집 결과가 QR 미리보기에 반영 | 실시간 확인 |
| 8 | dart analyze 에러 0 | CLI |
| 9 | 편집기 모드 시 팔레트 숨김 + 확인/취소 표시 | UI 확인 |
| 10 | 취소 시 편집 전 그라디언트 복원 | 상태 확인 |
| 11 | 탭 전환 시 편집기 자동 확인 | 다른 탭 이동 후 복귀 |
| 12 | 방사형 비중앙(topLeft 등) 정상 렌더링 | QR 미리보기 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-17 | Initial design | tawool83 |
| 1.0 | 2026-04-17 | Do phase enhancements 반영: 드롭다운 레이아웃, 편집기 모드 격리, 탭 전환 자동 확인, 통합 슬라이더, center 필드, 방사형 radius 보정 | tawool83 |
