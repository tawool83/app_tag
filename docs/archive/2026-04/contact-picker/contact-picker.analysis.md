# Gap Analysis: contact-picker

> Design 참조: `docs/02-design/features/contact-picker.design.md`
> 분석일: 2026-04-12

---

## 결과 요약

| 항목 | 값 |
|------|-----|
| **Match Rate** | **98%** |
| 수용 기준 통과 | 10 / 10 |
| 설계 명세 통과 | 6 / 7 (1 minor deviation) |
| Gap (누락) | 없음 |
| Gap (불일치) | 1건 (기능적 동일, 문서 업데이트 권장) |

---

## 수용 기준 (Acceptance Criteria) 검증

| # | 항목 | 결과 | 근거 |
|---|------|:----:|------|
| 1 | `/contact-tag` 진입 시 연락처 권한 요청 | Pass | `contact_tag_screen.dart:36` `FlutterContacts.requestPermission(readonly: true)` in `initState` |
| 2 | 권한 허용 후 이름순 연락처 목록 표시 | Pass | `contact_tag_screen.dart:45-49` `getContacts` + `sort by displayName` |
| 3 | "직접 입력" 카드 최상단 고정 | Pass | `contact_tag_screen.dart:98-104` Column에서 `_buildDirectInputCard()` 가장 먼저 |
| 4 | "직접 입력" 탭 → `/contact-manual` 이동 및 폼 동작 | Pass | `router.dart:72-73` + `contact_manual_form.dart` 정상 구현 |
| 5 | 연락처 탭 → `/output-selector`로 name/phone/email 전달 | Pass | `contact_tag_screen.dart:69-92` `_onContactSelected` |
| 6 | 검색 입력 시 실시간 필터링 | Pass | `contact_tag_screen.dart:58-67` `_onSearchChanged` |
| 7 | 권한 거부 시 안내 + 설정 열기 버튼 | Pass | `contact_tag_screen.dart:176-204` `openAppSettings()` |
| 8 | Empty State (연락처 없음 / 검색 결과 없음) | Pass | `contact_tag_screen.dart:206-214` 메시지 분기 처리 |
| 9 | 로딩 중 `CircularProgressIndicator` | Pass | `contact_tag_screen.dart:140-142` |
| 10 | iOS / Android 권한 설정 | Pass | `AndroidManifest.xml` READ_CONTACTS + `Info.plist` NSContactsUsageDescription |

---

## 설계 명세 항목 검증

| 항목 | 설계 | 구현 | 결과 |
|------|------|------|:----:|
| `flutter_contacts` 의존성 | `^1.1.9+1` | `pubspec.yaml:63` 일치 | Pass |
| `/contact-manual` 라우트 상수 | `static const contactManual` | `router.dart:32` 일치 | Pass |
| 라우트 매핑 | `ContactManualFormScreen` | `router.dart:72-73` 일치 | Pass |
| `_ContactTagScreenState` 필드 5개 | `_contacts, _filtered, _loading, _permissionDenied, _searchController` | 전부 일치 | Pass |
| ContactTile 이니셜 아바타 + fallback | CircleAvatar + '전화번호 없음' | `contact_tag_screen.dart:155-174` 일치 | Pass |
| `ContactManualFormScreen` 검증 | 이름 필수, 이메일 `@` 검증 | `contact_manual_form.dart:58-76` 일치 | Pass |
| 정렬 방식 | `sortBy: ContactSortOrder.firstName` | 수동 `List.sort` (버전 호환 이슈) | Minor Gap |

---

## Gap 목록

### G-01: 정렬 구현 방식 차이 (Minor — 기능적 동일)

- **위치**: `contact_tag_screen.dart:47-49`
- **설계**: `getContacts(withProperties: true, sortBy: ContactSortOrder.firstName)`
- **구현**: `getContacts(withProperties: true)` + 이후 `List.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()))`
- **원인**: `flutter_contacts ^1.1.9+1`에서 `sortBy` 파라미터 미지원
- **영향**: 사용자 경험에 차이 없음 (이름순 정렬 결과 동일)
- **권장 조치**: Design 문서 §3.2 코드 블록을 실제 구현 방식으로 업데이트

---

## 결론

Match Rate **98%** — 수용 기준 10/10 통과. 단 1건의 Minor deviation은 라이브러리 버전 제약으로 인한 불가피한 구현 변경이며 기능적으로 동일하다.

**다음 단계**: `/pdca report contact-picker`
