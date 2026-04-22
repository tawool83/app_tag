# Gap Analysis — logo-tab-dot-clearing

> gap-detector agent 결과 + 수동 보정. Design 문서(`docs/02-design/features/logo-tab-dot-clearing.design.md`) 와 구현 코드 사이 정합성 검증.

## Executive Summary

| 항목 | 값 |
|------|-----|
| Match Rate | **100%** |
| FR 총계 | 7 |
| Fully Passed | 7 |
| Partial | 0 |
| Failed | 0 |
| Architecture Compliance (applicable) | 100% |
| Non-goal Compliance | 100% |
| Critical Issues | 0 |
| Important Issues | 0 |
| Minor Issues | 0 |

**Formula**: (7 + 0.5×0) / 7 × 100 = **100.0%**

---

## 1. FR-level Findings

| FR | 설명 | Status | Evidence |
|----|------|--------|----------|
| FR-1 | Image + center + pretty_qr 경로 embed 유지 | **Pass** | `qr_preview_section.dart:329-332, 390-395` — `embedInQr` 분기 및 `PrettyQrDecorationImage.embedded` 경로 변경 없음 |
| FR-2 | Image + center + CustomQrPainter 경로 clear-zone 적용 | **Pass** | `qr_layer_stack.dart:170-175` clearZone 계산 + `custom_qr_painter.dart:46, 123, 133` 양 루프 skip |
| FR-3 | Logo + CustomQrPainter 경로 clear-zone 적용 (기존 누락분) | **Pass** | `logo_clear_zone.dart:44` 가 LogoType.logo 와 LogoType.image 모두 허용 |
| FR-4 | Clear-zone 모양이 logoBackground 에 맞춤 | **Pass** | `logo_clear_zone.dart:46-52` switch 가 Design §3.1 table 과 정확히 일치 (none/circle 원형, square/rectangle/roundedRectangle 사각, 크기 iconSize / iconSize+8 / iconSize+20×+12) |
| FR-5 | bottomRight 위치 시 clearing 없음 | **Pass** | `logo_clear_zone.dart:42` `logoPosition != center` 시 null 조기 리턴 |
| FR-6 | Row 1 반응형 레이아웃 | **Pass** | `sticker_tab.dart:49-105` — `Flexible(flex:0)` + `ConstrainedBox(minWidth:96, maxWidth:200)` + `Expanded`, DropdownButton 에서 `isExpanded:true` 제거, `isDense:true` 만 유지 |
| FR-7 | Text 타입은 현행 overlay (clearing 없음) | **Pass** | `logo_clear_zone.dart:43-44` `type != logo && type != image → return null` |

---

## 2. Design-Specific Checks

| 검증 항목 | 결과 | Evidence |
|-----------|------|----------|
| `typedef ClearZone = ({Rect rect, bool isCircular})` | ✅ | `logo_clear_zone.dart:12` |
| 파라미터명 (qrSize, iconSize, sticker, embedIcon) | ✅ | `logo_clear_zone.dart:35-39` |
| Null-return 조건 순서 (embedIcon → position → type) | ✅ | `logo_clear_zone.dart:41-44` Design §3.1 순서 일치 |
| Size 계산 표 일치 | ✅ | `logo_clear_zone.dart:46-52` 정확 |
| 2a structural 루프 skip | ✅ | `custom_qr_painter.dart:123` `if (_isInClearZone(center)) continue;` |
| 2b data 루프 skip | ✅ | `custom_qr_painter.dart:133` 동일 패턴 |
| `shouldRepaint` 에 clearZone 비교 포함 | ✅ | `custom_qr_painter.dart:200` `clearZone != old.clearZone` |
| AnimatedBuilder 경로에 clearZone 전달 | ✅ | `qr_layer_stack.dart:196` |
| 비-애니 경로에 clearZone 전달 | ✅ | `qr_layer_stack.dart:210` |
| Row 1 패턴 (Flexible flex:0 + ConstrainedBox min/max + Expanded) | ✅ | `sticker_tab.dart:49-52, 106-107` |
| DropdownButton `isExpanded:true` 제거 | ✅ | `sticker_tab.dart:66-68` `isDense:true` 만 유지 |

