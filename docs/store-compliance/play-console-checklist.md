# Google Play Console 제출 체크리스트

> AppTag v1.0.0+1 · bundle `com.tawool.app_tag`
> 본 체크리스트는 Play Console 에 **사용자가 직접 입력**하는 메타데이터 가이드입니다.
> 코드 변경 없음 — 콘솔 UI 작업.

---

## 1. App Content (앱 콘텐츠)

| 항목 | 값 |
|------|-----|
| Privacy Policy URL | `https://tawool83.github.io/apptag-legal/privacy-policy.html` |
| App Access | 로그인 불필요 (주요 기능은 비로그인 사용 가능) |
| Ads | **No** (광고 도입 전까지) |
| Content Rating | 설문 작성 필요 (권장: **모든 연령**) |
| Target Audience | 13+ (범용 유틸리티) |
| News App | No |
| Government App | No |
| Financial Features | No (결제 도입 전까지) |

---

## 2. Data Safety (데이터 안전)

### 수집 데이터

| 데이터 타입 | 수집 여부 | 목적 | 공유 | 선택 |
|-------------|----------|------|------|------|
| Email address | ✅ (로그인 사용자만) | Account Management | Supabase (위탁) | Optional |
| Name | ✅ (SSO 사용자만) | Account Management | Supabase (위탁) | Optional |
| User-generated content (QR 데이터) | ✅ (로그인 사용자만) | App Functionality | Supabase (위탁) | Optional |
| Device or Other IDs | ❌ | — | — | — |
| Location | ❌ (사용자 선택 좌표만, 외부 전송 없음) | — | — | — |
| Photos and Videos | ❌ (사용자 기기 내부만) | — | — | — |
| App activity | ❌ (광고 도입 전까지) | — | — | — |
| App info and performance | ✅ | App crash/diagnostics | — | Optional |

### 암호화
- 전송 중: ✅ HTTPS/TLS
- 저장 중: ✅ Supabase 기본 암호화

### 사용자 권리
- 데이터 삭제 요청: ✅ (앱 내 계정 삭제 + 외부 URL)

---

## 3. Permissions

### Standard (정상 선언)
| 권한 | 기능 |
|------|------|
| CAMERA | QR 스캔 |
| NFC | NFC 태그 읽기·쓰기 |
| ACCESS_FINE/COARSE_LOCATION | 지도 태그 현재 위치 (사용자 명시적 요청 시) |
| READ_CONTACTS | 연락처 QR 생성 (사용자 명시적 요청 시) |
| READ_MEDIA_IMAGES | 갤러리에서 로고 이미지 선택 |
| WRITE_EXTERNAL_STORAGE (Android 9 이하) | QR 이미지 갤러리 저장 (legacy) |

### Sensitive (Declaration 필수)

#### QUERY_ALL_PACKAGES

**Use Case**: **App discovery** / Interacts with other apps on user's device

**제출 사유 (English, 필수)**:

```
AppTag is a utility that allows users to save deep-links of installed apps as physical QR codes or NFC tags. Listing installed apps on the user's device is the core functionality — users select from their installed apps to create a QR/NFC tag for that specific app. Without QUERY_ALL_PACKAGES, the core "select app to tag" flow cannot function.

We only read the package list; we never transmit it off-device. No data from the package list is sent to our servers. The displayed list is used solely within the app to let the user choose an app to create a QR/NFC tag for.
```

**Policy Compliance Confirmation**:
- ✅ 앱의 핵심 기능에 필수
- ✅ 대체 메커니즘 없음 (`<queries>` 만으로는 사용자 설치 앱 전체 탐색 불가)
- ✅ 개인정보 외부 전송 없음

---

## 4. Account Deletion (2024년 필수)

| 항목 | 값 |
|------|-----|
| In-app deletion | ✅ Profile → "계정 삭제" |
| Web URL (앱 미설치 사용자) | `https://tawool83.github.io/apptag-legal/account-deletion.html` |
| 삭제되는 데이터 | 계정 + 클라우드 백업 |
| 보관되는 데이터 | 없음 |
| 처리 기한 | 즉시 (앱 내) / 5영업일 (이메일) |

---

## 5. Store Listing (스토어 등록)

| 항목 | 요구사항 | 상태 |
|------|---------|------|
| App name | 최대 30자 | 예: "AppTag" |
| Short description | 최대 80자 | 작성 필요 |
| Full description | 최대 4000자 | 작성 필요 |
| App icon | 512×512 PNG (alpha 없음) | 확인 필요 |
| Feature graphic | 1024×500 | 작성 필요 |
| Screenshots (Phone) | 최소 2장, 권장 8장, 16:9 or 9:16 | 작성 필요 |
| Screenshots (Tablet 7" & 10") | 선택 | — |
| Category | Productivity / Tools | 선택 |

---

## 6. App Bundle 빌드 및 업로드

### 빌드 명령
```bash
flutter build appbundle --release
```

### 산출물 위치
```
build/app/outputs/bundle/release/app-release.aab
```

### Play App Signing
- 최초 업로드 시 Google 이 서명 키 관리 (권장)
- 업로드 키 분실 대비 백업 필수 (keystore 파일)

---

## 7. 출시 Track

| Track | 용도 |
|-------|------|
| Internal testing | 개발자/팀원 (100명 이하, 즉시 반영) |
| Closed testing | 제한된 베타 그룹 |
| Open testing | 공개 베타 |
| Production | 정식 출시 |

**권장 순서**: Internal → Closed → Open → Production

---

## 8. 출시 전 최종 체크

- [ ] Pre-launch report 정책 위반 0건
- [ ] Data Safety 작성 완료
- [ ] QUERY_ALL_PACKAGES declaration 승인
- [ ] Content Rating 설문 완료
- [ ] Privacy Policy URL 실제 접근 가능
- [ ] Account Deletion URL 실제 접근 가능
- [ ] 앱 내 정책 링크 4종 동작 확인
- [ ] 계정 삭제 기능 실제 동작 확인 (Supabase RPC)
- [ ] targetSdk = 35 빌드 성공

---

## 9. 광고·결제 도입 시 추가 작업 (향후)

광고 도입 시 `docs/01-plan/features/store-compliance.plan.md` Phase 4 참조, 결제 도입 시 Phase 5 참조. Data Safety 재작성 필수.
