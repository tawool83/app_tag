# more-barcodes Design

> Plan: `docs/01-plan/features/more-barcodes.plan.md`

---

## 0. 아키텍처 결정

CLAUDE.md 고정 규약에 따라 R-series Provider 패턴 + Clean Architecture 자동 적용. 3-옵션 비교 생략.

**본 feature 의 R-series 적용 판정**:
- 기존 settings 인프라(`SettingsService` static + `SettingsScreen` local state) 확장 — **신규 feature 모듈 아님**
- CLAUDE.md 룰 1 의 trivial 요건(필드 ≤ 3, setter ≤ 3) 충족
- 기존 `_kReadabilityAlert` 와 동일 패턴이 reference
- 따라서 **신규 디렉터리/sub-state/notifier 생성 없음**. 단일 boolean key + 2 메서드만 추가.

---

## 1. 디렉터리 트리 (변경 영역)

```
lib/
├── core/services/
│   └── settings_service.dart                   # ✎ MODIFY — const 1 + method 2
└── features/settings/
    └── settings_screen.dart                    # ✎ MODIFY — 필드 + load + UI 행

lib/l10n/
└── app_ko.arb                                  # ✎ MODIFY — 키 3개
```

**총 파일**: 신규 0, 수정 3

> 신규 feature 모듈(`lib/features/more_barcodes/...`) 은 **만들지 않는다**. 향후 동작 cycle 에서 실제 바코드 처리 로직이 결정될 때 별도 feature 로 분리 (예: `lib/features/barcode/`).

---

## 2. SettingsService 시그니처

### 2.1 `lib/core/services/settings_service.dart`

기존 패턴(`_kReadabilityAlert`) 과 1:1 동형:

```dart
// 파일 상단 const 영역에 추가:
const _kMoreBarcodes = 'more_barcodes_enabled';

// SettingsService class 내부, getReadabilityAlert / saveReadabilityAlert 아래에 추가:

// ── More barcodes (PDF417, DataMatrix, EAN, UPC, Code128, ... 마스터 게이트) ──
static Future<bool> getMoreBarcodesEnabled() async =>
    (await _prefs).getBool(_kMoreBarcodes) ?? false;
static Future<void> saveMoreBarcodesEnabled(bool enabled) async =>
    (await _prefs).setBool(_kMoreBarcodes, enabled);
```

**시그니처 결정**:
- 메서드 명: `get/saveMoreBarcodesEnabled` (기존 `get/saveReadabilityAlert` 와 동형)
- key 명: `more_barcodes_enabled` (snake_case, 기존 `readability_alert` 패턴)
- default: `false`
- 반환 타입: `Future<bool>` (SharedPreferences 비동기)

---

## 3. SettingsScreen 변경 시그니처

### 3.1 `lib/features/settings/settings_screen.dart`

#### 3.1.1 State 필드 추가

```dart
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _readabilityAlert = false;
  bool _moreBarcodesEnabled = false;   // ★ NEW
  // ...
}
```

#### 3.1.2 `_loadSettings()` 확장

```dart
Future<void> _loadSettings() async {
  final results = await Future.wait([
    SettingsService.getReadabilityAlert(),
    SettingsService.getMoreBarcodesEnabled(),
  ]);
  if (!mounted) return;
  setState(() {
    _readabilityAlert = results[0];
    _moreBarcodesEnabled = results[1];
  });
}
```

> 기존 단일 호출 → `Future.wait` 로 병렬화 (관용적 개선, 마이크로 옵티). 한 번에 setState — 화면 깜빡임 1회로 감소.

#### 3.1.3 `build()` UI 추가

기존 `// 인식률 알림 설정` SwitchListTile 블록 다음에 추가:

```dart
// ── 인식률 알림 (기존) ──
SwitchListTile(
  secondary: const Icon(Icons.notifications_outlined),
  title: Text(l10n.settingsReadabilityAlert),
  value: _readabilityAlert,
  onChanged: (v) {
    setState(() => _readabilityAlert = v);
    SettingsService.saveReadabilityAlert(v);
  },
),
// ── 더 많은 바코드 사용 (신규) ──
SwitchListTile(
  secondary: const Icon(Icons.qr_code_2_outlined),
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(l10n.settingsMoreBarcodes)),
      const SizedBox(width: 4),
      InkResponse(
        onTap: () => _showMoreBarcodesInfo(context, l10n),
        radius: 16,
        child: Icon(Icons.info_outline,
            size: 18, color: Colors.grey.shade600),
      ),
    ],
  ),
  value: _moreBarcodesEnabled,
  onChanged: (v) {
    setState(() => _moreBarcodesEnabled = v);
    SettingsService.saveMoreBarcodesEnabled(v);
  },
),
```

