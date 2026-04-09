# AppTag Flutter 앱 Design Document

> **Summary**: 스마트폰 앱을 QR코드/NFC 태그에 연결하는 Flutter 크로스플랫폼 앱 — features/ 기반 Pragmatic 아키텍처
>
> **Project**: AppTag
> **Version**: 0.1.0
> **Author**: tawool83
> **Date**: 2026-04-09
> **Status**: Draft
> **Planning Doc**: [apptag-flutter.plan.md](../01-plan/features/apptag-flutter.plan.md)

---

## 1. Overview

### 1.1 Design Goals

- features/ 기반 모듈화로 각 화면의 독립적 개발 및 유지보수 용이
- Riverpod으로 상태관리 단순화 (불필요한 boilerplate 최소화)
- Services 계층에서 NFC/QR/이력 비즈니스 로직 캡슐화
- 플랫폼(Android/iOS) 분기 로직을 명확히 분리
- 오프라인 완결형 앱 (네트워크 불필요)
- 시스템 프린트 다이얼로그를 통한 QR 코드 직접 인쇄 지원

### 1.2 Design Principles

- **Feature Isolation**: 각 feature는 자신의 Screen + Provider만 담당
- **Single Responsibility**: Services는 단일 도메인 로직만 처리
- **Platform Separation**: Android/iOS 분기는 Home에서만 결정
- **Fail-Safe UX**: NFC 미지원/권한 거부 시 명확한 안내 제공

---

## 2. Architecture

### 2.0 Architecture Comparison

| Criteria | Option A: Minimal | Option B: Clean | **Option C: Pragmatic** |
|----------|:-:|:-:|:-:|
| New Files | ~15 | ~30 | ~22 |
| Modified Files | 0 | 0 | 0 |
| Complexity | Low | High | **Medium** |
| Maintainability | Medium | High | **High** |
| Effort | Low | High | **Medium** |
| Risk | Low (coupled) | Low (over-eng) | **Low (balanced)** |

**Selected: Option C — Pragmatic Balance**
> 이 앱은 화면 수 7개, 기능이 명확히 분리된 소규모 앱. 클린 아키텍처의 추상 인터페이스/Repository 패턴은 과도한 복잡도. features/ 모듈 구조 + Services 계층으로 충분한 분리 달성.

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
├─────────────────────────────────────────────────────┤
│  Presentation (features/)                            │
│  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌───────┐  │
│  │  home/   │ │app_picker/│ │ios_input/│ │history│  │
│  │  Screen  │ │ Screen+Pv │ │  Screen  │ │ S+Pv  │  │
│  └────┬─────┘ └─────┬─────┘ └─────┬────┘ └───┬───┘  │
│       │             │              │           │      │
│  ┌────┴─────────────┴──────────────┴───────────┴───┐  │
│  │  output_selector/ → qr_result/ → nfc_writer/    │  │
│  └──────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────┤
│  Services (비즈니스 로직)                             │
│  ┌──────────────┐ ┌────────────┐ ┌────────────────┐  │
│  │ NfcService   │ │ QrService  │ │HistoryService  │  │
│  └──────┬───────┘ └─────┬──────┘ └───────┬────────┘  │
├─────────┼───────────────┼────────────────┼───────────┤
│  Platform APIs / Packages                             │
│  nfc_manager  │  qr_flutter   │  Hive (Local DB)      │
│  device_apps  │  share_plus   │  screenshot           │
└─────────────────────────────────────────────────────┘
```

### 2.2 Screen Flow & Navigation

```
[HomeScreen]
    │
    ├─ Android ──→ [AppPickerScreen]
    │                    │ 앱 선택
    │                    ▼
    │              [OutputSelectorScreen]  ←── [HistoryScreen] (항목 선택 시)
    │                    │
    │              ┌─────┴──────┐
    │              ▼            ▼
    │        [QrResultScreen] [NfcWriterScreen]
    │
    └─ iOS ───→ [IosInputScreen]
                     │ 앱 이름 입력
                     ▼
               [OutputSelectorScreen] (이하 동일)

[HomeScreen] ──→ [HistoryScreen] (히스토리 버튼)
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| AppPickerScreen | NfcService (device_apps) | 설치 앱 목록 조회 |
| QrResultScreen | QrService | QR 생성 + 이미지 공유 |
| NfcWriterScreen | NfcService | NFC NDEF 기록 |
| HistoryScreen | HistoryService | 이력 CRUD |
| OutputSelectorScreen | NfcService (미지원 체크) | NFC 버튼 활성화 제어 |

