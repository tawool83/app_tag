# more-barcodes Plan

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 현재 앱은 QR(ISO/IEC 18004) 만 지원. 일부 사용자(인쇄·물류·재고 컨텍스트)는 PDF417·DataMatrix·EAN/UPC 같은 추가 바코드가 필요하나, 일반 사용자에게는 메뉴 복잡도만 가중. 일상 사용자와 전문 사용자 모두 만족시킬 진입 게이트가 필요. |
| **Solution** | 설정 화면에 **"더 많은 바코드 사용"** 토글 1개 추가 (default OFF). SharedPreferences 영속화. 토글 ON 시 동작은 본 scope 밖 — **이번 cycle 은 설정값만**. 향후 구현 시 이 게이트를 분기 조건으로 사용. |
| **Function UX Effect** | 햄버거 메뉴 → 설정 → "인식률 알림 사용" 아래 행에 SwitchListTile + i 아이콘. i 탭 → 지원 예정 바코드 11종 나열 dialog. 토글 ON/OFF 만 영속화, UI 다른 영역 변화는 없음. |
| **Core Value** | 추후 다양한 바코드 지원 기능을 누적적으로 추가할 수 있는 **단일 진입 게이트** 확보. 지금은 빈 토글이지만 토대 역할. 일반 사용자 화면 단순성 유지(default OFF). |

---

## 1. 요구사항

### 1.1 기능 정의 (이번 scope)
- 햄버거 메뉴 → 설정 화면(`SettingsScreen`)에 **"더 많은 바코드 사용"** SwitchListTile 1행 추가
- 위치: 기존 "인식률 알림 사용" 아래 (사용자 결정)
- 영속화: `SharedPreferences` 키 1개 (`more_barcodes_enabled`, default `false`)
- 동작:
  - 토글 ON → 설정값을 `true` 로 저장 (즉시)
  - 토글 OFF → 설정값을 `false` 로 저장 (즉시)
  - **토글 ON 시 다른 어떤 동작도 트리거하지 않음** (홈/생성 흐름 변화 없음)
- 지원 예정 바코드 11종 — i 아이콘 탭 → AlertDialog 안내:
  - **2D**: PDF417, DataMatrix, Aztec
  - **1D 일반**: Code128, Code39, Code93
  - **1D 산업**: Codabar
  - **1D 소매 (GTIN)**: EAN-8, EAN-13, UPC-A, UPC-E

### 1.2 UX 흐름
1. 사용자: 햄버거 메뉴 → "설정" 항목 탭 → `/settings`
2. 설정 화면 스크롤 → "인식률 알림 사용" 아래 "더 많은 바코드 사용" 행 노출
3. 토글 ON → 즉시 `SharedPreferences` 저장 (visual feedback 은 Switch animation 만)
4. i 아이콘 탭 → "지원 예정 바코드 — PDF417, DataMatrix, ... 11종" 안내 dialog → "확인" 닫기
5. 다른 화면(홈 / QR 생성 / 결과)에는 **이번 cycle 에서 어떤 변화도 발생 안 함**

### 1.3 비적용 범위 (이번 scope 밖)
- 토글 ON 시 홈 화면 tile 변화 — 미적용
- 실제 바코드 생성 로직 (PDF417/DataMatrix 등) — **미적용 (향후 cycle)**
- 바코드별 데이터 입력 화면 — 미적용
- 바코드 종류별 default 활성/비활성 세부 토글 — 미적용 (지금은 마스터 게이트 1개만)
- 다른 모듈에서 본 설정값 watch — 미적용 (사용자 결정: 한번 읽기만)
- 다국어 — `app_ko.arb` 만 (CLAUDE.md 정책)

---

## 2. 영향 분석

### 2.1 영속화 변경

**`lib/core/services/settings_service.dart`**:
- private const: `_kMoreBarcodes = 'more_barcodes_enabled'`
- public methods (기존 `_kReadabilityAlert` 패턴 동일):
  - `static Future<bool> getMoreBarcodesEnabled()` → default `false`
  - `static Future<void> saveMoreBarcodesEnabled(bool enabled)`

### 2.2 UI 변경

**`lib/features/settings/settings_screen.dart`**:
- `_SettingsScreenState` 에 `bool _moreBarcodesEnabled = false` 추가
- `_loadSettings()` 에서 `SettingsService.getMoreBarcodesEnabled()` 병행 read
- `build()` 의 인식률 알림 SwitchListTile 아래에 다음 추가:
  ```dart
  SwitchListTile(
    secondary: const Icon(Icons.qr_code_2_outlined),
    title: Text(l10n.settingsMoreBarcodes),
    value: _moreBarcodesEnabled,
    onChanged: (v) {
      setState(() => _moreBarcodesEnabled = v);
      SettingsService.saveMoreBarcodesEnabled(v);
    },
    // i 아이콘은 SwitchListTile 의 trailing/leading 슬롯이 이미 사용 중이므로
    // title 을 Row 로 감싸서 i 아이콘을 옆에 배치 (구현 단계에서 결정)
  ),
  ```
