---
template: plan
version: 1.0
feature: refactor-qr-notifier-split
date: 2026-04-21
author: tawool83
project: app_tag
---

# refactor-qr-notifier-split Planning Document

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | `QrResultNotifier` 단일 클래스가 **~460줄 + 40개 setter 메서드**로 god-class 상태. 5개 sub-state에 대한 setter가 한 파일에 섞여 있어 특정 관심사 수정 시 전체 파일 로드/스캔 필요. NFR-03(≤500줄) 미달 주요 원인. |
| **Solution** | Dart `part of` + mixin 패턴으로 관심사별 분할: 메인 Notifier는 **lifecycle + dispose**만, 5개 setter mixin이 각 sub-state(action/style/logo/template/meta) 전용 메서드를 소유. 기존 public API 시그니처 그대로 유지. |
| **Function/UX Effect** | 사용자 영향 **없음** (순수 구조 리팩터). Notifier 호출부(`ref.read(qrResultProvider.notifier).setQrColor(...)`)는 그대로. |
| **Core Value** | **Claude Code 읽기/수정 효율성**. setQrColor 수정 시 `style_setters.dart` 한 파일만 로드. 신규 style 필드 추가 시 관련 파일 1개만 touch. `qr_result_provider.dart` ≤200줄 달성 → 메인 파일 전체가 컨텍스트에 쉽게 들어옴. |

---

## 1. Problem Statement

### 1.1 현재 상태
- **파일**: `lib/features/qr_result/qr_result_provider.dart` (576줄)
- **QrResultNotifier 본체**: ~460줄 (파일의 80%)
- **메서드 구성** (40개):
  - Lifecycle + persistence: `setCurrentTaskId`, `loadFromCustomization`, `_rehydrateLogoAssetIfNeeded`, `_schedulePush`, `_pushNow`, `dispose` (6개)
  - Action (async): `setCapturedImage`, `saveToGallery`, `shareImage`, `printQrCode` (4개)
  - Style: `setQrColor`, `setRoundFactor`, `setEyeOuter/Inner`, `regenerateEyeSeed`, `clearRandomEye`, `setCustomGradient`, `setQuietZoneColor`, `setDotStyle`, `setCustomDotParams`, `setCustomEyeParams`, `setBoundaryParams`, `setAnimationParams` (13개)
  - Logo: `setEmbedIcon`, `setDefaultIconBytes`, `setCenterEmoji`, `clearEmoji`, `setLogoType`, `applyLogoLibrary`, `applyLogoImage`, `applyLogoText`, `setLogoBackgroundColor` (9개)
  - Template: `applyTemplate`, `applyUserTemplate`, `clearTemplate` (3개)
  - Meta + Sticker: `setPrintSizeCm`, `setTagType`, `setShapeEditorMode`, `setSticker` (4개)

### 1.2 문제점 (Claude 관점)
1. **컨텍스트 로드 비용**: setQrColor 하나 수정해도 460줄 Notifier 전체 또는 576줄 파일 전체 로드 필요
2. **Grep 노이즈**: `void set` 검색 시 40개 결과 중 관련 없는 37개 포함
3. **관심사 혼재**: style 수정 중 실수로 logo 로직 건드릴 가능성
4. **파일 네비게이션**: IDE outline에 40개 항목 — 원하는 메서드 찾기 비효율

### 1.3 해결하지 않을 것 (Non-Goals)
- 사용자 기능 변경 **없음**
- 공개 API 시그니처 변경 **없음** (`notifier.setQrColor(...)` 그대로)
- Use Case 계층 도입 **없음** — 현재 Notifier → Use Case 경로가 이미 존재, 추가 추상화 안 함
- Riverpod 구조 변경 **없음** — 여전히 단일 `QrResultNotifier` + `qrResultProvider`
- State 구조 변경 **없음** — R2에서 composite로 완성, 추가 개입 없음
- `freezed`/외부 패키지 도입 **없음**

---

## 2. Design Approach (Preview — Design 단계에서 확정)

### 2.1 선택 패턴: Dart `part of` + mixin

qr_shape_tab에서 검증된 동일 패턴:
- **메인 파일**: `library;` + part 디렉티브 + Notifier 클래스 (lifecycle만)
- **Part 파일들**: `part of '../qr_result_provider.dart';` + mixin 정의

mixin은 `StateNotifier<QrResultState>`을 `on` 제약으로 지정 → `state` 접근 가능. `part of`이므로 underscore-private 멤버(`_ref`, `_schedulePush`, `_suppressPush`) 직접 참조 가능.

### 2.2 분할 구조 (예정)

```
lib/features/qr_result/
├── qr_result_provider.dart              # main: library + imports + parts + QrResultState + Notifier lifecycle
│                                        # 목표: ≤200줄
└── notifier/
    ├── action_setters.dart              # mixin _ActionSetters — save/share/print + captured (~90줄)
    ├── style_setters.dart               # mixin _StyleSetters — 13 setters (~130줄)
    ├── logo_setters.dart                # mixin _LogoSetters — 9 setters (~100줄)
    ├── template_setters.dart            # mixin _TemplateSetters — 3 setters (~80줄)
    └── meta_setters.dart                # mixin _MetaSetters — 4 setters (~50줄)
```

메인 Notifier:
```dart
class QrResultNotifier extends StateNotifier<QrResultState>
    with _ActionSetters, _StyleSetters, _LogoSetters,
         _TemplateSetters, _MetaSetters {
  final Ref _ref;
  String? _currentTaskId;
  Timer? _debounceTimer;
  bool _suppressPush = false;
  bool _disposed = false;

  QrResultNotifier(this._ref) : super(const QrResultState());

  // lifecycle methods only (setCurrentTaskId, loadFromCustomization, 
  // _rehydrateLogoAssetIfNeeded, _schedulePush, _pushNow, dispose)
}
```

