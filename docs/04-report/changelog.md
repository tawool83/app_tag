# Changelog

모든 주요 변경사항을 기록합니다.

## [2026-04-11] - 홈 화면 타일 메뉴 재설계 완료

### Added
- **홈 화면 UI 전면 재설계**: 2열 GridView 타일 메뉴 (9종 태그 유형)
  - 앱 실행 (Android) / 단축키 (iOS)
  - 클립보드, 웹 사이트, 연락처, WiFi, 위치, 이벤트/일정, 이메일, SMS
  
- **TagPayloadEncoder 유틸리티**: 타입별 QR/NFC 페이로드 생성 표준화
  - `clipboard(text)` → 텍스트 그대로
  - `website(url)` → https:// 자동 보완
  - `contact(name, phone, email)` → vCard 3.0
  - `wifi(ssid, securityType, password)` → WIFI URI
  - `location(lat, lng, label)` → geo: 또는 Google Maps URL
  - `event(title, start, end, location, description)` → iCalendar
  - `email(address, subject, body)` → mailto: URI
  - `sms(phone, message)` → smsto: URI

- **8개 신규 입력 화면**
  - ClipboardTagScreen (`/clipboard-tag`) — 클립보드 내용 확인 및 편집
  - WebsiteTagScreen (`/website-tag`) — URL 입력 + 유효성검사
  - ContactTagScreen (`/contact-tag`) — 이름·전화·이메일 입력
  - WifiTagScreen (`/wifi-tag`) — SSID·보안방식·비밀번호 입력
  - LocationTagScreen (`/location-tag`) — 위도·경도·장소명 입력
  - EventTagScreen (`/event-tag`) — 제목·시작/종료·장소·설명 입력
  - EmailTagScreen (`/email-tag`) — 주소·제목·본문 입력
  - SmsTagScreen (`/sms-tag`) — 전화번호·메시지 입력

- **데이터 모델 확장**: TagHistory에 tagType 필드 추가 (HiveField 11)
  - 이력 화면에서 태그 유형별 필터링/통계 기반 마련

- **라우터 업데이트**: 8개 신규 라우트 상수 및 case 추가

### Changed
- **홈 화면 아키텍처**: 중앙 로고/버튼 → GridView 2열 타일 메뉴
- **AppBar UI**: 좌측 NFC 아이콘 추가, 제목에 BitcountGridDouble 폰트 적용

### Fixed
- (없음 — 99% Match Rate, 설계/구현 일치)

### Performance
- 외부 패키지 최소화 (클립보드는 Flutter 기본, 위치는 수동 입력)
- TagPayloadEncoder 순수 함수로 메모리 효율성 확보

---

## 버전 관리

| 버전 | 날짜 | 기능 | Match Rate |
|------|------|------|:----------:|
| 1.0 (home-tile-menu) | 2026-04-11 | 9종 타일 메뉴 + TagPayloadEncoder | 99% |

---

**최종 업데이트**: 2026-04-11
