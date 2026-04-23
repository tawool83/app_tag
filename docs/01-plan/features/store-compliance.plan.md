# Plan — Store Compliance (Google Play + App Store 심사 필수 항목)

> 생성일: 2026-04-23
> 최종 업데이트: 2026-04-23 (광고·결제 미래 요건 추가)
> Feature ID: `store-compliance`
> 대상 스토어: Google Play (Android) · App Store (iOS)
> 앱: AppTag v1.0.0+1, bundle `com.tawool.app_tag`
> 인증: Email / Google / Apple Sign-In (Supabase)
> **미래 기능 예정**: 광고 (AdMob/기타), 결제 (IAP: 구독·일회성)

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 출시 심사 필수 항목이 산재. `PrivacyInfo.xcprivacy`·개인정보처리방침·계정 삭제 URL 누락. 또한 **광고·결제(IAP) 도입 예정**으로 ATT·AD_ID·Billing·Subscription 정책 준비가 필요. |
| **Solution** | 양대 스토어 2025년 정책 기준 **출시용 Critical** + **광고/결제 기능 도입용 Future-ready** 체크리스트 통합. 항목별 상태(✅/⚠️/❌/📝/🔜) 분류. |
| **Function UX Effect** | 출시 단계: Drawer 정책 링크·계정 삭제 페이지 추가. 광고/결제 도입 단계: ATT 권한 다이얼로그·구매 복원·구독 해지 안내·GDPR Consent UI 추가. |
| **Core Value** | 출시 reject 차단 + 광고/결제 도입 시 추가 reject 위험 사전 차단 + GDPR/개인정보보호법 대응 일관성 확보. |

---

## 1. Scope & Out-of-Scope

### In-Scope
- 양대 스토어 2025년 출시 심사 필수 항목 catalog
- **광고 기능 도입 시 필수 정책** 사전 체크리스트 (ATT, AD_ID, GDPR Consent, Data Safety 업데이트)
- **결제(IAP) 기능 도입 시 필수 정책** 사전 체크리스트 (Billing, Subscription Terms, Restore, Tax)
- 코드/설정 (Android Manifest, iOS Info.plist, Privacy manifest)
- 앱 내부 UI (정책 링크, 계정 삭제 진입점, ATT 다이얼로그, 구매 복원 버튼 등)
- 메타데이터 작성 가이드 (실제 콘솔 입력은 사용자 작업)

### Out-of-Scope
- 실제 Play Console / App Store Connect 입력 (계정 권한 필요)
- 개인정보처리방침/이용약관 **법무 문구** 작성 (법무 검토 권장)
- 마케팅 ASO (Title/Description/Keywords 최적화)
- 광고 SDK 선택 (AdMob / AppLovin / Unity Ads 등 기술 결정은 별도 PDCA)
- 결제 엔진 선택 (`in_app_purchase` vs `flutter_inapp_purchase` 등 기술 결정은 별도 PDCA)
- 구독 상품 Pricing Strategy

---

## 2. 현재 구현 상태 조사 결과

### 2.1 인증·계정 (Auth)
- ✅ Email + Google + Apple SSO (Supabase)
- ✅ `deleteAccount` RPC 구현 (`supabase_auth_datasource.dart:101`)
- ✅ Profile 화면 계정 삭제 버튼 (`profile_screen.dart:126`)

### 2.2 권한 (Permissions)
**Android (`AndroidManifest.xml`)**:
- ✅ NFC, CAMERA, READ_CONTACTS
- ✅ ACCESS_FINE/COARSE_LOCATION
- ✅ READ_MEDIA_IMAGES (Android 13+)
- ✅ WRITE/READ_EXTERNAL_STORAGE (legacy maxSdk 명시)
- ⚠️ **QUERY_ALL_PACKAGES** — Google Play 민감 권한, 별도 declaration form 제출 필요

**iOS (`Info.plist`)**:
- ✅ NFCReaderUsageDescription
- ✅ NSCameraUsageDescription
- ✅ NSContactsUsageDescription
- ✅ NSLocationWhenInUseUsageDescription
- ✅ NSPhotoLibraryUsageDescription
- ✅ NSPhotoLibraryAddUsageDescription

