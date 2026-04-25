# Plan — SVG Logo Embed (SVG 로고 벡터 임베딩 + 에셋 관리 시스템)

> 생성일: 2026-04-24
> Feature ID: `svg-logo-embed`
> 대상: Flutter 모바일 앱 (pre-release)
> 관련 기존 feature: `svg-save`, `logo-tab-redesign`, `qr-custom-shape`

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | SVG 저장 시 중앙 로고가 누락됨. 로고(번들 SVG)와 텍스트가 벡터로 임베딩되지 않아 SVG 본래의 무한 확대 장점이 훼손. 또한 46개 번들 로고 에셋은 앱 빌드에 묶여 추가/수정 시 앱 업데이트가 필요. |
| **Solution** | QrSvgGenerator에 3종 로고 임베딩 추가 (logo=SVG inline, text=SVG `<text>`, image=Base64 `<image>`). Supabase Storage 기반 원격 에셋 관리 시스템 구축. 관리자 검색/업로드 UI + 앱 내 캐시 동기화. |
| **Function UX Effect** | SVG 저장 시 로고/텍스트가 벡터 품질로 포함. 관리자가 앱 업데이트 없이 로고/이모지 추가 가능. 사용자는 최신 로고를 자동으로 받아볼 수 있음. |
| **Core Value** | SVG 출력 완성도 + 에셋 운영 효율성. 향후 템플릿도 동일 인프라로 관리 확장 가능. |

---

## 1. Project Level & Key Architectural Decisions

| Item | Value |
|------|-------|
| **Project Level** | Flutter Dynamic x Clean Architecture x R-series |
| **Framework** | Flutter |
| **State Management** | Riverpod `StateNotifier` + `part of` mixin setters |
| **Local Storage** | Hive (기존 `qr_tasks` box) + 파일 캐시 |
| **Remote Storage** | Supabase Storage (SVG 에셋) + Supabase DB (manifest) |
| **Navigation** | `go_router` |
| **l10n 정책** | `app_ko.arb` 에 선반영 |

---

## 2. Scope

### Part A: SVG 로고 임베딩 (QrSvgGenerator 확장)

#### In-Scope

1. **LogoType.logo → SVG inline 임베딩**
   - `logoAssetId` ("social/twitter") 로 번들 SVG 파일을 읽고 `<svg>` 내용을 QR SVG 안에 `<g>` 그룹으로 인라인 삽입
   - 위치: `logoPosition` (center / bottomRight) 에 따라 `transform="translate(x,y)"` 적용
   - 크기: QR 전체 크기의 22% (기존 `_LogoWidget` 동일 비율)
   - 배경: `logoBackground` (none/circle/square/rectangle/roundedRectangle) + `logoBackgroundColor` 를 SVG rect/circle로 렌더링

2. **LogoType.text → SVG `<text>` 임베딩**
   - `logoText` (content, color, fontFamily, fontSize) 를 SVG `<text>` 요소로 렌더링
   - `text-anchor="middle"`, `dominant-baseline="central"` 로 중앙 정렬
   - 배경 도형 동일 적용

3. **LogoType.image → Base64 `<image>` 임베딩**
   - `centerIconBase64` (PNG bytes) 를 `<image href="data:image/png;base64,...">`로 삽입
   - 래스터이므로 확대 시 깨지지만, SVG 파일 내 포함은 가능

4. **LogoType.none → 기존 동작 유지** (로고 없음)

5. **상/하단 텍스트 (StickerText) SVG 임베딩**
   - `sticker.topText` / `sticker.bottomText` 를 SVG `<text>` 로 렌더링
   - QR 영역 위/아래에 배치

#### Out-of-Scope (Part A)

- 로고 clear zone (QR 도트 비우기) — SVG에서는 시각적으로 로고가 도트 위에 겹침 (PNG과 동일)
- 애니메이션 파라미터 SVG 반영
- 프레임 모드 SVG 반영

### Part B: 원격 에셋 관리 시스템

#### In-Scope

1. **Supabase Storage 구조**
   - Bucket: `logo-assets`
   - 경로: `{category}/{iconId}.svg` (예: `social/twitter.svg`)
   - 공개 URL로 직접 접근 가능

