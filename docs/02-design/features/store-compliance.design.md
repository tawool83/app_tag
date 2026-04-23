# Design — Store Compliance (Phase 1 + 2 범위)

> 생성일: 2026-04-23
> Feature ID: `store-compliance`
> Plan 문서: `docs/01-plan/features/store-compliance.plan.md`
> 범위: **Phase 1 (Critical) + Phase 2 (Important)** — 광고/결제 없는 1차 출시용
> Phase 4(광고), Phase 5(결제)는 기능 착수 시 별도 PDCA 로 분리

---

## 1. Architecture 결정 (CLAUDE.md 고정)

| 항목 | 값 | 근거 |
|------|-----|------|
| Framework | Flutter | 프로젝트 전역 고정 |
| State Management | Riverpod StateNotifier | R-series 패턴 — 다만 이번 feature 는 static doc + config 비중 ↑, Notifier 신규 없음 |
| 로컬 저장 | Hive | 이번 feature 영향 없음 |
| 라우팅 | go_router | 신규 라우트 없음 (Drawer → Dialog 재사용) |
| 외부 링크 | `url_launcher ^6.3.0` | **이미 pubspec 에 포함**, 추가 의존성 0 |

**왜 R-series 신규 Notifier 없음?**
- 본 Plan Phase 1+2 는 **정적 문서 + config + Drawer UI 링크 3개** 가 전부
- 상태 보유·변경이 필요한 로직 없음 — `StatelessWidget` + `url_launcher` 만으로 충족
- "Claude 가독성 최우선" 원칙(CLAUDE.md): 불필요한 Provider 껍데기 금지

Phase 4(광고)·Phase 5(결제) 진입 시 `lib/features/consent/`, `lib/features/iap/` 신규 feature 디렉터리로 R-series 적용 — 본 설계에서는 out-of-scope.

---

## 2. 디렉터리 트리 (변경 후)

```
app_tag/
├── android/app/
│   ├── build.gradle.kts                     # [수정] targetSdk 명시
│   └── src/main/AndroidManifest.xml         # [수정] 권한 주석 확장 (QUERY_ALL_PACKAGES 사유 명시)
│
├── ios/Runner/
│   ├── Info.plist                           # [수정] ITSAppUsesNonExemptEncryption 추가
│   └── PrivacyInfo.xcprivacy                # [신규] Privacy Manifest
│
├── lib/
│   ├── core/constants/
│   │   └── legal_urls.dart                  # [신규] 정책·약관·삭제 URL 상수
│   ├── features/home/
│   │   └── home_screen.dart                 # [수정] About dialog children 확장
│   └── l10n/
│       └── app_ko.arb                       # [수정] legal link 라벨 키 추가
│
└── docs/
    ├── legal/
    │   ├── privacy-policy.ko.md             # [신규] 개인정보처리방침 (한국어)
    │   ├── privacy-policy.en.md             # [신규] 영문 (최소)
    │   ├── terms.ko.md                      # [신규, Phase 2] 이용약관 (한국어)
    │   ├── terms.en.md                      # [신규, Phase 2] 영문
    │   └── account-deletion.md              # [신규] 계정 삭제 안내 (양대 스토어 요구 외부 URL 대상)
    └── store-compliance/
        ├── play-console-checklist.md        # [신규] Play Console 입력 가이드 (메타데이터)
        └── app-store-connect-checklist.md   # [신규] App Store Connect 입력 가이드
```

**총 신규 파일: 10개** · **수정 파일: 5개**

---

## 3. 파일별 상세 설계

### 3.1 `ios/Runner/PrivacyInfo.xcprivacy` (신규)

**목적**: Apple 2024-05 이후 필수 Privacy Manifest. 현재 앱이 사용하는 Required Reason API 선언.