### 2.3 Privacy 메타파일·정책
- ❌ `ios/Runner/PrivacyInfo.xcprivacy` (App Store **2024-05 이후 필수**)
- ❌ 개인정보처리방침 문서/URL (양대 스토어 **필수**)
- ❌ 이용약관 (App Store 권장)
- ❌ 앱 내 정책 링크 노출 (Drawer/About)

### 2.4 빌드 설정
- ✅ `applicationId`/`namespace`: `com.tawool.app_tag`
- ✅ `flutter_launcher_icons` 적용
- ⚠️ `targetSdk` = `flutter.targetSdkVersion` (Flutter 기본 의존) — 2025-08 이후 신규 앱 **API 35 (Android 15) 필수**
- ❌ `ITSAppUsesNonExemptEncryption` Info.plist 키

### 2.5 광고 (미구현 — 도입 예정)
- ❌ 광고 SDK 의존성 (미선택)
- ❌ ATT (App Tracking Transparency) 통합
- ❌ `NSUserTrackingUsageDescription` Info.plist
- ❌ Android `AD_ID` 권한 + POST_NOTIFICATIONS 연관 처리
- ❌ GDPR Consent Form (EU 사용자 대상)
- ❌ 광고 수집 항목 Data Safety 업데이트

### 2.6 결제·IAP (미구현 — 도입 예정)
- ❌ `in_app_purchase` 또는 동급 패키지 의존성
- ❌ Google Play Billing Library 연동
- ❌ StoreKit 2 (iOS) 연동
- ❌ 구매 복원 (Restore Purchases) UI
- ❌ 구독 상품 정의·콘솔 등록
- ❌ 영수증 검증 (서버 측, 권장 Supabase Edge Function)
- ❌ 구독 해지/환불 안내 링크
- ❌ 구독 약관 (Auto-renewal Terms) 앱 내 표기

### 2.7 콘텐츠 안전
- ⚠️ 사용자 생성 콘텐츠 (UGC) 있음 — QR 데이터, 템플릿 이름, 스티커 텍스트 → Apple App Store UGC 가이드라인 1.2 해당 시 신고·차단 메커니즘 필요

---

## 3. 필수 항목 종합 체크리스트

### 범례
- ✅ **완료** — 코드/설정 구현됨
- ⚠️ **부분** — 일부 구현 또는 추가 작업 필요
- ❌ **미구현** — 신규 작업 필요
- 📝 **메타데이터** — 콘솔 입력 (앱 코드 아닌 외부 작업)
- 🔜 **Future-ready** — 광고/결제 도입 시점에 필수
- 🔒 **Critical** — 출시 차단 risk
- 🟡 **Important** — reject 가능성, 우선순위 높음
- ⚪ **Recommended** — 권장 사항

---

### 3.1 Google Play 정책 필수 항목 (출시 기본)

| # | 항목 | 상태 | 위험도 | 비고 |
|---|------|------|--------|------|
| G-01 | Privacy Policy URL (Play Console) | ❌📝 | 🔒 | URL 호스팅 후 Console 입력 |
| G-02 | Privacy Policy 앱 내 링크 | ❌ | 🟡 | Drawer "프로그램 정보" 또는 Profile에 추가 |
| G-03 | **Account Deletion** — 앱 내 기능 | ✅ | 🔒 | `profile_screen.dart` 구현됨 |
| G-04 | **Account Deletion** — 외부 Web URL (Console 신청) | ❌📝 | 🔒 | 2024년부터 필수, 앱 미설치 사용자도 삭제 가능해야 함 |
| G-05 | Data Safety Form (Play Console) | ❌📝 | 🔒 | 수집 데이터·공유 여부·암호화 선언. **광고 도입 후 재작성 필수** |
| G-06 | Permissions 사용 목적 (Manifest 주석 + Console 설명) | ⚠️ | 🟡 | Manifest 주석 있음, Console 항목 별도 필요 |
| G-07 | **QUERY_ALL_PACKAGES Declaration** | ❌📝 | 🔒 | 민감 권한, 사용 사유 제출 필요 (앱태깅 핵심 기능). reject 사례 다수 |
| G-08 | **Target API Level** (2025-08: API 35) | ⚠️ | 🟡 | `flutter.targetSdkVersion` 의존 — Flutter SDK 업그레이드 확인 |
| G-09 | 64-bit 지원 | ✅ | 🔒 | Flutter 기본 |
| G-10 | App Bundle (.aab) 빌드 | ✅ | 🔒 | Flutter 기본 |
| G-11 | Content Rating Questionnaire | ❌📝 | 🔒 | Console 설문 |
| G-12 | App Category 선택 | ❌📝 | 🔒 | Console |
| G-13 | Screenshots / Feature Graphic | ❌📝 | 🔒 | 최소 2장 + 512×512 아이콘 + 1024×500 feature graphic |
| G-14 | Short/Full Description (4000자) | ❌📝 | 🔒 | Console |
| G-15 | App Access (로그인 정보 제공) | ❌📝 | 🟡 | 리뷰어용 테스트 계정 |
| G-16 | Sensitive Permissions Form (CAMERA/LOCATION/CONTACTS) | ❌📝 | 🟡 | 사유 작성 필요할 수 있음 |
| G-17 | Foreground Service Type (해당 시) | N/A | ⚪ | 사용 안 함 |

