# Design: direct-output

## 1. 개요

Plan 문서 참조: `docs/01-plan/features/direct-output.plan.md`

"다음 →" 버튼을 제거하고 각 태그 입력 화면 하단에 QR / NFC 버튼을 직접 배치한다.
OutputSelectorScreen 경유를 제거하여 사용자 조작 단계를 1단계 줄인다.

---

## 2. 아키텍처

### 현재 흐름
```
TagInputScreen → _onNext() → /output-selector → QR 또는 NFC 선택
```

### 변경 후 흐름
```
TagInputScreen → _onQr()  → /qr-result
              → _onNfc() → /nfc-writer
```

### 공유 위젯 위치
```
lib/shared/widgets/output_action_buttons.dart
```

---

## 3. 신규 위젯: `OutputActionButtons`

### 역할
- QR 버튼 (항상 활성) + NFC 버튼 (NFC 가용성에 따라 활성/비활성) 을 렌더링
- NFC 가용성 체크는 위젯 내부에서 Riverpod provider 구독
- 실제 폼 유효성 검사 및 네비게이션 인수 생성은 부모 화면이 담당

### 인터페이스
```dart
class OutputActionButtons extends ConsumerWidget {
  final VoidCallback onQrPressed;
  final VoidCallback onNfcPressed;
  
  const OutputActionButtons({
    super.key,
    required this.onQrPressed,
    required this.onNfcPressed,
  });
}
```

### NFC 상태 처리
```dart
// nfcAvailableProvider + nfcWriteSupportedProvider (from app_picker_provider.dart)
// - loading: NFC 버튼 비활성 (로딩 중)
// - error:   NFC 버튼 비활성
// - nfcAvailable == false: 버튼 비활성 (onTap: null)
// - writeSupported == false: 버튼 비활성
// - 모두 true: onNfcPressed 연결
```

### UI 레이아웃
```
┌────────────────────────────────────────┐
│  [QR 코드 생성]  ElevatedButton (전체 너비) │
│  [NFC 태그 쓰기] OutlinedButton (전체 너비) │
└────────────────────────────────────────┘
```

- 두 버튼 사이 간격: `SizedBox(height: 12)`
- 버튼 높이: `padding: EdgeInsets.symmetric(vertical: 16)`
- border radius: `BorderRadius.circular(12)`
- QR 버튼 아이콘: `Icons.qr_code`
- NFC 버튼 아이콘: `Icons.nfc`
- NFC 비활성 시: `OutlinedButton` `onPressed: null` (Flutter 기본 비활성 스타일)

---

## 4. 각 화면 변경 패턴

### 공통 패턴 (8개 화면 동일)

**제거**: 기존 `_onNext()` 메서드 + 단일 `ElevatedButton` 

**추가**: `_onQr()` + `_onNfc()` 메서드 + `OutputActionButtons` 위젯

```dart
// 기존
void _onNext() {
  if (!_formKey.currentState!.validate()) return;
  Navigator.pushNamed(context, '/output-selector', arguments: {
    'appName': 'XXX',
    'deepLink': TagPayloadEncoder.xxx(...),
    'platform': 'universal',
    'outputType': 'qr',
    'appIconBytes': null,
    'tagType': 'xxx',
  });
}

// 변경 후
void _onQr() {
  if (!_formKey.currentState!.validate()) return;
  Navigator.pushNamed(context, '/qr-result', arguments: _buildArgs());
}

void _onNfc() {
  if (!_formKey.currentState!.validate()) return;
  Navigator.pushNamed(context, '/nfc-writer', arguments: _buildArgs());
}

Map<String, dynamic> _buildArgs() => {
  'appName': 'XXX',
  'deepLink': TagPayloadEncoder.xxx(...),
  'platform': 'universal',
  'outputType': '',   // qr-result / nfc-writer 각자가 outputType을 알고 있으므로 생략 가능
  'appIconBytes': null,
  'tagType': 'xxx',
};
```

> **Note**: `/qr-result`와 `/nfc-writer`는 `outputType` 인수를 직접 사용하지 않고
> 각자의 역할이 고정되어 있으므로 `_buildArgs()`에서 `outputType` 제거 가능.
> 하지만 기존 QrResultScreen/NfcWriterScreen이 해당 키를 읽는지 확인 후 결정.

**위젯 교체**:
```dart
// 기존
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: _onNext,
    icon: const Icon(Icons.arrow_forward),
    label: const Text('다음'),
    ...
  ),
)

// 변경 후
OutputActionButtons(
  onQrPressed: _onQr,
  onNfcPressed: _onNfc,
)
```

---

## 5. 화면별 변경 명세

