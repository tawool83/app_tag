# Design — QR Favorite & Sort (즐겨찾기 + 정렬)

> 생성일: 2026-04-23
> Feature ID: `qr-favorite-sort`
> Plan 문서: `docs/01-plan/features/qr-favorite-sort.plan.md`
> Architecture: Flutter Dynamic x Clean Architecture x R-series Provider

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 홈 갤러리가 updatedAt desc 단일 정렬. 자주 사용하는 QR을 빠르게 찾을 수 없음. `isFavorite` 필드가 존재하나 UI 미노출. |
| **Solution** | 액션시트 미리보기 우측 상단 별 토글 + 갤러리 타일 좌측 상단 노란 별 배지 + favorite 우선 2단계 정렬 + 전체선택 시 즐겨찾기 제외. |
| **Function UX Effect** | 별 1-tap 즐겨찾기. 홈에서 즐겨찾기 QR 항상 최상단 + 노란 별 배지. 전체선택 삭제에서도 즐겨찾기 보호. |
| **Core Value** | 자주 사용하는 QR에 1-tap 접근 + 실수 삭제 방지 + 스키마 변경 없이 구현. |

---

## 1. Architecture

### 1.1 영향 범위 요약

```
수정 대상:
├─ lib/features/qr_task/domain/repositories/qr_task_repository.dart    # +toggleFavorite
├─ lib/features/qr_task/data/repositories/qr_task_repository_impl.dart # +toggleFavorite, 정렬 변경
├─ lib/features/qr_task/presentation/providers/qr_task_providers.dart  # +1 provider
├─ lib/features/home/widgets/qr_task_action_sheet.dart                 # 별 토글 UI
├─ lib/features/home/widgets/qr_task_gallery_card.dart                 # 별 배지
├─ lib/features/home/home_screen.dart                                  # _selectAll 필터
└─ lib/l10n/app_ko.arb                                                # +2 키

신규:
└─ lib/features/qr_task/domain/usecases/toggle_favorite_usecase.dart   # UseCase
```

### 1.2 데이터 모델 — 변경 없음

`QrTask` 엔티티는 이미 `isFavorite: bool` 필드를 가지고 있으며, `toPayloadMap()`/`fromPayloadMap()`/`copyWith()` 모두 지원. 스키마 버전 유지 (`currentSchemaVersion = 2`).

```dart
// 기존 — 변경 없음
class QrTask {
  final bool isFavorite;  // 이미 존재, 기본값 false
  // ...
  QrTask copyWith({ bool? isFavorite, ... })  // 이미 지원
}
```

---

## 2. 상세 설계

### 2.1 QrTaskRepository 확장

```dart
// lib/features/qr_task/domain/repositories/qr_task_repository.dart — 추가
/// 즐겨찾기 토글 (isFavorite 반전). updatedAt 미갱신.
Future<Result<void>> toggleFavorite(String id);
```

### 2.2 QrTaskRepositoryImpl — toggleFavorite + 정렬 변경

```dart
// lib/features/qr_task/data/repositories/qr_task_repository_impl.dart

@override
Future<Result<void>> toggleFavorite(String id) async {
  try {
    final existing = _local.readById(id);
    if (existing == null) {
      return Err(StorageFailure('QrTask 미존재: $id'));
    }
    final entity = existing.toEntity();
    final updated = entity.copyWith(isFavorite: !entity.isFavorite);
    await _local.put(QrTaskModel.fromEntity(updated));
    return const Success(null);
  } catch (e) {
    return Err(StorageFailure('QrTask 즐겨찾기 토글 실패: $e'));
  }
}
```

**정렬 함수 변경** — `listHomeVisible()`, `listAll()` 공통:

```dart
// 기존: ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
// 변경:
..sort((a, b) {
  // 1차: isFavorite desc (true 먼저)
  if (a.isFavorite != b.isFavorite) {
    return a.isFavorite ? -1 : 1;
  }
  // 2차: updatedAt desc
  return b.updatedAt.compareTo(a.updatedAt);
});
```

**핵심**: `toggleFavorite`에서 `updatedAt`를 갱신하지 않음. `copyWith(isFavorite: !entity.isFavorite)` 만 호출하여 2차 정렬(updatedAt) 순서가 유지됨.

### 2.3 ToggleFavoriteUseCase

```dart
// lib/features/qr_task/domain/usecases/toggle_favorite_usecase.dart
import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class ToggleFavoriteUseCase {
  final QrTaskRepository _repository;
  const ToggleFavoriteUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.toggleFavorite(id);
}
```

### 2.4 Provider 등록

```dart
// lib/features/qr_task/presentation/providers/qr_task_providers.dart — 추가
import '../../domain/usecases/toggle_favorite_usecase.dart';

final toggleFavoriteUseCaseProvider = Provider<ToggleFavoriteUseCase>(
  (ref) => ToggleFavoriteUseCase(ref.watch(qrTaskRepositoryProvider)),
);
```

### 2.5 액션시트 별 토글 (`qr_task_action_sheet.dart`)

현재 `QrTaskActionSheet`는 `ConsumerWidget`이고 `task`를 final로 받으므로, 별 토글 후 아이콘 즉시 반영을 위해 **`StatefulBuilder`** 를 미리보기 영역에 적용.

