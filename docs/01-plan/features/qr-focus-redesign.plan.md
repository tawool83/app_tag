# Plan: QR 화면 재설계 & Supabase 템플릿 시스템

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | QR 결과 화면이 단순 출력 → 저장에 그쳐, 앱의 핵심 가치인 "아름다운 QR 생성"이 부각되지 않음 |
| **Solution** | 화면 상단에 소형 QR 미리보기를 고정하고, 하단 전체를 탭 기반 꾸미기 패널로 전환 |
| **UX Effect** | 진입 즉시 꾸미기 모드 → 사용자 체류 시간 증가 및 QR 커스터마이징 중심 앱으로 포지셔닝 |
| **Core Value** | Supabase 기반 템플릿 시스템으로 앱 업데이트 없이 신규 템플릿 추가·배포 가능 |

> **최종 구현 기준으로 업데이트됨** (2026-04-13)  
> 아이 모양 QrEyeStyle enum 도입 / 그라디언트 커스터마이징 추가 / 템플릿 썸네일 동일 렌더링 엔진 적용

---

## 1. 배경 및 목표

### 1.1 현재 상태

- QR 결과 화면 레이아웃: 대형 QR 미리보기(240×240) → 커스터마이징 패널(접힘) → 액션 버튼
- 커스터마이징 패널은 탭 없이 단일 스크롤 영역
- 템플릿 목록은 CDN JSON(`apptagcdn.pages.dev`) 기반으로 제공 중
- 태그 타입별 전용 템플릿 없음 (모든 태그에 동일 목록)

### 1.2 변경 목표

1. **QR 미리보기 소형 고정** — 항상 상단에 노출, 꾸미기 내용 실시간 반영
- 하단에 돋보기 아이콘을 통해 크게 볼 수 있음.
2. **꾸미기 패널 확장** — 화면 하단 대부분을 차지, 탭 3개로 구성
3. **Supabase 템플릿 시스템** — 로컬 우선 + 백그라운드 동기화
4. **태그 타입별 추천 템플릿** — [추천] 탭에서 현재 태그 타입에 어울리는 템플릿 제공

---

## 2. 기능 요구사항

### 2.1 화면 레이아웃

```
┌─────────────────────────────┐
│  AppBar: "QR 코드"           │
├─────────────────────────────┤
│  [소형 QR 미리보기 160×160]   │  ← 항상 고정 (스크롤 밖)
│  deepLink URL (ellipsis)    │
│                [크게보기]   │
├─────────────────────────────┤
│  ┌─ 추천 ─┬─ 꾸미기 ─┬─ 전체 템플릿 ─┐
│  │  (탭 콘텐츠 스크롤 영역)          │  ← 화면 높이 채움
│  └───────────────────────────┘
├─────────────────────────────┤
│  [저장]  [공유]  [인쇄]       │  ← 항상 하단 고정
└─────────────────────────────┘
```

### 2.2 QR 데이터 제한

- **최대 150자** 제한 적용 (입력 UI에서 실시간 카운터 표시)
- 태그 타입별 URL 생성 직전 검증: 150자 초과 시 에러 메시지 표시 후 QR 화면 이동 불가
- URL 인코딩 전 raw 문자열 기준으로 카운트
- 이유: `pretty_qr_code`가 지원하는 최적 오류 복원 수준(H) 유지 및 QR 도트 과밀 방지

### 2.3 QR 스타일 패키지 전환: `qr_flutter` → `pretty_qr_code`

| 항목 | qr_flutter (기존) | pretty_qr_code (신규) |
|------|------------------|-----------------------|
| 도트 모양 | square / circle | square / circle / **rounded** |
| 아이 스타일 | square / circle | square / circle / **rounded / smooth** |
| 배경 커스텀 | 없음 | Image 배경 가능 |
| 이미지 삽입 | 직접 Stack 구현 | **내장 PrettyQrImage** |
| 그라디언트 | 별도 CustomPainter 필요 | **내장 PrettyQrLinearGradientDecoration** |
| 도트 전체 둥글기 | 없음 | **roundFactor 0.0~1.0** |

