---
template: plan
version: 1.0
feature: refactor-qr-result-state
date: 2026-04-20
author: tawool83
project: app_tag
---

# refactor-qr-result-state Planning Document

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | `QrResultState` 클래스가 **26+ 필드의 god-state**로 비대해짐. 27-arg constructor + 27-arg `copyWith` with hand-rolled `_sentinel` for nullables. 어떤 필드가 바뀌어도 `ref.watch(qrResultProvider)` 전 위젯 리빌드. 약 **75개 read-site**가 평탄 구조에 의존 중. |
| **Solution** | 논리 관심사별로 **5개 sub-state 계층**(Action/Style/Logo/Template/Meta) + 기존 `sticker: StickerConfig`를 조합한 composite state 로 재설계. 위젯은 `ref.watch(provider.select((s) => s.style.qrColor))` 등으로 필요한 필드만 구독 → 불필요 리빌드 제거. |
| **Function/UX** | 사용자 영향 **없음** (순수 내부 구조 재설계). 애니메이션 QR 편집 시 성능 개선 기대 (리빌드 감소). |
| **Core Value** | 장기 유지보수성 + 렌더 성능. 새 필드 추가 시 한 sub-state만 touch, 테스트 격리 용이. |

---

## 1. Problem Statement

### 1.1 현재 상태
- **위치**: `lib/features/qr_result/qr_result_provider.dart:75-225`
- **크기**: `QrResultState` 클래스 약 150줄 (26개 final 필드 + const constructor + copyWith + defaults factory)
- **블래스트 반경**:
  - `QrResultState` / `qrResultProvider` 참조: **74개 라인**
  - `state.xxx` 필드 접근: **75개 라인** (provider 파일 제외)
  - 주요 소비자: `qr_result_screen.dart`, `qr_preview_section.dart`, `qr_shape_tab.dart` + part files, `qr_color_tab.dart`, `sticker_tab.dart`, `text_tab.dart`, `logo_editors/*`, `all_templates_tab.dart`, `customization_mapper.dart`

### 1.2 문제점
1. **파라미터 스프롤**: 27-arg const constructor → 신규 필드 추가 시 매번 3곳 이상 수정 (필드 선언 + 생성자 + copyWith)
2. **Sentinel 패턴**: nullable 필드를 `copyWith`에서 "변경 없음 vs null 로 설정"을 구별하기 위해 `_sentinel` object를 수동 관리 — 에러 유발
3. **과도한 리빌드**: `ref.watch(qrResultProvider)` 사용 시 26개 필드 중 1개만 바뀌어도 전체 위젯 재빌드. 슬라이더 드래그 중 60fps로 모든 소비자 리빌드
4. **관심사 혼재**: 액션 status(save/share/print) + 스타일(color/dots) + 로고/이모지 + 템플릿 UI state + 메타가 한 객체에 혼재
5. **테스트 격리 어려움**: 한 분기 테스트 위해 26개 필드 mock 필요

### 1.3 해결하지 않을 것 (Non-Goals)
- 사용자 기능/UI 변경 **없음**
- `sticker: StickerConfig` 내부 재설계 **없음** (이미 적절히 분리됨, 이번 범위 외)
- `QrResultNotifier` 비즈니스 로직(use case 호출) 재설계 **없음**
- `freezed` 등 외부 패키지 도입 **없음** (수동 const class 유지)
- 기존 Hive 영속 스키마 변경 **없음** (`CustomizationMapper.fromState/loadFromCustomization` 단일 경계에서 변환)

---

## 2. Proposed Sub-State Decomposition

### 2.1 5개 Sub-state + 기존 StickerConfig

```dart
class QrResultState {
  final QrActionState action;     // save/share/print status + error + captured bytes
  final QrStyleState style;       // color/gradient/dot/eye/boundary/animation/quiet-zone
  final QrLogoState logo;         // embed flag + icon/emoji bytes
  final QrTemplateState template; // active template id + override data
  final QrMetaState meta;         // tagType + printSizeCm + shapeEditorMode
  final StickerConfig sticker;    // 기존 그대로 유지
}
```

### 2.2 필드 매핑

