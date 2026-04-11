# Design: 홈 화면 타일 메뉴 재설계

> Plan 참조: `docs/01-plan/features/home-tile-menu.plan.md`
> 은행 계좌번호 타일은 이번 구현 범위에서 제외

---

## 1. 아키텍처 개요

```
HomeScreen (GridView 2열)
├── 타일 1: 앱 실행/단축키   → /app-picker 또는 /ios-input (기존)
├── 타일 2: 클립보드          → /clipboard-tag (신규)
├── 타일 3: 웹 사이트         → /website-tag (신규)
├── 타일 4: 연락처            → /contact-tag (신규)
├── 타일 5: WiFi             → /wifi-tag (신규)
├── 타일 6: 위치              → /location-tag (신규)
├── 타일 7: 이벤트/일정       → /event-tag (신규)
├── 타일 8: 이메일            → /email-tag (신규)
└── 타일 9: SMS              → /sms-tag (신규)
                                    ↓ (모든 신규 화면 공통)
                              /output-selector
                           ↙              ↘
                    /qr-result          /nfc-writer
```

---

## 2. 데이터 모델 변경

### TagHistory (lib/models/tag_history.dart)

기존 HiveField 0~10 유지, `tagType` 필드 추가:

```dart
@HiveField(11)
final String? tagType;
// 값: 'app' | 'clipboard' | 'website' | 'contact' | 'wifi' | 'location' | 'event' | 'email' | 'sms'
```

생성자에 `this.tagType` 추가 (nullable, 기존 이력 호환).

`tag_history.g.dart` build_runner 재생성 필요.

---

## 3. 신규 서비스: TagPayloadEncoder

**파일**: `lib/shared/utils/tag_payload_encoder.dart`

각 타입별 QR/NFC 페이로드 문자열 생성. 순수 함수로 구성 (static methods).

```dart
class TagPayloadEncoder {
  TagPayloadEncoder._();

  static String clipboard(String text) => text;

  static String website(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  static String contact({
    required String name,
    String? phone,
    String? email,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:$name');
    if (phone != null && phone.isNotEmpty) buffer.writeln('TEL:$phone');
    if (email != null && email.isNotEmpty) buffer.writeln('EMAIL:$email');
    buffer.write('END:VCARD');
    return buffer.toString();
  }

  static String wifi({
    required String ssid,
    required String securityType, // 'WPA2' | 'WPA' | 'WEP' | 'nopass'
    String? password,
  }) {
    final pw = password?.isNotEmpty == true ? password! : '';
    return 'WIFI:T:$securityType;S:$ssid;P:$pw;;';
  }

  static String location({
    required double lat,
    required double lng,
    String? label,
  }) {
    if (label != null && label.isNotEmpty) {
      return 'https://maps.google.com/?q=${Uri.encodeComponent(label)}&ll=$lat,$lng';
    }
    return 'geo:$lat,$lng';
  }

  static String event({
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? description,
  }) {
    String fmt(DateTime dt) =>
        '${dt.year.toString().padLeft(4,'0')}'
        '${dt.month.toString().padLeft(2,'0')}'
        '${dt.day.toString().padLeft(2,'0')}T'
        '${dt.hour.toString().padLeft(2,'0')}'
        '${dt.minute.toString().padLeft(2,'0')}00';
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('SUMMARY:$title');
    buffer.writeln('DTSTART:${fmt(start)}');
    buffer.writeln('DTEND:${fmt(end)}');
    if (location != null && location.isNotEmpty) buffer.writeln('LOCATION:$location');
    if (description != null && description.isNotEmpty) buffer.writeln('DESCRIPTION:$description');
    buffer.writeln('END:VEVENT');
    buffer.write('END:VCALENDAR');
    return buffer.toString();
  }

  static String email({
    required String address,
    String? subject,
    String? body,
  }) {
    final params = <String>[];
    if (subject != null && subject.isNotEmpty) params.add('subject=${Uri.encodeComponent(subject)}');
    if (body != null && body.isNotEmpty) params.add('body=${Uri.encodeComponent(body)}');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return 'mailto:$address$query';
  }

  static String sms({
    required String phone,
    String? message,
  }) {
    if (message != null && message.isNotEmpty) return 'smsto:$phone:$message';
    return 'sms:$phone';
  }
}
```

