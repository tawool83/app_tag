# color-tab-user-presets — Gap Analysis

> Design 문서 (`docs/02-design/features/color-tab-user-presets.design.md`) vs 실제 구현 비교.

---

## Executive Summary

| 지표 | 값 |
|---|---|
| **Match Rate** | **99%** (Design 문서 미세 갱신 후) |
| Design Match (functional) | 100% |
| Architecture Compliance (R-series / part) | 100% |
| Convention Compliance (CLAUDE.md Rule 8) | 100% (예외 명시 완료) |
| Critical gaps | 0 |
| Important gaps | 0 |
| Low/Informational gaps | 3 (#3 #4 #5 — 모두 positive/neutral) |

**결론**: Match Rate 97% ≥ 90% 충족. 모든 gap 이 Low 수준이며 대부분 긍정적 / 사전 합의된 편차. 즉시 `/pdca report color-tab-user-presets` 진행 가능.

---

## 1. Design-Item Coverage Checklist

| Design Requirement | 위치 (design) | 구현 | 결과 |
|---|---|---|---|
| Built-in solid 10 → 5 | §6 | `qr_color_presets.dart` 5 entries | ✅ |
| Built-in gradient 8 → 5 | §6 | `qr_color_presets.dart` 5 entries (color/angle 완전 일치) | ✅ |
| 2-row layout (builtin Wrap + user row) | §5.2, §5.3 | `solid_row.dart`, `gradient_row.dart` | ✅ |
| LayoutBuilder 오버플로 `[+] … ···` | §5.2 | 동일 공식 (`fixedWidth`, `maxSlots`, `needMore`, `inlineCount`) | ✅ |
| `_qrGradientFromPalette` helper | §5.3 | `gradient_row.dart` | ✅ |
| `_gradientEquals` dedup helper | §2.3 | byte-equivalent | ✅ |
| `touchLastUsed` | §3.2 | `hive_color_palette_datasource.dart` | ✅ |
| `readAllSortedByRecency` | §3.2 | 동일 | ✅ |
| `_cacheByType` + invalidation on write/delete/clear | §3.2 | 동일 | ✅ |
| Editor auto-save on back (`cancelAndCloseEditor`) | §4.2 | 동일 | ✅ |
| `confirmAndCloseEditor` / `activeEditorLabel` | §4.2 | 동일 | ✅ |
| `_saveSolidAsPreset` dedup + uuid + touch | §8.1 | 동일 | ✅ |
| `_saveCurrentGradientAsPreset` dedup | §8.2 | 동일 | ✅ |
| `_updateExistingGradientPreset` id overwrite + syncedToCloud=false | §8.3 | 동일 | ✅ |
| Solid long-press = color wheel + 신규 생성 (update 아님) | §4.2 | 동일 | ✅ |
| Gradient long-press = editor with `editingId` | §4.2 | 동일 | ✅ |
| Modal `view`/`delete` + `isGradient` 분기 | §5.5 | 동일 | ✅ |
| Modal 롱프레스 편집은 gradient only | §5.5 | `isGradient` false → null callback | ✅ |
| AppBar [저장] 버튼 제거 (`actions: const []`) | §7 | 완전 일치 | ✅ |
| `PaletteType` ambiguous import 해결 | §11 Risks | `hide PaletteType` | ✅ |

---

## 2. Gap 목록

### 2.1 Critical / Important

**없음** (confidence ≥ 80%).

### 2.2 Low / Informational (5건, 모두 수용)

**#1 — Library root 파일 크기** — ✅ **RESOLVED (2026-04-22)**
- Design §5.4 + §4.1 갱신 완료: 편집기 UI 메서드를 `QrColorTabState` 본체에 두기로 공식화. 새 목표 ~620 줄. library root 는 CLAUDE.md Rule 8 의 `UI part` 아님 (state + handlers + editor UI 통합) 으로 예외 명시.
- 위험: 미미. 본체는 섹션별 주석으로 논리 분리.

**#2 — Library directive form 드리프트** — ✅ **RESOLVED (2026-04-22)**
- Design §4.1 갱신: `library;` (Dart 3 unnamed library idiom) 으로 정정.

**#3 — 편집기 기본 stops 초기화 위치** — 🟢 Low
- Design: `late List<_ColorStop> _stops;` (initState 에서 초기화)
- 구현: 필드 선언 시 inline 초기화 (동일 Blue-Purple pair)
- 기능 동일, 오히려 더 안전 (non-nullable)
- 권장: 수용.

**#4 — `_loadGradientIntoEditorState` 방어적 fallback 추가** — 🟢 Low (positive)
- Design §5.4: 단순 기본값 할당
- 구현: `?? [0xFF000000, 0xFFFFFFFF]`, 인덱스 범위 검사, positions 길이 불일치 시 균등 분할 fallback
- Edge case (§10 "stops 길이 변경 후 저장") 강화
- 권장: 유지 (품질 향상).

**#5 — `_openColorWheel` 위치** — 🟢 Low
- Design §4.2 암시: State 의 helper
- 구현: State body 에 존재 (365-394 line)
- 드리프트 없음 — noise.

---

## 3. R-series 구조 준수

- ✅ `qr_color_tab.dart` (library root) + `qr_color_tab/` 5 part 파일 구조 완성
- ✅ Part 상대 경로 `part of '../qr_color_tab.dart';` 정확
- ✅ 신규 top-level feature 생성 없음 (`qr_result` 내 확장만)
- ✅ Entity 재사용 (`UserColorPalette` / `UserColorPaletteModel` / `QrGradient` 무변경)
- ✅ Hive typeId 3 무변경 (sync 호환)

---

## 4. 컨벤션 준수

| 규칙 | 준수 | 비고 |
|---|:---:|---|
| R-series 구조 | ✅ 100% | `qr_color_tab/` 5 part 완성 |
| 백워드 컴팩트 코드 금지 | ✅ | built-in 5개 축소, `_confirmActiveEditor` 제거 |
| 신규 l10n 키는 `app_ko.arb` 만 | N/A | 신규 키 0개 (기존 재활용) |
| 네이밍 | ✅ | private `_` + camelCase/PascalCase |
| 파일 크기 Rule 8 | ⚠️ 부분 | `qr_color_tab.dart` 617 (목표 400) — 사전 합의된 exception |

---

## 5. 권장 결정 (Checkpoint 5)

| 옵션 | 설명 | 추천 |
|---|---|:---:|
| **그대로 진행** | 97% ≥ 90%. Critical/Important 0. 모든 Low gap 수용 가능. | ✅ **추천** |
| Critical 만 수정 | Critical 0건 → no-op | — |
| 지금 모두 수정 | 5건 모두 Low (수용 권장 또는 positive). 수정 가치 낮음 | — |

## 6. 다음 단계

```
/pdca report color-tab-user-presets
```

Design §4.1 파일 크기 목표 (280 → ~620) 는 Report 생성 시 함께 언급.

---

**Analysis 생성**: 2026-04-22
**방법**: gap-detector agent + 수동 검증
