# Completion Report: quiet-zone-border

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | quiet-zone 테두리선 (v1~v4 누적) |
| 기간 | 2026-04-28 ~ 2026-04-29 (4 iteration: v1 → v2(철회) → v3 → v4) |
| Match Rate | 97.5% (40/40 일치, Minor 2건) |
| Iteration | 0회 (Critical/Important 0건이라 iterate 불필요) |

### 1.3 Value Delivered

| 관점 | 내용 | 정량 지표 |
|------|------|----------|
| **Problem** | (v1) quiet zone 경계 부재로 밝은 배경에서 QR 미구분 → (v3) 선 종류 단조 + UI 라벨 중복 → (v4) 두께 조절 시 quiet zone 침범 + PNG 저장 시 quiet zone 4 모듈 미달로 스캐너 인식 위험 | quietPadding 5% (V5 ≈ 2 모듈) → QR 스펙 위반 |
| **Solution** | (v1) 토글 + 두께 슬라이더 + bgColor 재사용 → (v3) solid/dashed/dotted 선 종류 + UI 정리 → (v4) **`_kMaxBorderWidth` reserve 패턴** 도입: 안쪽 가장자리 고정, 외곽만 두께만큼 바깥 확장. quietPadding 12% 상향 (4 모듈 보장) | quietPadding 12% (V5 ≈ 4.4 모듈), reserve 4px 외부 영역 항상 확보 |
| **Function UX Effect** | 배경 탭 [테두리선] 토글 + 두께(1~4px) + 선 종류(SegmentedButton). 두께 변화 시 quiet zone 절대 불변, stroke 외곽만 배경 영역으로 확장. 외각 모양(frame) 사용 여부와 무관하게 동작 | INV-1~4 4개 불변식 100% 준수 |
| **Core Value** | **CLAUDE.md §5 QR 스펙 절대 준수 정책의 첫 적용 사례**. ISO/IEC 18004 quiet zone 4 모듈 보장 → 어떤 두께·외각 모양에서도 PNG 저장본의 스캐너 인식률 일관 보장 | reserve 패턴 정립 (재사용 가능한 디자인 패턴) |

---

## 2. PDCA 진행 이력

| Phase | 상태 | 비고 |
|-------|:----:|------|
| Plan | DONE | v1(2026-04-28) → v2(철회) → v3(2026-04-29) → v4(2026-04-29) |
| Design | DONE | v3 기준 작성 후 v4 갱신 (불변식 INV-1~4, 좌표 검증 표, frame 모드 시그니처 11개) |
| Do | DONE | v4: 1 파일 핵심 수정 (qr_layer_stack.dart) — 일반 모드 + frame 모드 |
| Check | DONE | gap-detector — 40/40 일치, Match Rate 97.5% |
| Act | SKIP | Critical/Important 0건, iterate 불필요 |

---

## 3. 변경 내역

### 3.1 v4 파일 변경 요약

| # | 파일 | 변경 유형 | 변경 내용 |
|---|------|:---------:|-----------|
| 1 | `lib/features/qr_result/widgets/qr_layer_stack.dart` | 수정 | (a) `_kMaxBorderWidth = 4.0` 상수 신설 (b) 일반 모드 quietPadding 5%→12%, contentInset 정책 변경 (`borderInset` 가변 → `borderReserve` 고정) (c) border painter `Padding(_kMaxBorderWidth - borderWidth)` 안에 배치 (d) frame 모드 innerInset 도입, Container/band/none-text padding 변경 (e) frame 모드 Layer 1.5 quiet zone border painter 추가 |
| 2 | `docs/01-plan/features/quiet-zone-border.plan.md` | 갱신 | v4 추가 — 렌더링 순서, reserve 패턴, frame 모드 적용, Revision History |
| 3 | `docs/02-design/features/quiet-zone-border.design.md` | 갱신 | v4 추가 — INV-1~4 불변식, 좌표 검증 표, §6.2 frame 모드 시그니처 |
| 4 | `docs/03-analysis/quiet-zone-border.analysis.md` | 신규 | gap-detector 분석 결과 (40/40 일치) |
| 5 | `CLAUDE.md` | 갱신 (사전 작업) | §5 QR 스펙 절대 준수 (ISO/IEC 18004) 규약 추가 |

