# qr-decorative-frame Planning Document

> **Summary**: QR 외곽을 클리핑에서 장식 프레임 방식으로 전환 — QR 인식률 보장 + 마진 패턴 + 크기 조절
>
> **Project**: app_tag
> **Author**: Claude
> **Date**: 2026-04-21
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 현재 Boundary 기능은 QR 코드 자체를 원형/별 등으로 클리핑하여 데이터 모듈이 잘려 QR 인식이 불가능함 |
| **Solution** | QR 코드는 항상 정사각형을 유지하고, 더 큰 장식 프레임(원형/육각형/하트 등) 안에 Quiet Zone과 함께 플로팅 배치. 프레임과 QR 사이 마진 영역에 장식 패턴(QR 도트, 미로, 지그재그 등) 렌더링 |
| **Function/UX Effect** | QR 인식률 100% 유지하면서 시각적으로 독특한 프레임 디자인 제공. 프레임 크기 슬라이더로 마진 영역 조절 가능 |
| **Core Value** | QR 코드의 실용성(인식)과 심미성(장식 프레임)을 동시에 달성하는 차별화된 UX |

---

## 1. Overview

### 1.1 Purpose

현재 `QrBoundaryClipper.applyClip()`는 `canvas.clipPath()`로 QR 코드 픽셀 자체를 잘라내어, 비정사각형 모양(원형, 별, 하트 등)을 선택하면 QR 데이터 모듈이 손실되어 스캐너가 인식하지 못한다. 이 기능을 **프레임 기반 접근**으로 전면 재설계하여 QR 인식률을 보장하면서 장식적 효과를 제공한다.

### 1.2 Background

- **현재 구현**: `QrBoundaryParams` → `QrBoundaryClipper.applyClip()` → `canvas.clipPath()` — QR 코드 영역을 모양대로 잘라냄
- **문제**: 원형 선택 시 QR 코너의 finder pattern이 잘려 인식 불가
- **목표**: 정사각형 QR 코드를 모양 프레임 안에 quiet zone을 확보한 채 배치하고, QR과 프레임 사이 마진을 장식 패턴으로 채움

### 1.3 Related Documents

- Archive: `docs/archive/2026-04/qr-custom-shape/` (도트/눈 커스텀)
- Archive: `docs/archive/2026-04/eye-quadrant-corners/` (눈 4-corner 독립)
- Existing: `lib/features/qr_result/domain/entities/qr_boundary_params.dart`
- Existing: `lib/features/qr_result/utils/qr_boundary_clipper.dart`

---

## 2. Scope

### 2.1 In Scope

- [ ] FR-01: QR 코드를 정사각형으로 유지하고 장식 프레임 안에 플로팅 배치
- [ ] FR-02: 프레임 모양 지원 — 원형, 육각형, 별, 하트, 슈퍼엘립스 (기존 `QrBoundaryType` 재활용)
- [ ] FR-03: 마진 영역 장식 패턴 시스템 — 최소 5종 (QR 도트, 미로, 지그재그, 물결, 격자)
- [ ] FR-04: 프레임 크기 조절 슬라이더 (QR 대비 프레임 비율)
- [ ] FR-05: 프레임 회전 슬라이더 (기존 rotation 유지)
- [ ] FR-06: Quiet Zone 자동 확보 (프레임 모양에 관계없이 QR 주변 최소 여백)
- [ ] FR-07: 기존 프리셋/사용자 프리셋 시스템과 호환 (Hive 저장)
- [ ] FR-08: 이미지 내보내기 시 프레임 포함 렌더링

### 2.2 Out of Scope

