# Plan: QR 스타일 커스터마이징

## Executive Summary

| 관점 | 내용 |
|------|------|
| Problem | QR 코드가 항상 정사각형 도트 + 정사각형 눈(finder pattern)으로만 출력되어 시각적으로 단조로움 |
| Solution | 커스터마이징 패널에 도트 모양(원형/사각) · 눈 모양(원형/사각) · 중앙 아이콘(앱 아이콘/없음) 옵션 추가 |
| UX Effect | 선택 즉시 QR 미리보기 실시간 반영, 기존 색상 커스터마이징과 자연스럽게 통합 |
| Core Value | `qr_flutter` 기본 API만으로 구현 가능한 범위 내에서 최대 다양성, 추가 패키지 불필요 |

---

## 배경 및 현황

현재 `QrImageView` 파라미터:
```dart
eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: state.qrColor)
dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: state.qrColor)
```

`qr_flutter ^4.1.0` 지원 범위:
| 파라미터 | 옵션 |
|----------|------|
| `QrEyeShape` | `square`, `circle` |
| `QrDataModuleShape` | `square`, `circle` |
| `embeddedImage` | `ImageProvider` (중앙 아이콘) |
| `embeddedImageStyle` | `QrEmbeddedImageStyle(size: Size(...))` |

> **주의**: 구글 크롬 스타일(둥근 모서리 도트)은 `qr_flutter` 기본 API에서 지원하지 않음.
> `square`(정사각) + `circle`(완전 원형) 두 가지가 전부. 추가 모양이 필요하면 별도 패키지
> (`pretty_qr_code` 등) 도입이 필요하며, 이번 플랜에서는 기본 API 범위만 구현.

---

## 요구사항

### FR-1 도트(데이터 모듈) 모양 선택
- `square` (정사각형, 기본값) / `circle` (원형)
- 선택 시 QR 미리보기 즉시 갱신
- 커스터마이징 패널 내 토글 형태 UI

### FR-2 눈(finder pattern, 코너 3개) 모양 선택
- `square` (정사각형, 기본값) / `circle` (원형)
- 도트 모양과 독립적으로 선택 가능 (예: 눈=원형 + 도트=사각)
- 커스터마이징 패널 내 토글 형태 UI

### FR-3 중앙 아이콘 삽입
- 옵션: **없음** (기본값) / **앱 아이콘** (화면에 전달된 `appIconBytes`)
- `appIconBytes`가 null이면 앱 아이콘 옵션 비활성화
- 아이콘 크기: QR 크기의 약 20% (오류 정정 레벨 M 기준 안전 범위)
- 오류 정정 레벨을 `M → H`로 자동 상향 (아이콘이 QR 일부를 가리므로)

### FR-4 설정 영속성
- `SettingsService` / `SharedPreferences`에 마지막 선택 스타일 저장
  - 키: `qr_eye_shape`, `qr_data_module_shape`, `qr_embed_icon`
- 화면 진입 시 복원

### FR-5 TagHistory 저장
- `TagHistory`에 `qrEyeShape`(HiveField 11), `qrDataModuleShape`(HiveField 12), `qrEmbedIcon`(HiveField 13) 추가
- 기존 이력 하위 호환 유지 (기본값 fallback)

---

## 구현 범위

### 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/models/tag_history.dart` | HiveField 11~13 추가 |
| `lib/models/tag_history.g.dart` | build_runner 재생성 |
| `lib/features/qr_result/qr_result_provider.dart` | `QrResultState`에 `eyeShape`, `dataModuleShape`, `embedIcon` 추가; setter 메서드 추가 |
| `lib/features/qr_result/qr_result_screen.dart` | `QrImageView` 파라미터 반영; `_CustomizePanel`에 스타일 선택 UI 추가 |
| `lib/services/settings_service.dart` | QR 스타일 3개 키 저장/복원 메서드 추가 |

### 신규 파일
- 없음

---

## UI 설계

커스터마이징 패널 내 추가 섹션 (기존 색상·크기 아래):

```
[ QR 모양 ]

  데이터 도트    [■ 사각형]  [● 원형]
  눈(finder)    [■ 사각형]  [● 원형]

[ 중앙 아이콘 ]

  [없음]  [앱 아이콘]  ← appIconBytes가 null이면 앱 아이콘 비활성
```

- 선택 버튼: `SegmentedButton` 또는 `ChoiceChip` 2~3개
- 변경 시 `_recapture()` 호출 → 저장/공유/인쇄에 반영

---

## 기술 제약 사항

1. **중앙 아이콘 + 오류 정정**: 아이콘 삽입 시 `errorCorrectionLevel: QrErrorCorrectLevel.H` 강제 설정 (기존 M → H). QR 크기가 약간 커질 수 있음.
2. **`qr_flutter` 패키지 업그레이드 불필요**: 현재 `^4.1.0`으로 모든 기능 지원.
3. **"구글 크롬 스타일" 미지원**: 둥근 모서리 사각형(rounded square) 도트는 `qr_flutter` 기본 API 범위 밖. 필요 시 `pretty_qr_code` 패키지 별도 도입 필요 (이번 범위 외).

---

## 비기능 요구사항

- 커스터마이징 패널 접힌 상태 유지 (기존 동작 변경 없음)
- Hive 어댑터 하위 호환 (기존 이력 null → 기본값 fallback)
- `_recapture()` 호출 횟수 최소화 (색상·스타일 변경 시 각 1회)