### 3.2 v4 핵심 설계 결정

| 결정 | 근거 |
|------|------|
| **`_kMaxBorderWidth = 4.0` reserve 패턴** | 두께 가변 → 안쪽 가장자리 위치 변동 → 사용자가 보고한 "두께 조절 시 quiet zone 침범" 해결. 외부 reserve 영역 max 두께만큼 항상 확보 → 두께 변화는 stroke 외곽만 배경 영역으로 이동 |
| **quietPadding 5% → 12%** | V5(37 modules) 기준 5% ≈ 2 모듈, QR 스펙 4 모듈 미달 (스펙 위반). 12% ≈ 4.4 모듈 (스펙 + 안전 마진) |
| **border painter 위치 = `Padding(_kMaxBorderWidth - borderWidth)` 안** | Padding 으로 painter 영역을 reserve 안에 inset → stroke 안쪽 가장자리는 항상 widget.size 외곽 - `_kMaxBorderWidth` 위치 (불변). 외곽은 두께만큼 확장 |
| **frame 모드 동일 정책 적용** (v3 의 "변경 없음" 철회) | 사용자 명시: "외각모양 사용여부와 무관하게 테두리선은 별개로 동작". qrAreaSize 안쪽에서 동일 reserve 패턴 적용 + Layer 1.5 painter 추가 |
| **`borderInset` 가변 정책 폐기** (v3 → v4) | v3 의 `borderInset = borderWidth` 는 두께에 따라 contentInset 가변 → quiet zone 위치도 변동 + PNG 캡처본 외곽이 흑색 stroke → 흰 quiet zone 여백 0 → 스캐너 인식 위험 |

### 3.3 코드 변경량

| 그룹 | 추가 | 삭제 | 순증 |
|---|---|---|---|
| qr_layer_stack.dart 일반 모드 | ~10 | ~5 | +5 |
| qr_layer_stack.dart frame 모드 | ~25 | ~5 | +20 |
| 상수 정의 (파일 상단) | ~4 | 0 | +4 |
| **소계 코드** | **~39** | **~10** | **+29** |
| 문서 (plan/design/analysis) | ~250 | ~40 | +210 |

---

## 4. 검증 결과

### 4.1 컴파일

- `flutter analyze`: 신규 issue **0건** (잔존 `unnecessary_underscores` 4건은 본 작업 무관 기존 info)
- 변경 파일: `qr_layer_stack.dart` 1개 (도큐먼트 제외)

### 4.2 불변식 검증 (Design §0 INV-1~4)

| Invariant | 검증 방법 | 결과 |
|---|---|:-:|
| INV-1: quiet zone size = quietPadding ∀ borderWidth | `contentInset = quietPadding + borderReserve` 에서 `borderReserve` 가 `borderWidth` 무관 | OK |
| INV-2: stroke 안쪽 가장자리 = quiet zone 외곽 ∀ borderWidth | painter `Rect.fromLTWH(width/2, ...)` + `Padding(_kMaxBorderWidth - borderWidth)` 합산 = `_kMaxBorderWidth` 상수 (재유도) | OK |
| INV-3: quietPadding ≥ 4 모듈 | 12% 비율 + min 12 / max 32 px (V5 기준 4.4 모듈) | OK |
| INV-4: PNG 외곽 ~ stroke 외곽 = quietZoneColor | `Container(color: bgColor)` 가 widget.size 외부 영역 채움 | OK |

### 4.3 좌표 검증 표 (Design §6.1.1, widget.size=200)

| width | stroke 안쪽 위치 | stroke 외곽 위치 | 배경 영역 |
|---|---|---|---|
| 1px | 4 (고정) | 3 | 3px |
| 2px | 4 (고정) | 2 | 2px |
| 3px | 4 (고정) | 1 | 1px |
| 4px (max) | 4 (고정) | 0 (외곽 닿음) | 0px |

### 4.4 v3 회귀 (18/18 OK)

- solid/dashed/dotted 3종 painter 정상
- SegmentedButton 3-segment UI 정상
- Hive 직렬화 (toJson skip solid, fromJson null fallback) 정상
- l10n `labelBorderStyle` 키 정상 (단, M-2 중복 키 발견)

