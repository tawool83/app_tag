# Plan — Band QR Robustness (logo-text-unification 후속)

> 생성일: 2026-04-28
> Feature ID: `band-qr-robustness`
> 부모 feature: `logo-text-unification` (v0.7 In Progress)
> 트리거 이슈: 가로/세로 띠 사용 시 가끔 인식 실패

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 가로/세로 띠 두께가 QR 의 15% 로 burst error 한도에 근접 + 짧은 데이터(작은 QR 버전) 에서는 띠가 finder/timing pattern 영역과 겹쳐 디코더가 QR 자체를 인식 못 함 |
| **Solution** | (1) 띠 두께 상수 15% → **12%** 축소 (실효 정정 capacity 안쪽 진입), (2) 띠 사용 시 QR **typeNumber ≥ V5 강제** (37×37) 로 finder/timing 침범 방지 |
| **Function UX Effect** | 띠 두께 약간 얇아짐 (자동 폰트 피팅이 비례 축소). 짧은 데이터로 띠 사용 시 QR 모듈이 약간 빽빽해짐 (V1~V4 → V5). 띠 미사용 시 동작 변화 없음 |
| **Core Value** | 띠 사용 시 인식률 ≈99%+ 안정화, 빈번한 reject 사례 제거 |

---

## 1. Background

### 1.1 현재 동작
- 띠 두께: `qrSize × 0.15` 상수 (3개 위치)
- QR 버전: `QrCode.fromData(data, ecLevel)` 자동 산출 (데이터 길이 기반 최소 버전)
- 띠 사용 시 ECL: 이미 H 강제 ✅ (`hasBand` 조건)

### 1.2 실패 케이스 분석
- ECL H = ~30% 정정. 띠 면적 = 15%.
- **이론상**: 15% < 30% → 인식 가능
- **실제**: burst error 의 실효 capacity ≈ 15~20% (RS 블록 단위 한계)
- **추가 위험**: 작은 QR 버전 (V1~V3) 에서는 띠 한 줄(3 모듈)이 finder pattern (7×7) 의 거의 절반을 침범 → 디코더가 finder 인식 실패 → 디코딩 자체 불가

### 1.3 누락된 ECL 승격
- `qr_layer_stack.dart::_qrImageFor` (custom painter 경로): `hasBand` 시 H 강제 ✅
- `qr_preview_section.dart::buildPrettyQr` (pretty_qr 경로): `hasLogo` 만 보고 H 승격, **`hasBand` 누락** ⚠️
  → 사용자가 띠만 사용 (custom eye/boundary/animation 없음) 시 pretty_qr 경로 → ECL M 으로 떨어짐 → 인식 실패 빈도 ↑
- 이 plan 에서 함께 수정

---

## 2. 변경 사항

### 2.1 띠 두께 15% → 12%

**근거**:
- burst error 실효 capacity (15~20%) 안쪽 진입
- finder pattern (7×7 = 전체의 ~33% in V1, ~12% in V5) 침범 위험 감소
- 폰트 자동 피팅이 비례 축소 → 사용자 가시 차이 작음

**영향 위치 (3곳)**:
- `lib/features/qr_result/utils/logo_clear_zone.dart:85` — `qrSize.width * 0.15`
- `lib/features/qr_result/widgets/qr_layer_stack.dart:616` — `qrSize * 0.15` (band content max font 산출)
- `lib/features/qr_result/widgets/qr_layer_stack.dart:723` — `qrSize * 0.15` (텍스트 단독 모드 max font)

상수화 제안: `kBandMaxRatio = 0.12` 로 한 곳에 모음 (e.g., `lib/features/qr_result/utils/qr_layout_constants.dart` 신규).

### 2.2 QR 버전 minimum 강제 (V5)

**근거**:
- V5 = 37×37 모듈
- 띠 12% 두께 = 약 4.4 모듈 (V5 기준) → finder (7×7) 와 충분한 여유
- 자동 산출이 V5 이상이면 무영향 (대부분 deeplink 는 자동으로 V5+ 산출됨)
- 짧은 데이터 (예: 단순 텍스트 "안녕") + 띠 사용 시에만 영향

**적용 조건**: `hasBand == true` 일 때만 (띠 미사용 시 자동 산출 그대로)

