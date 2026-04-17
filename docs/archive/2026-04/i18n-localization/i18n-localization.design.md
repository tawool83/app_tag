---
template: design
version: 1.2
feature: i18n-localization
date: 2026-04-17
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# i18n-localization Design Document

> **Summary**: Flutter 공식 i18n (flutter_localizations + intl + ARB) 기반 10개 언어 지원 + 설정 화면 언어 선택.
>
> **Planning Doc**: [i18n-localization.plan.md](../../01-plan/features/i18n-localization.plan.md)

---

## 1. 구현 순서

| Phase | 작업 | 신규 파일 | 수정 파일 |
|:-----:|------|----------|----------|
| P1 | i18n 인프라 설정 | `l10n.yaml` | `pubspec.yaml` |
| P2 | 한국어 ARB 템플릿 작성 | `lib/l10n/app_ko.arb` | - |
| P3 | 영어 ARB 작성 | `lib/l10n/app_en.arb` | - |
| P4 | 나머지 8개 언어 ARB | `lib/l10n/app_{ja,zh,es,fr,de,pt,vi,th}.arb` | - |
| P5 | Locale 상태 관리 | `lib/core/providers/locale_provider.dart` | - |
| P6 | MaterialApp에 localization 연결 | - | `lib/app/app.dart` |
| P7 | 전체 화면 하드코딩 → AppLocalizations 교체 | - | 25+ 파일 |
| P8 | 설정 화면 생성 + 라우터 등록 | `lib/features/settings/settings_screen.dart` | `lib/core/di/router.dart` |
| P9 | HomeScreen AppBar 설정 아이콘 추가 | - | `lib/features/home/home_screen.dart` |

---

## 2. 아키텍처

### 2.1 파일 구조

```
lib/
├── l10n/                              # ARB 번역 파일 (10개)
│   ├── app_ko.arb                     # 한국어 (템플릿)
│   ├── app_en.arb                     # 영어 (fallback)
│   ├── app_ja.arb                     # 일본어
│   ├── app_zh.arb                     # 중국어
│   ├── app_es.arb                     # 스페인어
│   ├── app_fr.arb                     # 프랑스어
│   ├── app_de.arb                     # 독일어
│   ├── app_pt.arb                     # 포르투갈어
│   ├── app_vi.arb                     # 베트남어
│   └── app_th.arb                     # 태국어
├── core/
│   └── providers/
│       └── locale_provider.dart       # Riverpod locale 상태 관리
├── features/
│   └── settings/
│       └── settings_screen.dart       # 언어 선택 UI
└── app/
    └── app.dart                       # localization delegates 연결
```

### 2.2 l10n.yaml

```yaml
arb-dir: lib/l10n
template-arb-file: app_ko.arb
output-localization-file: app_localizations.dart
```

### 2.3 pubspec.yaml 변경

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

---

## 3. Locale 상태 관리

### 3.1 LocaleProvider

```dart
// lib/core/providers/locale_provider.dart

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final saved = await SettingsService.getLocale();
    state = saved; // null = 시스템 기본
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await SettingsService.saveLocale(locale);
  }
}
```

### 3.2 SettingsService 확장

```dart
// core/services/settings_service.dart에 추가
static Future<Locale?> getLocale() async {
  final code = prefs.getString('app_locale');
  return code != null ? Locale(code) : null;
}

static Future<void> saveLocale(Locale? locale) async {
  if (locale == null) {
    await prefs.remove('app_locale');
  } else {
    await prefs.setString('app_locale', locale.languageCode);
  }
}
```

### 3.3 MaterialApp 연결

```dart
// lib/app/app.dart
class AppTagApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      locale: locale,  // null이면 시스템 기본
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
      ...
    );
  }
}
```

---

## 4. ARB 키 네이밍 규칙

| 패턴 | 예시 | 용도 |
|------|------|------|
| `screen_{화면}_{요소}` | `screen_home_title` | 화면별 UI 텍스트 |
| `action_{동작}` | `action_save`, `action_cancel` | 공통 버튼 |
| `dialog_{다이얼로그}_{요소}` | `dialog_delete_title` | 다이얼로그 |
| `tab_{탭이름}` | `tab_template`, `tab_shape` | 탭 라벨 |
| `tile_{타일}` | `tile_clipboard`, `tile_wifi` | 홈 타일 라벨 |
| `msg_{메시지}` | `msg_no_history` | 안내 메시지 |

### 4.1 ARB 예시 (app_ko.arb)