---

## 3. Functional Requirements

| # | 요구사항 | 우선순위 | 상태 |
|---|---------|---------|------|
| FR-01 | 기존 `QrResultNotifier` public API 시그니처 100% 유지 | High | Pending |
| FR-02 | 5개 mixin 파일로 setter 메서드 분할 (action/style/logo/template/meta) | High | Pending |
| FR-03 | 메인 `qr_result_provider.dart` ≤ 200줄 (NFR-03 초과달성) | High | Pending |
| FR-04 | 각 mixin 파일 ≤ 150줄 | High | Pending |
| FR-05 | `part of` 패턴 사용 — mixin이 `_ref`/`_schedulePush`/`_suppressPush` 등 private 멤버 접근 가능 | High | Pending |
| FR-06 | 메인 Notifier는 lifecycle 전용 (task id + persistence + dispose만) | High | Pending |
| FR-07 | mixin은 underscore-prefixed 이름 (`_StyleSetters` 등) — 외부 노출 방지 | High | Pending |
| FR-08 | 호출부 코드 **0줄 수정** — 외부 파일은 `notifier.setQrColor(...)` 그대로 | High | Pending |
| FR-09 | `flutter analyze` 에러 0건 | High | Pending |
| FR-10 | Hive 영속 스키마 변경 없음 | High | Pending |
| FR-11 | PDCA Gap 분석 Match Rate ≥ 90% | High | Pending |

---

## 4. Migration Strategy

### 4.1 작업 순서 (순수 내부 분할)

```
Phase 1: Scaffold
  └─ lib/features/qr_result/notifier/ 디렉터리 생성

Phase 2: Extract Mixins (의존 그래프 바닥부터)
  ├─ meta_setters.dart     ← sticker 포함, 가장 단순
  ├─ action_setters.dart   ← async, 독립적
  ├─ template_setters.dart ← style+logo+template 여러 sub-state 동시 touch
  ├─ logo_setters.dart
  └─ style_setters.dart    ← 가장 많음

Phase 3: Main File Refactor
  ├─ library + part 디렉티브 추가
  ├─ QrResultState 유지
  └─ Notifier에서 setter 삭제, mixin `with` 추가, lifecycle만 남김

Phase 4: Verification
  ├─ flutter analyze 0 errors
  ├─ 파일 크기 확인 (FR-03, FR-04)
  └─ (선택) 기기 스모크 테스트
```

각 Phase 완료 후 analyze 확인 → 단위별 커밋 가능.

### 4.2 왜 작업 순서를 바닥부터?
Mixin이 mixin을 의존하지 않음 (flat composition). 순서는 아무 것도 아니지만, 작은 것부터 하면 **매 단계마다 컴파일 검증이 빠름**.

### 4.3 Risk & Mitigation

| Risk | 영향 | 완화 |
|------|------|------|
| Mixin이 `state.copyWith(...)` 호출 시 `covariant` 문제 | 컴파일 실패 | `on StateNotifier<QrResultState>` 제약으로 state 타입 명확 |
| private 멤버(`_ref` 등) mixin 접근 시 library 분리 에러 | 컴파일 실패 | `part of` 디렉티브 사용 → 동일 library |
| mixin 누락 (특정 setter 이중 포함 or 누락) | 런타임 에러 / 빌드 실패 | Phase 2 각 mixin 완료 후 analyze로 검증 |
| `_suppressPush` 플래그가 mixin에서 필요한데 main에만 있음 | 저장 로직 버그 | mixin도 동일 library 내 private 접근 가능 (part of) |

### 4.4 Rollback 전략
단일 파일 분할이므로 문제 발견 시 part files 삭제 + main file 원상 복구. Git diff 범위가 클리어해서 쉬움.

---

## 5. Non-Functional Requirements

| # | NFR | 측정 기준 |
|---|-----|----------|
| NFR-01 | 기능 동일성 | 외부 호출부 0줄 수정 + Hive 스키마 불변 |
| NFR-02 | **파일 탐색성** | 특정 setter 수정 시 해당 mixin 파일만 로드 |
| NFR-03 | `qr_result_provider.dart` ≤ 200줄 | 파일 line count |
| NFR-04 | 각 mixin 파일 ≤ 150줄 | 파일 line count |

---

## 6. Success Criteria

- [ ] 메인 `qr_result_provider.dart` ≤ 200줄
- [ ] 5개 mixin 파일 생성, 각 ≤ 150줄
- [ ] 기존 40개 setter 메서드 모두 동일 시그니처 유지
- [ ] `flutter analyze` 에러 0건
- [ ] 외부 호출부(widgets 등) 코드 수정 0줄
- [ ] Gap 분석 Match Rate ≥ 90%

---

## 7. Effort Estimate

| Phase | 예상 시간 |
|-------|----------|
| Phase 1: Scaffold | 2분 |
| Phase 2: Extract 5 mixins | 40분 |
| Phase 3: Main refactor | 15분 |
| Phase 4: Verification | 10분 |
| **총** | **~1시간** |

순수 mechanical 작업이므로 리스크 낮고 빠름.

---

## 8. Out of Scope

- Use Case 계층 도입 (Notifier → use case function 호출 구조)
- Command pattern / Event Sourcing
- StateNotifier → AsyncNotifier 전환
- State 구조 재설계 (R2에서 완성)

---

## 9. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-04-21 | Initial plan — Notifier 460줄 → 5 mixin + main ≤200줄, part of 패턴 | tawool83 |
