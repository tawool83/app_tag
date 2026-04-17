---
template: plan
version: 1.2
feature: readability-ui-simplify
date: 2026-04-17
author: tawool83
project: app_tag
---

# readability-ui-simplify Planning Document

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | QR 미리보기의 인식률 배지가 부정확 (50% 이하에서도 정상 인식). 화면 공간 낭비. |
| **Solution** | 미리보기에서 인식률 배지 제거, 저장 시 SnackBar 알림으로만 경고. 설정에서 알림 on/off 토글 (기본: off). |
| **Function/UX** | 미리보기가 QR 코드에만 집중. 인식률 경고는 필요한 사용자만 설정에서 활성화. |
| **Core Value** | 불필요한 정보 제거로 UI 심플화. 사용자 선택권 보장. |

## 변경 범위

| # | 작업 | 파일 |
|---|------|------|
| 1 | QR 미리보기에서 인식률 배지 영역 제거 | `qr_preview_section.dart` |
| 2 | 저장 시 인식률 경고를 SnackBar 알림으로 변경 | `qr_result_screen.dart` |
| 3 | 설정 화면에 "인식률 알림 사용" 토글 추가 (기본: off) | `settings_screen.dart` |
| 4 | SettingsService에 readability alert 설정 저장 | `settings_service.dart` |
| 5 | ARB에 새 문자열 키 추가 | `lib/l10n/app_*.arb` |
