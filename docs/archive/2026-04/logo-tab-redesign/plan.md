---
template: plan
version: 1.2
feature: logo-tab-redesign
date: 2026-04-20
author: tawool83
project: app_tag
---

# logo-tab-redesign Planning Document

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 현재 "로고" 탭은 표시 여부 스위치와 위치·배경 선택만 제공. 로고 소스는 tagType 기본 아이콘 또는 템플릿에서 주어지는 것뿐으로, 사용자가 원하는 심볼·사진·글자를 자유롭게 넣을 수 없다. |
| **Solution** | 탭 상단 좌측에 표시 토글을 두고, 활성화 시 우측 드롭다운으로 **로고 / 이미지 / 텍스트** 3가지 타입을 선택. 타입별 전용 편집기(카테고리 아이콘 그리드 / 갤러리 크롭 / 문구 편집)를 제공하며 위치·배경(도형+테두리 색상)은 공용 설정으로 단순화. |
| **Function/UX** | 한 탭에서 3가지 로고 소스를 전환 가능. 아이콘 라이브러리(소셜·코인·이모지 등)는 번들 assets로 오프라인 동작. 사진은 `image_cropper`로 정사각 크롭 후 썸네일 미리보기. 텍스트 로고는 색상·폰트·크기까지 세밀 편집. 로고 배경(square/circle)의 테두리 색상도 사용자가 설정하여 시각 강조 가능. |
| **Core Value** | 로고 커스터마이징의 자유도를 "tagType 고정" → "사용자 선택형 3타입"으로 확장하여 개인화된 QR 브랜딩 가능. |

---

## 1. 현재 구조 (변경 전)

```
[로고] 탭
├── Row: ① 아이콘 표시 스위치 (우측 정렬)
│       └── 비활성: 앱 아이콘/이모지 미설정 시 disabled + 안내 문구
│
├── Row: ② 로고 위치 | ③ 로고 배경 (좌우 2분할)
│       ├── 로고 위치: center / bottomRight
│       └── 로고 배경: none / square / circle
│
└── (끝)
```

**로고 소스 우선순위 (현재, qr_preview_section.dart:437)**
1. `templateCenterIconBytes` (템플릿 URL 아이콘)
2. `emojiIconBytes` (이모지 렌더링)
3. `defaultIconBytes` (tagType 기본 Material 아이콘)

사용자는 이모지 하나만 변경 가능하며(현재 이모지 피커 미노출), 심볼·사진·글자 선택이 불가능.

## 2. 변경 후 구조

```
[로고] 탭 (단일 스크롤)
│
├── Row 1: 표시 토글 + 타입 드롭다운
│   ┌ [●/○ 표시] ─────────── [로고 ▾]
│   │    토글 ON → 드롭다운 활성 (기본 "로고")
│   │    토글 OFF → 드롭다운 비활성 + 하단 편집기 전체 숨김
│   └ 드롭다운 옵션: 로고 / 이미지 / 텍스트
│
├── Row 2: 공통 설정 (로고·이미지 공용, 텍스트는 "위치"만 공용)
│   ┌ [위치]             [배경]
│   │  center/bottomRight  none/square/circle
│   ├ [배경 색상]  ← 배경이 square 또는 circle일 때만 표시/활성
│   │  [●색상원형버튼] → HSV 컬러피커 (기본: 없음 / null)
│   │  ※ 두께는 고정 1.5dp (스코프 단순화)
│   │  ※ "없음" 토글 버튼 포함 (테두리 제거 옵션)
│   └ ※ "로고 위치"→"위치", "로고 배경"→"배경"으로 라벨 변경
│   ※ 타입이 "텍스트"일 때는 "배경" + "배경 색상" 모두 숨김
│
└── Row 3: 타입별 편집기 (선택된 타입에 따라 1개만 표시)
    │
    ├── 타입 A: "로고" — 카테고리 + 아이콘 그리드
    │   ┌ 카테고리 칩 Row (횡스크롤)
    │   │   [소셜] [코인] [브랜드] [비즈니스] [SNS] [이모지] ...
    │   └ 아이콘 그리드 (4~5열 GridView, ScrollView)
    │       [🅐][🅑][🅒][🅓]
    │       [🅔][🅕][🅖][🅗]  ← 선택 시 파란 테두리
    │       ...
    │
    ├── 타입 B: "이미지" — 사진 선택 + 크롭
    │   ┌ 썸네일 미리보기 (정사각, 크롭된 결과)
    │   │   [이미지 or 안내 플레이스홀더]
    │   ├ [📷 갤러리에서 선택] 버튼 → image_cropper 전체화면 모달
    │   └ [✂ 다시 자르기] 버튼 (이미지 선택 후 표시)
    │
    └── 타입 C: "텍스트" — 문구 입력 + 스타일
        ┌ [문구 ________________]  (최대 6자, 1~2줄)
        ├ [●색상]  [폰트 ▾]  [- 12sp +]
        └ 실시간 QR 미리보기 (상단 QrPreviewSection 자동 반영)
```

