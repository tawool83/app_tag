# Plan: QR Layer Editor

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | QR 꾸미기 옵션이 단일 탭에 혼재해 UX가 복잡하고, 배경 이미지·스티커·나만의 템플릿 저장 기능이 없어 창의적 QR 제작이 불가능하다. |
| **Solution** | 레이어 개념을 기반으로 탭을 5개로 재구성(전체 템플릿/배경화면/QR/스티커/나의 템플릿)하고, 현재 설정을 템플릿으로 저장·재사용하는 기능을 추가한다. |
| **Functional UX Effect** | 사용자는 레이어 순서대로 탭을 이동하며 직관적으로 QR을 꾸미고, 완성된 스타일을 '나의 템플릿'으로 저장해 다음 QR 생성 시 1탭으로 재적용할 수 있다. |
| **Core Value** | 단순 QR 생성 도구에서 개인화된 브랜드 QR 제작 플랫폼으로 진화. 향후 유료 플랜(클라우드 동기화)의 기반 데이터 모델을 확립한다. |

---

## 1. 배경 및 목적

### 1.1 현황 문제점

현재 QR 결과 화면은 3탭 구조(추천 / 꾸미기 / 전체 템플릿)로, 꾸미기 탭 안에 색상·그라디언트·도트·눈 모양·중앙 아이콘·레이블·인쇄 크기가 모두 집중되어 있다.

- **복잡성**: 스크롤이 길고 설정 항목 간 연관성이 시각적으로 불명확
- **레이어 개념 부재**: 배경 이미지 위에 QR, 그 위에 스티커가 쌓이는 레이어 구조가 드러나지 않음
- **재사용 불가**: 공들여 꾸민 QR 스타일을 저장해 다음에 재사용할 방법이 없음
- **배경 이미지 미지원**: 갤러리 사진을 QR 배경으로 사용하는 기능 없음
- **스티커 미지원**: 로고 위치 제어, 상단/하단 텍스트 추가 불가

### 1.2 목표

1. **탭 재구조화**: 레이어 개념 기반 5탭으로 재편, 추천 탭 제거
2. **배경화면 레이어**: 갤러리 이미지 불러오기 + 자유 비율 crop + 크기 조정
3. **QR 레이어**: 기존 꾸미기의 도트·눈·색상 설정을 독립 탭으로 분리
4. **스티커 레이어**: 로고 위치/배경 제어 + 상단·하단 텍스트 전체 커스터마이징
5. **나의 템플릿**: 현재 레이어 설정을 로컬 저장·재사용 (클라우드 구조 준비)
6. **액션 버튼 정리**: 갤러리저장 / 템플릿저장 / 공유 (인쇄·저장 버튼 제거)

---

## 2. 범위 정의

### 2.1 이번 범위 (In Scope)

| 카테고리 | 항목 |
|----------|------|
| UI 구조 | 5탭 재편, 추천 탭 제거, 액션 버튼 3개로 정리 |
| 배경화면 탭 | 갤러리 이미지 선택, 자유 비율 crop, 크기/위치 조정 |
| QR 탭 | 도트 모양·둥글기, 눈 모양, 색상/그라디언트, 콰이어트 존 여백 색상 |
| 스티커 탭 | 로고(위치: 중앙/우하단, 배경: 없음/사각/원형) + 텍스트(상단/하단, 내용·위치·색상·폰트·크기) |
| 나의 템플릿 | 레이어 설정 로컬 저장(Hive), 저장 목록 표시, 재적용, 삭제 |
| 데이터 모델 | `UserQrTemplate` 모델 + 클라우드 동기화 대비 구조 설계 |
| 렌더링 | 3개 레이어 합성 (배경 → QR → 스티커) RepaintBoundary 캡처 |

### 2.2 이번 범위 제외 (Out of Scope)

| 항목 | 이유 |
|------|------|
| 사용자 인증·로그인 | 별도 피처로 분리 |
| 클라우드 동기화 (Supabase) | 유료 플랜 단계 — 데이터 구조만 준비 |
| 인쇄 기능 | 액션 버튼 정리로 제거 |
| 히스토리 저장(TagHistory) 변경 | 기존 로직 유지 |
| 전체 템플릿 탭 내용 변경 | 위치만 1번째로 이동 |

---

## 3. 사용자 시나리오

### 시나리오 A: 배경 이미지 QR 제작

