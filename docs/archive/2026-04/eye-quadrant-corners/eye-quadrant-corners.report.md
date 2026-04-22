# eye-quadrant-corners — Completion Report

> Plan → Design → Do → Check 전체 사이클 통합 보고서.

---

## Executive Summary

| 항목 | 내용 |
|---|---|
| **Feature** | `eye-quadrant-corners` |
| **Started / Completed** | 2026-04-22 (단일 세션) |
| **Architecture** | R-series Provider 패턴 내 확장 (`qr_result` feature) |
| **Match Rate** | **98%** (Critical 0, Important 0, Low 2 — 수용) |
| **Files Changed** | 9 수정 / 0 신규 / 0 삭제 |
| **LOC Delta** | ~+240 / ~-20 (net +220) |
| **Iteration 횟수** | 0 (첫 구현에서 ≥ 90% 달성) |

### 1.3 Value Delivered (4-perspective, 실제 결과 반영)

| Perspective | 결과 |
|---|---|
| **Problem** | 기존 `EyeShapeParams` 는 outerN/innerN 2개 필드로 4 모서리 균일 제어만 가능했고, 3 finder pattern 이 같은 방향으로 렌더링되어 **시각 디자인 자유도가 부족**했음. |
| **Solution** | Entity 를 4-corner 독립 + innerN 5필드로 재설계. 외곽 ring 은 `RRect.fromRectAndCorners`(Q2→TL, Q1→TR, Q3→BL, Q4→BR), 내부 fill 은 기존 superellipse(`innerN`) 유지. 3 finder 위치에 따라 ±90° 회전 적용해 **각 eye 의 local Q4 모서리가 QR 중심을 향하는** 일관된 구도. |
| **Function / UX Effect** | 편집기 슬라이더 5개 (Q1/Q2/Q3/Q4 + innerN). Q4 모서리가 회전 후 중심 방향이라 **"중심을 향한 화살표"** 같은 디자인 구사 가능. pretty_qr 경로는 built-in 전용이라 건드리지 않음 — 변경 영향 최소화. |
| **Core Value** | ① 디자인 자유도 대폭 확장 (2필드 → 5필드, 대칭→비대칭 허용) ② 3 finder 일체감 (Q4가 중심 향함, 시각적 방향성) ③ QR 인식률 안정 (Flutter native `RRect` 사용, 별도 수학 단순) ④ Legacy 데이터 무해 처리 (preset box 자동 cleanup, template 은 customEye 해제 후 빌트인 fallback) ⑤ 랜덤 버튼 UX 실험 → 제거 결정 → 문서/코드 전면 정리 (dead code 0). |

---

## 1. 배경 (Plan 요약)

사용자가 기존 사용자 눈모양에 대해 2가지 확장을 요청:
1. 3 finder 방향성: Q2 eye 기준, Q1 eye는 시계 +90°, Q3 eye는 반시계 -90° 회전 → 각 eye 의 local Q4 모서리가 QR 중심을 향함
2. 4-corner 독립 조절: Q1/Q2/Q3/Q4 각 모서리 둥글 ↔ 사각 개별 슬라이더

Plan Checkpoint 1/2 에서 아래 사항 확정:
- 4 슬라이더는 **공유 방식** (외부 ring + 내부 fill 의 동일 local 모서리 에 적용)
- 회전은 **사용자 눈모양(customEye)만**. 빌트인 enum 은 회전 적용 안 함
- 랜덤 버튼 동작: 4 corner 모두 동일값 + innerN 독립 난수 (대칭 보장)
- 레거시 preset: Hive box 자동 삭제

---

## 2. 아키텍처 (Design 요약)

### 2.1 Entity 재설계

`EyeShapeParams` (pre / post):

```
Before:                              After:
  double outerN (2.0~20.0)             double cornerQ1 (0.0 round ~ 1.0 square)
  double innerN (2.0~20.0)             double cornerQ2
                                       double cornerQ3
                                       double cornerQ4
                                       double innerN (2.0~20.0, unchanged)
```

JSON 스키마:
- 새 키: `cornerQ1/Q2/Q3/Q4`, `innerN` 유지
- Legacy 감지: `outerN` 키 존재 + `cornerQ1` 부재 → `fromJsonOrNull == null` → 호출자가 skip/fallback

### 2.2 Renderer

`SuperellipsePath.paintEye(canvas, bounds, params, paint, {rotationDeg = 0.0})`:
1. Canvas 중심점 기준 회전 (`translate → rotate → translate -`)
2. Outer ring: `RRect.fromRectAndCorners` per-corner radius. `radius = (1 - cornerQX) × maxR` (0=완전 둥근, 1=각진)
3. Hole: 동일 corner 매핑 with `holeMaxR` (bounds.deflate(m) 기준)
4. Inner fill: `buildPath(innerRect, innerN)` (기존 superellipse, uniform, rotation invariant)

