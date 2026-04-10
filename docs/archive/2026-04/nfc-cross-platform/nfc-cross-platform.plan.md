# NFC 크로스 플랫폼 태그 Planning Document

> **Summary**: 하나의 NFC 태그를 Android와 iPhone이 각자 자기 영역만 순차적으로 기록하여 두 플랫폼 모두에서 앱을 실행할 수 있게 하는 기능
>
> **Project**: AppTag
> **Version**: 0.2.0
> **Author**: tawool83
> **Date**: 2026-04-10
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 현재 NFC 태그는 Android 또는 iPhone 중 하나의 플랫폼만 지원. 하나의 물리적 태그를 두 플랫폼 사용자가 공유하려면 각각 별도 태그가 필요함 |
| **Solution** | NFC 쓰기 시 태그를 먼저 읽어 기존 레코드를 보존하고, 현재 플랫폼의 레코드만 교체/추가 (Read-Merge-Write) |
| **Function/UX Effect** | Android는 AAR 레코드만 갱신, iPhone은 URI 레코드만 갱신. 서로 상대방 플랫폼 정보를 알 필요 없이 독립적으로 기록 가능 |
| **Core Value** | 하나의 NFC 스티커로 Android+iPhone 동시 지원 — 물리적 장치 한 개로 두 사용자 모두 충족 |

---

## 1. Overview

### 1.1 Purpose

자동 사료 급여기, 냉장고 관리 앱 등 공유 기기 옆에 NFC 스티커 하나를 붙이면, Android 사용자도 iPhone 사용자도 각자의 앱을 실행할 수 있어야 합니다.

현재 AppTag는 NFC 쓰기 시 태그 전체를 새로 덮어씁니다. 크로스 플랫폼을 위해서는 기존 레코드를 보존하며 자기 플랫폼 레코드만 갱신하는 Read-Merge-Write 방식이 필요합니다.

### 1.2 Scope

**포함:**
- NFC 쓰기 로직을 Read-Merge-Write 방식으로 변경
- Android: NDEF 내 AAR 레코드만 갱신 (URI 레코드 보존)
- iPhone: NDEF 내 URI 레코드만 갱신 (AAR 레코드 보존)
- 첫 번째 쓰기(빈 태그): 자기 플랫폼 레코드만 기록 (정상 동작)
- 두 번째 쓰기(기존 레코드 있음): 기존 레코드 보존 + 자기 레코드 갱신

**제외:**
- QR 코드 기능 (영향 없음)
- iOS NFC 쓰기 (iPhone은 NFC 쓰기 불가 — iPhone XS 이상에서 읽기만 가능)
  - **제약**: iPhone 사용자가 URI 레코드를 기록하는 것은 현실적으로 불가 → 아래 대안 참고

---

## 2. Problem Analysis

### 2.1 플랫폼별 NFC 쓰기 지원

| 플랫폼 | NFC 읽기 | NFC 쓰기 |
|--------|----------|----------|
| Android | 가능 | **가능** |
| iPhone (iOS 13+) | 가능 | **가능** (CoreNFC NFCNDEFTag) |

iOS 13부터 CoreNFC가 NDEF 쓰기를 지원합니다. `nfc_manager` 패키지도 iOS 쓰기를 지원하므로 **양 플랫폼 모두 독립적으로 기록 가능**합니다.

### 2.2 순차 기록 시나리오 (채택)

```
1. Android 사용자: AppTag → 태그 읽기 → AAR만 갱신 → 쓰기
   (URI 레코드가 있으면 보존, 없으면 그냥 AAR만 기록)

2. iPhone 사용자: AppTag → 태그 읽기 → URI만 갱신 → 쓰기
   (AAR 레코드가 있으면 보존, 없으면 그냥 URI만 기록)

결과: 태그에 AAR + URI 두 레코드 공존
→ Android가 태그 인식 → AAR 처리 → 앱 실행
→ iPhone이 태그 인식 → URI 처리 → 단축어 실행
```

