# svg-save Planning Document

> **Summary**: QR 액션 바텀시트에 "SVG 저장" 메뉴를 추가하고, CustomQrPainter 렌더링 파이프라인을 SVG 문자열로 재현하여 벡터 파일로 저장
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Author**: Claude
> **Date**: 2026-04-23
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 현재 QR 저장은 PNG(래스터)만 지원하여, 인쇄물·대형 배너 등 고해상도 용도에서 품질 저하 발생 |
| **Solution** | CustomQrPainter와 동일한 QR 데이터+스타일 파라미터를 SVG `<path>` 문자열로 변환하는 `QrSvgGenerator` 유틸리티 신규 작성 |
| **Function/UX Effect** | 바텀시트 "갤러리 저장" 바로 아래 "SVG 저장" 메뉴 1개 추가, 탭 시 SVG 파일을 기기 파일 시스템에 저장 후 공유 시트 표시 |
| **Core Value** | 무한 확대 가능한 벡터 QR 출력으로 인쇄·브랜딩 용도 대응 |

---

## 1. Overview

### 1.1 Purpose

홈 화면 QR 타일 롱프레스 바텀시트(`QrTaskActionSheet`)에 "SVG 저장" 액션을 추가하여, 사용자가 현재 스타일링(도트 모양, 눈 모양, 색상, 그라디언트, 외곽 클리핑)이 반영된 SVG 벡터 파일을 다운로드할 수 있게 한다.

### 1.2 Background

- 현재 QR 출력 경로: PNG `thumbnailBytes` → 갤러리 저장 / 공유 / 인쇄
- PNG는 래스터이므로 확대 시 계단 현상 발생
- SVG는 벡터 기반으로 해상도 무관하게 선명 — 인쇄물, 명함, 포스터 용도에 필수
- `CustomQrPainter`의 렌더링 로직은 `Path` 객체(PolarPolygon, SuperellipsePath) 기반 → SVG `<path d="...">` 로 직접 변환 가능

### 1.3 Related Documents

- 참조 구현: `lib/features/qr_result/widgets/custom_qr_painter.dart`
- 도트 Path: `lib/features/qr_result/utils/polar_polygon.dart`
- 눈 Path: `lib/features/qr_result/utils/superellipse.dart`
- 출력 Repository: `lib/features/qr_result/data/repositories/qr_output_repository_impl.dart`

---

## 2. Scope

### 2.1 In Scope

- [x] `QrTaskActionSheet`에 "SVG 저장" ListTile 추가 (갤러리 저장 아래)
- [x] `QrSvgGenerator` 유틸 신규: QR 데이터 + 스타일 파라미터 → SVG 문자열 생성
- [x] `QrOutputRepository`에 `saveAsSvg` 메서드 추가
- [x] `SaveQrAsSvgUseCase` 신규
- [x] SVG 파일 임시 저장 후 `share_plus`로 공유 시트 표시
- [x] l10n: `actionSaveSvg` 키 추가 (ko 선반영)

### 2.2 Out of Scope

- 로고/이미지 오버레이의 SVG 내 임베딩 (PNG 비트맵 → SVG 변환 불가, 별도 feature)
- 장식 프레임(`DecorativeFramePainter`) SVG 변환 (후속 feature)
- 마진 패턴(`QrMarginPatternEngine`) SVG 변환 (후속 feature)
- 애니메이션 파라미터 SVG 반영 (SVG는 정적 출력)
- SVG 편집/미리보기 UI

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | `QrTaskActionSheet`의 "갤러리 저장" ListTile 바로 아래에 "SVG 저장" ListTile 표시 | High | Pending |
| FR-02 | SVG 저장 탭 시 현재 QR의 모든 스타일(도트 모양, 눈 모양, 색상/그라디언트, 외곽 boundary)이 반영된 SVG 파일 생성 | High | Pending |
| FR-03 | 생성된 SVG 파일을 `share_plus`로 공유 시트에 표시 (사용자가 파일 앱·메일·메신저 등으로 내보내기 가능) | High | Pending |
| FR-04 | 로고/이미지가 있는 QR의 경우 clear zone만 비워두고 로고는 SVG에 포함하지 않음 (scope 외) — 사용자에게 별도 안내 불필요 | Medium | Pending |
| FR-05 | SVG viewBox는 QR 모듈 크기 기반 정사각형 (예: `0 0 {moduleCount*cellSize} {moduleCount*cellSize}`) | Medium | Pending |
| FR-06 | 그라디언트 적용 시 SVG `<linearGradient>` / `<radialGradient>` `<defs>` 로 변환 | Medium | Pending |
| FR-07 | 외곽 boundary 클리핑 적용 시 SVG `<clipPath>` 로 변환 | Medium | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| 성능 | SVG 생성 ≤ 500ms (일반 QR 기준) | 프로파일링 |
| 파일 크기 | SVG 파일 ≤ 200KB (version 25, EC-H 기준) | 파일 크기 확인 |
| 호환성 | 생성된 SVG가 주요 뷰어(Chrome, Illustrator, Inkscape)에서 정상 렌더 | 수동 확인 |

---

## 4. Technical Approach

### 4.1 SVG 생성 전략: Path 재생성 방식

Canvas-to-SVG 브릿지 대신, `CustomQrPainter`와 동일한 입력 파라미터로 SVG 문자열을 직접 생성한다.

