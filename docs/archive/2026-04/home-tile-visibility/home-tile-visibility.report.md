# Completion Report: home-tile-visibility

> 작성일: 2026-04-12
> Plan: `docs/01-plan/features/home-tile-visibility.plan.md`
> Design: `docs/02-design/features/home-tile-visibility.design.md`
> Analysis: `docs/03-analysis/home-tile-visibility.analysis.md`

---

## Executive Summary

### 1.1 프로젝트 개요

| 항목 | 내용 |
|------|------|
| Feature | home-tile-visibility |
| 시작일 | 2026-04-11 |
| 완료일 | 2026-04-12 |
| 소요 기간 | 2일 |
| 변경 파일 | 2개 |
| 신규 파일 | 없음 |

### 1.2 결과 지표

| 지표 | 값 |
|------|-----|
| Match Rate | **99%** |
| 수용 기준 통과 | 9 / 9 |
| Iteration 횟수 | 0 (첫 구현에 통과) |
| Blocker | 없음 |
| Info Gap | 5건 (브랜딩/명명 — 기능 범위 외) |

### 1.3 Value Delivered

| 관점 | 내용 |
|------|------|
| **Problem** | 홈 화면 9개 타일 중 사용하지 않는 메뉴가 항상 노출되어 화면이 복잡하고 원하는 기능 접근이 느렸다. |
| **Solution** | 길게 누르면 편집 모드 진입 → 각 타일 X 버튼으로 숨기기 → "더보기" 버튼으로 복원. SharedPreferences로 영속 저장. |
| **Function UX Effect** | 자주 쓰는 타일만 보이는 커스텀 홈 화면 제공 — 최소 1개부터 9개까지 사용자가 직접 선택. 마지막 타일은 실수 방지 보호. |
| **Core Value** | 앱을 개인 워크플로에 맞게 조정할 수 있어 재사용률과 만족도 향상. 앱 재시작 후에도 설정 유지. |

---

## 2. 구현 내역

### 2.1 파일 변경 명세

| 파일 | 변경 유형 | 주요 내용 |
|------|---------|---------|
| `lib/features/home/home_screen.dart` | 대폭 수정 | `StatelessWidget` → `StatefulWidget`, 편집 모드, X 배지, 더보기 섹션 |
| `lib/services/settings_service.dart` | 수정 | `getHiddenTileKeys()`, `saveHiddenTileKeys()` 추가 |

### 2.2 주요 구현 포인트

**HomeScreen (StatefulWidget)**
- 4개 state 필드: `_editMode`, `_hiddenKeys`, `_showHiddenSection`, `_initialized`
- `initState` → `SharedPreferences`에서 숨김 목록 로드 (`_initialized` flag로 로딩 스피너 처리)
- 타일 길게 누름 → `_enterEditMode()` → X 배지 + AppBar "완료" 버튼 표시
- 편집 모드 중 타일 `onTap` 비활성화 (`editMode ? null : item.onTap`)
- X 탭 → `_hideTile()` → 마지막 1개 보호(회색 배지) → SharedPreferences 저장
- "더보기" 섹션: `Opacity(0.5)` + 탭으로 복원

**SettingsService**
- `hidden_tile_keys` 키에 comma-separated string 저장/로드
- 빈 값 → 빈 Set 반환 (모든 타일 표시)

**레이아웃 버그 수정 (추가 발견)**
- `Stack(fit: StackFit.expand)` 명시 — GridView tight constraint 전달 보장
- 미설정 시 타일 카드가 콘텐츠 크기로 축소되는 문제 수정

### 2.3 설계 대비 변경 사항 (Info)

| 항목 | 사유 | 영향 |
|------|------|------|
| AppBar 타이틀 `'QR, NFC 생성기'` | 브랜딩 개선 요청 | 기능 외, UX 향상 |
| AppBar leading 듀얼 아이콘 (QR+NFC) | 브랜딩 개선 요청 | 기능 외, 시각적 개선 |
| iOS `app` 타일 `CupertinoIcons` | 플랫폼 일관성 | 기능 외, 플랫폼 적합성 |
| `StackFit.expand` 추가 | GridView 레이아웃 버그 수정 | 버그 fix |

---

## 3. Gap Analysis 요약

| 항목 | 값 |
|------|-----|
| Match Rate | 99% |
| Pass | 9 / 9 AC |
| Info Gap | 5건 (기능 범위 외) |
| Critical/Major Gap | 없음 |

---

## 4. 수용 기준 최종 체크리스트

- [x] `_initialized = false`일 때 로딩 스피너 표시
- [x] 길게 누르면 편집 모드 진입 (X 배지 + "완료" 버튼 표시)
- [x] 편집 모드에서 타일 onTap 비활성화
- [x] X 탭 → 타일 그리드에서 제거, SharedPreferences 저장
- [x] 타일 1개 남을 때 X 배지 회색 + 탭 무반응
- [x] "완료" → 편집 모드 종료, 더보기 버튼 표시
- [x] "더보기" 탭 → 숨긴 타일 그리드 펼침 (opacity 0.5)
- [x] 숨긴 타일 탭 → 복원, SharedPreferences 저장
- [x] 앱 재시작 후 숨김 상태 유지

---

## 5. 학습 및 특이사항

1. **StackFit 트랩**: `GridView.count` 내부 `Stack` 사용 시 `StackFit.loose`(기본값)가 tight constraint를 느슨하게 만들어 Card가 콘텐츠 높이로 축소됨. `StackFit.expand`로 해결.
2. **SharedPreferences CSV 패턴**: `Set<String>`을 comma-separated string으로 직렬화하는 간단하고 의존성 없는 방식. 타일 수가 적어 성능 문제 없음.
3. **StatefulWidget 전환 최소화**: 4개 로컬 상태만 있어 Riverpod 불필요. 화면 단위 StatefulWidget이 적절.
