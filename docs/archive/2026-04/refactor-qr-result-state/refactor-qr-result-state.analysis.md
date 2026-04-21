# refactor-qr-result-state — Gap Analysis

> **Feature**: refactor-qr-result-state
> **Design**: [refactor-qr-result-state.design.md](refactor-qr-result-state.design.md) v1.0 (Option B Clean Architecture)
> **Plan**: [refactor-qr-result-state.plan.md](refactor-qr-result-state.plan.md)
> **Analyzed**: 2026-04-21 (v3 — post flat-getter removal + call-site migration)
> **Match Rate**: **97%** (v1: 88% → v2: 94% → **v3: 97%**)
> **Status**: ≥ 90%, Design §1.1 목표 모두 달성

---

## Executive Summary

| Category | v1 | v2 | v3 | Δ (v2→v3) |
|----------|:---:|:---:|:---:|:---:|
| 구조 분해 (FR-01~03, FR-09) | 100% | 100% | 100% | — |
| Notifier 재작성 (FR-05) | 100% | 100% | 100% | — |
| Hive 호환 (FR-06) | 100% | 100% | 100% | — |
| `_sentinel` 제거 (FR-07) | 100% | 100% | 100% | — |
| 읽기 API 정합 (FR-04) | 100% (flat bridge) | 100% (bridge 유지) | **100% (bridge 제거, 직접 접근)** | 완전 정합 |
| 공용 상수/enum 독립 (NFR-04) | ❌ | ✅ | ✅ | — |
| Sub-state→provider 순환 (M2) | ❌ | ✅ | ✅ | — |
| **평탄 getter 0개** (Design §1.1) | ❌ (26개) | ❌ (26개) | **✅ (0개)** | **해결** |
| **Call-site sub-state 표기** | ❌ | ❌ | **✅ (~115곳)** | **해결** |
| `qr_result_provider.dart` ≤500줄 (NFR-03) | ❌ 660줄 | 🔶 626줄 | 🔶 576줄 | -50 (76줄 초과) |
| `flutter analyze` 0 errors | ✅ | ✅ | ✅ | — |
| **전체** | **88%** | **94%** | **97%** | **+3pp** |

- Critical: 0
- Important: 0 (G2는 별도 PDCA로 공식 이관)
- Minor: 2 (M1, M3)

---

## 1. v3 Resolved (이번 세션 완료)

### ✅ G1 FULLY RESOLVED — 평탄 getter 26개 완전 제거

`QrResultState` class body가 **순수 composite** (6 필드 + copyWith + ==/hashCode). flat getter 0개.

### ✅ Call-site 115곳 일괄 마이그레이션

10개 파일 `state.xxx` → `state.sub.xxx`:
- `nfc_writer_screen.dart`, `qr_readability_service.dart`, `qr_result_provider.dart`, `action_buttons.dart`, `qr_result_screen.dart`, `qr_color_tab.dart`, `qr_shape_tab.dart`, `customization_mapper.dart`, `qr_layer_stack.dart`, `qr_preview_section.dart`

### ✅ Backward-compat `export` 4건 제거

`qr_result_provider.dart`의 4개 re-export 삭제. 소비자는 `domain/entities/*.dart` 직접 import.

### ✅ 파일 크기 축소: 626 → 576줄 (-50)

---

## 2. Remaining Important Gap (이관됨)

### 🔶 G2 (Deferred to separate PDCA) — `qr_result_provider.dart` ≤500줄

- **현재**: 576줄 (NFR-03 대비 +76 초과)
- **구성**: `QrResultNotifier` 본체 ~460줄이 파일의 80% 점유
- **이관**: `refactor-qr-notifier-split` 신규 PDCA — Notifier를 action/style/logo/template use case로 분할

---

## 3. Remaining Minor Gaps

| # | Gap | 처리 |
|---|-----|------|
| M1 | `QrStyleState.quietZoneColor` default `Colors.white` vs Design `Color(0xFFFFFFFF)` | 의미 동일, 무시 |
| M3 | Phase D `.select()` 미검증 | Plan 선택 단계, 무시 |

---

## 4. Matches (v3 전수 검증)

| Design 요구 | 구현 | 상태 |
|-------------|------|:-:|
| 5 sub-state 파일 `domain/state/` | 전부 존재 | ✅ |
| 각 sub-state: const + copyWith + ==/hashCode | 전수 검증 | ✅ |
| `clearXxx` 플래그 패턴 (sentinel 대체) | 전부 | ✅ |
| `_sentinel` 전역 제거 | — | ✅ |
| `QrResultState` 6 composite 필드 only | L38-86 | ✅ |
| **flat getter 0개 (v3 신규)** | L38-86 | ✅ |
| Notifier setter sub-state copyWith | 전체 | ✅ |
| `loadFromCustomization` sub-state 경로 | L115-147 | ✅ |
| Hive JSON 스키마 불변 | `CustomizationMapper` | ✅ |
| 공용 상수/enum 독립 파일 | 4 entity 파일 | ✅ |
| Sub-state → entity 직접 import | `qr_style_state.dart:6`, `qr_action_state.dart:3` | ✅ |
| **Call-site sub-state 표기 (v3 신규)** | ~115곳 | ✅ |
| **Provider re-export 제거 (v3 신규)** | 0건 | ✅ |

---

## 5. Recommendation

Design §1.1 의 모든 목표 (**평탄 필드/getter 0개 + composite only**) 완전 달성. NFR-03 미달은 Plan §8 Out-of-Scope 항목으로 별도 PDCA 이관.

**후속 PDCA candidate**:
1. `refactor-qr-notifier-split` — Notifier use-case 분해 (G2 해소, NFR-03 달성)
2. (선택) `qr-result-rebuild-optimization` — Phase D `.select()` 채택 + 벤치마크

---

## 6. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-04-21 | Initial Gap — Match 88%, Path 1/2 옵션 | tawool83 (gap-detector) |
| 2.0 | 2026-04-21 | Path 2 완료 — Match 94% (+6pp), G3/M2 resolved | tawool83 (gap-detector) |
| 3.0 | 2026-04-21 | Post `refactor-qr-read-sites` — Match **97%** (+3pp). 26 flat getter 제거, ~115 call-site 마이그레이션, 4 re-export 제거. G1 FULLY RESOLVED. | tawool83 (gap-detector) |