### 3.2 Google Play — 광고 도입 시 추가 필수 (🔜 Future)

| # | 항목 | 상태 | 위험도 | 비고 |
|---|------|------|--------|------|
| GA-01 | `AD_ID` 권한 (Android 13+ `com.google.android.gms.permission.AD_ID`) | ❌🔜 | 🔒 | Google Mobile Ads SDK 사용 시 필수. Android 13 이상 권한 선언 |
| GA-02 | Data Safety Form 업데이트 — 광고 데이터 수집 선언 | ❌📝🔜 | 🔒 | "Advertising or marketing" 데이터 타입 추가 |
| GA-03 | Google Play **Families Policy** 확인 | N/A | ⚪ | 어린이 대상 아니므로 영향 적음, 광고 대상 연령 확인 |
| GA-04 | **GDPR/UMP Consent** (EU 사용자) | ❌🔜 | 🔒 | Google User Messaging Platform SDK 또는 대체 consent SDK 도입 |
| GA-05 | IDFA/광고 ID Privacy Policy 명시 | ❌🔜 | 🔒 | 광고 식별자 수집·용도 명시 |
| GA-06 | Data Safety — "Shared with third parties" (광고 네트워크) | ❌📝🔜 | 🔒 | 광고 SDK 별 공유 대상 명시 |
| GA-07 | Deceptive Ads / 광고 배치 가이드라인 준수 | N/A🔜 | 🟡 | 광고 UI 구현 시 Google Play Ads Policy 참조 (reward ad, banner 구분) |
| GA-08 | COPPA (13세 미만) 대응 | ❌🔜 | ⚪ | 대상 연령 설정 (광고 네트워크 세팅) |

### 3.3 Google Play — 결제(IAP) 도입 시 추가 필수 (🔜 Future)

| # | 항목 | 상태 | 위험도 | 비고 |
|---|------|------|--------|------|
| GP-01 | `com.android.vending.BILLING` 권한 | ❌🔜 | 🔒 | `in_app_purchase` 의존성 자동 추가 |
| GP-02 | **Google Play Billing Library v7+** | ❌🔜 | 🔒 | 2024-08부터 v6 이상 필수 (v7 권장) |
| GP-03 | Google Play Console — **IAP 상품 등록** | ❌📝🔜 | 🔒 | Product ID, 가격, 구독 그룹 |
| GP-04 | **Monetization Setup** — Merchant 계정 + 세금·은행정보 | ❌📝🔜 | 🔒 | Play Console > Monetization setup |
| GP-05 | **Restore Purchases** UI (비구독 재다운 사용자 대응) | ❌🔜 | 🔒 | 앱 내 "구매 복원" 버튼 |
| GP-06 | **Subscription Terms 앱 내 명시** | ❌🔜 | 🔒 | 자동 갱신 주기, 가격, 해지 방법, 무료체험 조건 |
| GP-07 | **영수증 검증** (서버 측) | ❌🔜 | 🟡 | Google Play Developer API 또는 RTDN (Real-time Developer Notifications) |
| GP-08 | 구독 해지 링크 (`https://play.google.com/store/account/subscriptions`) | ❌🔜 | 🟡 | Google Play 내 이동 |
| GP-09 | **External Payment 사용 금지** 준수 | ❌🔜 | 🔒 | 디지털 재화는 Google Play Billing 만 허용 |
| GP-10 | **Free Trial / Introductory Price** UI 명시 | ❌🔜 | 🟡 | Apple 와 동일 수준 공시 |
| GP-11 | Data Safety — "Financial info" 수집 여부 선언 | ❌📝🔜 | 🔒 | Google Play Billing 사용 시 대부분 "not collected" |
| GP-12 | 환불 정책 링크 (이용약관 내) | ❌🔜 | 🟡 | 한국 전자상거래법 + Google Play 자체 환불 정책 |

