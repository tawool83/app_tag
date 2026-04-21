---
template: plan
version: 1.2
feature: color-tab-redesign
date: 2026-04-17
author: tawool83
project: app_tag
---

# color-tab-redesign Planning Document

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | QR 색상 탭이 단색/그라디언트 서브탭으로 분리되어 전환이 번거롭고, 그라디언트는 프리셋만 제공되어 커스텀 불가. |
| **Solution** | 서브탭 제거 → 단일 스크롤 뷰로 통합. 단색 팔레트 + 그라디언트 프리셋을 연속 배치, 각 끝에 "직접 선택" 버튼. 그라디언트 직접 선택 시 Google Slides 스타일 맞춤 편집기 (유형/각도/색 지점 추가삭제/드래그 슬라이더) 전체 표시. |
| **Function/UX** | 한 화면에서 단색↔그라디언트 모두 접근. 맞춤 그라디언트로 무한한 색상 조합 가능. |
| **Core Value** | QR 꾸미기의 색상 자유도를 프리셋 제한에서 완전 자유 편집으로 격상. |

---

## 1. 현재 구조 (변경 전)

```
색상 탭
├── TabBar: [단색] [그라디언트]
├── 단색 화면
│   ├── "추천 색상" 라벨
│   ├── 10색 팔레트 (원형 버튼 Wrap)
│   └── "직접 선택" 버튼 → HSV 컬러 휠 다이얼로그
└── 그라디언트 화면
    ├── "그라디언트 프리셋" 라벨
    └── 8개 프리셋 (사각 버튼 Wrap)
```

## 2. 변경 후 구조

```
색상 탭 (단일 스크롤 뷰)
├── ─── 단색 ─────────────────────────────
│   ├── 10색 팔레트 (원형 버튼 Wrap)
│   └── [+ 직접 선택] 버튼 (마지막 위치, HSV 컬러 휠)
│
├── ─── 그라디언트 ───────────────────────
│   ├── 8개 프리셋 (사각 버튼 Wrap)
│   └── [+ 직접 선택] 버튼 → 맞춤 그라디언트 편집기
│
└── ─── 맞춤 그라디언트 편집기 ────────── (직접 선택 시 표시)
    │   ※ 편집기 진입 시 단색/그라디언트 팔레트 숨김
    │   ※ 하단 액션 버튼(갤러리저장 등) → 확인/취소 버튼으로 교체
    ├── [유형 ▾] [각도 ▾ 또는 가운데 ▾]  (드롭다운 한 행)
    ├── 색 지점 목록
    │   ├── 지점 1: [●색상] [삭제]
    │   ├── 지점 2: [●색상] [삭제]
    │   └── [+ 추가] 버튼
    └── 그라디언트 미리보기 + 드래그 슬라이더 (통합 컴포넌트)
        └── [██●██████████████●██] 바 위에 핸들 직접 배치
```

## 3. 맞춤 그라디언트 편집기 상세

### 3.1 유형 + 옵션 드롭다운 (한 행)
- `DropdownButtonFormField` 으로 한 행에 배치
- 왼쪽: 유형 (선형/방사형)
- 오른쪽: 선형 → 각도 드롭다운 (0~315, 기본 45) / 방사형 → 가운데 드롭다운 (5개, 기본 중앙)

### 3.2 편집기 모드 격리
- 편집기 진입 시 단색/그라디언트 기본 팔레트 숨김
- 하단 갤러리저장/템플릿저장/공유 버튼 → 확인/취소 버튼으로 교체
- `onEditorModeChanged` 콜백으로 부모(QrResultScreen)에 알림
- 취소 시 편집 전 그라디언트로 복원 (`_gradientBeforeEdit` 백업)

### 3.3 탭 전환 자동 확인
- 편집기가 열린 상태에서 다른 탭(템플릿/모양/로고/텍스트)으로 이동 시 자동 확인 처리
- `TabController.addListener` + `GlobalKey<QrColorTabState>` 패턴
- 부모에서 `confirmAndCloseEditor()` 호출

### 3.4 색 지점 관리
- 기본 2개 지점 (시작색 + 끝색)
- [+ 추가] 버튼으로 중간 지점 추가 (최대 5개)
- 각 지점: 색상 원형 버튼(탭 → HSV 피커) + 삭제 버튼
- 최소 2개 보호 (삭제 버튼 비활성)

### 3.5 그라디언트 미리보기 + 드래그 슬라이더 (통합)
- 그라디언트 바 위에 핸들이 직접 배치된 단일 컴포넌트 (`_GradientSliderBar`)
- 핸들은 바 하단 경계에 위치, 흰색 배경 + 색상 원 + 테두리
- 드래그 시 핸들 확대 + 파란 테두리 활성화
- 첫/마지막 핸들 고정, 중간 핸들만 이웃 사이에서 드래그 가능
- 실시간 미리보기 갱신

## 4. 변경 파일

| 파일 | 변경 |
|------|------|
| `lib/features/qr_result/tabs/qr_color_tab.dart` | 전면 재작성 (편집기 모드 격리, 통합 슬라이더 등) |
| `lib/features/qr_result/qr_result_screen.dart` | 편집기 모드 상태 관리, 탭 전환 자동 확인, GlobalKey 연동 |
| `lib/features/qr_result/domain/entities/qr_template.dart` | QrGradient에 `center` 필드 추가 |
| `lib/features/qr_task/domain/entities/qr_gradient_data.dart` | QrGradientData에 `center` 필드 추가 |
| `lib/features/qr_result/utils/customization_mapper.dart` | center 필드 양방향 매핑 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | 방사형 center 정렬 + 비중앙 radius 1.4 보정 |
| `lib/features/qr_result/data/datasources/local_default_template_datasource.dart` | center JSON 직렬화 |
| `lib/l10n/app_*.arb` (10개) | 14개 새 키 추가 + 기존 2개 재사용 |

## 5. 새 ARB 키

| 키 | 한국어 | 용도 |
|---|--------|------|
| `tabColorSolid` | 단색 | 섹션 헤더 (기존 키 재사용) |
| `tabColorGradient` | 그라디언트 | 섹션 헤더 (기존 키 재사용) |
| `labelCustomGradient` | 맞춤 그라디언트 | 편집기 헤더 |
| `labelCenter` | 가운데 | 가운데 선택 라벨 |
| `optionCenterCenter` | 중앙 | 가운데 옵션 |
| `optionCenterTopLeft` | 왼쪽 상단 | 가운데 옵션 |
| `optionCenterTopRight` | 오른쪽 상단 | 가운데 옵션 |
| `optionCenterBottomLeft` | 왼쪽 하단 | 가운데 옵션 |
| `optionCenterBottomRight` | 오른쪽 하단 | 가운데 옵션 |
| `labelGradientType` | 유형 | 유형 선택 라벨 |
| `optionLinear` | 선형 | 유형 옵션 |
| `optionRadial` | 방사형 | 유형 옵션 |
| `labelAngle` | 각도 | 각도 선택 라벨 |
| `labelColorStops` | 색 지점 | 지점 목록 라벨 |
| `actionAddStop` | 추가 | 지점 추가 버튼 |
| `actionDeleteStop` | 삭제 | 지점 삭제 버튼 |