## 3. 핵심 동작 상세

### 3.1 표시 토글 (상단 좌측)

- 현재: 화면 상단 `Row(spaceBetween)`의 오른쪽에 배치
- 변경: **좌측 배치**. 라벨 "표시"(기존 `labelShowIcon` "아이콘 표시" → 간결화 검토) + `Switch`
- 토글 OFF: 드롭다운 disabled + 공통 설정·타입별 편집기 숨김 (`ConstrainedBox` 로 높이 고정 없이 자연 축소)
- 토글 ON: 선택된 타입의 편집기 활성 — 단, 선택된 타입에 유효한 데이터(아이콘/이미지/문구)가 없으면 QR 미리보기에서는 아이콘이 렌더되지 않음(기존 `hasIconSource` 로직 확장)

### 3.2 타입 드롭다운 (상단 우측)

- 옵션: `LogoType.logo` / `LogoType.image` / `LogoType.text` (기본 `logo`)
- Enum은 state/엔티티 확장으로 도입 (`StickerConfig.logoType` 추가)
- 드롭다운 전환 시 기존 데이터는 유지(이미지 bytes·텍스트 문구·선택 아이콘 id)되며, 선택된 타입의 소스만 렌더링 우선순위 적용
- 토글 OFF 시 비활성 (라벨만 표시, 클릭 불가)

### 3.3 공통 설정: 위치 + 배경 + 배경 색상 색상

- 라벨만 "로고 위치"→**"위치"**, "로고 배경"→**"배경"** 으로 변경 (ARB 키는 새로 추가: `labelLogoTabPosition`, `labelLogoTabBackground` — 기존 키는 Preview/Template 탭에서도 쓰일 수 있으므로 안전하게 신규)
- 타입 "텍스트" 선택 시 **배경 + 배경 색상 섹션 모두 숨김** (텍스트는 배경 도형과 조합 시 가독성 저하 우려 + 스코프 단순화)
- 위치·배경은 `StickerConfig` 의 기존 필드 (`logoPosition`, `logoBackground`) 그대로 재사용

**배경 색상 색상 (신규)**

- 현재 `qr_layer_stack.dart:268-293` 의 배경 렌더링은 `color: Colors.white` + `boxShadow` 만 있고 테두리(border)가 없음 → `Border.all(color, width: 1.5)` 추가 경로 신설
- UI: "배경" 섹션 아래에 "배경 색상" 행
  - 색상 원형 버튼 (탭 → HSV `ColorPicker` 다이얼로그, `flutter_colorpicker` 기존 사용)
  - 보조 버튼 "없음" → 테두리 제거 (`logoBackgroundBorderColor = null`)
- 활성 조건: `logoBackground != LogoBackground.none` (배경 도형이 있을 때만 의미 있음)
  - 배경이 `none`이면 섹션 disabled + 회색 처리 + "배경을 선택하면 활성화됩니다" 힌트
- 두께는 **고정 1.5dp** (사용자 조정 불필요, 너무 두꺼우면 QR 캡처/인쇄 시 로고 잠식)
- 저장: `StickerConfig.logoBackgroundBorderColor: Color?` (null = 테두리 없음)
- 기본값: `null` (기존 동작과 동일 — 테두리 없음, 회귀 영향 없음)
- 추천 색상 팔레트(선택 다이얼로그 상단): QR 색상과 동일한 `qrSafeColors` 10색 재사용 + 흰/검정 포함

### 3.4 타입 A — "로고" (카테고리 아이콘 라이브러리)

**자산 관리 전략 (확정): 앱 번들 고정**

- 경로: `assets/logos/{category}/{id}.svg` (또는 png) — **SVG 우선** (벡터, 색상·크기 자유)
- manifest: `assets/logos/manifest.json` — 카테고리 목록 + 각 카테고리의 아이콘 id 리스트
- 패키지: `flutter_svg` 추가 필요 (pubspec 의존성 추가)
- 렌더링: SVG를 `Uint8List`(PNG)로 래스터화 후 기존 `templateCenterIconBytes` 슬롯과 동일한 파이프라인 재사용 (일관성)

