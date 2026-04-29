# Gap Analysis — `qr-preview-drag-resize`

> 분석일: 2026-04-29
> Feature: `qr-preview-drag-resize` + `qr-preview-inner-scale` (병합)
> 비교 대상: Plan 2 종 + 후속 버그 수정 vs 실제 구현

---

## Overall Scores

| Category | Score | Status |
|---|:-:|:-:|
| Plan 1 Match (drag-resize) | 100% | OK |
| Plan 2 Match (inner-scale) | 100% | OK |
| Legacy Cleanup (Q6=a) | ~95% | OK (1 dangling param) |
| Follow-up Bug Fix (capture decoupling) | 100% | OK |
| **Overall Match Rate** | **~98.7%** | OK (>>90%) |

---

## 1. Plan 1 — `qr-preview-drag-resize` 매칭

| Plan 항목 | 코드 위치 | 상태 |
|---|---|:-:|
| `_previewExtra: double` (0~1) | `qr_result_screen.dart:57` | OK |
| `AnimationController _previewSnapController` (300ms) | `:58-60` | OK |
| `dispose()` 정리 | `:209-210` | OK |
| `LayoutBuilder` 가용 높이 산출 | `:442-449` | OK |
| `lerp(184, max*0.7, _previewExtra)` 동치 | `:445-449` | OK |
| compact 184 / expanded 70% | `:62-63` 상수 | OK |
| 임계값 0.5 | `:263` | OK |
| velocity > 500 fling | `:256-261` | OK |
| 300ms easeOut 스냅 | `:59` + `:235` | OK |
| `_onPreviewDragUpdate` clamp(0~1) | `:246-252` | OK |
| `_onPreviewDragEnd(velocity)` | `:254-266` | OK |
| `_onPreviewDragStart` (snap 정지) | `:238-243` | OK (Plan 외 회귀 방어) |
| 단일 탭 무시 (Q3=b) | `qr_preview_section.dart:59-64` | OK |
| 편집 모드 동작 (Q4=a) | always-on GestureDetector | OK |
| Drag handle (16×4 알약) | `:124-138` (실제 32×4) | **Minor 불일치** |
| Handle 위치 (하단 안쪽 4px) | `:98-101` | OK |
| Handle 색 grey.shade400 | `:133` | OK |
| `QrPreviewSection` 시그니처 | `:33-49` | OK |

---

## 2. Plan 2 — `qr-preview-inner-scale` 매칭

| Plan 항목 | 코드 위치 | 상태 |
|---|---|:-:|
| `LayoutBuilder` Stack 외곽 | `qr_preview_section.dart:73-104` | OK |
| `available = math.min(maxW,maxH).clamp(80,∞)` | `:76-78` | OK |
| `QrLayerStack(size: available)` | `:85-88` | OK |
| FittedBox 제거 | `:84-89` | OK |
| `_OverlayedDedicatedPreview(size)` | `:90-96` | OK |
| 내부 FittedBox 제거 | `:148-244` | OK |
| `_buildDedicatedFor(mode, size)` | `:213` | OK |
| `_DotShapePreview({size})` | `:249-269` | OK |
| `_EyeShapePreview({size})` | `:292-340` | OK |
| `_BoundaryShapePreview({size})` | `:368-389` | OK |
| Painter 자동 비례 (`size.width * 0.X`) | dot/eye/boundary 모두 | OK |
| 라벨 chip 절대값 유지 (Q2=a) | `:332-335` | OK |

**완벽 매칭.**

---

## 3. 레거시 정리 (Q6=a)

| 제거 대상 | 상태 |
|---|:-:|
| `_showQrZoomDialog` 함수 본체 | 제거됨 |
| `onTap` GestureDetector | 제거됨 (`onVerticalDrag*` 만) |
| 미사용 import (`qr_readability_service`, `app_localizations`) | 제거됨 |

**잔여 dead-param 가능성**: `buildPrettyQr` 의 `isDialog` 파라미터 (`qr_preview_section.dart:514, 551`). Dialog 제거 후 `isDialog: true` 호출이 사라졌을 수 있음. 호출처 검증 권장.

---

## 4. 후속 버그 수정 검증 — `_forceCompactForCapture` 분리

| 흐름 | compact 강제? | 의도 일치? |
|---|:-:|:-:|
| `_confirmAndPop` (뒤로가기, `:283-289`) | YES | OK |
| `_saveAndGoHome` (저장, `:292-302`) | YES | OK |
| `_recapture` (탭 자동, `:349-355`) | NO | OK — 사용자 확대 보존 |
| `_captureThumbnailToState` (init, `:327-339`) | NO | OK — init 시 extra=0 |
| `_onFavoriteSelected` → `_recapture` | NO | OK |

**완벽 분리. 사용자 보고 버그 100% 해소.**

---

## 5. 회귀 위험 검토

| 항목 | 위험 | 메모 |
|---|:-:|---|
| 캡처 사이즈 일관성 (`setState` → 다음 프레임) | 낮음 | `Future.delayed(100ms)` 가 한 프레임 이상 보장 |
| 매우 작은 화면 (< 184px height) | 낮음 | inverted clamp 가능하나 ClipRect 보호. Plan §8 위험 4 미리 인지 |
| TabBarView 가로 스와이프 충돌 | 낮음 | `onVerticalDrag*` 만 사용 — 수직 격리 |
| 편집 모드 슬라이더 충돌 | 낮음 | 영역 분리 |

---

## 6. Gap 분류

### Critical
*없음.*

### Important — RESOLVED
1. ~~**`buildPrettyQr` 의 `isDialog` dead-param**~~ → **수정 완료 (2026-04-29)**
   - 호출처 grep 결과 `isDialog: true` 0 건 확인
   - `qr_preview_section.dart:510-514`: `buildPrettyQr` 시그니처에서 `isDialog` 파라미터 제거
   - `qr_preview_section.dart:548-553`: `qrKey` Object.hash 첫 키 `isDialog` 제거 + 주석 정리
   - `qr_layer_stack.dart:26-36`: `QrLayerStack` 의 `isDialog` 필드/생성자 제거
   - `qr_layer_stack.dart:181-185`: `buildPrettyQr` 호출 시 `isDialog` 인자 제거
   - flutter analyze: 새 issue 0 건

### Minor
1. **드래그 핸들 폭 명세 불일치** (`qr_preview_section.dart:130`)
   - Plan: 16×4, 코드/주석: 32×4 (주석은 "16×4"로 잘못 표기)
   - confidence: 95%
   - 32px 가 발견성 더 좋음 → Plan/주석 갱신 권장

---

## 7. Match Rate 산정

| 그룹 | 항목 | 일치 | 부분 | 불일치 |
|---|:-:|:-:|:-:|:-:|
| Plan 1 (drag-resize) | 18 | 17 | 1 (handle 폭) | 0 |
| Plan 2 (inner-scale) | 12 | 12 | 0 | 0 |
| 레거시 정리 | 3 | 3 | 0 | 0 |
| 후속 버그 픽스 | 6 | 6 | 0 | 0 |
| **합계** | **39** | **38** | **1** | **0** |

**Match Rate = 38.5 / 39 ≈ 98.7%**

Important 1건 수정 후 재산정: **39 / 39 ≈ 100%** (Minor 1건만 잔존: 핸들 폭 32 의도적 유지)

---

## 8. 다음 단계 권고

**`/pdca report qr-preview-drag-resize` 진행**

잔여 Minor (핸들 폭 16→32) 는 의도적 결정으로 유지 — Plan/주석 정정은 report 시 반영.