**근거**:
- `PolarPolygon.buildPath()` / `SuperellipsePath.buildPath()` 는 `Path` 객체(moveTo/lineTo/cubicTo)를 반환
- Flutter `Path`는 `PathMetrics` / `PathOperation`은 있지만 SVG serialize API가 없음
- 그러나 두 함수 내부의 수학 로직(cos/sin 좌표 계산)은 SVG `d` attribute 문자열로 직접 변환 가능
- 별도 `QrSvgGenerator` 클래스에서 동일한 수학 로직으로 SVG path data 문자열을 생성

### 4.2 데이터 소스

현재 `QrTaskActionSheet`는 `QrTask` 객체만 받으며 스타일 파라미터를 갖지 않는다.
SVG 생성에는 `QrResultState`의 스타일 정보가 필요하므로, `QrTask`에 저장된 스타일 데이터를 활용한다.

**QrTask.template (UserQrTemplate)** 에 이미 모든 스타일 파라미터가 Hive 직렬화되어 있음:
- `dotShape` → DotShapeParams
- `eyeShape` → EyeShapeParams
- `boundary` → QrBoundaryParams
- `colorValue` / `gradientStartColor` / `gradientEndColor` → 색상
- `deepLink` → QR 데이터 문자열 (QrImage 생성용)

따라서 추가 state 주입 없이 `QrTask.template` + `QrTask.meta.deepLink` 로 SVG 생성 가능.

---

## 5. Data Flow

```
QrTaskActionSheet."SVG 저장" tap
  → SaveQrAsSvgUseCase(task)
    → QrSvgGenerator.generate(deepLink, template) → String (SVG)
    → QrOutputRepository.saveAsSvg(svgString, appName)
      → 임시 디렉터리에 .svg 파일 쓰기
      → share_plus로 공유 시트 표시
```

---

## 6. Implementation Items

| # | Item | New/Modify | File |
|---|------|-----------|------|
| 1 | `QrSvgGenerator` | New | `lib/features/qr_result/utils/qr_svg_generator.dart` |
| 2 | `QrOutputRepository.saveAsSvg` | Modify | `lib/features/qr_result/domain/repositories/qr_output_repository.dart` |
| 3 | `QrOutputRepositoryImpl.saveAsSvg` | Modify | `lib/features/qr_result/data/repositories/qr_output_repository_impl.dart` |
| 4 | `SaveQrAsSvgUseCase` | New | `lib/features/qr_result/domain/usecases/save_qr_as_svg_usecase.dart` |
| 5 | `saveQrAsSvgUseCaseProvider` | Modify | `lib/features/qr_result/presentation/providers/qr_result_providers.dart` |
| 6 | "SVG 저장" ListTile 추가 | Modify | `lib/features/home/widgets/qr_task_action_sheet.dart` |
| 7 | l10n `actionSaveSvg` 키 | Modify | `lib/l10n/app_ko.arb` + 생성 파일들 |

---

## 7. Architecture

### 7.1 Project Level

Flutter Dynamic × Clean Architecture × R-series

### 7.2 Key Architectural Decisions

| Item | Decision |
|------|----------|
| Framework | Flutter |
| State Management | Riverpod StateNotifier |
| Local Storage | Hive |
| Routing | go_router |
| SVG 생성 | 자체 구현 (외부 패키지 불필요 — 수학 로직 재사용) |
| SVG 공유 | share_plus (기존 의존성) |
| 임시 파일 | path_provider (기존 의존성) |

### 7.3 디렉터리 구조 (변경분)

```
lib/features/qr_result/
├── utils/
│   └── qr_svg_generator.dart          # NEW: SVG 문자열 생성
├── domain/
│   ├── repositories/
│   │   └── qr_output_repository.dart  # MODIFY: saveAsSvg 추가
│   └── usecases/
│       └── save_qr_as_svg_usecase.dart # NEW
├── data/
│   └── repositories/
│       └── qr_output_repository_impl.dart # MODIFY: saveAsSvg 구현
└── presentation/
    └── providers/
        └── qr_result_providers.dart   # MODIFY: provider 추가

lib/features/home/
└── widgets/
    └── qr_task_action_sheet.dart       # MODIFY: ListTile 추가
```

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| PolarPolygon의 cubicTo 곡선 SVG 변환 정확도 | SVG와 Canvas 렌더 결과 미세 차이 | 동일 수학 로직 사용, 100-segment polyline으로 충분한 정밀도 보장 |
| 그라디언트 SVG 변환 복잡성 | SVG `<linearGradient>` 매핑 필요 | Flutter Gradient → SVG defs 변환 유틸 별도 구현 |
| QrTask에 template 없는 구버전 데이터 | SVG 생성 불가 | template null 체크 → 없으면 "SVG 저장" 비활성화 또는 스낵바 안내 |

---

## 9. Success Criteria

- [ ] "SVG 저장" 메뉴가 "갤러리 저장" 바로 아래에 표시됨
- [ ] 탭 시 .svg 파일 공유 시트가 열림
- [ ] 공유된 SVG를 브라우저에서 열었을 때 QR 스타일(도트/눈/색상/경계)이 Canvas 렌더와 일치
- [ ] 로고 clear zone 영역이 SVG에서 비어있음
- [ ] 그라디언트 QR이 SVG에서도 그라디언트로 렌더됨