**manifest.json 예시**
```json
{
  "categories": [
    { "id": "social",   "name_ko": "소셜",  "icons": ["twitter","facebook","instagram","tiktok"] },
    { "id": "coin",     "name_ko": "코인",  "icons": ["btc","eth","sol","xrp"] },
    { "id": "brand",    "name_ko": "브랜드", "icons": ["nike","adidas","apple"] },
    { "id": "emoji",    "name_ko": "이모지", "icons": ["smile","heart","star","fire"] }
  ]
}
```

**초기 카테고리 범위 (설계 단계 확정 예정)**
- MVP 후보: 소셜(10), 코인(8), 이모지(20), 비즈니스(8) — 총 ~46개
- 상세 목록은 Design 문서에서 확정

**UI**
- 카테고리 칩: 수평 스크롤 `ListView.builder` + 선택 상태 배경
- 아이콘 그리드: 4~5열 `GridView.count`, 각 셀은 48×48 SVG + 선택 시 파란 테두리
- 선택 시 `StickerConfig.logoType = logo, logoAssetId = "social/twitter"` 저장 + SVG→PNG 래스터화 후 `defaultIconBytes` 슬롯에 주입

### 3.5 타입 B — "이미지" (갤러리 + 크롭)

**UX 플로우 (확정): 전체화면 + 미리보기 썸네일 (둘 다)**

1. [갤러리에서 선택] 버튼 탭 → `image_picker` (ImageSource.gallery, maxWidth 1024)
2. 선택된 이미지 파일을 `image_cropper`로 전달 → **전체화면 모달** (aspectRatio 1:1 고정, `CropStyle.rectangle`)
3. 크롭 완료 → `CroppedFile` → `Uint8List` 변환 → `StickerConfig.logoType = image, logoImageBytes = ...`
4. 탭 내에는 크롭된 결과를 **96×96 썸네일 미리보기**로 표시 + [✂ 다시 자르기] 버튼 노출

**저장 정책**
- `logoImageBytes` 는 메모리 state + Hive (`UserQrTemplate`) + QrTask JSON (base64)에 저장
- QrTask JSON 크기 증가 대비: 크롭 결과를 **256×256 JPEG Q85**로 재인코딩 (예상 10~30KB)

**패키지 활용** (이미 설치됨)
- `image_picker: ^1.1.2`
- `image_cropper: ^8.0.2`
- `image: ^4.2.0` (재인코딩용)

### 3.6 타입 C — "텍스트" (로고 위치에 글자 삽입)

**옵션 범위 (확정): 문구 + 색상 + 폰트 + 크기 (전체)**

- 별도 위젯 `_LogoTextEditor` — 기존 상/하단 텍스트의 `_TextEditor`(text_tab.dart)를 베이스로 경량 복제
- 필드:
  - 문구: `TextField`, 최대 **6자** (로고는 짧아야 가독성 유지)
  - 색상: `ColorPicker` 다이얼로그 (재사용)
  - 폰트: `sans-serif` / `serif` / `monospace` (기존 `_kFonts` 재사용)
  - 크기: 10~40sp 스텝퍼 (로고 공간 기준 상한 40)
- 저장: `StickerConfig.logoType = text, logoText: StickerText(content, color, fontFamily, fontSize)`
- 렌더링: QR 중앙 로고 영역에서 `TextPainter` 또는 Canvas 기반으로 그림 → PNG bytes 변환 → 기존 아이콘 슬롯과 동일 파이프라인
  - 또는 레이어 합성 시 Widget 레벨에서 `Text` 위젯을 로고 영역에 겹치기 (보다 간단) — 설계 단계에서 결정

### 3.7 기존 데이터 호환성 (확정 정책)

**기존은 그대로, 신규만 3타입 지원**

| 시나리오 | 동작 |
|----------|------|
| 기존 저장 QrTask 열기 (`centerIconBase64` 또는 tagType 기본 아이콘) | `logoType`=null → 기존 로직 그대로 (`templateCenterIconBytes` or `defaultIconBytes` 렌더). 사용자가 3타입 중 하나 선택 시점에 `logoType` 주입 |
| 기존 저장 템플릿 로드 | `applyTemplate()` 동작 유지, `logoType`=null |
| 신규 QR + 사용자가 로고 탭 접근 | 드롭다운 기본 "로고" 선택 상태로 표시, 카테고리 편집기 노출. 다른 것 선택 전까지는 기존 동작(tagType 기본 아이콘) |
| 신규 QR + 사용자가 타입 변경 | `logoType` 설정 + 해당 타입 데이터 저장, 렌더링 분기 활성화 |