**실제 구현된 스타일 옵션 (꾸미기 탭)**:
- `roundFactor` 슬라이더 (0.0 = 사각, 1.0 = 완전 원형) → 도트(데이터 모듈) 둥글기 단계별 조절
- 아이(Eye/Finder Pattern) 모양: **`QrEyeStyle` enum 4종**
  - `square` → `PrettyQrSquaresSymbol(rounding: 0.0)` — 날카로운 직각 사각형
  - `rounded` → `PrettyQrSquaresSymbol(rounding: 0.8)` — 크게 둥근 사각형
  - `circle` → `PrettyQrDotsSymbol()` — 원형
  - `smooth` → `PrettyQrSmoothSymbol(roundFactor: 1.0)` — 완전 부드러운 연결형
  - `PrettyQrShape.custom(dotShape, finderPattern: eyeShape)` (experimental API)로 도트/아이 독립 제어
- 그라디언트: `ShaderMask(BlendMode.srcIn)` + `LinearGradient` / `RadialGradient`
  - 8종 프리셋 팔레트 (`kQrPresetGradients`) — WCAG 스캔 안전 색상 기준
  - 단색 / 그라디언트 토글 UI
  - **그라디언트 + 중앙 아이콘 동시 사용 시**: 아이콘을 `ShaderMask` 밖 `Stack`으로 분리 → 원본 색상 보존
- 중앙 이미지: `PrettyQrDecorationImage` 사용 (그라디언트 없는 경우) / Stack 오버레이 (그라디언트 있는 경우)

**마이그레이션 영향 파일**:
- `lib/features/qr_result/gradient_qr_painter.dart` → **삭제** (pretty_qr_code 내장 대체)
- `lib/features/qr_result/qr_result_screen.dart` — QrImageView → PrettyQrView 전환
- `lib/features/qr_result/qr_result_provider.dart` — eyeShape/dataModuleShape 타입 변경
- `lib/models/qr_template.dart` — style 필드 타입 `pretty_qr_code` 모델에 맞게 조정
- `pubspec.yaml` — `qr_flutter` 제거, `pretty_qr_code` 추가

### 2.4 탭 구성

#### [추천] 탭
- 현재 `tagType`에 해당하는 전용 템플릿 목록 표시
- `tagType`이 매핑된 템플릿 없으면 전체 템플릿 중 추천 순서로 표시
- 선택 시 즉시 QR 스타일 적용 (미리보기 실시간 갱신)

#### [꾸미기] 탭
- `pretty_qr_code` 기반으로 확장된 옵션:
  - 인쇄 상단 문구 / QR 하단 문구 텍스트필드
  - **아이 모양** (`QrEyeStyle` enum): 사각형 / 둥글기 / 원형 / 부드럽게 (4종) — 도트와 독립 제어
  - **도트 둥글기** (`roundFactor` 슬라이더, 0.0~1.0): 도트(데이터 모듈)만 적용, 아이는 별도
  - **색상**: 단색 팔레트 (WCAG 안전 10색) ↔ 그라디언트 프리셋 (8종) 토글 전환
  - 중앙 아이콘 (없음 / 기본 아이콘 / 이모지)
  - 인쇄 크기 슬라이더 (2.5cm ~ 20.0cm)
- **미래 확장**: 현재 꾸미기 설정값(`QrResultState`) → 나만의 템플릿 저장 기능 연동 예정

#### [전체 템플릿] 탭
- Supabase/로컬에서 로드된 전체 템플릿을 카테고리별로 그룹화
- 각 템플릿: 썸네일(미리 렌더링된 QR 미니어처) + 이름
- 현재 적용 템플릿 하이라이트

### 2.3 Supabase 템플릿 시스템

#### 로딩 전략 (로컬 우선 + 동기화)
```
앱 시작
  └→ ① 로컬 default_templates.json 즉시 표시 (빠른 UX)
  └→ ② 백그라운드: Supabase에서 updatedAt 타임스탬프 확인
        └→ 로컬보다 새 데이터 있으면 → Supabase 전체 로드
        └→ Hive 캐시 갱신 (다음 앱 실행 시 캐시 우선 사용)
```

#### 캐시 전략
- Hive Box `qr_templates_cache` 재사용
- 캐시 TTL: 24시간 (기존 1시간 → 연장, Supabase로 명시적 동기화 가능하므로)
- `updatedAt` 비교로 불필요한 전체 로드 방지