2. **Supabase DB: 에셋 매니페스트 테이블**
   ```
   logo_assets (
     id: uuid PK,
     category: text NOT NULL,
     icon_id: text NOT NULL,
     name_ko: text,
     name_en: text,
     tags: text[],          -- 검색용 태그
     storage_path: text,    -- Storage 경로
     svg_content: text,     -- SVG 문자열 직접 저장 (인라인 임베딩용)
     is_active: bool DEFAULT true,
     sort_order: int DEFAULT 0,
     created_at: timestamptz,
     updated_at: timestamptz,
     UNIQUE(category, icon_id)
   )
   ```

3. **관리자 기능 (앱 내 admin 화면 또는 Supabase Dashboard 직접 사용)**
   - **Option A (MVP — Supabase Dashboard 직접)**:
     - Supabase Dashboard에서 Storage 업로드 + DB 레코드 수동 관리
     - 앱에는 동기화/캐시 로직만 구현
   - **Option B (향후 — 앱 내 admin)**:
     - 로그인한 관리자 계정에만 노출되는 에셋 관리 화면
     - SVG 파일 업로드, 카테고리 지정, 태그 입력, 미리보기
     - 검색: 이름/태그 기반

4. **앱 내 동기화**
   - 앱 시작 시 매니페스트 버전 체크 → 변경 시 delta sync
   - SVG 내용은 로컬 캐시 (`getApplicationSupportDirectory()/logo_cache/`)
   - 오프라인 폴백: 번들 에셋 (`assets/logos/`) 유지
   - 캐시된 SVG 문자열을 그대로 QrSvgGenerator에 전달 (인라인 삽입)

5. **검색 기능**
   - 로고 라이브러리 편집기에 검색 TextField 추가
   - DB `tags` + `name_ko` + `icon_id` 에서 로컬 필터링
   - 카테고리 칩 + 검색 병행

#### Out-of-Scope (Part B)

- 템플릿 관리 (동일 인프라 확장 예정이나 이번 scope 아님)
- 유료/프리미엄 에셋 잠금
- 사용자 커스텀 SVG 업로드 (관리자만)
- 에셋 버전 관리 (단순 덮어쓰기)

---

## 3. 현재 구조 분석

### 3.1 이미 존재하는 것

| 항목 | 위치 | 상태 |
|------|------|------|
| QrSvgGenerator | `utils/qr_svg_generator.dart` | 도트+눈+경계만 지원, 로고 없음 |
| 로고 타입 체계 | `logo_source.dart` | LogoType (none/logo/image/text) 완비 |
| StickerConfig | `sticker_config.dart` | logoAssetId, logoText, logoImageBytes 등 |
| 번들 SVG 로고 | `assets/logos/` (46개) | 4 카테고리 (social/coin/brand/emoji) |
| manifest.json | `assets/logos/manifest.json` | 카테고리별 아이콘 목록 |
| LogoManifest 엔티티 | `logo_manifest.dart` | 도메인 표현 + findByCompositeId |
| 로고 라이브러리 편집기 | `logo_library_editor.dart` | 카테고리 칩 + 그리드 |
| QrCustomization | `qr_customization.dart` | centerIconBase64, centerEmoji 등 Hive 직렬화 |
| `_saveAsSvg` | `qr_task_action_sheet.dart` | QrSvgGenerator 호출 (로고 미전달) |

### 3.2 없는 것 (구현 필요)

| 항목 | 설명 |
|------|------|
| SVG 로고 인라인 임베딩 | QrSvgGenerator에 로고/텍스트/이미지 렌더링 |
| SVG 번들 파일 읽기 유틸 | assetPath → SVG 문자열 로딩 |
| 원격 에셋 테이블 | Supabase `logo_assets` 테이블 |
| 원격 에셋 동기화 | manifest delta sync + 로컬 캐시 |
| 검색 기능 | 태그/이름 기반 필터링 |
| `_saveAsSvg`에서 로고 데이터 전달 | sticker/customization → QrSvgGenerator 파라미터 |

---

## 4. Functional Requirements

### Part A: SVG 로고 임베딩

#### FR-A01. QrSvgGenerator 로고 파라미터 추가

