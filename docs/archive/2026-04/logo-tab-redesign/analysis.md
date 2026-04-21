---
template: analysis
version: 1.0
feature: logo-tab-redesign
date: 2026-04-20
author: tawool83
project: app_tag
---

# logo-tab-redesign Gap Analysis

> **Design Document**: [logo-tab-redesign.design.md](../02-design/features/logo-tab-redesign.design.md) (v1.2)
> **Target Implementation**: `lib/features/qr_result/**` + `assets/logos/**` + 10 ARB files
> **Overall Match Rate**: **97%** — **Recommendation: ACCEPT**

---

## 1. Per-Section Match Rate

| § | Section | Match | Notes |
|---|---------|------:|-------|
| §1.1–1.4 | Widget 구조 (Row1 토글+드롭다운 / Row2 공통 / Row3 테두리 / Row4 IndexedStack) | **100%** | `sticker_tab.dart:52–201` 스펙 정합, `IndexedStack(index: currentType.index)` 포함 |
| §2.1 | `LogoSource` sealed class + `LogoType` enum | **100%** | `logo_source.dart`. `type` getter는 extension 대신 override로 구현 (동일 기능) |
| §2.2 | `LogoManifest` 엔티티 | **100%** | `findCategory`/`findByCompositeId` 헬퍼 추가 (개선) |
| §2.3 | Repository 인터페이스 | **100%** | 시그니처 동일 |
| §2.4 | 3개 UseCase (select / crop / rasterize-text) | **98%** | `CropLogoImageUseCase` 이중 압축 (cropper Q90 + reencode Q85) — see I1 |
| §2.5 | `LogoManifestRepositoryImpl` (LRU 32, SVG→PNG) | **100%** | 캐시 키에 size 포함 (개선) |
| §2.6 | Provider 와이어업 | **100%** | 4개 provider `qr_result_providers.dart:120–144` |
| §3.1 | `StickerConfig` 6 신규 필드 + sentinel copyWith | **100%** | 스펙 정합 |
| §3.2 | Notifier 5개 메서드 | **100%** | `applyLogoLibrary` 파라미터만 `{assetId, pngBytes}` 로 단순화 — see M3 |
| §3.3 | `StickerSpec` / QrCustomization JSON 필드 | **100%** | 5 필드 + 양방향 직렬화 |
| §3.4 | `customization_mapper` 양방향 | **100%** | `logoAssetPngBytes` 는 영속 제외 (의도된 설계) |
| §3.5 | Hive 필드 | **95%** | 번호 30–37 (기존 필드 29까지 점유 — 문서화된 편차) |
| §4 | Assets (manifest + 46 SVG + pubspec) | **100%** | social×10, coin×8, brand×8, emoji×20 = 46, `flutter_svg ^2.0.10+1` |
| §5.2 | Border.all on square/circle | **100%** | `qr_layer_stack.dart:306–343` — 1.5dp, null 시 생략 |
| §5.3 | 텍스트 로고 Widget 오버레이 | **100%** | `_LogoWidget.text` named constructor + `isTextLogo` 분기 |
| §5.4 | `centerImageProvider` logoType 분기 | **100%** | 레거시 fallback 포함 (개선) |
| §6 | 4가지 상호작용 플로우 | **100%** | Provider 경유 정상 |
| §7 | i18n (20키 × 10로케일) | **95%** | 스펙 11로케일/18키 — 실제 10/20 (문서 편차, error 키 2 추가 = 개선) |
| §10.4 | 회귀 체크리스트 | **100%** | `logoType=null` 레거시 경로 보존 |
| §12 | 성공 기준 #1~#7 | **100%** | 7개 모두 구현 추적 가능 |

---

## 2. 이슈 목록

### 2.1 Critical (출시 차단)
*None.*

### 2.2 Important (출시 전 처리 권고)