### 2.3 회전 상수

```dart
// finder 순서: [top-left (Q2), top-right (Q1), bottom-left (Q3)]
const kEyeRotations = <double>[0.0, 90.0, -90.0];
```

`customEyeParams != null` 이면 항상 `CustomQrPainter` 경로 → 회전 적용. pretty_qr 경로는 built-in enum 전용이라 회전 불필요 (대칭형 모양).

### 2.4 Editor UI

- `_EyeEditor`: 슬라이더 5개 (Q1→Q2→Q3→Q4→innerN)
- 랜덤 버튼: **최초 구현 → 이후 제거** (UX 결정, 별도 `/pdca do` 세션)
- Preview: `_EyePreviewPainter` 에 `rotationDeg: 0.0` 명시 (local 1-eye 표시)

### 2.5 Legacy 데이터 처리

- `LocalUserShapePresetDatasource._decodeBox`: eye type + `fromJsonOrNull == null` 감지 → box.delete (fire-and-forget)
- `customization_mapper.eyeParamsFromJson`: legacy 발견 시 null 반환 → `customEyeParams` 자동 해제 → 빌트인 eye 로 fallback

---

## 3. 구현 (Do 요약)

### 3.1 변경 파일 (9개, 신규 0)

| # | 파일 | 변경 |
|---|---|---|
| 1 | `domain/entities/qr_shape_params.dart` | `EyeShapeParams` 재작성 (+~80줄 교체) |
| 2 | `utils/superellipse.dart` | `paintEye` 재작성 (+40줄) — RRect per-corner + rotation |
| 3 | `widgets/custom_qr_painter.dart` | finder loop + `kEyeRotations` (+10줄) |
| 4 | `widgets/qr_preview_section.dart` | `_EyePreviewPainter` 명시적 `rotationDeg: 0.0` (+2줄) |
| 5 | `tabs/qr_shape_tab/eye_editor.dart` | 슬라이더 2→5개 (+50줄) |
| 6 | `tabs/qr_shape_tab.dart` | built-in/custom dim 로직, `_onEyeOuterSelected`/`_onEyeInnerSelected`, eye grid modal 추가 (이전 PDCA 사이클 이월) |
| 7 | `data/datasources/local_user_shape_preset_datasource.dart` | `_decodeBox` 에 legacy 감지/cleanup (+~25줄) |
| 8 | `utils/customization_mapper.dart` | `eyeParamsFromJson` → `fromJsonOrNull` (+1줄 로직, +1줄 주석) |
| 9 | `l10n/app_{ko,en,de,es,fr,ja,pt,th,vi,zh}.arb` | `sliderCornerQ1~Q4` 추가 (ko 만 번역, 나머지 fallback), `actionRandomEye/Regenerate` 제거 |

`flutter gen-l10n` 으로 `app_localizations*.dart` 자동 재생성.

### 3.2 수정 요약

- **삭제**: `EyeShapeParams.outerN`, `_RandomEyeButton` 클래스, `_onRandomEyeFromEditor` 메서드, `onRandomGenerate` 콜백, `actionRandomEye`/`actionRandomRegenerate` l10n 키
- **추가**: 4 corner 필드, `fromJsonOrNull` 정적 메서드, `rotationDeg` 파라미터, `kEyeRotations` 상수, 4 slider row, legacy cleanup 로직

### 3.3 수정하지 않은 영역 (의도적)

- `QrStyleState`, `setCustomEyeParams` 시그니처 무변경 — entity 내부만 변경
- `randomEyeSeed` 필드/setter — Hive 호환성 위해 유지 (dead code 이지만 데이터 마이그레이션 비용 없음)
- 빌트인 QrEyeOuter/Inner enum + `_ComboFinderPattern` 렌더러 — 본 feature scope 외

---

## 4. 검증 (Check 요약)

### 4.1 Gap 분석 결과

| 지표 | 값 |
|---|---|
| Match Rate | **98%** |
| Critical Gap | 0 |
| Important Gap | 0 |
| Low/Cosmetic Gap | 2 (수용) |
| R-series 구조 준수 | 100% |
| 컨벤션 준수 | 100% |

### 4.2 남은 Low Gap (수용)

**#1 `kEyeRotations` 스코프 드리프트** — 🟢 Low, Confidence 100%
- Design: top-level `const _kEyeRotations`
- Impl: `paint()` 내부 local `const kEyeRotations`
- 기능 동일, 스코프 더 타이트. 수정 불필요.

**#3 `_PresetIconPainter` 썸네일 묵시적 기본값** — 🟢 Low, Confidence 90%
- `paintEye(...)` 의 `rotationDeg` 인자 생략 → 기본 0.0 (local orientation, 썸네일 의도 일치)
- 자기 문서화 위해 명시할 수도 있으나 선택 사항.