```dart
static String generate({
  // ... 기존 파라미터 ...
  // 신규:
  String? logoSvgContent,    // LogoType.logo: SVG 문자열 (인라인)
  String? logoBase64Png,     // LogoType.image: PNG Base64
  SvgLogoText? logoText,     // LogoType.text: 텍스트 정보
  SvgLogoStyle? logoStyle,   // 위치, 배경, 크기 등 공통 스타일
  SvgStickerText? topText,   // 상단 텍스트
  SvgStickerText? bottomText,// 하단 텍스트
})
```

#### FR-A02. LogoType.logo 벡터 인라인 임베딩
- 번들/캐시된 SVG 문자열을 `<g transform="translate(x,y) scale(s)">` 안에 삽입
- SVG의 viewBox를 파싱하여 적절한 scale 계산
- 배경 도형 (circle/square 등) 을 로고 `<g>` 아래에 먼저 렌더링

#### FR-A03. LogoType.text 벡터 임베딩
- `<text>` 요소로 렌더링
- fontFamily, fontSize, color 반영
- 배경 도형 동일 적용

#### FR-A04. LogoType.image Base64 임베딩
- `<image href="data:image/png;base64,{data}" x="..." y="..." width="..." height="..."/>`
- 배경 도형 동일 적용

#### FR-A05. 상/하단 스티커 텍스트 SVG 임베딩
- `topText` → QR 영역 위에 `<text>` 요소
- `bottomText` → QR 영역 아래에 `<text>` 요소
- viewBox 확장: 텍스트 높이만큼 SVG 전체 높이 증가

#### FR-A06. `_saveAsSvg` 호출부 수정
- `QrTask.customization` + `StickerSpec` 에서 로고 데이터 추출
- LogoType.logo: `logoAssetId` → SVG 문자열 로드 → `logoSvgContent` 전달
- LogoType.image: `centerIconBase64` → `logoBase64Png` 전달
- LogoType.text: `sticker.logoText` → `SvgLogoText` 변환 → `logoText` 전달

### Part B: 원격 에셋 관리

#### FR-B01. Supabase 테이블 생성
- `logo_assets` 테이블 (위 스키마)
- RLS 정책: 읽기 = public, 쓰기 = admin role only

#### FR-B02. 매니페스트 동기화
- 앱 시작 시 Supabase에서 `logo_assets` 쿼리 (is_active = true)
- 로컬 `manifest_version` 과 비교 → 변경 시 업데이트
- 결과를 기존 `LogoManifest` 형식으로 변환
- 오프라인 시 번들 manifest 사용

#### FR-B03. SVG 콘텐츠 캐시
- DB의 `svg_content` 필드에서 SVG 문자열 직접 가져옴
- 로컬 파일 캐시: `{supportDir}/logo_cache/{category}/{iconId}.svg`
- 캐시 히트 시 네트워크 미사용
- 캐시 무효화: manifest 동기화 시 `updated_at` 비교

#### FR-B04. 검색 기능
- 로고 라이브러리 편집기 상단에 `TextField` (검색)
- 로컬 필터: `tags`, `name_ko`, `icon_id` 에서 contains 매칭
- 카테고리 필터와 AND 조합
- 검색어 비어있으면 전체 표시

#### FR-B05. 향후 확장 포인트
- `asset_type` 컬럼 추가 시 `template` 타입 관리 가능
- 동일 테이블 + Storage 구조 재사용

---

## 5. Non-Functional Requirements

- **SVG 파일 크기**: 로고 인라인 시 +2~5KB 증가 (수용 가능)
- **오프라인 지원**: 번들 에셋으로 폴백, 네트워크 필수 아님
- **캐시 크기**: SVG 46개 기준 ~200KB (무시 가능)
- **동기화 빈도**: 앱 시작 시 1회 (백그라운드, UI 블로킹 아님)

---

## 6. 요구사항 → 영향 파일 매핑

