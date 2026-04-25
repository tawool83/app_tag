# Plan — QR Favorite & Sort (즐겨찾기 + 정렬)

> 생성일: 2026-04-23
> Feature ID: `qr-favorite-sort`
> 대상: Flutter 모바일 앱 (pre-release)
> 관련 기존 feature: `qr_task`, `home` (main-screen-redesign 완료 기반)

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 홈 갤러리의 QR 목록이 updatedAt desc 단일 정렬만 지원. 자주 사용하는 QR을 빠르게 찾을 수 없고, `isFavorite` 필드가 이미 존재하나 UI에 노출되지 않음. |
| **Solution** | 액션시트 미리보기 우측 상단에 별 아이콘 토글 추가. 갤러리 타일 좌측 상단에 노란색 별 배지 표시. 목록 정렬을 favorite 우선 + updatedAt desc 2단계로 변경. 삭제 모드 "전체선택" 시 즐겨찾기 자동 제외. |
| **Function UX Effect** | 별 아이콘 탭 한 번으로 즐겨찾기 등록/해제. 홈 갤러리에서 즐겨찾기 QR이 항상 최상단에 노출되며 노란 별 배지로 시각 구분. |
| **Core Value** | 자주 사용하는 QR에 1-tap 접근 보장 + 기존 미사용 `isFavorite` 필드 활용으로 스키마 변경 없이 구현. |

---

## 1. Project Level & Key Architectural Decisions

> CLAUDE.md 고정 규약: 아래 항목은 선택지 없이 자동 적용.

| Item | Value |
|------|-------|
| **Project Level** | Flutter Dynamic × Clean Architecture × R-series |
| **Framework** | Flutter |
| **State Management** | Riverpod `StateNotifier` + `part of` mixin setters |
| **Local Storage** | Hive (기존 `qr_tasks` box) |
| **Navigation** | `go_router` |
| **l10n 정책** | `app_ko.arb` 에 선반영 |

---

## 2. Scope

### In-Scope

1. **액션시트 즐겨찾기 토글** (`qr_task_action_sheet.dart`)
   - 미리보기 영역 우측 상단에 `Icons.star` / `Icons.star_border` 토글 아이콘 배치
   - 탭 시 `isFavorite` 토글 → Hive 저장 → `onChanged()` 호출로 홈 갤러리 리로드

2. **갤러리 타일 별 배지** (`qr_task_gallery_card.dart`)
   - `isFavorite == true` 일 때 좌측 상단에 노란색 별 아이콘(Icons.star, Colors.amber) 배지 표시
   - 삭제 모드 체크마크(우측 상단)와 공존 가능

3. **정렬 로직 변경** (`qr_task_repository_impl.dart`)
   - `listHomeVisible()` 정렬 기준: **① isFavorite desc → ② updatedAt desc** (favorite이 항상 상단)
   - `listAll()` 도 동일하게 2단계 정렬 적용

4. **ToggleFavoriteUseCase** 신규
   - `QrTaskRepository.toggleFavorite(String id)` 메서드 추가
   - UseCase + Provider 등록

### Out-of-Scope

- 즐겨찾기 전용 필터/탭 UI
- 즐겨찾기 개수 제한
- 즐겨찾기 섹션 구분선 (별도 헤더)
- 꾸미기 화면 내 즐겨찾기 토글

---

## 3. 현재 구조 분석

### 3.1 이미 존재하는 것

- `QrTask.isFavorite: bool` — 엔티티에 필드 존재, `toPayloadMap`/`fromPayloadMap`에서 직렬화/역직렬화 지원
- `QrTask.copyWith(isFavorite: bool?)` — 지원
- `QrCustomization` 스키마 v2 — 변경 불필요

### 3.2 없는 것 (구현 필요)

- `QrTaskRepository.toggleFavorite(String id)` — 메서드 미존재
- `ToggleFavoriteUseCase` — UseCase 미존재
- Provider — 미등록
- 정렬 로직 — `listHomeVisible()`/`listAll()` 에서 `isFavorite` 미고려
- UI — 액션시트 별 아이콘 없음, 갤러리 타일 별 배지 없음

---

## 4. Functional Requirements

### FR-01. 즐겨찾기 토글 (액션시트)

- 미리보기 컨테이너(220×220) 우측 상단에 `Positioned` 별 아이콘 배치
- `isFavorite == false`: `Icons.star_border`, 회색
- `isFavorite == true`: `Icons.star`, `Colors.amber`
- 탭 → `toggleFavoriteUseCaseProvider(task.id)` → `onChanged()` (갤러리 리로드)
- 액션시트는 닫지 않음 (별 토글은 시트 내에서 즉시 반영, 미리보기 옆 아이콘만 변경)

### FR-02. 갤러리 타일 별 배지

