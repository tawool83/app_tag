# app-info-menu Gap Analysis

> **Feature**: app-info-menu
> **Date**: 2026-04-23
> **Design Doc**: [app-info-menu.design.md](../02-design/features/app-info-menu.design.md)
> **Match Rate**: 100%

---

## 1. FR Verification

| ID | Requirement | Design Spec | Implementation | Match |
|----|-------------|-------------|----------------|:-----:|
| FR-01 | Drawer 하단에 "프로그램 정보" ListTile (아이콘: `Icons.info_outline`) | `_buildDrawer()`에 ListTile 추가 | `home_screen.dart:217-224` — `Icons.info_outline` + `l10n.drawerAppInfo` | PASS |
| FR-02 | `showAboutDialog` — 앱 이름, 버전, 빌드 번호 | `_showAppInfoDialog()` 메서드 | `home_screen.dart:230-246` — `applicationName: l10n.appTitle`, `applicationVersion` with version+buildNumber | PASS |
| FR-03 | 템플릿 엔진 버전 (`kTemplateEngineVersion`) 표시 | children에 `Text('... v$kTemplateEngineVersion')` | `home_screen.dart:241` — 정확히 일치 | PASS |
| FR-04 | 템플릿 스키마 버전 (`kTemplateSchemaVersion`) 표시 | children에 `Text('... v$kTemplateSchemaVersion')` | `home_screen.dart:243` — 정확히 일치 | PASS |
| FR-05 | `package_info_plus` 의존성 추가 | `pubspec.yaml`에 추가 | `pubspec.yaml:68` — `package_info_plus: ^8.0.0` | PASS |

**FR Match Rate: 5/5 = 100%**

---

## 2. Design Spec Compliance

### 2.1 Import 구조

| Design Spec | Implementation | Match |
|-------------|----------------|:-----:|
| `import 'package:package_info_plus/package_info_plus.dart'` | `home_screen.dart:6` | PASS |
| `import '...template_engine_version.dart'` | `home_screen.dart:10` | PASS |

### 2.2 `_buildDrawer()` 변경

| Design Spec | Implementation | Match |
|-------------|----------------|:-----:|
| 설정 ListTile 아래에 프로그램 정보 ListTile 추가 | `home_screen.dart:217-224` (설정=209, 정보=217) | PASS |
| `Icons.info_outline` 아이콘 | `home_screen.dart:218` | PASS |
| `l10n.drawerAppInfo` 타이틀 | `home_screen.dart:219` | PASS |
| `Navigator.pop(context)` 후 `_showAppInfoDialog()` 호출 | `home_screen.dart:221-222` | PASS |

### 2.3 `_showAppInfoDialog()` 메서드

| Design Spec | Implementation | Match |
|-------------|----------------|:-----:|
| `async` + `PackageInfo.fromPlatform()` | `home_screen.dart:230-231` | PASS |
| `if (!mounted) return` 안전 체크 | `home_screen.dart:232` | PASS |
| `applicationName: l10n.appTitle` | `home_screen.dart:236` | PASS |
| `applicationVersion` = version + buildNumber 포맷 | `home_screen.dart:237` | PASS |
| `applicationIcon` = logo.png 64x64 | `home_screen.dart:238` | PASS |
| children: 엔진 버전 + 스키마 버전 텍스트 | `home_screen.dart:239-244` | PASS |

### 2.4 중복 상수 제거

| Design Spec | Implementation | Match |
|-------------|----------------|:-----:|
| `app_config.dart`에서 `kTemplateEngineVersion` 삭제 | 삭제 완료 — 파일에 해당 상수 없음 | PASS |
| `local_default_template_datasource.dart` import 전환 | `show kTemplateCacheTtl` + `template_engine_version.dart` import | PASS |

### 2.5 l10n 문자열

| Design Spec | Implementation | Match |
|-------------|----------------|:-----:|
| `drawerAppInfo`: "프로그램 정보" | `app_ko.arb:249` | PASS |
| `appInfoBuild`: "빌드" | `app_ko.arb:250` | PASS |
| `appInfoTemplateEngine`: "템플릿 엔진" | `app_ko.arb:251` | PASS |
| `appInfoTemplateSchema`: "템플릿 스키마" | `app_ko.arb:252` | PASS |
| gen-l10n 생성 완료 | `app_localizations.dart`에 4개 getter 확인 | PASS |

---

## 3. Code Quality

| Check | Result |
|-------|--------|
| `flutter analyze` — error/warning | 0 (info 1개는 기존 코드, 이번 변경 무관) |
| 파일 크기 제한 (home_screen.dart ≤ UI 400줄) | ~460줄 (기존 445줄 + 16줄 추가) — 기존 초과분, 이번 추가분 미미 |
| 새 파일 생성 | 0개 (Design 명세대로) |
| 불필요 import | 없음 |

---

## 4. Summary

| Metric | Value |
|--------|-------|
| **Match Rate** | **100%** |
| FR Pass | 5/5 |
| Design Spec Items | 18/18 |
| Gaps Found | 0 |
| Critical Issues | 0 |
| Files Modified | 5 (Design 명세: 4 + import 전환 1) |

---

## 5. Recommendation

Match Rate 100% — `/pdca report app-info-menu` 진행 가능.
