## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 홈 화면 9개 타일 중 사용하지 않는 메뉴가 항상 노출되어 화면이 복잡하고 원하는 기능 접근이 느리다. |
| **Solution** | 길게 누르면 편집 모드 진입 → 각 타일 우측 상단 X 버튼으로 숨기기 → 더보기 버튼으로 숨긴 타일 복원. |
| **Function UX Effect** | 자주 쓰는 타일만 보이는 커스텀 홈 화면을 제공해 탭 수를 줄이고 혼잡함을 제거한다. |
| **Core Value** | 사용자가 앱을 자기 워크플로에 맞게 조정할 수 있어 재사용률과 만족도가 높아진다. |

---

# Plan: home-tile-visibility

## 1. 기능 개요

| 항목 | 내용 |
|------|------|
| Feature | home-tile-visibility |
| 작성일 | 2026-04-11 |
| 우선순위 | High |
| 난이도 | Medium |

홈 화면 타일을 길게 눌러 편집 모드로 진입하고, 불필요한 타일을 숨길 수 있는 기능이다. 숨긴 타일은 화면 하단 "더보기" 버튼을 통해 다시 확인하고 복원할 수 있다.

---

## 2. 요구사항

### 2.1 기능 요구사항

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| FR-01 | 홈 화면에서 아무 타일이나 길게 누르면 편집 모드로 진입한다. | Must |
| FR-02 | 편집 모드에서 각 타일 우측 상단에 X 아이콘 배지가 표시된다. | Must |
| FR-03 | 편집 모드에서 X 배지를 탭하면 해당 타일이 즉시 숨겨진다. | Must |
| FR-04 | AppBar에 "완료" 버튼이 나타나 탭하면 편집 모드를 종료한다. | Must |
| FR-05 | 숨겨진 타일이 1개 이상 있으면 그리드 하단에 "더보기" 버튼이 표시된다. | Must |
| FR-06 | "더보기" 버튼을 탭하면 숨겨진 타일 목록이 그리드 아래 섹션에 펼쳐진다. | Must |
| FR-07 | 펼쳐진 숨긴 타일을 탭하면 해당 타일이 복원(다시 보이기)된다. | Must |
| FR-08 | 숨김/복원 상태는 앱 재시작 후에도 유지된다 (SharedPreferences 저장). | Must |
| FR-09 | 모든 타일이 표시 중일 때는 "더보기" 버튼이 나타나지 않는다. | Must |
| FR-10 | 마지막 타일 1개는 숨길 수 없다 (최소 1개 보장). | Should |

### 2.2 비기능 요구사항

- 편집 모드 진입/종료 애니메이션: 자연스러운 전환 (scale or fade)
- 숨긴 타일 섹션: 흐릿한 스타일(opacity 0.5)로 "비활성" 느낌 전달
- 편집 모드 중 타일 onTap은 비활성화 (X 버튼만 반응)

---

## 3. 기술 스택 및 구현 방향

### 3.1 상태 관리

| 상태 | 타입 | 저장 위치 | 설명 |
|------|------|---------|------|
| `_editMode` | `bool` | 메모리 (transient) | 편집 모드 활성 여부 |
| `_hiddenKeys` | `Set<String>` | SharedPreferences | 숨긴 타일 key 목록 |
| `_showHiddenSection` | `bool` | 메모리 (transient) | 더보기 섹션 펼침 여부 |

- `HomeScreen`을 `StatefulWidget`으로 변환 (현재 `StatelessWidget`)
- SharedPreferences key: `hidden_tile_keys` (comma-separated string)

### 3.2 타일 키 정의

각 타일에 고정 key를 부여한다:

| Key | 타일 |
|-----|------|
| `app` | 앱 실행 / 단축키 |
| `clipboard` | 클립보드 |
| `website` | 웹 사이트 |
| `contact` | 연락처 |
| `wifi` | WiFi |
| `location` | 위치 |
| `event` | 이벤트/일정 |
| `email` | 이메일 |
| `sms` | SMS |

