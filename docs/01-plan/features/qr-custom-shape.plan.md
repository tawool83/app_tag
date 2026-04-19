# QR Custom Shape Planning Document

> **Summary**: QR 도트/눈/외곽/애니메이션을 극좌표 다각형 + Superellipse + AnimationController 기반 CustomPainter로 완전 자유도 커스터마이징 + 사용자 프리셋 저장
>
> **Project**: AppTag
> **Version**: 1.0.0
> **Author**: tawool83
> **Date**: 2026-04-18
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 현재 `pretty_qr_code` 기반 렌더링은 도트 5종, 눈 9종 프리셋으로 제한. 연속적 파라미터 조절 불가, QR 외곽 변형 불가, 애니메이션 미지원, 사용자 맞춤 프리셋 저장 불가 |
| **Solution** | `qr` 패키지(순수 매트릭스) + CustomPainter로 극좌표 다각형(도트) + Superellipse(눈) + 클리핑(외곽) + AnimationController(데이터 영역 애니메이션) 직접 렌더링. "+" 버튼 → 파라미터 편집기 → 사용자 프리셋 Hive 저장 패턴 |
| **Function/UX Effect** | 슬라이더로 도트/눈/외곽 실시간 조절 + 데이터 영역 물결·무지개·펄스 애니메이션 + 사용자가 만든 스타일을 저장하여 재사용 |
| **Core Value** | 프리셋 선택이 아닌 파라미터 기반 무한 조합 + 애니메이션으로 살아있는 QR + 개인화 프리셋 라이브러리로 사용자만의 브랜드 QR 생성 |

---

## 1. Overview

### 1.1 Purpose

현재 QR 모양 탭은 `pretty_qr_code` 패키지의 `PrettyQrShape` API에 의존하여 사전 정의된 프리셋(도트 5종, 눈 외곽 5종, 내부 4종)만 선택 가능하다. 이 구조로는 슬라이더 기반의 연속적 파라미터 조절이나 QR 전체 외곽 형태 변경이 불가능하다.

본 기능은 QR 렌더링 레이어를 `pretty_qr_code` 의존에서 완전히 분리하여, 수학적 모델(극좌표 다각형 + Superellipse) 기반의 CustomPainter 직접 렌더링으로 전환한다. 이를 통해:
- **도트**: 꼭짓점 수(n), 내부 반지름, 둥글기, 회전, 사각형화 파라미터로 원→사각→별→꽃 등 무한 형태
- **눈(Eye) 프레임**: Superellipse `|x/a|^n + |y/b|^n = 1` 공식으로 원↔사각 연속 변형
- **QR 외곽**: 원형, 별, 하트 등 비정형 클리핑으로 QR 전체 형태 커스터마이징
- **애니메이션**: 데이터 영역 도트에만 크기 펄스·색상 흐름·페이드 등 애니메이션 (finder/alignment/timing pattern 제외, 스캔 안전성 보장)
- **사용자 프리셋**: 각 카테고리(도트, 눈, 애니메이션)에 "+" 버튼 → 파라미터 편집기 → 완료 시 Hive 저장하여 재사용

### 1.2 Background

- 웹 에디터에서 검증한 극좌표 다각형 + Superellipse 수학 모델을 Flutter로 이식
- `pretty_qr_code`의 `PrettyQrShape` 인터페이스는 모듈 단위 렌더링만 지원 → 전체 QR 형태(클리핑) 처리 불가
- 사용자 피드백: 프리셋 선택만으로는 차별화된 QR 디자인이 어려움
- `qr` 패키지(순수 Dart, 렌더링 없음)는 이미 `pretty_qr_code`의 내부 의존성으로 사용 중

### 1.3 Related Documents

- Design: `docs/02-design/features/qr-custom-shape.design.md` (예정)
- 기존 QR 렌더링: `lib/features/qr_result/widgets/qr_preview_section.dart`
- 기존 도트 스타일: `lib/features/qr_result/domain/entities/qr_dot_style.dart`
- 기존 모양 탭: `lib/features/qr_result/tabs/qr_shape_tab.dart`

---

## 2. Scope

### 2.1 In Scope