---

## 3. Data Model

### 3.1 TagHistory (이력 모델)

```dart
// models/tag_history.dart
@HiveType(typeId: 0)
class TagHistory extends HiveObject {
  @HiveField(0)
  final String id;           // UUID

  @HiveField(1)
  final String appName;      // 앱 이름 (표시용)

  @HiveField(2)
  final String deepLink;     // 딥링크 URL
                             // Android: "package:com.example.app"
                             // iOS: "shortcuts://run-shortcut?name=..."

  @HiveField(3)
  final String platform;     // "android" | "ios"

  @HiveField(4)
  final String outputType;   // "qr" | "nfc"

  @HiveField(5)
  final DateTime createdAt;  // 생성 일시

  @HiveField(6)
  final String? packageName; // Android only (앱 패키지명)

  @HiveField(7)
  final String? appIconBytes; // Base64 인코딩 아이콘 (Android only, nullable)
}
```

### 3.2 AppInfo (Android 앱 목록용 임시 모델)

```dart
// models/app_info.dart (in-memory, not persisted)
class AppInfo {
  final String appName;
  final String packageName;
  final Uint8List? icon;      // 앱 아이콘 바이트
}
```

### 3.3 Hive 스토리지 구조

```
Hive Box: "tag_history"
  └── List<TagHistory>  (시간 역순 정렬로 표시)
```

---

## 4. Services 설계

### 4.1 NfcService

```dart
// services/nfc_service.dart
class NfcService {
  /// NFC 지원 여부 확인
  Future<bool> isNfcAvailable() async

  /// iOS NFC 쓰기 지원 여부 (iPhone XS+ & iOS 13+)
  Future<bool> isNfcWriteSupported() async

  /// NFC 태그에 딥링크 NDEF 기록
  /// throws NfcWriteException on failure
  Future<void> writeNdefTag(String deepLink) async

  /// Android 설치 앱 목록 조회 (device_apps)
  Future<List<AppInfo>> getInstalledApps() async
}
```

**NFC 지원 분기 로직**:
```
isNfcAvailable()
  └── false → NFC 버튼 비활성화 + "NFC를 지원하지 않는 기기입니다" 안내
  └── true (Android) → 바로 쓰기 가능
  └── true (iOS)
        └── isNfcWriteSupported()
              └── false (iPhone X 이하) → 읽기 전용 안내
              └── true (iPhone XS+ / iOS 13+) → 쓰기 가능
```

### 4.2 QrService

```dart
// services/qr_service.dart
class QrService {
  /// QR 코드 위젯을 이미지(Uint8List)로 캡처
  Future<Uint8List> captureQrImage(GlobalKey repaintKey) async

  /// 이미지를 갤러리에 저장
  Future<void> saveToGallery(Uint8List imageBytes, String filename) async

  /// 공유 시트를 통해 이미지 공유
  Future<void> shareImage(Uint8List imageBytes) async

  /// 시스템 프린트 다이얼로그를 통해 QR 코드 인쇄
  /// - QR 이미지를 PDF 페이지로 래핑 후 시스템 인쇄 다이얼로그 호출
  /// - Android: 연결된 프린터 / iOS: AirPrint 지원 프린터
  /// throws PrintException on failure
  Future<void> printQrCode({
    required Uint8List imageBytes,
    required String appName,
    String pageFormat = 'A4',  // 'A4' | 'LETTER'
  }) async

  /// 딥링크 생성 헬퍼
  static String buildAndroidDeepLink(String packageName)
  // → "package:com.example.app"

  static String buildIosDeepLink(String shortcutName)
  // → "shortcuts://run-shortcut?name=${Uri.encodeFull(shortcutName)}"
}
```

### 4.3 PrintService (QrService 내 구현)

```dart
// services/qr_service.dart — printQrCode() 상세 구현

Future<void> printQrCode({
  required Uint8List imageBytes,
  required String appName,
}) async {
  // 1. pdf 패키지로 A4 PDF 문서 생성
  final doc = pw.Document();
  final image = pw.MemoryImage(imageBytes);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                appName,
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 16),
              pw.Image(image, width: 200, height: 200),
              pw.SizedBox(height: 8),
              pw.Text(
                'Scan to launch app',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
            ],
          ),
        );
      },
    ),
  );

  // 2. printing 패키지로 시스템 프린트 다이얼로그 호출
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => doc.save(),
    name: 'AppTag_$appName',
  );
}
```