### 3.4 App Store 정책 필수 항목 (출시 기본)

| # | 항목 | 상태 | 위험도 | 비고 |
|---|------|------|--------|------|
| A-01 | **`PrivacyInfo.xcprivacy`** (Privacy Manifest) | ❌ | 🔒 | **2024-05부터 필수**. Required Reason API 선언 |
| A-02 | Required Reason API declarations | ❌ | 🔒 | `UserDefaults`, `FileTimestamp` 등 사용 사유 코드 (A-01 내) |
| A-03 | App Privacy "Nutrition Label" (App Store Connect) | ❌📝 | 🔒 | Console 입력. **광고 도입 후 재작성** |
| A-04 | Privacy Policy URL (App Store Connect) | ❌📝 | 🔒 | G-01 과 동일 URL |
| A-05 | **Sign in with Apple** (제3자 SSO 사용 시 의무) | ✅ | 🔒 | 구현됨 |
| A-06 | **Account Deletion** (앱 내 기능) | ✅ | 🔒 | 2022-06 이후 필수, 구현됨 |
| A-07 | Account Deletion 명시적 위치 (Settings/Profile) | ✅ | 🔒 | Profile 노출됨 |
| A-08 | NSXxxUsageDescription strings | ✅ | 🔒 | 6종 모두 작성됨 |
| A-09 | `ITSAppUsesNonExemptEncryption` Info.plist 키 | ❌ | 🟡 | `false` 권장 (HTTPS 표준 암호화만 사용 시) |
| A-10 | EULA/이용약관 — Apple Standard EULA 또는 자체 | ⚠️📝 | 🟡 | 자체 약관 없으면 Apple 기본 자동 적용 |
| A-11 | Encryption Export Compliance (USEEAR 면제) | ⚠️📝 | 🟡 | A-09 로 자동 처리 |
| A-12 | **App Icon** (1024×1024 alpha 없음) | ⚠️ | 🔒 | 1024px alpha 제거 검증 필요 |
| A-13 | Launch Screen | ✅ | 🔒 | 기본 제공 |
| A-14 | Screenshots (각 디바이스 사이즈) | ❌📝 | 🔒 | 6.7" iPhone + 12.9" iPad 필수 |
| A-15 | App Description / Keywords / Support URL / Marketing URL | ❌📝 | 🔒 | Console |
| A-16 | App Review Information (테스트 계정·연락처) | ❌📝 | 🟡 | 리뷰어용 |
| A-17 | Age Rating Questionnaire | ❌📝 | 🔒 | Console |
| A-18 | Localization 메타데이터 (영문 필수) | ❌📝 | 🟡 | 최소 영문 description |
| A-19 | UGC 모더레이션 정책 (Guideline 1.2) | ⚠️ | 🟡 | QR/템플릿 텍스트 — 신고 메커니즘 권장 |
| A-20 | iOS 최소 버전 (`platform :ios`) | ✅ | ⚪ | Flutter 기본 12.0+ |

### 3.5 App Store — 광고 도입 시 추가 필수 (🔜 Future)