| 파일 | appName | TagPayloadEncoder 메서드 | tagType |
|------|---------|-------------------------|---------|
| clipboard_tag_screen.dart | `'클립보드'` | `TagPayloadEncoder.clipboard(text)` | `'clipboard'` |
| website_tag_screen.dart | `'웹사이트'` | `TagPayloadEncoder.url(url)` | `'website'` |
| contact_manual_form.dart | `'연락처'` | `TagPayloadEncoder.contact(name, phone, email)` | `'contact'` |
| wifi_tag_screen.dart | `'WiFi'` | `TagPayloadEncoder.wifi(ssid, securityType, password)` | `'wifi'` |
| location_tag_screen.dart | `'위치'` | `TagPayloadEncoder.location(lat, lng)` | `'location'` |
| event_tag_screen.dart | `'일정'` | `TagPayloadEncoder.event(...)` | `'event'` |
| email_tag_screen.dart | `'이메일'` | `TagPayloadEncoder.email(address, subject, body)` | `'email'` |
| sms_tag_screen.dart | `'SMS'` | `TagPayloadEncoder.sms(phone, body)` | `'sms'` |

---

## 6. contact_tag_screen 처리

연락처 picker 화면은 리스트 탭 액션이므로 폼 구조가 없음.
`_onContactSelected(Contact contact)` 에서 직접 `/qr-result`로 이동하도록 변경:

```dart
// 기존
void _onContactSelected(Contact contact) {
  Navigator.pushNamed(context, '/output-selector', arguments: {...});
}

// 변경 후
void _onContactSelected(Contact contact) {
  Navigator.pushNamed(context, '/qr-result', arguments: {
    'appName': '연락처',
    'deepLink': TagPayloadEncoder.contact(...),
    'platform': 'universal',
    'appIconBytes': null,
    'tagType': 'contact',
  });
}
```

> 연락처 탭은 QR이 주 사용 목적. NFC 추가 버튼은 QrResultScreen 내 공유/NFC 옵션으로 처리.

---

## 7. QrResultScreen / NfcWriterScreen arguments 확인

기존 `/output-selector`가 `/qr-result`로 전달하던 인수:
```dart
{
  'appName': appName,
  'deepLink': deepLink,
  'packageName': packageName,   // nullable
  'platform': platform,
  'outputType': 'qr',
  'appIconBytes': appIconBytes, // nullable
}
```

태그 화면들은 `packageName` 없이 호출 → `null`로 전달 (기존과 동일).
`outputType` 키: QrResultScreen이 사용하는지 확인 필요. 사용하지 않으면 생략.

---

## 8. StatelessWidget → ConsumerWidget 변경

`OutputActionButtons`가 `ConsumerWidget`이므로 태그 화면 자체는 변경 불필요.
(`ConsumerWidget`은 위젯 트리 내 어디서든 Riverpod 구독 가능)

---

## 9. 파일 구조

```
lib/
  shared/
    widgets/
      output_action_buttons.dart   ← 신규
  features/
    clipboard_tag/clipboard_tag_screen.dart   ← 수정
    website_tag/website_tag_screen.dart        ← 수정
    contact_tag/contact_tag_screen.dart        ← 수정 (picker 흐름)
    contact_tag/contact_manual_form.dart       ← 수정
    wifi_tag/wifi_tag_screen.dart              ← 수정
    location_tag/location_tag_screen.dart      ← 수정
    event_tag/event_tag_screen.dart            ← 수정
    email_tag/email_tag_screen.dart            ← 수정
    sms_tag/sms_tag_screen.dart                ← 수정
```

---

## 10. 검수 기준 (AC)

| # | 항목 | 확인 방법 |
|---|------|-----------|
| AC-01 | 8개 입력 화면 하단에 QR/NFC 버튼 2개 표시 | 각 화면 렌더링 확인 |
| AC-02 | QR 버튼 탭 → `/qr-result`로 정상 이동 | 탭 후 화면 전환 확인 |
| AC-03 | NFC 버튼 탭 → `/nfc-writer`로 정상 이동 | 탭 후 화면 전환 확인 |
| AC-04 | NFC 미지원 기기에서 NFC 버튼 비활성 | 시뮬레이터에서 확인 |
| AC-05 | 폼 빈 칸 상태로 버튼 탭 → 유효성 오류 표시, 화면 이동 없음 | 빈 폼 테스트 |
| AC-06 | OutputSelectorScreen 유지, app-picker 흐름 정상 | 앱 선택 흐름 테스트 |
| AC-07 | contact_tag_screen에서 연락처 탭 → `/qr-result` 이동 | 연락처 탭 확인 |