```json
{
  "@@locale": "ko",
  "appTitle": "QR, NFC 생성기",
  "screen_home_title": "QR, NFC 생성기",
  "tile_app": "앱 실행",
  "tile_shortcut": "단축어",
  "tile_clipboard": "클립보드",
  "tile_website": "웹 사이트",
  "tile_contact": "연락처",
  "tile_wifi": "WiFi",
  "tile_location": "위치",
  "tile_event": "이벤트/일정",
  "tile_email": "이메일",
  "tile_sms": "SMS",
  "action_save": "저장",
  "action_cancel": "취소",
  "action_delete": "삭제",
  "action_share": "공유",
  "action_done": "완료",
  "action_retry": "다시 시도",
  "screen_qr_title": "QR 코드",
  "screen_nfc_title": "NFC 기록",
  "screen_history_title": "생성 이력",
  "screen_help_title": "사용 안내",
  "screen_settings_title": "설정",
  "settings_language": "언어",
  "settings_language_system": "시스템 기본",
  "msg_no_history": "이력이 없습니다.",
  "msg_delete_all": "모든 이력을 삭제하시겠습니까?",
  "splash_tagline": "자신만의 QR 을 만들고 꾸미세요"
}
```

---

## 5. 설정 화면 UI

### 5.1 와이어프레임

```
┌──────────────────────────────────────┐
│ ←  설정                              │
├──────────────────────────────────────┤
│                                      │
│  언어                                │
│  ┌──────────────────────────────┐   │
│  │ ○ 시스템 기본                 │   │
│  │ ● 한국어                      │   │
│  │ ○ English                    │   │
│  │ ○ 日本語                      │   │
│  │ ○ 中文(简体)                  │   │
│  │ ○ Español                    │   │
│  │ ○ Français                   │   │
│  │ ○ Deutsch                    │   │
│  │ ○ Português                  │   │
│  │ ○ Tiếng Việt                 │   │
│  │ ○ ภาษาไทย                    │   │
│  └──────────────────────────────┘   │
│                                      │
└──────────────────────────────────────┘
```

### 5.2 언어 목록 데이터

```dart
const kSupportedLanguages = [
  (locale: null,         label: 'settings_language_system', nativeName: null),
  (locale: Locale('ko'), label: 'Korean',    nativeName: '한국어'),
  (locale: Locale('en'), label: 'English',   nativeName: 'English'),
  (locale: Locale('ja'), label: 'Japanese',  nativeName: '日本語'),
  (locale: Locale('zh'), label: 'Chinese',   nativeName: '中文(简体)'),
  (locale: Locale('es'), label: 'Spanish',   nativeName: 'Español'),
  (locale: Locale('fr'), label: 'French',    nativeName: 'Français'),
  (locale: Locale('de'), label: 'German',    nativeName: 'Deutsch'),
  (locale: Locale('pt'), label: 'Portuguese',nativeName: 'Português'),
  (locale: Locale('vi'), label: 'Vietnamese',nativeName: 'Tiếng Việt'),
  (locale: Locale('th'), label: 'Thai',      nativeName: 'ภาษาไทย'),
];
```

### 5.3 HomeScreen AppBar 설정 아이콘

```dart
// 기존 help 아이콘 앞에 추가
actions: [
  IconButton(
    icon: const Icon(Icons.settings_outlined),
    tooltip: AppLocalizations.of(context)!.screen_settings_title,
    onPressed: () => context.push('/settings'),
  ),
  IconButton(
    icon: const Icon(Icons.help_outline),
    ...
  ),
],
```

---

## 6. 사용 패턴

### 6.1 화면에서 번역 사용

```dart
// Before (하드코딩)
Text('QR 코드')

// After (i18n)
Text(AppLocalizations.of(context)!.screen_qr_title)
```

### 6.2 축약 extension (선택)

```dart
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// 사용
Text(context.l10n.screen_qr_title)
```

---

## 7. 검증 기준

| # | 항목 | 방법 |
|---|------|------|
| 1 | `flutter gen-l10n` 경고 0 | CLI 확인 |
| 2 | 에뮬레이터 영어 → 앱 영어 표시 | 시스템 언어 변경 |
| 3 | 설정에서 일본어 선택 → 즉시 전환 | UI 확인 |
| 4 | 앱 재시작 후 선택 언어 유지 | SharedPreferences |
| 5 | "시스템 기본" 선택 → 시스템 언어 복귀 | 확인 |
| 6 | 10개 ARB 파일 모든 키 존재 | gen-l10n 체크 |
| 7 | dart analyze 에러 0 | CLI 확인 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-17 | Initial design | tawool83 |