| # | 항목 | 상태 | 위험도 | 비고 |
|---|------|------|--------|------|
| AA-01 | **`NSUserTrackingUsageDescription`** Info.plist | ❌🔜 | 🔒 | IDFA/추적 사용 시 필수. 사용자 친화적 문구 필요 |
| AA-02 | **ATT (App Tracking Transparency) 권한 요청 UI** | ❌🔜 | 🔒 | `app_tracking_transparency` 패키지. 첫 광고 이벤트 전 호출 |
| AA-03 | ATT 거부 시 비개인화 광고 fallback | ❌🔜 | 🔒 | 광고 SDK 옵션 또는 별도 경로 |
| AA-04 | App Privacy Nutrition Label 업데이트 — "Identifiers" + "Usage Data" + "Linked to You" | ❌📝🔜 | 🔒 | 광고 도입 후 Connect 재작성 |
| AA-05 | PrivacyInfo.xcprivacy — 광고 SDK Required Reason API 추가 | ❌🔜 | 🔒 | SDK 벤더가 자체 Privacy Manifest 제공해야 함 (2024-05+) |
| AA-06 | SKAdNetwork 식별자 (SKAN) Info.plist 등록 | ❌🔜 | 🔒 | `SKAdNetworkItems` key — 광고 SDK가 요구하는 모든 네트워크 ID 등록 |
| AA-07 | Apple Ad Attribution 가이드라인 준수 | ❌🔜 | 🟡 | Guideline 5.1.2 |
| AA-08 | GDPR Consent (EU) — **ATT 와 별도 관리** | ❌🔜 | 🔒 | Apple 정책상 ATT 다이얼로그가 legal basis 아님. CMP 필요 |
| AA-09 | 광고 라벨링 (네이티브 광고 "Sponsored/Ad" 표시) | ❌🔜 | 🟡 | Apple Review Guideline 2.3.12 |

### 3.6 App Store — 결제(IAP) 도입 시 추가 필수 (🔜 Future)

| # | 항목 | 상태 | 위험도 | 비고 |
|---|------|------|--------|------|
| AP-01 | **StoreKit 2** 통합 (`in_app_purchase`) | ❌🔜 | 🔒 | Flutter 표준 패키지 |
| AP-02 | **Paid Apps Agreement** (App Store Connect) | ❌📝🔜 | 🔒 | Agreement, Tax, Banking 설정 |
| AP-03 | **IAP Product 등록** (Consumable/Non-Consumable/Subscription) | ❌📝🔜 | 🔒 | Connect > In-App Purchases |
| AP-04 | **Subscription Groups** 정의 | ❌📝🔜 | 🔒 | 구독 있을 경우. 업그레이드·다운그레이드 규칙 |
| AP-05 | **Restore Purchases** 버튼 — App Store Review Guideline 3.1.1 **필수** | ❌🔜 | 🔒 | Non-consumable/Subscription 있으면 앱 내 "구매 복원" 필수 |
| AP-06 | **Subscription Disclosure** 앱 내 표기 — Guideline 3.1.2 | ❌🔜 | 🔒 | Title, Duration, Price, Auto-renewal 문구 필수 |
| AP-07 | **구독 약관 + Privacy Policy 링크** 결제 화면 내 | ❌🔜 | 🔒 | 링크 실제 동작 확인 |
| AP-08 | **Free Trial / Introductory Offer** 공시 | ❌🔜 | 🔒 | 기간 종료 후 자동 갱신 가격 명시 |
| AP-09 | 구독 관리 링크 (`https://apps.apple.com/account/subscriptions`) | ❌🔜 | 🟡 | Apple 내 이동 |
| AP-10 | **영수증 검증** (서버 측, 권장 Supabase Edge Function) | ❌🔜 | 🟡 | App Store Server API + notificationsV2 |
| AP-11 | **Family Sharing 지원 여부** (Non-consumable/Subscription) | ❌🔜 | ⚪ | 지원 시 Connect 에서 opt-in |
| AP-12 | **External Payment Link 사용 금지** (EU 예외 존재) | ❌🔜 | 🔒 | 디지털 재화는 StoreKit 만 사용 (EU 에서만 Apple External Link Entitlement 별도 승인 후 가능) |
| AP-13 | App Store Connect **"App Information" > Privacy > Data Collected** 업데이트 | ❌📝🔜 | 🔒 | "Purchases" 데이터 타입 추가 |
| AP-14 | 환불 정책 — Apple 자체 정책 + 한국 전자상거래법 고지 | ❌🔜 | 🟡 | 이용약관 내 표기 |