| Sub-state | 필드 수 | 기존 필드 |
|-----------|:---:|----------|
| **QrActionState** | 5 | `capturedImage`, `saveStatus`, `shareStatus`, `printStatus`, `errorMessage` |
| **QrStyleState** | 12 | `qrColor`, `roundFactor`, `eyeOuter`, `eyeInner`, `randomEyeSeed`, `customGradient`, `dotStyle`, `customDotParams`, `customEyeParams`, `boundaryParams`, `animationParams`, `quietZoneColor` |
| **QrLogoState** | 4 | `embedIcon`, `defaultIconBytes`, `centerEmoji`, `emojiIconBytes` |
| **QrTemplateState** | 3 | `activeTemplateId`, `templateGradient`, `templateCenterIconBytes` |
| **QrMetaState** | 3 | `tagType`, `printSizeCm`, `shapeEditorMode` |
| **StickerConfig** | (유지) | `sticker` |

각 sub-state는 5개 이하 필드 → copyWith가 자명해짐.

---

## 3. Functional Requirements

| # | 요구사항 | 우선순위 | 상태 |
|---|---------|---------|------|
| FR-01 | `QrResultState`를 5개 sub-state + `sticker` 로 재구성 | High | Pending |
| FR-02 | 각 sub-state는 독립 파일 (`state/qr_action_state.dart` 등 5개) | High | Pending |
| FR-03 | `QrResultState` 자체는 composite로 축소 (~30줄) | High | Pending |
| FR-04 | 기존 **75개 read-site** 전부 마이그레이션 (`state.qrColor` → `state.style.qrColor`) | High | Pending |
| FR-05 | `QrResultNotifier`의 기존 setter/update 메서드 API **그대로 유지** (내부 구현만 sub-state touch) | High | Pending |
| FR-06 | `CustomizationMapper.fromState`/`loadFromCustomization`는 내부 필드 접근만 업데이트 (Hive JSON 스키마 동일) | High | Pending |
| FR-07 | `_sentinel` 패턴 제거 — sub-state 단위 `copyWith`로 대체 | Medium | Pending |
| FR-08 | 성능 개선: 주요 소비자 위젯이 `select` 기반으로 sub-state 구독 (최소 5곳 이상) | Medium | Pending |
| FR-09 | 각 sub-state에 immutable `==`/`hashCode` 구현 (Object.hash 권장) | High | Pending |
| FR-10 | `flutter analyze` 에러 0건 | High | Pending |
| FR-11 | 실기기 회귀 테스트: 주요 플로우 7종 (요구사항 §6) 전부 통과 | High | Pending |
| FR-12 | 변경 전후 git diff 기준 **동작 동일** (PDCA Gap 분석 Match Rate ≥ 90%) | High | Pending |

---

## 4. Migration Strategy

### 4.1 3단 점진 마이그레이션 (Safe-Refactor)

**Phase A — Sub-state 정의 (읽기 전용, 빌드 깨지지 않음)**
- 5개 sub-state 클래스 파일 생성 (immutable const class + copyWith + ==/hashCode)
- `QrResultState`에 **getter** 추가: `QrActionState get action => QrActionState(saveStatus: saveStatus, ...)` 형태로 기존 평탄 필드를 런타임 구성해 반환
- **기존 필드 제거 안 함** → 빌드 깨지지 않음, 기존 75개 read-site 정상 동작
- 신규 소비자는 `state.action.saveStatus` 로 접근 가능

**Phase B — Read-site 점진 마이그레이션**
- 파일 단위로 `state.xxx` → `state.subState.xxx` 교체 (grep 기반)
- 각 파일 마이그레이션마다 `flutter analyze` 통과 확인
- 예상 순서(blast radius 작은 것부터): `customization_mapper` → `logo_editors/*` → `text_tab` → `sticker_tab` → `qr_color_tab` → `qr_shape_tab` + parts → `qr_preview_section` → `qr_layer_stack` → `qr_result_screen` → `all_templates_tab`

**Phase C — Flat 필드 제거 + Composite 본격 구조**
- `QrResultState`의 평탄 필드 모두 삭제, 5개 sub-state + `sticker`만 유지
- 생성자/copyWith 재설계 (sub-state 단위만)
- `QrResultNotifier`의 setter 내부를 `state.copyWith(style: state.style.copyWith(qrColor: c))` 형태로 변환
- `_sentinel` 패턴 제거

**Phase D — Performance 개선 (선택)**
- 주요 소비자 위젯을 `ref.watch(qrResultProvider.select((s) => s.style))` 로 전환
- 측정: 슬라이더 드래그 시 빌드 카운트 before/after 비교

### 4.2 risk & mitigation

