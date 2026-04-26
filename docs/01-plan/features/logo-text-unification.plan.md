# logo-text-unification Planning Document

> **Summary**: "텍스트" 탭 제거 + 로고 유형="텍스트" 선택 시 중앙 텍스트 전용 편집 + 배경 옵션(가로띠/세로띠/사각/원형) 토글 UI
>
> **Project**: app_tag
> **Author**: Claude
> **Date**: 2026-04-26
> **Status**: In Progress (v0.7 — 단일 토글 + 사각/원형 ClearZone + 🚫 자동피팅)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | "텍스트" 탭과 로고 유형 "텍스트"가 공존하여 혼란. 상/하단 텍스트는 실사용 가치 낮고 UI 복잡도만 증가. 배경 옵션이 분산되어 발견 어려움 |
| **Solution** | 텍스트 탭 제거 + 상/하단 텍스트 제거 → 중앙 텍스트 전용 편집. 배경 옵션 [🚫/가로띠/세로띠/사각/원형] 단일 토글. 모든 모드 자동 폰트 피팅 + 사각/원형도 QR ClearZone 적용 |
| **Function/UX Effect** | 6탭→5탭, 배경 5개 단일 토글로 직관적, 사각/원형도 QR 보호, 🚫=배경 없는 가로 텍스트(15% 자동 피팅), 폰트 슬라이더 완전 삭제 |
| **Core Value** | 최소 UI로 최대 텍스트 커스터마이징 + QR 스캔 안정성 |

---

## 1. Overview

### 1.1 Purpose

현재 앱은 "텍스트" 탭(index 5)에서 상단/하단 텍스트를 편집하고, "로고" 탭에서 유형="텍스트"를 선택하면 별도의 짧은 로고 텍스트(max 6자)를 편집한다. 두 개의 "텍스트" 개념이 서로 다른 탭에 분산되어 있어 사용자 혼란이 크다. 이를 하나의 통합된 텍스트 편집 경험으로 합친다.

v0.4에서는:
- **상단/하단 텍스트 완전 제거** — 중앙 텍스트만 남김 (3-position → center only)
- **배경 옵션 토글 재설계** — [취소][가로띠|세로띠][사각|원형] 토글 그룹
- **균등분할 기본 ON** — 띠 모드 시 입력칸 우측 아이콘으로 토글 (텍스트 라벨 없음)
- **자동 폰트 피팅** — 띠 영역 크기와 글자수로 최적 fontSize 자동 계산

### 1.2 Background

- "텍스트" 탭 vs 로고 유형 "텍스트" — 한글로 동일 단어여서 구분 불가
- 상단/하단 텍스트는 실사용 빈도 낮고 UI 복잡도만 증가 → v0.4에서 완전 제거
- 중앙 텍스트(로고 영역)는 QR 도트 위에 오버레이되어 스캔 안정성을 해침
- 배경 옵션(띠/도형)이 분산되어 발견 어려움 → 통합 토글 그룹으로 재설계

### 1.3 Related Documents

- 참조 구현: `lib/features/qr_result/tabs/sticker_tab.dart`, `tabs/text_tab.dart`
- 렌더링: `lib/features/qr_result/widgets/qr_layer_stack.dart`
- ClearZone: `lib/features/qr_result/utils/logo_clear_zone.dart`

---

## 2. Scope

### 2.1 In Scope

- [x] 독립 "텍스트" 탭(TextTab, index 5) 제거 → 5탭 구성
- [x] 로고 유형="텍스트" 선택 시 중앙 텍스트 전용 편집기 표시
- [ ] **상단/하단 텍스트 완전 제거** — 세그먼트 버튼 제거, topText/bottomText UI 삭제
- [ ] 중앙 텍스트: 가로 띠 / 세로 띠 2방향 지원 (배타적 토글, 동시 불가)
- [ ] **배경 옵션 토글 재설계**: [취소][가로띠|세로띠][사각|원형] 단일 행
- [ ] 띠 크기 제한: 여백 포함 QR 크기의 15% 이하
- [ ] **자동 폰트 피팅**: 띠 모드 시 폰트 슬라이더 숨김, 글자수 기반 자동 계산
- [ ] **균등분할 기본 ON**: 띠 모드 활성 시 evenSpacing 기본 true, 입력칸 우측 아이콘으로 토글
- [x] ClearZone 확장: band 모드용 스트립 clearing
- [x] l10n: app_ko.arb 업데이트 (신규 키)