### 3.7 양대 공통 (개인정보·법무)

| # | 항목 | 상태 | 위험도 | 비고 |
|---|------|------|--------|------|
| C-01 | **개인정보처리방침** 문서 (HTML/MD) | ❌ | 🔒 | 한국어·영문. 광고/결제 도입 시 재작성 |
| C-02 | 개인정보처리방침 호스팅 URL | ❌📝 | 🔒 | GitHub Pages 등 |
| C-03 | 이용약관 문서 (구독·환불 조항 포함) | ❌ | 🟡 | 결제 도입 시 필수 확장 |
| C-04 | 이용약관 URL | ❌📝 | 🟡 | C-03 호스팅 |
| C-05 | 데이터 삭제 안내 페이지 (G-04 연동) | ❌ | 🔒 | 앱 미설치 사용자 대응 |
| C-06 | 오픈소스 라이선스 페이지 | ⚠️ | ⚪ | Flutter `showAboutDialog` 자동 포함 — 확인 필요 |
| C-07 | 연락처/문의 채널 (이메일·웹) | ❌📝 | 🟡 | Support URL |
| C-08 | 14세 미만 동의 처리 (한국 정보통신망법) | ⚠️ | ⚪ | 광고·결제 도입 시 재평가 |
| C-09 | **GDPR Cookie/Consent** (EU 출시 시) | ❌🔜 | 🔒 | 광고 SDK 도입 후 필수. Google UMP 또는 대체 CMP |
| C-10 | **결제·구독 전용 약관 섹션** (이용약관 내) | ❌🔜 | 🔒 | 자동 갱신·해지·환불 조건, 한국 전자상거래법 공시 |

---

## 4. 우선순위·작업 그룹 (단계별)

### 🔒 Phase 1 — 출시 차단 Critical (현재 시점 즉시)
**목표: 광고·결제 없는 1차 출시 통과**

1. **C-01 + C-02**: 개인정보처리방침 작성 + GitHub Pages 호스팅
2. **A-01 + A-02**: `ios/Runner/PrivacyInfo.xcprivacy` 작성 (현재 사용 중인 API만 선언)
   - Hive / shared_preferences (UserDefaults) — `CA92.1`
   - path_provider (FileTimestamp) — `C617.1`
3. **G-04 + C-05**: 계정 삭제 안내 외부 페이지
4. **G-02**: 앱 내 정책 링크 (Drawer "프로그램 정보" dialog 확장 또는 Profile)
5. **G-07**: `QUERY_ALL_PACKAGES` 사유 정리 → Console declaration 준비
6. **A-09**: Info.plist `ITSAppUsesNonExemptEncryption = false`

### 🟡 Phase 2 — 출시 Important (Phase 1 완료 후)
1. **G-08**: targetSdk 35 명시
2. **A-12**: 1024×1024 아이콘 alpha 채널 제거 검증
3. **C-03 + C-04**: 이용약관 작성·호스팅 (광고·결제 확장 고려한 기본 구조)
4. **A-19**: UGC 신고 메커니즘 (mailto: 링크라도)
5. **A-18**: 영문 description 최소 작성
6. **C-06**: `showLicensePage` 노출 확인

### 📝 Phase 3 — 출시용 콘솔 메타데이터 (사용자 작업)
- G-01, G-05, G-11~G-16 (Play Console)
- A-03, A-04, A-14~A-17 (App Store Connect)
- 별도 가이드 문서로 분리

### 🔜 Phase 4 — 광고 도입 시 (별도 PDCA 트리거)
**광고 기능 개발 시 본 Plan을 참조**

1. **C-09**: GDPR Consent SDK 통합 (Google UMP 추천)
2. **AA-01 + AA-02 + AA-03**: iOS ATT 권한·UI
3. **GA-01**: Android `AD_ID` 권한
4. **AA-06**: `SKAdNetworkItems` Info.plist
5. **AA-05**: 광고 SDK 벤더가 제공하는 PrivacyInfo 병합
6. **GA-04 + GA-05**: 광고 데이터 Privacy Policy 업데이트
7. **G-05 + A-03 재작성**: Data Safety + Nutrition Label 업데이트
8. **AA-09**: 네이티브 광고 "Ad/Sponsored" 라벨링
9. **GA-07**: Google Play Ads Policy 준수 (광고 배치 검토)

