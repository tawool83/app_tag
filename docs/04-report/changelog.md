# Changelog

모든 주요 변경사항을 기록합니다.

## [2026-04-21] - QrResultNotifier 분할 리팩터 완료 (R-Series 종료)

### Changed
- **QrResultNotifier 모놀리식 구조 해체**: 576줄 god-class를 part of + mixin 패턴으로 분할
  - 메인 파일 (`qr_result_provider.dart`): 576 → 234줄 (59% 축소, lifecycle 전용)
  - 5개 mixin 파일 (`notifier/` 아래): action/style/logo/template/meta 관심사별 분리
  - 각 mixin: 29~109줄 (목표 ≤150 달성)

- **파일 탐색성 극대화**: 
  - 스타일 setter 수정 시 `style_setters.dart` (109줄)만 로드 (원본 576줄 → 19% 축소)
  - IDE outline: mixin당 4~13 항목 (원본 40개 → 5배 정리)
  - Grep 노이즈 제거: `void set` 검색 시 관련 결과만 표시

### Design
- **구조**: Dart `part of` + `mixin on StateNotifier<QrResultState>`
  - Lifecycle methods (ctor, setCurrentTaskId, loadFromCustomization, _schedulePush, dispose)는 main 유지
  - 40개 setter → 5개 mixin 파일로 위임 (public API 100% 유지)
  - Private 멤버 (_ref, _suppressPush, _debounceTimer) part of로 직접 접근

### Quality Metrics
- **Design Match Rate**: 95.5% (10/11 FRs @ 100%, 1 FR @50% justified overrun)
- **FR-03 미달 분석**: main 234줄 (목표 ≤200, +34줄)
  - Root cause: `loadFromCustomization` + `_rehydrateLogoAssetIfNeeded`의 원자성 필요 (분할 불가)
  - 수용 사유: NFR-02 (파일 탐색성) 주목표 완전 달성, 234줄은 context window 수용 가능
  - 향후: lifecycle helper 클래스 도입으로 해소 가능 (지금은 권고 안 함)

- **Flutter analyze**: 0 errors
- **외부 마이그레이션**: 0줄 (mixin auto-inherit, public API 불변)
- **Hive 스키마**: 불변

### R-Series 시리즈 종료
1. **R1** (qr_shape_tab split): Shape 로직 분리
2. **R2** (QrResultState composite): Sub-state 토폴로지
3. **R3** (qr_result_screen split): Screen 컴포저빌리티
4. **R4** (SettingsService cache): Persistence 성능
5. **R5** (refactor-qr-notifier-split): Setter 국소성

**시리즈 성과**: 699줄 monolithic provider → 234줄 main + 5 mixin + R2's 5 sub-state 구조 (Clean Architecture)

---

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