---

## 4. 홈 화면 (home_screen.dart) 재설계

### AppBar

```dart
AppBar(
  leading: const Icon(Icons.nfc),  // 좌측 태그 아이콘
  title: const Text('App Tag'),
  actions: [
    IconButton(icon: Icons.help_outline, ...),
    IconButton(icon: Icons.history, ...),
  ],
)
```

### 타일 데이터 모델 (파일 내부 private)

```dart
class _TileItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
}
```

### GridView 구성

```dart
GridView.count(
  crossAxisCount: 2,
  padding: EdgeInsets.all(16),
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 1.1,   // 약간 납작한 정사각형
  children: _tiles.map((t) => _TileCard(item: t)).toList(),
)
```

### 타일 정의 (9종, 플랫폼 분기 포함)

| # | label | icon | iconColor | route |
|---|-------|------|-----------|-------|
| 1 | 앱 실행 (Android) / 단축키 (iOS) | `Icons.apps` / `Icons.shortcut` | `Colors.indigo` | `/app-picker` 또는 `/ios-input` |
| 2 | 클립보드 | `Icons.content_paste` | `Colors.blueGrey` | `/clipboard-tag` |
| 3 | 웹 사이트 | `Icons.language` | `Colors.blue` | `/website-tag` |
| 4 | 연락처 | `Icons.contact_phone` | `Colors.green` | `/contact-tag` |
| 5 | WiFi | `Icons.wifi` | `Colors.teal` | `/wifi-tag` |
| 6 | 위치 | `Icons.location_on` | `Colors.red` | `/location-tag` |
| 7 | 이벤트/일정 | `Icons.event` | `Colors.orange` | `/event-tag` |
| 8 | 이메일 | `Icons.email` | `Colors.deepPurple` | `/email-tag` |
| 9 | SMS | `Icons.sms` | `Colors.pink` | `/sms-tag` |

### _TileCard 위젯

```dart
class _TileCard extends StatelessWidget {
  // Card + InkWell
  // 아이콘 (48px) + SizedBox(8) + Text(label, 중앙 정렬)
  // Card elevation: 2, borderRadius: 16
  // 배경색: Colors.white, border: 없음
}
```

---

## 5. 신규 입력 화면 상세 설계

모든 입력 화면 공통 패턴:
- `Scaffold` + `AppBar(title: Text('<타입명> 태그'))`
- `SingleChildScrollView` + `Padding(all: 24)`
- `Form` + `GlobalKey<FormState>`
- 하단 `SizedBox(width: double.infinity, child: ElevatedButton('다음'))`
- 다음 버튼 → `Navigator.pushNamed('/output-selector', arguments: {...})`

### 공통 output-selector arguments

```dart
{
  'appName': '<타입 표시명>',       // 예: '연락처', 'WiFi'
  'deepLink': TagPayloadEncoder.<method>(...),
  'platform': 'universal',
  'outputType': 'qr',
  'appIconBytes': null,
  'tagType': '<tagType값>',        // TagHistory 저장용
}
```

---

### 5-1. ClipboardTagScreen (`/clipboard-tag`)

**파일**: `lib/features/clipboard_tag/clipboard_tag_screen.dart`

```
상태:
  - TextEditingController _controller
  - bool _isEmpty = false

initState 후 WidgetsBinding.addPostFrameCallback:
  - Clipboard.getData(Clipboard.kTextPlain) 호출
  - 결과가 null 또는 빈 문자열 → _isEmpty = true
  - 결과가 있으면 _controller.text 에 설정

UI:
  - _isEmpty 시: InfoBox("클립보드가 비어 있습니다. 직접 입력하세요.")
  - TextFormField(controller, maxLines: 5, validator: 비어있으면 오류)
  - '다음' 버튼

tagType: 'clipboard'
appName: '클립보드'
```