### 🔜 Phase 5 — 결제(IAP) 도입 시 (별도 PDCA 트리거)
**결제 기능 개발 시 본 Plan을 참조**

1. **GP-04 + AP-02**: Monetization/Paid Apps Agreement 완료 (콘솔)
2. **AP-01**: `in_app_purchase` 패키지 통합
3. **GP-02**: Google Play Billing v7+ 검증
4. **GP-03 + AP-03**: 상품 등록 (Product IDs)
5. **AP-04**: Subscription Groups (구독 시)
6. **GP-05 + AP-05**: **"구매 복원" 버튼** (Apple 필수)
7. **GP-06 + AP-06 + AP-07 + AP-08**: 구독 약관·가격·해지 방법 명시 UI
8. **C-10**: 이용약관 결제·구독 섹션 확장
9. **GP-07 + AP-10**: 서버 측 영수증 검증 (Supabase Edge Function)
10. **GP-08 + AP-09**: 구독 관리 링크 (Play/App Store 표준 URL)
11. **AP-13**: Connect Privacy 메타데이터 "Purchases" 추가
12. **GP-11**: Data Safety "Financial info" 항목 업데이트
13. **AP-14 + GP-12**: 한국 전자상거래법 환불 정책 명시

### ⚪ Phase 6 — Recommended
- 다국어 메타데이터 확장
- App Bundle 서명 키 백업 가이드

---

## 5. 코드 변경 범위 요약 (단계별)

### Phase 1+2 (현재 시점 출시용)
| 종류 | 대상 | 예상 |
|------|------|------|
| 신규 | `ios/Runner/PrivacyInfo.xcprivacy` | ~50줄 |
| 신규 | `docs/legal/privacy-policy.{ko,en}.md` | 2개 |
| 신규 | `docs/legal/terms.{ko,en}.md` | 2개 |
| 신규 | `docs/legal/account-deletion.md` | 1개 |
| 신규 | `docs/store-compliance/play-console-checklist.md` | 1개 |
| 신규 | `docs/store-compliance/app-store-connect-checklist.md` | 1개 |
| 수정 | `ios/Runner/Info.plist` | +2줄 |
| 수정 | `lib/features/home/home_screen.dart` | ~30줄 |
| 수정 | `android/app/build.gradle.kts` | +1줄 |
| 수정 | `lib/l10n/app_ko.arb` | +5키 |

### Phase 4 (광고 도입 시 추가 예상)
| 종류 | 대상 | 예상 |
|------|------|------|
| 신규 | `lib/features/consent/` (GDPR Consent UI) | R-series pattern, ~300줄 |
| 신규 | ATT 권한 요청 흐름 (iOS only) | ~100줄 |
| 수정 | `ios/Runner/Info.plist` (`NSUserTrackingUsageDescription`, `SKAdNetworkItems`) | ~30줄 |
| 수정 | `AndroidManifest.xml` (`AD_ID` 권한) | +1줄 |
| 수정 | `PrivacyInfo.xcprivacy` (광고 SDK API 추가) | +20줄 |
| 수정 | `docs/legal/privacy-policy` (광고 데이터 섹션) | 확장 |
| 신규 | 광고 SDK wrapper (별도 PDCA 결정) | — |

### Phase 5 (결제 도입 시 추가 예상)
| 종류 | 대상 | 예상 |
|------|------|------|
| 신규 | `lib/features/iap/` (구매·복원·검증 플로우) | R-series, ~800줄 |
| 신규 | 구독 상품 UI (가격·해지·자동갱신 공시) | ~400줄 |
| 신규 | `supabase/functions/verify-iap/` (영수증 검증) | ~200줄 (TypeScript) |
| 수정 | `docs/legal/terms` (결제·구독 섹션) | 확장 |
| 신규 | Restore Purchases 화면 | ~150줄 |
| 신규 | 영수증 검증 후 사용자 entitlement 업데이트 로직 | ~100줄 |

