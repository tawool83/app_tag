# Gap Analysis — qr-favorite-sort

> 분석일: 2026-04-23
> Design: `docs/02-design/features/qr-favorite-sort.design.md`
> Match Rate: **100%**

---

## Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 100% | OK |
| Architecture Compliance | 100% | OK |
| Convention Compliance | 100% | OK |
| **Overall** | **100%** | OK |

---

## 8개 구현 항목 검증

| # | Item | Design | 구현 | 결과 |
|:-:|------|--------|------|:----:|
| 1 | Repository interface: +toggleFavorite | `Future<Result<void>> toggleFavorite(String id)` | `qr_task_repository.dart:42` | PASS |
| 2 | Repository impl: toggleFavorite | `copyWith(isFavorite: !entity.isFavorite)`, updatedAt 미갱신 | `qr_task_repository_impl.dart:167-180` | PASS |
| 3 | Repository impl: 정렬 변경 | `_favoriteFirstSort`: isFavorite desc → updatedAt desc | `listAll:66`, `listHomeVisible:141`, `_favoriteFirstSort:183-186` | PASS |
| 4 | ToggleFavoriteUseCase | `call(id) → repository.toggleFavorite(id)` | `toggle_favorite_usecase.dart` (신규 10줄) | PASS |
| 5 | Provider 등록 | `toggleFavoriteUseCaseProvider` | `qr_task_providers.dart:62-64` | PASS |
| 6 | 갤러리 타일 별 배지 | `Positioned(top:4, left:4)` + `Icons.star, size:16, amber` + 흰 원형 배경 | `qr_task_gallery_card.dart:52-65` | PASS |
| 7 | 액션시트 별 토글 | `StatefulBuilder` + `Positioned(top:16, right:32)` + `Icons.star/star_border` + `onChanged()` | `qr_task_action_sheet.dart:34-91` | PASS |
| 8 | 전체선택 즐겨찾기 제외 | `_tasks.where((t) => !t.isFavorite)` | `home_screen.dart:107-108` | PASS |

---

## Design 요구사항 세부 검증

### FR-01. 즐겨찾기 토글 (액션시트)

| 항목 | Design | 구현 | 결과 |
|------|--------|------|:----:|
| 별 위치 | 미리보기 우측 상단 | `Positioned(top:16, right:32)` | PASS |
| 비활성 아이콘 | `Icons.star_border`, 회색 | `Icons.star_border, color: Colors.grey` | PASS |
| 활성 아이콘 | `Icons.star`, amber | `Icons.star, color: Colors.amber` | PASS |
| 토글 후 즉시 반영 | `StatefulBuilder` local state | `setStarState(() => isFav = !isFav)` | PASS |
| 시트 닫지 않음 | 별 토글 시 시트 유지 | `Navigator.pop` 미호출 | PASS |
| onChanged 호출 | 홈 갤러리 리로드 | `onChanged()` 호출됨 | PASS |
| 흰 원형 배경 | `BoxShape.circle, alpha 0.9` | `Container(padding:6, BoxShape.circle, alpha:0.9)` | PASS |
| 아이콘 크기 | size: 24 | `size: 24` | PASS |

### FR-02. 갤러리 타일 별 배지

| 항목 | Design | 구현 | 결과 |
|------|--------|------|:----:|
| 위치 | 좌측 상단 `Positioned(top:4, left:4)` | 동일 | PASS |
| 아이콘 | `Icons.star, size:16, amber` | 동일 | PASS |
| 배경 | 흰 원형, alpha 0.9 | `Container(padding:2, BoxShape.circle, alpha:0.9)` | PASS |
| 조건 | `task.isFavorite` | `if (task.isFavorite)` | PASS |
| 삭제 체크와 독립 | 좌측(별) / 우측(체크) | `left:4` / `right:4` | PASS |

### FR-03. 정렬 규칙

| 항목 | Design | 구현 | 결과 |
|------|--------|------|:----:|
| 1차 정렬 | isFavorite desc | `a.isFavorite ? -1 : 1` | PASS |
| 2차 정렬 | updatedAt desc | `b.updatedAt.compareTo(a.updatedAt)` | PASS |
| listHomeVisible 적용 | 적용 | `..sort(_favoriteFirstSort)` | PASS |
| listAll 적용 | 적용 | `..sort(_favoriteFirstSort)` | PASS |

### FR-04. ToggleFavorite — updatedAt 미갱신

| 항목 | Design | 구현 | 결과 |
|------|--------|------|:----:|
| isFavorite 반전 | `copyWith(isFavorite: !entity.isFavorite)` | 동일 | PASS |
| updatedAt 미갱신 | copyWith에 updatedAt 미전달 | `copyWith(isFavorite: ...)` 만 호출 | PASS |

### FR-05. 전체선택 즐겨찾기 제외

| 항목 | Design | 구현 | 결과 |
|------|--------|------|:----:|
| 필터 | `_tasks.where((t) => !t.isFavorite)` | 동일 | PASS |

---

## 파일 크기

| 파일 | 실제 | 제한 | 상태 |
|------|-----:|:----:|:----:|
| `qr_task_action_sheet.dart` | 249 | 400 | OK |
| `qr_task_gallery_card.dart` | 108 | 400 | OK |
| `home_screen.dart` | 433 | 400 | WARN (기존) |
| `qr_task_repository_impl.dart` | 207 | 400 | OK |
| `qr_task_providers.dart` | 85 | 200 | OK |
| `toggle_favorite_usecase.dart` | 9 | 150 | OK |

---

## 발견된 차이

없음. Design 문서의 모든 요구사항이 정확히 구현됨.

---

## l10n 키

| 키 | 추가됨 | 사용처 |
|----|:------:|--------|
| `tooltipFavorite` | Yes | `app_ko.arb` |
| `tooltipUnfavorite` | Yes | `app_ko.arb` |

Note: 현재 l10n 키는 추가되었으나 액션시트에서 직접 참조하지는 않음 (아이콘만 사용). 향후 tooltip/semanticLabel 추가 시 사용 가능.

---

_Match Rate 100% 기준 충족. `/pdca report qr-favorite-sort` 실행 가능._