1. 앱 선택 → QR 결과 화면 진입
2. **전체 템플릿** 탭에서 기본 QR 스타일 선택 (또는 스킵)
3. **배경화면** 탭 → 갤러리에서 사진 선택 → 자유 비율 crop → 확인
4. **QR** 탭 → 도트 모양 원형 선택, 색상 파란색 설정
5. **스티커** 탭 → 로고 우하단 배치, 하단 텍스트 "Scan Me" 입력, 흰색 설정
6. **템플릿저장** 버튼 → "내 카페 QR" 이름으로 저장
7. **갤러리저장** 버튼 → 완성된 QR 저장

### 시나리오 B: 나의 템플릿 재사용

1. 새 앱 선택 → QR 결과 화면 진입
2. **나의 템플릿** 탭 → "내 카페 QR" 선택 → 즉시 적용
3. **갤러리저장** → 완료

---

## 4. 기능 요구사항

### 4.1 탭 구조 변경

**현재** → **변경 후**

```
[추천] [꾸미기] [전체 템플릿]
   ↓
[전체 템플릿] [배경화면] [QR] [스티커] [나의 템플릿]
```

- `TabController` length: 3 → 5
- 기본 선택 탭: 전체 템플릿 (index 0)
- 추천 탭(`recommended_tab.dart`) 제거
- 꾸미기 탭(`customize_tab.dart`) 해체 → 배경화면/QR/스티커 탭으로 분리

### 4.2 액션 버튼 변경

**현재**: 갤러리저장 / 공유 / 인쇄 / 저장
**변경 후**: 갤러리저장 / 템플릿저장 / 공유

- 인쇄 버튼 제거 (QR 화면 내 인쇄 기능 삭제)
- 저장(TagHistory) 버튼 제거 — 히스토리 자동 저장은 유지
- **템플릿저장** 신규 추가: 바텀시트로 이름 입력 → `UserQrTemplate`로 Hive 저장

### 4.3 배경화면 탭 (`background_tab.dart`)

```
┌──────────────────────────────────┐
│  [+ 이미지 불러오기]              │  ← 갤러리 피커 (image_picker)
│                                  │
│  ┌──────────────────────────┐    │
│  │   crop 미리보기           │    │  ← 자유 비율 (crop_your_image 등)
│  │   (선택 이미지 표시)       │    │
│  └──────────────────────────┘    │
│                                  │
│  크기: [──●──────────] 100%      │  ← 슬라이더 (배경 스케일)
│  [이미지 제거]                    │
└──────────────────────────────────┘
```

- 패키지: `image_picker` (기존 사용 여부 확인), `crop_your_image` 또는 `image_cropper`
- 선택한 이미지 bytes → `QrResultState.backgroundImageBytes`
- crop 완료 이미지를 `Uint8List`로 저장
- 자유 비율 crop 지원

### 4.4 QR 탭 (`qr_style_tab.dart`)

기존 꾸미기 탭에서 QR 관련 설정만 분리:

```
┌──────────────────────────────────┐
│  도트 모양                        │
│  [사각] [원형] [다이아] [별] ...  │
│                                  │
│  도트 둥글기: [──●──────] 0.5    │
│                                  │
│  눈 모양                          │
│  [사각형] [둥글기] [원형] [부드럽] │
│                                  │
│  색상                             │
│  [단색 | 그라디언트] 토글          │
│  [● ● ● ● ● ● ● ●] 팔레트       │
│                                  │
│  콰이어트 존 배경색               │
│  [흰색] [투명] [커스텀]           │
└──────────────────────────────────┘
```

- 기존 `QrEyeStyle`, `roundFactor`, `qrColor`, `customGradient` 유지
- 콰이어트 존(quiet zone) 배경색 옵션 신규 추가: `quietZoneColor` 상태 추가

### 4.5 스티커 탭 (`sticker_tab.dart`)

```
┌──────────────────────────────────┐
│  로고                             │
│  위치: [중앙] [우하단]            │
│  배경: [없음] [사각] [원형]       │
│  [앱 기본 아이콘] [이모지 선택]   │
│                                  │
│  상단 텍스트                      │
│  [텍스트 입력창]                  │
│  색상: [● ● ● ●]                 │
│  폰트: [Sans] [Serif] [Mono]      │
│  크기: [──●──────] 14sp           │
│                                  │
│  하단 텍스트                      │
│  (동일 구조)                      │
└──────────────────────────────────┘
```

**로고 옵션**:
- `logoPosition`: `center` | `bottomRight`
- `logoBackground`: `none` | `square` | `circle`