---

### 5-2. WebsiteTagScreen (`/website-tag`)

**파일**: `lib/features/website_tag/website_tag_screen.dart`

```
UI:
  - TextFormField(
      keyboardType: TextInputType.url,
      hintText: 'https://example.com',
      validator: URL 형식 확인 (Uri.tryParse + hasAuthority)
    )
  - '다음' 버튼 → TagPayloadEncoder.website(url)

tagType: 'website'
appName: '웹 사이트'
```

---

### 5-3. ContactTagScreen (`/contact-tag`)

**파일**: `lib/features/contact_tag/contact_tag_screen.dart`

```
필드:
  - 이름 (TextFormField, 필수)
  - 전화번호 (TextFormField, keyboardType: phone, 선택)
  - 이메일 (TextFormField, keyboardType: emailAddress, 선택)

validator: 이름 필수, 이메일 형식 체크(입력 시)

'다음' → TagPayloadEncoder.contact(name, phone, email)
tagType: 'contact'
appName: '연락처'
```

---

### 5-4. WifiTagScreen (`/wifi-tag`)

**파일**: `lib/features/wifi_tag/wifi_tag_screen.dart`

```
필드:
  - SSID (TextFormField, 필수)
  - 보안 방식 (DropdownButtonFormField)
      항목: ['WPA2', 'WPA', 'WEP', 'nopass']
      표시: ['WPA2 (권장)', 'WPA', 'WEP', '없음']
      기본: 'WPA2'
  - 비밀번호 (TextFormField, obscureText + 표시 토글)
      nopass 선택 시 비활성화

'다음' → TagPayloadEncoder.wifi(ssid, securityType, password)
tagType: 'wifi'
appName: 'WiFi'
```

---

### 5-5. LocationTagScreen (`/location-tag`)

**파일**: `lib/features/location_tag/location_tag_screen.dart`

```
필드:
  - 위도 (TextFormField, keyboardType: numberWithOptions(decimal:true, signed:true))
      validator: double 파싱 가능, -90~90 범위
  - 경도 (TextFormField, 동일)
      validator: double 파싱 가능, -180~180 범위
  - 장소명 (TextFormField, 선택, 입력 시 Google Maps URL 포맷 사용)

  - [지도에서 미리보기] TextButton
      → url_launcher로 Google Maps 오픈:
        'https://maps.google.com/?q=<lat>,<lng>'

'다음' → TagPayloadEncoder.location(lat, lng, label)
tagType: 'location'
appName: '위치'
```

---

### 5-6. EventTagScreen (`/event-tag`)

**파일**: `lib/features/event_tag/event_tag_screen.dart`

```
상태:
  - DateTime _startDate, _startTime → 합쳐서 DateTime _start
  - DateTime _endDate, _endTime → 합쳐서 DateTime _end
  - 기본값: 오늘 + 현재 시각, 종료: +1시간

필드:
  - 이벤트 제목 (TextFormField, 필수)
  - 시작 일시: [날짜 선택 버튼] [시간 선택 버튼] (행으로 배치)
  - 종료 일시: [날짜 선택 버튼] [시간 선택 버튼]
  - 장소/주소 (TextFormField, 선택)
  - 설명 (TextFormField, maxLines:3, 선택)

validator: 종료 > 시작 검사

날짜/시간 선택: showDatePicker / showTimePicker 사용

'다음' → TagPayloadEncoder.event(title, start, end, location, description)
tagType: 'event'
appName: '이벤트/일정'
```

---

### 5-7. EmailTagScreen (`/email-tag`)

**파일**: `lib/features/email_tag/email_tag_screen.dart`

```
필드:
  - 이메일 주소 (TextFormField, keyboardType: emailAddress, 필수)
      validator: @ 포함 여부
  - 제목 (TextFormField, 선택)
  - 내용 (TextFormField, maxLines:4, 선택)

'다음' → TagPayloadEncoder.email(address, subject, body)
tagType: 'email'
appName: '이메일'
```