**조사한 사용 지점**:
| API 카테고리 | 사용 패키지 | 사용 지점 | Required Reason Code |
|-------------|-------------|-----------|----------------------|
| `NSPrivacyAccessedAPICategoryUserDefaults` | `shared_preferences` | `SettingsService` | **CA92.1** (사용자 선호값 저장용, 앱 내부 전용) |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `path_provider`, `image_gallery_saver` | QR 이미지 공유·저장 | **C617.1** (파일을 사용자에게 표시하기 위함) |
| `NSPrivacyAccessedAPICategorySystemBootTime` | 없음 | — | N/A |
| `NSPrivacyAccessedAPICategoryDiskSpace` | 없음 (`path_provider` 내부 사용 가능성) | — | N/A |

**Data Types 수집 여부**:
- `NSPrivacyCollectedDataTypes` = 비어 있음 선언 (`supabase_flutter` 는 사용자 개인정보를 수집하지만, **선택적 로그인 사용자에 한함**. 기본 상태는 비수집)
- ⚠️ Supabase 로그인 사용자 데이터는 본 manifest 가 아닌 **Nutrition Label** 에서 선언 → Phase 3 콘솔 작업

**Tracking 여부**: `NSPrivacyTracking = false` (광고·추적 SDK 미사용)

**예상 plist 구조**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Xcode 프로젝트 포함 방법**:
- 파일을 `ios/Runner/` 에 저장
- `ios/Runner.xcodeproj/project.pbxproj` 에 file reference 추가 (Xcode 에서 Add Files to Runner)
- `pubspec.lock` 과 무관, 빌드 시 자동 번들 포함

---

### 3.2 `ios/Runner/Info.plist` 수정

**추가 키 1개**:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

**위치**: `<dict>` 내, 기존 `CADisableMinimumFrameDurationOnPhone` 부근

**근거**:
- 앱이 HTTPS 표준 암호화만 사용 (Supabase 통신, Google/Apple SSO 등 OS 표준 TLS)
- 자체 암호화 알고리즘·큰 키 사용하지 않음 → **Exempt** 해당
- `false` 선언 시 매 빌드 업로드마다 Xcode/App Store Connect 에서 묻지 않음

**변경 diff (예상 2줄)**:
```diff
 <dict>
   <key>CADisableMinimumFrameDurationOnPhone</key>
   <true/>
+  <key>ITSAppUsesNonExemptEncryption</key>
+  <false/>
   <key>CFBundleDevelopmentRegion</key>
```

---

### 3.3 `android/app/build.gradle.kts` 수정

**현재**: `targetSdk = flutter.targetSdkVersion` (Flutter SDK 버전에 위임)

**변경**: 명시적 버전 선언 + 주석

```kotlin
// targetSdk: Google Play 신규 앱은 2025-08 이후 API 35 필수.
// Flutter 3.24+ 는 기본 35 지원. 명시 선언으로 빌드 일관성 확보.
targetSdk = 35
```

**근거**: Google Play 2025-08-31 이후 신규 앱 targetSdk 35 미만 거부. `flutter.targetSdkVersion` 은 Flutter 버전에 따라 바뀔 수 있어 빌드 재현성 위해 명시.

**주의**: Flutter SDK 가 35 미만을 반환하면 오히려 빌드 실패 가능. Flutter 3.24+ 프로젝트 확인 필요. (현재 `pubspec.lock` 기준 Dart ^3.x 사용 → Flutter 3.22+ 추정)

---

### 3.4 `android/app/src/main/AndroidManifest.xml` 수정

**수정 내용**: 주석만 보강 (코드 변경 없음, Play Console declaration 작성 위한 사유 문서화)