- [ ] **S-01**: 극좌표 다각형 기반 도트 렌더링 엔진 (꼭짓점 수, 내부 반지름, 둥글기, 회전, 사각형화)
- [ ] **S-02**: Superellipse 기반 눈 프레임 렌더링 (외곽 + 내부 독립 파라미터)
- [ ] **S-03**: QR 전체 외곽 클리핑 Path (원형, 둥근사각, Superellipse, 별, 하트 등)
- [ ] **S-04**: CustomPainter 기반 QR 렌더러 (`qr` 패키지 매트릭스 → 직접 렌더링)
- [ ] **S-05**: 슬라이더 UI (도트/눈/외곽 파라미터 실시간 조절)
- [ ] **S-06**: 기존 프리셋 호환 (현재 5종 도트 + 눈 조합을 새 엔진의 프리셋으로 매핑)
- [ ] **S-07**: QrTask JSON 직렬화/역직렬화 (새 파라미터 저장·복원)
- [ ] **S-08**: 그라디언트·색상 시스템 연동 (기존 ShaderMask 방식 유지)
- [ ] **S-09**: 이미지 캡처(갤러리 저장, 공유) 호환성 확인
- [ ] **S-10**: 데이터 영역 애니메이션 엔진 (물결, 무지개, 펄스, 페이드 등 프리셋)
- [ ] **S-11**: QR 매트릭스 영역 분류기 (finder/alignment/timing/format/data 판별)
- [ ] **S-12**: "+" 버튼 → 파라미터 편집기 UI 패턴 (도트/눈/애니메이션 각각)
- [ ] **S-13**: 사용자 커스텀 프리셋 저장/로드 (Hive 기반, 도트/눈/애니메이션 독립)
- [ ] **S-14**: 랜덤 스타일 생성 확장 (현재 눈만 → 도트+눈+애니메이션 통합 랜덤)

### 2.2 Out of Scope