### 3.3 파일 변경 범위

| 파일 | 변경 유형 | 내용 |
|------|---------|------|
| `lib/features/home/home_screen.dart` | **수정** | StatefulWidget 전환, 편집 모드, 숨김 로직 |
| `lib/services/settings_service.dart` | **수정** | `getHiddenTileKeys()`, `saveHiddenTileKeys()` 추가 |

신규 파일 없음. 기존 파일 2개만 수정.

---

## 4. UX 흐름

```
[홈 화면 - 일반 모드]
  ↓ 타일 길게 누르기
[편집 모드]
  - AppBar 우측: "완료" 버튼
  - 각 타일: X 배지 표시, onTap 비활성화
  - X 탭 → 해당 타일 즉시 숨김
  ↓ "완료" 탭
[홈 화면 - 일반 모드]
  - 숨긴 타일 있으면 그리드 하단에 [더보기 ▼] 버튼
  ↓ [더보기] 탭
[더보기 섹션 펼침]
  - 숨긴 타일들이 흐릿하게(opacity 0.5) 표시
  - 탭하면 복원 → 그리드에 재등장
```

---

## 5. UI 컴포넌트 설계

### 5.1 편집 모드 AppBar 변경

```
편집 모드 OFF: [NFC 아이콘] "App Tag"         [?] [이력]
편집 모드 ON:  [NFC 아이콘] "편집 모드"        [완료]
```

### 5.2 타일 X 배지

`Stack` 위젯으로 `_TileCard` 위에 `Positioned` 배지를 올린다:

```
Stack
  └─ _TileCard (onTap: editMode ? null : item.onTap)
  └─ Positioned(top: 4, right: 4)
       └─ X 아이콘 버튼 (CircleAvatar, red)
         (editMode 일 때만 표시)
```

### 5.3 더보기 섹션

그리드 하단에 `AnimatedSize` + `Column`으로 펼침:

```
[더보기 ▼ / 숨긴 메뉴 ▲] 버튼
  ↓ 펼치면
  흐릿한 타일 그리드 (Opacity 0.5)
  각 타일 탭 → 복원
```

---

## 6. 데이터 영속성

`SettingsService`에 추가할 메서드:

```dart
static const _kHiddenTileKeys = 'hidden_tile_keys';

static Future<Set<String>> getHiddenTileKeys() async {
  final prefs = await SharedPreferences.getInstance();
  final csv = prefs.getString(_kHiddenTileKeys) ?? '';
  if (csv.isEmpty) return {};
  return csv.split(',').toSet();
}

static Future<void> saveHiddenTileKeys(Set<String> keys) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kHiddenTileKeys, keys.join(','));
}
```

---

## 7. 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| 모든 타일 숨기려 할 때 | 마지막 1개는 X 배지를 비활성(grey)으로 표시, 탭 무시 |
| SharedPreferences 읽기 실패 | 빈 Set 반환 (모든 타일 표시) |
| 편집 모드 중 더보기 버튼 | 편집 모드 중에는 더보기 버튼 숨김 (혼란 방지) |

---

## 8. 수용 기준 (Acceptance Criteria)

- [ ] 아무 타일이나 길게 누르면 편집 모드 진입 (X 배지 + "완료" 버튼 표시)
- [ ] 편집 모드에서 X 탭 시 해당 타일이 그리드에서 사라짐
- [ ] "완료" 탭 시 편집 모드 종료, 정상 모드로 복귀
- [ ] 숨긴 타일이 있으면 하단에 "더보기" 버튼 표시
- [ ] "더보기" 탭 시 숨긴 타일 목록 펼쳐짐
- [ ] 숨긴 타일 탭 시 복원 (그리드 재등장)
- [ ] 앱 재시작 후 숨김 상태 유지
