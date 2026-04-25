# Gap Analysis — svg-logo-embed (Phase 1: Part A)

> 분석일: 2026-04-24
> Design: `docs/02-design/features/svg-logo-embed.design.md`
> Scope: Phase 1 (Part A: SVG 로고 임베딩) — Part B (Supabase 원격 에셋)는 별도 구현 예정

---

## Match Rate: **97%**

---

## Design Item Checklist

### 2.1 신규 Value Object: `svg_logo_params.dart`

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| SvgLogoStyle (sizeRatio, position, background, backgroundColorArgb) | 4 fields | 4 fields 동일 | PASS |
| SvgLogoText (content, colorArgb, fontFamily, fontSize) | 4 fields | 4 fields 동일 | PASS |
| SvgStickerText (content, colorArgb, fontFamily, fontSize) | 4 fields | 4 fields 동일 | PASS |
| 파일 위치 | `domain/entities/svg_logo_params.dart` | 동일 | PASS |

### 2.2 QrSvgGenerator 확장 시그니처

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| logoSvgContent 파라미터 | String? | String? | PASS |
| logoBase64Png 파라미터 | String? | String? | PASS |
| logoText 파라미터 | SvgLogoText? | SvgLogoText? | PASS |
| logoStyle 파라미터 | SvgLogoStyle? | SvgLogoStyle? | PASS |
| topText 파라미터 | SvgStickerText? | SvgStickerText? | PASS |
| bottomText 파라미터 | SvgStickerText? | SvgStickerText? | PASS |

### 2.3 SVG 렌더링 로직 상세

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| 2.3.1 viewBox 확장 (top/bottom text) | topH = fontSize * 1.6, viewBox 음수 Y | 구현 동일 | PASS |
| 2.3.2 로고 배치 (center) | (totalSize-logoSize)/2 | 구현 동일 | PASS |
| 2.3.2 로고 배치 (bottomRight) | totalSize-logoSize-padding | `totalSize * 0.02` padding | PASS |
| 2.3.3 배경 도형 — none | 빈 문자열 | 구현 동일 | PASS |
| 2.3.3 배경 도형 — circle | `<circle>` | 구현 동일 | PASS |
| 2.3.3 배경 도형 — square | `<rect rx="4">` | 구현 동일 | PASS |
| 2.3.3 배경 도형 — roundedRectangle | `<rect rx="10">` | 구현 동일 | PASS |
| 2.3.3 배경 도형 — rectangle | `<rect rx="2">` | 구현 동일 | PASS |
| 2.3.4 SVG 인라인 — viewBox 파싱 | 정규식, 폴백 [0,0,96,96] | 구현 동일 + try/catch 보강 | PASS |
| 2.3.4 SVG 인라인 — inner 추출 | xml/svg 태그 제거 | 구현 동일 | PASS |
| 2.3.4 SVG 인라인 — id 충돌 방지 | `logo-` 접두사 | 구현 동일 + xlink:href/href 추가 | PASS |
| 2.3.4 SVG 인라인 — viewBox offset 보정 | translate + scale | 구현 동일 | PASS |
| 2.3.5 LogoType.text — `<text>` 렌더링 | text-anchor/dominant-baseline/font | 구현 동일 | PASS |
| 2.3.6 LogoType.image — Base64 `<image>` | href="data:image/png;base64,..." | 구현 동일 | PASS |
| 2.3.7 상/하단 스티커 텍스트 | viewBox 확장 + `<text>` | 구현 동일 | PASS |
| 2.3.8 XML 이스케이프 | &, <, >, ", ' 5종 | 구현 동일 | PASS |
| xmlns:xlink 추가 | Design 미명시 | 구현에서 추가 (`xmlns:xlink`) | PASS (개선) |

### 2.4 SVG 에셋 로더: `svg_asset_loader.dart`

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| compositeId → SVG 로드 | AssetBundle + cache | 구현 동일 | PASS |
| putCache (외부 주입) | 메서드 존재 | 구현 동일 | PASS |
| 파일 위치 | `utils/svg_asset_loader.dart` | 동일 | PASS |

### 2.5 `_saveAsSvg` 호출부 수정

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| StickerSpec → SvgLogoStyle 변환 | position/background/bgColor | 구현 동일 | PASS |
| logoType 'logo' → svgAssetLoader.load | ref.read(svgAssetLoaderProvider) | 구현 동일 | PASS |
| logoType 'image' → centerIconBase64 | c.centerIconBase64 | 구현 동일 | PASS |
| logoType 'text' → SvgLogoText 변환 | 4 fields 매핑 | 구현 동일 | PASS |
| topText/bottomText → SvgStickerText | null + isEmpty 체크 | 구현 동일 | PASS |
| generate() 호출 12 파라미터 전달 | 모든 신규 파라미터 | 구현 동일 | PASS |

### 2.6 LogoManifestRepository 인터페이스 확장

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| loadSvgContent() 인터페이스 | `Future<Result<String>>` | 구현 동일 | PASS |
| impl: bundle.loadString() | compositeId → asset.assetPath | 구현 동일 | PASS |

### Step 7: Provider 등록

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| svgAssetLoaderProvider | `Provider<SvgAssetLoader>` | 구현 동일 | PASS |

### Step 8: l10n

| Item | Design | Implementation | Status |
|------|--------|---------------|--------|
| app_ko.arb 키 추가 | Design 명시 | 불필요 (Part A에 신규 UI 문자열 없음) | N/A |

---

## Gaps Found

### Minor (1건)

| # | Severity | Gap | 파일 | Detail |
|---|----------|-----|------|--------|
| G-1 | Minor | `logo_manifest_repository_impl.dart` 주석 깨짐 | `logo_manifest_repository_impl.dart:133` | `_` prefix Helpers 구분선 주석에 유니코드 깨짐 문자 (`────────────────────────────────────────────────────`) — 기능에 영향 없으나 코드 품질 |

### Not Applicable (Part B 미구현)

Design 문서 섹션 3 (Part B: 원격 에셋 관리 시스템)은 Phase 2로 분리되어 이번 분석 범위에서 제외:
- 3.1 Supabase 테이블 스키마
- 3.2 RemoteLogoAsset 엔티티
- 3.3 동기화 리포지토리
- 3.4 캐시 데이터소스
- 3.5 Supabase 데이터소스
- 3.6 동기화 구현
- 3.7 LogoManifest 통합
- 3.8 검색 기능

---

## Summary

| Metric | Value |
|--------|-------|
| Design Items (Phase 1) | 35 |
| Pass | 34 |
| Minor Gap | 1 |
| N/A (Part B) | 8 |
| **Match Rate** | **97%** |

Phase 1 (Part A) 구현이 Design 문서와 높은 정합성을 보입니다. Minor gap 1건은 코드 기능에 영향 없는 주석 문자 깨짐입니다.