- 캐릭터/커스텀 SVG 프레임 (향후 확장 가능하도록 설계하되, 이번 구현에서는 기하학 모양만)
- 프레임 색상 독립 설정 (QR 색상/그라디언트를 공유)
- 애니메이션과 프레임의 결합 (기존 애니메이션은 QR 영역 내에서만 동작)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | QR 코드는 항상 정사각형을 유지. 프레임 모양이 원형이면 QR보다 큰 원 안에 QR을 중앙 배치 | High | Pending |
| FR-02 | 프레임 모양: square(없음), circle, superellipse, star, heart, hexagon — 기존 `QrBoundaryType` enum 재활용 | High | Pending |
| FR-03 | 마진 패턴 5종 이상: `none`(단색), `qrDots`(QR 도트 패턴 반복), `maze`(미로), `zigzag`(지그재그), `wave`(물결), `grid`(격자) | High | Pending |
| FR-04 | 프레임 크기 슬라이더: QR 대비 프레임 비율 1.2~2.0 (기본 1.4). 비율이 클수록 마진 영역이 넓어짐 | Medium | Pending |
| FR-05 | 프레임 회전: 기존 `rotation` 파라미터 유지 (0~360도) | Medium | Pending |
| FR-06 | Quiet Zone: QR과 마진 패턴 사이 최소 quiet zone 4 모듈 폭 자동 확보 | High | Pending |
| FR-07 | `UserShapePreset` 저장 시 프레임 파라미터(모양, 패턴, 비율) Hive에 직렬화 | Medium | Pending |
| FR-08 | `RepaintBoundary` 캡처 및 이미지 내보내기 시 프레임 영역 포함 | Medium | Pending |
| FR-09 | square 타입 선택 시 프레임 없음(현재 동작과 동일) — backward 호환 | High | Pending |
| FR-10 | 마진 패턴 색상은 QR 색상/그라디언트를 투명도 40~60%로 적용 | Low | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 프레임 + 패턴 렌더링이 60fps 유지 (패턴은 사전 계산 Path 캐시) | 프로파일러 프레임 타임 |
| QR 인식률 | 모든 프레임 모양에서 QR 스캐너 인식 성공 | 실기기 + 시뮬레이터 테스트 |
| 메모리 | 패턴 Path 캐시가 프레임 크기 변경 시에만 재계산 | shouldRepaint 조건 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] 모든 FR 구현 완료
- [ ] 6종 프레임 모양 × 6종 패턴 조합에서 QR 인식 성공
- [ ] 프레임 크기 슬라이더 동작 확인
- [ ] 이미지 내보내기에 프레임 포함
- [ ] 기존 boundary 프리셋과 호환 (square = 프레임 없음)

### 4.2 Quality Criteria

- [ ] lint 에러 0
- [ ] 빌드 성공 (iOS + Android)
- [ ] 파일 크기 제한 준수 (메인 ≤200줄, part ≤400줄)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 복잡한 패턴(미로 등) 렌더링이 프레임 드롭 유발 | High | Medium | 패턴 Path를 사전 계산하고 캐시. shouldRepaint에서 params 변경 시에만 재생성 |
| 프레임 비율이 너무 크면 QR이 작아져 인식 어려움 | Medium | Low | 비율 상한 2.0 제한 + 최소 QR 크기 경고 |
| 기존 `QrBoundaryParams` Hive 데이터 마이그레이션 | Medium | High | 기존 데이터의 `type != square`는 자동으로 프레임 모드로 전환. 새 필드는 기본값 폴백 |
| `QrLayerStack` 레이아웃 변경으로 로고/텍스트 위치 영향 | Medium | Medium | 프레임 레이어를 QR 아래에 별도 레이어로 추가. 로고는 QR 영역 기준 유지 |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Dynamic** | Feature-based modules, Clean Architecture, R-series Provider | Flutter 모바일 앱 | **V** |

### 6.2 Key Architectural Decisions

| Decision | Selected | Rationale |
|----------|----------|-----------|
| Framework | Flutter | 기존 프로젝트 |
| State Management | Riverpod StateNotifier | R-series 패턴 고정 |
| 로컬 저장 | Hive | 기존 프리셋 저장 구조 |
| 라우팅 | go_router | 기존 프로젝트 |

### 6.3 렌더링 아키텍처 변경

**현재 (클리핑 방식)**:
```
QrLayerStack (size × size)
  └─ Container (quietPadding)
       └─ CustomQrPainter.paint()
            ├─ canvas.clipPath(boundaryShape)  ← QR 자체를 잘라냄
            ├─ draw finder patterns
            ├─ draw structural dots
            └─ draw data dots
```