- i 아이콘 탭 → `showDialog` → `AlertDialog(title, content: Text(지원 바코드 11종 안내), actions: [확인])`

> SwitchListTile 의 secondary slot 는 leading 위치. i 아이콘은 title 옆에 inline 으로 배치 (구현 단계에서 Row(title + i icon) 또는 별도 ListTile + Switch 패턴 결정).

### 2.3 l10n 추가 키

**`lib/l10n/app_ko.arb`**:
- `settingsMoreBarcodes`: "더 많은 바코드 사용"
- `settingsMoreBarcodesInfoTitle`: "지원 예정 바코드"
- `settingsMoreBarcodesInfoBody`: "켜면 향후 다음 바코드를 사용할 수 있습니다.\n\n• 2D: PDF417, DataMatrix, Aztec\n• 1D 일반: Code128, Code39, Code93\n• 1D 산업: Codabar\n• 1D 소매: EAN-8, EAN-13, UPC-A, UPC-E\n\n현재는 설정만 저장되며 실제 사용은 추후 업데이트에서 제공됩니다."

기존 `actionConfirm` ("확인") 재사용 — dialog action 버튼.

### 2.4 State / Notifier / Entity 변경

**모두 변경 없음** — settings 는 R-series 도메인 외부 (앱 전역 environment 설정). 기존 `_readabilityAlert` 와 동일 패턴: local State 로만 관리, SharedPreferences 직접 호출, 다른 곳에서 watch 안 함.

CLAUDE.md 룰 1 ("R-series Provider 패턴") 의 "신규 feature" 정의에 해당 안 함 — 기존 settings infra 확장이며, trivial 요건 (필드 ≤ 3, setter ≤ 3) 도 충족.

---

## 3. 구현 순서

| 순서 | 파일 | 작업 |
|------|------|------|
| 1 | `lib/core/services/settings_service.dart` | `_kMoreBarcodes` const + `get/saveMoreBarcodesEnabled` 2 메서드 |
| 2 | `lib/l10n/app_ko.arb` | 3개 키 추가 |
| 3 | `lib/features/settings/settings_screen.dart` | `_moreBarcodesEnabled` 필드 + `_loadSettings` 확장 + SwitchListTile + i 아이콘 + dialog |
| 4 | `flutter gen-l10n` | l10n 코드 재생성 |
| 5 | 수동 테스트 | 토글 ON/OFF → 앱 재시작 후 상태 보존 확인. dialog 표시 확인. |

---

## 4. 기술 결정

| 항목 | 결정 | 근거 |
|------|------|------|
| 영속화 위치 | `SettingsService` (SharedPreferences) | 기존 `_kReadabilityAlert` 와 동일 인프라 사용. 단일 진실원천 |
| State 관리 | 로컬 `setState` (Riverpod 미사용) | 다른 모듈에서 watch 불필요 (사용자 결정). YAGNI 적용 |
| Default 값 | `false` | 사용자 명시 — 일상 사용자 단순성 유지 |
| 안내 방식 | i 아이콘 → AlertDialog | 부제 텍스트 길어서 줄 바뀜 우려 + 향후 지원 바코드 늘어나도 dialog 본문만 수정 (사용자 결정) |
| 토글 위치 | "인식률 알림 사용" 아래 | 사용자 결정 — 단순 추가, Divider/섹션 그룹화 미적용 |
| 키 명명 | `more_barcodes_enabled` (snake_case) | 기존 `readability_alert` 패턴 동일 |
| 지원 바코드 코드 정의 | **미적용** (이번 scope 밖) | 동작은 향후 결정. 11종 list 는 dialog body 텍스트로만 존재 |
| 햄버거 메뉴 자체 변경 | **없음** | 햄버거 → /settings 라우팅은 이미 존재. 신규 라우트 불필요 |

---

## 5. 향후 cycle (참고용 — 본 plan 의 일부 아님)

토글 ON 시 동작이 결정되면 다음 사이클에서 다룰 예정:
- 홈 화면 tile 메뉴에 "PDF417 / DataMatrix / 바코드(GTIN)" 섹션 노출 (조건부)
- 바코드별 입력 화면 (`lib/features/{barcode_type}_tag/` 신규 feature)
- 바코드 렌더링 라이브러리 선정 (예: `barcode_widget`, `pretty_qr_code` 의 한계 검토)
- NFC 기록 시 바코드 종류별 지원 여부 검토 (NFC NDEF 는 바코드 자체가 아닌 데이터)
- 인쇄/공유 흐름 통합 (현재 QR 전용 → 바코드 일반화)

이 시점에 본 설정값을 분기 조건으로 사용 (`if (await SettingsService.getMoreBarcodesEnabled()) ...`).

---

## 6. 프로젝트 메타

- **Level**: Flutter Dynamic × Clean Architecture × R-series
- **State Management**: 본 feature 한정으로 `setState` (settings 화면 로컬 state). 다른 곳 watch 없음
- **로컬 저장**: `SharedPreferences` (기존 SettingsService 인프라)
- **라우팅**: go_router (기존 `/settings` 재사용, 변경 없음)