- SVG 내보내기 (PNG 캡처만 지원)
- 도트별 개별 색상 (전체 단색 또는 그라디언트만)
- 눈 3개의 독립 스타일링 (3개 눈 동일 스타일 유지)
- 애니메이션 GIF/MP4 내보내기 (화면 내 라이브 미리보기만, 저장은 정적 이미지)
- 도트 위치 이동 애니메이션 (스캔 안전성을 위해 크기·색·투명도만 변화)
- `pretty_qr_code` 패키지 완전 제거 (점진적 전환, 1단계에서는 공존)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | **도트 모양 엔진 [대칭/비대칭 듀얼 모드]**: [대칭] 극좌표 다각형 — 꼭짓점(3~12), 내부 반경(0~1), 둥글기(0~1). [비대칭] Superformula(Gielis) — r(θ)=(\|cos(mθ/4)/a\|^n2+\|sin(mθ/4)/b\|^n3)^(-1/n1), 슬라이더 6개(m,n1,n2,n3,a,b)로 원/별/꽃/하트/나뭇잎/나비 등 거의 모든 형태 생성. 프리셋 9종 + 자유 조합. 공통: 회전(0~360). 채움률 ≥50% 검증. | High | Pending |
| FR-02 | **Superellipse 눈 프레임**: 외곽 n값(2.0~20.0), 내부 n값(2.0~20.0), 회전, 내부 도트 크기 비율 독립 조절 | High | Pending |
| FR-03 | **QR 외곽 클리핑**: 원형, Superellipse, 별, 하트, 육각형 등 프리셋 + 파라미터 조절 | Medium | Pending |
| FR-04 | **CustomPainter QR 렌더러**: `qr` 패키지 매트릭스에서 finder pattern 영역/데이터 도트 판별 후 각각 해당 Path로 렌더링 | High | Pending |
| FR-05 | **슬라이더 UI**: 도트 파라미터 5개 + 눈 파라미터 4개 + 외곽 파라미터 3개, 실시간 미리보기 반영 | High | Pending |
| FR-06 | **프리셋 호환**: 기존 QrDotStyle 5종(square, circle, diamond, heart, star)을 새 엔진 파라미터 조합으로 매핑, 기존 저장 데이터 복원 가능 | High | Pending |
| FR-07 | **JSON 직렬화**: QrCustomization에 새 도트/눈/외곽 파라미터 필드 추가, 하위 호환성 유지 | High | Pending |
| FR-08 | **그라디언트 연동**: 기존 ShaderMask 그라디언트 + 단색 시스템이 새 렌더러와 동일하게 작동 | Medium | Pending |
| FR-09 | **프리셋 갤러리**: 슬라이더 외에 인기 도트/눈 조합 프리셋을 썸네일로 제공하여 빠른 선택 지원 | Medium | Pending |
| FR-10 | **데이터 영역 애니메이션**: AnimationController(0→1 반복) + CustomPainter에서 데이터 도트에만 위상 차이 기반 크기·색·투명도 변화 적용. finder/alignment/timing/format 영역은 항상 정적 유지 | High | Pending |
| FR-11 | **QR 영역 분류기**: 매트릭스에서 finder pattern(3개 7x7), alignment pattern, timing pattern, format info, version info 영역을 정확히 식별하여 "보호 영역"과 "애니메이션 가능 영역" 분리 | High | Pending |
| FR-12 | **애니메이션 프리셋**: 물결(sin wave scale), 무지개(Hue shift), 펄스(scale pulse), 순차 등장(sequential fade-in), 회전(rotation wave) 최소 5종 기본 제공 | Medium | Pending |
| FR-13 | **"+" 버튼 편집기 UI**: 도트/눈/애니메이션 각 섹션의 첫 번째 버튼을 "+" 아이콘으로 표시. 탭하면 색상 탭의 맞춤 그라디언트 편집기와 동일한 패턴으로 파라미터 슬라이더 화면 전환. 확인/취소 버튼 제공 | High | Done |
| FR-14 | **사용자 프리셋 저장**: 편집기에서 "완료" 시 파라미터 세트를 Hive에 저장. 도트/눈/애니메이션 각각 독립 저장. 저장된 프리셋은 프리셋 행에 썸네일로 추가되어 재사용 가능 | High | Done |
| FR-15 | **사용자 프리셋 관리**: 저장된 프리셋 삭제, 이름 변경, 편집(재수정) 지원 | Medium | Done |
| FR-16 | **통합 랜덤 스타일**: 현재 눈 전용 랜덤을 도트+눈+애니메이션 통합 랜덤으로 확장. 시드 기반으로 재현 가능 | Medium | Pending |
| FR-17 | **프리셋 최근 사용순 정렬**: 사용자 프리셋을 `lastUsedAt` 기준 내림차순 정렬. 선택/재사용 시 `touchLastUsed()` 호출하여 타임스탬프 갱신 | High | Done |
| FR-18 | **프리셋 선택 표시**: 현재 선택된 프리셋에 primary 컬러 테두리 + check_circle 아이콘 표시. ID 기반 추적(`_selectedDotPresetId`)으로 동일 파라미터 중복 프리셋 구분 | High | Done |
| FR-19 | **프리셋 선택-정렬 부드러운 전환**: 선택 표시 → 100ms 딜레이 → 정렬 갱신 (AnimatedSwitcher 300ms crossfade) | Medium | Done |
| FR-20 | **프리셋 중복 방지**: 새 프리셋 저장 시 동일 파라미터(`DotShapeParams` equality) 기존 프리셋이 있으면 새로 생성하지 않고 기존 프리셋을 선택 | High | Done |
| FR-21 | **도트 크기(Scale) 미세 조정**: 대칭/비대칭 공통 슬라이더. 범위 0.8~1.15 (80%~115%). QR 포인트 겹침으로 인식률 저하 방지를 위해 의도적으로 좁은 범위 | High | Done |
| FR-22 | **뒤로가기 동작 분기**: (1) 기존 프리셋 수정 모드(롱프레스 진입): [<] = 자동 저장(기존 프리셋 덮어쓰기) + 에디터 닫기. (2) 새 프리셋 생성 모드(+ 버튼 진입): [<] = "저장/취소" 다이얼로그 표시 → 저장 선택 시 프리셋 생성, 취소 선택 시 변경 폐기 | High | Done |
| FR-23 | **편집기 모드 중 탭 스와이프 차단**: `NeverScrollableScrollPhysics()`로 편집기 활성 시 좌우 탭 이동 방지 | Medium | Done |
| FR-24 | **프리셋 그리드 모달**: 프리셋이 많을 때 전체보기 BottomSheet. 뷰/삭제 모드. 롱프레스로 편집 진입 | Medium | Done |
| FR-25 | **저장 버튼 시인성**: AppBar 저장 버튼을 `FilledButton`(배경색)으로 변경하여 텍스트 버튼 대비 가시성 향상 | Low | Done |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 슬라이더 조작 시 QR 렌더링 16ms 이내 (60fps) | DevTools Timeline |
| Performance | QR 매트릭스 생성 + Path 계산 합산 50ms 이내 | Stopwatch 측정 |
| Compatibility | 기존 저장된 QrTask JSON에서 새 렌더러로 정상 복원 | 기존 테스트 데이터로 검증 |
| UX | 슬라이더 조작 → 미리보기 반영 지연 100ms 이내 체감 | 육안 테스트 |
| Performance | 애니메이션 재생 시 60fps 유지 (AnimationController + CustomPainter) | DevTools Timeline |
| Performance | 애니메이션 중 배터리 소모 최소화 — 미리보기 영역 밖 미노출 시 애니메이션 일시정지 | VisibilityDetector 또는 TickerMode |
| Storage | 사용자 프리셋 1개당 Hive 저장 크기 < 1KB (파라미터 값만 저장, 이미지 없음) | Hive box size 측정 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] CustomPainter 기반 QR 렌더러가 기존 pretty_qr_code 렌더링과 동일한 기본 출력 생성
- [ ] 도트 슬라이더 5개 파라미터로 원→사각→별→꽃 연속 변형 확인
- [ ] 눈 프레임 Superellipse 슬라이더로 원↔사각 연속 변형 확인
- [ ] QR 외곽 클리핑으로 원형/별 등 비정형 QR 생성 확인
- [ ] 기존 저장 데이터(QrTask JSON) 하위 호환성 확인
- [ ] 갤러리 저장·공유 기능 정상 동작
- [ ] 그라디언트 + 센터 아이콘 + 텍스트 레이어 정상 합성
- [ ] 애니메이션 QR이 finder pattern 제외 데이터 영역에서만 동작 확인
- [ ] 애니메이션 중 QR 스캔 가능 확인 (실제 기기 테스트)
- [ ] "+" 버튼 → 편집기 → 완료 → 프리셋 추가 플로우 정상 동작
- [ ] 저장된 프리셋이 앱 재시작 후에도 유지 확인
- [ ] 통합 랜덤 스타일로 도트+눈+애니메이션 동시 랜덤 생성 확인