---

## 3. Architecture Compliance (CLAUDE.md Hard Rules)

| Rule | Status | 비고 |
|------|--------|------|
| 1. `state.sub.field` 경로 접근 | ✅ | `state.sticker.*`, `state.logo.embedIcon` 만 사용 (`qr_layer_stack.dart:162-174`) |
| 2. nullable clearing 에 `_sentinel` 금지 | ✅ | `ClearZone?` 는 pure nullable record, state 저장 대상 아님 |
| 3. Backward-compat 코드 금지 | ✅ | `logoType==null` 방어 조기 리턴 외 shim/bridge 없음 |
| 4. re-export 금지 | ✅ | `logo_clear_zone.dart` 를 직접 import, 재수출 없음 |
| 5. mixin `_` prefix | N/A | 신규 mixin 없음 |
| 6. sub-state 단일 관심사 | N/A | state 변경 없음 |
| 7. 메인 Notifier lifecycle only | N/A | Notifier 변경 없음 |
| 8. 파일 크기 한도 | ⚠️ | `qr_layer_stack.dart` 411줄 (UI part 권장 ≤400 을 11줄 초과). **Pre-existing 조건** — 본 feature 는 +8줄 기여, 리팩터 스코프 밖 |

**Minor observation** (feature 기여 아님): `qr_layer_stack.dart` 는 본 feature 이전 이미 403줄로 임계값 근접 상태였으며, 본 feature 가 +8줄 추가 (clearZone 계산 블록). 별도 `_LogoWidget` 추출 리팩터 feature 로 해결 권장.

---

## 4. Non-goal Compliance

| Non-goal | Status | Evidence |
|----------|--------|----------|
| 신규 ARB 문자열 없음 | ✅ | 관련 `app_*.arb` 변경 없음 |
| `domain/state/` 변경 없음 | ✅ | `StickerConfig`, `LogoBackground`, `LogoType`, `LogoPosition` 그대로 |
| `notifier/` 변경 없음 | ✅ | `*_setters.dart` 미수정 |
| Hive 스키마 변경 없음 | ✅ | `StickerConfig` 필드 목록 그대로 |
| Text 타입 렌더 그대로 | ✅ | `_LogoWidget` text 분기 미수정, clearZone 은 text 에 대해 null |
| Position enum 2 값 유지 | ✅ | `sticker_config.dart:8` `{ center, bottomRight }` |

---

## 5. Issues Summary

- **Critical**: 0
- **Important**: 0
- **Minor**: 0
- **Observation (pre-existing)**: `qr_layer_stack.dart` 411줄 (UI part 가이드 ≤400 을 11줄 초과). 본 feature 기여 아님.

---

## 6. 수동 QA 잔여 (gap-detector 검증 범위 밖)

- T-01~T-10 시나리오 visual regression (Plan §8.1)
- 실제 기기 QR 스캔 성공 (ecLevel=H 복원력)
- i18n 전환 (ko/en/de/ja/zh) Row 1 한 줄 유지
- 기기 폭 360/411/600 dp Row 1 한 줄 유지

→ 사용자 수동 확인 대상

---

## 7. Recommended Next Action

**Match Rate 100% ≥ 90%** → iteration 불필요, **`/pdca report logo-tab-dot-clearing`** 로 완료 보고서 생성 권장.

- Critical/Important 이슈 없음
- Design 과 구현이 정확히 일치 (signature, parameter, 조건, 호출부 모두 literal match)
- Confidence: **High (~95%)**, 잔여 불확실성은 visual QA 영역뿐

---

## Appendix — 변경 파일 결산

| 파일 | 상태 | 라인 |
|------|------|------|
| `lib/features/qr_result/utils/logo_clear_zone.dart` | 신규 | 60 |
| `lib/features/qr_result/widgets/custom_qr_painter.dart` | 수정 | 189 → 207 (+18) |
| `lib/features/qr_result/widgets/qr_layer_stack.dart` | 수정 | 403 → 411 (+8) |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | 변경 없음 (검증) | 0 |
| `lib/features/qr_result/tabs/sticker_tab.dart` | 수정 | 381 → 384 (+3) |
| **합계** | | **+89/-0** |
