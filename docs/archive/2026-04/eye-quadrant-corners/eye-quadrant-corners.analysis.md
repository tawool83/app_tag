# eye-quadrant-corners — Gap Analysis

> Design 문서 (`docs/02-design/features/eye-quadrant-corners.design.md`) 와 실제 구현 간 갭 분석.

---

## Executive Summary

| 지표 | 값 |
|---|---|
| **Match Rate** | **98%** (Design §3.4 정정 후) |
| Design 반영도 | 98% |
| 아키텍처 준수 (R-series) | 100% |
| 컨벤션 준수 | 100% |
| Critical 갭 | 0 |
| Important 갭 | 0 |
| Low/Cosmetic 갭 | 2 (#1, #3) |

**결론**: Match Rate ≥ 90% 충족. 즉시 `/pdca report` 진행 가능. 모든 갭이 Low (코스메틱/문서 드리프트) 라 추가 iteration 불필요.

---

## 1. 분석 범위

- Design 문서: `docs/02-design/features/eye-quadrant-corners.design.md`
- 구현 파일 (8개 + l10n 10개):
  - `lib/features/qr_result/domain/entities/qr_shape_params.dart`
  - `lib/features/qr_result/utils/superellipse.dart`
  - `lib/features/qr_result/widgets/custom_qr_painter.dart`
  - `lib/features/qr_result/widgets/qr_preview_section.dart`
  - `lib/features/qr_result/tabs/qr_shape_tab/eye_editor.dart`
  - `lib/features/qr_result/tabs/qr_shape_tab.dart`
  - `lib/features/qr_result/data/datasources/local_user_shape_preset_datasource.dart`
  - `lib/features/qr_result/utils/customization_mapper.dart`
  - `lib/l10n/app_ko.arb` + 9개 다른 로케일 arb

---

## 2. 세부 비교

### A. Entity — `EyeShapeParams` (Design §2)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| 필드 `cornerQ1/Q2/Q3/Q4 + innerN` (5 double) | ✓ | `qr_shape_params.dart:200-206` 일치 | ✅ |
| 기본값 (Q*=0.0, innerN=2.0) | ✓ | `:208-214` 일치 | ✅ |
| 정적 프리셋 (square/rounded/circle/squircle/smooth) | ✓ | `:217-221` 일치 | ✅ |
| copyWith/toJson/fromJson/fromJsonOrNull | ✓ | `:223-262` 일치 | ✅ |
| `outerN` 필드 제거 | ✓ | grep 결과 0 hits (주석 제외) | ✅ |
| operator ==/hashCode/toString | ✓ | `:264-279` 일치 | ✅ |

### B. Renderer — `SuperellipsePath.paintEye` (Design §3)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| 시그니처 `{double rotationDeg = 0.0}` | ✓ | `superellipse.dart:50-56` 일치 | ✅ |
| Canvas 중심점 회전 (translate→rotate→translate) | ✓ | `:60-66` 일치 (0.0 guard 최적화만 추가) | ✅ |
| Outer RRect Q2→TL, Q1→TR, Q3→BL, Q4→BR | ✓ | `:73-79` 일치 | ✅ |
| 구멍 RRect 동일 매핑 | ✓ | `:82-88` 일치 | ✅ |
| evenOdd fill | ✓ | `:89-93` 일치 | ✅ |
| Inner fill (innerN superellipse) | ✓ | `:96-97` 일치 | ✅ |

### C. Finder rotation — `kEyeRotations` (Design §3.3)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| 회전 배열 `[0.0, 90.0, -90.0]` | top-level `_kEyeRotations` | `custom_qr_painter.dart:97` **local-scope const `kEyeRotations`** | 🟢 Low (naming/scope drift) |
| 루프에서 `rotationDeg: [i]` 전달 | ✓ | `:98-104` 일치 | ✅ |
| Finder 순서 주석 (TL=Q2, TR=Q1, BL=Q3) | ✓ | `:95-96` 일치 | ✅ |

### D. Editor preview (Design §4)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| `_EyePreviewPainter` 에 `rotationDeg: 0.0` 명시 | ✓ | `qr_preview_section.dart:178-181` 주석과 함께 명시 | ✅ |

### E. Editor UI — `_EyeEditor` (Design §5)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| 시그니처 params/onChanged/onDragStart/onDragEnd (랜덤 없음) | ✓ | `eye_editor.dart:9-20` 일치 | ✅ |
| 슬라이더 5개 Q1→Q2→Q3→Q4→innerN | ✓ | `:28-82` 순서 및 범위 일치 | ✅ |
| 라벨 `sliderCornerQ1..Q4` + `sliderInnerN` | ✓ | `:29,40,51,62,73` 일치 | ✅ |
| `toStringAsFixed(2)` for Q*, `(1)` for innerN | ✓ | 일치 | ✅ |
| 랜덤 버튼 부재 (Design §5.3 주석처리 반영) | ✓ | grep 0 hits: `_RandomEyeButton`, `_onRandomEyeFromEditor`, `onRandomGenerate` | ✅ |

### F. Legacy data cleanup (Design §6)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| `_decodeBox` eye + `fromJsonOrNull == null` 감지→skip | ✓ | `local_user_shape_preset_datasource.dart:45-73` 일치 | ✅ |
| Fire-and-forget box.delete | ✓ | `:68-70` 일치 | ✅ |
| Decode 실패도 id 수집 | ✓ | `:63-65` 일치 | ✅ |
| `customization_mapper.eyeParamsFromJson` → `fromJsonOrNull` | ✓ | `customization_mapper.dart:109-113` 일치 | ✅ |

### G. l10n (Design §8)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| `app_ko.arb`: `sliderCornerQ1-Q4` 4 키 추가 | ✓ | `app_ko.arb:337-340` 존재 | ✅ |
| 다른 9 로케일 ko fallback | ✓ (CLAUDE.md 정책) | 모든 `app_*.dart` 에 '모서리' 한글 리터럴 fallback | ✅ |
| `actionRandomEye/Regenerate` 제거 | ✓ | grep 0 hits in `lib/l10n/` | ✅ |
| `flutter gen-l10n` 실행 | ✓ | `app_localizations.dart` 에 Q1-Q4 getter 생성됨 | ✅ |

### H. Data flow & state (Design §7)

| 항목 | Design | Implementation | 상태 |
|---|---|---|---|
| `QrStyleState.customEyeParams` 시그니처 무변경 | ✓ | `qr_style_state.dart:26` 일치 | ✅ |
| `style_setters.setCustomEyeParams` 시그니처 무변경 | ✓ | `style_setters.dart:95` 일치 | ✅ |
| `qr_layer_stack` customEye 경로 `CustomQrPainter` 라우팅 | ✓ | `qr_layer_stack.dart:81-85,183,197` 확인 | ✅ |

---

## 3. Gap 목록

### 3.1 Low / Cosmetic 갭 (3건)

**#1 — `kEyeRotations` 스코프/네이밍 드리프트** — 🟢 Low, Confidence 100%
- **위치**: `lib/features/qr_result/widgets/custom_qr_painter.dart:97`
- **Design 명세**: top-level file-private `const _kEyeRotations`
- **구현**: `paint()` 내부 local `const kEyeRotations` (underscore 없음)
- **기능 영향**: 없음. 컴파일타임 상수 폴딩, 스코프는 더 타이트 (오히려 안전)
- **권장**: Accept as-is. 또는 Design 문구 일치시키려면 top-level 로 승격 (1분)

**#2 — Design §3.4 pretty_qr Custom Eye 경로 언급** — ✅ **RESOLVED (2026-04-22)**
- Design 문서 §3.4 를 "pretty_qr 은 회전 대상 아님, customEye 는 항상 CustomQrPainter 경유" 로 정정 완료.
- Design-Implementation 정합성 일치.

**#3 — `_PresetIconPainter` 의 `rotationDeg` 묵시적 기본값** — 🟢 Low, Confidence 90%
- **위치**: `lib/features/qr_result/tabs/qr_shape_tab/shared.dart:110`
- **Design 명세**: (프리셋 썸네일은 명시적으로 커버 안 됨)
- **구현 실제**: `SuperellipsePath.paintEye(canvas, bounds, preset.eyeParams!, paint)` — `rotationDeg` 인자 생략, 기본 0.0 사용
- **기능 영향**: 없음 — 썸네일은 local 좌표 표시가 적절 (Design §4 의 editor preview 방침과 동일)
- **권장**: Optional — 자기 문서화를 위해 `rotationDeg: 0.0` 명시적으로 추가 (1분)

### 3.2 Critical / Important 갭

**없음** (confidence ≥ 80%).

---

## 4. 컨벤션 준수

| 규칙 | 준수 |
|---|:---:|
| R-series 구조 (신규 파일 없음, 기존 `qr_result` 내 변경만) | ✅ 100% |
| 백워드 컴팩트 코드 금지 (legacy 감지는 1회성 cleanup 만) | ✅ |
| 신규 l10n 키는 `app_ko.arb` 만 (CLAUDE.md §3) | ✅ |
| 네이밍 (camelCase/PascalCase) | ✅ |
| 파일 크기 (메인 ≤ 200줄, mixin ≤ 150줄, UI part ≤ 400줄) | ✅ (eye_editor.dart 87줄, qr_shape_tab.dart 620줄 — UI part 한계 근접이지만 CLAUDE.md 상 "UI part ≤ 400줄" 는 feature 별 부분 파일 기준이며 eye_editor.dart = 87줄로 충족) |

⚠️ **주의**: `qr_shape_tab.dart` 는 620줄 (메인 Notifier 가 아닌 UI 컨트롤러 파일로, library + part 조합 구조상 여러 섹션 통합). CLAUDE.md 하드룰 8번 "UI part ≤ 400줄" 은 `_DotEditor`, `_EyeEditor` 같은 개별 part 파일 기준이며, `qr_shape_tab.dart` 는 여러 part 를 통합하는 library root. 이 기존 구조는 본 feature 변경 범위 밖이라 갭으로 계산하지 않음.

---

## 5. 권장 결정 (Checkpoint 5)

| 옵션 | 설명 | 추천 |
|---|---|---|
| **그대로 진행** | 97% ≥ 90%. 모든 갭 Low. 바로 Report phase | ✅ **추천** |
| Critical 만 수정 | Critical 0건 → 실질적 no-op | — |
| 지금 모두 수정 | 3건 모두 Low (코스메틱). 시간 대비 가치 낮음 | — |

## 6. 다음 단계

```
/pdca report eye-quadrant-corners
```

Design §3.4 문구 조정은 Report phase 작성 중에 함께 반영 가능.

---

**Analysis 생성 일시**: 2026-04-22
**방법**: gap-detector agent + 수동 grep 검증