각 플랫폼 사용자는 자기 정보만 알면 됩니다:
- Android: device_apps로 패키지명 자동 획득
- iPhone: 본인이 등록한 단축어 이름 입력

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| FR-01 | NFC 쓰기 전 태그를 먼저 읽어 기존 NDEF 레코드 파악 | Must |
| FR-02 | 기존 레코드 중 현재 플랫폼 레코드만 교체, 나머지 보존 | Must |
| FR-03 | 빈 태그(첫 쓰기)는 현재 플랫폼 레코드만 기록 | Must |
| FR-04 | Android에서 iOS 단축어 이름 추가 입력 UI 제공 | Must |
| FR-05 | iOS URI 레코드가 이미 있는 경우 덮어쓰기 여부 확인 | Should |
| FR-06 | 태그에 기록된 플랫폼 구성 (Android만/iOS만/둘 다) 읽기 화면 표시 | Could |

### 3.2 Non-Functional Requirements

- NFC 읽기+쓰기 합산 응답 시간 < 5초
- 읽기 실패 시 (빈 태그로 간주) 기존 쓰기 방식으로 폴백

---

## 4. User Stories

### US-01 — Android 사용자가 크로스 플랫폼 태그 생성

```
As Android 사용자
When NFC 쓰기 선택 시 "iOS 단축어도 함께 기록" 옵션 활성화
Then iOS 단축어 이름 입력 필드 표시
And 태그에 AAR + URI 두 레코드 모두 기록
So that iPhone 사용자도 같은 태그로 앱 실행 가능
```

### US-02 — Android 사용자가 기존 태그에 iOS 단축어 추가

```
As Android 사용자
When 이미 AAR만 기록된 태그에 재기록 시도
Then 기존 AAR 보존, iOS URI 레코드만 추가
So that 태그를 지우지 않고 iOS 지원 추가 가능
```

### US-03 — iPhone 사용자가 크로스 플랫폼 태그 인식

```
As iPhone 사용자
When 크로스 플랫폼 태그에 폰을 가져다 댐
Then URI 레코드(shortcuts://) 인식
And 단축어 실행
```

---

## 5. Technical Design (High Level)

### 5.1 NDEF 레코드 구조

```
NDEF Message
├── Record 0: URI  → shortcuts://run-shortcut?name=카카오톡  (iOS용)
└── Record 1: AAR  → package:com.kakao.talk                (Android용)
```

- **AAR (Android Application Record)**: TNF=0x04, type=`android.com:pkg`
- **URI Record**: TNF=0x01, type=`U`, payload=URI

### 5.2 Read-Merge-Write 플로우

```
[NFC 태그 접촉]
      ↓
  태그 읽기 시도
      ↓
  ┌─────────────────┐
  │ 빈 태그?        │──Yes──→ 자기 레코드만 기록
  └─────────────────┘
      │ No
      ↓
  기존 레코드 파싱
  (AAR 목록, URI 목록 분리)
      ↓
  현재 플랫폼 레코드 교체
  나머지 레코드 보존
      ↓
  병합된 NDEF 메시지 쓰기
```

### 5.3 변경 파일 (예상)

| 파일 | 변경 내용 |
|------|-----------|
| `lib/services/nfc_service.dart` | readAndMergeWrite() 메서드 추가 |
| `lib/features/nfc_writer/nfc_writer_provider.dart` | 읽기→병합→쓰기 흐름으로 변경 |
| `lib/features/nfc_writer/nfc_writer_screen.dart` | iOS 단축어 추가 입력 UI |
| `lib/features/output_selector/output_selector_screen.dart` | "iOS 단축어도 기록" 옵션 추가 |

---

## 6. Constraints & Risks

| 항목 | 내용 |
|------|------|
| iPhone 백그라운드 쓰기 불가 | 앱이 포그라운드에서 NFC 세션을 명시적으로 시작해야 쓰기 가능 (읽기는 백그라운드 가능) |
| 태그 용량 | NTAG213 (144바이트). AAR + URI 두 레코드 합산 약 80~100바이트 — 충분 |
| 쓰기 전 읽기 추가 | NFC 접촉 시간 약 1~2초 추가 (허용 범위) |
| 태그 잠금(read-only) | 읽기만 가능한 태그는 쓰기 실패 → 에러 메시지로 처리 |