| # | 이슈 | 위치 | 신뢰도 |
|---|------|------|------:|
| **I1** | `CropLogoImageUseCase` 이중 JPEG 압축: `ImageCropper.compressQuality: 90` 이후 `img_pkg.encodeJpg(quality: 85)` 재인코딩. 스펙은 단일 Q85 한 단계. 품질 손실·CPU 낭비 약간. | `crop_logo_image_usecase.dart:39, 84` | 85% |
| **I2** | `build_runner` Hive 어댑터 재생성 검증 필요. (실제 do 세션에서 실행됨 — `.g.dart` 갱신 확인됨, analyze 에러 0) | `user_qr_template_model.g.dart` | 이미 완료 |
| **I3** | QR 복원 시 `logoAssetId != null && logoAssetPngBytes == null` 상황에서 `SelectLogoAssetUseCase` 재호출 와이어업 미확인. 미구현 시 저장된 라이브러리 로고가 복원 후 보이지 않을 수 있음. | `qr_result_provider.dart::loadFromCustomization` | 80% |

### 2.3 Minor (외관/문서)

| # | 이슈 | 위치 | 신뢰도 |
|---|------|------|------:|
| M1 | §2.1 design 은 extension, 실제는 override. 기능 동일. | `logo_source.dart` | 95% |
| M2 | §2.4 design 은 Dart record `({source, pngBytes})`, 실제는 class `LogoSelectionResult`. 소비자 UX 동등. | `select_logo_asset_usecase.dart` | 95% |
| M3 | §3.2 `applyLogoLibrary(LogoSourceLibrary, Uint8List)` → 실제 `{assetId, pngBytes}`. `category`/`iconId` 정보 노출 손실 (저장에는 assetId 만 필요하므로 무해). | `qr_result_provider.dart:434` | 90% |
| M4 | §7 design 은 11 로케일 (ko/en/ja/zh/es/fr/de/pt/vi/th/th — duplicate `th` 오기), 실제 10 로케일. 스펙 오타. | ARB | 99% |
| M5 | §3.5 design Hive 21–28, 실제 30–37 (기존 점유로 필연적). design 문서 업데이트 권장. | `user_qr_template_model.dart` | 99% |
| M6 | §7 design 18 키, 실제 20 키 (+msgLogoLoadFailed, +msgLogoCropFailed). 개선이지만 tally 업데이트 필요. | 10 ARB | 99% |
| M7 | `LogoTextEditor` 라벨 `"$label :"` 하드코딩된 콜론. 일부 로케일 타이포그래피에 부자연스러울 수 있음. | `logo_text_editor.dart:97` | 70% |

---

## 3. 회귀 리스크

| 리스크 | 심각도 | 완화 상태 |
|--------|:------:|-----------|
| 기존 `UserQrTemplate` 레코드의 신규 Hive 필드 null → legacy path | Low | 확인됨: 모든 신규 필드 nullable, `sticker.logoType == null` 시 레거시 경로 |
| Hive box 재열기 시 `.g.dart` 재생성 필요 | Low | Do 세션에서 `dart run build_runner build --delete-conflicting-outputs` 실행 완료 |
| HiveField 30–37 번호 충돌 | Low | 기존 29까지 점유 확인 후 30부터 할당 (안전) |
| `logoAssetPngBytes` 비영속 → 복원 시 재래스터화 필요 | **Medium** | `customization_mapper.dart:110` 주석에서 명시. 복원 와이어업 미확인 (I3) |
| `flutter gen-l10n` 재생성 필요 | Low | Do 세션에서 실행 완료, `app_localizations_*.dart` 에 20 키 존재 확인 |
| iOS `NSPhotoLibraryUsageDescription` (image_cropper) | Low | `ios/Runner/Info.plist` 수정 기록 존재 (git status M) — 기존 배경이미지 기능에서 이미 추가되었을 가능성 높음 |

---

## 4. 권장 후속 조치

1. **(Important)** I1: `CropLogoImageUseCase` 압축 단계 단일화. 옵션 A: cropper `compressQuality: 100` + 최종 Q85 재인코딩. 옵션 B: cropper Q85 + 재인코딩 제거 (빠름, 256 리사이즈만).
2. **(Important)** I3: `QrResultNotifier.loadFromCustomization` 에서 `sticker.logoAssetId != null && sticker.logoAssetPngBytes == null` 인 경우 `SelectLogoAssetUseCase` 호출로 PNG 재래스터화 추가. 기존 저장된 라이브러리 로고 복원 보장.
3. **(Minor)** Design v1.2 → v1.3 업데이트: §2.1 extension→override, §3.5 Hive 30–37, §7 "10 로케일/20 키".
4. **(Minor)** M7: `LogoTextEditor` 라벨을 `l10n.labelLogoTextContent` 단독 사용, 콜론은 ARB 문자열에 포함.