| # | 작업 | 파일 | 변경 유형 |
|---|------|------|-----------|
| 1 | QrSvgGenerator 로고 파라미터 추가 | `qr_svg_generator.dart` | 수정 |
| 2 | SVG 로고 인라인 렌더링 | `qr_svg_generator.dart` | 수정 |
| 3 | SVG 텍스트 렌더링 | `qr_svg_generator.dart` | 수정 |
| 4 | SVG Base64 이미지 렌더링 | `qr_svg_generator.dart` | 수정 |
| 5 | SVG 스티커 텍스트 렌더링 | `qr_svg_generator.dart` | 수정 |
| 6 | SvgLogoStyle/SvgLogoText VO | `svg_logo_params.dart` (신규) | 신규 |
| 7 | `_saveAsSvg` 로고 데이터 전달 | `qr_task_action_sheet.dart` | 수정 |
| 8 | SVG 에셋 파일 로드 유틸 | `svg_asset_loader.dart` (신규) | 신규 |
| 9 | Supabase 테이블 | migration SQL | 신규 |
| 10 | 원격 매니페스트 동기화 서비스 | `logo_sync_service.dart` (신규) | 신규 |
| 11 | 로컬 캐시 데이터소스 | `logo_cache_datasource.dart` (신규) | 신규 |
| 12 | LogoManifest 원격 소스 통합 | `logo_manifest_repository.dart` | 수정 |
| 13 | 검색 TextField | `logo_library_editor.dart` | 수정 |
| 14 | l10n 키 | `app_ko.arb` | 수정 |

---

## 7. 구현 순서

### Phase 1: SVG 로고 임베딩 (Part A) — 우선 구현
1. `SvgLogoParams` VO 신규
2. `QrSvgGenerator` 로고/텍스트/이미지 렌더링 추가
3. SVG 에셋 로더 유틸 (번들 SVG 읽기)
4. `_saveAsSvg` 호출부 수정
5. 테스트: 각 LogoType별 SVG 출력 확인

### Phase 2: 원격 에셋 관리 (Part B) — 후속 구현
1. Supabase 테이블 + Storage 설정
2. 동기화 서비스 + 캐시 데이터소스
3. LogoManifest 원격 소스 통합
4. 검색 기능
5. 기존 번들 에셋 → Supabase 마이그레이션

---

## 8. Risks & Mitigations

| Risk | 영향 | Mitigation |
|------|------|-----------|
| SVG 인라인 삽입 시 viewBox 파싱 실패 | 로고 위치/크기 오류 | 정규식 기반 viewBox 추출 + 폴백 (96x96 기본) |
| 번들 SVG에 네임스페이스 충돌 | `id` 중복 시 SVG 렌더링 오류 | 인라인 시 id 접두사 추가 (`logo-`) |
| 이모지 SVG의 `<text>` 폰트 호환성 | 외부 뷰어에서 이모지 깨짐 | 향후 path 기반 이모지 SVG로 교체 |
| Supabase 의존 시 오프라인 동작 | 첫 실행 시 로고 없음 | 번들 에셋 유지 (오프라인 폴백) |

---

## 9. Decisions Confirmed

| Decision | 확정값 | 근거 |
|----------|--------|------|
| LogoType.logo | SVG 인라인 (`<g>` 그룹) | 벡터 품질 유지 |
| LogoType.text | SVG `<text>` | 벡터 폰트 렌더링 |
| LogoType.image | Base64 `<image>` | PNG 래스터, 벡터 변환 불가 |
| 원격 에셋 | Supabase Storage + DB | 기존 인프라 활용, 1인 관리 적합 |
| 오프라인 | 번들 에셋 폴백 | 네트워크 필수 아님 |
| MVP 관리 | Supabase Dashboard 직접 | 별도 admin UI는 향후 |
| 로고 크기 비율 | QR 22% | 기존 `_LogoWidget` 동일 |

---

## 10. Approval Checklist

- [x] 요구사항 이해 합의
- [x] 3종 로고 타입별 SVG 임베딩 방식 확정
- [x] 원격 에셋 관리 인프라 (Supabase) 확정
- [x] 구현 순서 (Part A 먼저 → Part B 후속) 확정
- [x] 오프라인 폴백 전략 확정

---

_이 Plan 은 CLAUDE.md 고정 규약(R-series Provider 패턴 + Clean Architecture + l10n ko 선반영)을 기반으로 작성되었습니다._