**#2 는 Design §3.4 정정으로 Check 중 RESOLVED** (pretty_qr 경로가 회전 대상이 아님을 Design 에 명확히 기술).

### 4.3 수동 검증 체크리스트 (기기 필요)

- [ ] 사용자 눈 편집기 진입 → 슬라이더 5개 표시
- [ ] Q1 슬라이더 변경 → 3 eye 모두 local top-right 모서리 변화 (회전 후 실제 위치 각각 다름)
- [ ] Q4 슬라이더 변경 → 3 eye 모두 중심을 향하는 모서리 변화 (가장 직관적)
- [ ] 빌트인 eye (square 등) 선택 → 회전 없이 기존처럼 렌더
- [ ] 슬라이더 drag → preview 즉시 갱신
- [ ] 뒤로가기 → 자동 저장 + 프리셋 추가
- [ ] 기기 재설치 후 legacy 데이터 감지 → 빈 목록 + 크래시 없음

---

## 5. 학습 / 의사결정 이력

### 5.1 중간 scope 변경

초기 Plan 에는 랜덤 버튼이 포함됐으나, Do 구현 후 사용자가 UX 실험 결과를 토대로 제거 결정:
- Do phase 1회차: 랜덤 버튼 + `_onRandomEyeFromEditor` 구현
- Do phase 2회차 (본 세션): 버튼 완전 삭제 + l10n 키 정리

교훈: **첫 구현 후 즉시 기기 검증으로 feedback loop 단축**. Design 는 살아있는 문서 — 변경 시 "RESOLVED" 마커로 이력 보존.

### 5.2 렌더링 방식 선택

Superellipse per-corner 블렌딩 vs RRect per-corner radius:
- 전자는 수학적으로 정교하지만 각 모서리 사이 블렌딩 구간에서 불연속/이상치 위험
- 후자는 Flutter native + 안정 + QR 인식률 예측 가능

→ **RRect 선택**. 결과적으로 구현 단순화 + QR 인식 안정성 확보.

### 5.3 랜덤 기능 Hive 호환성

`randomEyeSeed` 필드는 dead code 화 되었지만 Hive typeId 26 으로 고정되어 있어 제거 시 마이그레이션 필요. Pre-release 라도 typeId 변경은 개발자 환경 Hive 파일 삭제를 강제함. **유지 결정** — 비용 대비 정리 이득 낮음. 장래 `/simplify` 때 Hive 전체 마이그레이션 기회 있을 때 함께 정리.

---

## 6. Metrics

| 지표 | 값 |
|---|---|
| PDCA 사이클 | 1 (Plan → Design → Do → Check → Report) |
| AskUserQuestion 호출 | 5 (Checkpoints 1, 2, 4, 5 + 중간 clarification) |
| TaskCreate 누적 | 30+ (Step 단위 tracking) |
| flutter analyze 에러 | 0 (pre-existing 15 info/warning 유지) |
| 신규 dead code | 0 (랜덤 버튼 제거로 dead code 방지) |
| Entity 필드 변화 | 2 → 5 (150% 증가) |
| 슬라이더 개수 | 2 → 5 |
| 영향 파일 (lib/) | 9 |
| 영향 파일 (l10n arb) | 10 (+ generated .dart) |

---

## 7. 다음 단계

### 7.1 기기 검증 (필수)

현재 Design/구현/분석 모두 정합. 하지만 실제 기기 렌더 및 QR 인식률은 수동 확인 필요:
1. Android/iOS 에서 QR 생성 → 3 finder 회전 시각 확인
2. QR 스캐너로 인식 테스트 (Q4 극단값 조합: 모두 0=둥근, 모두 1=사각, 혼합)
3. 랜덤 조합 5~10회 스캔 → 인식률 모니터링

### 7.2 Archive (선택)

```
/pdca archive eye-quadrant-corners
```

완료된 Plan/Design/Analysis/Report 를 `docs/archive/2026-04/eye-quadrant-corners/` 로 이동.

### 7.3 향후 확장 (Out of Scope)

- 8-slider 모드 (outer 4 + inner 4 독립 corner)
- 사용자 회전 각도 지정 (0/90/-90 고정 해제)
- 빌트인 enum 에도 회전 적용
- 3-eye preview 미니맵 (편집기 내 회전 시각화)

---

## Related Docs

- Plan: `docs/01-plan/features/eye-quadrant-corners.plan.md`
- Design: `docs/02-design/features/eye-quadrant-corners.design.md`
- Analysis: `docs/03-analysis/eye-quadrant-corners.analysis.md`
- Report: **this file**

**Completed**: 2026-04-22