### 4.2 Quality Criteria

- [ ] 빌드 성공 (Android + iOS)
- [ ] 슬라이더 조작 시 60fps 유지
- [ ] 애니메이션 재생 시 60fps 유지
- [ ] 기존 QR 스캔 인식률 유지 (QrReadabilityService 통합)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| CustomPainter 성능: 복잡한 Path 계산으로 슬라이더 조작 시 프레임 드롭 | High | Medium | Path 캐싱(파라미터 변경 시만 재계산), RepaintBoundary 분리, 디바운스 적용 |
| QR 스캔 인식률 저하: 비표준 도트/외곽 형태로 인식 실패 | High | Medium | QrReadabilityService 임계값 경고 유지, 외곽 클리핑 시 quiet zone 보존, 극단적 파라미터에 경고 |
| 기존 데이터 하위 호환: 새 파라미터 구조로 전환 시 기존 JSON 파싱 실패 | Medium | Low | 새 필드는 모두 nullable + 기본값, 기존 enum 값에서 새 파라미터로의 마이그레이션 매퍼 제공 |
| `pretty_qr_code` → `qr` 패키지 전환: 매트릭스 API 차이 | Medium | Low | `qr` 패키지는 이미 `pretty_qr_code`의 내부 의존성, API는 `QrCode.fromData()` → `moduleCount` + `isDark(row, col)` 단순 |
| 도트 간 겹침: 큰 도트 형태(별 등)가 인접 모듈과 겹쳐 시각적 결함 | Low | Medium | 도트 크기를 셀 크기 내로 제한하는 clamp 파라미터, 미리보기에서 즉시 확인 가능 |
| 애니메이션 중 스캔 실패: 도트 크기/투명도 변화가 극단적일 때 인식 실패 | High | Medium | 애니메이션 파라미터에 안전 범위 설정 (scale 0.6~1.2, opacity 0.5~1.0), QrReadabilityService 경고 연동 |
| 애니메이션 배터리 소모: 상시 AnimationController 실행 시 배터리 소모 | Medium | Medium | TickerMode/VisibilityDetector로 화면 밖 시 자동 정지, 사용자 토글로 애니메이션 on/off |
| 영역 분류기 정확도: QR 버전별 alignment pattern 위치가 다름 | Medium | Low | QR 스펙(ISO/IEC 18004) 기반 정확한 영역 테이블 구현, `qr` 패키지의 typeNumber로 판별 |
| 사용자 프리셋 데이터 마이그레이션: 향후 파라미터 추가 시 기존 프리셋 깨짐 | Low | Medium | 프리셋 JSON에 버전 필드 포함, 마이그레이션 함수로 이전 버전 자동 변환 |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure | Static sites | ☐ |
| **Dynamic** | Feature-based modules, BaaS integration | Web apps, SaaS MVPs | ☑ |
| **Enterprise** | Strict layer separation, DI, microservices | High-traffic systems | ☐ |

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| QR 매트릭스 | `pretty_qr_code` 내부 / `qr` 패키지 직접 | `qr` 패키지 직접 | 렌더링 레이어 완전 분리, 순수 매트릭스만 필요 |
| 렌더링 | PrettyQrShape 확장 / CustomPainter 직접 | CustomPainter 직접 | 전체 QR 외곽 클리핑, finder pattern 영역 판별 등 전체 제어 필요 |
| 도트 수학 모델 | 프리셋 enum / 극좌표 다각형 파라미터 | 극좌표 다각형 파라미터 | 연속적 변형(슬라이더)과 무한 조합 지원 |
| 눈 수학 모델 | 프리셋 enum / Superellipse 파라미터 | Superellipse 파라미터 | n값 하나로 원↔사각 연속 변형, iOS squircle(n≈4) 자연스러운 표현 |
| 상태 관리 | QrResultState 확장 | QrResultState에 새 파라미터 그룹 추가 | 기존 Riverpod 패턴 유지 |
| pretty_qr_code 처리 | 즉시 제거 / 점진적 전환 | 점진적 전환 | 1단계: 새 렌더러 추가 + 토글, 2단계: 안정화 후 제거 |
| 애니메이션 | Rive / Lottie / AnimationController+CustomPainter | AnimationController+CustomPainter | QR 도트 개별 제어 필요, 외부 애니메이션 도구로는 매트릭스 연동 불가 |
| 프리셋 저장 | SharedPreferences / Hive / SQLite | Hive | 이미 프로젝트에서 사용 중, 구조화 데이터 저장에 적합 |
| 편집기 UI 패턴 | BottomSheet / 풀스크린 / 인라인 전환 | 인라인 전환 (색상 탭 맞춤 그라디언트 패턴) | 기존 UX 일관성, 미리보기 유지하면서 편집 가능 |

