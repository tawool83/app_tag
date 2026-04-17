---
template: design
version: 1.2
feature: app-branding
date: 2026-04-17
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# app-branding Design Document

> **Summary**: assets/img/logo.png를 앱 아이콘, 스플래시 화면, HomeScreen AppBar에 적용하는 단일 설계안.
>
> **Planning Doc**: [app-branding.plan.md](../../01-plan/features/app-branding.plan.md)

---

## 1. 구현 순서

| Step | 작업 | 파일 | 비고 |
|:----:|------|------|------|
| S1 | pubspec.yaml에 assets/img/ 등록 | `pubspec.yaml` | assets 경로 추가 |
| S2 | flutter_launcher_icons 설정 + 실행 | `pubspec.yaml` | dev_dependencies 추가, 아이콘 생성 |
| S3 | flutter_native_splash 설정 + 실행 | `pubspec.yaml` | dev_dependencies 추가, 스플래시 생성 |
| S4 | HomeScreen AppBar leading 교체 | `lib/features/home/home_screen.dart` | QR/NFC 아이콘 → logo.png Image |
| S5 | 편집 모드 AppBar leading도 교체 | `lib/features/home/home_screen.dart` | NFC 아이콘 → logo.png |

---

## 2. 상세 설계

### S1. pubspec.yaml assets 등록

```yaml
assets:
  - assets/default_templates.json
  - assets/img/             # 추가
```

### S2. flutter_launcher_icons

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.3

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/img/logo.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/img/logo.png"
```

실행: `dart run flutter_launcher_icons`

### S3. flutter_native_splash

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.6

flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/img/logo.png"
  android_12:
    image: "assets/img/logo.png"
    color: "#FFFFFF"
```

실행: `dart run flutter_native_splash:create`

### S4. HomeScreen AppBar leading 교체

**Before:**
```dart
leading: const Padding(
  padding: EdgeInsets.only(left: 12),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.qr_code),
      SizedBox(width: 4),
      Icon(Icons.nfc),
    ],
  ),
),
```

**After:**
```dart
leading: Padding(
  padding: const EdgeInsets.only(left: 12),
  child: Image.asset('assets/img/logo.png'),
),
```

### S5. 편집 모드 AppBar leading도 교체

**Before:**
```dart
leading: const Padding(
  padding: EdgeInsets.only(left: 16),
  child: Icon(Icons.nfc),
),
```

**After:**
```dart
leading: Padding(
  padding: const EdgeInsets.only(left: 16),
  child: Image.asset('assets/img/logo.png', width: 32),
),
```

---

## 3. 검증 기준

| # | 항목 | 방법 |
|---|------|------|
| 1 | Android 앱 아이콘이 logo.png 기반 | 빌드 후 런처 확인 |
| 2 | iOS 앱 아이콘이 logo.png 기반 | 빌드 후 홈화면 확인 |
| 3 | 스플래시 화면에 로고 표시 | cold start 확인 |
| 4 | HomeScreen AppBar에 로고 이미지 | 앱 실행 확인 |
| 5 | 편집 모드에서도 로고 이미지 | 타일 길게 눌러 확인 |
| 6 | flutter analyze 에러 0 | CLI 확인 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-17 | Initial design | tawool83 |
