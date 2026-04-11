# Plan: 홈 화면 타일 메뉴 재설계

## Executive Summary

| 관점 | 내용 |
|------|------|
| Problem | 현재 홈 화면은 "앱 실행" 단일 기능만 제공하며, NFC/QR이 활용 가능한 다양한 유형(연락처, WiFi, 위치 등)에 접근할 방법이 없음 |
| Solution | 홈 화면을 2열 타일 그리드로 재설계하여 10가지 태그 유형을 직접 선택할 수 있게 하고, 각 유형별 입력 화면 → QR/NFC 출력 플로우 구현 |
| UX Effect | 앱 진입 즉시 원하는 기능을 선택할 수 있어 UX 깊이 감소, 각 유형에 최적화된 입력 폼으로 실수 방지 |
| Core Value | 앱 실행 태그를 넘어 실생활 전반(WiFi 공유, 명함, 일정, 결제 등)에 활용 가능한 범용 NFC/QR 생성 도구로 확장 |

---

## 요구사항

### 홈 화면 구조 변경

- AppBar: 좌측에 로컬 태그 아이콘(`Icons.nfc` 또는 커스텀) + 중앙 또는 기본 위치에 `"App Tag"` 텍스트
- Body: `GridView` 2열 타일 배열
- 기존 AppBar 우측 액션(도움말, 이력) 유지
- 현재 홈 화면의 중앙 로고/버튼 레이아웃 제거

### 타일 목록 (10종)

| # | 타일명 | 플랫폼 차이 | 기능 설명 | QR/NFC 포맷 |
|---|--------|------------|-----------|-------------|
| 1 | 앱 실행 (Android) / 단축키 (iOS) | Android/iOS 분기 | 기존 앱 피커 / iOS 단축어 입력 플로우 재사용 | `https://play.google.com/...` / `shortcuts://run-shortcut?name=...` |
| 2 | 클립보드 | 공통 | 현재 클립보드 내용 확인 후 QR/NFC 생성 | 텍스트 레코드 (plain text) |
| 3 | 웹 사이트 | 공통 | URL 입력 → 브라우저로 오픈 | URI 레코드 (`https://...`) |
| 4 | 연락처 | 공통 | 이름·전화번호·이메일 입력 → 연락처 앱으로 저장 | vCard 3.0 (`text/vcard` MIME) |
| 5 | WiFi | 공통 | SSID·암호화방식·비밀번호 입력 → WiFi 자동 연결 | `WIFI:T:WPA2;S:<ssid>;P:<pw>;;` |
| 6 | 위치 | 공통 | 위도·경도 입력(수동 또는 지도 선택) → Google Maps | `geo:<lat>,<lng>` 또는 Maps URL |
| 7 | 이벤트/일정 | 공통 | 이벤트 제목·일시·장소·설명 입력 → 캘린더 앱 | iCalendar (`text/calendar` MIME) |
| 8 | 이메일 | 공통 | 수신자·제목·내용 입력 → 이메일 앱 | `mailto:addr?subject=...&body=...` |
| 9 | SMS | 공통 | 전화번호·내용 입력 → 문자 앱 | `smsto:<number>:<message>` |

### 타일 공통 동작

- 타일 탭 → 각 유형 전용 입력 화면 이동
- 입력 화면에서 "다음" → `/output-selector` 로 이동 (QR 또는 NFC 선택)
- output-selector는 기존 구조 유지: `appName`(표시명), `deepLink`(인코딩된 페이로드), `platform`, `outputType` 전달
- 새 유형들은 `platform: 'universal'` 로 통일

### 각 입력 화면 상세

#### 클립보드 (`/clipboard-tag`)
- 진입 시 클립보드 내용 자동 읽기 (`Clipboard.getData`)
- 현재 클립보드 내용 표시 + 편집 가능 텍스트 필드 (Flutter는 단일 항목만 접근 가능)
- 빈 클립보드 시 "클립보드가 비어 있습니다" 안내 + 직접 입력 허용
- 페이로드: 텍스트 그대로 전달

#### 웹 사이트 (`/website-tag`)
- URL 입력 필드 (유효성: `http://` 또는 `https://` 시작, 또는 자동 보완)
- 페이로드: URL 문자열

#### 연락처 (`/contact-tag`)
- 이름 (필수), 전화번호, 이메일 입력 필드
- 페이로드: vCard 3.0 형식 문자열
  ```
  BEGIN:VCARD
  VERSION:3.0
  FN:<이름>
  TEL:<전화번호>
  EMAIL:<이메일>
  END:VCARD
  ```

#### WiFi (`/wifi-tag`)
- SSID (네트워크 이름, 필수), 암호화 방식 드롭다운 (WPA/WPA2/WEP/None), 비밀번호
- 페이로드: `WIFI:T:<type>;S:<ssid>;P:<password>;;`