### 6.3 Clean Architecture Approach

```
Selected Level: Dynamic (Feature-based modules)

핵심 변경 파일 구조:
┌──────────────────────────────────────────────────────────────┐
│ lib/features/qr_result/                                      │
│   domain/entities/                                           │
│     qr_shape_params.dart        ← NEW: 도트/눈/외곽 파라미터 모델│
│     qr_dot_style.dart           ← UPDATE: 프리셋→파라미터 매핑  │
│   widgets/                                                   │
│     custom_qr_painter.dart      ← NEW: CustomPainter 렌더러   │
│     qr_preview_section.dart     ← UPDATE: 렌더러 교체          │
│     qr_layer_stack.dart         ← UPDATE: 새 렌더러 연동       │
│   tabs/                                                      │
│     qr_shape_tab.dart           ← UPDATE: 슬라이더 UI 추가     │
│   qr_result_provider.dart       ← UPDATE: 새 파라미터 상태 추가  │
│   utils/                                                     │
│     polar_polygon.dart          ← NEW: 극좌표 다각형 Path 생성  │
│     superellipse.dart           ← NEW: Superellipse Path 생성  │
│     qr_matrix_helper.dart       ← NEW: finder pattern 영역 판별│
│     qr_animation_engine.dart    ← NEW: 애니메이션 계산 엔진     │
│   data/datasources/                                          │
│     local_user_shape_preset_datasource.dart ← NEW: Hive 프리셋│
│   domain/entities/                                           │
│     user_shape_preset.dart      ← NEW: 사용자 프리셋 모델      │
│     qr_animation_params.dart    ← NEW: 애니메이션 파라미터 모델  │
└──────────────────────────────────────────────────────────────┘
```

### 6.4 수학 모델 상세

#### 도트 모양 엔진 (듀얼 모드)

```
[대칭 모드] 극좌표 다각형
  파라미터:
    n (꼭짓점 수): 3~12 → 삼각형~12각형(≈원)
    innerRadius (내부 반경): 0.0~1.0 → 0=첨예한 별, 1=볼록 다각형
  공통: roundness(둥글기 0~1), rotation(회전 0~360)

  생성 알고리즘:
    for i in 0..n*2:
      r = (i.isEven) ? outerRadius : outerRadius * innerRadius
      angle = (i * PI / n) + rotation
      vertex = polar_to_cartesian(r, angle)
    → roundness > 0이면 cubicTo로 보간

[비대칭 모드] Superformula (Gielis, 1999)
  단 하나의 공식으로 원, 사각형, 별, 꽃, 나뭇잎, 하트, 나비 등 거의 모든 2D 형태 생성.

  공식 (극좌표):
    r(θ) = ( |cos(mθ/4)/a|^n2 + |sin(mθ/4)/b|^n3 )^(-1/n1)

  파라미터 (슬라이더 6개):
    m  (대칭 차수): 0~20 — 회전 대칭 반복 수 (0=원, 3=삼각, 4=사각, 5=별, 6=꽃 ...)
    n1 (곡률 1):   0.1~40 — 전체 형태 둥글기 (작으면 뾰족, 크면 둥글)
    n2 (곡률 2):   0.1~40 — cos 항 곡률 제어
    n3 (곡률 3):   -5~40 — sin 항 곡률 제어 (음수 → 비대칭/오목)
    a  (X 스케일): 0.5~2.0 — 가로 비율
    b  (Y 스케일): 0.5~2.0 — 세로 비율

  프리셋 (파라미터 조합):
    원:      m=0,  n1=1,   n2=1,   n3=1,   a=1, b=1
    사각형:  m=4,  n1=100, n2=100, n3=100, a=1, b=1
    별:      m=5,  n1=0.3, n2=0.3, n3=0.3, a=1, b=1
    꽃:      m=6,  n1=1,   n2=1,   n3=8,   a=1, b=1
    나뭇잎:  m=1,  n1=0.5, n2=0.5, n3=0.5, a=1, b=1
    하트:    m=1,  n1=1,   n2=0.8, n3=-0.5,a=1, b=1
    나비:    m=3,  n1=1,   n2=6,   n3=1,   a=1, b=1
    다이아몬드: m=4, n1=2, n2=1, n3=1,     a=1, b=1
    물방울:  m=1,  n1=0.5, n2=1,   n3=0.3, a=0.8, b=1.2

  공통 슬라이더:
    rotation (회전): 0~360도
    scale (크기): 0.8~1.15 (QR 인식 범위 내 미세 조정, 포인트 겹침 방지)

  생성 알고리즘:
    θ in 0..2π, steps=128:
      r = superformula(θ, m, n1, n2, n3, a, b)
      x = r * cos(θ), y = r * sin(θ)
    → bounding box 정규화 → 셀 크기에 맞춤 → rotation 적용

  채움률(Fill Ratio) 검증:
    생성된 도형 면적 ÷ 셀 면적 ≥ 50% 이상이어야 QR 스캐너 인식 보장.
    미달 시 경고 SnackBar 표시.
```

