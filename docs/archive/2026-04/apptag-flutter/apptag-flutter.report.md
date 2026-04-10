# AppTag Flutter — PDCA Completion Report

> **Feature**: AppTag Flutter  
> **Author**: tawool83  
> **Report Date**: 2026-04-10  
> **PDCA Cycle**: Plan → Design → Do → Check → Act (Post-launch fixes)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 자동 사료 급여기·냉장고 관리 앱 등 자주 쓰지 않는 기기 연동 앱의 이름을 잊어 실행이 불편함 |
| **Solution** | 앱을 QR코드/NFC 태그에 연결해 기기 옆에 붙여두면 카메라 스캔 또는 태그 터치 한 번으로 즉시 실행 |
| **Value Delivered** | Android Play Store 링크 기반 딥링크 안정화, 앱 검색 정확도 향상, NFC 화면 키보드 overflow 해결 등 실사용 검증 완료 |
| **Core Value** | 물리 공간과 디지털 앱을 연결하는 간단한 브리지 — 기술 지식 없이도 누구나 앱 단축키 생성 가능 |

---

## 1. Plan Summary

| 항목 | 내용 |
|------|------|
| 프로젝트 | AppTag Flutter |
| 목표 | Android/iOS 크로스플랫폼 앱 태그 생성기 |
| 아키텍처 | Dynamic Level — Riverpod + Hive + feature 모듈 구조 |
| 기능 요구사항 | FR-01 ~ FR-14 (14개) |
| 핵심 의사결정 | Android: device_apps / iOS: Shortcuts URL / NFC: nfc_manager / 이력: Hive |

---

## 2. Design Summary

| 항목 | 내용 |
|------|------|
| 화면 수 | 7개 (홈, 앱선택, iOS입력, 출력방식, QR결과, NFC기록, 이력) |
| 상태 관리 | Riverpod StateNotifierProvider |
| NFC 방식 | Read-Merge-Write (기존 레코드 보존, 플랫폼별 교체) |
| 딥링크 전략 | Android: Play Store URL / iOS: shortcuts:// |

---

## 3. Implementation Results

### 3.1 Functional Requirements 달성률

| ID | Requirement | Status |
|----|-------------|--------|
| FR-01 | Android 설치 앱 목록 조회 (`QUERY_ALL_PACKAGES`) | Done |
| FR-02 | 앱 이름 + 패키지명 검색 | Done |
| FR-03 | QR 코드 생성 (Play Store 딥링크) | Done |
| FR-04 | QR 이미지 갤러리 저장 / 공유 | Done |
| FR-05 | NFC 태그 NDEF 기록 (Read-Merge-Write) | Done |
| FR-06 | iOS Shortcuts URL 스킴 QR/NFC 생성 | Done |
| FR-07 | iOS 단축어 생성 안내 화면 | Done |
| FR-08 | NFC 미지원 기기 비활성화 + 안내 | Done |
| FR-09 | iOS NFC 쓰기 iPhone XS 이상 제한 | Done |
| FR-10 | 생성 이력 저장 (Hive) | Done |
| FR-11 | 이력에서 QR 재출력 / NFC 재기록 | Done |
| FR-12 | 이력 항목 삭제 | Done |
| FR-13 | 플랫폼 자동 감지 후 흐름 분기 | Done |
| FR-14 | QR 결과 화면 직접 인쇄 | Done |

**달성률: 14/14 (100%)**

### 3.2 Gap Analysis 결과

| 항목 | 값 |
|------|-----|
| Match Rate | **97%** |
| Critical Gaps | 0 |
| Important Gaps | 1 (appIconBytes — 비파괴적, 이력 표시 아이콘 누락) |
| Improvements | 3 (NFC 콜백 패턴, 동기 이력 조회, StateNotifierProvider) |

---

## 4. Post-launch Fixes (Act Phase)

초기 배포 후 실기기 검증에서 발견된 문제들을 수정:

| 수정 항목 | 변경 내용 | 파일 |
|-----------|-----------|------|
| Android 딥링크 형식 수정 | `intent://#Intent;...` → `intent:#Intent;...;S.browser_fallback_url=...;end` | `deep_link_constants.dart`, `app_picker_screen.dart` |
| Android 딥링크 방향 전환 | intent URI 불안정 → Play Store URL로 전면 교체 | `deep_link_constants.dart`, `ndef_record_helper.dart` |
| 앱 검색 개선 | appName 단독 검색 → appName + packageName 동시 검색 (밴드/band 등 대응) | `app_picker_provider.dart` |
| NFC 화면 키보드 overflow 수정 | `Column` 고정 → `SingleChildScrollView` + `ConstrainedBox(minHeight)` | `nfc_writer_screen.dart` |

---

## 5. Architecture Decisions Validated

| 결정 | 검증 결과 |
|------|-----------|
| Riverpod StateNotifierProvider | NFC 상태 관리에 적합, 화면 전환 후 dispose 정상 동작 |
| Hive 로컬 이력 | 앱 재실행 후 이력 정상 유지, appIconBytes 포함 |
| Read-Merge-Write NFC | Android-iOS 크로스 플랫폼 태그 공존 구조 검증 완료 |
| Play Store URL (Android) | intent URI 대비 안정적, 미설치 앱도 설치 페이지로 유도 |
| shortcuts:// (iOS) | Shortcuts 앱 연동 정상 동작 확인 |

---

## 6. Known Limitations

| 항목 | 내용 | 대응 |
|------|------|------|
| iOS 앱 목록 조회 불가 | Apple 보안 정책상 설치된 앱 목록 열거 불가 | Shortcuts 방식으로 대체 (설계 결정) |
| Android Play Store 딥링크 | 앱을 직접 실행하지 않고 Play Store 경유 | 사용자 경험 허용 가능 수준으로 판단 |
| NFC NTAG213 용량 제한 | 144 bytes — Play Store URL 포함 시 여유 있음 | 문제 없음 |
| appIconBytes 이력 아이콘 | 구현됐으나 Gap Analysis 시점에는 누락으로 기록됨 | 실제로는 커밋에서 구현 완료 |

---

## 7. Retrospective

### 잘 된 것
- Riverpod + Hive 조합으로 상태/이력 관리가 깔끔하게 분리됨
- NFC Read-Merge-Write 패턴으로 Android-iOS 태그 공존 달성
- feature 모듈 구조로 화면별 독립성 유지

### 개선할 것
- 초기 딥링크 전략 검증을 설계 단계에서 실기기로 사전 확인했으면 intent URL 이슈를 조기 발견 가능했음
- iOS는 Shortcuts에 의존하는 구조라 사용자에게 사전 설정 부담 존재

---

## 8. Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-04-09 | 초기 구현 완료 (전체 7화면 + NFC/QR 기능) |
| 0.1.1 | 2026-04-09 | NFC 크로스 플랫폼 태그 지원 (Read-Merge-Write) |
| 0.1.2 | 2026-04-10 | Android 딥링크 Play Store URL 전환, 앱 검색 개선, NFC 화면 overflow 수정 |
