# Gap Analysis: home-tile-visibility

> Design 참조: `docs/02-design/features/home-tile-visibility.design.md`
> 분석일: 2026-04-12

---

## 결과 요약

| 항목 | 값 |
|------|-----|
| **Match Rate** | **99%** |
| 수용 기준 통과 | 9 / 9 |
| 설계 명세 일치 | 전 섹션 Pass |
| Gap (누락) | 없음 |
| Gap (불일치) | 5건 (전부 Info — 기능 범위 외 브랜딩/명명) |

---

## 수용 기준 (Acceptance Criteria) 검증 — 섹션 9

| # | 항목 | 결과 | 근거 |
|---|------|:----:|------|
| 1 | `_initialized = false`일 때 로딩 스피너 표시 | Pass | `home_screen.dart:177-182` `!_initialized` → `CircularProgressIndicator` |
| 2 | 길게 누르면 `_editMode = true`, X 배지 + "완료" 버튼 표시 | Pass | `onLongPress: _enterEditMode` (L228), AppBar "완료" (L135), X badge (L230-247) |
| 3 | 편집 모드에서 타일 onTap 비활성화 | Pass | `_TileCard`: `onTap: editMode ? null : item.onTap` (L358) |
| 4 | X 탭 → 타일 제거, SharedPreferences 저장 | Pass | `_hideTile` → `setState` + `saveHiddenTileKeys` (L44-48) |
| 5 | 타일 1개 남을 때 X 배지 회색 + 탭 무반응 | Pass | `isLastVisible ? null : ...` (L235), `Colors.grey` (L240) |
| 6 | "완료" → 편집 모드 종료, 더보기 버튼 표시 | Pass | `_exitEditMode` (L40-42), `if (hiddenTiles.isNotEmpty && !_editMode)` (L210) |
| 7 | "더보기" 탭 → 숨긴 타일 그리드 펼침 (opacity 0.5) | Pass | `_showHiddenSection` toggle (L257), `Opacity(0.5)` (L290) |
| 8 | 숨긴 타일 탭 → 복원, SharedPreferences 저장 | Pass | `onTap: () => _restoreTile(t.key)` override (L301-306) |
| 9 | 앱 재시작 후 숨김 상태 유지 | Pass | `initState` → `_loadHiddenKeys` → `SharedPreferences` read |

**수용 기준 Match Rate: 9/9 = 100%**

---

## 설계 명세 검증 (섹션 2~8)

| 섹션 | 항목 | 결과 | 비고 |
|------|------|:----:|------|
| 2 | `StatefulWidget` 전환 | Pass | `HomeScreen extends StatefulWidget` |
| 3 | `_TileItem` key 필드 + 9개 타일 key | Pass | 전부 일치 |
| 4 | 4개 state 필드 + 4개 메서드 | Pass | 완전 일치 |
| 5.1 | `build()` 구조 | Pass | loading → split → Scaffold |
| 5.2 | AppBar 편집/일반 모드 분기 | Pass | 구현됨 (타이틀/아이콘 브랜딩 변경은 기능 범위 외) |
| 5.3 | Body 레이아웃 | Pass | `SingleChildScrollView` + Grid + 더보기 |
| 5.4 | `_buildTileWithBadge` Stack + Positioned X 배지 | Pass | `StackFit.expand` 추가 (레이아웃 버그 수정) |
| 5.5 | `_TileCard` onLongPress + editMode | Pass | 완전 일치 |
| 5.6 | 숨긴 타일 섹션 + 복원 onTap | Pass | 완전 일치 |
| 6 | `SettingsService` 메서드 2개 | Pass | CSV 저장/로드 일치 |
| 7 | 데이터 흐름 전체 | Pass | 모든 경로 구현 |
| 8 | 파일별 변경 명세 | Pass | 9항목(home_screen) + 3항목(settings) 전부 |

---

## Gap 목록

### 누락 (Design O, 구현 X)
**없음**

### 추가 (Design X, 구현 O) — Info

| 항목 | 위치 | 설명 |
|------|------|------|
| 로딩 중 AppBar 표시 | `home_screen.dart:179` | 설계 누락 → UX 개선 |
| `StackFit.expand` | `home_screen.dart:222` | GridView 셀 크기 정합성 버그 수정 |
| `visibleCount` 파라미터 방식 | `home_screen.dart:44` | 설계는 내부 계산 → 더 명확한 구조 |

### 불일치 (Design ≠ 구현) — Info (기능 범위 외)

| 항목 | 설계 | 구현 |
|------|------|------|
| AppBar 타이틀 | `'App Tag'` | `'QR, NFC 생성기'` |
| AppBar leading | `Icons.nfc` 단일 | `Icons.qr_code` + `Icons.nfc` |
| iOS `app` 타일 레이블 | `'앱 실행 / 단축키'` | `'단축어'` |
| iOS `app` 타일 아이콘 | `Icons.shortcut` | `CupertinoIcons.square_stack_3d_up` |
| 메서드명 | `_buildShowMoreButton` | `_buildHiddenSection` |

모두 수용 기준 외 브랜딩/플랫폼 선택 사항으로 Match Rate에 영향 없음.

---

## 결론

Match Rate **99%** — 수용 기준 9/9 완전 통과. 모든 Gap은 Info 수준이며 기능 범위 외.

**다음 단계**: `/pdca report home-tile-visibility`