#### Superellipse (눈 프레임)

```
공식: |x/a|^n + |y/b|^n = 1

파라미터:
  n (형태): 2.0=원, ~4.0=squircle(iOS), →∞=사각형
  rotation: 0~360도
  innerScale: 0.3~0.8 (내부 도트 크기 비율)

Path 생성:
  t in 0..2PI, step=0.01:
    x = a * sign(cos(t)) * |cos(t)|^(2/n)
    y = b * sign(sin(t)) * |sin(t)|^(2/n)
```

### 6.5 애니메이션 엔진 상세

#### QR 매트릭스 영역 분류

```
QR 매트릭스 영역:
┌─────────────────────────────────────────────────┐
│ [보호 영역 — 절대 변경 금지]                       │
│   • Finder Pattern: 3개 코너 7×7 블록             │
│   • Separator: finder 주변 1모듈 백색 갭           │
│   • Timing Pattern: 6행/6열 교대 흑백             │
│   • Alignment Pattern: 버전별 위치 (v2+)          │
│   • Format Information: finder 인접 15비트         │
│   • Version Information: v7+ 전용 18비트           │
│                                                   │
│ [애니메이션 가능 영역]                              │
│   • Data + Error Correction 모듈                  │
│   • 오류 정정 한도(Level H=30%) 내 안전 도트        │
│   • 도트 중심 위치 고정, 크기·색·투명도만 변화       │
└─────────────────────────────────────────────────┘
```

#### 애니메이션 수학 모델

```
AnimationController: 0.0 → 1.0 반복 (duration 조절 가능)

프리셋별 계산식 (animValue=t, 도트 위치=(x,y), gridSize=N):

1. 물결 (Wave Scale):
   scale = sin(t * 2π + (x+y) * 0.3) * amplitude + baseScale
   amplitude: 0.1~0.3, baseScale: 0.8

2. 무지개 (Rainbow Hue):
   hue = ((t + x/N) % 1.0) * 360
   color = HSVColor(hue, saturation, value)

3. 펄스 (Pulse):
   scale = sin(t * 2π) * 0.15 + 0.85  (전체 동시)

4. 순차 등장 (Sequential Fade):
   delay = (x + y * N) / (N * N)
   opacity = clamp((t - delay) * 3, 0, 1)

5. 회전 물결 (Rotation Wave):
   rotation = sin(t * 2π + distance_from_center * 0.5) * maxAngle

제약 조건:
  • scale 범위: 0.6 ~ 1.2 (스캔 안전)
  • opacity 범위: 0.5 ~ 1.0 (스캔 안전)
  • 위치(x,y) 변경: 금지
```

### 6.6 "+" 버튼 편집기 UI 패턴

