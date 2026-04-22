# Plan — logo-tab-dot-clearing

## Executive Summary

| 항목 | 값 |
|------|-----|
| Feature | logo-tab-dot-clearing |
| Level | Flutter Dynamic × Clean Architecture × R-series |
| 시작일 | 2026-04-22 |
| 작성자 | tawool83@gmail.com |
| PDCA Phase | Plan |

### Value Delivered (4-perspective)

| 관점 | 내용 |
|------|------|
| Problem | `LogoType.image` 는 QR 도트 위에 그냥 덮여 씌워져 스캔 안정성이 로고보다 낮고, 커스텀 눈·외곽·애니메이션 활성 시에는 `LogoType.logo` 조차도 도트 clearing 이 동작하지 않는다. 또한 로고 탭의 유형/위치 Row 가 5:5 고정이라 위치 옵션 라벨이 길어질 때 두 줄로 떨어진다. |
| Solution | (1) 이미지 타입도 로고와 동일하게 **logoBackground 도형 모양 clear-zone** 을 적용해 QR 도트를 비우고, 이 동작을 **pretty_qr 경로와 CustomQrPainter 경로 양쪽**에서 일관되게 지원. (2) 유형 드롭다운을 내용 폭 기반으로, 위치 segment 를 남은 폭 Expanded 로 배치해 한 줄 유지. |
| Function UX Effect | 이미지 로고 뒤 도트가 자동으로 비워져 시각적 충돌이 사라지고, ecLevel=H 로 전환되어 오버레이 후에도 QR 스캔 성공률 상승. 로고 탭 Row 1 레이아웃이 ko/en/de 등 라벨 폭이 긴 언어에서도 한 줄 유지. |
| Core Value | "로고를 넣어도 스캔되는 QR" 의 약속을 이미지/로고 전 타입에 대해 동일 품질로 제공. 레이아웃 안정성으로 i18n 리그레션 방지. |

---

## 1. Problem Statement

### 1.1 관찰된 동작 (현행)

| 경로 | LogoType.logo | LogoType.image | LogoType.text |
|------|---------------|----------------|---------------|
| pretty_qr 경로 (default) | embed (도트 비움 + ecLevel=H) | embed — but 시각적으로 인식되지 않는 케이스 발생 | overlay (의도적) |
| CustomQrPainter 경로 (custom eye/boundary/anim) | overlay (clearing 없음) | overlay (clearing 없음) | overlay (의도적) |

- **pretty_qr 경로**: `qr_preview_section.dart:389-396` 에서 `PrettyQrDecorationImage(image, position: embedded)` 가 centerImage != null && position == center 조건으로 적용. 이론상 image 도 logo 와 동일하게 embed 되지만, 사용자 관찰로는 "재배열 안 됨"으로 보이는 케이스가 있음.
- **CustomQrPainter 경로**: `qr_layer_stack.dart:130-141` 에서 QR 전체를 그린 뒤 `_LogoWidget` 을 Stack 오버레이로 얹음. 모든 타입이 오버레이되고 clearing 없음.

### 1.2 UX 문제

1. 사용자가 기대하는 "이미지 로고는 QR 위에 올려도 스캔됨" 이 **커스텀 shape 활성 시 보장 안 됨**.
2. Custom 설정 여부에 따라 로고 타입의 동작 일관성이 깨지면 사용자는 "이미지만 유독 도트를 가린다" 고 인식함.
3. 레이아웃: `sticker_tab.dart:45-123` Row 가 `Expanded(유형) | Expanded(위치)` → 위치 옵션이 `Wrap` 이라 `labelLogoTabPosition` 의 라벨이 긴 언어에서 2행으로 떨어짐.

---

## 2. Goals

### 2.1 In-scope

- **G1**: `LogoType.image` 의 QR 도트 clearing 이 `LogoType.logo` 와 동일하게 **양쪽 렌더 경로**(pretty_qr / CustomQrPainter)에서 일관되게 동작.
- **G2**: Clear-zone 모양을 `logoBackground` 값에 따라 자동 선택:
  - `none` → 이미지/로고의 원형(`ClipOval` 적용됨) 기준 **원형** clear-zone
  - `square` → 사각
  - `circle` → 원형
  - `rectangle` → 사각 (텍스트용, 본 feature 에서 이미지 타입에는 해당 없음)
  - `roundedRectangle` → 사각 (라운드 코너 무시, clear 영역 기준)