- `isFavorite == true` 일 때 썸네일 좌측 상단에 노란 별 아이콘 배치
- `Positioned(top: 4, left: 4)` — `Icon(Icons.star, size: 18, color: Colors.amber)`
- 삭제 모드 체크마크(우측 상단)와 독립 표시

### FR-03. 정렬 규칙

- **1차**: `isFavorite` desc (true 먼저)
- **2차**: `updatedAt` desc (최근 수정 먼저)
- 적용 대상: `listHomeVisible()`, `listAll()`

### FR-04. ToggleFavorite UseCase

- `QrTaskRepository` 에 `toggleFavorite(String id)` 추가
- 구현: `getById → copyWith(isFavorite: !current, updatedAt: now) → put`
- **주의**: 즐겨찾기 토글 시 `updatedAt` 갱신하지 않음 — 정렬 순서가 의도치 않게 변경되는 것 방지
  - 즉, `copyWith(isFavorite: !current)` 만 변경. `updatedAt` 는 유지.

### FR-05. 삭제 모드 "전체선택" 시 즐겨찾기 제외

- `_selectAll()` 에서 `isFavorite == true` 인 항목은 선택 대상에서 제외
- 변경: `_selectedIds.addAll(_tasks.where((t) => !t.isFavorite).map((t) => t.id))`
- 즐겨찾기 QR은 개별 탭으로만 선택/삭제 가능 (실수 삭제 방지)
- 전체선택 후에도 즐겨찾기 타일은 미선택 상태로 유지

---

## 5. Non-Functional Requirements

- **성능**: 정렬 비교 함수 O(n log n) — 현재 규모(~200건)에서 무시 가능
- **데이터 안정성**: `isFavorite` 필드는 이미 Hive 직렬화에 포함. 스키마 변경 없음.

---

## 6. 요구사항 → 영향 파일 매핑

| # | 작업 | 파일 | 변경 유형 |
|---|------|------|-----------|
| 1 | Repository: toggleFavorite 메서드 | `qr_task_repository.dart` | 수정 (인터페이스 +1 메서드) |
| 2 | Repository impl: toggleFavorite | `qr_task_repository_impl.dart` | 수정 (+1 메서드) |
| 3 | Repository impl: 정렬 변경 | `qr_task_repository_impl.dart` | 수정 (listHomeVisible, listAll 정렬 변경) |
| 4 | ToggleFavoriteUseCase | `toggle_favorite_usecase.dart` | 신규 |
| 5 | Provider 등록 | `qr_task_providers.dart` | 수정 (+1 provider) |
| 6 | 액션시트 별 토글 | `qr_task_action_sheet.dart` | 수정 (미리보기 Stack + 별 아이콘) |
| 7 | 갤러리 타일 별 배지 | `qr_task_gallery_card.dart` | 수정 (Stack + 별 배지) |
| 8 | 삭제 모드 전체선택 시 즐겨찾기 제외 | `home_screen.dart` | 수정 (`_selectAll` 필터) |
| 9 | l10n | `app_ko.arb` | 수정 (+1~2 키) |

---

## 7. Risks & Mitigations

| Risk | 영향 | Mitigation |
|------|------|-----------|
| 즐겨찾기 토글 시 updatedAt 갱신하면 정렬 꼬임 | 별만 눌러도 목록 순서 변경 | **updatedAt 미갱신** — isFavorite만 변경 |
| 액션시트가 ConsumerWidget이라 별 토글 시 즉시 반영 어려움 | 아이콘 상태 안 바뀜 | StatefulBuilder 또는 ConsumerStatefulWidget 부분 사용 |

---

## 8. Decisions Confirmed

| Decision | 확정값 | 근거 |
|----------|--------|------|
| 별 아이콘 위치 (액션시트) | 미리보기 우측 상단 | 사용자 요구사항 |
| 별 배지 위치 (갤러리 타일) | 좌측 상단 | 사용자 요구사항 — 삭제 체크(우측)와 분리 |
| 정렬 규칙 | favorite desc → updatedAt desc | 사용자 요구사항 |
| 즐겨찾기 토글 시 updatedAt | 미갱신 | 의도치 않은 정렬 변경 방지 |
| 스키마 변경 | 없음 | isFavorite 이미 존재 |
| 전체선택 시 즐겨찾기 | 제외 | 실수 삭제 방지 — 개별 선택으로만 삭제 가능 |

---

## 9. Approval Checklist

- [x] 요구사항 이해 합의
- [x] isFavorite 필드 기존 존재 확인
- [x] 정렬 규칙 확정 (favorite → updatedAt)
- [x] 별 아이콘/배지 위치 확정
- [x] updatedAt 미갱신 결정

---

_이 Plan 은 CLAUDE.md 고정 규약(R-series Provider 패턴 + Clean Architecture + l10n ko 선반영)을 기반으로 작성되었습니다._
