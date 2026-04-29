# Plan — QR 미리보기 내부 QR 동반 확대

> 생성일: 2026-04-29
> Feature ID: `qr-preview-inner-scale`
> 트리거: `qr-preview-drag-resize` 후속. 미리보기 박스는 커지는데 안의 QR 은 160 으로 고정.

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 미리보기 드래그로 박스 높이가 184→화면70% 로 확대돼도, 내부 `QrLayerStack` 과 dedicated 미리보기가 `size: 160` 로 하드코딩돼 있어 그대로. `FittedBox(scaleDown)` 은 축소 전용이라 확대 안 됨. |
| **Solution** | 미리보기 박스 안에서 `LayoutBuilder` 로 가용 정사각 크기 산출 → `QrLayerStack(size: available)` 와 dedicated 미리보기들에 동적 size 전달. FittedBox 제거. |
| **Function UX Effect** | 박스 확대와 함께 QR 도 비례 확대. 사용자가 디테일(도트/눈/외곽) 을 큰 화면으로 확인 가능. dedicated 모드(편집)도 동일 동작. |
| **Core Value** | 드래그 확대의 의미 회복 — 박스가 아니라 *QR* 을 크게 보고 싶었던 본래 의도 충족. |

---

## 1. 현재 동작 (Bug)

### 1.1 `qr_preview_section.dart`
- L67-68: `SizedBox(height: height)` — 부모에서 동적 height 받음 ✓
- L80-85: 그러나 내부 QR 은
  ```dart
  Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,        // ← 축소만 됨, 확대 안 됨
      child: QrLayerStack(deepLink: deepLink, size: 160),  // ← 하드코딩
    ),
  ),
  ```
- L226, 246, 301, 355: dedicated 미리보기 (`_DotShapePreview`, `_EyeShapePreview`, `_BoundaryShapePreview`) 모두
  ```dart
  SizedBox(width: 160, height: 160, ...)   // 하드코딩
  ```
- L226-230: overlay 도 `FittedBox(BoxFit.scaleDown)` 으로 감싸 확대 안 됨

### 1.2 결과
| height (parent) | inner QR 실제 크기 |
|---|---|
| 184 | 160 (160 ≤ available 160 → 그대로) |
| 300 | 160 (FittedBox.scaleDown 은 확대 X) |
| 600 | 160 (동일) |

---

## 2. 변경 사항

### 2.1 가용 정사각 크기 산출
미리보기 Container 안에서 `LayoutBuilder` 로 가로/세로 중 작은 값 → QR 크기.
```dart
final available = math.min(constraints.maxWidth, constraints.maxHeight);
```
- Container padding (12px × 2 = 24) 는 LayoutBuilder 가 자동 처리 (constraints 가 inner 영역 기준)
- 최소 80px 보장 (`clamp(80, ∞)`)

### 2.2 `QrLayerStack` 동적 사이즈
- L83: `QrLayerStack(deepLink: deepLink, size: 160)` → `size: available`
- FittedBox 제거 (직접 사이즈 전달이 더 정확)

### 2.3 Dedicated 미리보기들 동적 사이즈
3개 위젯에 `size` 파라미터 추가:
- `_DotShapePreview({required size, ...})`
- `_EyeShapePreview({required size, ...})`
- `_BoundaryShapePreview({required size, ...})`

`SizedBox(width: size, height: size, ...)` 로 변경.

### 2.4 Overlay FittedBox 제거
`_OverlayedDedicatedPreview` 가 inner widget 에 size 직접 전달 → FittedBox 불필요.
`_buildDedicatedFor(mode, size)` 시그니처로 size 전파.

### 2.5 폰트/라벨 비율 검증
- `_EyeShapePreview` 의 4 개 chip 라벨 (1/2/3/4): `Positioned(top:4, right:6, ...)` 절대값 → 큰 박스에서도 그대로 작은 4px/6px → 시각적 위화감 가능.
  - **결정**: 그대로 유지. 라벨은 위치 인식용이라 크기는 작아도 됨. 큰 박스에서 더 작아 보이는 것 OK.
  - 필요 시 후속 작업으로 size 비례 (`size * 0.025`).

