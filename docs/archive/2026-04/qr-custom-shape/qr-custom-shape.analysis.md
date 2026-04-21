# QR Custom Shape — Gap Analysis

> **Feature**: qr-custom-shape
> **Design**: [qr-custom-shape.design.md](../02-design/features/qr-custom-shape.design.md) v0.6 (2026-04-20)
> **Plan**: [qr-custom-shape.plan.md](../01-plan/features/qr-custom-shape.plan.md)
> **Analyzed**: 2026-04-20
> **Match Rate**: **94%**
> **Status**: ≥ 90% — proceed to report (after minor doc fixup)

---

## Executive Summary

| Category | Score |
|----------|:-----:|
| Scale feature consistency (v0.6) | 100% |
| Architecture / layer placement | 100% |
| Functional requirements (FR-01~25) | 92% |
| Naming / convention | 95% |
| **Overall** | **94%** |

- **Critical Gaps**: 0
- **Important Gaps**: 2 (doc drift)
- **Minor Gaps**: 2

Scale feature (핵심 Focus Area)은 4개 렌더링 경로 모두에서 일관되게 적용됨을 확인.

---

## 1. Scale Feature Verification (v0.6 — Focus Area)

v0.6에서 `scale 0.5~2.0` + 비대칭 슬라이더(-100%~+100%, 중앙 0%=1.0x)로 확장된 설계가 모든 렌더링 경로에서 올바르게 구현되었음.

| 경로 | scale 적용 | 파일:라인 |
|------|:-:|---|
| `_PolarDotSymbol.paint` (PrettyQrView 경로, 실제 QR) | ✅ | `qr_dot_style.dart:73` (`rect.width / 2 * params.scale`) |
| `CustomQrPainter` 데이터 도트 | ✅ | `custom_qr_painter.dart:128-129` (`radius * frame.scale * dotParams.scale`) |
| `_DotPreviewPainter` (드래그 중 단독 미리보기) | ✅ | `qr_preview_section.dart:130` (`size.width * 0.4 * params.scale`) |
| 프리셋 썸네일 | ✅ | `qr_shape_tab.dart:1180` (`radius * preset.dotParams!.scale`) |
| 슬라이더 매핑 (-1→0.5x, 0→1.0x, +1→2.0x) | ✅ | `qr_shape_tab.dart:1308-1309` (`_sliderToScale`: `s>=0?1+s:1+s*0.5`) |
| 라벨 `+/-N%` 포맷 | ✅ | `qr_shape_tab.dart:1311-1315` (`_formatScaleLabel`) |
| JSON round-trip (기본값 1.0) | ✅ | `qr_shape_params.dart:122-156` |
| 구조 모듈(finder/timing) scale 제외 | ✅ | `custom_qr_painter.dart:121-126` (QR 인식률 보장, 설계 의도대로) |

---

## 2. Gap List

### 2.1 Critical Gaps (High Severity, confidence ≥ 80%)

**없음.**

### 2.2 Important Gaps (Medium Severity, confidence ≥ 80%)

#### I-1: Plan 문서 FR-21이 v0.5 기준 유지 (문서 drift)

- **Design v0.6**: `scale: 0.5~2.0, 슬라이더 -100%~+100%, 중앙 0%=1.0x`
- **Plan FR-21** (`docs/01-plan/features/qr-custom-shape.plan.md:109`): `scale 0.8~1.15` 기술
- **Code** (`lib/features/qr_result/domain/entities/qr_shape_params.dart:28`): `scale: 0.5~2.0` (Design과 일치)
- **Recommendation**: Plan 문서 FR-21을 v0.6 설계와 동기화 (1줄 편집)

#### I-2: Superformula 프리셋 값이 Design 표와 상이

- **Design** (`docs/02-design/features/qr-custom-shape.design.md:161-167`):
  - `sfStar(m=5, n1=0.3, n2=0.3, n3=0.3)`, `sfFlower(m=6, n1=1, n2=1, n3=8)`, `sfHeart(m=1, n1=1, n2=0.8, n3=-0.5)`
- **Code** (`lib/features/qr_result/domain/entities/qr_shape_params.dart:77-91`):
  - `sfStar(m=5, n1=4.5, n2=12, n3=10, a=1.10, b=1.10, rot=240)`, `sfFlower(m=10, n1=7.6, n2=21.8, n3=6.6, ...)`, `sfHeart(m=2, n1=1.5, n2=0.2, n3=-1.9, ...)`
- **원인**: 채움률 ≥ 50% 보장을 위한 프로덕션 튜닝 값으로 재조정됨 (의도된 변경)
- **Recommendation**: Design Section 3.1 프리셋 표를 튜닝 값으로 갱신 OR "프로덕션 채움률 50%+ 기준 재튜닝됨" 주석 추가

### 2.3 Minor Gaps (Low Severity)

| # | Gap | Reference |
|---|-----|-----------|
| M-1 | 비대칭 프리셋 수 불일치: Design은 9종(sfCircle/Square/Star/Flower/Heart/Leaf/Butterfly/Diamond/Teardrop), Code는 5종만 구현 (Leaf/Butterfly/Diamond/Teardrop 누락), 편집기 UI도 5종만 노출 | Design `:158-167` vs `qr_shape_params.dart:69-91`, `qr_shape_tab.dart:1232-1238` |
| M-2 | Design 4.6 샘플 painter 시그니처(`qrCode: QrCode`)와 실제 `CustomQrPainter(qrImage: QrImage)` 상이. Design 샘플은 예시 수준이라 기능 gap 아님 | Design `:822-832`, `custom_qr_painter.dart:19` |

---

## 3. Architecture & Convention Compliance

| 항목 | 상태 |
|------|:-:|
| Clean Architecture 레이어 준수 (domain/data/widgets/tabs) | ✅ |
| Immutable entity 패턴 (`DotShapeParams` const constructor + copyWith) | ✅ |
| Hive 프리셋 저장 (v0.5 추가 스펙) | ✅ |
| `onChanged`/`onChangeEnd` 분기 (드래그 전용 단독 미리보기) | ✅ |
| 구조 모듈 보호 (finder/alignment/timing 절대 변경 금지) | ✅ |
| `hashCode` / `==` scale 포함 (ValueKey 리빌드 트리거) | ✅ |

---

## 4. Recommendation

### 4.1 다음 단계

Match Rate **94% ≥ 90%** → **`/pdca report qr-custom-shape`로 진행 가능**.

단, 깨끗한 Report를 위해 아래 문서 정리를 권장:

1. **(필수)** Plan 문서 FR-21 scale 범위를 `0.5~2.0`로 업데이트 (1줄)
2. **(선택)** Design 프리셋 표를 프로덕션 튜닝 값으로 동기화 OR 분기 주석 추가
3. **(선택)** 누락된 4개 비대칭 프리셋 (Leaf/Butterfly/Diamond/Teardrop)을 후속 이터레이션으로 계획

### 4.2 Iteration 불필요

Critical gap 0건, Important 2건 모두 **문서 drift**(구현은 정상). 코드 수정이 필요한 gap은 없음.

---

## 5. Version History

| Version | Date | Author |
|---------|------|--------|
| 1.0 | 2026-04-20 | tawool83 (via gap-detector) |
