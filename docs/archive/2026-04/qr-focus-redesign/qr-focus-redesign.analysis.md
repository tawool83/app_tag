# Gap Analysis Report: `qr-focus-redesign`

**Analysis Date**: 2026-04-13  
**Design Document**: `docs/02-design/features/qr-focus-redesign.design.md`  
**Architecture Selected**: Option B — Clean Architecture

---

## Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 94% | Good |
| Architecture Compliance | 100% | Good |
| Convention Compliance | 96% | Good |
| **Overall Match Rate** | **94%** | **Good** |

> Match rate exceeds 90% threshold — ready for `/pdca report`.

---

## Verified Matches

| Item | Design § | Implementation | Status |
|------|:---:|---|:---:|
| `QrEyeStyle` enum (square/rounded/circle/smooth) | 5.1 | `qr_result_provider.dart:49` | Match |
| `kQrPresetGradients` 8 gradients (colors/angles) | 5.2 | `qr_result_provider.dart:15-32` | Match |
| `QrResultState` new fields (tagType, roundFactor, eyeStyle, customGradient) | 5.3 | `qr_result_provider.dart:51-95` | Match |
| New notifier setters (setTagType/setRoundFactor/setEyeStyle/setCustomGradient) | 5.4 | `qr_result_provider.dart:197-211` | Match |
| `applyTemplate` preserves customGradient, applies roundFactor from template | 5.5 | `qr_result_provider.dart:222-234` | Match |
| `QrPreviewSection` ConsumerWidget + RepaintBoundary + zoom dialog | 6.1 | `qr_preview_section.dart` | Match |
| `buildPrettyQr` eyeStyle→PrettyQrShape switch mapping | 7.1 | `qr_preview_section.dart:158-171` | Match |
| Gradient priority: templateGradient ?? customGradient | 7.1 | `qr_preview_section.dart:145` | Match |
| `useIconOverlay` Stack-based icon overlay for gradient+icon | 7.1 | `qr_preview_section.dart:191, 220-244` | Match |
| `ValueKey` with full state hash for forced re-render | 7.1 | `qr_preview_section.dart:176-187` | Match |
| `buildQrGradientShader` public exported function | 7.2 | `qr_preview_section.dart:263-281` | Match |
| `TemplateThumbnail` uses `buildQrGradientShader` | 7.3 | `template_thumbnail.dart:110-116` | Match |
| `CustomizeTab` full UI (단색/그라디언트 toggle, eye shape, roundFactor) | 6.3 | `customize_tab.dart:77-248` | Match |
| 3-tab layout (추천/꾸미기/전체 템플릿) + TabController length 3 | 6.5 | `qr_result_screen.dart:108, 263-267` | Match |
| `RecommendedTab` filter (tagTypes/fallback take(6)) | 6.2 | `recommended_tab.dart:22-29` | Match |
| `TemplateRepository.getTemplates` (local-first + background Supabase sync) | 4.2 | `template_repository.dart:14-23` | Match |
| `_syncFromSupabase` updated_at comparison + full-load + cache write | 4.2 | `template_repository.dart:27-66` | Match |
| `QrTemplate` new fields `tagTypes`, `roundFactor` with fromJson | 3.2 | `qr_template.dart:166-196` | Match |
| `kQrMaxLength = 150`, `validateQrData` utility | 8 | `app_config.dart:4-21` | Match |
| `TagHistory` `HiveField(16)` for roundFactor | 9 | `tag_history.dart:56-57` | Match |
| `SupabaseService.initialize()` called in main | 10 | `main.dart:10` | Match |

---

## Gaps Found

### Critical (0)
없음.

### Important (1)

| # | Gap | Design § | Impact |
|---|-----|:---:|---|
| 1 | `validateQrData(deepLink)` 정의만 있고 실제 태그 입력 화면 "다음" 버튼 핸들러에서 호출되지 않음. 150자 제한이 end-to-end로 적용되지 않아 Plan 성공 기준 "QR 데이터 150자 이하 제한" 미충족. | 8 | QR 스캔 성공률 보장 실패 |

### Minor (3)

| # | Gap | Design § | Note |
|---|-----|:---:|---|
| 2 | 설계 §9에서 `roundFactor`로 기술했으나 구현은 `qrRoundFactor`. 기존 Hive 필드 네이밍 컨벤션(`qrLabel`, `qrColor` 등)과 일치하는 구현이 맞으므로 **설계 문서 업데이트 권장**. | 9 | 기능 동일 |
| 3 | `RecommendedTab`에 `_ClearTile` ("스타일 없음") + `onTemplateClear` 콜백 추가됨 — 설계 §6.2에 미반영. 사용자 경험상 긍정적 추가. | 6.2 | 설계 문서 보완 권장 |
| 4 | `QrGradient.==` / `hashCode`가 `type` + `angleDegrees`만 비교하고 `colors`/`stops` 미포함. 동일 타입·각도의 다른 색상 그라디언트가 동일 해시로 처리될 수 있음 (ValueKey 영향). | 3.2 | 현재 사용자 가시 이슈 없으나 잠재적으로 fragile |

---

## Design Doc Drift (설계 수정 권장)

- §9: `roundFactor` → `qrRoundFactor` (구현 컨벤션에 맞춤)
- §6.2: `RecommendedTab` 인터페이스에 `onTemplateClear` 추가
- §3.1: Supabase 스키마에 `min_engine_version` 컬럼 명시 (`template_repository.dart:86` 참조)

---

## Recommended Actions

### 즉시 (Report 전)
1. **[Important #1]** 각 태그 입력 화면(app_picker, website, contact, wifi, location, event, email, sms, clipboard)의 "다음"/"생성" 핸들러에서 `validateQrData(deepLink)`를 호출하고, 150자 초과 시 에러 메시지 표시.

### 설계 문서 수정 (코드 변경 불필요)
2. §9 `roundFactor` → `qrRoundFactor`
3. §6.2에 `onTemplateClear` 추가
4. §3.1 SQL 스키마에 `min_engine_version` 컬럼 명시

### 선택적 개선
5. `QrGradient.==`/`hashCode`에 `colors`, `stops` 포함