```
기존 색상 탭 맞춤 그라디언트 패턴을 도트/눈/애니메이션에 동일 적용:

[모양 탭 기본 화면]
┌──────────────────────────────────────────┐
│ ■ 도트 모양                               │
│ [+] [●] [◆] [♥] [★] [사용자1] [사용자2]  │
│                                          │
│ ■ 눈 외곽                                │
│ [+] [□] [◎] [○] [◐] [사용자1]            │
│                                          │
│ ■ 눈 내부                                │
│ [+] [■] [●] [◇] [★] [사용자1]            │
│                                          │
│ ■ 애니메이션                              │
│ [+] [없음] [물결] [무지개] [펄스] [사용자1] │
│                                          │
│ [🎲 랜덤 스타일]  [초기화]                  │
└──────────────────────────────────────────┘

["+" 탭 시 편집기로 전환] (QrColorTab의 _colorEditorMode 패턴)
┌──────────────────────────────────────────┐
│ ■ 도트 모양 편집기                         │
│                                          │
│  [■ 대칭]  [♥ 비대칭]     ← 상단 토글 버튼 │
│                                          │
│ ── [대칭 모드] ──────────────────────     │
│ 꼭짓점 수  ───●──────  5                  │
│ 내부 반경  ──────●───  0.7               │
│ 둥글기     ─●────────  0.2               │
│ 회전       ──────●───  45°               │
│                                          │
│ ── [비대칭 모드] ────────────────────     │
│ [●원][■사각][★별][✿꽃][🍃잎][♥하트][🦋나비]│
│ m (대칭)   ──────●───  5                  │
│ n1 (곡률)  ──────●───  0.3               │
│ n2 (곡률)  ──────●───  0.3               │
│ n3 (곡률)  ──────●───  0.3               │
│ a (X비율)  ───●──────  1.0               │
│ b (Y비율)  ───●──────  1.0               │
│ 회전       ──────●───  45°               │
│                                          │
│ ⚠ 채움률 42% — 인식률 낮을 수 있음 (≥50%) │
│                                          │
│        [취소]        [확인]               │
└──────────────────────────────────────────┘

플로우:
1. "+" 버튼 탭 → 편집기 모드 활성화 (색상 탭 _colorEditorMode와 동일)
2. 상단 [대칭/비대칭] 토글로 모드 선택 → 해당 모드의 슬라이더만 표시
3. 하단 액션 버튼 숨김 (qr_result_screen에서 _shapeEditorMode 상태)
4. 슬라이더로 파라미터 조절 → QR 미리보기 실시간 반영
5. 비대칭 모드: Superformula 프리셋 선택 후 슬라이더 6개로 자유 변형
6. 채움률 < 50% 시 경고 SnackBar
7. "저장(확인)" → Hive에 프리셋 저장 + 프리셋 행에 썸네일 추가 + 편집기 닫기
8. [<] 뒤로가기 동작 분기:
   - 기존 프리셋 수정(롱프레스 진입): 자동 저장 + 닫기
   - 새 프리셋 생성(+ 버튼): "저장/취소" 다이얼로그
9. 저장된 프리셋은 롱프레스로 편집 진입, 그리드 모달에서 삭제 가능
10. 프리셋 목록은 lastUsedAt 기준 정렬, 선택 시 100ms 딜레이 후 재정렬
11. 동일 파라미터 프리셋 중복 방지 (equality 체크)
```

### 6.7 사용자 프리셋 데이터 모델