- **G3**: 위치가 `LogoPosition.center` 인 경우에만 clearing. `bottomRight` 는 QR 밖 배치 유지(현행).
- **G4**: 유형 드롭다운 / 위치 segment 레이아웃 반응형화 — 유형은 내용 폭, 위치는 남은 폭 Expanded.

### 2.2 Out-of-scope (명시)

- **Text 타입 clearing 미구현** — 글자 길이·폰트 가변으로 clear-zone 사전 결정이 복잡, 사용자 명시적 허용. 현행 overlay 유지.
- 위치 옵션 확장 (topLeft/topRight/bottomLeft 등 추가) — 본 Plan 기준 center / bottomRight 2개 유지.
- 로고 탭의 배경/색상/텍스트 편집기 영역은 수정 없음.
- QR 리더빌리티 지표(`qr_readability_service.dart`) 로직 변경 없음 (기존 점수 계산은 그대로 신뢰).

---

## 3. Requirements

### 3.1 Functional

| ID | 요구사항 | 수용기준 |
|----|---------|---------|
| FR-1 | Image 타입 + center 위치 + pretty_qr 경로에서 QR 도트 clearing 이 동작 | PrettyQrDecorationImage.embedded 로 로고와 동일한 경로로 embed 되는지 확인. 현재 동작이 이미 올바르다면 회귀 테스트 포인트로만 기록. |
| FR-2 | Image 타입 + center 위치 + CustomQrPainter 경로에서도 clear-zone 적용 | CustomQrPainter 에 clearRect 파라미터 추가, clear-zone 내부 모듈은 paint skip. |
| FR-3 | Logo 타입도 CustomQrPainter 경로에서 clear-zone 적용 (현재 누락) | FR-2 와 동일 메커니즘으로 logo 에도 적용. |
| FR-4 | Clear-zone 모양이 logoBackground 에 맞춰 자동 선택 | square/roundedRectangle/rectangle → Rect skip, circle/none(원형 ClipOval) → Circle skip. |
| FR-5 | bottomRight 위치 시 clearing 없음 | 현행 유지. `position == center && embedIcon` 조건만 clearing 활성화. |
| FR-6 | Row 1 반응형 레이아웃: 유형 드롭다운 내용 폭, 위치 segment 남은 폭 Expanded | ko/en/de/ja 등 라벨이 긴 언어에서도 위치 옵션이 한 줄로 유지됨을 수동 확인. |
| FR-7 | Text 타입은 현행 overlay 유지 | 코드 변경 없음. 회귀 테스트로 확인. |

### 3.2 Non-functional

| ID | 요구사항 |
|----|---------|
| NFR-1 | 성능: CustomQrPainter paint() 루프에 clear-zone 포함 여부 판정 추가 시 **O(1) 셀당 오버헤드**. 전체 QR 렌더 60fps 유지. |
| NFR-2 | 영속화: `StickerConfig` 스키마 변경 없음. 기존 저장된 QR 은 로직 변경만으로 동일하게 렌더. |
| NFR-3 | 코드 크기: `custom_qr_painter.dart` 는 189줄 → +30줄 이내(CLAUDE.md 메인 ≤200줄 한도 위반 위험, 분할 검토 필요). |
| NFR-4 | i18n: 문자열 추가 없음. 반응형 레이아웃 자체로 모든 언어 커버. |
| NFR-5 | 스캔 가능성: Image clearing 후에도 `ecLevel=H` 유지로 30% 복원력 보장. |

---

## 4. Data Model (No schema change)

영향 엔티티: `StickerConfig` (`logoType`, `logoPosition`, `logoBackground`, `logoAssetPngBytes`, `logoImageBytes`) — 모두 기존 필드. **신규 필드 없음**.

Hive 스키마 변경 없음 → 마이그레이션 불필요.

---

## 5. Architecture Approach (R-series Fixed)

> CLAUDE.md 고정 규약: Flutter × Riverpod StateNotifier × Clean Architecture × R-series Provider 패턴.

이번 feature 는 **상태 추가 없음**, 순수 렌더링 로직 수정이므로 신규 sub-state / mixin / entity 불필요. 기존 `qr_result` feature 내부 렌더 계층(`widgets/`) 만 수정.

### 5.1 렌더 경로 통합 설계