### 2.6 dedicated `eyeSize` 비례
- `_EyePreviewPainter` 가 `size.width * 0.8` 사용 → 자동 비례 ✓
- `_DotPreviewPainter` 가 `size.width * 0.4 * params.scale` → 자동 비례 ✓
- `_BoundaryPreviewPainter` 가 `size.width * 0.9` → 자동 비례 ✓

---

## 3. Architecture (CLAUDE.md 고정)

### 3.1 상태 위치
- 추가 state 없음. 부모(`_QrResultScreenState`) 의 `currentHeight` 가 이미 LayoutBuilder 로 흘러옴.
- `QrPreviewSection` 내부에서 `LayoutBuilder` 로 가용 사각 사이즈 산출 → 자체 위젯들에 전달.

### 3.2 신규 컴포넌트
- 없음. 시그니처 확장만.

### 3.3 데이터 흐름
```
_QrResultScreenState
  └ currentHeight (lerp 184 ↔ screen×0.7)
     └ QrPreviewSection(height: currentHeight)
        └ SizedBox(height) → Container(pad 12) → Stack
           └ LayoutBuilder
              ├ available = min(maxW, maxH)
              ├ QrLayerStack(size: available)        ← 변경
              └ _OverlayedDedicatedPreview(size: available)  ← 변경
                 └ _DotShapePreview(size) / _EyeShapePreview(size) / _BoundaryShapePreview(size)
```

---

## 4. 변경 파일 (1개)

| 파일 | 변경 |
|------|------|
| `lib/features/qr_result/widgets/qr_preview_section.dart` | (a) Stack 외부 `LayoutBuilder` 추가, available 산출 (b) `QrLayerStack(size: 160)` → `size: available`, FittedBox 제거 (c) `_OverlayedDedicatedPreview` 에 `size` 인자 추가, FittedBox 제거 (d) `_DotShapePreview`/`_EyeShapePreview`/`_BoundaryShapePreview` 에 `size` 인자 추가, `SizedBox(width: size, height: size)` 로 변경 |

총 **수정 1개 파일**. 신규 0개. 예상 ~30줄 추가/수정.

---

## 5. 세부 결정

| 항목 | 결정 | 근거 |
|---|---|---|
| 가용 사각 산출 | `LayoutBuilder + min(maxW, maxH)` | Container padding 자동 반영, 박스가 가로/세로 중 어느 쪽이 더 작은지 적응 |
| 최소 사이즈 | 80px (`clamp(80, ∞)`) | 너무 작은 화면 방어 |
| FittedBox | 제거 | 직접 size 전달이 정확. scaleDown 효과는 LayoutBuilder 가 maxW 한계로 자동 보장 |
| dedicated 라벨 chip 사이즈 | 절대값 유지 (`top:4, right:6`) | 라벨은 위치 인식용. 시각 균형 약간 깨지지만 가독성 영향 없음. 후속 작업으로 비례 가능 |
| 폰트 사이즈 | dedicated painter 들 모두 size 비례 (`size.width * 0.X`) → 자동 ✓ | 별도 변경 불필요 |

---

## 6. 구현 순서

### Step 1 — `QrPreviewSection.build` LayoutBuilder
1. Stack 의 외부에 `LayoutBuilder` 추가
2. `available = math.min(c.maxWidth, c.maxHeight).clamp(80.0, double.infinity)` 산출

### Step 2 — main `QrLayerStack`
3. `QrLayerStack(deepLink: deepLink, size: 160)` → `size: available`
4. 감싸던 `Center + FittedBox` 제거 → `Center(child: QrLayerStack(...))`

### Step 3 — `_OverlayedDedicatedPreview`
5. 생성자에 `final double size` 추가
6. `_buildDedicatedFor(mode)` → `_buildDedicatedFor(mode, size)` 로 size 전달
7. 내부 FittedBox 제거 → 자식 위젯이 자체 SizedBox(size) 가짐

### Step 4 — 3개 Dedicated Preview
8. `_DotShapePreview`, `_EyeShapePreview`, `_BoundaryShapePreview` 생성자에 `final double size` 추가
9. `SizedBox(width: 160, height: 160, ...)` → `SizedBox(width: size, height: size, ...)`

### Step 5 — 검증
10. `flutter analyze` → 0 issue
11. 수동 검증: drag 확대 시 QR 도 함께 커지는지, dedicated 모드 (도트/눈/외곽) 도 동일 동작 확인