```xml
<!-- 앱 목록 조회 (Android 11+) —
     사유: AppTag 는 설치된 앱의 딥링크를 QR/NFC 로 저장하는 앱이므로
     사용자 기기의 앱 목록 조회가 핵심 기능.
     Play Console Declaration:
       - Use case: App discovery
       - Sub-category: Interacts with other apps on a user's device
  -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

**실제 Console 제출 사유** (play-console-checklist.md 에 전문 수록):
> AppTag is a utility that allows users to save deep-links of installed apps as physical QR codes or NFC tags. Listing installed apps is the core functionality — users select from their installed apps to create a QR/NFC tag for that specific app. Without QUERY_ALL_PACKAGES the core "select app" flow cannot function.

---

### 3.5 `lib/core/constants/legal_urls.dart` (신규)

**목적**: URL 하드코딩 분산 방지. 단일 진실 원천.

```dart
/// 법적 문서·정책 외부 URL 상수.
///
/// 호스팅 위치: GitHub Pages (`tawool83.github.io/apptag-legal/`)
/// 변경 시 이 파일만 수정하면 모든 참조 위치 업데이트.
class LegalUrls {
  LegalUrls._();

  /// 개인정보처리방침. 양대 스토어 Console 에서도 동일 URL 사용.
  static const privacyPolicy =
      'https://tawool83.github.io/apptag-legal/privacy-policy.html';

  /// 이용약관 (Phase 2 이후 활성).
  static const termsOfService =
      'https://tawool83.github.io/apptag-legal/terms.html';

  /// 계정 삭제 안내 — Google Play 2024 필수 외부 URL.
  /// 앱 미설치 상태에서도 접근 가능해야 함.
  static const accountDeletion =
      'https://tawool83.github.io/apptag-legal/account-deletion.html';

  /// 지원/문의 (메일 또는 폼). Support URL.
  static const support = 'mailto:tawool83@gmail.com';
}
```

**네이밍 규칙**: `camelCase` 상수, private constructor, 클래스로 그룹핑 (enum 부적합 — URL 문자열이라 extension·tap 메서드 없이 단순 참조만).

**사용 예** (`home_screen.dart` 내):
```dart
launchUrl(Uri.parse(LegalUrls.privacyPolicy), mode: LaunchMode.externalApplication);
```

---

### 3.6 `lib/features/home/home_screen.dart` 수정

**현재 `_showAppInfoDialog` (L230-246)** 의 `children` 리스트에 ListTile 3개 추가.

**설계 이유**: `showAboutDialog` 의 `children` 은 임의 Widget 허용. ListTile 이 Dialog 내 일관된 UI 패턴 — 새 화면 신설 불필요.

**변경 후 구조**:
```dart
Future<void> _showAppInfoDialog() async {
  final info = await PackageInfo.fromPlatform();
  if (!mounted) return;
  final l10n = AppLocalizations.of(context)!;
  showAboutDialog(
    context: context,
    applicationName: l10n.appTitle,
    applicationVersion: '${info.version} (${l10n.appInfoBuild} ${info.buildNumber})',
    applicationIcon: Image.asset('assets/img/logo.png', width: 64, height: 64),
    children: [
      const SizedBox(height: 16),
      Text('${l10n.appInfoTemplateEngine} v$kTemplateEngineVersion'),
      const SizedBox(height: 4),
      Text('${l10n.appInfoTemplateSchema} v$kTemplateSchemaVersion'),
      const Divider(height: 24),
      // 정책·약관·계정 삭제 링크
      _LegalLinkTile(
        icon: Icons.privacy_tip_outlined,
        label: l10n.legalPrivacyPolicy,
        url: LegalUrls.privacyPolicy,
      ),
      _LegalLinkTile(
        icon: Icons.description_outlined,
        label: l10n.legalTermsOfService,
        url: LegalUrls.termsOfService,
      ),
      _LegalLinkTile(
        icon: Icons.person_remove_outlined,
        label: l10n.legalAccountDeletion,
        url: LegalUrls.accountDeletion,
      ),
      _LegalLinkTile(
        icon: Icons.mail_outline,
        label: l10n.legalSupport,
        url: LegalUrls.support,
      ),
    ],
  );
}
```

**`_LegalLinkTile` 내부 위젯 추가** (파일 말미):
```dart
/// 프로그램 정보 dialog 내 외부 링크용 컴팩트 ListTile.
class _LegalLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LegalLinkTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
```

**import 추가**:
```dart
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/legal_urls.dart';
```

**파일 크기**: 현재 ~400줄 + 추가 ~40줄 = 440줄 → CLAUDE.md 하드룰 "UI part ≤ 400줄" 근접. 초과 시 `_LegalLinkTile` 을 별도 `home_screen/legal_link_tile.dart` 로 분리.

---

### 3.7 `lib/l10n/app_ko.arb` 수정

CLAUDE.md 정책: **ko 만 선반영**, 다른 9개 언어는 ko fallback.

**추가 키 4개**:
```json
{
  "legalPrivacyPolicy": "개인정보처리방침",
  "legalTermsOfService": "이용약관",
  "legalAccountDeletion": "계정 삭제 안내",
  "legalSupport": "문의하기"
}
```

**배치 위치**: `drawerAppInfo` 키 근처 (기능적 응집).

**적용 후 작업**:
- `flutter gen-l10n` 으로 Dart 자동 재생성
- 다른 9개 arb/dart 는 untranslated 경고만 나옴 (정상)

---

### 3.8 `docs/legal/privacy-policy.ko.md` (신규)

**구조** (법적 정확성 < 심사 통과 목적, 실제 서비스 전 법무 검토 권장):

```markdown
# AppTag 개인정보처리방침