**변경 후 (프레임 방식)**:
```
QrLayerStack (frameSize × frameSize)   ← 프레임 크기로 확장
  └─ Stack
       ├─ Layer 0: DecorativeFramePainter  ← 신규: 프레임 모양 + 마진 패턴
       │     ├─ draw frame shape outline
       │     ├─ clip to frame shape
       │     └─ draw margin fill pattern (qrDots/maze/zigzag/...)
       ├─ Layer 1: Positioned.center       ← QR 코드 (정사각형, 변형 없음)
       │     └─ CustomQrPainter.paint()    ← clipPath 제거됨
       │          ├─ draw finder patterns
       │          ├─ draw structural dots
       │          └─ draw data dots
       └─ Layer 2: Logo/Sticker            ← 기존 동일
```

### 6.4 핵심 변경 파일

| 파일 | 변경 내용 |
|------|-----------|
| `domain/entities/qr_boundary_params.dart` | `frameScale` (1.2~2.0), `marginPattern` enum 필드 추가 |
| `domain/entities/qr_margin_pattern.dart` | **신규** — `QrMarginPattern` enum + `MarginPatternParams` |
| `utils/qr_boundary_clipper.dart` | `applyClip()` 제거 → `buildFramePath()` + `buildMarginClip()` 으로 전환 |
| `utils/qr_margin_painter.dart` | **신규** — 마진 영역 패턴 렌더링 (6종 패턴 Path 생성) |
| `widgets/decorative_frame_painter.dart` | **신규** — `CustomPainter` 서브클래스, 프레임 + 마진 패턴 통합 렌더링 |
| `widgets/custom_qr_painter.dart` | `QrBoundaryClipper.applyClip()` 호출 제거 (clipPath 삭제) |
| `widgets/qr_layer_stack.dart` | `_buildCustomQr()` 에서 프레임 크기 계산 + `DecorativeFramePainter` 레이어 추가 |
| `tabs/qr_shape_tab/boundary_editor.dart` | 프레임 크기 슬라이더 + 마진 패턴 선택 UI 추가 |
| `tabs/qr_shape_tab/boundary_preset_row.dart` | 프리셋 아이콘에 패턴 미리보기 반영 |
| `widgets/qr_preview_section.dart` | `_BoundaryShapePreview` 에 프레임 미리보기 반영 |

### 6.5 엔티티 설계 요약

```dart
// 신규 enum
enum QrMarginPattern { none, qrDots, maze, zigzag, wave, grid }

// QrBoundaryParams 확장 필드
class QrBoundaryParams {
  // ... 기존 필드 유지 ...
  final double frameScale;          // 1.0~2.0 (1.0 = 프레임 없음 = square)
  final QrMarginPattern marginPattern;  // 마진 채움 패턴
  final double patternDensity;      // 패턴 밀도 0.5~2.0
}
```

### 6.6 프레임 크기 계산 로직

```
frameSize = qrSize * frameScale
quietZone = qrSize * 0.05 (기존 유지)
marginArea = framePath - Rect(qr + quietZone)

렌더 순서:
1. framePath 내부를 배경색으로 채움
2. marginArea에 선택된 패턴 렌더링 (framePath로 clip)
3. QR 코드를 중앙에 렌더 (clipPath 없음, 정사각형 유지)
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [x] `CLAUDE.md` has coding conventions section
- [x] R-series Provider pattern enforced
- [x] Clean Architecture directory structure
- [x] Hive for local persistence

### 7.2 Naming Conventions

| Item | Convention |
|------|-----------|
| 신규 enum | `QrMarginPattern` — `qr_margin_pattern.dart` |
| 신규 painter | `DecorativeFramePainter` — `decorative_frame_painter.dart` |
| 신규 util | `QrMarginPatternEngine` — `qr_margin_painter.dart` |
| Hive 필드 | `QrBoundaryParams.fromJson()`에 새 필드 기본값 폴백 |

---

## 8. Next Steps

1. [ ] Write design document (`qr-decorative-frame.design.md`)
2. [ ] Start implementation
3. [ ] Gap analysis

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-21 | Initial draft | Claude |
