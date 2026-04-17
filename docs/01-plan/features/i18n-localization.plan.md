---
template: plan
version: 1.2
feature: i18n-localization
date: 2026-04-17
author: tawool83
project: app_tag
version_app: 1.0.0+1
---

# i18n-localization Planning Document

> **Summary**: 앱 전체 다국어 지원 (10개 언어) + 설정 화면에서 언어 수동 선택 기능 추가.

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 모든 UI 문자열이 한국어로 하드코딩되어 해외 사용자가 앱을 이해할 수 없음. 언어 설정 변경 기능 없음. |
| **Solution** | Flutter 공식 i18n (flutter_localizations + intl + ARB) 기반 10개 언어 지원. 설정 화면에서 언어 수동 선택, SharedPreferences 영속 저장. 기본값은 시스템 언어 자동 감지. |
| **Function/UX Effect** | 영어권 사용자는 영어 UI, 일본어 사용자는 일본어 UI로 자동 표시. 설정에서 수동 전환 가능. |
| **Core Value** | 글로벌 시장 진출 기반 확보. 10개 언어로 전 세계 인구 75% 이상 커버. |

---

## 1. 지원 언어 목록

| # | 언어 | Locale | 비고 |
|---|------|--------|------|
| 1 | 한국어 | `ko` | 기본 (현재 하드코딩) |
| 2 | 영어 | `en` | 글로벌 기본 fallback |
| 3 | 일본어 | `ja` | 동아시아 |
| 4 | 중국어 (간체) | `zh` | 동아시아 |
| 5 | 스페인어 | `es` | 중남미 |
| 6 | 프랑스어 | `fr` | 유럽/아프리카 |
| 7 | 독일어 | `de` | 유럽 |
| 8 | 포르투갈어 | `pt` | 브라질 |
| 9 | 베트남어 | `vi` | 동남아 |
| 10 | 태국어 | `th` | 동남아 |

---

## 2. 기능 요구사항

### 2.1 자동 언어 감지
- 앱 첫 실행 시 시스템 언어(locale) 자동 감지
- 지원하지 않는 언어일 경우 영어(en) fallback

### 2.2 설정 화면
- HomeScreen AppBar 우측에 설정 아이콘 (기존 도움말 아이콘 옆)
- 설정 화면: 언어 선택 리스트 (10개 + "시스템 기본" 옵션)
- 선택 시 즉시 UI 언어 전환 (앱 재시작 불필요)
- 선택한 언어 SharedPreferences 영속 저장

### 2.3 번역 범위
- 모든 UI 문자열: AppBar 타이틀, 버튼, 라벨, 다이얼로그, 스낵바, 도움말
- 25개 파일의 하드코딩된 한국어 문자열 추출

---

## 3. 기술 구현 방식

### 3.1 Flutter 공식 i18n

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_ko.arb
output-localization-file: app_localizations.dart
```

### 3.2 ARB 파일 구조

```
lib/l10n/
├── app_ko.arb    (한국어 — 템플릿)
├── app_en.arb    (영어)
├── app_ja.arb    (일본어)
├── app_zh.arb    (중국어)
├── app_es.arb    (스페인어)
├── app_fr.arb    (프랑스어)
├── app_de.arb    (독일어)
├── app_pt.arb    (포르투갈어)
├── app_vi.arb    (베트남어)
└── app_th.arb    (태국어)
```

### 3.3 설정 화면 구조

```
lib/features/settings/
└── settings_screen.dart    (언어 선택 UI)
```

### 3.4 언어 상태 관리

```dart
// Riverpod StateNotifier로 locale 관리
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(...)
// null = 시스템 기본, Locale('en') = 영어 수동 선택
```

---

## 4. 구현 순서

| Phase | 작업 |
|:-----:|------|
| P1 | ARB 인프라 설정 (pubspec, l10n.yaml, 템플릿 ARB) |
| P2 | 한국어 문자열 추출 → app_ko.arb 작성 |
| P3 | 영어 번역 → app_en.arb 작성 |
| P4 | 나머지 8개 언어 ARB 작성 |
| P5 | MaterialApp.router에 localization delegates 연결 |
| P6 | 전체 화면 하드코딩 문자열 → AppLocalizations.of(context) 교체 |
| P7 | 설정 화면 생성 (언어 선택 + 저장) |
| P8 | HomeScreen AppBar에 설정 아이콘 추가 |
| P9 | 통합 QA (10개 언어 전환 테스트) |

---

## 5. 범위 제외 (Out of Scope)

| 항목 | 이유 |
|------|------|
| RTL(아랍어/히브리어) | 복잡한 레이아웃 변경 필요, 별도 피처 |
| 서버 기반 번역 | 오프라인 우선 앱, ARB 파일로 충분 |
| 앱 내 번역 기여 | 커뮤니티 번역은 향후 |

---

## 6. 성공 기준

| 기준 | 측정 |
|------|------|
| 시스템 언어 영어 → 앱 UI 영어 표시 | 에뮬레이터 언어 변경 확인 |
| 설정에서 일본어 선택 → 즉시 전환 | UI 확인 |
| 앱 재시작 후 선택 언어 유지 | SharedPreferences 확인 |
| "시스템 기본" 선택 시 시스템 언어 복귀 | 확인 |
| 10개 ARB 파일 누락 키 없음 | flutter gen-l10n 경고 0 |