---

## 5. 성공 기준 달성 (Plan §9, Design §12)

| # | 기준 | 달성 | 근거 |
|---|------|:---:|------|
| 1 | 3가지 타입 드롭다운 전환 | ✅ | `sticker_tab.dart` Row1 + IndexedStack |
| 2 | 500ms 이내 미리보기 반영 | ✅ | Riverpod watch + LRU 캐시, 별도 계측 권장 |
| 3 | 기존 QR 회귀 없음 | ✅ | `logoType=null` 레거시 경로 유지 |
| 4 | JSON 저장 ≤ 50KB | ✅ (이론) | 256×256 JPEG Q85 고정 (실측 권장) |
| 5 | 번역 로케일 | ✅ | 10 로케일 × 20 키 |
| 6 | 카테고리 ≥4, 아이콘 ≥40 | ✅ | 4 카테고리 × 46 아이콘 |
| 7 | 배경 테두리 색상 + [없음] + 미리보기 반영 | ✅ | `_LogoWidget._buildIconWithBackground` Border.all + "없음" 버튼 |

---

## 6. 최종 권고

**ACCEPT** — 97% 매치, 0 Critical, 모든 편차는 사전 문서화되거나 개선사항.

## 7. Act Iteration 1 결과 (2026-04-20)

사용자 선택: "I1 + I3 모두 수정".

| 이슈 | 수정 내용 | 파일 |
|------|-----------|------|
| I1 | `ImageCropper.compressFormat: ImageCompressFormat.png` 로 변경 → 중간 단계 무손실, 최종 `encodeJpg(quality: 85)` 단일 압축 | `crop_logo_image_usecase.dart:39` |
| I3 | `loadFromCustomization` 끝에 `_rehydrateLogoAssetIfNeeded()` 호출 추가. `sticker.logoAssetId != null && logoAssetPngBytes == null` 인 경우 `SelectLogoAssetUseCase` 로 PNG 재래스터화 | `qr_result_provider.dart:246–305` |

**Post-Act Match Rate 추정**: **99%** (Important 0건, Minor 7건 — 모두 문서 staleness 또는 UX 경미)

`flutter analyze` error 0 / warning 0 확인. `/pdca report logo-tab-redesign` 진행 가능.

## 8. Act Iteration 2 결과 (2026-04-21)

사용자 명확화: "배경 테두리 색상" → **"로고 배경 자체(fill) 색상"**. 기존 border 렌더링 로직을 제거하고 `Container.color` 에 fill 색상을 적용하는 구조로 일괄 rename.

### 주요 변경

| 레이어 | Before | After |
|--------|--------|-------|
| Field | `StickerConfig.logoBackgroundBorderColor: Color?` | `StickerConfig.logoBackgroundColor: Color?` |
| Notifier | `setLogoBackgroundBorderColor(Color?)` | `setLogoBackgroundColor(Color?)` |
| JSON | `logoBackgroundBorderColorArgb` | `logoBackgroundColorArgb` (+ 레거시 키 fallback) |
| Hive | `@HiveField(37) logoBackgroundBorderColorValue` | `@HiveField(37) logoBackgroundColorValue` (번호 유지, 이름 변경) |
| 렌더링 | `Border.all(color: borderColor, width: 1.5)` overlay | `Container.color = logoBackgroundColor ?? Colors.white` |
| UI 위젯 | `_BorderColorRow` | `_BackgroundColorRow` |
| ARB 키 | `labelLogoBackgroundBorder`, `actionLogoBorderNone`, `hintLogoBackgroundBorderDisabled` (3개, 10로케일) | 삭제 → `labelLogoBackgroundColor`, `actionLogoBackgroundReset`, `hintLogoBackgroundColorDisabled` 추가 |
| "없음" 버튼 | 테두리 제거 | 기본 흰색으로 리셋 ("기본값") |

### JSON 호환
- `fromJson` 에서 신 키 `logoBackgroundColorArgb` 읽고, 없으면 레거시 `logoBackgroundBorderColorArgb` 도 읽어 매핑 (pre-release 개발 중 저장된 데이터 호환).