```dart
// 미리보기 영역을 Stack으로 감싸고 별 아이콘 추가
// 변경 위치: Builder(builder: (context) { ... }) 블록 내부

StatefulBuilder(
  builder: (context, setStarState) {
    var isFav = task.isFavorite;
    return Stack(
      children: [
        // 기존 Padding > Center > Container(220×220) 미리보기
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
          child: Center(
            child: Container(
              width: 220, height: 220,
              // ... 기존 미리보기 코드 유지 ...
            ),
          ),
        ),
        // 별 아이콘 — 미리보기 우측 상단
        Positioned(
          top: 16,
          right: 32,
          child: GestureDetector(
            onTap: () async {
              await ref.read(toggleFavoriteUseCaseProvider)(task.id);
              setStarState(() => isFav = !isFav);
              onChanged();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? Colors.amber : Colors.grey,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  },
),
```

**설계 포인트**:
- `StatefulBuilder`로 별 아이콘만 local state로 즉시 반영 (시트 전체 rebuild 불필요)
- `onChanged()` 호출로 홈 갤러리도 리로드 (정렬 순서 반영)
- 시트는 닫지 않음 — 사용자가 다른 액션(공유/편집 등)을 계속 사용 가능
- 별 아이콘에 흰 원형 배경(`BoxShape.circle`, alpha 0.9) → 썸네일 위에서도 잘 보임

### 2.6 갤러리 타일 별 배지 (`qr_task_gallery_card.dart`)

기존 Stack에 `Positioned` 추가:

```dart
// Stack children 내, 기존 selectable 체크마크 이후에 추가:
if (task.isFavorite)
  Positioned(
    top: 4,
    left: 4,
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.star, size: 16, color: Colors.amber),
    ),
  ),
```

**설계 포인트**:
- 좌측 상단 배치 — 삭제 모드 체크마크(우측 상단)와 겹치지 않음
- 흰 원형 배경으로 썸네일 위에서도 가시성 확보
- `selectable` 체크마크와 독립 — 삭제 모드에서도 별 배지는 항상 표시

### 2.7 삭제 모드 전체선택 (`home_screen.dart`)

```dart
// 기존:
void _selectAll() {
  setState(() {
    _selectedIds.addAll(_tasks.map((t) => t.id));
  });
}

// 변경:
void _selectAll() {
  setState(() {
    _selectedIds.addAll(
      _tasks.where((t) => !t.isFavorite).map((t) => t.id),
    );
  });
}
```

**설계 포인트**:
- `isFavorite == true` 항목은 전체선택에서 제외 → 실수 삭제 방지
- 개별 탭으로 즐겨찾기 항목을 수동 선택하면 삭제 가능 (완전 차단은 아님)

### 2.8 l10n 키 (`app_ko.arb`)

```json
"tooltipFavorite": "즐겨찾기",
"tooltipUnfavorite": "즐겨찾기 해제"
```

---

## 3. Implementation Order

| 순서 | 작업 | 파일 | 의존 |
|:----:|------|------|------|
| 1 | Repository interface: +toggleFavorite | `qr_task_repository.dart` | — |
| 2 | Repository impl: +toggleFavorite + 정렬 변경 | `qr_task_repository_impl.dart` | #1 |
| 3 | ToggleFavoriteUseCase | `toggle_favorite_usecase.dart` (신규) | #1 |
| 4 | Provider 등록 | `qr_task_providers.dart` | #3 |
| 5 | 갤러리 타일 별 배지 | `qr_task_gallery_card.dart` | — |
| 6 | 액션시트 별 토글 | `qr_task_action_sheet.dart` | #4 |
| 7 | 전체선택 즐겨찾기 제외 | `home_screen.dart` | — |
| 8 | l10n 키 추가 | `app_ko.arb` | — |

---

## 4. File Size Compliance

| 파일 | 현재 줄 수 | 변경 후 예상 | 제한 |
|------|--------:|--------:|:----:|
| `qr_task_action_sheet.dart` | 222 | ~250 | 400 |
| `qr_task_gallery_card.dart` | 94 | ~110 | 400 |
| `home_screen.dart` | 433 | ~433 | 400 (WARN — 기존) |
| `qr_task_repository_impl.dart` | 185 | ~200 | 400 |
| `qr_task_providers.dart` | 81 | ~87 | 200 |
| `toggle_favorite_usecase.dart` | — | ~12 | 150 |

---

## 5. Edge Cases

| 상황 | 처리 |
|------|------|
| 기존 QrTask의 isFavorite 없음 | `fromPayloadMap`에서 `false` 폴백 (이미 구현됨) |
| 즐겨찾기 토글 후 시트 내 아이콘 | `StatefulBuilder` local state로 즉시 반영 |
| 즐겨찾기 토글 후 홈 갤러리 정렬 | `onChanged()` → `_loadTasks()` → 리로드 시 favorite 우선 정렬 |
| 전체선택 시 즐겨찾기만 있는 경우 | `_selectedIds` 가 빈 set → 확인 버튼 비활성 (기존 동작) |
| 즐겨찾기 해제 후 전체선택 | 해제된 항목은 다음 전체선택에 포함됨 |
| 삭제 모드에서 즐겨찾기 개별 선택 | 허용 — 전체선택만 제외, 개별 탭은 차단하지 않음 |

---

_이 Design 은 CLAUDE.md 고정 규약(R-series Provider 패턴 + Clean Architecture + l10n ko 선반영)을 기반으로 작성되었습니다. 3-옵션 아키텍처 비교는 건너뛰고 R-series 고정 구조를 적용합니다._