```dart
// Hive Box: 'user_dot_presets', 'user_eye_presets', 'user_animation_presets'

class UserDotPreset {
  String id;          // UUID
  String name;        // 사용자 지정 이름
  DateTime createdAt;
  DateTime lastUsedAt; // 최근 사용 시각 (정렬용, fallback: createdAt)
  String mode;        // 'symmetric' | 'asymmetric'
  // 대칭 전용
  int? vertices;      // 꼭짓점 수 (3~12)
  double? innerRadius;// 내부 반경 (0~1)
  // 비대칭 전용 (Superformula 파라미터)
  double? m;          // 대칭 차수 (0~20)
  double? n1;         // 곡률 1 (0.1~40)
  double? n2;         // 곡률 2 (0.1~40)
  double? n3;         // 곡률 3 (-5~40)
  double? a;          // X 스케일 (0.5~2.0)
  double? b;          // Y 스케일 (0.5~2.0)
  // 공통
  double roundness;   // 둥글기 (0~1)
  double rotation;    // 회전 (0~360)
}

class UserEyePreset {
  String id;
  String name;
  DateTime createdAt;
  double outerN;      // 외곽 superellipse n
  double innerN;      // 내부 superellipse n
  double rotation;
  double innerScale;  // 내부 크기 비율
}

class UserAnimationPreset {
  String id;
  String name;
  DateTime createdAt;
  String type;        // wave, rainbow, pulse, sequential, rotation
  double speed;       // AnimationController duration 배수
  double amplitude;   // 효과 강도
  double frequency;   // 위상 차이 주파수
}
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [x] Clean Architecture (domain/data/presentation 분리)
- [x] Riverpod 상태 관리
- [x] QrTask JSON 직렬화 패턴 (`QrCustomization` 모델)
- [x] 다국어(i18n) ARB 파일 패턴
- [x] `analysis_options.yaml` lint 설정

### 7.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **수학 유틸 위치** | 없음 | `utils/polar_polygon.dart`, `utils/superellipse.dart` | High |
| **파라미터 모델** | enum 기반 | `qr_shape_params.dart` — 불변 클래스 + copyWith | High |
| **CustomPainter 패턴** | 부분적 (아이콘 렌더링) | `custom_qr_painter.dart` — shouldRepaint 최적화 | High |
| **슬라이더 UI 패턴** | 없음 | Slider + 라벨 + 값 표시 공통 위젯 | Medium |

### 7.3 패키지 의존성 변경

| Package | Action | Rationale |
|---------|--------|-----------|
| `qr: ^3.0.0` | 추가 (직접 의존) | 매트릭스 데이터 직접 접근 |
| `pretty_qr_code: ^3.3.0` | 유지 (1단계) | 점진적 전환, 기존 코드 호환 |

> `qr` 패키지는 이미 `pretty_qr_code`의 transitive dependency로 설치되어 있으므로, `pubspec.yaml`에 직접 선언만 추가하면 됨.

---

## 8. Implementation Strategy

### 8.1 Phase 구분 (순차 구현)

> 도트 → 눈 → 애니메이션 각각 완성한 후, 통합 랜덤으로 진행

| Phase | 내용 | 우선순위 | 의존 |
|-------|------|----------|------|
| **Phase 1** | 수학 유틸(polar_polygon, superellipse) + CustomPainter 기본 렌더러 + QR 매트릭스 영역 분류기 | P0 | - |
| **Phase 2** | **도트 커스텀**: 극좌표 다각형 렌더링 + "+" 편집기 UI + 사용자 프리셋 저장(Hive) + 기존 enum 호환 | P0 | Phase 1 |
| **Phase 3** | **눈 커스텀**: Superellipse 외곽/내부 렌더링 + "+" 편집기 UI + 사용자 프리셋 저장 | P0 | Phase 1 |
| **Phase 4** | **애니메이션**: AnimationController + 데이터 영역 애니메이션 엔진 + "+" 편집기 UI + 프리셋 저장 | P1 | Phase 1 |
| **Phase 5** | **QR 외곽 클리핑**: 원형, Superellipse, 별, 하트 등 + 파라미터 조절 | P1 | Phase 1 |
| **Phase 6** | **통합**: 그라디언트/색상/아이콘/텍스트 레이어 + 통합 랜덤 스타일 (도트+눈+애니메이션) | P1 | Phase 2~4 |
| **Phase 7** | **직렬화**: QrTask JSON 새 파라미터 + 하위 호환 마이그레이션 + 프리셋 내보내기 | P2 | Phase 2~4 |

### 8.2 기존 코드 영향 범위

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `qr_preview_section.dart` | Major | `buildPrettyQr()` → 새 CustomPainter 기반 렌더러로 교체 |
| `qr_layer_stack.dart` | Medium | QR 위젯 교체, AnimatedBuilder 래핑 |
| `qr_result_provider.dart` | Major | 도트/눈/애니메이션 파라미터 + 편집기 모드 상태 추가 |
| `qr_shape_tab.dart` | Major | "+" 버튼 + 프리셋 행 + 편집기 모드 전환 전면 재구성 |
| `qr_result_screen.dart` | Medium | _shapeEditorMode 상태 + 탭 전환 시 편집기 자동 확인(색상 탭 패턴) |
| `qr_dot_style.dart` | Medium | enum → 파라미터 매핑 함수 추가 |
| `customization_mapper.dart` | Medium | 새 파라미터 직렬화/역직렬화 |
| `local_default_template_datasource.dart` | Minor | 프리셋 템플릿 파라미터 업데이트 |
| **NEW** `custom_qr_painter.dart` | NEW | CustomPainter + shouldRepaint + 애니메이션 연동 |
| **NEW** `qr_matrix_helper.dart` | NEW | 영역 분류기 (finder/alignment/timing/data) |
| **NEW** `qr_animation_engine.dart` | NEW | 애니메이션 프리셋 계산 엔진 |
| **NEW** `local_user_shape_preset_datasource.dart` | NEW | Hive 기반 사용자 프리셋 CRUD |
| **NEW** `user_shape_preset.dart` | NEW | 프리셋 도메인 모델 (dot/eye/animation) |

---

## 9. Next Steps

1. [ ] Write design document (`qr-custom-shape.design.md`)
2. [ ] 수학 모델 프로토타입 (polar_polygon + superellipse 단위 테스트)
3. [ ] CustomPainter 렌더러 구현
4. [ ] 슬라이더 UI 설계 및 구현

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-18 | Initial draft — 도트/눈/외곽 커스텀 | tawool83 |
| 0.2 | 2026-04-18 | 애니메이션 QR, "+" 편집기 UI, 사용자 프리셋 저장, 통합 랜덤 추가 | tawool83 |
| 0.3 | 2026-04-18 | 도트 squareness 제거 → [대칭/비대칭] 듀얼 모드 + Superformula(Gielis) 6파라미터(m,n1,n2,n3,a,b) + 프리셋 9종 + 채움률 검증. UserDotPreset 모델 Superformula 파라미터로 교체 | tawool83 |
| 0.4 | 2026-04-20 | 사용자 도트 프리셋 UX 요구사항 추가 (FR-17~FR-25): lastUsedAt 정렬, ID 기반 선택 표시, AnimatedSwitcher 전환, 중복 방지, Scale 슬라이더(0.8~1.15), 뒤로가기 동작 분기(자동저장/다이얼로그), 탭 스와이프 차단, 그리드 모달, FilledButton 저장 | tawool83 |