최종 업데이트: 2026-04-23

## 1. 수집하는 개인정보 항목

### 1.1 회원 가입 시 (선택)
- 이메일 주소 (Email 로그인)
- 구글/애플 제공 프로필 정보 (이름, 이메일) — SSO 사용 시

### 1.2 서비스 이용 시 자동 수집
- 기기 정보 (OS 버전, 앱 버전)
- 로그 데이터 (에러·크래시)

### 1.3 사용자가 직접 입력·생성한 데이터
- QR 코드 콘텐츠 (URL, 텍스트, 연락처, 위치 좌표 등)
- 템플릿 이름, 스티커 텍스트

## 2. 개인정보 수집·이용 목적
- 회원 식별 및 계정 관리
- 사용자 생성 QR 코드의 클라우드 백업 (선택적)
- 서비스 안정성 및 품질 개선

## 3. 보관 및 파기
- 회원 탈퇴 시 즉시 파기
- 법령에 따른 보관 의무 없음

## 4. 제3자 제공
- 제3자 제공 없음
- 사용되는 외부 서비스: Supabase (인증·데이터 저장 위탁)

## 5. 사용자 권리
- 개인정보 열람·정정·삭제 요청 가능 (앱 내 "계정 삭제" 또는 문의 메일)
- 계정 삭제 → Supabase 데이터 즉시 삭제

## 6. 데이터 저장 위치
- 로컬 기기 (Hive): 사용자 생성 템플릿·QR Task·스캔 히스토리
- 클라우드 (Supabase): 로그인 사용자의 백업 템플릿 (ap-northeast-2 region)

## 7. 연락처
- 이메일: tawool83@gmail.com
```

**영문판 `privacy-policy.en.md`**: 동일 구조 영역·단락 번호 유지, 최소 영문 번역.

---

### 3.9 `docs/legal/terms.ko.md` (신규, Phase 2)

**구조 (결제·광고 도입 전 최소 버전, 향후 확장 고려)**:

```markdown
# AppTag 이용약관

최종 업데이트: 2026-04-23

## 1. 서비스 개요
AppTag는 스마트폰 앱 딥링크를 QR 코드·NFC 태그로 저장·공유하는 유틸리티 앱입니다.

## 2. 계정 및 이용
- 주요 기능은 로그인 없이 사용 가능
- 클라우드 백업 등 일부 기능은 계정 필요

## 3. 금지 행위
- 불법·유해 콘텐츠를 QR 코드로 생성·배포
- 타인의 지적재산권 침해
- 서비스 역공학·상용 목적 무단 이용

## 4. 책임 제한
- 사용자 생성 콘텐츠에 대한 책임은 해당 사용자에게 있음
- 당사는 사용자 간 분쟁에 개입하지 않음

## 5. 약관 변경
약관 변경 시 앱 업데이트 또는 이메일로 고지합니다.

