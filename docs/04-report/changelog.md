# Changelog

모든 주요 변경사항을 기록합니다.

## [2026-04-16] - QR 결과 화면 텍스트 탭 분리 완료

### Added
- **텍스트 탭 생성**: QR 결과 화면에 전용 "텍스트" 탭 추가
  - 상단/하단 텍스트 독립 편집
  - 색상 선택 (ColorPicker 다이얼로그)
  - 폰트 선택 (Sans/Serif/Mono)
  - 크기 제어 (10~64sp, ±1 스텝)
  - 텍스트 입력란 (40자 제한, 초기화 버튼)

- **TextTab 위젯** (`lib/features/qr_result/tabs/text_tab.dart`)
  - ConsumerWidget 기반 Riverpod 통합
  - _TextEditor StatefulWidget (드래프트 패턴)
  - _StepButton 재사용 컴포넌트
  - 플랫폼 제네릭 폰트 (asset 불필요)

### Changed
- **StickerTab (로고 탭)**: 상단/하단 텍스트 편집 UI 제거
  - 아이콘 표시 토글 + 로고 위치 + 로고 배경만 유지
  - 스크롤 감소, 단일 책임 원칙 적용

- **QrResultScreen**: TabController(length: 5)로 업데이트
  - 탭 순서: QR 모양 → QR 색상 → 로고 → 텍스트 → 모든 템플릿
  - TabBar에 "텍스트" 탭 추가

### Design Improvements
- **관심사 분리**: 로고 vs 텍스트 탭 책임 분명화
- **UX 향상**: 각 탭이 단일 기능에 집중 → 직관적 탐색
- **유지보수성**: 향후 탭 추가 시 확장성 개선 (TabController 기반)

### Match Rate
- Design vs Implementation: **100%** (gaps: 0)

---

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