```
                              centerImageProvider(state)
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
   embedInQr &&                 iconProvider != null       text overlay
   (center + logo/image)                                   (LogoType.text)
        │                          │
        ▼                          ▼
  ┌──────────────┐         ┌───────────────────────┐
  │ pretty_qr 경로│         │ CustomQrPainter 경로  │
  │ (현재 embed 동작) │     │ (현재 overlay만)      │
  │ — FR-1 검증     │       │ — FR-2,3,4 추가       │
  └──────────────┘         └───────────────────────┘
```

### 5.2 Clear-zone 계산 (신규 헬퍼)

`qr_layer_stack.dart` 내부에 private helper 로 추가:

```dart
// conceptual — 실제 구현 시 Design phase 에서 확정
({Rect rect, bool isCircular}) _computeClearZone({
  required Size qrSize,          // CustomQrPainter draw area
  required StickerConfig sticker,
});
```

- 입력: QR draw size (quiet zone 제외), `sticker` (position, background, type)
- 출력: clear 영역 (center 기준 iconSize = qrSize * 0.22, logoBackground 일 때 +8px padding)
- `isCircular == true` 인 경우 CustomQrPainter 는 cell center 와 Rect.center 사이 거리로 판정, `false` 이면 Rect.contains 로 판정

### 5.3 CustomQrPainter 확장

```dart
class CustomQrPainter extends CustomPainter {
  // ...기존 필드
  final ClearZone? clearZone;  // 신규

  // paint() 에서 각 cell 위치가 clearZone 에 포함되면 skip
  bool _shouldSkip(Offset cellCenter) {
    if (clearZone == null) return false;
    return clearZone!.isCircular
      ? (cellCenter - clearZone!.rect.center).distance < clearZone!.rect.width / 2
      : clearZone!.rect.contains(cellCenter);
  }
}
```

- 기존 `_structuralCells` / `_dataCells` 루프 각각에서 skip 적용
- Finder pattern(3개 코너 7x7) 은 clear-zone 과 절대 겹치지 않는 중앙 영역(center 위치에서 ~22% 아이콘)이므로 skip 불필요
- `shouldRepaint` 에 `clearZone` 비교 추가

### 5.4 Layout 변경 (sticker_tab.dart)

**Before** (Row 1, line 45-123):
```
Row(
  Expanded(Column(Label, Dropdown)),        // flex: 1
  SizedBox(width: 12),
  Expanded(Column(Label, _SegmentRow)),     // flex: 1
)
```

**After**:
```
Row(
  ConstrainedBox(maxWidth: ~45% screen, Column(Label, IntrinsicWidth Dropdown)),
  SizedBox(width: 12),
  Expanded(Column(Label, _SegmentRow)),
)
```

또는 더 단순한 안:
```
Row(
  Flexible(flex: 0, Column(Label, IntrinsicWidth Dropdown)),  // 내용 폭
  SizedBox(width: 12),
  Expanded(Column(Label, _SegmentRow)),                       // 남은 폭
)
```

- Dropdown 의 `isExpanded: true` 는 제거 (내용 폭 기반으로 변경)
- minWidth 하한선 (예: 96px) 두어 아주 짧은 라벨일 때도 탭 영역 충분히 확보
- Design phase 에서 구체 수치 확정

---

## 6. File Change Inventory (예상)

| 파일 | 변경 유형 | 사유 |
|------|-----------|------|
| `lib/features/qr_result/widgets/qr_layer_stack.dart` | Modify | clear-zone 계산 헬퍼 추가, CustomQrPainter 에 전달 |
| `lib/features/qr_result/widgets/custom_qr_painter.dart` | Modify | `clearZone` 필드 추가, paint 루프 skip, shouldRepaint 업데이트 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | Verify (no/minor change) | pretty_qr 경로 image embed 동작 검증. 필요 시 image 에서 `PrettyQrDecorationImage` 인자 보정 |
| `lib/features/qr_result/tabs/sticker_tab.dart` | Modify | Row 1 Expanded → Flexible+Expanded 반응형 레이아웃 |

**신규 파일 없음** — 기존 feature 폴더 내 수정만.

---

## 7. Edge Cases & Risks

### 7.1 Edge Cases