### 2.2 Out of Scope

- 텍스트 애니메이션 효과
- 다국어 번역 (ko만 선반영, 기존 정책)
- 로고 유형 logo/image의 동작 변경
- 텍스트 편집기 내 색상 제어 (색상 탭에서 관리)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | TextTab(index 5) 제거, TabController length 6→5 | High | Done |
| FR-02 | 로고 탭: 유형="텍스트" 선택 시 `LogoTextUnifiedEditor` 표시 (중앙 텍스트 전용) | High | Done |
| FR-03 | 텍스트 유형 선택 시 "위치" 설정 자체 숨김 (항상 center 고정) | High | Done |
| FR-04 | ~~상/하단 텍스트 QR 내부 이동~~ → **상단/하단 텍스트 완전 제거**. 세그먼트 버튼(상/중/하) 제거, topText/bottomText 관련 UI·렌더링·State 모두 삭제 | High | v0.4 |
| FR-05 | 중앙 텍스트 "띠" 모드: `BandMode` enum (none/horizontal/vertical) — 배타적 토글 | High | Done |
| FR-06 | 가로 띠: QR 수직 중앙에 가로 전폭 스트립, 높이 ≤ QR 15% | High | Done |
| FR-07 | 세로 띠: QR 수평 중앙에 세로 전높이 스트립, 너비 ≤ QR 15% | High | Done |
| FR-08 | 띠 모드에서 폰트 크기 슬라이더 숨김. 띠 영역이 허용하는 최대 크기로 자동 표시, 글자수↑ → 폰트↓ | High | v0.3 |
| FR-09 | 자동 피팅 공식: 가로 `min(bandH×0.85, availW/n/0.6)`, 세로 `min(bandW×0.85, availH/n/1.2)` | High | v0.3 |
| FR-10 | StickerConfig: `centerTextBand: bool` → `bandMode: BandMode` 마이그레이션 | High | Done |
| FR-11 | CustomQrPainter: 가로/세로 band ClearZone 수신 시 해당 도트 제거 | High | Done |
| FR-12 | 균등 분할: 글자를 띠 방향으로 균등 간격 배치. **띠 모드 시 기본 ON** | Medium | Done (기본값 v0.4) |
| FR-13 | ~~위치별 독립 배경~~ → 중앙 텍스트 전용으로 단순화 (top/bottom 제거) | Medium | v0.4 |
| FR-14 | **배경 토글 단일 그룹**: `[🚫] [가로띠] [세로띠] [사각] [원형]` — 5개 중 1개 선택. 구분선 제거, 단일 토글 세트. 🚫 = 배경 없는 가로 텍스트 오버레이 | High | v0.7 |
| FR-15 | 자동 피팅으로 오버플로우 없음. maxLength(20) 유지. 미리보기 ↔ 내보내기 비율 동일 보장 | High | v0.3 |
| FR-16 | **전체 자동 폰트 피팅**: 모든 배경 모드(🚫/띠/사각/원형)에서 자동 fontSize. **폰트 크기 슬라이더 완전 삭제**. 🚫 모드: max fontSize = QR 15%, 가로 1줄 표시, 글자수↑→폰트↓ | High | v0.7 |
| FR-17 | **균등분할 아이콘**: 글자 입력칸 우측에 아이콘 버튼 배치 (텍스트 라벨 없음). 띠 모드에서만 표시, 기본 ON | High | v0.4 |
| FR-18 | **상단/하단 텍스트 렌더링 제거**: QrLayerStack에서 topText/bottomText 렌더링 삭제 | High | v0.4 |
| FR-19 | **배경 단일 선택**: 5개 옵션 중 1개만 활성. 다른 옵션 탭 → 기존 해제 + 새 옵션 활성. 같은 항목 재탭 → 🚫로 복귀. 이미 🚫면 재탭 무시 | High | v0.7 |
| FR-20 | **색상 제어 위임**: 텍스트 편집기에서 글자색/배경색 선택 UI 제거. 색상 탭에서 제어. 기본 글자색=검정(#000000), 기본 배경색=흰색(#FFFFFF) | High | v0.5 |
| FR-21 | **폰트 선택 제거**: Sans/Serif/Mono 글꼴 선택 UI 제거. 시스템 기본 폰트 사용 (fontFamily=null). StickerText.fontFamily 필드는 유지하되 UI에서 노출하지 않음 | High | v0.5 |
| FR-22 | **로고 유형 토글**: DropdownButton → 색상 탭과 동일한 토글 형태로 변경. 4개 옵션(없음/로고/이미지/텍스트)을 수평 ToggleChip 행으로 표시 | High | v0.6 |
| FR-23 | **사각/원형 텍스트 ClearZone**: logoType==text + logoBackground==square/circle 일 때 기존 logo/image와 동일한 `computeLogoClearZone` 적용. QR 도트가 사각/원형 배경 영역을 피해서 렌더링 | High | v0.7 |
| FR-24 | **🚫 모드 텍스트 렌더링**: 배경 없이 QR 중앙에 가로 1줄 텍스트 오버레이. 최대 fontSize = QR크기×15%. 글자수↑→폰트↓ 자동 피팅. QR 너비 초과 불가. ClearZone은 텍스트 영역만큼 가로 스트립으로 적용 | High | v0.7 |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | QR 미리보기 리렌더 시간 변화 없음 (16ms 이내) | 프로파일러 |
| QR 스캔 안정성 | 띠 모드에서 QR 스캔 성공률 유지 (error correction H) | 실제 스캔 테스트 |
| 파일 크기 | 메인 파일 ≤200줄, UI part ≤400줄 | 코드 리뷰 |
| 띠 크기 안전성 | 가로/세로 띠 크기가 QR의 15%를 초과하지 않음 | 단위 계산 검증 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [x] 탭 5개(템플릿/모양/배경/색상/로고)로 동작
- [x] 로고→유형→텍스트 선택 시 중앙 텍스트 전용 편집기 표시
- [ ] 상단/하단 텍스트 UI + 렌더링 완전 제거됨
- [x] 로고 유형: 토글 칩 형태 동작 (없음/로고/이미지/텍스트)
- [ ] 배경 단일 토글: [🚫][가로띠][세로띠][사각][원형] 5개 중 1개 선택
- [ ] 사각/원형 텍스트 ClearZone: QR 도트가 배경 영역 피함
- [ ] 🚫 모드: 가로 텍스트 오버레이, max 15% 자동 피팅
- [ ] 폰트 크기 슬라이더 완전 삭제
- [ ] 띠 크기가 QR의 15% 이하
- [ ] 띠 모드 시 자동 폰트 피팅 (글자수↑ → 폰트↓)
- [ ] 띠 모드 시 균등분할 기본 ON + 입력칸 우측 아이콘 토글
- [ ] flutter analyze 에러 0

### 4.2 Quality Criteria

- [ ] QR 코드 가로 띠 모드에서 실제 스캔 성공
- [ ] QR 코드 세로 띠 모드에서 실제 스캔 성공
- [ ] 빌드 성공
- [ ] 기존 logo/image 유형 동작 회귀 없음

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 세로 띠 모드에서 QR 스캔 실패 (수직 clearing이 finder pattern 침범) | High | Medium | 세로 스트립이 3개 finder pattern 영역을 제외하도록 ClearZone 조정; error correction H 강제 |
| 띠 크기 15% 제한 시 폰트가 너무 작아 못 읽음 | Medium | Low | QR 크기 160px 기준 24px = fontSize ~15sp — 충분히 가독. 슬라이더 min을 6sp로 설정 |
| `centerTextBand: bool` → `bandMode: BandMode` 마이그레이션 | Medium | High | `centerTextBand: true` 기존 데이터 → `bandMode: horizontal`로 자동 변환 (fromJson 호환) |
| 세로 띠에서 텍스트 회전 렌더링 복잡도 | Low | Medium | `RotatedBox(quarterTurns: 1)` 또는 `Transform.rotate` 사용 — Flutter 기본 제공 |
| 상/하단 텍스트 제거 시 기존 저장 데이터 호환 | Low | Medium | State 에 topText/bottomText 필드는 유지 (null), 렌더링만 제거 — 데이터 마이그레이션 불필요 |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure | Static sites | |
| **Dynamic** | Feature-based modules, Clean Architecture | Flutter apps | v |
| **Enterprise** | Strict layer separation, microservices | High-traffic systems | |

**Flutter Dynamic x Clean Architecture x R-series**

### 6.2 Key Architectural Decisions

| Decision | Selected | Rationale |
|----------|----------|-----------|
| Framework | Flutter | 기존 프로젝트 |
| State Management | Riverpod StateNotifier | R-series 패턴 |
| 로컬 저장 | Hive | 기존 방식 |
| 라우팅 | go_router | 기존 방식 |

### 6.3 BandMode enum 설계

```dart
/// 중앙 텍스트 띠 모드.
/// - none: 띠 없음 (기존 오버레이)
/// - horizontal: 가로 띠 (QR 수직 중앙, 전폭 스트립)
/// - vertical: 세로 띠 (QR 수평 중앙, 전높이 스트립)
///
/// Hive 에는 index(int) 저장 → 새 값은 enum 끝에 추가.
enum BandMode { none, horizontal, vertical }
```

**`centerTextBand: bool` → `bandMode: BandMode` 마이그레이션**:
- `StickerSpec.fromJson`: `centerTextBand: true` → `bandMode: horizontal` 으로 자동 변환
- `StickerSpec.toJson`: `bandMode` → `'bandMode': 'horizontal'/'vertical'` 직렬화
- 레거시 `centerTextBand` 키도 읽어서 호환

### 6.4 띠 크기 제한: QR의 15%

```
QR 크기 = 160px (기본 미리보기)
15% = 24px

가로 띠:
  - 높이(여백 포함) ≤ 24px
  - 텍스트 영역 = 24px * 0.9 = 21.6px → 최대 fontSize ~15sp (scale 적용 시)
  - 슬라이더 range: 동적 계산 (min 6sp ~ max 띠높이*0.9/scale)

세로 띠:
  - 너비(여백 포함) ≤ 24px
  - 텍스트 영역 = 24px * 0.9 = 21.6px → 최대 fontSize ~15sp
  - 텍스트는 정방향으로 세로 나열 배치
```

**폰트 크기 슬라이더**:
- 수치(sp) 비표시 — 슬라이더만으로 조절
- min: 6sp (최소 가독 크기)
- max: 동적 계산 `= (qrRefSize * 0.15 * 0.9) / scale` → 띠 높이/너비의 90%
- 기본 미리보기(160px) 기준 max ≈ 15sp

### 6.5 디렉터리 변경 계획

```
lib/features/qr_result/
├── tabs/
│   ├── sticker_tab.dart              # [수정] 유형 DropdownButton→토글 칩 (v0.6)
│   ├── text_tab.dart                 # [삭제] (Done)
│   └── logo_editors/
│       ├── logo_text_editor.dart     # [삭제] (Done)
│       └── logo_text_unified_editor.dart  # [수정] 🚫 취소 + 상호배타 토글 (v0.6)
├── domain/entities/
│   ├── sticker_config.dart           # [수정] centerTextBand→bandMode + BandMode enum
│   └── band_mode.dart                # [신규] BandMode enum (또는 sticker_config 내 정의)
├── utils/
│   └── logo_clear_zone.dart          # [수정] 세로 ClearZone 계산 추가
├── widgets/
│   ├── qr_layer_stack.dart           # [수정] 세로 띠 렌더링 + 띠 크기 제한
│   └── custom_qr_painter.dart        # [수정] 세로 band ClearZone 지원
├── notifier/
│   └── logo_setters.dart             # [수정] setCenterTextBand→setBandMode
├── data/
│   └── (qr_task 쪽)
│       ├── sticker_spec.dart         # [수정] bandMode 직렬화 + 레거시 호환
│       └── customization_mapper.dart # [수정] bandMode 매핑
└── qr_result_screen.dart             # [완료] 5탭 (Done)
```

### 6.6 데이터 흐름

```
[로고 탭] 유형="텍스트" 선택
  → LogoTextUnifiedEditor 표시
    ├── 텍스트 입력: TextField + [∷ 균등분할 아이콘] (띠 모드에서만 표시)
    ├── (색상/폰트: 색상 탭에서 제어, 편집기에서 제거)
    ├── 배경 토글: [취소] [가로띠|세로띠] [사각|원형]
    │   ├── 취소 = bandMode:none + logoBackground:none
    │   ├── 가로띠 = bandMode:horizontal
    │   ├── 세로띠 = bandMode:vertical
    │   ├── 사각 = logoBackground:square
    ��   └── 원형 = logoBackground:circle
    └── 폰트 슬라이더 (bandMode==none 일 때만 표시)

[렌더링: QrLayerStack]
  ├── bandMode == horizontal:
  │   └── 가로 전폭 스트립 (높이 ≤ QR 15%)
  │       ClearZone: Rect(0, center-h/2, qrWidth, h)
  │       텍스트: 자동 피팅 fontSize (글자수↑ → 폰트↓)
  │
  ├── bandMode == vertical:
  │   └── 세로 전높이 스트립 (너비 ≤ QR 15%)
  │       ClearZone: Rect(center-w/2, 0, w, qrHeight)
  │       텍스트: 자동 피팅 Column 세로 배치 (글자수↑ → 폰트↓)
  │
  └── bandMode == none:
      └── 기존 로고 텍스트 오버레이 (변경 없음)

[CustomQrPainter] clearZone + bandClearZone → 해당 셀 skip
```

### 6.7 띠 텍스트 렌더링 — 자동 피팅 방식 (v0.3)

```dart
// 자동 피팅: 띠 영역 크기 + 글자수로 최적 fontSize 계산
// FittedBox/ClipRect 모두 미사용 → 미리보기/내보내기 비율 동일 보장
//
// build() 에서 autoFitFontSize 계산 후 style 에 적용:
double _autoFitFontSize() {
  final n = text.content.length.clamp(1, 999);
  if (bandMode == BandMode.horizontal) {
    final byHeight = maxBandDim * 0.85;              // 띠 높이에 맞춤
    final byWidth = availWidth / n / 0.6;            // 글자수에 맞춤
    return min(byHeight, byWidth).clamp(4.0, 200.0);
  }
  // vertical
  final byWidth = maxBandDim * 0.85;                 // 띠 너비에 맞춤
  final byHeight = availHeight / n / 1.2;            // 글자수에 맞춤
  return min(byWidth, byHeight).clamp(4.0, 200.0);
}

// _buildHorizontal: 그냥 Text (maxLines:1, no overflow handling needed)
// _buildVertical: Column of Text chars (no ClipRect needed)
```

**핵심 원칙**:
- 띠 모드 활성 시 `_FontSizeSlider` 숨김 (fontSize 는 자동 계산)
- top/bottom 위치에서는 기존 슬라이더 유지
- 미리보기와 내보내기 모두 동일한 `_autoFitFontSize()` 로직 사용 → 비율 보장
- 글자 1개 = 최대 크기, 글자 N개 = 띠 영역 / N 기반 축소

### 6.8 세로 띠 ClearZone

```dart
ClearZone computeVerticalBandClearZone({
  required Size qrSize,
  required double fontSize,
}) {
  final bandWidth = fontSize * 1.4;
  // QR 15% 제한
  final maxWidth = qrSize.width * 0.10;
  final clampedWidth = bandWidth.clamp(0, maxWidth);
  final rect = Rect.fromCenter(
    center: Offset(qrSize.width / 2, qrSize.height / 2),
    width: clampedWidth,
    height: qrSize.height,  // 전체 세로
  );
  return (rect: rect, isCircular: false);
}
```

---

## 7. UI Design

### 7.1 로고 유형 토글 + 텍스트 편집기 (v0.7)

**로고 유형 선택** — 토글 칩 행:
```
유형: [없음] [로고] [이미지] [텍스트]
```

**텍스트 편집기** (유형="텍스트" 선택 시):
```
┌──────────────────────────────────────────┐
│ [________________] [∷]                   │  <- 입력 + 균등분할 아이콘(띠 모드만)
│                                          │
│ [🚫] [━가로띠] [┃세로띠] [■사각] [●원형]  │  <- 단일 토글 (5개 중 1개)
└──────────────────────────────────────────┘
```

**v0.7 변경 항목**:
- 배경 토글: 2그룹 상호배타 → **단일 토글 그룹** (구분선 제거)
- 폰트 크기 슬라이더: **완전 삭제** (모든 모드 자동 피팅)
- 사각/원형: QR ClearZone 적용 (FR-23)
- 🚫: 배경 없는 가로 텍스트 + max 15% 자동 피팅 (FR-24)

**기본값**: 글자색=#000000(검정), 배경색=#FFFFFF(흰색), 폰트=시스템 기본

**배경 토글 동작 규칙 (단일 선택)**:
- `[🚫]` = bandMode=none + logoBackground=none → 배경 없는 가로 텍스트 오버레이
- `[가로띠]` = bandMode=horizontal + logoBackground=none
- `[세로띠]` = bandMode=vertical + logoBackground=none
- `[사각]` = bandMode=none + logoBackground=square
- `[원형]` = bandMode=none + logoBackground=circle
- 다른 옵션 탭 → 기존 해제 + 새 옵션 활성
- 같은 항목 재탭 → 🚫로 복귀 (bandMode=none + logoBackground=none)
- 🚫 재탭 → 무시 (이미 🚫 상태)

**모드별 렌더링**:
| 모드 | 렌더링 | 자동 피팅 | ClearZone |
|------|--------|-----------|-----------|
| 🚫 | 가로 1줄, 배경 없음 | max=QR 15%, 글자수↑→폰트↓ | 텍스트 영역 가로 스트립 |
| 가로띠 | 가로 전폭 스트립 | 띠 영역 기반 | 가로 전폭 스트립 |
| 세로띠 | 세로 전높이 스트립 | 띠 영역 기반 | 세로 전높이 스트립 |
| 사각 | 사각 배경 + 텍스트 | iconSize 기반 | logo/image와 동일 (사각) |
| 원형 | 원형 배경 + 텍스트 | iconSize 기반 | logo/image와 동일 (원형) |

**균등분할 아이콘 동작**:
- 띠 모드(가로/세로) 활성 시에만 입력칸 우측에 `space_bar` 아이콘 표시
- 띠 모드 진입 시 기본값 = ON (evenSpacing: true)
- 아이콘 탭으로 ON/OFF 토글
- 띠 모드 외에는 아이콘 숨김

### 7.2 QR 미리보기

**가로 띠 모드** (상/하단 텍스트 없음):
```
┌──────────────────────┐
│ ┌──────────────────┐ │
│ │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│ │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│ │━━━━ BAND ━━━━━━━│ │ <- 가로 띠 (높이 <= QR 15%)
│ │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│ │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │ │
│ └──────────────────┘ │
└──────────────────────┘
```

**세로 띠 모드**:
```
┌──────────────────────┐
│ ┌──────────────────┐ │
│ │  ▓▓▓▓▓┃▓▓▓▓▓▓▓▓  │ │
│ │  ▓▓▓▓▓┃▓▓▓▓▓▓▓▓  │ │
│ │  ▓▓▓▓B┃D▓▓▓▓▓▓▓  │ │ <- 세로 띠 (너비 <= QR 15%)
│ │  ▓▓▓▓A┃N▓▓▓▓▓▓▓  │ │    텍스트 세로 배치
│ │  ▓▓▓▓▓┃▓▓▓▓▓▓▓▓  │ │
│ └──────────────────┘ │
└──────────────────────┘
```

---

## 8. Next Steps

**v0.5 완료 항목** (코드 구현 Done):
1. [x] 상단/하단 텍스트 편집기 + 렌더링 제거
2. [x] 배경 토글 UI [취소][가로띠|세로띠][사각|원형] 구현
3. [x] 균등분할 아이콘 입력칸 우측 배치, 띠 모드 기본 ON
4. [x] 자동 폰트 피팅 (글자수 기반 자동 fontSize)
5. [x] 폰트 슬라이더 bandMode==none 일 때만 표시
6. [x] 색상/폰트 UI 제거 (색상 탭 위임)

**v0.6 완료 항목** (코드 구현 Done):
1. [x] `sticker_tab.dart`: 로고 유형 DropdownButton → 수평 토글 칩 행 (FR-22)
2. [x] `logo_text_unified_editor.dart`: 취소 버튼 → 🚫 (FR-14 v0.6)
3. [x] `logo_text_unified_editor.dart`: 배경 토글 상호배타 (FR-19 v0.6)
4. [x] 사각/원형 자동 피팅 + 세로 띠 overflow 수정 + 가로 띠 수직 정렬

**v0.7 작업 항목**:
1. [ ] `logo_text_unified_editor.dart`: 배경 토글 단일 그룹 — 구분선 제거, 5개 단일 선택 (FR-14 v0.7)
2. [ ] `logo_text_unified_editor.dart`: `_FontSizeSlider` 완전 삭제 (FR-16 v0.7)
3. [ ] `logo_clear_zone.dart`: logoType==text + square/circle ClearZone 추가 (FR-23)
4. [ ] `qr_layer_stack.dart`: 🚫 모드 텍스트 렌더링 — 배경 없는 가로 오버레이 + max 15% 자동 피팅 (FR-24)
5. [ ] `qr_layer_stack.dart`: 🚫 모드 ClearZone — 텍���트 영역 가로 스트립 (FR-24)
6. [ ] flutter analyze 에러 0

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-26 | Initial draft — 가로 띠 모드 설계 | Claude |
| 0.2 | 2026-04-26 | 가로/세로 2방향 띠 모드, 15% 크기 제한, 슬라이더 수치 숨김, 위치/배경 독립화 | Claude |
| 0.3 | 2026-04-26 | 자동 폰트 피팅 (FittedBox/ClipRect → 글자수 기반 자동 fontSize) | Claude |
| 0.4 | 2026-04-26 | 상/하단 텍스트 제거, 배경 토글 재설계 [취소][가로띠\|세로띠][사각\|원형], 균등분할 기본 ON + 아이콘 | Claude |
| 0.5 | 2026-04-26 | 색상/폰트 UI 제거 (색��� 탭 위임), 시스템 기본 폰트, 기본색 검정/흰 | Claude |
| 0.6 | 2026-04-26 | 로고 유형 토글 칩(FR-22), 🚫 취소 아이콘(FR-14), 띠↔도형 상호배타(FR-19) | Claude |
| 0.7 | 2026-04-26 | 배경 단일 토글(FR-14), 폰트 슬라이더 삭제(FR-16), 사각/원형 ClearZone(FR-23), 🚫 가로 자동피팅(FR-24) | Claude |