---

### 5-8. SmsTagScreen (`/sms-tag`)

**파일**: `lib/features/sms_tag/sms_tag_screen.dart`

```
필드:
  - 전화번호 (TextFormField, keyboardType: phone, 필수)
  - 메시지 내용 (TextFormField, maxLines:3, 선택)

'다음' → TagPayloadEncoder.sms(phone, message)
tagType: 'sms'
appName: 'SMS'
```

---

## 6. 라우터 변경 (router.dart)

추가할 라우트 상수 및 케이스:

```dart
// 상수
static const clipboardTag = '/clipboard-tag';
static const websiteTag   = '/website-tag';
static const contactTag   = '/contact-tag';
static const wifiTag      = '/wifi-tag';
static const locationTag  = '/location-tag';
static const eventTag     = '/event-tag';
static const emailTag     = '/email-tag';
static const smsTag       = '/sms-tag';

// onGenerateRoute case 추가
case clipboardTag: return MaterialPageRoute(builder: (_) => const ClipboardTagScreen());
case websiteTag:   return MaterialPageRoute(builder: (_) => const WebsiteTagScreen());
case contactTag:   return MaterialPageRoute(builder: (_) => const ContactTagScreen());
case wifiTag:      return MaterialPageRoute(builder: (_) => const WifiTagScreen());
case locationTag:  return MaterialPageRoute(builder: (_) => const LocationTagScreen());
case eventTag:     return MaterialPageRoute(builder: (_) => const EventTagScreen());
case emailTag:     return MaterialPageRoute(builder: (_) => const EmailTagScreen());
case smsTag:       return MaterialPageRoute(builder: (_) => const SmsTagScreen());
```

---

## 7. output-selector 변경사항

`tagType` arguments key 추가 수신 및 TagHistory 저장 시 전달:

현재 output-selector는 `appName`, `deepLink`, `platform`, `outputType`, `appIconBytes`만 사용.  
`tagType`은 QR/NFC 결과 화면(`qr_result_screen`, `nfc_writer_screen`)에서 TagHistory 저장 시 포함:

```dart
final history = TagHistory(
  ...
  tagType: args['tagType'] as String?,   // 신규 필드
);
```

---

## 8. 구현 파일 목록 (최종)

### 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/features/home/home_screen.dart` | 전면 재작성 |
| `lib/app/router.dart` | 8개 라우트 상수 + case 추가 |
| `lib/models/tag_history.dart` | `tagType` HiveField(11) 추가 |
| `lib/models/tag_history.g.dart` | build_runner 재생성 |
| `lib/features/qr_result/qr_result_screen.dart` | TagHistory 저장 시 tagType 추가 |
| `lib/features/nfc_writer/nfc_writer_screen.dart` | TagHistory 저장 시 tagType 추가 |

### 신규 파일

| 파일 | 역할 |
|------|------|
| `lib/shared/utils/tag_payload_encoder.dart` | 타입별 페이로드 인코더 |
| `lib/features/clipboard_tag/clipboard_tag_screen.dart` | 클립보드 화면 |
| `lib/features/website_tag/website_tag_screen.dart` | 웹 사이트 화면 |
| `lib/features/contact_tag/contact_tag_screen.dart` | 연락처 화면 |
| `lib/features/wifi_tag/wifi_tag_screen.dart` | WiFi 화면 |
| `lib/features/location_tag/location_tag_screen.dart` | 위치 화면 |
| `lib/features/event_tag/event_tag_screen.dart` | 이벤트/일정 화면 |
| `lib/features/email_tag/email_tag_screen.dart` | 이메일 화면 |
| `lib/features/sms_tag/sms_tag_screen.dart` | SMS 화면 |

---

## 9. 의존성

추가 패키지 없음. 기존 패키지로 모두 구현 가능:
- `flutter/services.dart` → `Clipboard`
- `url_launcher` → 위치 미리보기
- `hive_flutter` → TagHistory 저장
