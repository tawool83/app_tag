# Plan: template-data-completeness

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | 템플릿 데이터 완전성 + 버전 관리 |
| 작성일 | 2026-04-23 |
| 예상 변경 파일 | ~7개 |

### Value Delivered

| 관점 | 내용 |
|------|------|
| Problem | 사용자 템플릿 저장 시 색상만 적용되고 도트모양/눈모양/외곽 등 커스텀 파라미터가 누락됨. 또한 사용자 커스텀 모양이 삭제되면 템플릿 복원 불가 |
| Solution | 템플릿 저장 시 모든 QR 스타일 데이터를 JSON 스냅샷으로 저장 + 스키마 버전/엔진 버전 관리 |
| Function UX Effect | 템플릿 선택 시 저장 시점의 QR 디자인이 100% 복원됨 |
| Core Value | 사용자가 만든 디자인이 어떤 상황에서도 유실되지 않는 신뢰성 확보 |

---

## 1. 요구사항

### 1.1 버그 (현재 상태)

**저장 누락 필드** — `UserQrTemplate` 및 Hive 모델에 없음:
| 필드 | 타입 | 설명 |
|------|------|------|
| `customDotParams` | `DotShapeParams?` | 사용자 커스텀 도트 모양 (극좌표/Superformula) |
| `customEyeParams` | `EyeShapeParams?` | 사용자 커스텀 눈 모양 |
| `boundaryParams` | `QrBoundaryParams` | QR 외곽 모양 (superellipse, star, heart 등) |

> **참고**: `animationParams`(도트 애니메이션)는 기능 제거 예정이므로 템플릿 저장 대상에서 제외.

**적용 누락** — `applyUserTemplate()`에서 위 3필드를 복원하지 않음

**저장 시점 스냅샷 부재** — 템플릿이 사용자 커스텀 모양의 ID/index만 저장하므로, 원본이 삭제되면 복원 불가

### 1.2 요구사항

| ID | 요구사항 | 우선도 |
|----|----------|--------|
| R1 | 템플릿 저장 시 QrStyleState 주요 필드를 JSON 스냅샷으로 저장 (animationParams 제외) | Must |
| R2 | 템플릿 적용 시 스냅샷에서 모든 스타일 필드 복원 | Must |
| R3 | 로고/스티커 레이어도 완전 저장 (기존 동작 유지 확인) | Must |
| R4 | 템플릿 데이터 스키마 버전 (`schemaVersion`) 관리 | Must |
| R5 | 템플릿 엔진 버전 (`minEngineVersion`) 관리 — 하위 호환 판단용 | Must |
| R6 | 기존 Hive 저장 템플릿 → 새 스키마 마이그레이션 (무손실) | Must |
| R7 | 스냅샷은 참조(ID)가 아닌 값 복사 — 원본 삭제에도 복원 보장 | Must |

---

## 2. 현재 아키텍처 분석

### 2.1 데이터 흐름

```
[QR편집 화면] ──save──→ [UserQrTemplate entity] ──Hive DTO──→ [UserQrTemplateModel] ──persist──→ Hive Box
                                                                                          │
[QR편집 화면] ←─apply──← [UserQrTemplate entity] ←─toEntity()─← [UserQrTemplateModel] ←──load──┘
```

### 2.2 현재 UserQrTemplate 저장 필드 (38개 HiveField)

| 레이어 | 저장됨 | 누락됨 |
|--------|--------|--------|
| 색상 | qrColor, gradient, quietZoneColor | - |
| 모양 enum | dotStyle, eyeOuter, eyeInner, randomEyeSeed, roundFactor | - |
| 모양 params | - | **customDotParams, customEyeParams** |
| 외곽 | - | **boundaryParams** |
| 애니메이션 | - | ~~animationParams~~ (기능 제거 예정, 저장 불필요) |
| 로고 | logoType, logoAssetId, logoImageBytes, logoText*, logoBackgroundColor | - |
| 스티커 | logoPosition, logoBackground, topText*, bottomText* | - |
| 메타 | id, name, createdAt, updatedAt, thumbnail, remoteId, syncedToCloud | **schemaVersion, minEngineVersion** |

### 2.3 직렬화 현황

모든 누락 엔티티에 `toJson()`/`fromJson()` 이미 존재:
- `DotShapeParams.toJson()` / `DotShapeParams.fromJson()`
- `EyeShapeParams.toJson()` / `EyeShapeParams.fromJson()`
- `QrBoundaryParams.toJson()` / `QrBoundaryParams.fromJson()`

→ Hive에 JSON 문자열(`String?`)로 저장하면 됨. 기존 gradient와 동일 패턴.

---

## 3. 변경 계획