**텍스트 옵션** (상단/하단 각각):
- `topText`: 내용, 색상(`Color`), 폰트패밀리, 크기(`double`)
- `bottomText`: 동일 구조

### 4.6 나의 템플릿 탭 (`my_templates_tab.dart`)

```
┌──────────────────────────────────┐
│  나의 템플릿 (3개)                │
│  ┌────┐ ┌────┐ ┌────┐            │
│  │ QR │ │ QR │ │ QR │            │
│  │    │ │    │ │    │            │
│  └────┘ └────┘ └────┘            │
│  내 카페  브랜드  기본            │
│  [적용] [적용] [적용]             │
│  (롱프레스 → 삭제)               │
└──────────────────────────────────┘
```

- 저장된 `UserQrTemplate` 목록을 그리드로 표시
- 탭 → 즉시 적용 (모든 레이어 설정 복원)
- 롱프레스 → 삭제 확인 다이얼로그

### 4.7 나의 템플릿 저장 (`UserQrTemplate`)

```dart
@HiveType(typeId: 2)
class UserQrTemplate {
  @HiveField(0) String id;           // UUID
  @HiveField(1) String name;         // 사용자 입력 이름
  @HiveField(2) DateTime createdAt;

  // 배경 레이어
  @HiveField(3) Uint8List? backgroundImageBytes;  // 자유 비율 crop 결과
  @HiveField(4) double backgroundScale;

  // QR 레이어
  @HiveField(5) int qrColorValue;      // Color.value
  @HiveField(6) String? gradientJson;  // QrGradient JSON
  @HiveField(7) double roundFactor;
  @HiveField(8) int eyeStyleIndex;     // QrEyeStyle.index
  @HiveField(9) int quietZoneColorValue;

  // 스티커 레이어
  @HiveField(10) int logoPositionIndex;   // center=0, bottomRight=1
  @HiveField(11) int logoBackgroundIndex; // none=0, square=1, circle=2
  @HiveField(12) String? topText;
  @HiveField(13) int? topTextColorValue;
  @HiveField(14) String? topTextFont;
  @HiveField(15) double? topTextSize;
  @HiveField(16) String? bottomText;
  @HiveField(17) int? bottomTextColorValue;
  @HiveField(18) String? bottomTextFont;
  @HiveField(19) double? bottomTextSize;

  // 클라우드 동기화 대비 (미사용 - 향후 활성화)
  @HiveField(20) String? remoteId;     // Supabase UUID (미래)
  @HiveField(21) bool syncedToCloud;   // 동기화 여부 (미래)
}
```

---

## 5. 레이어 렌더링 아키텍처

```
RepaintBoundary
└── Stack
    ├── [0] 배경 레이어
    │       Image(backgroundImageBytes, fit: BoxFit.cover, scale: backgroundScale)
    │       또는 Container(color: Colors.white) if null
    │
    ├── [1] QR 레이어
    │       Container(color: quietZoneColor, padding: quietZonePadding)
    │       └── buildPrettyQr(state, ...) — 기존 함수 재사용
    │
    └── [2] 스티커 레이어
            ├── Positioned(상단 텍스트)
            ├── Positioned(로고: center or bottomRight)
            └── Positioned(하단 텍스트)
```

- 기존 `buildPrettyQr()` 재사용 (변경 없음)
- `QrPreviewSection` 내부 Stack 구조 확장
- 캡처 시 모든 레이어 합성된 결과를 PNG로 저장

---

## 6. 상태 관리 변경 (`QrResultState`)

### 신규 추가 필드

```dart
// 배경 레이어
final Uint8List? backgroundImageBytes;  // 갤러리 이미지 (crop 결과)
final double backgroundScale;           // 배경 스케일 (0.5~2.0, default 1.0)

// QR 레이어
final Color quietZoneColor;             // 콰이어트 존 배경색 (default: white)

// 스티커 레이어
final LogoPosition logoPosition;        // center | bottomRight
final LogoBackground logoBackground;    // none | square | circle
final StickerText? topText;             // 상단 텍스트
final StickerText? bottomText;          // 하단 텍스트
```

```dart
class StickerText {
  final String content;
  final Color color;
  final String fontFamily;
  final double fontSize;
}

enum LogoPosition { center, bottomRight }
enum LogoBackground { none, square, circle }
```

### 기존 필드 유지