## 6. 문의
- 이메일: tawool83@gmail.com

---

<!-- Phase 5 결제 도입 시 아래 섹션 추가 예정 -->
<!-- ## 7. 유료 서비스 및 구독 -->
<!-- ## 8. 환불 정책 -->
<!-- ## 9. 자동 갱신 조건 -->
```

---

### 3.10 `docs/legal/account-deletion.md` (신규)

**용도**: Google Play Console 에서 입력하는 **외부 계정 삭제 안내 URL** 대상 페이지. 앱 미설치 사용자도 접근해서 삭제 가능해야 함.

```markdown
# AppTag 계정 삭제 안내

AppTag 계정을 삭제하시려면 아래 두 가지 방법 중 하나를 선택하세요.

## 방법 1 — 앱 내에서 직접 삭제 (권장)
1. AppTag 앱 실행
2. 하단 "프로필" 탭 이동
3. "계정 삭제" 버튼 탭
4. 확인 다이얼로그에서 "삭제" 선택
→ 즉시 모든 데이터 삭제 및 계정 폐기

## 방법 2 — 이메일로 삭제 요청
앱이 설치되지 않은 경우:
- 수신 이메일: **tawool83@gmail.com**
- 제목: "AppTag 계정 삭제 요청"
- 본문: 가입 이메일 주소, 가입 방법 (이메일/Google/Apple)

영업일 기준 5일 이내 처리합니다.

## 삭제되는 데이터
| 항목 | 처리 |
|------|------|
| 계정 정보 (이메일, 프로필) | 즉시 삭제 |
| 클라우드 백업 템플릿 | 즉시 삭제 |
| 로컬 기기 데이터 (Hive) | 앱 삭제 시 자동 제거 |
| 로그 데이터 | 90일 이내 자동 삭제 |

## 보관되는 데이터
- 법령에 따른 보관 의무 없음 — 모든 데이터 삭제 처리

## 문의
tawool83@gmail.com
```

---

### 3.11 `docs/store-compliance/play-console-checklist.md` (신규)

**용도**: 사용자가 Play Console 에 직접 입력할 메타데이터 가이드.

**구조**:
```markdown
# Google Play Console 제출 체크리스트

## 1. App Content
- [ ] Privacy Policy URL: `https://tawool83.github.io/apptag-legal/privacy-policy.html`
- [ ] App Access: 로그인 불필요 (주요 기능은 비로그인 사용 가능)
- [ ] Ads: No
- [ ] Content Rating: 설문 작성 (3+ 예상)
- [ ] Target Audience: 13+ (범용)
- [ ] News App: No
- [ ] Data Safety: 아래 섹션 참조
- [ ] Government App: No

## 2. Data Safety (2.x)
### 수집 데이터
- Personal Info — Email (로그인 사용자만, Account Management 용도, Supabase 로 전송)
- App Activity — 사용자 생성 QR 데이터 (App Functionality, Supabase 로 전송, 암호화됨)
### 미수집
- Location (사용자가 직접 선택한 지도 좌표만, 앱 외부 전송 없음)
- Device or Other IDs
- Photos and Videos (갤러리 저장은 사용자 기기에만 있음)

## 3. Permissions
### Standard
- CAMERA — QR 스캔
- NFC — NFC 태그 읽기·쓰기
- LOCATION — 지도 태그 현재 위치 (사용자 명시적 요청 시에만)
- READ_CONTACTS — 연락처 QR 생성 (사용자 명시적 요청 시에만)
- READ_MEDIA_IMAGES — 갤러리에서 로고 이미지 선택

### Sensitive (Declaration 필수)
- **QUERY_ALL_PACKAGES**:
  - Use case: App Discovery
  - Core purpose: "사용자가 설치한 앱 목록에서 선택해서 해당 앱의 딥링크를 QR 코드로 저장. 이것이 앱의 핵심 기능."

## 4. Account Deletion
- In-app: "프로필 > 계정 삭제" 경로
- Web URL: `https://tawool83.github.io/apptag-legal/account-deletion.html`

