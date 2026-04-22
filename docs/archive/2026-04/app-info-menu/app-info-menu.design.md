# app-info-menu Design Document

> **Summary**: Drawer 하단에 "프로그램 정보" 메뉴 추가 — 앱 버전, 템플릿 엔진/스키마 버전 표시
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Author**: Claude
> **Date**: 2026-04-23
> **Status**: Draft
> **Planning Doc**: [app-info-menu.plan.md](../01-plan/features/app-info-menu.plan.md)

---

## 1. Overview

### 1.1 Design Goals

- Drawer에 "프로그램 정보" 메뉴 항목 1개 추가
- 탭 시 `showAboutDialog`로 앱 메타 정보 표시
- `package_info_plus`로 런타임 앱 버전/빌드 번호 조회
- 별도 feature 디렉터리 불필요 (trivial scope: UI 추가만, state/provider 없음)

### 1.2 Design Principles

- 최소 변경: `home_screen.dart`의 `_buildDrawer()` 메서드에만 코드 추가
- Flutter 내장 `showAboutDialog` 활용 — 라이선스 페이지 자동 연결
- `kTemplateEngineVersion` 중복 제거 (app_config.dart vs template_engine_version.dart)

---

## 2. Architecture

### 2.1 변경 범위

이 기능은 **새 파일 0개**, 기존 파일 수정만으로 완성됨.

```
lib/
├── features/home/
│   └── home_screen.dart              # _buildDrawer()에 ListTile + 다이얼로그 메서드 추가
├── core/constants/
│   └── app_config.dart               # kTemplateEngineVersion 중복 제거
├── l10n/
│   └── app_ko.arb                    # 4개 문자열 추가
└── (pubspec.yaml)                    # package_info_plus 의존성 추가
```

### 2.2 데이터 흐름

```
사용자 Drawer 열기
  → "프로그램 정보" ListTile 탭
    → _showAppInfoDialog() 호출
      → PackageInfo.fromPlatform() (async, 최초 1회)
      → showAboutDialog(
          applicationName: l10n.appTitle,
          applicationVersion: packageInfo.version,
          children: [버전 정보 위젯들]
        )
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| `_showAppInfoDialog()` | `package_info_plus` | 런타임 앱 버전/빌드 번호 조회 |
| `_showAppInfoDialog()` | `template_engine_version.dart` | kTemplateEngineVersion, kTemplateSchemaVersion 상수 |
| `_showAppInfoDialog()` | `app_ko.arb` | l10n 문자열 |

---

## 3. UI/UX Design

### 3.1 Drawer 레이아웃 (변경 후)

```
┌────────────────────────────────┐
│  DrawerHeader                  │
│    logo.png + appTitle         │
├────────────────────────────────┤
│  [settings_outlined] 설정      │  ← 기존
│  [info_outline] 프로그램 정보   │  ← 신규 (FR-01)
│                                │
│                                │
│  ── Spacer ──                  │
│                                │
│  v1.0.0 (빌드 1)              │  ← 하단 버전 텍스트 (FR-02 보조)
└────────────────────────────────┘
```

### 3.2 AboutDialog 내용

```
┌─────────────────────────────────────┐
│  [logo.png 64x64]                   │
│  QR, NFC 생성기                      │
│  버전 1.0.0 (빌드 1)                │
│                                     │
│  ─────────────────────────          │
│  템플릿 엔진 v2                      │  ← FR-03
│  템플릿 스키마 v2                    │  ← FR-04
│  ─────────────────────────          │
│                                     │
│  [라이선스 보기]  [닫기]              │  ← showAboutDialog 내장
└─────────────────────────────────────┘
```

### 3.3 User Flow

```
홈 → 햄버거 메뉴(Drawer) 열기 → "프로그램 정보" 탭 → AboutDialog 표시 → 닫기
                                                    └→ "라이선스 보기" → LicensePage