### 2.4 태그 타입 매핑

템플릿에 `tagTypes` 필드 추가:
- `['all']` → 모든 태그 타입에서 추천
- `['website', 'clipboard']` → 해당 타입에서만 추천
- `[]` 또는 null → 추천 탭 미표시, 전체 탭에만 표시

---

## 3. 기술 설계

### 3.1 Supabase 스키마

```sql
-- 템플릿 카테고리
CREATE TABLE qr_template_categories (
  id           text PRIMARY KEY,
  name         text NOT NULL,
  display_order int  NOT NULL DEFAULT 0
);

-- 템플릿
CREATE TABLE qr_templates (
  id                  text PRIMARY KEY,
  name                text NOT NULL,
  category_id         text REFERENCES qr_template_categories(id),
  tag_types           text[] NOT NULL DEFAULT '{}',  -- ['all'] | ['website','contact'] | []
  display_order       int NOT NULL DEFAULT 0,
  thumbnail_url       text,
  is_premium          boolean NOT NULL DEFAULT false,
  style               jsonb NOT NULL,
  min_engine_version  int NOT NULL DEFAULT 1,
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now()
);

-- 변경 시 updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER qr_templates_updated_at
  BEFORE UPDATE ON qr_templates
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS: 익명 읽기 허용 (공개 데이터)
ALTER TABLE qr_template_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_templates           ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read categories" ON qr_template_categories FOR SELECT USING (true);
CREATE POLICY "public read templates"  ON qr_templates           FOR SELECT USING (true);
```

### 3.2 패키지 변경

```yaml
# pubspec.yaml

# 추가
dependencies:
  supabase_flutter: ^2.5.0
  pretty_qr_code: ^3.3.0   # qr_flutter 대체

# 제거
# qr_flutter: ^4.1.0       ← 삭제
```

> `pretty_qr_code`는 내부적으로 `qr` 패키지를 사용하므로 QR 인코딩 로직은 동일.

### 3.3 변경 파일 목록

| 파일 | 변경 유형 | 주요 변경 내용 |
|------|----------|--------------|
| `pubspec.yaml` | 수정 | `supabase_flutter` 추가, `qr_flutter` 제거, `pretty_qr_code` 추가 |
| `lib/shared/constants/app_config.dart` | 수정 | Supabase URL/anon key 상수 추가, `kQrMaxLength = 150` |
| `lib/models/qr_template.dart` | 수정 | `QrTemplate.tagTypes`, `roundFactor` 추가, `pretty_qr_code` 스타일 타입 반영 |
| `assets/default_templates.json` | 수정 | 각 템플릿에 `tagTypes` 필드 추가 |
| `lib/services/supabase_service.dart` | **신규** | Supabase 클라이언트 싱글턴 초기화 |
| `lib/services/template_service.dart` | 수정 | CDN → Supabase 동기화 전략으로 교체 |
| `lib/features/qr_result/gradient_qr_painter.dart` | **삭제** | `ShaderMask` 기반 렌더링으로 완전 대체 |
| `lib/features/qr_result/qr_result_provider.dart` | 수정 | `QrEyeStyle` enum, `customGradient`, `kQrPresetGradients` 추가 |
| `lib/features/qr_result/qr_result_screen.dart` | 수정 | **전면 재설계**: 소형 미리보기 고정, 탭 UI, PrettyQrView 전환 |
| `lib/features/qr_result/tabs/customize_tab.dart` | **신규** | 꾸미기 탭: 아이 모양, 도트 슬라이더, 단색/그라디언트 토글 |
| `lib/features/qr_result/tabs/recommended_tab.dart` | **신규** | 추천 탭: tagType 기반 필터링 |
| `lib/features/qr_result/tabs/all_templates_tab.dart` | **신규** | 전체 템플릿 탭: 카테고리 그룹 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | **신규** | 소형 QR 미리보기 + 확대 팝업 + `buildPrettyQr()` + `buildQrGradientShader()` |
| `lib/features/qr_result/widgets/template_thumbnail.dart` | 수정 | 그라디언트 템플릿 썸네일: `buildQrGradientShader()` 공용 함수 적용 |
| `lib/main.dart` | 수정 | Supabase 초기화 |