### 3.1 스키마 버전 전략

```
schemaVersion: int (현재 데이터 구조 버전)
  - v1: 기존 (HiveField 0~37, 커스텀 파라미터 없음)
  - v2: 이번 변경 (HiveField 38~42 추가, 커스텀 파라미터 + 버전 관리)

minEngineVersion: int (이 템플릿을 처리할 수 있는 최소 엔진 버전)
  - 엔진 버전 = 앱 내 상수 (kTemplateEngineVersion = 2)
  - 로드 시: template.minEngineVersion > kTemplateEngineVersion 이면 "업데이트 필요" 안내
```

### 3.2 Hive 모델 확장

기존 HiveField는 **절대 변경/삭제 불가** (Hive 호환). 새 필드만 추가:

| HiveField | 필드명 | 타입 | 설명 |
|-----------|--------|------|------|
| 38 | `customDotParamsJson` | `String?` | DotShapeParams.toJson() 직렬화 |
| 39 | `customEyeParamsJson` | `String?` | EyeShapeParams.toJson() 직렬화 |
| 40 | `boundaryParamsJson` | `String?` | QrBoundaryParams.toJson() 직렬화 |
| 41 | `schemaVersion` | `int` | 데이터 구조 버전 (기본 2) |
| 42 | `minEngineVersion` | `int` | 최소 엔진 버전 (기본 1) |

### 3.3 마이그레이션 전략

기존 v1 템플릿 (HiveField 38~42 = null):
- `schemaVersion` null → v1로 취급
- `customDotParamsJson` null → 기본값 (도트 enum으로만 결정)
- `boundaryParamsJson` null → `QrBoundaryParams.square` (기본)
- 별도 마이그레이션 로직 불필요 — Hive는 새 필드를 null로 반환, 코드에서 null → 기본값 처리

### 3.4 minEngineVersion 결정 로직

템플릿 저장 시 사용된 기능에 따라 자동 결정:
```
minEngineVersion = 1 (기본: enum 도트/눈 + 색상만 사용)

if customDotParams != null → minEngineVersion = max(_, 2)
if customEyeParams != null → minEngineVersion = max(_, 2)
if boundaryParams != default → minEngineVersion = max(_, 2)
```

---

## 4. 변경 대상 파일

| # | 파일 | 변경 내용 |
|---|------|-----------|
| 1 | `domain/entities/user_qr_template.dart` | 5필드 추가 (customDotParams~minEngineVersion) |
| 2 | `data/models/user_qr_template_model.dart` | HiveField 38~42 추가, toEntity/fromEntity 매핑 |
| 3 | `data/models/user_qr_template_model.g.dart` | `build_runner` 재생성 |
| 4 | `notifier/template_setters.dart` | `applyUserTemplate()` 에 3필드 복원 로직 추가 |
| 5 | `qr_result_screen.dart` | 템플릿 저장 시 3필드 + 버전 정보 포함 |
| 6 | `domain/entities/template_engine_version.dart` | (신규) `kTemplateEngineVersion` 상수 + 호환성 체크 유틸 |
| 7 | `tabs/my_templates_tab.dart` | 비호환 템플릿 UI 표시 (minEngineVersion > 현재) |

---

## 5. 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| v1 템플릿 로드 (새 필드 null) | null → 기본값 fallback, 정상 적용 |
| 미래 v3 템플릿을 현재 v2 엔진에서 로드 | `minEngineVersion > kTemplateEngineVersion` → 적용 차단 + "앱 업데이트 필요" 안내 |
| customDotParams의 fromJson 실패 | try-catch → null fallback (enum dotStyle로 렌더링) |
| 매우 큰 JSON (극단적 파라미터) | DotShapeParams/EyeShapeParams JSON은 ~200 bytes, 무시 가능 |

---

## 6. 구현 순서

1. `template_engine_version.dart` 상수 정의
2. `user_qr_template.dart` entity 5필드 추가
3. `user_qr_template_model.dart` HiveField 38~42 + 매핑
4. `build_runner` 실행 → `.g.dart` 재생성
5. `qr_result_screen.dart` 저장 로직 수정
6. `template_setters.dart` 적용 로직 수정
7. `my_templates_tab.dart` 비호환 UI 처리
8. 기존 템플릿 저장 → 로드 → 적용 검증

---

## 7. 기술 결정

### 7.1 Project Level
Flutter Dynamic × Clean Architecture × R-series

### 7.2 Key Architectural Decisions
- Framework: Flutter
- State Management: Riverpod StateNotifier
- 로컬 저장: Hive
- 라우팅: go_router
- 직렬화: 기존 패턴 (JSON String → Hive field) 재사용