---

## 7. 검증 플랜

### 컴파일
- [ ] `flutter analyze` 변경 파일 issue 0
- [ ] `import 'dart:math'` 이미 존재 (`math.min`)

### UX 검증 (수동)
- [ ] compact (184) 상태에서 QR ≈ 160 그대로
- [ ] expanded 상태에서 QR 이 박스에 꽉 차게 확대 (height-24 정도)
- [ ] 드래그 중 즉시 비례 변화 (지터 없이 부드럽게)
- [ ] dedicated dot 모드 — 단일 도트도 박스 비례로 확대
- [ ] dedicated eye 모드 — 7×7 패턴 + 4 라벨 chip (1/2/3/4) 정상
- [ ] dedicated boundary 모드 — 외곽 윤곽선이 박스 90% 비례로 확대
- [ ] band 모드 (V5 강제) — 띠 두께/폰트 자동 비례
- [ ] 그라디언트 / 로고 embed — 비례 유지

### 회귀
- [ ] 캡처(저장/공유) — `repaintKey` 가 Container 전체를 캡처하므로 확대된 상태로도 정상 출력될지 확인
  - **주의**: 사용자가 expanded 로 펴둔 채 저장하면 캡처 사이즈가 커질 수 있음 → 저장 시 항상 compact 로 강제할지 별도 결정 필요 (Q 항목 1)
- [ ] 다크/라이트 모드 핸들 가시성

---

## 8. 위험·전제

### 위험
1. **저장(repaintKey) 캡처 크기 변동**: 사용자가 expanded 상태에서 "저장" 누르면 캡처 사이즈가 커짐 → 결과 PNG 도 커짐. **결정 필요** (아래 Q1).
2. **performance**: QrLayerStack 이 큰 사이즈로 매 프레임 재렌더 — `_qrImageFor` 캐시는 (deepLink, ecLevel, minTypeNumber) 키 → size 변경에 영향 없음 ✓. CustomQrPainter 는 size 변경 시 재페인트 (당연).
3. **Edge case**: 매우 작은 화면 (<200px height) → `available < 160` 가 될 수 있음. 그러나 현재도 `FittedBox.scaleDown` 으로 축소되므로 동일 동작. clamp(80, ∞) 로 안전망.

### 전제
- `LayoutBuilder` 가 Container padding(12) 안쪽 constraints 를 정확히 전달 (Flutter 표준 동작)
- 사용자는 박스가 커지면 안의 QR 도 커지길 원함 (사용자 명시적 요청)

---

## 9. Out-of-Scope

- 저장/공유 캡처 시 사이즈 정규화 (별도 Q 로 분리, 후속 처리)
- dedicated 라벨 chip 의 size 비례 (절대값 유지로 충분)
- pinch-to-zoom / 가로 모드

---

## 10. 미해결 질문 (Checkpoint 1·2)

### Q1. 저장 캡처 시 사이즈 정책
- (a) **항상 compact (184) 강제** — 일관된 출력 사이즈, 단 사용자가 큰 미리보기 보다가 저장 누르면 잠깐 줄어드는 시각 깜빡임
- (b) **현재 사이즈 그대로 캡처** — 큰 PNG 가 나올 수 있음 (e.g. 600×600). 단 결과 화질은 더 좋아짐
- (c) **저장 시 별도 offscreen 렌더 (현재 미구현)** — 일관성 + 화질 모두 보장. 구현 비용 큼

→ **권장: (a)**. 기존 동작과 호환. 저장 직전 `_animatePreviewTo(0)` 호출 후 1프레임 wait → 캡처. 약 300ms 사용자 대기.
실제로는 캡처가 동기적이므로 사용자에 보이는 깜빡임 없음 (snap 애니메이션 없이 즉시 `_previewExtra=0` setState 후 다음 프레임에 capture).

### Q2. 라벨 chip 비례 처리
- (a) 절대값 유지 (현재안)
- (b) `size * 0.025` 등으로 비례

→ **권장: (a)**. 단순화. 후속 요청 시 (b) 로 전환.

---

## 11. Next Steps

1. 사용자가 Q1 / Q2 답변 → 본 Plan 확정
2. `/pdca do qr-preview-inner-scale` 진행
3. 단일 파일 수정이라 Design 단계 생략 가능