**인쇄 흐름**:
```
QrResultScreen [🖨️ 인쇄] 탭
  → QrService.captureQrImage() (이미 캡처된 이미지 재사용)
  → QrService.printQrCode(imageBytes, appName)
  → pdf 패키지: QR 이미지를 A4 PDF 페이지로 래핑
  → Printing.layoutPdf(): 시스템 프린트 다이얼로그 표시
      ├─ Android: Google Cloud Print / 연결된 프린터 목록
      └─ iOS: AirPrint 지원 프린터 목록
```

**PDF 레이아웃 (A4 기준)**:
```
┌─────────────────────────┐
│                         │
│      냉장고 관리         │  ← 앱 이름
│                         │
│   ┌─────────────────┐   │
│   │                 │   │
│   │   QR CODE       │   │  200×200pt
│   │   200×200       │   │
│   │                 │   │
│   └─────────────────┘   │
│                         │
│   Scan to launch app    │  ← 안내 문구
│                         │
└─────────────────────────┘
```

### 4.4 HistoryService

```dart
// services/history_service.dart
class HistoryService {
  /// 이력 저장 (최신 순)
  Future<void> saveHistory(TagHistory history) async

  /// 전체 이력 조회 (시간 역순)
  Future<List<TagHistory>> getHistory() async

  /// 이력 항목 삭제
  Future<void> deleteHistory(String id) async

  /// 이력 전체 삭제
  Future<void> clearAll() async
}
```

---

## 5. Features 상세 설계

### 5.1 HomeScreen

```
역할: 플랫폼 감지 후 Android/iOS 흐름 분기, 이력 버튼 제공
상태: 없음 (StatelessWidget)

UI 구성:
┌─────────────────────────────┐
│  AppTag                 [⏱] │  ← 이력 버튼
├─────────────────────────────┤
│                             │
│    [앱 아이콘]              │
│    AppTag                   │
│    앱에 QR/NFC 태그 달기    │
│                             │
│    [시작하기] ──────────┐   │
│                         │   │
└─────────────────────────┼───┘
  Platform.isAndroid ? AppPickerScreen : IosInputScreen
```

### 5.2 AppPickerScreen (Android)

```
역할: 설치된 앱 목록 표시 + 검색
상태: AppPickerProvider (Riverpod)
  - List<AppInfo> apps (전체 목록)
  - String searchQuery
  - bool isLoading

UI 구성:
┌─────────────────────────────┐
│  ← 앱 선택              [x] │
├─────────────────────────────┤
│  🔍 앱 검색...              │
├─────────────────────────────┤
│  [아이콘] 카카오톡           │
│  [아이콘] 냉장고 관리        │
│  [아이콘] 자동 사료 급여기   │
│  ...                        │
└─────────────────────────────┘

동작:
1. initState → getInstalledApps() 호출
2. 검색 입력 시 실시간 필터링 (앱 이름 포함 검색)
3. 앱 탭 → OutputSelectorScreen(appInfo: selected)으로 이동
```

**AppPickerProvider**:
```dart
final appPickerProvider = StateNotifierProvider<AppPickerNotifier, AppPickerState>
```

### 5.3 IosInputScreen (iOS)

```
역할: 앱 이름 입력 + 단축어 생성 안내
상태: TextEditingController (단순)

UI 구성:
┌─────────────────────────────┐
│  ← iOS 앱 실행 설정         │
├─────────────────────────────┤
│                             │
│  실행할 앱의 단축어 이름     │
│  ┌─────────────────────┐    │
│  │  내냉장고           │    │
│  └─────────────────────┘    │
│                             │
│  ℹ️ 안내                    │
│  ┌─────────────────────┐    │
│  │ 단축어 앱을 열고     │    │
│  │ 앱을 실행하는 단축어 │    │
│  │ 를 만든 후 위 이름으 │    │
│  │ 로 저장하세요        │    │
│  └─────────────────────┘    │
│                             │
│  [다음 →]                   │
└─────────────────────────────┘

동작:
1. 이름 입력 (빈칸 불가 validation)
2. "다음" 탭 → buildIosDeepLink(name) 생성
3. OutputSelectorScreen(deepLink: url, appName: name)으로 이동
```

### 5.4 OutputSelectorScreen