---

## 5. 잔여 Minor (별도 백로그)

| ID | 항목 | confidence | 영향 | 상태 |
|---|---|:-:|---|:-:|
| M-1 | `qr_background_tab.dart:262` 헤더 Row 와 SliderRow 사이 `SizedBox(height:4)` 누락 | 95% | cosmetic, 4px 시각적 여백 | OPEN |
| M-2 | ~~`app_ko.arb` `labelBorderStyle` 키 중복~~ | 100% | 런타임 동일 (last-wins), 린트 경고 위험 | **RESOLVED 2026-04-29** — line 340 (v4 중복분) 삭제, line 381 단일 유지. `flutter gen-l10n` + `flutter analyze` 0 issue |

---

## 6. 학습 / 개선 포인트

### 6.1 reserve 패턴 — 재사용 가능한 디자인 패턴

이번 v4 에서 도입된 "max 값 기준 reserve 영역" 패턴은 다른 가변 두께 요소에도 응용 가능:
- 슬라이더 max 와 일치하는 상수 정의
- 외부 reserve 를 *항상* max 만큼 확보
- 가변 값과 max 의 차이만큼 inset 으로 위치 조정
- 결과: 안쪽 가장자리 고정 + 외곽만 변동 (또는 그 반대)

### 6.2 CLAUDE.md §5 의 첫 적용 사례

본 작업은 사용자가 "어떤 경우라도 QR 스펙에 벗어나는 구현은 하지 않는다" 규약을 CLAUDE.md 에 추가한 직후의 첫 적용. 결과:
- 5% quietPadding 이 V5 기준 약 2 모듈로 스펙 위반이라는 사실 발견
- v3 의 가변 `borderInset` 정책이 PNG 캡처본 quiet zone 부족 야기 발견
- frame 모드 quiet zone border 누락 (외각 사용 시 미동작) 발견

규약이 가독성 좋게 명문화되어 있을 때 검증 의무가 효과적으로 작동함이 입증.

### 6.3 v3 → v4 의 retroactive 문서 갱신

기존 v3 문서가 완성도 높은 상태에서 v4 정책 추가. 문서를 폐기하지 않고 누적 변경(Revision History)로 처리하여 의사결정 흐름이 보존됨. 향후 유사 사례 (예: v2 철회 사유) 참조 가능.

### 6.4 사용자 의사소통 사이클

사용자의 "다시 설명할게" 표현으로 의도가 정확히 전달된 후 1회 만에 정확한 구현. 직전 시도는 painter 위치를 quiet zone 안쪽으로 옮긴 잘못된 해석이었으나, 사용자의 명확한 순서 기술 (QR → quiet zone → 테두리 → 배경) 로 즉시 정정.

---

## 7. 다음 단계

**선택지**:
1. **`/pdca archive quiet-zone-border`** — PDCA 문서 4종 (plan/design/analysis/report) 을 `docs/archive/2026-04/quiet-zone-border/` 로 이동 + Index 갱신.
2. **Minor 정리 micro-task** — M-1 (4px SizedBox) + M-2 (중복 ARB 키) 정리 후 archive.
3. **다른 feature 진행** — quiet-zone-border 는 보고서까지 완료 상태로 보존.

권장: M-2 (중복 ARB 키)는 lint 경고 위험이 있으므로 archive 전 정리. M-1 은 cosmetic 으로 보류.

---

## 8. Revision History

| 버전 | 날짜 | 단계 | 변경 |
|---|---|---|---|
| v1 | 2026-04-28 | 초기 구현 | 토글 + 두께 슬라이더 + bgColor 재사용. Container.BoxDecoration.border |
| v2 | 2026-04-29 | 철회 | 외각 모양 동기화 추가 (잘못된 이해) — 사용자 명확화로 철회 |
| v3 | 2026-04-29 | 확장 | solid/dashed/dotted 선 종류 + SegmentedButton + UI 정리 + `borderInset = borderWidth` 가변 정책 |
| v4 | 2026-04-29 | **CLAUDE.md §5 적용** | reserve 패턴 도입 (`_kMaxBorderWidth` 고정), quietPadding 5%→12%, frame 모드 적용, `borderInset` 가변 정책 폐기 |