- `qrColor`, `customGradient`, `templateGradient`, `roundFactor`, `eyeStyle`
- `embedIcon`, `defaultIconBytes`, `emojiIconBytes`, `templateCenterIconBytes`
- `customLabel`, `printTitle`, `printSizeCm`

### 제거 필드

- `printSizeCm` — 인쇄 기능 제거에 따라 향후 제거 (이번은 유지, 호환성)

---

## 7. 신규 파일 목록

| 파일 | 역할 |
|------|------|
| `lib/features/qr_result/tabs/background_tab.dart` | 배경화면 탭 UI |
| `lib/features/qr_result/tabs/qr_style_tab.dart` | QR 스타일 탭 UI (기존 customize_tab 분리) |
| `lib/features/qr_result/tabs/sticker_tab.dart` | 스티커 탭 UI |
| `lib/features/qr_result/tabs/my_templates_tab.dart` | 나의 템플릿 탭 UI |
| `lib/models/user_qr_template.dart` | UserQrTemplate Hive 모델 |
| `lib/models/user_qr_template.g.dart` | Hive 어댑터 (자동생성) |
| `lib/models/sticker_text.dart` | StickerText, LogoPosition, LogoBackground 정의 |
| `lib/repositories/user_template_repository.dart` | 나의 템플릿 CRUD (Hive) |
| `lib/features/qr_result/widgets/qr_layer_stack.dart` | 3레이어 Stack 렌더링 위젯 |

### 수정 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `lib/features/qr_result/qr_result_provider.dart` | 신규 상태 필드 추가, 신규 setter 추가 |
| `lib/features/qr_result/qr_result_screen.dart` | 5탭 구조, 액션 버튼 변경, 탭 연결 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | QrLayerStack으로 교체 |
| `lib/models/tag_history.dart` | (필요시 신규 필드 추가) |

### 제거 파일

| 파일 | 이유 |
|------|------|
| `lib/features/qr_result/tabs/recommended_tab.dart` | 추천 탭 제거 |
| `lib/features/qr_result/tabs/customize_tab.dart` | 역할 분리로 해체 |

---

## 8. 의존성 추가

| 패키지 | 용도 | 비고 |
|--------|------|------|
| `image_picker` | 갤러리 이미지 선택 | 기존 사용 여부 확인 필요 |
| `image_cropper` 또는 `crop_your_image` | 자유 비율 crop UI | 결정 필요 |
| `google_fonts` (선택) | 텍스트 스티커 폰트 선택 | 번들 크기 고려 |

---

## 9. 기술 제약 및 고려사항

### 9.1 배경 이미지 저장 용량

- `UserQrTemplate.backgroundImageBytes`: crop된 이미지를 `Uint8List`로 Hive 저장
- 이미지 크기는 저장 전 압축 필요 (예: 최대 800×800, JPEG 80%)
- Hive 단일 박스 항목 크기 제한 없음, 단 앱 전체 Hive 용량 모니터링 필요

### 9.2 렌더링 성능

- 배경 이미지 + QR + 스티커 3개 레이어 합성 — `RepaintBoundary` 유지
- 미리보기 QR 크기: 기존 160px 유지
- 레이어 Stack이 추가되므로 `ValueKey` 해시 대상에 배경·스티커 상태 포함

### 9.3 클라우드 대비 구조

- `UserQrTemplate.remoteId`, `syncedToCloud` 필드를 처음부터 포함
- 향후 인증 피처 완료 후 Supabase `user_templates` 테이블과 연동

### 9.4 기존 기능 유지

- `TagHistory` 자동 저장: 변경 없음
- `validateQrData` 150자 제한: 변경 없음
- 전체 템플릿(서버 템플릿) 로직: 변경 없음

---

## 10. 성공 기준

| 기준 | 측정 방법 |
|------|-----------|
| 5탭 구조 정상 동작 | 탭 전환 시 각 레이어 설정이 독립적으로 유지됨 |
| 배경 이미지 자유 crop → QR에 반영 | 갤러리 선택 → crop → 미리보기 즉시 반영 |
| 3레이어 합성 캡처 | 갤러리저장 결과 이미지에 배경+QR+스티커 모두 포함 |
| 나의 템플릿 저장·재적용 | 저장 후 앱 재시작 시에도 목록 유지, 재적용 시 모든 레이어 설정 복원 |
| 인쇄·저장 버튼 제거 | 액션 버튼 3개만 표시 |
| 기존 기능 회귀 없음 | QR 생성·저장·공유·deepLink 검증 정상 동작 |