```
역할: QR / NFC 출력 방식 선택
상태: isNfcAvailable (FutureProvider)

UI 구성:
┌─────────────────────────────┐
│  ← 출력 방식 선택           │
├─────────────────────────────┤
│  앱: 냉장고 관리             │
├─────────────────────────────┤
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │          │ │          │  │
│  │  QR코드  │ │ NFC태그  │  │
│  │          │ │ [비활성] │  │
│  └──────────┘ └──────────┘  │
│                             │
│  ⚠️ 이 기기는 NFC를         │  ← NFC 미지원 시 표시
│  지원하지 않습니다           │
└─────────────────────────────┘

동작:
- NFC 버튼: isNfcAvailable && isNfcWriteSupported 시만 활성
- QR 탭 → QrResultScreen(deepLink, appName)
- NFC 탭 → NfcWriterScreen(deepLink, appName)
```

### 5.5 QrResultScreen

```
역할: QR 코드 표시 + 저장/공유 + 이력 자동 저장
상태: QrResultProvider
  - isImageCaptured: bool
  - isSaving: bool

UI 구성:
┌─────────────────────────────┐
│  ← QR 코드                  │
├─────────────────────────────┤
│                             │
│     ┌────────────────┐      │
│     │                │      │
│     │   QR CODE      │      │  ← RepaintBoundary 위젯
│     │   IMAGE        │      │
│     │                │      │
│     └────────────────┘      │
│                             │
│     냉장고 관리              │
│     package:com.xxx.app     │
│                             │
│  [💾 갤러리 저장] [📤 공유]  │
│  [🖨️ 인쇄]                  │
│                             │
│  [✓ 완료]                   │
└─────────────────────────────┘

동작:
1. 화면 진입 시 → HistoryService.saveHistory() 자동 호출
2. 갤러리 저장 → QrService.saveToGallery()
3. 공유 → QrService.shareImage()
4. 인쇄 → QrService.printQrCode() → 시스템 프린트 다이얼로그 표시
5. 완료 → HomeScreen으로 이동 (스택 초기화)
```

### 5.6 NfcWriterScreen

```
역할: NFC 태그 대기 + 기록 + 이력 저장
상태: NfcWriterProvider
  - NfcWriteStatus: idle | waiting | success | error

UI 구성:
┌─────────────────────────────┐
│  ← NFC 기록                 │
├─────────────────────────────┤
│                             │
│     [NFC 애니메이션]         │
│                             │
│   NFC 태그를 스마트폰 뒷면에  │
│   가져다 대세요              │
│                             │
│   ── 대기 중... ──          │  ← waiting 상태
│                             │
│   ✅ 기록 완료!             │  ← success 상태
│   또는                      │
│   ❌ 오류 발생. 다시 시도    │  ← error 상태
│                             │
│  [취소]                     │
└─────────────────────────────┘

동작:
1. 화면 진입 → NfcService.writeNdefTag(deepLink) 시작
2. success → HistoryService.saveHistory() → 완료 메시지 3초 후 홈으로
3. error → 재시도 버튼 표시
4. dispose → NFC 세션 취소
```

### 5.7 HistoryScreen

```
역할: 이력 목록 표시 + 항목 선택으로 재출력 + 삭제
상태: HistoryProvider (Riverpod)
  - List<TagHistory> histories

UI 구성:
┌─────────────────────────────┐
│  ← 생성 이력            [🗑] │  ← 전체 삭제
├─────────────────────────────┤
│  [아이콘] 냉장고 관리        │
│  QR코드 · 2026.04.09 14:30  │
│                        [삭제]│
├─────────────────────────────┤
│  [아이콘] 자동 사료 급여기   │
│  NFC · 2026.04.08 09:15     │
│                        [삭제]│
├─────────────────────────────┤
│  이력이 없습니다             │  ← 빈 상태
└─────────────────────────────┘

동작:
1. 항목 탭 → OutputSelectorScreen(deepLink, appName) (재출력 흐름)
2. 삭제 아이콘 탭 → 확인 다이얼로그 → 삭제
3. 전체 삭제 버튼 → 확인 다이얼로그 → clearAll()
```

---

## 6. Riverpod Providers 구조