#### 3.1.4 `_showMoreBarcodesInfo()` 메서드 추가

```dart
void _showMoreBarcodesInfo(BuildContext context, AppLocalizations l10n) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.settingsMoreBarcodesInfoTitle),
      content: Text(l10n.settingsMoreBarcodesInfoBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionConfirm),
        ),
      ],
    ),
  );
}
```

---

## 4. l10n 변경 시그니처

### 4.1 `lib/l10n/app_ko.arb` — 3 키 추가

기존 `settingsReadabilityAlert` 다음에 추가 권장 (그룹화):

```json
{
  "settingsReadabilityAlert": "인식률 알림 사용",
  "settingsMoreBarcodes": "더 많은 바코드 사용",
  "@settingsMoreBarcodes": {
    "description": "Toggle to enable additional barcode types (PDF417, DataMatrix, EAN, UPC, etc.). Default OFF."
  },
  "settingsMoreBarcodesInfoTitle": "지원 예정 바코드",
  "@settingsMoreBarcodesInfoTitle": {
    "description": "AlertDialog title shown when user taps the info icon next to 'more barcodes' toggle"
  },
  "settingsMoreBarcodesInfoBody": "켜면 향후 다음 바코드를 사용할 수 있습니다.\n\n• 2D: PDF417, DataMatrix, Aztec\n• 1D 일반: Code128, Code39, Code93\n• 1D 산업: Codabar\n• 1D 소매: EAN-8, EAN-13, UPC-A, UPC-E\n\n현재는 설정만 저장되며 실제 사용은 추후 업데이트에서 제공됩니다.",
  "@settingsMoreBarcodesInfoBody": {
    "description": "AlertDialog body listing 11 supported barcode types and noting that actual functionality is not yet implemented"
  }
}
```

`actionConfirm` ("확인") 은 기존 키 재사용 — dialog action 버튼 라벨.

CLAUDE.md 정책: ko 만 추가, 다른 언어는 fallback.

---

## 5. 데이터 흐름

```
[앱 시작]
   ↓
[홈 화면 햄버거 메뉴]
   ↓ (사용자 탭)
[/settings 라우팅 — go_router 기존]
   ↓
[SettingsScreen.initState → _loadSettings()]
   Future.wait([
     SettingsService.getReadabilityAlert(),     // 기존
     SettingsService.getMoreBarcodesEnabled(),  // 신규
   ])
   ↓ setState
[SettingsScreen.build]
   인식률 알림 SwitchListTile (기존)
   더 많은 바코드 SwitchListTile (신규) ── i 아이콘 ── _showMoreBarcodesInfo
                                                          ↓
                                                       AlertDialog (지원 바코드 11종)

[사용자 토글 ON/OFF]
   onChanged: (v) {
     setState(() => _moreBarcodesEnabled = v);   // UI 즉시 반영
     SettingsService.saveMoreBarcodesEnabled(v); // SharedPreferences 비동기 저장
   }

[다른 모듈 — 본 cycle 에서는 read 없음]
   향후 cycle 에서 분기 조건으로 사용:
     final enabled = await SettingsService.getMoreBarcodesEnabled();
     if (enabled) { /* 추가 바코드 UI/로직 노출 */ }
```

**watch / Provider 미사용 근거**:
- 사용자 결정 — "한번 읽으면 됨"
- 다른 모듈에서 본 설정값 변경에 반응할 필요 없음
- YAGNI: Riverpod Provider 추가는 향후 동작 cycle 에서 필요해지면 그때 도입

---

## 6. 구현 순서

| 순서 | 파일 | 작업 | 줄 수 영향 |
|------|------|------|-----------|
| 1 | `core/services/settings_service.dart` | const 1줄 + method 2개 (4줄) | +5 |
| 2 | `l10n/app_ko.arb` | 3 키 + @설명 메타 | +12 |
| 3 | `flutter gen-l10n` | l10n 코드 재생성 | (자동) |
| 4 | `features/settings/settings_screen.dart` | 필드 1 + load 병렬화 + SwitchListTile + dialog 메서드 | +35, -2 |
| 5 | 수동 테스트 | 토글 ON/OFF → 앱 재시작 → 상태 보존 / dialog 표시 / 다른 화면 변화 없음 | — |

**총 변경량**: ~52줄 추가, ~2줄 삭제. R-series 룰 8 (파일 크기) 위반 없음 (settings_screen 164 → ~200 줄, 메인 200줄 룰은 R-series Notifier 메인에 적용. UI screen 은 400줄 룰 적용 — 충분).