**API 강제 방법** (qr 패키지):
```dart
// 1) 자동 산출 시도
var qrCode = QrCode.fromData(data: deepLink, errorCorrectLevel: ecLevel);
// 2) 자동 산출이 minimum 미만이면 강제 재생성
if (hasBand && qrCode.typeNumber < 5) {
  qrCode = QrCode(5, ecLevel)..addData(deepLink);
}
```

### 2.3 buildPrettyQr 경로의 ECL 누락 수정

`qr_preview_section.dart:buildPrettyQr` 의 `ecLevel` 산출에 `hasBand` 추가:

```dart
final hasBand = state.sticker.bandMode != BandMode.none && ...;
final ecLevel = (hasLogo || hasBand) ? H : M;
```

### 2.4 buildPrettyQr 경로의 typeNumber 미지원 — 우회

`pretty_qr_code` 패키지의 `PrettyQrView.data()` 는 typeNumber 를 외부에서 강제할 수 없음 (내부에서 `QrCode.fromData` 호출).

**해결**: `_useCustomPainter()` 에 `_hasBand(sticker)` OR 조건 추가 → 띠 사용 시 항상 custom painter 경로로 라우팅. 그러면 `_qrImageFor()` 에서 typeNumber 강제 가능.

부작용: 띠만 사용해도 custom painter 사용 → 도트 렌더가 polygon 기반 (`_PolarDotSymbol`) 으로 전환. 이전에 `DotShapeParams.square.scale = √2` 로 폴리곤이 PrettyQrSmoothSymbol 과 시각 동일하게 만들어둠 → 시각 차이 거의 없음.

---

## 3. Architecture (CLAUDE.md 고정)

- Framework: Flutter
- 상태 관리: Riverpod StateNotifier (이번 작업은 순수 유틸/렌더 수정, 신규 Notifier 없음)
- 신규 feature 디렉터리 없음 — 기존 utils/widgets 수정
- R-series 패턴 영향 없음

---

## 4. 변경 파일 (예상 4개)

| 파일 | 변경 |
|------|------|
| `lib/features/qr_result/utils/logo_clear_zone.dart` | `0.15` → `0.12` 상수 (또는 신규 상수 모듈 참조) + 주석 |
| `lib/features/qr_result/widgets/qr_layer_stack.dart` | (a) `_qrImageFor()` 시그니처에 `int? minTypeNumber` 추가, 캐시 키 확장, typeNumber 강제 로직 (b) `_useCustomPainter()` 에 `_hasBand` 추가 (c) 두 곳의 `qrSize * 0.15` → `0.12` (d) 호출처에서 `minTypeNumber: hasBand ? 5 : null` 전달 |
| `lib/features/qr_result/utils/qr_svg_generator.dart` | `generate()` 에 `int minTypeNumber = 1` 인자 추가 + typeNumber 강제 로직 (SVG export 도 동일 정책) |
| `lib/features/home/widgets/qr_task_action_sheet.dart` | `_saveAsSvg` 에서 `QrSvgGenerator.generate(..., minTypeNumber: hasBand ? 5 : 1)` 전달 |
| (선택) `lib/features/qr_result/widgets/qr_preview_section.dart` | `buildPrettyQr` 의 `ecLevel` 산출에 `hasBand` 추가 — **단**, 위 (b) 의 `_useCustomPainter` 변경으로 띠 사용 시 buildPrettyQr 경로 미진입 → 이 수정은 안전망 차원 |

총 4~5개 파일, ~50줄 변경 (대부분 함수 시그니처 + 한두 곳 if 분기).

---

## 5. 세부 결정 (자동 확정)

| 항목 | 결정 | 근거 |
|------|------|------|
| 띠 두께 비율 | `0.12` | 사용자 합의, burst capacity 안쪽 |
| QR minimum 버전 | `5` (37×37) | 띠 12% = 4.4 모듈 < V5 의 finder 비율 12% 여유 |
| 적용 조건 | 띠 사용 시에만 | 짧은 데이터로 띠 미사용하는 일반 케이스는 영향 없음 |
| SVG export 정책 | 동일 (12% + V5 강제) | 화면·SVG 일관성 |
| 호환성 | **무시** (사용자 지시) | 두께는 코드 상수, 사용자 저장 데이터 영향 없음 |
| 구버전 빌드 | 무영향 | 신규 빌드부터 적용 |

