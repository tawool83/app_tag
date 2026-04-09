# AppTag Flutter 앱 Planning Document

> **Summary**: 스마트폰 앱을 QR코드/NFC 태그에 연결하여 물리적 공간에서 즉시 실행하는 Flutter 크로스플랫폼 앱
>
> **Project**: AppTag
> **Version**: 0.1.0
> **Author**: tawool83
> **Date**: 2026-04-09
> **Status**: Draft
> **Source**: [Notion - AppTag Flutter 앱 설계 문서](https://www.notion.so/tawool/AppTag-Flutter-33d7ef63522981c3899ceecedd92d46a)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 자동 사료 급여기, 냉장고 관리 앱 등 자주 쓰지 않는 스마트 기기 연동 앱의 이름을 잊어버려 실행이 불편함 |
| **Solution** | 앱을 QR코드 또는 NFC 태그에 연결하여 기기 옆에 붙여두면 카메라/태치 한 번으로 즉시 실행 |
| **Function/UX Effect** | Android는 설치 앱 목록 선택, iOS는 Shortcuts 연동으로 플랫폼별 최적 UX 제공. 생성 이력 관리로 반복 사용 편의성 향상 |
| **Core Value** | 물리적 공간과 디지털 앱을 연결하는 간단한 브리지 — 기술 지식 없이도 누구나 앱 단축키를 만들 수 있음 |

---

## 1. Overview

### 1.1 Purpose

스마트 기기와 연동된 앱(자동 사료 급여기, 냉장고 관리 등)은 자주 사용하지 않으면 앱 이름을 잊어버리기 쉽습니다. AppTag는 해당 기기 옆에 QR코드나 NFC 스티커를 붙여두어, 카메라로 찍거나 스마트폰을 가져다 대는 것만으로 앱을 즉시 실행할 수 있게 해줍니다.

### 1.2 Background

- **앱 이름 후보**: AppTag (App + Tag 합성어, 직관적이고 영어·한국어 모두 이해 쉬움)
- **기타 후보**: TapLaunch, QuickTag, 앱태그
- Android와 iOS의 보안 정책 차이로 인해 플랫폼별 다른 접근 방식 필요
  - Android: `device_apps` 패키지로 설치 앱 직접 조회 가능
  - iOS: 보안 정책상 앱 목록 접근 불가 → Shortcuts 앱 우회 방식 사용

### 1.3 Related Documents

- 원본 설계: [Notion - AppTag Flutter 앱 설계 문서](https://www.notion.so/tawool/AppTag-Flutter-33d7ef63522981c3899ceecedd92d46a)
- 상위 아이디어: [스마트폰의 어플을 바로 실행할수 있는 QR 출력기](https://www.notion.so/33d7ef63522980458694c526db53cf81)

---

## 2. Scope

### 2.1 In Scope

- [ ] Android: 설치 앱 목록 조회 + 검색 (`device_apps`)
- [ ] Android: 선택한 앱 → QR 코드 생성 (`package:` 딥링크)
- [ ] Android: 선택한 앱 → NFC 태그 NDEF 기록
- [ ] iOS: 앱 이름 직접 입력 + 단축어 생성 안내
- [ ] iOS: Shortcuts URL 스킴 → QR 코드 생성
- [ ] iOS: Shortcuts URL 스킴 → NFC 태그 기록 (iPhone XS 이상 + iOS 13 이상만 지원)
- [ ] QR 이미지 저장 (갤러리) / 공유 (`share_plus`)
- [ ] NFC 미지원 기기 처리 (옵션 비활성화 + 안내)
- [ ] **생성 이력 관리**: 이전에 출력했던 QR/NFC 기록 저장, 재출력/재기록 가능
- [ ] 한국어 우선 UI

### 2.2 Out of Scope

- 즐겨찾기 기능 (이력 관리로 대체)
- URL/웹사이트 QR 변환 범용 기능 (향후 확장)
- QR 코드 디자인 커스터마이징 (향후 확장)
- NFC 태그 내용 읽기 기능 (향후 확장)
- 다국어 지원 - 영어 등 (향후 확장)
- 앱 스토어 배포 (별도 계획)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | Android: `QUERY_ALL_PACKAGES` 권한으로 설치 앱 목록 조회 | High | Pending |
| FR-02 | Android: 앱 목록에서 이름/아이콘으로 검색 | High | Pending |
| FR-03 | 선택한 앱을 QR 코드(package: 딥링크)로 생성 | High | Pending |
| FR-04 | 생성된 QR 코드 이미지를 갤러리에 저장 또는 공유 | High | Pending |
| FR-05 | 선택한 앱을 NFC 태그(NDEF 레코드)에 기록 | High | Pending |
| FR-06 | iOS: 앱 이름 입력 및 Shortcuts URL 스킴으로 QR/NFC 생성 | High | Pending |
| FR-07 | iOS: 단축어 생성 방법 안내 화면 제공 | Medium | Pending |
| FR-08 | NFC 미지원 기기에서 NFC 옵션 비활성화 + 안내 문구 표시 | High | Pending |
| FR-09 | iOS NFC 쓰기: iPhone XS 이상 + iOS 13 이상만 지원, 미지원 기기 안내 | High | Pending |
| FR-10 | 생성 이력 저장: 앱명, 딥링크, 생성 방식(QR/NFC), 생성 일시 보관 | High | Pending |
| FR-11 | 이력에서 항목 선택 시 QR 재출력 또는 NFC 재기록 가능 | High | Pending |
| FR-12 | 이력 항목 삭제 기능 | Medium | Pending |
| FR-13 | 플랫폼 자동 감지 후 Android/iOS 흐름 분기 | High | Pending |
| FR-14 | QR 코드 결과 화면에서 시스템 프린트 다이얼로그를 통한 직접 인쇄 | Medium | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 앱 목록 로딩 < 2초 (Android) | 실기기 측정 |
| Compatibility | Android 6.0+, iOS 13+ (NFC 쓰기는 iPhone XS+) | 다기기 테스트 |
| UX | 앱 선택 → QR 생성 3탭 이내 완료 | 사용성 테스트 |
| Storage | 이력 데이터 로컬 저장 (네트워크 불필요) | 오프라인 동작 확인 |
| Accessibility | 한국어 우선, 텍스트 크기 적절 | 기기 접근성 설정 테스트 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] Android 앱 목록 조회 및 QR/NFC 생성 동작 확인
- [ ] iOS Shortcuts URL 기반 QR/NFC 생성 동작 확인
- [ ] 생성 이력 저장 및 재출력 동작 확인
- [ ] NFC 미지원 기기에서 적절한 안내 표시
- [ ] iOS NFC 미지원 기기(iPhone X 이하) 안내 표시
- [ ] QR 이미지 저장/공유 동작 확인

### 4.2 Quality Criteria

- [ ] 실기기 테스트 통과 (Android 1대 이상, iOS 1대 이상)
- [ ] 앱 크래시 없음 (기본 플로우)
- [ ] 빌드 성공 (Debug + Release)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Android 11+ `QUERY_ALL_PACKAGES` 권한 거부 | High | Medium | 권한 요청 흐름 명확화, 거부 시 안내 화면 제공 |
| iOS 단축어 URL 인코딩 오류 (한글/공백) | Medium | High | URL 인코딩 처리 (`Uri.encodeFull`) 필수 적용 |
| NFC 태그 용량 부족 (긴 딥링크) | Medium | Low | NTAG213(144 bytes) 기준 딥링크 길이 제한 안내 |
| 구형 iPhone NFC 쓰기 불가 (iPhone X 이하) | Medium | Medium | 기기 감지 후 안내 문구 표시, 읽기 전용 안내 |
| `device_apps` 패키지 최신 Flutter 버전 호환성 | Medium | Low | 사전 패키지 호환성 검증, 대안 패키지 조사 |
| 금속 표면 NFC 태그 미작동 | Low | Medium | 사용자 가이드에 주의사항 포함 |

---

## 6. Impact Analysis

### 6.1 Changed Resources

| Resource | Type | Change Description |
|----------|------|--------------------|
| 로컬 이력 저장소 | Local Storage (SharedPreferences/SQLite) | 신규 생성 — 이력 데이터 CRUD |
| NFC 권한 | Android Manifest / iOS Info.plist | 신규 추가 — NFC 읽기/쓰기 권한 |
| 앱 목록 권한 | Android Manifest | 신규 추가 — `QUERY_ALL_PACKAGES` |

### 6.2 Current Consumers

신규 프로젝트이므로 기존 소비자 없음.

### 6.3 Verification

- [ ] Android 권한 선언 및 런타임 권한 요청 검증
- [ ] iOS Info.plist NFC 사용 설명 문구 추가 검증
- [ ] 이력 저장 데이터 마이그레이션 전략 (향후 스키마 변경 대비)

---

## 7. Architecture Considerations

### 7.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | 단순 구조 | 정적 앱, 포트폴리오 | ☐ |
| **Dynamic** | 기능 모듈 기반, 로컬/BaaS 연동 | 기능이 있는 모바일 앱 | ☑ |
| **Enterprise** | 엄격한 레이어 분리, DI | 대규모 시스템 | ☐ |

**선택: Dynamic** — 기능 모듈 구조 + 로컬 스토리지 연동으로 충분

### 7.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Framework | Flutter | Flutter | Notion 설계 문서 기준, 크로스플랫폼 단일 코드베이스 |
| State Management | Provider / Riverpod / Bloc | Riverpod | 단순하면서 테스트 용이, Flutter 커뮤니티 권장 |
| Local Storage | SharedPreferences / Hive / SQLite | Hive | 구조적 이력 데이터 저장에 적합, 경량 NoSQL |
| NFC | nfc_manager | nfc_manager | Android/iOS 통합 NFC API |
| QR 생성 | qr_flutter | qr_flutter | 널리 사용되는 안정적 패키지 |
| 이미지 저장/공유 | share_plus + screenshot | share_plus + screenshot | Notion 설계 문서 기준 |
| 앱 목록 (Android) | device_apps | device_apps | Notion 설계 문서 기준 |

### 7.3 Flutter 폴더 구조 (Dynamic Level)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                  # MaterialApp 설정
│   └── router.dart               # 화면 라우팅
├── features/
│   ├── home/                     # 홈 화면 (플랫폼 분기)
│   ├── app_picker/               # Android 앱 목록 + 검색
│   ├── ios_input/                # iOS 앱 이름 입력 + 단축어 안내
│   ├── output_selector/          # QR/NFC 출력 방식 선택
│   ├── qr_result/                # QR 코드 결과 화면
│   ├── nfc_writer/               # NFC 기록 화면
│   └── history/                  # 생성 이력 목록 + 재출력
├── services/
│   ├── nfc_service.dart          # NFC 읽기/쓰기 로직
│   ├── qr_service.dart           # QR 생성 로직
│   └── history_service.dart      # 이력 저장/조회 (Hive)
├── models/
│   └── tag_history.dart          # 이력 데이터 모델
└── shared/
    ├── widgets/                  # 공통 위젯
    └── constants/                # 딥링크 포맷 상수 등
```

---

## 8. Convention Prerequisites

### 8.1 Existing Project Conventions

- [ ] `CLAUDE.md` 코딩 컨벤션 섹션 존재 여부 확인
- [ ] Flutter 린트 설정 (`analysis_options.yaml`)
- [ ] `flutter_lints` 또는 `very_good_analysis` 적용 여부

### 8.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **네이밍** | 미정 | Dart 표준 (camelCase, snake_case 파일명) | High |
| **폴더 구조** | 미정 | features/ 기반 모듈화 구조 | High |
| **상태관리** | 미정 | Riverpod Provider 네이밍 규칙 | Medium |
| **에러 처리** | 미정 | NFC/권한 오류 공통 처리 패턴 | Medium |

### 8.3 Environment Variables / Configuration

| 항목 | 내용 | 비고 |
|------|------|------|
| `minSdkVersion` | Android 23 (6.0) | device_apps 요구사항 |
| `compileSdkVersion` | 34 이상 | 최신 Flutter 기준 |
| `iOS Deployment Target` | 13.0 | NFC 쓰기 최소 버전 |
| `NSNFCUsageDescription` | NFC 태그 기록을 위해 NFC를 사용합니다 | iOS Info.plist 필수 |

---

## 9. Screen Flow

```
[홈 화면]
  ├─ Android: 앱 목록 화면 → 앱 선택 → 출력 방식 선택 → QR/NFC 결과 화면
  └─ iOS:     앱 이름 입력 → 단축어 안내 → 출력 방식 선택 → QR/NFC 결과 화면

[이력 화면] ← 홈에서 접근 가능
  └─ 이력 항목 선택 → 출력 방식 선택 → QR/NFC 결과 화면
```

| 화면 | 설명 |
|------|------|
| 홈 화면 | 플랫폼 자동 감지 후 Android/iOS 흐름으로 분기, 이력 접근 버튼 |
| 앱 목록 (Android) | 설치된 앱 목록 + 검색 기능 |
| 앱 이름 입력 (iOS) | 텍스트 필드 + 단축어 생성 안내 |
| 출력 방식 선택 | QR 코드 / NFC 태그 선택 (NFC 미지원 시 비활성화) |
| QR 결과 화면 | QR 코드 이미지 표시, 저장/공유 버튼 |
| NFC 기록 화면 | "태그를 가져다 대세요" 안내 + 기록 완료 메시지 |
| 이력 목록 화면 | 생성 이력 목록, 항목 선택 시 재출력 가능, 삭제 가능 |

---

## 10. Development Schedule

| 단계 | 내용 | 예상 기간 |
|------|------|----------|
| 1단계 | 프로젝트 셋업, 폴더 구조, 화면 와이어프레임 | 1주 |
| 2단계 | Android 앱 목록 + QR 생성 기능 | 1~2주 |
| 3단계 | NFC 기록 기능 (Android + iOS 지원 범위 처리) | 1주 |
| 4단계 | iOS 단축어 흐름 + 이력 관리 기능 | 1~2주 |
| 5단계 | 테스트 및 디버깅 | 1주 |

---

## 11. NFC 태그 규격 참고

| 규격 | 메모리 | 권장 용도 | 비고 |
|------|--------|----------|------|
| **NTAG213** | 144 bytes | 앱 딥링크 (이 앱 용도에 최적) | 개당 200~500원, 구하기 쉬움 |
| NTAG215 | 504 bytes | 긴 데이터 | 여유 메모리 필요 시 |
| NTAG216 | 888 bytes | 대용량, 고빈도 | 최대 50만 회 스캔 |

> **권장**: NTAG213 — Android `package:...` 또는 iOS `shortcuts://...` 딥링크는 수십~100바이트 내외로 충분

---

## 12. Next Steps

1. [ ] Design 문서 작성 (`apptag-flutter.design.md`) — 화면별 상세 설계
2. [ ] Flutter 프로젝트 초기화 및 패키지 설정
3. [ ] Phase 1 Schema 정의 (`/phase-1-schema`)
4. [ ] Phase 2 Convention 정의 (`/phase-2-convention`)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-09 | Initial draft (Notion 기반) | tawool83 |