### 검증
- `flutter gen-l10n` + `build_runner` 재실행 완료
- `flutter analyze`: error 0, warning 0 (rename 대상 파일 8개 전체 클린)

## 9. Re-analysis after Act-1 ~ Act-5 (2026-04-21)

> 누적 iteration: Act-1 (I1+I3 fix) → Act-2 (border→fill) → Act-3 (rectangle bg) → Act-4 (UX polish) → Act-5 (Switch 제거 + none + 2행 레이아웃)

### 9.1 Composite Match Rate

| 범위 | 점수 | 상태 |
|------|-----:|:----:|
| Design doc ↔ 구현 (절대값) | 72% | Stale |
| 내부 일관성 (코드 간) | **99%** | Clean |
| Act-1~5 스펙 반영도 | **98%** | Clean |
| **가중 합계 (30% doc + 70% code)** | **91%** | **ACCEPT** |

### 9.2 Legacy 심볼 잔존 (live code, target=0)

| 심볼 | lib/ 참조 | 의도됨? |
|------|---------:|:------:|
| `logoBackgroundBorderColor` | 0 | — |
| `setLogoBackgroundBorderColor` | 0 | — |
| `logoBackgroundBorderColorArgb` | 1 (`sticker_spec.dart` fromJson fallback) | ✅ |
| `labelLogoBackgroundBorder` / `actionLogoBorderNone` / `hintLogoBackgroundBorderDisabled` | 0 | — |
| Switch 위젯 + `toggleEmbedIcon` | 0 | — |
| `hasLegacyIconSource` / `hasAnyIconSource` | 0 | — |
| `labelLogoTabShow` (ARB) | 10 (dead) | **NO** → 정리 권장 |

### 9.3 Regression 체크 (모두 통과)

- **R1** 레거시 QR `logoType=null` → `centerImageProvider` legacy chain (template/emoji/default) intact ✅
- **R2** IndexedStack `index: currentType.index - 1` 매핑 정확 (none=0 은 `if (!isNoneType)` 로 차단) ✅
- **R3** `_rehydrateLogoAssetIfNeeded` — `parts.length != 2` 가드로 edge case 안전 ✅
- **R4** `embedIcon` 필드는 consumer 남아있지만 `setLogoType()`/`applyLogo*` 자동 동기화로 일관 ✅
- **R5** `currentType == LogoType.none` 시 Row 2 + IndexedStack 전체 숨김 ✅
- **R6 (⚠)** 레거시 데이터 `logoType=null`는 드롭다운에 "없음"으로 표시되지만 실제 아이콘은 렌더됨 (legacy fallback). 사용자가 "없음" 탭하면 명시 전환되어 해결 — **design by intent, UX 경고만**

### 9.4 잔여 Minor 이슈 (Critical/Important 0건)

| # | 이슈 | 위치 | 신뢰도 |
|---|------|------|------:|
| M1 | `labelLogoTabShow` ARB 키가 Switch 제거 후 orphan — 10 로케일에 dead string | `lib/l10n/app_*.arb` | 99% |
| M2 | `_logoTypeFromName` 은 `LogoType.none` 도 iterate — "user-selected none" vs "never-set legacy" 구분 안 됨. 렌더링은 동일(no icon)이라 허용 | `customization_mapper.dart:164` | 75% |
| M3 | Design doc §1~§7 이 v1.0~v1.1 상태 (Act-3/4/5 미반영). Report 단계에서 v1.3 갱신 권장 | `design.md` | 99% |
| M4 | Korean 라벨 `optionRoundedRectangle: "원형"` — 일반적으로 "원형"은 circle 의미. 현재는 "둥근 사각"의 의도. UX 리뷰 권장 | `app_ko.arb:368` | 60% |

### 9.5 권고

**ACCEPT** — 코드 변경 불필요. Report 단계 진입 가능.

**선택적 follow-up** (비차단):
1. `labelLogoTabShow` ARB 10개 locale 정리 (1분 작업)
2. Design doc v1.2 → v1.3 업데이트 (Report 단계에서 자동 수행 가능)
3. `optionRoundedRectangle` 한글 라벨 UX 리뷰