#### 위치 (`/location-tag`)
- 위도·경도 수동 입력 텍스트 필드 (소수점 6자리까지)
- 선택 사항: 레이블(장소명) 입력
- 지도 앱 링크 미리보기 버튼 (url_launcher로 Google Maps 오픈)
- 페이로드: `geo:<lat>,<lng>` (레이블 있으면 Google Maps URL 사용)

#### 이벤트/일정 (`/event-tag`)
- 이벤트 제목 (필수), 시작일시, 종료일시, 장소(주소), 설명
- 날짜/시간 선택: `DatePicker` + `TimePicker`
- 페이로드: iCalendar 형식
  ```
  BEGIN:VCALENDAR
  VERSION:2.0
  BEGIN:VEVENT
  SUMMARY:<제목>
  DTSTART:<YYYYMMDDTHHmmss>
  DTEND:<YYYYMMDDTHHmmss>
  LOCATION:<장소>
  DESCRIPTION:<설명>
  END:VEVENT
  END:VCALENDAR
  ```

#### 이메일 (`/email-tag`)
- 이메일 주소 (필수), 제목, 메시지 본문 입력 필드
- 페이로드: `mailto:<addr>?subject=<encoded>&body=<encoded>`

#### SMS (`/sms-tag`)
- 전화번호 (필수), 내용 입력 필드
- 페이로드: `smsto:<number>:<message>`


---

## 구현 범위

### 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/features/home/home_screen.dart` | 전면 재작성 — AppBar + 2열 GridView 타일 |
| `lib/app/router.dart` | 새 9개 라우트 추가 |
| `lib/shared/constants/deep_link_constants.dart` | 새 유형별 페이로드 생성 메서드 추가 |

### 신규 파일

| 파일 | 역할 |
|------|------|
| `lib/features/clipboard_tag/clipboard_tag_screen.dart` | 클립보드 확인 및 편집 화면 |
| `lib/features/website_tag/website_tag_screen.dart` | URL 입력 화면 |
| `lib/features/contact_tag/contact_tag_screen.dart` | 연락처 입력 화면 |
| `lib/features/wifi_tag/wifi_tag_screen.dart` | WiFi 정보 입력 화면 |
| `lib/features/location_tag/location_tag_screen.dart` | 위도/경도 입력 화면 |
| `lib/features/event_tag/event_tag_screen.dart` | 이벤트/일정 입력 화면 |
| `lib/features/email_tag/email_tag_screen.dart` | 이메일 입력 화면 |
| `lib/features/sms_tag/sms_tag_screen.dart` | SMS 입력 화면 |
| `lib/features/bank_tag/bank_tag_screen.dart` | 은행 계좌번호 입력 화면 |

### 라우트 추가 (router.dart)

```
/clipboard-tag  → ClipboardTagScreen
/website-tag    → WebsiteTagScreen
/contact-tag    → ContactTagScreen
/wifi-tag       → WifiTagScreen
/location-tag   → LocationTagScreen
/event-tag      → EventTagScreen
/email-tag      → EmailTagScreen
/sms-tag        → SmsTagScreen
/bank-tag       → BankTagScreen
```

### output-selector 연결 공통 인터페이스

모든 새 화면에서 output-selector로 이동 시 전달하는 arguments:

```dart
{
  'appName': '<타입별 표시명>',   // 예: '연락처', 'WiFi', ...
  'deepLink': '<인코딩된 페이로드>',
  'platform': 'universal',
  'outputType': 'qr',           // 기본값, output-selector에서 변경 가능
  'appIconBytes': null,
}
```

---

## 데이터 흐름

```
홈 화면 (타일 선택)
    ↓
각 유형 입력 화면
    ↓  (입력 완료 후 "다음")
/output-selector (QR / NFC 선택)
    ↓ QR 선택         ↓ NFC 선택
/qr-result         /nfc-writer
```

---

## 비기능 요구사항

- 기존 "앱 실행" 플로우는 동작 변경 없이 타일 진입점만 변경
- 새 입력 화면들은 기존 화면들과 동일한 디자인 언어(OutlineInputBorder, ElevatedButton) 사용
- `TagHistory` 모델에 `tagType` 필드 추가 고려 (이력 화면에서 유형 구분 표시)
- 외부 패키지 최소 추가 원칙 — 클립보드는 Flutter 기본 `Clipboard`, 위치는 수동 입력 우선

---

## 미결 사항

- **위치 타일**: Google Maps API 연동 vs 수동 위도/경도 입력 — 패키지 의존성 최소화를 위해 수동 입력 우선 채택, 지도 선택은 차후 고려
- **TagHistory tagType 필드**: HiveField 11 추가 여부는 Design 단계에서 결정
- **은행 목록**: 하드코딩 드롭다운 vs 직접 입력 텍스트 필드 — Design 단계 결정