| Risk | 영향 | 완화 |
|------|------|------|
| 중간 단계에서 기존 코드와 신규 코드 동시 존재 → 혼란 | 일시적 가독성↓ | Phase A 의 getter 는 임시 bridge 로만 사용, Phase C 에서 완전 제거 |
| 75곳 read-site 중 일부 누락 | 런타임 오류 | `flutter analyze` + 파일 단위 커밋 (Phase B 각 파일 1 커밋) |
| Hive 영속 스키마 깨짐 | 사용자 저장 데이터 손실 | `CustomizationMapper` 단일 경계 유지, 스키마 변환은 없음 (필드명만 내부 경로 재매핑) |
| Riverpod `select` 사용 전환 시 이전에 없던 lint/type 에러 | 작은 빌드 에러 | FR-08 은 Medium 우선순위, Phase D 에서 옵션으로 진행 |
| 5개 sub-state `==` 구현 실수 → 불필요 리빌드 또는 반대로 누락 | 기능 회귀 | 각 sub-state 별 간단 equality 테스트 작성 (같은 값 copyWith 후 `identical`/`==` 확인) |

### 4.3 Rollback 전략
- Phase B 진행 중 심각한 회귀 발견 시: 해당 Phase B 커밋만 revert (Phase A getter 덕분에 중간 상태에서도 빌드 가능)
- Phase C 완료 후 회귀 발견 시: 전체 PDCA feature 롤백 (`git revert {merge-commit}`) 
- 실기기 스모크 테스트를 각 Phase 완료마다 수행 권장

---

## 5. Non-Functional Requirements

| # | NFR | 측정 기준 |
|---|-----|----------|
| NFR-01 | 기능 동일성 | PDCA Gap 분석 Match Rate ≥ 90% |
| NFR-02 | 렌더 성능 개선 (Phase D) | 애니메이션 QR 편집 시 `qr_preview_section` 리빌드 횟수 ≥ 50% 감소 |
| NFR-03 | 파일 크기 | `qr_result_provider.dart` ≤ 500줄 (현재 ~650줄) |
| NFR-04 | 공용 state 의존성 | 각 sub-state는 다른 sub-state를 import 하지 않음 (flat composition) |

---

## 6. Regression Test Scenarios (FR-11)

실기기 스모크 테스트 7종:

1. **도트 모양 편집**: Shape 탭 → [+] → 도트 편집기 → 슬라이더 조정 → 저장 → 미리보기 반영
2. **눈 모양 랜덤**: 랜덤 눈 버튼 → 재생성 → 해제
3. **외곽 모양 편집**: Boundary 편집기 → 타입 전환 → 슬라이더 → 저장
4. **애니메이션 편집**: Animation 편집기 → 타입 선택 → speed/amplitude → 저장
5. **색상 그라디언트**: Color 탭 → 프리셋 선택 → 맞춤 편집 → stops 조정
6. **로고 embed**: Sticker 탭 → 로고 타입 전환 (이미지/라이브러리/텍스트) → 중앙 표시 확인
7. **템플릿 저장 후 복원**: 저장 → 앱 재시작 → "나의 템플릿" 적용 → 동일 결과

---

## 7. Effort Estimate

| Phase | 예상 작업 |
|-------|----------|
| A. Sub-state 정의 + getter bridge | 1시간 |
| B. Read-site 마이그레이션 (10 파일 × 평균 7.5 site) | 3시간 |
| C. Flat 필드 제거 + copyWith 재설계 | 1.5시간 |
| D. Performance `select` 전환 (선택) | 1시간 |
| 검증 (analyze + 스모크 테스트 7종) | 1시간 |
| **총** | **~7시간** (Phase D 포함) / **~5.5시간** (핵심만) |

---

## 8. Out of Scope (별도 PDCA)

- `QrResultNotifier` 내부 비즈니스 로직 재설계 (use case 분해 등)
- `StickerConfig` 내부 구조 변경
- Hive 영속 스키마 버전 업 (migration 로직)
- `freezed` 또는 `built_value` 도입
- UI 컴포넌트 재설계

---

## 9. Success Criteria

- [ ] `QrResultState`가 5개 sub-state + `sticker` 로만 구성 (평탄 필드 0개)
- [ ] 각 sub-state 파일 ≤ 150줄
- [ ] `qr_result_provider.dart` ≤ 500줄
- [ ] `flutter analyze` 에러 0건 (FR-10)
- [ ] 실기기 스모크 테스트 7종 전부 통과 (FR-11)
- [ ] PDCA Gap 분석 Match Rate ≥ 90% (FR-12)
- [ ] `_sentinel` 패턴 제거 (FR-07)
- [ ] (선택) 5곳 이상 위젯이 `select` 기반으로 sub-state 구독 (FR-08)

---

## 10. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-04-20 | Initial plan — R2 (QrResultState 26-field → 5 sub-state composite, 3단 점진 마이그레이션) | tawool83 |