**마이그레이션 없음**: `StickerConfig.logoType` 은 `nullable` 로 추가, null은 "기존 동작"을 의미.

## 4. 데이터 모델 확장

### 4.1 `sticker_config.dart` (StickerConfig)

```dart
enum LogoType { logo, image, text }   // 새로 추가

class StickerConfig {
  // 기존
  final LogoPosition logoPosition;
  final LogoBackground logoBackground;
  final StickerText? topText;
  final StickerText? bottomText;

  // 신규 (모두 nullable)
  final LogoType? logoType;              // null = 기존 동작
  final String? logoAssetId;             // "social/twitter" (LogoType.logo)
  final Uint8List? logoImageBytes;       // 크롭된 정사각 PNG (LogoType.image)
  final StickerText? logoText;           // 로고 텍스트 (LogoType.text)
  final Color? logoBackgroundBorderColor; // 배경(square/circle) 테두리 색상 (null = 테두리 없음)
}
```

### 4.2 `qr_result_provider.dart` (QrResultState)

기존 `embedIcon: bool` 유지 (= 토글 상태). 렌더링 경로는:
1. `embedIcon=false` → 아이콘 없음
2. `embedIcon=true && sticker.logoType=null` → 기존 fallback (`templateCenterIconBytes` > `emojiIconBytes` > `defaultIconBytes`)
3. `embedIcon=true && sticker.logoType=logo` → assetId 기반 SVG 로드 → PNG
4. `embedIcon=true && sticker.logoType=image` → `logoImageBytes` 직접 렌더
5. `embedIcon=true && sticker.logoType=text` → TextPainter로 PNG 생성 or Widget 레이어 합성

### 4.3 QrTask JSON (영속화)

`QrCustomization` 에 신규 필드 추가:
- `logoType: "logo" | "image" | "text" | null`
- `logoAssetId: string | null`
- `logoImageBase64: string | null` (256×256 JPEG Q85, base64)
- `logoText: { content, color, fontFamily, fontSize } | null`
- `logoBackgroundBorderColor: int | null` (ARGB32, null = 테두리 없음)

기존 `centerIconBase64` 는 유지 — 기존 QR 호환용. 새 QR 저장 시에는 `logoType` 에 따라 분기.

### 4.4 `UserQrTemplate` (Hive)

위와 동일 필드를 Hive 모델(`user_qr_template_model.dart`)에 추가 — `logoType`, `logoAssetId`, `logoImageBytes`(Uint8List로 직접), `logoTextContent/Color/Font/Size` 4필드, `logoBackgroundBorderColorValue: int?` 1필드. Hive 스키마 변경 시 `@HiveField` 번호를 새로 할당하고 `build_runner` 재실행.

## 5. 변경 파일

| 파일 | 변경 |
|------|------|
| `lib/features/qr_result/tabs/sticker_tab.dart` | **전면 재작성** (토글+드롭다운, 공통 설정, 3타입 편집기 분기) |
| `lib/features/qr_result/domain/entities/sticker_config.dart` | `LogoType` enum + 4개 필드 추가 |
| `lib/features/qr_result/qr_result_provider.dart` | 타입별 아이콘 렌더링 우선순위 로직 추가 + setter 메서드들 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | `centerImageProvider`에 logoType 분기 |
| `lib/features/qr_result/widgets/qr_layer_stack.dart` | 텍스트 로고 위젯 합성 경로 (선택적) + **square/circle 배경에 `Border.all(color: logoBackgroundBorderColor, width: 1.5)` 적용** |
| `lib/features/qr_result/utils/customization_mapper.dart` | `logoType`·`logoAssetId`·`logoImageBase64`·`logoText` 양방향 매핑 |
| `lib/features/qr_task/domain/entities/qr_customization.dart` | 4개 필드 추가 |
| `lib/features/qr_result/data/models/user_qr_template_model.dart` | Hive 필드 4개 추가 (+g.dart 재생성) |
| `lib/features/qr_result/data/datasources/local_default_template_datasource.dart` | 필요 시 template JSON 스키마 확장 |
| `lib/core/services/logo_asset_service.dart` | **신규** — manifest 로드 + SVG→PNG 래스터화 + 캐시 |
| `assets/logos/manifest.json` | **신규** — 카테고리·아이콘 메타 |
| `assets/logos/{category}/*.svg` | **신규** — 아이콘 SVG 파일들 |
| `pubspec.yaml` | `flutter_svg` 의존성 추가 + `assets/logos/` 등록 |
| `lib/l10n/app_*.arb` (11개) | 신규 키 ~12개 추가 |

