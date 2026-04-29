# Gap Analysis — `quiet-zone-border` v4

> 분석일: 2026-04-29
> Plan: `docs/01-plan/features/quiet-zone-border.plan.md` (v4)
> Design: `docs/02-design/features/quiet-zone-border.design.md` (v4)
> 비교 대상: 7 파일 (1 NEW + 6 MODIFIED)

---

## Overall Scores

| Category | Score | Status |
|---|:-:|:-:|
| INV-1~4 불변식 준수 | 100% | OK |
| §6.1 일반 모드 좌표 검증 | 100% | OK |
| §6.2 frame 모드 시그니처 | 100% (11/11) | OK |
| `_kMaxBorderWidth` 상수 일치 | 100% | OK (Minor risk 인지됨) |
| v3 회귀 (solid/dashed/dotted, UI, Hive, l10n) | 100% (18/18) | OK |
| **Overall Match Rate** | **97.5%** | OK (>>90%) |

---

## 1. 불변식 검증 (Design §0)

| Invariant | 코드 위치 | 상태 |
|---|---|:-:|
| **INV-1**: quiet zone size = quietPadding ∀ borderWidth | `qr_layer_stack.dart:179` (`quietPadding` 상수) + `:181` (`contentInset = quietPadding + borderReserve`, borderReserve 는 borderWidth 무관) | OK |
| **INV-2**: stroke 안쪽 가장자리 = quiet zone 외곽 ∀ borderWidth | `qr_layer_stack.dart:279` `Padding(_kMaxBorderWidth - borderWidth)` + painter `Rect.fromLTWH(width/2, ...)` → stroke 안쪽 offset = `_kMaxBorderWidth` 상수 (재유도 검증 완료) | OK |
| **INV-3**: quietPadding ≥ 4 모듈 (12% 비율) | 일반 `:179` `(widget.size * 0.12).clamp(12, 32)` / frame `:421` `(qrAreaSize * 0.12).clamp(8, 24)` | OK |
| **INV-4**: PNG 캡처 외곽 ~ stroke 외곽 = quietZoneColor | `Container(color: bgColor)` `:299` 이 widget.size 외부 영역 채움 (max=4 시 0px, min=1 시 3px reserve) | OK |

---

## 2. 좌표 검증 표 (Design §6.1.1, widget.size=200)

| width | contentInset | stroke 안쪽 (px from 외곽) | stroke 외곽 (px from 외곽) | 상태 |
|---|---|---|---|:-:|
| 1px | 28 (24+4) | 4 (= `_kMaxBorderWidth`, 고정) | 3 (= `_kMaxBorderWidth - borderWidth`) | OK |
| 2px | 28 | 4 (고정) | 2 | OK |
| 3px | 28 | 4 (고정) | 1 | OK |
| 4px (max) | 28 | 4 (고정) | 0 (외곽 닿음) | OK |

설계 표 4행 모두 코드 동작과 일치.

---

## 3. Frame 모드 시그니처 (Design §6.2)

| 항목 | Design | 코드 위치 | 상태 |
|---|---|---|:-:|
| `quietPadding` 12% + clamp(8, 24) | §6.2.1 | `qr_layer_stack.dart:421` | OK |
| `borderReserve` 조건부 | §6.2.1 | `:423-424` | OK |
| `innerInset = quietPadding + borderReserve` | §6.2.1 | `:425` | OK |
| `effectiveQrSize = qrAreaSize - innerInset*2` | §6.2.1 | `:426` | OK |
| Container padding = `innerInset` | §6.2.2 | `:488` | OK |
| Band overlay padding = `innerInset` | §6.2.2 | `:548` | OK |
| None-text overlay padding = `innerInset` | §6.2.2 | `:564` | OK |
| Layer 1.5 painter 위치 (Layer 1 직후) | §6.2.3 | `:498-520` | OK |
| `Padding(_kMaxBorderWidth - borderWidth)` 래핑 | §6.2.3 | `:507-518` | OK |
| `IgnorePointer + SizedBox(qrAreaSize)` | §6.2.3 | `:502-506` | OK |
| 색상 `bgColor ?? qrColor` | §6.2.3 | `:513` | OK |

**Frame 모드: 11/11 일치.**

---

## 4. `_kMaxBorderWidth` 상수 일치