```dart
// features/app_picker/app_picker_provider.dart
final appListProvider = FutureProvider<List<AppInfo>>((ref) async {
  return ref.read(nfcServiceProvider).getInstalledApps();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredAppsProvider = Provider<List<AppInfo>>((ref) {
  final apps = ref.watch(appListProvider).valueOrNull ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return apps;
  return apps.where((a) => a.appName.toLowerCase().contains(query)).toList();
});

// features/history/history_provider.dart
final historyProvider = FutureProvider<List<TagHistory>>((ref) async {
  return ref.read(historyServiceProvider).getHistory();
});

// shared providers (services)
final nfcServiceProvider = Provider<NfcService>((ref) => NfcService());
final qrServiceProvider = Provider<QrService>((ref) => QrService());
final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());

final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(nfcServiceProvider).isNfcAvailable();
});

final nfcWriteSupportedProvider = FutureProvider<bool>((ref) async {
  return ref.read(nfcServiceProvider).isNfcWriteSupported();
});
```

---

## 7. Deep Link 포맷 정의

```dart
// shared/constants/deep_link_constants.dart

/// Android: package intent 딥링크
/// 카메라 앱으로 QR 스캔 시 Play Store로 이동하거나 앱 직접 실행
static String androidDeepLink(String packageName) =>
    'package:$packageName';

/// Android: intent 방식 (일부 기기에서 더 안정적)
static String androidIntentDeepLink(String packageName) =>
    'intent:#Intent;action=android.intent.action.MAIN;'
    'category=android.intent.category.LAUNCHER;'
    'package=$packageName;end';

/// iOS: Shortcuts URL 스킴
/// 한글/공백 포함 이름은 반드시 URL 인코딩
static String iosShortcutDeepLink(String shortcutName) =>
    'shortcuts://run-shortcut?name=${Uri.encodeFull(shortcutName)}';
```

---

## 8. 에러 처리

### 8.1 에러 유형별 처리

| 에러 상황 | 처리 방식 | 사용자 메시지 |
|----------|----------|-------------|
| Android QUERY_ALL_PACKAGES 권한 거부 | 권한 요청 다이얼로그 → 거부 시 설정 화면 안내 | "앱 목록 권한이 필요합니다. 설정에서 허용해 주세요." |
| NFC 미지원 기기 | NFC 버튼 비활성화 | "이 기기는 NFC를 지원하지 않습니다." |
| iOS NFC 쓰기 미지원 (iPhone X 이하) | NFC 버튼 비활성화 | "NFC 쓰기는 iPhone XS 이상에서 지원됩니다." |
| NFC 기록 실패 (태그 없음/오류) | 재시도 버튼 표시 | "NFC 기록에 실패했습니다. 다시 시도해주세요." |
| QR 이미지 저장 실패 | 스낵바 오류 표시 | "이미지 저장에 실패했습니다." |
| 인쇄 취소 (사용자가 다이얼로그 닫음) | 무시 (정상 흐름) | — |
| 프린터 없음 / 인쇄 실패 | 스낵바 오류 표시 | "인쇄에 실패했습니다. 프린터 연결을 확인해주세요." |
| iOS 단축어 이름 빈칸 입력 | TextField validation | "앱 이름을 입력해주세요." |

### 8.2 에러 처리 패턴

```dart
// NFC 쓰기 에러 처리 예시
try {
  await nfcService.writeNdefTag(deepLink);
  state = NfcWriteStatus.success;
  await historyService.saveHistory(history);
} on NfcWriteException catch (e) {
  state = NfcWriteStatus.error;
  // 로그 기록, 재시도 UI 표시
} catch (e) {
  state = NfcWriteStatus.error;
}
```

---

## 9. 플랫폼 설정

### 9.1 Android (android/app/src/main/AndroidManifest.xml)

```xml
<!-- NFC 권한 -->
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />

<!-- 앱 목록 조회 (Android 11+) -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />

<!-- QR 이미지 갤러리 저장 -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```

**build.gradle**:
```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Android 6.0
        compileSdkVersion 34
    }
}
```

### 9.2 iOS (ios/Runner/Info.plist)

```xml
<!-- NFC 사용 목적 설명 (필수) -->
<key>NFCReaderUsageDescription</key>
<string>NFC 태그에 앱 딥링크를 기록하기 위해 NFC를 사용합니다.</string>

<!-- NFC 태그 타입 (com.apple.developer.nfc.readersession.formats 필요) -->
<!-- Xcode Signing & Capabilities에서 Near Field Communication Tag Reading 추가 필요 -->
```

**Deployment Target**: iOS 13.0

---

