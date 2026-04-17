---
template: plan
version: 1.2
feature: app-branding
date: 2026-04-17
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# app-branding Planning Document

> **Summary**: assets/img/logo.png 로고 이미지를 앱 아이콘, 스플래시 화면, 홈 화면 AppBar에 통합 적용.

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 앱 아이콘이 Flutter 기본 아이콘이고, 스플래시 화면이 없으며, 홈 화면 AppBar에 QR/NFC 아이콘이 Material 아이콘으로만 표시됨. 앱 브랜드 아이덴티티가 부재. |
| **Solution** | `assets/img/logo.png`를 flutter_launcher_icons로 Android/iOS 앱 아이콘 생성, flutter_native_splash로 스플래시 화면 추가, HomeScreen AppBar leading을 로고 이미지로 교체. |
| **Function/UX Effect** | 앱 설치 시 고유 로고 아이콘 표시, 실행 시 스플래시 화면에서 로고 확인, 홈 화면에서 브랜드 로고 노출. |
| **Core Value** | 앱의 시각적 정체성 확립. QR+NFC 기능을 한눈에 전달하는 브랜드 이미지. |

---

## 변경 범위

| # | 작업 | 파일 | 패키지 |
|---|------|------|--------|
| 1 | 앱 아이콘 생성 | `pubspec.yaml`, Android mipmap, iOS Assets.xcassets | flutter_launcher_icons |
| 2 | 스플래시 화면 | `pubspec.yaml`, Android/iOS native | flutter_native_splash |
| 3 | HomeScreen AppBar 로고 교체 | `lib/features/home/home_screen.dart` | - |
| 4 | pubspec.yaml assets 등록 | `pubspec.yaml` | - |

---

## 성공 기준

| 기준 | 측정 |
|------|------|
| Android/iOS 앱 아이콘이 logo.png 기반으로 생성 | 빌드 후 런처 아이콘 확인 |
| 앱 실행 시 스플래시 화면에 로고 표시 | 실기기 cold start 확인 |
| 홈 화면 AppBar에 로고 이미지 표시 | UI 확인 |