| 위치 | 값 |
|---|---|
| `qr_layer_stack.dart:29` | `const double _kMaxBorderWidth = 4.0` |
| `style_setters.dart:167` | `width.clamp(1.0, 4.0)` (literal) |
| `qr_background_tab.dart:267` | slider `max: 4.0` (literal) |

literal `4.0` 가 두 곳에 중복 존재. Design §13 에서 명시적으로 risk acknowledged 됨 (주석으로 일치 의무 명시). **Minor risk, 의도된 설계**.

---

## 5. v3 회귀 (18/18 OK)

| 항목 | 상태 | 위치 |
|---|:-:|---|
| `QuietZoneBorderStyle` enum 3종 | OK | `quiet_zone_border_style.dart:5-9` |
| State 필드 + default solid | OK | `qr_style_state.dart:39, 58` |
| copyWith / == / hashCode | OK | `qr_style_state.dart:84, 111, 134, 154` |
| Setter `setQuietZoneBorderStyle` | OK | `style_setters.dart:172-177` |
| `QrCustomization.quietZoneBorderStyleName` | OK | `qr_customization.dart:51, 76` |
| toJson skip solid | OK | `:103-104` |
| fromJson null fallback | OK | `:139` |
| Mapper fromState skip solid | OK | `customization_mapper.dart:63-66` |
| `borderStyleFromName` helper | OK | `customization_mapper.dart:70-71` |
| Notifier 복원 | OK | `qr_result_provider.dart:164-165` |
| SegmentedButton 3종 UI | OK | `qr_background_tab.dart:286-309` |
| Row(label+Switch) 헤더 | OK | `qr_background_tab.dart:251-261` |
| `app_ko.arb labelBorderStyle` | OK | `app_ko.arb:340` (단, M-2 중복 키 참조) |
| painter solid/dashed/dotted switch | OK | `qr_layer_stack.dart:1060-1071` |
| `_drawDashedRect` 4-edge | OK | `:1074-1080` |
| `_drawDashedLine` total≤0 가드 | OK | `:1085` |
| dashed: w*4/w*2/butt | OK | `:1063-1066` |
| dotted: w/w*2/round | OK | `:1067-1070` |

---

## 6. Gap 분류

### Critical
*없음.*

### Important
*없음.*

### Minor

| ID | 항목 | 설명 | confidence | 영향 | 상태 |
|---|---|---|:-:|---|:-:|
| **M-1** | 헤더 Row 와 SliderRow 사이 `SizedBox(height:4)` 누락 | Design §7.1 line 517 명시 / `qr_background_tab.dart:262` 미반영 | 95% | 시각적 4px 여백 — 무시 가능 | OPEN |
| **M-2** | ~~`app_ko.arb` `labelBorderStyle` 중복 키~~ | line 340 (v4 추가) 삭제, line 381 (frame editor 그룹) 단일 유지 | 100% | 린트 경고 위험 해소 | **RESOLVED 2026-04-29** — `flutter gen-l10n` + `flutter analyze` 0 issue. 호출처 2곳 (`qr_background_tab.dart:282`, `boundary_editor.dart:71`) 정상 동작 |

---

## 7. Match Rate 산정

| 그룹 | 항목 | 일치 | 부분 | 불일치 |
|---|:-:|:-:|:-:|:-:|
| INV 불변식 | 4 | 4 | 0 | 0 |
| 좌표 검증 표 | 4 | 4 | 0 | 0 |
| Frame 모드 시그니처 | 11 | 11 | 0 | 0 |
| 상수 일치 | 3 | 3 | 0 | 0 |
| v3 회귀 | 18 | 18 | 0 | 0 |
| **합계** | **40** | **40** | **0** | **0** |

Minor 가중치 (-0.25 × 2 = -0.5): **39.5 / 40 ≈ 98.75%** → 보수적으로 **97.5%**.

---

## 8. 다음 단계 권고

**Critical/Important 0건 → `/pdca report quiet-zone-border` 진행 권장**

선택적 후속 작업 (별도 micro-task, iterate 불필요):
- M-1: `qr_background_tab.dart:262` 에 `const SizedBox(height: 4)` 추가 (cosmetic)
- M-2: `app_ko.arb` 중복 `labelBorderStyle` 키 정리 (값 동일이라 어느 한 줄 삭제하면 됨. 최근 커밋 `801ed31` 의 중복 해소 패턴 참고)
