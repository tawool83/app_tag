# App Store Connect 제출 체크리스트

> AppTag v1.0.0+1 · bundle ID: (Xcode project 에서 설정)
> 본 체크리스트는 App Store Connect 에 **사용자가 직접 입력**하는 메타데이터 가이드입니다.

---

## 1. App Information

| 항목 | 값 |
|------|-----|
| Primary Language | Korean (한국어) |
| Bundle ID | `com.tawool.app_tag` (또는 Xcode 설정에 따름) |
| SKU | `APPTAG001` (임의) |
| Primary Category | Productivity (생산성) |
| Secondary Category | Utilities (유틸리티, 선택) |

---

## 2. Pricing and Availability

| 항목 | 값 |
|------|-----|
| Price | Free (결제 도입 전까지) |
| Availability | All territories (권장) 또는 Korea + English-speaking countries |

---

## 3. App Privacy (Nutrition Label)

### Privacy Policy URL
`https://tawool83.github.io/apptag-legal/privacy-policy.html`

### Data Types Collected

| 데이터 카테고리 | Linked to User | Used for Tracking | 수집 목적 |
|------------------|----------------|-------------------|----------|
| **Contact Info → Email Address** | ✅ | ❌ | App Functionality |
| **Contact Info → Name** | ✅ (SSO 사용자) | ❌ | App Functionality |
| **User Content → Customer Support** | ❌ | ❌ | — |
| **User Content → Other User Content** (QR 데이터) | ✅ (로그인 시) | ❌ | App Functionality |
| **Identifiers → User ID** | ✅ | ❌ | App Functionality |
| **Diagnostics → Crash Data** | ❌ | ❌ | App Functionality |

### Data Not Collected
- Device or Other IDs (advertising IDs)
- Usage Data (광고 도입 전까지)
- Precise/Coarse Location (사용자가 선택한 지도 좌표만 사용, 외부 전송 없음)
- Sensitive Info
- Purchases (결제 도입 전까지)

### Tracking
- **Does your app collect data from this app and link it to the user's identity?** Yes (로그인 시)
- **Does your app use data for tracking?** **No** (광고·추적 SDK 미사용)

---

## 4. App Review Information

| 항목 | 값 |
|------|-----|
| Contact First Name | (입력) |
| Contact Last Name | (입력) |
| Contact Phone | (입력) |
| Contact Email | tawooltag@gmail.com |
| Demo Account (required if login) | 테스트 계정 이메일 + 비밀번호 |
| Notes | "Main features work without login. Login only required for cloud backup. Test account provided for optional features." |

---

## 5. Localization 메타데이터

### Required: Korean (ko)
- Name (최대 30자)
- Subtitle (최대 30자)
- Description (최대 4000자)
- Keywords (쉼표 구분, 최대 100자)
- Support URL: `mailto:tawooltag@gmail.com` 또는 별도 support 페이지
- Marketing URL (선택)

### Recommended: English (en-US)
- App Store 는 영문 메타데이터 강력 권장
- Name, Subtitle, Description, Keywords 영문 작성

---

## 6. Version Information (Build)

| 항목 | 값 |
|------|-----|
| Version | 1.0.0 |
| Build number | 1 |
| What's New (영문 필수) | 초도 출시 내용 |
| Copyright | © 2026 tawool (또는 법인명) |

### Promotional Text (170자, 버전 업데이트 없이 변경 가능)
- 선택

---

## 7. Screenshots (필수)

### 6.7" iPhone (iPhone 16 Pro Max) — **필수**
- 1290 × 2796 px (세로) 또는 2796 × 1290 (가로)
- 최소 3장, 권장 5장

### 6.5" iPhone (iPhone 14 Plus) — 선택 (6.7" 있으면 스케일됨)

### 12.9" iPad (iPad Pro) — **iPad 지원 시 필수**
- 2048 × 2732 px (세로) 또는 2732 × 2048 (가로)
- 최소 3장

### 5.5" iPhone — 2025년 현재 선택 사항

---

## 8. App Icon

- 1024 × 1024 PNG (alpha 채널 **없음**)
- 모서리 둥글게 처리 금지 (Apple 이 자동 처리)
- `flutter_launcher_icons` 로 생성된 아이콘 검증
  ```bash
  flutter pub run flutter_launcher_icons
  ```
- 검증 명령:
  ```bash
  sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
  # 결과: hasAlpha: no (바람직)
  ```

---

## 9. Age Rating Questionnaire

| 질문 | 답변 |
|------|------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Gambling | None |
| Contests | None |
| Unrestricted Web Access | None |
| Made for Kids | No |

**예상 등급**: **4+**

---

## 10. Privacy Manifest (코드에 포함됨)

- ✅ `ios/Runner/PrivacyInfo.xcprivacy` 작성됨 (Do phase Step 2)
- ✅ Xcode 에서 Runner target 에 file reference 추가 필요 (**수동 작업**)

### Xcode 파일 등록 방법
1. Xcode 에서 `ios/Runner.xcworkspace` 열기
2. Project Navigator 에서 **Runner** 폴더 우클릭 → "Add Files to 'Runner'..."
3. `ios/Runner/PrivacyInfo.xcprivacy` 선택
4. **Target: Runner** 체크 → Add
5. 확인: File Inspector 에서 Target Membership 에 "Runner" 체크됨

---

## 11. Encryption Export Compliance

- ✅ `ITSAppUsesNonExemptEncryption = false` Info.plist 에 추가됨
- 추가 작업 불필요 (매 빌드 업로드 시 다이얼로그 자동 생략)

---

## 12. Account Deletion (2022-06 이후 필수)

- ✅ 앱 내 "Profile → 계정 삭제" 구현됨
- 추가 스토어 메타데이터 입력 불필요 (Apple 은 Google Play 와 달리 외부 URL 요구하지 않음)

---

## 13. Sign in with Apple (필수)

- ✅ 이미 구현됨 (Supabase + `sign_in_with_apple` 패키지)
- Xcode Capabilities: **Sign in with Apple** 활성화 확인 필요

---

## 14. 출시 전 최종 체크

- [ ] Xcode validation 통과 (Archive → Validate App)
- [ ] App Store Connect 업로드 시 **Privacy Manifest 경고 0건**
- [ ] Nutrition Label 작성 완료
- [ ] Screenshots 업로드 (6.7" 최소 3장 + 12.9" iPad 최소 3장)
- [ ] App Icon alpha 없음 확인
- [ ] Sign in with Apple capability 활성화
- [ ] Demo account 제공
- [ ] Korean + English metadata 작성

---

## 15. TestFlight 단계

1. Internal Testing (Apple 즉시 승인)
2. External Testing (Apple 간단 리뷰, 수 시간)
3. App Store Review 제출 → 24-48시간 예상

---

## 16. 광고·결제 도입 시 추가 작업 (향후)

- 광고 도입: `NSUserTrackingUsageDescription`, `SKAdNetworkItems`, Nutrition Label 재작성
- 결제 도입: Paid Apps Agreement, IAP Products 등록, Restore Purchases UI (Guideline 3.1.1 필수)
- 상세는 `docs/01-plan/features/store-compliance.plan.md` Phase 4/5 참조