---

## 6. Architecture (CLAUDE.md 고정값)

- Framework: Flutter
- State Management: Riverpod StateNotifier
- 로컬 저장: Hive
- 라우팅: go_router
- **신규 feature (legal, consent, iap)** 도입 시 → R-series Provider 패턴 + Clean Architecture 디렉터리 구조
- 광고/결제 도입 시 별도 feature 디렉터리:
  - `lib/features/consent/` (GDPR · ATT)
  - `lib/features/iap/` (구매·구독·복원)
  - `lib/features/legal/` (약관·정책 화면)

---

## 7. 검증 체크리스트 (Phase 별)

### Phase 1+2 완료 검증
- [ ] `flutter build appbundle --release` 성공
- [ ] `flutter build ipa --release` + Xcode validation 통과
- [ ] App Store Connect upload 시 Privacy Manifest 경고 없음
- [ ] Play Console pre-launch report 정책 위반 0건
- [ ] 앱 내 정책 링크 외부 브라우저 정상 이동
- [ ] 계정 삭제 RPC 실제 동작

### Phase 4 (광고) 완료 검증
- [ ] iOS 신규 설치 → 첫 광고 전 ATT 다이얼로그 표시
- [ ] ATT 거부 시 비개인화 광고로 fallback
- [ ] EU IP 접속 → GDPR Consent 화면 표시
- [ ] SKAdNetwork 식별자 모두 등록 확인 (광고 SDK 문서와 대조)
- [ ] App Store Connect Nutrition Label 업데이트 완료
- [ ] Play Console Data Safety 업데이트 완료

### Phase 5 (결제) 완료 검증
- [ ] Sandbox 환경에서 구매 성공
- [ ] **구매 복원** 버튼으로 기존 구매 복원 성공 (Apple 필수)
- [ ] 구독 자동 갱신 문구 가시성 (UI screenshot 기록)
- [ ] 해지 링크 동작 (Play/App Store 이동)
- [ ] 영수증 검증 서버 응답 검증
- [ ] 환불 시 entitlement 회수 동작

---

## 8. 위험·전제

### 위험
1. **법무 검토 부재**: 본 Plan은 "심사 통과 기준"만 다룸. 정책 문서 법적 정확성은 별도 법무 검토 필요.
2. **Apple Privacy Manifest 정책 변동**: Required Reason API 목록이 주기적으로 확장. 광고·결제 SDK 도입 시 SDK 벤더 업데이트 확인.
3. **Google Play 정책 변동**: API level/Billing Library 요구가 매년 갱신.
4. **광고 SDK 호환성**: AdMob 외 다른 SDK 선택 시 SKAdNetwork·PrivacyInfo 요구 상이.
5. **결제 환불 분쟁**: 한국 전자상거래법과 Apple/Google 환불 정책 간 충돌 소지 — 이용약관에 명확히 분리 기재.
6. **QUERY_ALL_PACKAGES**: Google Play 승인 거부 시 권한 제거 + `<queries>` element 대체 필요 — 일부 기능 제한 가능.
7. **EU External Payment Link**: 2024년 DMA 규제로 EU 한정 Apple External Link 허용 — 한국 대상이면 무관.

### 전제
- 본 Plan은 **현재 미구현 기능(광고·결제)의 정책 요건을 사전 문서화**. 실제 구현은 해당 기능 별도 PDCA 사이클로 진행.
- 어린이 대상 앱 아님 (COPPA/Family 정책 영향 작음)
- 한국·영어권 1차 출시 가정 (EU 진출 시 GDPR 재검토)

---

## 9. Next Steps

1. 사용자 승인 후 → `/pdca design store-compliance` (Phase 1+2 범위)
2. Phase 1+2 완료 후 Phase 3 메타데이터 입력 가이드 문서 생성
3. 광고 기능 개발 착수 시점 → `/pdca plan ads-integration` 별도 feature 로 시작, 본 Plan Phase 4 참조
4. 결제 기능 개발 착수 시점 → `/pdca plan iap-integration` 별도 feature 로 시작, 본 Plan Phase 5 참조