```

---

## 4. 상세 구현 명세

### 4.1 home_screen.dart 변경

#### 4.1.1 import 추가

```dart
import 'package:package_info_plus/package_info_plus.dart';
import '../../features/qr_result/domain/entities/template_engine_version.dart';
```

#### 4.1.2 `_buildDrawer()` 수정 — ListTile 추가

기존 설정 ListTile 아래에 "프로그램 정보" ListTile 추가:

```dart
Widget _buildDrawer() {
  final l10n = AppLocalizations.of(context)!;
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(...),  // 기존 유지
        ListTile(           // 기존: 설정
          leading: const Icon(Icons.settings_outlined),
          title: Text(l10n.screenSettingsTitle),
          onTap: () { Navigator.pop(context); context.push('/settings'); },
        ),
        ListTile(           // 신규: 프로그램 정보
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.drawerAppInfo),
          onTap: () { Navigator.pop(context); _showAppInfoDialog(); },
        ),
      ],
    ),
  );
}
```

#### 4.1.3 `_showAppInfoDialog()` 메서드

```dart
Future<void> _showAppInfoDialog() async {
  final info = await PackageInfo.fromPlatform();
  if (!mounted) return;
  final l10n = AppLocalizations.of(context)!;
  showAboutDialog(
    context: context,
    applicationName: l10n.appTitle,
    applicationVersion: '${info.version} (${l10n.appInfoBuild} ${info.buildNumber})',
    applicationIcon: Image.asset('assets/img/logo.png', width: 64, height: 64),
    children: [
      const SizedBox(height: 16),
      Text('${l10n.appInfoTemplateEngine} v$kTemplateEngineVersion'),
      const SizedBox(height: 4),
      Text('${l10n.appInfoTemplateSchema} v$kTemplateSchemaVersion'),
    ],
  );
}
```

**주의**: `kTemplateEngineVersion`과 `kTemplateSchemaVersion`은 `template_engine_version.dart`에서 import. `app_config.dart`의 중복 상수는 제거.

### 4.2 app_config.dart 변경 — 중복 제거

`app_config.dart`에서 `kTemplateEngineVersion` 상수(값=1, 오래된 값)를 **삭제**. 정본은 `template_engine_version.dart`(값=2).

기존 `app_config.dart`에서 `kTemplateEngineVersion`을 참조하는 코드가 있으면 `template_engine_version.dart`로 import 변경.

### 4.3 l10n 문자열 (app_ko.arb)

```json
"drawerAppInfo": "프로그램 정보",
"appInfoBuild": "빌드",
"appInfoTemplateEngine": "템플릿 엔진",
"appInfoTemplateSchema": "템플릿 스키마"
```

4개 키 추가. 다른 언어 파일은 ko fallback.

### 4.4 pubspec.yaml 의존성

```yaml
dependencies:
  package_info_plus: ^8.0.0
```

추가 후 `flutter pub get` 실행.

---

## 5. kTemplateEngineVersion 중복 정리

| 파일 | 현재 값 | 조치 |
|------|---------|------|
| `lib/core/constants/app_config.dart` | `kTemplateEngineVersion = 1` | **삭제** |
| `lib/features/qr_result/domain/entities/template_engine_version.dart` | `kTemplateEngineVersion = 2` | **정본 유지** |

`app_config.dart`에서 이 상수를 import하는 파일이 있으면 `template_engine_version.dart`로 전환.

---

## 6. Error Handling

| 시나리오 | 처리 |
|----------|------|
| `PackageInfo.fromPlatform()` 실패 | 실질적으로 발생하지 않음 (Flutter 내장 API). 만일 실패 시 mounted 체크로 안전 종료 |
| Drawer 닫힘 상태에서 다이얼로그 | `Navigator.pop(context)` 후 `_showAppInfoDialog()` 호출이므로 Drawer 닫힌 후 표시 |

---

## 7. Test Plan

| Type | Target | Method |
|------|--------|--------|
| 수동 QA | Drawer에서 "프로그램 정보" 탭 → 다이얼로그 표시 확인 | 디바이스 실행 |
| 수동 QA | 버전 정보 올바른 값 표시 (1.0.0, 빌드 1, 엔진 v2, 스키마 v2) | 디바이스 실행 |
| 수동 QA | "라이선스 보기" 탭 → LicensePage 표시 | 디바이스 실행 |
| 빌드 검증 | `flutter build apk --debug` / `flutter build ios --no-codesign` | CI/로컬 |

---

## 8. Implementation Order

1. [ ] `pubspec.yaml` — `package_info_plus` 의존성 추가 + `flutter pub get`
2. [ ] `app_config.dart` — `kTemplateEngineVersion` 중복 상수 삭제 + import 전환
3. [ ] `app_ko.arb` — 4개 l10n 문자열 추가 + `flutter gen-l10n`
4. [ ] `home_screen.dart` — `_buildDrawer()`에 ListTile 추가 + `_showAppInfoDialog()` 메서드 추가
5. [ ] 빌드 확인

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-23 | Initial draft | Claude |
