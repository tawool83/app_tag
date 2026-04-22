# app-info-menu Planning Document

> **Summary**: 햄버거 메뉴(Drawer) 하단에 "프로그램 정보" 메뉴를 추가하여 앱 버전, 템플릿 엔진 버전 등을 표시
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Author**: Claude
> **Date**: 2026-04-23
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 사용자가 현재 사용 중인 앱 버전, 템플릿 엔진 버전 등을 확인할 수 없어 지원 요청이나 호환성 문제 시 정보 파악이 어려움 |
| **Solution** | Drawer 하단에 "프로그램 정보" ListTile 추가 → 탭 시 다이얼로그(또는 AboutDialog)로 버전 정보 표시 |
| **Function/UX Effect** | 설정 메뉴 아래에 자연스럽게 배치, Flutter 내장 `showAboutDialog` 활용으로 OS 라이선스 정보까지 통합 제공 |
| **Core Value** | 앱의 완성도와 투명성 향상 — 버전 추적 가능, 지원 채널에서 빠른 문제 진단 |

---

## 1. Overview

### 1.1 Purpose

홈 화면의 햄버거 메뉴(Drawer) 하단에 "프로그램 정보" 항목을 추가하여, 사용자가 앱 버전 및 템플릿 엔진 버전 등 핵심 메타 정보를 확인할 수 있게 한다.

### 1.2 Background

- 현재 Drawer에는 **설정(Settings)** 메뉴만 존재 (`home_screen.dart:207-215`)
- 앱 버전(`1.0.0+1`)은 pubspec.yaml에만 있고 UI에서 확인 불가
- 템플릿 엔진 버전(`kTemplateEngineVersion = 2`)은 코드 내부 상수로만 존재
- pre-release 단계이지만, 테스터/개발자가 현재 빌드의 버전 정보를 빠르게 확인할 필요 있음

### 1.3 Related Documents

- 참조 구현: `lib/features/home/home_screen.dart` (`_buildDrawer()` 메서드)
- 템플릿 엔진 버전: `lib/features/qr_result/domain/entities/template_engine_version.dart`
- 앱 설정 상수: `lib/core/constants/app_config.dart`

---

## 2. Scope

### 2.1 In Scope

- [x] Drawer에 "프로그램 정보" ListTile 추가 (설정 아래, Drawer 하단 영역)
- [x] 탭 시 정보 다이얼로그 표시 (앱 버전, 빌드 번호, 템플릿 엔진 버전, 템플릿 스키마 버전)
- [x] `package_info_plus` 패키지로 런타임 앱 버전 조회
- [x] l10n 문자열 추가 (ko 선반영)

### 2.2 Out of Scope

- 별도 "정보" 전용 화면/라우트 (다이얼로그로 충분)
- 오픈소스 라이선스 목록 (Flutter 내장 `LicensePage`를 AboutDialog에 연결하면 자동 포함)
- 서버 연결 상태, 계정 정보 등 동적 데이터

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | Drawer 하단에 "프로그램 정보" ListTile 표시 (아이콘: `Icons.info_outline`) | High | Pending |
| FR-02 | 탭 시 `showAboutDialog` 호출 — 앱 이름, 앱 버전, 빌드 번호 표시 | High | Pending |
| FR-03 | 다이얼로그 본문에 템플릿 엔진 버전 (`kTemplateEngineVersion`) 표시 | High | Pending |
| FR-04 | 다이얼로그 본문에 템플릿 스키마 버전 (`kTemplateSchemaVersion`) 표시 | Medium | Pending |
| FR-05 | `package_info_plus` 의존성 추가 및 런타임 버전 조회 | High | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 다이얼로그 표시 < 100ms (PackageInfo 캐싱) | 수동 확인 |
| UX | Drawer 내 위치가 자연스럽고 탭 영역 충분 | 수동 확인 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [x] FR-01~FR-05 구현 완료
- [x] 다이얼로그에서 올바른 버전 정보 표시 확인
- [x] 빌드 성공 (iOS/Android)
- [x] l10n ko 문자열 추가

### 4.2 Quality Criteria

- [x] Zero lint errors
- [x] Build succeeds (flutter build 통과)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `package_info_plus` 초기 로딩 지연 | Low | Low | 앱 시작 시 1회 조회 후 캐싱, 또는 FutureBuilder로 async 처리 |
| `app_config.dart`와 `template_engine_version.dart`에 `kTemplateEngineVersion` 중복 | Medium | High | 하나로 통합 — `template_engine_version.dart` 값(=2)을 정본으로 사용 |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure | Static sites | |
| **Dynamic** | Feature-based modules, BaaS | Web apps with backend | **V** |
| **Enterprise** | Strict layer separation, DI, microservices | High-traffic systems | |

**Flutter Dynamic x Clean Architecture x R-series**

### 6.2 Key Architectural Decisions

| Decision | Selected | Rationale |
|----------|----------|-----------|
| Framework | Flutter | 프로젝트 고정 |
| State Management | Riverpod StateNotifier | 프로젝트 고정 |
| 로컬 저장 | Hive | 프로젝트 고정 |
| 라우팅 | go_router | 프로젝트 고정 |
| 버전 조회 | `package_info_plus` | Flutter 공식 권장, 런타임에 pubspec version/buildNumber 접근 |
| 정보 표시 방식 | `showAboutDialog` | Flutter 내장, 라이선스 페이지 자동 포함, 별도 화면 불필요 |

### 6.3 구현 위치

이 기능은 **별도 feature 디렉터리 불필요** (필드 ≤ 3, setter 없음). `home_screen.dart`의 `_buildDrawer()` 메서드에 ListTile 1개 + 다이얼로그 호출 함수를 추가하는 수준.

```
변경 파일:
├── lib/features/home/home_screen.dart      # Drawer에 ListTile + 다이얼로그 추가
├── lib/l10n/app_ko.arb                     # "프로그램 정보" 문자열 추가
├── lib/l10n/app_localizations*.dart        # gen-l10n 재생성
└── pubspec.yaml                            # package_info_plus 의존성 추가
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [x] `CLAUDE.md` has coding conventions section
- [x] R-series Provider 패턴 + Clean Architecture 적용
- [x] l10n: ko 선반영, 나머지 언어 ko fallback

### 7.2 참고 사항

- 이 기능은 trivial scope이므로 별도 provider/state 불필요
- `_buildDrawer()` 내에서 직접 `showAboutDialog` 호출
- `package_info_plus`는 `PackageInfo.fromPlatform()` 1회 호출 후 결과 사용

---

## 8. Next Steps

1. [ ] Design 문서 작성 (`app-info-menu.design.md`)
2. [ ] 구현 시작
3. [ ] Gap Analysis

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-23 | Initial draft | Claude |
