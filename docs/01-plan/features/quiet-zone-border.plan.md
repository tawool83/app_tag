# quiet-zone-border Plan

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | QR 코드의 quiet zone 영역에 시각적 경계가 없어, 밝은 배경에서 QR이 뚜렷하게 구분되지 않음 |
| **Solution** | 배경 탭에 quiet zone 테두리선 토글 + 두께 설정 추가, 색상은 색상 탭의 "배경" 모드에서 기존 bgColor와 함께 제어 |
| **Function UX Effect** | 테두리 ON/OFF + 두께 슬라이더 조작 → QR 외곽에 즉시 테두리선 렌더링 |
| **Core Value** | 인쇄물·명함에 QR을 넣을 때 깔끔한 경계선으로 브랜드 품질 향상 |

---

## 1. 요구사항

### 1.1 기능 정의
- quiet zone(QR 도트 영역 바깥, 배경색 채워진 여백) 가장자리에 테두리선(border)을 그리는 기능
- 테두리선 활성/비활성 토글
- 테두리선 두께 조절 (1~4px, 기본 1px)
- 테두리선 색상 = 색상 탭 "배경" 모드(`ColorTargetMode.bgOnly`)에서 설정하는 `bgColor`와 동일

### 1.2 UX 흐름
1. **배경 탭**: 기존 외곽 프리셋 영역 아래에 "테두리선" 섹션 추가
   - 토글 스위치: ON/OFF
   - 두께 슬라이더: 1~4px (토글 ON일 때만 표시)
2. **색상 탭**: 기존 "배경" 세그먼트(`bgOnly`) 선택 시, 배경 패턴 색상과 동시에 테두리선 색상도 변경됨 (별도 UI 불필요)

### 1.3 비적용 범위
- 프레임 모드(`isFrameMode`)에서는 테두리선 미적용 (프레임이 이미 테두리 역할)
- 테두리선 모양(둥근 모서리 등)은 이번 scope 밖 — 항상 직사각형

---

## 2. 영향 분석

### 2.1 State 변경

**`QrStyleState`** (기존 sub-state에 2개 필드 추가):
- `bool quietZoneBorderEnabled` (기본값: `false`)
- `double quietZoneBorderWidth` (기본값: `1.0`, 범위 1.0~4.0)

테두리선 색상은 별도 필드 불필요 — 기존 `bgColor ?? qrColor` 를 따름.

### 2.2 영속화 변경

**`QrCustomization`** (도메인 직렬화):
- `bool? quietZoneBorderEnabled` (null/false = 비활성)
- `double? quietZoneBorderWidth` (null = 기본 1.0)

**`CustomizationMapper`**: `fromState` / 복원 시 2개 필드 매핑 추가.

### 2.3 렌더링 변경

**`QrLayerStack`** 일반 경로:
- `qrSquare` SizedBox에 `Container.decoration` 으로 `Border.all` 추가
- 조건: `quietZoneBorderEnabled && !isFrameMode`
- 색상: `state.style.bgColor ?? state.style.qrColor`
- 두께: `state.style.quietZoneBorderWidth`

**`QrLayerStack` 프레임 경로**:
- 변경 없음 (프레임이 이미 외곽 역할)

**PNG 내보내기**:
- `QrLayerStack`이 렌더링을 담당하므로 별도 처리 불필요

### 2.4 UI 변경

**배경 탭 (`qr_background_tab.dart`)**:
- 프리셋 섹션 아래에 "테두리선" 섹션 추가
- `SwitchListTile` + `_SliderRow` (조건부)

**색상 탭**:
- 변경 없음 (기존 `bgOnly` 색상이 자동 적용)

### 2.5 Notifier 변경

**`style_setters.dart`**:
- `setQuietZoneBorderEnabled(bool)`
- `setQuietZoneBorderWidth(double)`

---

## 3. 구현 순서

1. `QrStyleState` 에 2개 필드 추가 + `copyWith` / `==` / `hashCode`
2. `QrCustomization` 에 2개 필드 추가 + `toJson` / `fromJson` / `copyWith`
3. `CustomizationMapper.fromState` / 복원 매핑
4. `style_setters.dart` 에 setter 2개 추가
5. `qr_layer_stack.dart` 일반 경로에 테두리 렌더링
6. `qr_background_tab.dart` 에 토글 + 슬라이더 UI
7. `app_ko.arb` 에 l10n 키 추가

---

## 4. 기술 결정

| 항목 | 결정 | 근거 |
|------|------|------|
| 테두리 색상 저장 | 별도 필드 없음, bgColor 재사용 | 사용자 요구 "색상 탭 배경에서 같이 설정" |
| 프레임 모드 제외 | 적용 안 함 | 프레임 자체가 외곽 장식 역할 |
| 두께 범위 | 1~4px | 4px 초과 시 quiet zone 침범 → 스캔 신뢰도 저하 |
| 기본값 | 비활성 | 기존 동작 유지 (하위 호환) |

---

## 5. 프로젝트 메타

- **Level**: Flutter Dynamic x Clean Architecture x R-series
- **State Management**: Riverpod StateNotifier
- **로컬 저장**: Hive
- **라우팅**: go_router