---

## 6. 구현 순서

### Step 1 — 상수 정리 (선택)
- `lib/features/qr_result/utils/qr_layout_constants.dart` 신규
- `kBandMaxRatio = 0.12`, `kBandMinTypeNumber = 5` 정의
- 또는 각 파일에서 직접 0.12 사용 (간단)

### Step 2 — `qr_layer_stack.dart`
- `_useCustomPainter` 에 `_hasBand(state.sticker)` 추가
- `_qrImageFor` 시그니처 + typeNumber 강제 로직
- 두 곳의 `0.15` → `0.12`
- `_buildCustomQr`, `_buildFrameQrPainter` 에서 `_qrImageFor` 호출 시 `minTypeNumber` 전달

### Step 3 — `logo_clear_zone.dart`
- `0.15` → `0.12` + 주석 업데이트

### Step 4 — `qr_svg_generator.dart`
- `generate()` 인자 추가 + 강제 로직

### Step 5 — `qr_task_action_sheet.dart`
- `_saveAsSvg` 에서 hasBand 판정 + `minTypeNumber` 전달

### Step 6 — `qr_preview_section.dart` (안전망)
- `ecLevel` 산출에 `hasBand` 추가 (이론상 진입 안 함)

---

## 7. 검증 플랜

### 컴파일
- [ ] `flutter analyze` → 0 issue (변경 파일)

### 시각/렌더 검증
- [ ] 띠 미사용 (단순 QR): 동작 변화 없음
- [ ] 띠 사용 + 짧은 데이터 (예: "Hi" → 자동 V1): QR 이 V5 로 표시됨
- [ ] 띠 사용 + 긴 데이터 (예: 100자 이상 deeplink): 자동 ≥ V5, V 그대로
- [ ] 띠 두께 시각: 기존보다 약간 얇음 (15% → 12%)

### 인식률 검증 (수동)
- [ ] 짧은 데이터 + 띠: 다양한 QR 스캐너 (iOS 카메라, Android 카메라, Google Lens) 로 인식 성공률 측정 → 이전 ≈85% → 목표 ≈99%+
- [ ] 긴 데이터 + 띠: 동일

### SVG export
- [ ] SVG 저장 후 외부 브라우저에서 인식 가능

---

## 8. 위험·전제

### 위험
1. **V5 강제 시 시각 변화**: 짧은 데이터 사용자가 "왜 더 복잡해 보이지?" 라고 느낄 수 있음 — 단, 띠 사용자에 한정.
2. **typeNumber 데이터 한계**: V5 의 ECL H 데이터 용량 ≈ 78 영문자 / 46 한글. 데이터가 이를 초과하면 자동으로 더 큰 V 산출 → 무영향. 단, V5 보다 큰 V 필요 시 자동 산출에 위임.
3. **pretty_qr 경로로 띠 사용 시 버그 잔존**: `_useCustomPainter` 에 `_hasBand` 추가 안 하면 buildPrettyQr 경로로 가서 typeNumber 강제 불가. → Step 2 의 (b) 가 핵심.

### 전제
- `qr` 패키지의 `QrCode(typeNumber, ecLevel)` 생성자 + `addData()` 사용 가능 (확인 완료)
- `QrCode.fromData()` 의 자동 산출 결과 typeNumber 가 minimum 보다 작으면 재생성하는 패턴 안전 (typeNumber 강제 시 데이터가 안 들어가면 throw — 이 경우 자동 산출이 더 큰 V 이므로 발생 안 함)
- 사용자 저장 데이터에 띠 두께 별도 설정 없음 (코드 상수) → 마이그레이션 불필요

---

## 9. Out-of-Scope

- 띠 위치를 finder/timing 영역 회피하도록 동적 배치 (복잡도 ↑, 효과는 V5 강제로 충분)
- 데이터 길이별 띠 두께 동적 산출 (일괄 12% 로 단순화)
- 사용자가 띠 두께를 직접 조정하는 UI (상수 유지)
- 광고/결제 등 무관 항목

---

## 10. Next Steps

1. 사용자 승인 → `/pdca design band-qr-robustness` (간단한 변경이라 design 생략 가능 → 바로 `/pdca do`)
2. Step 1~6 순차 구현
3. 인식률 회귀 테스트 (수동)