## 6. 새 ARB 키 (제안)

| 키 | 한국어 | 용도 |
|---|--------|------|
| `labelLogoTabShow` | 표시 | 토글 라벨 (간결화) |
| `labelLogoType` | 유형 | 드롭다운 라벨(숨김용 — screen reader) |
| `optionLogoTypeLogo` | 로고 | 드롭다운 옵션 |
| `optionLogoTypeImage` | 이미지 | 드롭다운 옵션 |
| `optionLogoTypeText` | 텍스트 | 드롭다운 옵션 |
| `labelLogoTabPosition` | 위치 | 공통 설정 라벨 |
| `labelLogoTabBackground` | 배경 | 공통 설정 라벨 |
| `labelLogoBackgroundBorder` | 배경 색상 | 배경 색상 색상 섹션 라벨 |
| `hintLogoBackgroundBorderDisabled` | 배경을 선택하면 활성화됩니다 | 비활성 상태 안내 |
| `actionLogoBorderNone` | 없음 | 테두리 제거 버튼 |
| `labelLogoCategory` | 카테고리 | 로고 타입 섹션 |
| `labelLogoGallery` | 갤러리에서 선택 | 이미지 타입 버튼 |
| `labelLogoRecrop` | 다시 자르기 | 이미지 타입 버튼 |
| `labelLogoTextContent` | 문구 | 텍스트 타입 입력 라벨 |
| `hintLogoTextContent` | 로고에 넣을 글자 | 텍스트 타입 placeholder |
| (카테고리명) `categorySocial`, `categoryCoin`, `categoryBrand`, `categoryEmoji` 등 | 소셜/코인/브랜드/이모지 | 카테고리 칩 라벨 |

## 7. 스코프 밖 (Out of Scope)

- 사용자 커스텀 아이콘 업로드 후 "로고" 카테고리에 영구 저장 (향후 기능)
- 아이콘 라이브러리 원격 동기화 / CDN (이번 사이클은 번들 고정)
- 배경 도형 위에 텍스트 로고 배치 (텍스트 타입은 배경 숨김)
- 이모지 기반 로고 삽입 (이모지 카테고리는 SVG로 대체 제공)
- 기존 `centerEmoji` 기능의 제거 (호환 유지)
- 배경 색상 **두께** 사용자 조정 (1.5dp 고정) + 점선·대시 스타일 (실선 고정)

## 8. 위험 요소

| 위험 | 대응 |
|------|------|
| SVG 라이브러리(`flutter_svg`) 렌더링 차이 (Android vs iOS) | 초기 아이콘 세트를 테스트 + 필요 시 PNG 폴백 |
| 이미지 base64 저장으로 QrTask JSON 비대화 | 크롭 결과를 256×256 JPEG Q85로 재인코딩 (10~30KB 목표) |
| 기존 저장 QR 복원 시 `logoType=null` 처리 누락 | `customization_mapper` 에 명시적 `null`-aware 분기 + 기존 회귀 테스트 |
| Hive 스키마 변경으로 기존 저장 템플릿 호환성 깨짐 | `@HiveField` 번호 중복 금지 + 누락 필드는 default 값으로 읽기 |
| 번들 SVG 자산으로 앱 용량 증가 | 카테고리당 10개 이내로 제한, SVG 최소화 (simplify SVG) |
| 텍스트 로고의 TextPainter 정확한 위치/크기 계산 | Widget 레이어 합성 방식(간단)을 1차 검토, 저장 시 캡처로 일관성 확보 |

## 9. 성공 기준

1. 로고 탭에서 3가지 타입(로고·이미지·텍스트)을 드롭다운으로 전환 가능
2. 각 타입별 편집 결과가 상단 QR 미리보기에 **500ms 이내** 반영
3. 기존 저장 QR/템플릿 로드 시 **회귀 없음** (기존 아이콘 렌더링 그대로)
4. 이미지 크롭 후 JSON 저장 크기가 QR 1건당 **50KB 이내**
5. 11개 로케일 모두 신규 키 번역 완료
6. 번들된 아이콘 카테고리 ≥ 4개, 총 아이콘 ≥ 40개
7. 배경(square/circle) 선택 시 테두리 색상을 HSV 피커로 지정하고 [없음]으로 제거 가능, QR 미리보기/저장/공유/인쇄 모두 테두리 반영