## 10. 패키지 목록

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 상태 관리
  flutter_riverpod: ^2.5.0
  
  # NFC
  nfc_manager: ^3.3.0
  
  # QR 생성
  qr_flutter: ^4.1.0
  
  # 이미지 캡처/저장/공유
  screenshot: ^2.1.0
  share_plus: ^9.0.0
  image_gallery_saver: ^2.0.3
  printing: ^5.13.1    # 시스템 프린트 다이얼로그 (Android/iOS/Desktop)
  pdf: ^3.11.1         # PDF 생성 (QR 이미지 → PDF 페이지 래핑)
  
  # Android 앱 목록
  device_apps: ^2.2.0
  
  # 로컬 저장소
  hive_flutter: ^1.1.0
  
  # 유틸리티
  uuid: ^4.4.0
  path_provider: ^2.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.9
```

---

## 11. 구현 순서

```
Phase 1: 프로젝트 셋업 (1주)
  ├── [ ] flutter create app_tag
  ├── [ ] pubspec.yaml 패키지 추가
  ├── [ ] AndroidManifest.xml / Info.plist 설정
  ├── [ ] Hive 초기화 + TagHistory 어댑터 생성 (build_runner)
  ├── [ ] app/, shared/, models/ 기본 구조 생성
  └── [ ] router.dart 라우팅 설정

Phase 2: Android 핵심 기능 (1~2주)
  ├── [ ] NfcService.getInstalledApps() 구현
  ├── [ ] AppPickerScreen + Provider 구현
  ├── [ ] OutputSelectorScreen + NFC 감지 로직
  ├── [ ] QrService + QrResultScreen 구현 (갤러리 저장, 공유)
  ├── [ ] QrService.printQrCode() + 인쇄 버튼 UI 구현 (pdf + printing)
  └── [ ] HistoryService + QR 이력 자동 저장

Phase 3: NFC 기록 기능 (1주)
  ├── [ ] NfcService.writeNdefTag() 구현
  ├── [ ] NfcWriterScreen + Provider 구현
  ├── [ ] iOS NFC 지원 범위 감지 로직
  └── [ ] NFC 이력 자동 저장

Phase 4: iOS 흐름 + 이력 관리 (1~2주)
  ├── [ ] IosInputScreen 구현
  ├── [ ] iOS URL 인코딩 처리 검증
  ├── [ ] HistoryScreen + Provider 구현
  └── [ ] 재출력 흐름 연결

Phase 5: 테스트 및 디버깅 (1주)
  ├── [ ] 실기기 Android 테스트
  ├── [ ] 실기기 iOS 테스트
  ├── [ ] NFC 미지원 기기 시뮬레이션
  └── [ ] 엣지 케이스: 긴 앱 이름, 특수문자, 한글 URL 인코딩
```

---

## 12. 테스트 계획

### 12.1 단위 테스트

| 대상 | 테스트 항목 |
|------|------------|
| QrService.buildIosDeepLink | 한글 URL 인코딩 정확성 |
| QrService.buildAndroidDeepLink | package: 포맷 |
| HistoryService | 저장/조회/삭제 CRUD |

### 12.2 통합 테스트 (실기기)

| 시나리오 | 기기 | 기대 결과 |
|----------|------|----------|
| Android 앱 목록 조회 | Android 11+ | 앱 목록 표시 |
| Android QR 생성 + 갤러리 저장 | Android | 이미지 저장 성공 |
| Android QR 인쇄 | Android (프린터 연결) | 프린트 다이얼로그 표시 + 인쇄 |
| iOS QR 인쇄 (AirPrint) | iPhone (AirPrint 프린터) | 프린트 다이얼로그 표시 + 인쇄 |
| Android NFC 기록 | NFC 지원 Android | NDEF 기록 성공 |
| iOS 단축어 QR 생성 | iPhone XS+ / iOS 13+ | QR 생성 성공 |
| iOS NFC 기록 | iPhone XS+ | NDEF 기록 성공 |
| iOS NFC 미지원 | iPhone X 이하 | 버튼 비활성화 + 안내 |
| NFC 미지원 기기 | NFC 없는 기기 | NFC 버튼 비활성화 |
| 이력 재출력 | 모든 기기 | 기존 QR/NFC 재생성 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-09 | Initial draft — Option C (Pragmatic Balance) | tawool83 |
| 0.2 | 2026-04-09 | QR 코드 직접 인쇄 기능 추가 (printing + pdf 패키지, FR-14) | tawool83 |