| ID | 케이스 | 처리 |
|----|--------|------|
| EC-1 | logoBackground == rectangle (텍스트 전용) 인데 사용자가 이미지 타입 선택 후 수동으로 rectangle 배경 선택 | sticker_tab.dart 에 이미 타입별 배경 정규화 로직 있음 (`_normalizedBackground`) — clear-zone 은 정규화 후 배경으로 계산 |
| EC-2 | logoImageBytes 가 로딩 중 (null) | `centerImageProvider` 가 null → clearZone 도 null → 기존 렌더 |
| EC-3 | 애니메이션 중 QR 재계산 | CustomQrPainter 는 `_structuralCells`/`_dataCells` 사전 계산 유지, skip 판정만 매 프레임 |
| EC-4 | QR 그라디언트 + clear-zone | clear 는 draw skip 이므로 gradient shader 영향 없음. ShaderMask 적용 이후에도 비어 있음 |
| EC-5 | Boundary 클리핑으로 QR 외곽이 원형인데 로고 위치가 그 원 밖 | center 위치는 항상 원 내부 → 문제없음. bottomRight 는 clearing 대상 아님 |
| EC-6 | 아주 작은 QR (preview 160px) 에서 clear-zone 이 structural cells 영역(timing/alignment)과 겹침 | ecLevel=H 로 이미 증가한 redundancy 가 timing/alignment 손실 복구 불가 — 기존 pretty_qr 경로에서도 동일 한계. **추가 방어 없음** (pre-release + logo 는 항상 중앙 소형) |

### 7.2 Risks

| 위험 | 완화 |
|------|-----|
| R-1: CustomQrPainter 파일이 200줄 한도 초과 | Design phase 에서 clear-zone 헬퍼를 별도 파일(`utils/logo_clear_zone.dart`) 로 추출 검토 |
| R-2: pretty_qr 경로에서 image 가 이미 embed 되고 있어 FR-1 이 "no-op" | Check phase 에서 수동 검증. 그렇다면 FR-1 은 regression guard 용 코멘트만 추가 |
| R-3: Row 레이아웃 변경으로 기존 소문자 라벨(ko "유형") 이 너무 좁게 표시 | minWidth 하한선 96px 설정. Design 에서 실측 |
| R-4: Finder pattern 3개 코너의 alignment pattern 이 center 영역에 겹치는 대형 QR(version 7+) | 로고 22% 영역은 QR 중앙 ~40% 이내 → finder 와 무관. alignment pattern 일부와 겹칠 수 있으나 structural cells skip 은 기존 ecLevel=H redundancy 로 보정. 영향 미미 |

---

## 8. Testing Strategy

### 8.1 Visual regression (수동)

다음 시나리오를 preview (160px) + zoom dialog 에서 각각 확인:

| # | 타입 | 위치 | 배경 | 커스텀 shape | 기대 |
|---|------|------|------|-------------|------|
| T-01 | logo | center | none (원형) | × (기본) | 원형 clear-zone, 도트 없음 |
| T-02 | logo | center | circle | × | 원형 clear-zone, 배경 원 안쪽에 도트 없음 |
| T-03 | logo | center | square | × | 사각 clear-zone |
| T-04 | logo | center | none | ✓ (custom eye) | **신규**: 원형 clear-zone 적용됨 |
| T-05 | image | center | none | × | **신규**: 원형 clear-zone |
| T-06 | image | center | circle | × | **신규**: 원형 clear-zone |
| T-07 | image | center | square | ✓ (boundary = circle) | **신규**: 사각 clear-zone, boundary 내부에서 skip |
| T-08 | image | center | circle | ✓ (animation) | **신규**: 원형 clear-zone, 애니메이션 중에도 skip 유지 |
| T-09 | text | center | rectangle | × | 현행 overlay (clearing 없음) |
| T-10 | logo | bottomRight | square | ✓ (animation) | 현행 overlay (clearing 없음), QR 밖 우하단 |

### 8.2 스캔 가능성 검증

- Android 기기 또는 mobile_scanner 로 T-01 ~ T-08 의 생성된 QR 을 실제 스캔 시도
- 기대: 모든 케이스에서 스캔 성공 (ecLevel=H 복원력 ≥ 30%)

### 8.3 레이아웃 검증

- `flutter run` → 로고 탭 진입
- 언어 전환: ko / en / de / ja / zh → 유형 드롭다운 폭 자연 조정, 위치 segment 한 줄 유지
- 기기 폭 변화: 360dp / 411dp / 600dp (tablet) → 한 줄 유지 & 유형 드롭다운 minWidth 유지

### 8.4 코드 품질

- `flutter analyze` — warning 0
- `dart format` 적용
- 변경 파일 diff 만 review (call-site 전부 migration)