## 5. Store Listing
- [ ] App name, Short description (80자), Full description (4000자)
- [ ] App icon 512×512 (PNG, alpha 없음)
- [ ] Feature graphic 1024×500
- [ ] Screenshots 최소 2장 (Phone) — 권장 8장
- [ ] Category: Productivity (or Tools)

## 6. App Bundle 업로드
```bash
flutter build appbundle --release
```
산출물: `build/app/outputs/bundle/release/app-release.aab`
```

---

### 3.12 `docs/store-compliance/app-store-connect-checklist.md` (신규)

**구조** (위와 유사한 포맷, App Store 특화):
- App Privacy Nutrition Label 입력 가이드
- App Information, Pricing, Availability
- App Review Information (테스트 계정)
- Screenshots (6.7" iPhone + 12.9" iPad 필수)
- Encryption Export Compliance (Info.plist 로 자동 처리)

---

## 4. 기존 feature 와의 데이터 흐름

```
[Drawer 탭] → [_buildDrawer] → [ListTile "프로그램 정보"]
                                      ↓
                           [_showAppInfoDialog]
                                      ↓
              ┌─────────── showAboutDialog.children ─────────┐
              │                                              │
              │  • 기존: 앱 이름/버전/빌드/엔진/스키마         │
              │                                              │
              │  • 신규: Divider                              │
              │    ├── _LegalLinkTile (privacyPolicy)        │
              │    ├── _LegalLinkTile (termsOfService)       │
              │    ├── _LegalLinkTile (accountDeletion)      │
              │    └── _LegalLinkTile (support)              │
              │                                              │
              └──────────────────────────────────────────────┘
                                      ↓ (탭)
                           LegalUrls.{xxx}
                                      ↓
                       url_launcher.launchUrl()
                                      ↓
                     OS 기본 브라우저/메일 앱 호출
                                      ↓
                  GitHub Pages 호스팅 정책 페이지 표시