### 3.4 QrTemplate 모델 변경

```dart
// 추가 필드
final List<String> tagTypes; // [] | ['all'] | ['website', 'contact']
final double? roundFactor;   // 0.0~1.0, null = 기본값 사용

// fromJson
tagTypes: (json['tagTypes'] as List<dynamic>?)
    ?.map((e) => e as String)
    .toList() ?? [],
roundFactor: (json['roundFactor'] as num?)?.toDouble(),
```

### 3.5 QR 데이터 제한 유틸

```dart
// lib/shared/constants/app_config.dart
const int kQrMaxLength = 150;

// 태그 타입별 deepLink 생성 직전 검증 (공통)
String? validateQrData(String data) {
  if (data.length > kQrMaxLength) {
    return 'QR 코드에 입력 가능한 최대 길이는 ${kQrMaxLength}자입니다.';
  }
  return null; // valid
}
```

- 각 태그 입력 화면에서 `Navigator.pushNamed('/qr-result', ...)` 직전 검증
- 초과 시 `ScaffoldMessenger.showSnackBar`로 에러 표시, 이동 차단

### 3.5 QrResultState 변경

```dart
// 추가 필드 (최종 구현 기준)
final String? tagType;           // navigation args에서 주입
final double roundFactor;        // 도트 둥글기 (0.0~1.0)
final QrEyeStyle eyeStyle;       // 아이 모양 enum (square/rounded/circle/smooth)
final QrGradient? customGradient; // 꾸미기 탭에서 직접 선택한 그라디언트 (null = 단색)
final QrGradient? templateGradient; // 템플릿에서 설정된 그라디언트 (우선순위 높음)

// 그라디언트 우선순위: templateGradient ?? customGradient
// 그라디언트 + 중앙 아이콘 동시 사용: useIconOverlay = true → Stack 오버레이 방식
```

**프리셋 상수**:
```dart
// kQrPresetGradients (8종, qr_result_provider.dart)
const kQrPresetGradients = [
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFF0066CC), Color(0xFF6A0DAD)]),  // 블루-퍼플
  // ... 8종
];
```

---

## 4. UI 구현 상세

### 4.1 화면 구조 (Flutter 위젯 트리)

```
Scaffold
├─ AppBar
├─ Column (mainAxis: max)
│   ├─ _QrPreviewSection (고정, 소형)    ← 160px QR + 돋보기 버튼
│   ├─ Text(deepLink, ellipsis)
│   ├─ Expanded
│   │   └─ DefaultTabController(length: 3)
│   │       ├─ TabBar([추천, 꾸미기, 전체 템플릿])
│   │       └─ TabBarView
│   │           ├─ _RecommendedTab
│   │           ├─ _CustomizeTab         ← PrettyQrView 옵션 기반 재구성
│   │           └─ _AllTemplatesTab
│   └─ _ActionButtons (고정 하단)
```

### 4.2 소형 QR 미리보기 & 확대 기능

- 크기: 160×160 px (기존 240→160)
- RepaintBoundary 유지 (캡처용, 소형 기준으로 고해상도 캡처)
- 패딩 최소화 (top: 12, bottom: 8)
- **돋보기(확대) 버튼**: 미리보기 우하단 오버레이
  - 탭 시 `showDialog`로 전체 화면 크기 QR 팝업 표시
  - 팝업 내 QR은 `PrettyQrView(size: 300)` 재렌더링 (캡처 이미지 아님)
  - 팝업 닫기: 배경 탭 또는 X 버튼

### 4.3 [추천] 탭 필터링 로직

```dart
List<QrTemplate> _recommendedTemplates(String? tagType) {
  final all = _templateManifest.templates;
  final typed = all.where((t) =>
    t.tagTypes.contains(tagType) || t.tagTypes.contains('all')).toList();
  return typed.isNotEmpty ? typed : all.take(6).toList();
}
```

### 4.4 템플릿 썸네일 렌더링