---

## 9. Implementation Order (Do phase 참고)

1. **Step 1 — Clear-zone 헬퍼** (`qr_layer_stack.dart` 내부)
   - `_computeClearZone(qrSize, sticker) → ClearZone?` 추가
   - `ClearZone` 구조체(또는 record) 정의

2. **Step 2 — CustomQrPainter 확장** (`custom_qr_painter.dart`)
   - `clearZone` 필드 추가, paint 루프에 `_shouldSkip` 적용
   - `shouldRepaint` 업데이트

3. **Step 3 — QrLayerStack 연결** (`qr_layer_stack.dart`)
   - `_buildCustomQr` 내부에서 `_computeClearZone` 호출해 Painter 에 전달
   - 기존 Stack 오버레이 `_LogoWidget` 은 그대로 유지 (위에 시각적 로고 그려야 함)

4. **Step 4 — pretty_qr 경로 검증** (`qr_preview_section.dart`)
   - 현재 `buildPrettyQr` 의 image 경로가 실제로 embed 되는지 확인
   - 필요 시 `PrettyQrDecorationImage` 인자 수정

5. **Step 5 — Layout 반응형화** (`sticker_tab.dart`)
   - Row 1 의 좌측 Expanded → Flexible(flex:0) + IntrinsicWidth
   - Dropdown `isExpanded: true` 제거, minWidth 제약
   - 우측은 그대로 Expanded

6. **Step 6 — 수동 QA**
   - Visual regression T-01~T-10 확인
   - i18n 언어 전환 시 레이아웃 확인

**예상 변경 규모**: 3~5 파일, +80~120 라인, -10~20 라인

---

## 10. Open Questions (Design Phase 해소 대상)

- Q-D1: `_computeClearZone` 를 `qr_layer_stack.dart` 내부 private 으로 둘지, `utils/logo_clear_zone.dart` 로 분리할지 (custom_qr_painter.dart 크기 초과 위험과 연동) → Design 에서 결정
- Q-D2: `ClearZone` 을 record `({Rect rect, bool isCircular})` 로 둘지, domain/entities 에 class 로 승격할지 → Design 에서 결정 (state 저장 대상 아니므로 record 유력)
- Q-D3: logoBackground.rectangle/roundedRectangle 은 이미지 타입에서 UI 정규화로 선택 불가하지만, 레거시 저장 데이터 복원 시에는 나타날 수 있음 — clear-zone 계산 시 rectangle 도 Rect 로 처리 (무시 아님) → Design 에서 확정

---

## 11. Success Criteria (Check phase 기준)

| 지표 | 목표 | 측정 |
|------|------|------|
| Match Rate (Design ↔ 구현) | ≥ 90% | gap-detector |
| FR 통과 | 7/7 | 수동 시나리오 T-01~T-10 |
| 회귀 | 0 건 | 기존 logo center pretty_qr / text overlay / bottomRight 동일 렌더 |
| `flutter analyze` | warning 0 | CI |
| 파일 크기 하드룰 | 메인 Notifier ≤ 200줄 유지 | 본 feature 는 widgets 수정만 → 영향 없음 |

---

## Appendix A — 관련 Archive 참조

- `docs/archive/2026-04/logo-tab-redesign/` — 초기 로고 타입 드롭다운 도입 PDCA
- `docs/archive/2026-04/logo-tab-text-editor/` — 텍스트 로고 오버레이 경로 설계
- `docs/archive/2026-04/qr-custom-shape/` — CustomQrPainter 도입 배경
- `docs/archive/2026-04/refactor-qr-result-state/`, `refactor-qr-notifier-split/` — R-series 패턴 레퍼런스

## Appendix B — 의사결정 로그

| 결정 | 근거 |
|------|------|
| Architecture: R-series + Clean Architecture 고정 | CLAUDE.md 고정 규약 |
| 신규 state/entity 없음 | 순수 렌더링 로직 변경, 사용자 입력 상태 불변 |
| Text clearing 미구현 | 사용자 명시적 skip 허용, 글자 폭 가변 |
| Clear-zone 모양 logoBackground 기반 | 사용자 선택 — 시각 일관성 우선 |
| CustomQrPainter 에도 clearing 적용 | 사용자 선택 — 모든 상황 일관성 |
| Position 확장 대비 안 함 | 사용자 선택 — 2개 유지 |