```

**변경 없는 영역**:
- Profile 화면의 기존 "계정 삭제" 버튼 (`profile_screen.dart`) — 이미 동작
- Supabase auth `deleteAccount` RPC — 이미 동작
- Drawer 의 Settings 링크 — 무관

---

## 5. 구현 순서 (Do phase 참조용)

### Step 1 — 정적 문서 작성 (선행, 코드 영향 0)
1. `docs/legal/privacy-policy.ko.md`
2. `docs/legal/privacy-policy.en.md`
3. `docs/legal/terms.ko.md`
4. `docs/legal/terms.en.md`
5. `docs/legal/account-deletion.md`

### Step 2 — 네이티브 config (iOS 먼저, 개별 빌드 검증 가능)
6. `ios/Runner/PrivacyInfo.xcprivacy` 작성
7. `ios/Runner/Info.plist` 에 `ITSAppUsesNonExemptEncryption` 추가
8. Xcode 에서 `PrivacyInfo.xcprivacy` 를 Runner target 에 추가 (파일 reference)
9. `flutter build ipa --no-codesign` 로 plist 오류 없는지 검증

### Step 3 — Android config
10. `android/app/build.gradle.kts` `targetSdk = 35` 명시
11. `AndroidManifest.xml` 주석 확장
12. `flutter build appbundle --release` 검증

### Step 4 — Flutter 코드
13. `lib/core/constants/legal_urls.dart` 신규
14. `lib/l10n/app_ko.arb` 키 4개 추가
15. `flutter gen-l10n` 실행
16. `lib/features/home/home_screen.dart` 수정 (ListTile 4개 + `_LegalLinkTile` 내부 위젯)
17. `flutter analyze lib/features/home/ lib/core/constants/ lib/l10n/` — 에러 0 확인

### Step 5 — 콘솔 가이드 문서
18. `docs/store-compliance/play-console-checklist.md`
19. `docs/store-compliance/app-store-connect-checklist.md`

### Step 6 — 호스팅 (사용자 작업, Out-of-scope)
- GitHub Pages 리포지토리 생성·배포 (`tawool83.github.io/apptag-legal`)
- 3개 HTML 파일 업로드 (MD → HTML 변환)

---

## 6. 세부 기술 결정 (자동 확정)

| 항목 | 결정 | 근거 |
|------|------|------|
| URL launcher 모드 | `LaunchMode.externalApplication` | 외부 브라우저에서 정책 페이지 열기 — 앱 내 WebView 는 App Store 심사에서 별도 이슈 가능 |
| ListTile 아이콘 스타일 | Material Outlined | 기존 Drawer 통일 |
| 아이콘 색상 | `colorScheme.primary` | 기존 Drawer ListTile 스타일 통일 |
| 트레일링 아이콘 | `Icons.open_in_new` | 외부 이동 시각 단서 (UX 관용) |
| l10n key prefix | `legal*` | 기능적 그룹핑 (기존 `drawer*`, `appInfo*` 와 구분) |
| URL 호스팅 | GitHub Pages (`tawool83.github.io/apptag-legal`) | 무료·간편, 정적 페이지로 충분 |
| Hive typeId 영향 | 없음 | 이번 feature 는 Hive 모델 변경 없음 |
| 라이브러리 버전 | `url_launcher ^6.3.0` (기존) | 추가 의존성 0 |

---

## 7. 검증 플랜

### 빌드 검증
- [ ] `flutter analyze` → 0 issue
- [ ] `flutter build appbundle --release` → 성공
- [ ] `flutter build ios --release --no-codesign` → 성공
- [ ] Xcode validation → Privacy Manifest 경고 0

### 기능 검증 (수동)
- [ ] Drawer → "프로그램 정보" 탭 → 기존 앱 정보 표시 유지
- [ ] 신규 링크 4개 탭 → 외부 브라우저/메일 앱 호출 성공
- [ ] 링크 URL 이 실제 GitHub Pages 페이지로 이동 (호스팅 완료 후)
- [ ] 링크 leading 아이콘·트레일링 `open_in_new` 렌더링 확인

### 문서 검증
- [ ] `privacy-policy.ko.md` 모든 섹션 작성
- [ ] `account-deletion.md` 2가지 방법 + 연락처 포함
- [ ] Play Console checklist 와 App Store Connect checklist 각 항목 체크박스 형태

---

## 8. 위험·미결 항목

### 위험
1. **GitHub Pages 도메인 미확정**: `LegalUrls` 상수에 플레이스홀더 URL 사용. 실제 호스팅 도메인 결정 시 본 파일만 수정.
2. **법무 검토 부재**: 개인정보처리방침·이용약관 문구는 "심사 통과 최소 기준" 수준. 상용 서비스 전 법무 자문 필요.
3. **QUERY_ALL_PACKAGES 거부 가능성**: Google Play 가 사유 불충분 판단 시 reject → 권한 제거 후 `<queries>` 로 대체 가능한지 재설계 필요.
4. **`home_screen.dart` 400줄 근접**: 추가 UI 로 초과 시 `_LegalLinkTile` 분리 필요 (CLAUDE.md 하드룰 8번).

### 미결 (사용자 결정 필요)
- [ ] GitHub Pages 실제 도메인 (placeholder `tawool83.github.io/apptag-legal` 사용 여부)
- [ ] Support 이메일 (현재 `tawool83@gmail.com` 로 상수화 — 별도 support 계정 원하면 수정)

### Phase 3 (콘솔 메타데이터) 연결
- 본 Design 은 **코드/문서** 만 다룸
- Play Console / App Store Connect 입력은 **사용자 수동 작업** — `play-console-checklist.md` 와 `app-store-connect-checklist.md` 가 그 가이드 역할

---

## 9. Next Steps

1. 본 Design 사용자 검토 후 승인 시 → `/pdca do store-compliance`
2. Do phase 에서 Step 1 → Step 5 순차 실행
3. Step 6 (호스팅) 은 사용자 직접 작업
4. 구현 완료 후 → `/pdca analyze store-compliance` (Gap 분석)