---

## 7. 기술 결정 (design 단계 추가)

| 항목 | 결정 | 근거 |
|------|------|------|
| 신규 feature 모듈 생성 | **하지 않음** | 기존 settings infra 확장. 단일 boolean. R-series 적용 대상 외 |
| `Future.wait` 도입 | 적용 | load 호출이 1 → 2 로 늘어나므로 병렬화로 화면 첫 렌더 깜빡임 감소 |
| i 아이콘 위치 | title Row 안 inline | secondary slot 은 leading icon 으로 사용 중. trailing 은 Switch. title Row 가 자연스러움 |
| InkResponse vs IconButton | InkResponse(radius: 16) | IconButton 의 기본 padding(48dp) 이 SwitchListTile title 안에서 너무 큼. 작은 터치 영역으로 충분 |
| Dialog action 버튼 | `l10n.actionConfirm` 재사용 | 기존 "확인" 버튼 라벨 일관성 |
| 키 명명 | `settingsMoreBarcodes` (camelCase) | 기존 `settingsReadabilityAlert` 패턴 |
| 아이콘 | `Icons.qr_code_2_outlined` | QR 보다 광의의 "코드" 의미. 추후 동작 cycle 에서 `Icons.barcode` 등 후보 검토 |
| Provider/watch 미도입 | YAGNI | 다른 모듈 read 필요 없음 (사용자 결정). 향후 필요해지면 Riverpod Provider 로 마이그레이션 (read-only async provider) |

---

## 8. 검증 시나리오

### 8.1 기능 (이번 cycle scope)
- [ ] 설정 화면 진입 시 토글 default = OFF 노출
- [ ] 토글 ON → 즉시 UI 반영 + SharedPreferences 저장
- [ ] 토글 OFF → 즉시 UI 반영 + 저장
- [ ] 앱 재시작 → 마지막 토글 상태 복원
- [ ] i 아이콘 탭 → AlertDialog 표시 (제목 + 11종 본문 + "확인")
- [ ] dialog "확인" 탭 → 닫힘
- [ ] 토글 ON 상태에서 홈 / QR 생성 / 결과 화면 → **변화 없음** (의도된 비활성)

### 8.2 회귀 (기존 기능 보존)
- [ ] "인식률 알림 사용" 토글 — 기존 동작 정상 (병렬 load 도입에 따른 부작용 없음)
- [ ] 언어 설정 dropdown — 기존 동작 정상
- [ ] 계정 섹션 — 기존 동작 정상

### 8.3 엣지 케이스
- [ ] `_loadSettings` 진행 중 화면 dispose → `if (!mounted) return` 가드로 안전
- [ ] 빠른 연속 토글 ON/OFF → SharedPreferences write 는 idempotent. setState 와 save 순서 보장
- [ ] dialog 열린 상태에서 화면 회전 → AlertDialog Material 기본 처리

---

## 9. 비적용 범위

- 토글 ON 시 다른 화면 변화 — **이번 cycle scope 밖** (사용자 명시)
- 실제 바코드 (PDF417 etc.) 생성 라이브러리 도입 — 향후 cycle
- 바코드별 세부 토글 (예: PDF417 만 켜기) — 향후 cycle
- 본 설정값 cloud sync — 향후 cycle
- Riverpod Provider 도입 — YAGNI, 필요 시점에 도입

---

## 10. 위험 / 대안

| 위험 | 영향 | 대응 |
|------|------|------|
| `Future.wait` 결과 인덱스 의존 | 키 추가 시 인덱스 바뀌면 버그 | record 또는 named field 사용 검토. 현재 2개라 위험 낮음 |
| i 아이콘 inline 배치 시 긴 텍스트로 줄바꿈 | UX 손상 | `Flexible` 로 텍스트 우선 축소. 한국어 "더 많은 바코드 사용" 충분히 짧음 |
| 향후 동작 cycle 시 본 boolean 만으로 부족 | 마이그레이션 필요 | enum 화 또는 Set\<BarcodeType\> 으로 확장 (별도 cycle 에서 결정). 현재는 단순 boolean 으로 충분 |

---

## 11. 프로젝트 메타

- **Level**: Flutter Dynamic × Clean Architecture × R-series
- **State Management**: 본 feature 한정으로 `setState` (settings 화면 로컬 state)
- **로컬 저장**: `SharedPreferences` (기존 `SettingsService` 인프라 재사용)
- **라우팅**: go_router (기존 `/settings` 재사용, 변경 없음)
- **검증**: 수동 테스트 (단위 테스트 미작성 — settings 영역 기존 정책 일치)
