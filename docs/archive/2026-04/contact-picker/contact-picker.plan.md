## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 연락처 태그 생성 시 이름·전화번호·이메일을 매번 직접 타이핑해야 하며, 오타 위험과 번거로움이 크다. |
| **Solution** | 화면 상단에 "직접 입력" 옵션을 두고, 하단에 기기 연락처 목록을 표시해 탭 한 번으로 정보를 자동 채운다. |
| **Function UX Effect** | 연락처 선택 → 폼 자동완성 → 바로 다음 단계로 이동하는 3-tap 플로우로 입력 마찰을 제거한다. |
| **Core Value** | 기기에 저장된 연락처를 즉시 NFC/QR 태그로 변환할 수 있어 앱 실용성과 재사용률이 높아진다. |

---

# Plan: contact-picker

## 1. 기능 개요

| 항목 | 내용 |
|------|------|
| Feature | contact-picker |
| 작성일 | 2026-04-12 |
| 우선순위 | High |
| 난이도 | Medium |

연락처 태그 화면에서 기기 주소록을 불러와 목록으로 표시하고, 선택 시 이름·전화번호·이메일을 자동 입력하는 기능이다. 상단의 "직접 입력" 옵션은 기존 수동 폼 흐름을 유지한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| FR-01 | ContactTagScreen 진입 시 기기 연락처 읽기 권한을 요청한다. | Must |
| FR-02 | 화면 최상단에 "직접 입력" 카드/버튼을 고정 표시한다. | Must |
| FR-03 | "직접 입력" 탭 시 기존 수동 입력 폼 화면으로 이동한다. | Must |
| FR-04 | 권한 허용 시 기기 연락처 목록을 이름·전화번호 형태로 표시한다. | Must |
| FR-05 | 연락처 항목 탭 시 이름·전화번호·이메일이 자동 채워진 상태로 다음 단계(/output-selector)로 이동한다. | Must |
| FR-06 | 권한 거부 시 안내 메시지를 표시하고 "직접 입력" 만 사용 가능하게 한다. | Must |
| FR-07 | 연락처 목록 상단에 이름 검색 필드를 제공한다. | Should |
| FR-08 | 연락처가 없거나 권한 거부 시 빈 상태(Empty State) 안내 문구를 표시한다. | Should |
| FR-09 | 연락처 로딩 중 CircularProgressIndicator를 표시한다. | Must |
| FR-10 | 전화번호 없는 연락처도 목록에 표시하되, 전화번호 필드는 빈 값으로 채운다. | Should |

### 2.2 비기능 요구사항

- 연락처 로딩은 비동기(async/await)로 처리하여 UI 블로킹 없음
- 목록은 이름 기준 가나다(ABC) 정렬
- iOS / Android 모두 동일한 UX 제공

---

## 3. 기술 스택 및 구현 방향

### 3.1 신규 패키지

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter_contacts` | ^1.1.9+1 | 기기 연락처 읽기 (iOS/Android 통합) |

> `permission_handler` 는 이미 존재 (^11.3.1) — 별도 추가 불필요

### 3.2 권한 설정

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSContactsUsageDescription</key>
<string>연락처 태그를 만들기 위해 연락처에 접근합니다.</string>
```

### 3.3 파일 변경 범위

| 파일 | 변경 유형 | 내용 |
|------|---------|------|
| `pubspec.yaml` | 수정 | `flutter_contacts: ^1.1.9+1` 추가 |
| `android/app/src/main/AndroidManifest.xml` | 수정 | READ_CONTACTS 권한 추가 |
| `ios/Runner/Info.plist` | 수정 | NSContactsUsageDescription 추가 |
| `lib/features/contact_tag/contact_tag_screen.dart` | 대폭 수정 | 연락처 피커 UI + 기존 수동 폼 유지 |
| `lib/features/contact_tag/contact_manual_form.dart` | 신규 | 기존 수동 입력 폼을 별도 위젯/화면으로 분리 |

---

## 4. UX 흐름

```
[홈 화면] → "연락처" 타일 탭
  ↓
[ContactTagScreen]
  ┌─────────────────────────────┐
  │  [직접 입력 →]  (고정 카드)  │
  ├─────────────────────────────┤
  │  🔍 이름 검색               │
  ├─────────────────────────────┤
  │  홍길동   010-1234-5678     │
  │  김영희   010-9876-5432     │
  │  ...                        │
  └─────────────────────────────┘
  
  ↓ "직접 입력" 탭
[ContactManualFormScreen]  (기존 폼)
  → 다음 → /output-selector

  ↓ 연락처 항목 탭
자동으로 /output-selector 로 이동 (name, phone, email 전달)
```

---

## 5. UI 컴포넌트 설계

### 5.1 ContactTagScreen (리뉴얼)

```
Scaffold
  AppBar: '연락처 태그'
  body:
    Column
      ├─ _DirectInputCard  (고정)
      ├─ _SearchField      (검색 TextField)
      └─ Expanded
           └─ _ContactList  (ListView.builder)
                ├─ CircularProgressIndicator  (로딩 중)
                ├─ EmptyState                 (없거나 권한 거부)
                └─ ContactListTile            (이름 + 전화번호)
```

### 5.2 ContactListTile

- leading: CircleAvatar (이름 이니셜)
- title: 연락처 이름
- subtitle: 전화번호 (없으면 "전화번호 없음")
- onTap: `_onContactSelected(contact)`

---

## 6. 데이터 흐름

```
initState()
  └─ FlutterContacts.requestPermission()
       ├─ 허용 → FlutterContacts.getContacts(withProperties: true)
       │           └─ 이름순 정렬 → _contacts 저장
       └─ 거부 → _permissionDenied = true

사용자 검색 입력
  └─ _filtered = _contacts.where(name contains query)

사용자 연락처 탭
  └─ Navigator.pushNamed('/output-selector', arguments: {
       'appName': '연락처',
       'deepLink': TagPayloadEncoder.contact(name, phone, email),
       'platform': 'universal',
       'outputType': 'qr',
       'tagType': 'contact',
     })
```

---

## 7. 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| 권한 거부 | "연락처 접근이 거부되었습니다. 직접 입력을 사용하세요." 안내 + 설정 이동 버튼 |
| 권한 영구 거부 (Android) | 시스템 설정 화면으로 이동하는 버튼 표시 |
| 연락처 0개 | "저장된 연락처가 없습니다." EmptyState |
| 검색 결과 0개 | "검색 결과가 없습니다." 안내 |
| 전화번호 여러 개 | 첫 번째 전화번호 사용 |
| 이메일 없는 연락처 | email 필드 빈 문자열로 전달 |

---

## 8. 수용 기준 (Acceptance Criteria)

- [ ] 앱 진입 시 또는 연락처 탭 시 권한 요청 다이얼로그 표시
- [ ] 권한 허용 후 연락처 목록이 이름순으로 표시됨
- [ ] "직접 입력" 카드가 항상 목록 최상단에 고정됨
- [ ] 연락처 탭 시 해당 정보가 채워진 상태로 output-selector 화면 이동
- [ ] 검색 필드 입력 시 실시간 필터링
- [ ] 권한 거부 시 안내 메시지 표시, 직접 입력은 정상 작동
- [ ] iOS / Android 양쪽에서 동작
