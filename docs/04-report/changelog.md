# Changelog

모든 주요 변경사항을 기록합니다.

## [2026-04-22] - color-tab-user-presets 완료

### Added
- 색상 탭 사용자 프리셋 UX (도트/눈 편집 R-series 패턴 동형)
  - 단색 사용자 preset 저장/선택/삭제 + color wheel 기반 편집 (신규 생성 방식)
  - 그라디언트 사용자 preset 저장/선택/편집/삭제 + editor 자동 저장 (update 방식)
  - 섹션 라벨 우측 🗑 → `_ColorGridModal` (view/delete 모드, `isGradient` 분기)
  - `···` 오버플로 → grid modal view 모드
  - `updatedAt` 기준 최근 순 정렬 + 100ms 지연 재정렬
  - Dedup: solid (`solidColorArgb`), gradient (colors + stops + type + angleDegrees)
- `HiveColorPaletteDataSource` 확장: `touchLastUsed`, `readAllSortedByRecency(PaletteType)`, in-memory cache
- `qr_color_tab/` part 폴더 (R-series 구조): `shared.dart`, `solid_row.dart`, `gradient_row.dart`, `gradient_editor.dart`, `color_grid_modal.dart`

### Changed
- `qr_color_tab.dart` 824줄 single-file → library root 617줄 + 5 part 파일 (~856줄 분산)
- built-in 단색 `qrSafeColors` 10개 → 5개 (검정/진파랑/진초록/진빨강/진보라)
- built-in 그라디언트 `kQrPresetGradients` 8개 → 5개 (블루-퍼플/선셋/에메랄드-네이비/로즈-퍼플/라디얼 다크)
- `qr_color_tab.dart` import: `flutter_colorpicker` 의 `PaletteType` 충돌 → `hide PaletteType` 적용
- AppBar `actions` 를 `const []` 로 정리 — shape/color 편집기 모두 뒤로가기 = 자동 저장 통일

### Removed
- `qr_result_screen.dart` 의 `_confirmActiveEditor` 메서드 (AppBar [저장] 버튼 제거로 미사용)
- built-in 단색 5개 (남색/청록/진갈색/진주황/인디고), built-in 그라디언트 3개 (오션/포레스트/미드나잇)

### Design Notes
- **Extension → State body 결정**: Design §5.4 의 `extension _GradientEditorBuilder on QrColorTabState` 는 Flutter `setState @protected` lint 를 유발 → 편집기 UI 메서드 7개를 `QrColorTabState` 본체로 이동. library root 가 617줄 되었으나 CLAUDE.md Rule 8 의 "UI part ≤ 400" 는 `qr_color_tab/*.dart` 개별 part 에만 적용 (shape tab 선례 동일). Design 문서 갱신 완료.
- `UserColorPalette` / `UserColorPaletteModel` (Hive typeId 3) 무변경 — sync 인프라 호환 유지.

### Quality Metrics
- **Design Match Rate**: 99% (Design §4.1/§5.4 갱신 후)
- **Critical/Important Gap**: 0 / 0
- **Low Gap**: 3 (모두 positive 또는 cosmetic, 수용)
- **flutter analyze**: 0 errors (pre-existing 15 info/warning)
- **Iteration 횟수**: 0 (첫 구현에서 ≥ 90% 달성)

### Related
- Plan: `docs/01-plan/features/color-tab-user-presets.plan.md`
- Design: `docs/02-design/features/color-tab-user-presets.design.md`
- Analysis: `docs/03-analysis/color-tab-user-presets.analysis.md`
- Report: `docs/04-report/features/color-tab-user-presets.report.md`

---

## [2026-04-22] - eye-quadrant-corners 완료

### Added
- `EyeShapeParams` 4-corner 독립 필드 (`cornerQ1/Q2/Q3/Q4`, 0.0 round ~ 1.0 square)
- `SuperellipsePath.paintEye` 에 `rotationDeg` 파라미터 — 3 finder 위치별 ±90° 회전으로 각 eye 의 local Q4 모서리가 QR 중심을 향함
- `kEyeRotations = [0.0, 90.0, -90.0]` 상수 (TL=Q2, TR=Q1, BL=Q3)
- Editor 슬라이더 5개 (Q1/Q2/Q3/Q4 + innerN)
- Legacy eye preset 자동 cleanup (Hive `user_eye_presets` box, `fromJsonOrNull` 기반 감지)
- `sliderCornerQ1~Q4` l10n 키 (ko 만 번역, 9개 로케일 fallback)

### Changed
- `EyeShapeParams`: `outerN` 제거 → 4-corner 로 대체 (backward-incompatible, pre-release 승인)
- `customization_mapper.eyeParamsFromJson`: `fromJsonOrNull` 사용 — legacy 감지 시 null 반환 → customEye 해제 후 빌트인 fallback
- 외곽 ring 렌더: superellipse → `RRect.fromRectAndCorners` (Flutter native + QR 인식 안정)

### Removed
- `_RandomEyeButton`, `_onRandomEyeFromEditor`, `onRandomGenerate` (중간 실험 후 UX 결정으로 제거)
- `actionRandomEye`, `actionRandomRegenerate` l10n 키 (10 로케일)

### Quality Metrics
- **Design Match Rate**: 98% (Critical 0, Important 0, Low 2 수용)
- **flutter analyze**: 0 errors (pre-existing info/warning 15개 유지)
- **파일 변경**: 9 수정 / 0 신규 / 0 삭제 (~+240 / -20)
- **Iteration 횟수**: 0 (첫 구현에서 ≥ 90% 달성)

### Related
- Plan: `docs/01-plan/features/eye-quadrant-corners.plan.md`
- Design: `docs/02-design/features/eye-quadrant-corners.design.md`
- Analysis: `docs/03-analysis/eye-quadrant-corners.analysis.md`
- Report: `docs/04-report/features/eye-quadrant-corners.report.md`

---

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