- 1차: `thumbnailUrl`이 있으면 네트워크 이미지 (에러 시 2차로 fallback)
- 2차: `thumbnailUrl`이 null이면 앱 내에서 소형 `PrettyQrView` 실시간 렌더
  - **그라디언트 템플릿**: `buildQrGradientShader()` 공용 함수로 미리보기와 동일한 `ShaderMask` 렌더링 적용
  - 기존 `첫 번째 그라디언트 색상만 단색으로 표시하던 방식` → 실제 그라디언트 시각화로 개선
- 선택된 템플릿: 테두리 강조 (`Theme.colorScheme.primary` 2px border)

---

## 5. 구현 순서

```
Step 1. 패키지 & 설정
  - pubspec.yaml: qr_flutter 제거, pretty_qr_code + supabase_flutter 추가
  - app_config.dart: Supabase URL/key, kQrMaxLength = 150 추가
  - supabase_service.dart 생성
  - main.dart: Supabase 초기화

Step 2. QR 데이터 제한 적용
  - validateQrData() 유틸 구현
  - 각 태그 입력 화면에 150자 검증 추가

Step 3. pretty_qr_code 마이그레이션
  - gradient_qr_painter.dart 삭제
  - QrImageView → PrettyQrView 전환 (qr_result_screen)
  - QrResultState: eyeShape/dataModuleShape 타입 → pretty_qr_code 호환 형태
  - QrTemplate 모델에 roundFactor 추가

Step 4. 데이터 모델 확장
  - QrTemplate.tagTypes 추가
  - default_templates.json tagTypes 추가
  - Supabase DB 테이블 생성 (SQL 실행)

Step 5. TemplateService Supabase 동기화
  - 기존 CDN http 로직 제거
  - 로컬 우선 + Supabase diff 동기화 구현

Step 6. QR 화면 전면 재설계
  - QrResultState.tagType 추가
  - QrResultScreen: 소형 미리보기 고정 + 돋보기 확대 팝업
  - DefaultTabController + 3탭 구성
  - _RecommendedTab, _CustomizeTab, _AllTemplatesTab 위젯 작성

Step 7. 검증
  - 각 태그 타입에서 추천 탭 필터링 확인
  - 150자 초과 시 에러 처리 확인
  - 돋보기 확대 팝업 확인
  - Supabase 연결 / 오프라인 fallback 확인
  - 캡처 이미지 품질 확인 (소형 QR → 저장 시 정상 출력)
```

---

## 6. 제약 및 고려사항

| 항목 | 내용 |
|------|------|
| **Supabase anon key 보안** | `.env` 또는 `dart-define`으로 관리, 코드에 하드코딩 금지 |
| **오프라인 지원** | Supabase 연결 실패 시 로컬 캐시 → 빌트인 JSON 순으로 fallback |
| **캡처 이미지 크기** | QR preview 160px이지만 저장 시 고해상도(×3) capture 적용 |
| **기존 Hive 호환** | `qr_templates_cache` 박스 구조 동일하게 유지 |
| **isPremium 템플릿** | 현재 단계에서는 UI 표시만 (잠금 아이콘), 실제 결제 기능 미구현 |
| **태그 타입 매핑 데이터** | 초기 Supabase 데이터 투입 시 tagTypes 직접 입력 필요 |
| **150자 제한 기준** | URL 인코딩 전 raw 문자열 기준, 다국어(한글 등) 포함 문자 수 기준 |
| **pretty_qr_code 호환성** | iOS/Android 모두 지원, 실제 설치 버전: `3.6.0` |
| **기존 히스토리 호환** | qrEyeShape/qrDataModuleShape 문자열 값은 유지, roundFactor는 신규 HiveField(16) 추가 |
| **`PrettyQrShape.custom()` API** | `@experimental` 태그, finder pattern 독립 제어용. 버전 업에서 breaking 가능성 주의 |
| **그라디언트 + 중앙 아이콘** | `ShaderMask.BlendMode.srcIn`이 아이콘까지 물들이는 문제 → `useIconOverlay` Stack 분리로 해결 |
| **그라디언트 QR 스캔성** | `kQrPresetGradients` 8종 모두 WCAG 기준 흰 배경 대비비 충족 색상으로 구성 |
| **나만의 템플릿 (예정)** | `QrResultState` 전체가 스타일 정보를 보유 → `QrTemplate`으로 직렬화해 저장 기능 추후 구현 |
