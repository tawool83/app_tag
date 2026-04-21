# qr-scanner-ui-ux Design Document

> **Feature**: QR 스캐너 기능 신규 도입 + 스캔 결과 Bottom Sheet + History 2-탭 확장
>
> **Plan**: `docs/01-plan/features/qr-scanner-ui-ux.plan.md`
> **Author**: tawool83
> **Date**: 2026-04-21
> **Status**: Draft

---

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 앱이 QR "생성" 전용이라 역방향(공간→앱) 연결고리가 없고, History가 단일 리스트로 검색/필터/즐겨찾기 기능 부재 |
| **Solution** | `mobile_scanner` 기반 풀스크린 스캐너 + 9종 타입 자동 분류 Bottom Sheet + ScanHistory R-series 모듈 + History 2-탭(생성/스캔) + 공통 관리 UX |
| **Function/UX Effect** | 홈 첫 타일로 즉시 스캐너 진입 → 햅틱 피드백 → Bottom Sheet 결과 확인 → "꾸미기" 경유 기존 태그 파이프라인 재사용. History는 2탭 + 검색/필터/⭐/스와이프 삭제 |
| **Core Value** | "빠른 스캔 → 스마트한 기록 관리 → 바로 내 것으로 꾸미기" 단일 루프 완성 |

---

## 1. Architecture Overview

### 1.1 Selected Architecture

**Flutter Feature Modules x Clean Architecture x R-series Provider 패턴** (CLAUDE.md 고정 규약)

### 1.2 신규 Feature 디렉터리 트리

```
lib/features/scanner/
├── scanner_provider.dart                       # library; + part + ScannerState + ScannerNotifier(lifecycle)
├── domain/
│   ├── entities/
│   │   ├── scan_detected_type.dart             # enum ScanDetectedType { url, wifi, contact, sms, email, location, event, appDeepLink, text }
│   │   └── scan_result.dart                    # @immutable class ScanResult { rawValue, detectedType, parsedMeta }
│   ├── state/
│   │   ├── scanner_camera_state.dart           # @immutable class ScannerCameraState { isActive, flashOn, permissionStatus, errorMessage }
│   │   └── scanner_result_state.dart           # @immutable class ScannerResultState { currentResult, sheetVisible }
│   └── parser/
│       ├── url_parser.dart                     # ScanResult? tryParseUrl(String raw)
│       ├── wifi_parser.dart                    # ScanResult? tryParseWifi(String raw)
│       ├── vcard_parser.dart                   # ScanResult? tryParseContact(String raw) — vCard + MECARD
│       ├── sms_parser.dart                     # ScanResult? tryParseSms(String raw)
│       ├── email_parser.dart                   # ScanResult? tryParseEmail(String raw) — mailto + MATMSG
│       ├── geo_parser.dart                     # ScanResult? tryParseLocation(String raw)
│       ├── vevent_parser.dart                  # ScanResult? tryParseEvent(String raw)
│       ├── app_deeplink_parser.dart            # ScanResult? tryParseAppDeepLink(String raw) — apptag:// schema
│       └── scan_payload_parser.dart            # ScanResult parse(String raw) — 우선순위 체인 디스패처
├── data/
│   └── datasources/
│       └── gallery_qr_decoder_datasource.dart  # MobileScannerController.analyzeImage 래퍼
├── notifier/
│   ├── camera_setters.dart                     # part of; mixin _CameraSetters on StateNotifier<ScannerState>
│   └── result_setters.dart                     # part of; mixin _ResultSetters on StateNotifier<ScannerState>
└── presentation/
    ├── screens/
    │   └── scanner_screen.dart                 # StatelessWidget (ConsumerWidget)
    ├── widgets/
    │   ├── scanning_reticle.dart               # 중앙 사각형 오버레이 + 인식 성공 애니메이션
    │   ├── scanner_control_bar.dart            # 플래시 토글 + 갤러리 임포트 버튼
    │   ├── permission_fallback_view.dart       # 카메라 권한 거부 시 폴백 UI
    │   └── result_bottom_sheet/
    │       ├── result_sheet.dart               # showModalBottomSheet 호출부
    │       ├── data_type_tag.dart              # 타입 아이콘 + 라벨 위젯
    │       ├── preview_area.dart               # 원문/파싱 결과 프리뷰
    │       └── primary_actions.dart            # 타입별 액션 버튼군 + 공통 "꾸미기" 버튼
    └── providers/
        └── scanner_providers.dart              # scannerProvider, galleryDecoderProvider 등

lib/features/scan_history/
├── scan_history_provider.dart                  # library; + part + ScanHistoryState + ScanHistoryNotifier(lifecycle)
├── domain/
│   ├── entities/
│   │   └── scan_history_entry.dart             # @immutable class ScanHistoryEntry { id, scannedAt, rawValue, detectedType, parsedMeta, isFavorite }
│   └── state/
│       ├── scan_history_list_state.dart         # @immutable class ScanHistoryListState { items, isLoading }
│       └── scan_history_filter_state.dart       # @immutable class ScanHistoryFilterState { query, selectedType, sortOrder }
├── data/
│   ├── models/
│   │   └── scan_history_model.dart             # @HiveType(typeId: 4) — Hive adapter
│   ├── datasources/
│   │   └── hive_scan_history_datasource.dart   # ScanHistoryLocalDataSource impl
│   └── repositories/
│       └── scan_history_repository_impl.dart
└── notifier/
    ├── list_setters.dart                       # part of; mixin _ListSetters
    └── filter_setters.dart                     # part of; mixin _FilterSetters

수정 영역 (기존 파일):
├── lib/features/home/home_screen.dart           # scanner 타일을 index 0 에 삽입
├── lib/features/history/presentation/screens/history_screen.dart  # TabBar 2탭 전면 개편
├── lib/features/history/presentation/widgets/   # (신규) 공통 위젯
│   ├── history_search_bar.dart
│   ├── history_filter_chips.dart
│   ├── history_list_view.dart                   # 제네릭 HistoryListView<T>
│   └── history_tile.dart                        # 공통 리스트 아이템
├── lib/features/qr_task/domain/entities/qr_task.dart             # isFavorite 필드
├── lib/features/qr_task/presentation/providers/qr_task_list_notifier.dart  # search/filter/toggleFavorite
├── lib/core/di/router.dart                      # /scanner 라우트
├── lib/core/di/hive_config.dart                 # ScanHistoryModel adapter + box
├── lib/l10n/app_ko.arb                          # 신규 문자열
├── pubspec.yaml                                 # mobile_scanner 추가
├── android/app/src/main/AndroidManifest.xml     # CAMERA 권한
└── ios/Runner/Info.plist                        # NSCameraUsageDescription
```

### 1.3 데이터 흐름도

```
[Home 타일 "스캐너"] ─tap→ [/scanner 라우트]
                              │
                    ┌─────────┴──────────┐
                    │ ScannerScreen       │
                    │  MobileScanner      │
                    │  + ScanningReticle  │
                    │  + ControlBar       │
                    └─────────┬──────────┘
                              │ onDetect (barcode.rawValue)
                              ▼
                    ┌──────────────────────┐
                    │ ScanPayloadParser    │
                    │  .parse(rawValue)    │
                    │  → ScanResult        │
                    │  (type + parsedMeta) │
                    └──────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
    [HapticFeedback]   [ScanHistory       [ResultBottomSheet]
                        .save()]           │
                                           ├─ Primary Actions (타입별)
                                           │   URL → 브라우저/복사
                                           │   WiFi → 연결/복사
                                           │   Text → 복사/공유
                                           │   기타 → OS intent
                                           │
                                           └─ "꾸미기" 버튼
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │ 기존 태그 화면        │
                                    │ (값 prefill)         │
                                    │ /website-tag         │
                                    │ /wifi-tag etc.       │
                                    └─────────┬───────────┘
                                              │ 기존 플로우
                                              ▼
                                    [/qr-result 꾸미기 화면]
```

---

## 2. Detailed Signatures

### 2.1 scanner feature

#### 2.1.1 Entities

```dart
// domain/entities/scan_detected_type.dart
enum ScanDetectedType {
  url,
  wifi,
  contact,
  sms,
  email,
  location,
  event,
  appDeepLink,
  text;  // fallback

  /// l10n 키 매핑용 (app_ko.arb 의 scanType* 키와 1:1)
  String get l10nKey => 'scanType${name[0].toUpperCase()}${name.substring(1)}';

  /// 아이콘 매핑
  IconData get icon => switch (this) {
    url       => Icons.language,
    wifi      => Icons.wifi,
    contact   => Icons.contact_phone,
    sms       => Icons.sms,
    email     => Icons.email,
    location  => Icons.location_on,
    event     => Icons.event,
    appDeepLink => Icons.apps,
    text      => Icons.text_snippet,
  };

  /// 태그 화면 라우트 매핑 ("꾸미기" 경유)
  /// null 이면 해당 타입은 "꾸미기" 불가 (text 는 clipboard-tag 로 폴백)
  String get tagRoute => switch (this) {
    url       => '/website-tag',
    wifi      => '/wifi-tag',
    contact   => '/contact-tag',
    sms       => '/sms-tag',
    email     => '/email-tag',
    location  => '/location-tag',
    event     => '/event-tag',
    appDeepLink => '/clipboard-tag', // 딥링크는 텍스트로 폴백
    text      => '/clipboard-tag',
  };
}
```

```dart
// domain/entities/scan_result.dart
@immutable
class ScanResult {
  final String rawValue;
  final ScanDetectedType detectedType;
  /// 타입별 파싱 결과. 키 규격:
  /// - url: { 'url': String }
  /// - wifi: { 'ssid': String, 'password': String?, 'securityType': String }
  /// - contact: { 'name': String, 'phone': String?, 'email': String? }
  /// - sms: { 'phone': String, 'message': String? }
  /// - email: { 'address': String, 'subject': String?, 'body': String? }
  /// - location: { 'lat': double, 'lng': double, 'label': String? }
  /// - event: { 'title': String, 'start': String(ISO), 'end': String(ISO), 'location': String?, 'description': String? }
  /// - appDeepLink: { 'uri': String }
  /// - text: { 'text': String }
  final Map<String, dynamic> parsedMeta;

  const ScanResult({
    required this.rawValue,
    required this.detectedType,
    required this.parsedMeta,
  });
}
```

#### 2.1.2 Sub-States

```dart
// domain/state/scanner_camera_state.dart
@immutable
class ScannerCameraState {
  final bool isActive;       // 카메라 스트림 활성 여부
  final bool flashOn;        // 플래시 토글
  final String permissionStatus;  // 'granted' | 'denied' | 'permanentlyDenied' | 'undetermined'
  final String? errorMessage;     // 카메라 오류 메시지

  const ScannerCameraState({
    this.isActive = false,
    this.flashOn = false,
    this.permissionStatus = 'undetermined',
    this.errorMessage,
  });

  ScannerCameraState copyWith({
    bool? isActive,
    bool? flashOn,
    String? permissionStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => ScannerCameraState(
    isActive: isActive ?? this.isActive,
    flashOn: flashOn ?? this.flashOn,
    permissionStatus: permissionStatus ?? this.permissionStatus,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );

  // == / hashCode 생략 (표준 패턴)
}
```

```dart
// domain/state/scanner_result_state.dart
@immutable
class ScannerResultState {
  final ScanResult? currentResult;
  final bool sheetVisible;

  const ScannerResultState({
    this.currentResult,
    this.sheetVisible = false,
  });

  ScannerResultState copyWith({
    ScanResult? currentResult,
    bool? sheetVisible,
    bool clearCurrentResult = false,
  }) => ScannerResultState(
    currentResult: clearCurrentResult ? null : (currentResult ?? this.currentResult),
    sheetVisible: sheetVisible ?? this.sheetVisible,
  );
}
```

#### 2.1.3 Composite State + Notifier

```dart
// scanner_provider.dart (메인, ≤ 200줄 목표)
library;

import ...;

part 'notifier/camera_setters.dart';
part 'notifier/result_setters.dart';

class ScannerState {
  final ScannerCameraState camera;
  final ScannerResultState result;

  const ScannerState({
    this.camera = const ScannerCameraState(),
    this.result = const ScannerResultState(),
  });

  ScannerState copyWith({
    ScannerCameraState? camera,
    ScannerResultState? result,
  }) => ScannerState(
    camera: camera ?? this.camera,
    result: result ?? this.result,
  );

  // == / hashCode
}

class ScannerNotifier extends StateNotifier<ScannerState>
    with _CameraSetters, _ResultSetters {
  @override
  final Ref _ref;

  ScannerNotifier(this._ref) : super(const ScannerState());

  // lifecycle only — 권한 체크 초기화
  Future<void> initialize() async {
    await checkPermission();   // _CameraSetters
  }

  @override
  void dispose() {
    // 카메라 리소스 정리 (MobileScannerController 는 위젯에서 관리)
    super.dispose();
  }
}

final scannerProvider =
    StateNotifierProvider.autoDispose<ScannerNotifier, ScannerState>(
  (ref) => ScannerNotifier(ref),
);
```

#### 2.1.4 Mixin Setters

```dart
// notifier/camera_setters.dart
part of '../scanner_provider.dart';

mixin _CameraSetters on StateNotifier<ScannerState> {
  Ref get _ref;

  Future<void> checkPermission() async {
    final status = await Permission.camera.status;
    state = state.copyWith(
      camera: state.camera.copyWith(
        permissionStatus: status.name, // granted/denied/permanentlyDenied/...
        isActive: status.isGranted,
      ),
    );
  }

  Future<void> requestPermission() async {
    final status = await Permission.camera.request();
    state = state.copyWith(
      camera: state.camera.copyWith(
        permissionStatus: status.name,
        isActive: status.isGranted,
      ),
    );
  }

  void toggleFlash() {
    state = state.copyWith(
      camera: state.camera.copyWith(flashOn: !state.camera.flashOn),
    );
  }

  void setCameraError(String message) {
    state = state.copyWith(
      camera: state.camera.copyWith(errorMessage: message, isActive: false),
    );
  }

  void setCameraActive(bool active) {
    state = state.copyWith(
      camera: state.camera.copyWith(isActive: active),
    );
  }
}
```

```dart
// notifier/result_setters.dart
part of '../scanner_provider.dart';

mixin _ResultSetters on StateNotifier<ScannerState> {
  Ref get _ref;

  /// QR 인식 성공 시 호출. 파싱 + 히스토리 저장 + Bottom Sheet 표시.
  Future<void> onBarcodeDetected(String rawValue) async {
    // 이미 시트가 열려 있으면 무시 (중복 인식 방지)
    if (state.result.sheetVisible) return;

    final parsed = ScanPayloadParser.parse(rawValue);

    state = state.copyWith(
      result: state.result.copyWith(
        currentResult: parsed,
        sheetVisible: true,
      ),
      // 스캔 중 카메라 일시정지
      camera: state.camera.copyWith(isActive: false),
    );

    // ScanHistory 에 자동 저장
    await _ref.read(scanHistoryProvider.notifier).addEntry(
      rawValue: rawValue,
      detectedType: parsed.detectedType,
      parsedMeta: parsed.parsedMeta,
    );
  }

  /// Bottom Sheet 닫힘 시 스캐너 재개.
  void dismissResult() {
    state = state.copyWith(
      result: state.result.copyWith(
        clearCurrentResult: true,
        sheetVisible: false,
      ),
      camera: state.camera.copyWith(isActive: true),
    );
  }
}
```

#### 2.1.5 Parser — 우선순위 체인

```dart
// domain/parser/scan_payload_parser.dart

/// 스캔 원문을 9종 타입으로 분류하는 우선순위 체인 디스패처.
///
/// 순서: appDeepLink → wifi → vcard/mecard → vevent → email(mailto/MATMSG) →
///       sms(SMSTO) → geo → url(http/https) → text(fallback)
///
/// 순서 근거: 구체적인 스키마부터 매칭하고 URL은 후순위 (http 로 시작하는 딥링크를
/// URL로 잘못 분류하는 것 방지).
class ScanPayloadParser {
  ScanPayloadParser._();

  static ScanResult parse(String raw) {
    return tryParseAppDeepLink(raw)
        ?? tryParseWifi(raw)
        ?? tryParseContact(raw)
        ?? tryParseEvent(raw)
        ?? tryParseEmail(raw)
        ?? tryParseSms(raw)
        ?? tryParseLocation(raw)
        ?? tryParseUrl(raw)
        ?? ScanResult(
             rawValue: raw,
             detectedType: ScanDetectedType.text,
             parsedMeta: {'text': raw},
           );
  }
}
```

각 타입별 파서 시그니처 (모두 `ScanResult? tryParseXxx(String raw)` 형태, 실패 시 null 반환):

| 파서 | 매칭 조건 | parsedMeta 키 |
|------|-----------|---------------|
| `tryParseUrl` | `raw.startsWith('http://') \|\| raw.startsWith('https://')` (단, `apptag://` 제외) | `{ 'url': String }` |
| `tryParseWifi` | `raw.toUpperCase().startsWith('WIFI:')` | `{ 'ssid': String, 'password': String?, 'securityType': String }` |
| `tryParseContact` | `raw.contains('BEGIN:VCARD')` or `raw.toUpperCase().startsWith('MECARD:')` | `{ 'name': String, 'phone': String?, 'email': String? }` |
| `tryParseSms` | `raw.toUpperCase().startsWith('SMSTO:')` or `raw.startsWith('sms:')` | `{ 'phone': String, 'message': String? }` |
| `tryParseEmail` | `raw.startsWith('mailto:')` or `raw.toUpperCase().startsWith('MATMSG:')` | `{ 'address': String, 'subject': String?, 'body': String? }` |
| `tryParseLocation` | `raw.startsWith('geo:')` | `{ 'lat': double, 'lng': double, 'label': String? }` |
| `tryParseEvent` | `raw.contains('BEGIN:VEVENT')` | `{ 'title': String, 'start': String, 'end': String, 'location': String?, 'description': String? }` |
| `tryParseAppDeepLink` | `raw.startsWith('apptag://')` | `{ 'uri': String }` |

### 2.2 scan_history feature

#### 2.2.1 Entity

```dart
// domain/entities/scan_history_entry.dart
@immutable
class ScanHistoryEntry {
  final String id;           // uuid v4
  final DateTime scannedAt;
  final String rawValue;
  final ScanDetectedType detectedType;
  final Map<String, dynamic> parsedMeta;
  final bool isFavorite;

  const ScanHistoryEntry({
    required this.id,
    required this.scannedAt,
    required this.rawValue,
    required this.detectedType,
    required this.parsedMeta,
    this.isFavorite = false,
  });

  ScanHistoryEntry copyWith({
    bool? isFavorite,
  }) => ScanHistoryEntry(
    id: id,
    scannedAt: scannedAt,
    rawValue: rawValue,
    detectedType: detectedType,
    parsedMeta: parsedMeta,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
```

#### 2.2.2 Hive Model

```dart
// data/models/scan_history_model.dart
part 'scan_history_model.g.dart';

/// Hive DTO for ScanHistoryEntry.
///
/// typeId: 4 (기존: 0=폐기, 1=UserQrTemplateModel, 2=QrTaskModel, 3=UserColorPaletteModel)
///
/// 설계: QrTaskModel 과 동일 철학 — 핵심 인덱싱 필드만 Hive 직접 필드,
/// 나머지(parsedMeta 등)는 payloadJson 에 JSON 문자열로 보관.
@HiveType(typeId: 4)
class ScanHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime scannedAt;

  @HiveField(2)
  final String detectedType;  // ScanDetectedType.name

  @HiveField(3)
  final String payloadJson;   // { rawValue, parsedMeta, isFavorite }

  static const String boxName = 'scan_history_box';

  ScanHistoryModel({
    required this.id,
    required this.scannedAt,
    required this.detectedType,
    required this.payloadJson,
  });

  ScanHistoryEntry toEntity() {
    final map = jsonDecode(payloadJson) as Map<String, dynamic>;
    return ScanHistoryEntry(
      id: id,
      scannedAt: scannedAt,
      rawValue: map['rawValue'] as String? ?? '',
      detectedType: ScanDetectedType.values.firstWhere(
        (e) => e.name == detectedType,
        orElse: () => ScanDetectedType.text,
      ),
      parsedMeta: map['parsedMeta'] as Map<String, dynamic>? ?? const {},
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  factory ScanHistoryModel.fromEntity(ScanHistoryEntry e) {
    return ScanHistoryModel(
      id: e.id,
      scannedAt: e.scannedAt,
      detectedType: e.detectedType.name,
      payloadJson: jsonEncode({
        'rawValue': e.rawValue,
        'parsedMeta': e.parsedMeta,
        'isFavorite': e.isFavorite,
      }),
    );
  }
}
```

#### 2.2.3 Composite State + Notifier

```dart
// scan_history_provider.dart (메인, ≤ 200줄 목표)
library;

import ...;

part 'notifier/list_setters.dart';
part 'notifier/filter_setters.dart';

class ScanHistoryState {
  final ScanHistoryListState list;
  final ScanHistoryFilterState filter;

  const ScanHistoryState({
    this.list = const ScanHistoryListState(),
    this.filter = const ScanHistoryFilterState(),
  });

  ScanHistoryState copyWith({
    ScanHistoryListState? list,
    ScanHistoryFilterState? filter,
  }) => ScanHistoryState(
    list: list ?? this.list,
    filter: filter ?? this.filter,
  );

  // == / hashCode
}

class ScanHistoryNotifier extends StateNotifier<ScanHistoryState>
    with _ListSetters, _FilterSetters {
  @override
  final Ref _ref;

  ScanHistoryNotifier(this._ref) : super(const ScanHistoryState()) {
    _loadAll();   // _ListSetters
  }

  @override
  void dispose() {
    super.dispose();
  }
}

final scanHistoryProvider =
    StateNotifierProvider.autoDispose<ScanHistoryNotifier, ScanHistoryState>(
  (ref) => ScanHistoryNotifier(ref),
);
```

#### 2.2.4 Sub-States

```dart
// domain/state/scan_history_list_state.dart
@immutable
class ScanHistoryListState {
  final List<ScanHistoryEntry> items;
  final bool isLoading;

  const ScanHistoryListState({
    this.items = const [],
    this.isLoading = false,
  });

  ScanHistoryListState copyWith({
    List<ScanHistoryEntry>? items,
    bool? isLoading,
  }) => ScanHistoryListState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
  );
}
```

```dart
// domain/state/scan_history_filter_state.dart
@immutable
class ScanHistoryFilterState {
  final String query;
  final ScanDetectedType? selectedType;  // null = 전체
  final bool favoritesOnly;

  const ScanHistoryFilterState({
    this.query = '',
    this.selectedType,
    this.favoritesOnly = false,
  });

  ScanHistoryFilterState copyWith({
    String? query,
    ScanDetectedType? selectedType,
    bool? favoritesOnly,
    bool clearSelectedType = false,
  }) => ScanHistoryFilterState(
    query: query ?? this.query,
    selectedType: clearSelectedType ? null : (selectedType ?? this.selectedType),
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
  );
}
```

#### 2.2.5 Mixin Setters

```dart
// notifier/list_setters.dart
part of '../scan_history_provider.dart';

mixin _ListSetters on StateNotifier<ScanHistoryState> {
  Ref get _ref;

  Future<void> _loadAll() async {
    state = state.copyWith(list: state.list.copyWith(isLoading: true));
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    final entries = await datasource.getAll();
    state = state.copyWith(
      list: state.list.copyWith(items: entries, isLoading: false),
    );
  }

  Future<void> addEntry({
    required String rawValue,
    required ScanDetectedType detectedType,
    required Map<String, dynamic> parsedMeta,
  }) async {
    final entry = ScanHistoryEntry(
      id: const Uuid().v4(),
      scannedAt: DateTime.now(),
      rawValue: rawValue,
      detectedType: detectedType,
      parsedMeta: parsedMeta,
    );
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.save(entry);
    state = state.copyWith(
      list: state.list.copyWith(items: [entry, ...state.list.items]),
    );
  }

  Future<void> toggleFavorite(String id) async {
    final idx = state.list.items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final updated = state.list.items[idx].copyWith(
      isFavorite: !state.list.items[idx].isFavorite,
    );
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.save(updated);
    final newList = [...state.list.items]..[idx] = updated;
    state = state.copyWith(list: state.list.copyWith(items: newList));
  }

  Future<void> deleteEntry(String id) async {
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.delete(id);
    state = state.copyWith(
      list: state.list.copyWith(
        items: state.list.items.where((e) => e.id != id).toList(),
      ),
    );
  }

  Future<void> clearAll() async {
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.clearAll();
    state = state.copyWith(list: const ScanHistoryListState());
  }
}
```

```dart
// notifier/filter_setters.dart
part of '../scan_history_provider.dart';

mixin _FilterSetters on StateNotifier<ScanHistoryState> {
  Ref get _ref;

  void setQuery(String query) {
    state = state.copyWith(
      filter: state.filter.copyWith(query: query),
    );
  }

  void setTypeFilter(ScanDetectedType? type) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        selectedType: type,
        clearSelectedType: type == null,
      ),
    );
  }

  void toggleFavoritesOnly() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        favoritesOnly: !state.filter.favoritesOnly,
      ),
    );
  }

  void clearFilters() {
    state = state.copyWith(filter: const ScanHistoryFilterState());
  }
}
```

### 2.3 QrTask isFavorite 확장

**설계 결정**: `isFavorite` 를 `QrTaskModel` 의 `payloadJson` 내부에 추가 (Hive `@HiveField` 추가 아님).

**근거**: 기존 `QrTaskModel` 은 "4개 필드만 Hive 화, 나머지는 payloadJson" 철학. `isFavorite` 는 꾸미기 상세와 같은 레벨의 메타 데이터이므로 payload 안에 들어가는 것이 일관적. 기존 데이터는 `map['isFavorite'] ?? false` 로 자동 복원되어 Hive 스키마 변경 없음.

```dart
// qr_task.dart 변경
class QrTask {
  // ... 기존 필드 ...
  final bool isFavorite;    // 신규

  const QrTask({
    // ... 기존 ...
    this.isFavorite = false,
  });

  Map<String, dynamic> toPayloadMap() => {
    // ... 기존 ...
    'isFavorite': isFavorite,
  };

  factory QrTask.fromPayloadMap({...}) {
    return QrTask(
      // ... 기존 ...
      isFavorite: map['isFavorite'] as bool? ?? false,  // 기존 데이터 자동 false
    );
  }

  QrTask copyWith({
    // ... 기존 ...
    bool? isFavorite,
  }) => QrTask(
    // ... 기존 ...
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
```

`QrTaskModel` 에는 Hive 필드 변경 **없음**. `payloadJson` 안에서 처리.

### 2.4 QrTaskListNotifier 확장

```dart
// qr_task_list_notifier.dart 에 추가할 메서드
class QrTaskListNotifier extends StateNotifier<List<QrTask>> {
  // ... 기존 _list, _delete, _clear, _load ...

  final UpdateQrTaskCustomizationUseCase _update;  // 신규 주입

  /// 즐겨찾기 토글 — payload 내 isFavorite 만 변경 후 저장.
  Future<void> toggleFavorite(String id) async {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final task = state[idx];
    final updated = task.copyWith(isFavorite: !task.isFavorite);
    // payloadJson 전체 재직렬화하여 Hive 저장
    await _ref.read(qrTaskRepositoryProvider).update(updated);
    state = [...state]..[idx] = updated;
  }
}
```

> **Note**: `toggleFavorite` 은 기존 `QrTaskRepository` 에 `update(QrTask)` 메서드 추가가 필요. 구현 시 `HiveQrTaskDataSource.put(id, QrTaskModel.fromEntity(task))` 로 처리.

---

## 3. UI Specification

### 3.1 Scanner Screen (`/scanner`)

| 영역 | 위젯 | 설명 |
|------|------|------|
| 전체 배경 | `MobileScanner` | 카메라 풀스크린 프리뷰 |
| 중앙 오버레이 | `ScanningReticle` | 250x250 반투명 사각형, 모서리 4개에 2px 흰색 L자 장식. 인식 성공 시 `AnimatedContainer` 로 border color → green + scale 0.95 → 1.0 (200ms) |
| 하단 바 | `ScannerControlBar` | `SafeArea` 하단 정렬. Row: 플래시 `IconButton(Icons.flash_on/off)` + 갤러리 `IconButton(Icons.photo_library)` |
| 상단 뒤로가기 | `AppBar` transparent | 좌측 `BackButton` (white), 배경 투명 |
| 권한 거부 | `PermissionFallbackView` | 카메라 아이콘 + "카메라 권한이 필요합니다" 안내 + "설정으로 이동" 버튼 (`openAppSettings()`) + "갤러리에서 선택" 버튼 |

### 3.2 Result Bottom Sheet

```
┌─────────────────────────────┐
│  ═══  (drag handle)          │
│                              │
│  🌐  URL                     │  ← DataTypeTag (icon + label)
│                              │
│  https://example.com         │  ← PreviewArea (rawValue or parsed title)
│                              │
│  ┌──────────┐ ┌──────────┐  │
│  │ 열기     │ │ 복사     │  │  ← PrimaryActions (타입별 1~3개)
│  └──────────┘ └──────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │    ✨ 꾸미기            │  │  ← 공통 "꾸미기" 버튼 (accent color, full-width)
│  └────────────────────────┘  │
└─────────────────────────────┘
```

- `showModalBottomSheet` (route 아닌 overlay)
- `isScrollControlled: true`, `useSafeArea: true`
- 아래로 스와이프 → 자동 닫힘 → `ScannerNotifier.dismissResult()` 호출

### 3.3 "꾸미기" 버튼 — 태그 화면 값 주입 규격

각 태그 화면은 현재 `context.push('/qr-result', extra: _buildArgs())` 패턴을 사용. 스캔 결과의 "꾸미기" 는 **태그 화면을 경유하여** 해당 화면의 `extra` 파라미터로 값을 주입하는 것이 아니라, 태그 화면에 **prefill** 파라미터를 전달해야 함.

**설계 결정**: 각 태그 화면에 `extra: Map<String,dynamic>` 수신 기능 추가.

```dart
// GoRoute 에서 extra 를 전달:
GoRoute(
  path: '/website-tag',
  builder: (_, state) => WebsiteTagScreen(
    prefill: state.extra as Map<String, dynamic>?,
  ),
),

// WebsiteTagScreen 수정:
class WebsiteTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const WebsiteTagScreen({super.key, this.prefill});
  ...
}

// initState 에서:
@override
void initState() {
  super.initState();
  if (widget.prefill != null) {
    _controller.text = widget.prefill!['url'] as String? ?? '';
  }
}
```

**태그별 prefill 매핑**:

| ScanDetectedType | 라우트 | prefill 키 → 폼 필드 |
|------------------|--------|----------------------|
| `url` | `/website-tag` | `{ 'url': String }` → `_controller.text` |
| `wifi` | `/wifi-tag` | `{ 'ssid': String, 'password': String?, 'securityType': String }` → 각 컨트롤러 |
| `contact` | `/contact-manual` | `{ 'name': String, 'phone': String?, 'email': String? }` → 각 컨트롤러 |
| `sms` | `/sms-tag` | `{ 'phone': String, 'message': String? }` → 각 컨트롤러 |
| `email` | `/email-tag` | `{ 'address': String, 'subject': String?, 'body': String? }` → 각 컨트롤러 |
| `location` | `/location-tag` | `{ 'lat': double, 'lng': double, 'label': String? }` → 지도 마커 + 라벨 |
| `event` | `/event-tag` | `{ 'title': String, 'start': String, 'end': String, 'location': String? }` → 각 컨트롤러 |
| `appDeepLink` | `/clipboard-tag` | `{ 'text': rawValue }` → `_controller.text` |
| `text` | `/clipboard-tag` | `{ 'text': rawValue }` → `_controller.text` |

> **Contact 타입 특이점**: `/contact-tag` 는 연락처 목록 선택 화면이므로 스캔 결과 prefill 에는 `/contact-manual` 직접 진입이 적합.

### 3.4 History Screen 2-탭 개편

```
┌──────────────────────────────────┐
│  AppBar: "이력"                   │
│  [생성이력] [스캔이력]  ← TabBar  │
├──────────────────────────────────┤
│  🔍 검색...            ← SearchBar│
│  [전체] [URL] [WiFi] ...← Chips  │
├──────────────────────────────────┤
│  ┌────────────────────────────┐  │
│  │ 🌐 example.com       ⭐   │  │  ← HistoryTile
│  │     URL · 2026.04.21 14:30 │  │     좌 스와이프 → 삭제
│  ├────────────────────────────┤  │
│  │ 📱 앱이름            ⭐   │  │
│  │     QR · Android           │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

#### 공통 위젯 시그니처

```dart
// history/presentation/widgets/history_list_view.dart
/// 제네릭 히스토리 리스트. T = QrTask | ScanHistoryEntry
class HistoryListView<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) titleExtractor;
  final String Function(T) subtitleExtractor;
  final IconData Function(T) iconExtractor;
  final bool Function(T) isFavoriteExtractor;
  final void Function(T) onTap;
  final void Function(T) onDelete;
  final void Function(T) onToggleFavorite;

  const HistoryListView({...});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item),
          direction: DismissDirection.endToStart,
          background: _deleteBackground(),
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) => onDelete(item),
          child: HistoryTile(
            icon: iconExtractor(item),
            title: titleExtractor(item),
            subtitle: subtitleExtractor(item),
            isFavorite: isFavoriteExtractor(item),
            onTap: () => onTap(item),
            onToggleFavorite: () => onToggleFavorite(item),
          ),
        );
      },
    );
  }
}
```

```dart
// history/presentation/widgets/history_filter_chips.dart
class HistoryFilterChips extends StatelessWidget {
  final List<String> availableTypes;  // 현재 데이터에서 추출한 타입 목록
  final String? selectedType;         // null = 전체
  final ValueChanged<String?> onSelected;
  ...
}
```

```dart
// history/presentation/widgets/history_search_bar.dart
class HistorySearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;
  ...
}
```

#### HistoryScreen 개편

```dart
// history_screen.dart — TabBar 2탭 구조
class HistoryScreen extends ConsumerStatefulWidget {
  ...
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenHistoryTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.historyTabCreated),   // 생성이력
            Tab(text: l10n.historyTabScanned),    // 스캔이력
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CreatedHistoryTab(),    // 기존 qrTaskListNotifier 기반
          _ScannedHistoryTab(),    // 신규 scanHistoryProvider 기반
        ],
      ),
    );
  }
}
```

---

## 4. Router Changes

```dart
// lib/core/di/router.dart 추가
GoRoute(
  path: '/scanner',
  builder: (_, _) => const ScannerScreen(),
),

// 기존 태그 화면 라우트 수정 — extra 를 prefill 로 전달
GoRoute(
  path: '/website-tag',
  builder: (_, state) => WebsiteTagScreen(
    prefill: state.extra as Map<String, dynamic>?,
  ),
),
// ... 나머지 태그 화면도 동일 패턴 ...
```

---

## 5. Hive Configuration

### 5.1 TypeId Registry (전수)

| typeId | Model | Box Name | Status |
|--------|-------|----------|--------|
| 0 | TagHistoryModel (폐기) | `tag_history` (삭제됨) | Deprecated |
| 1 | UserQrTemplateModel | `user_qr_templates` | Active |
| 2 | QrTaskModel | `qr_task_box` | Active |
| 3 | UserColorPaletteModel | `user_color_palettes` | Active |
| **4** | **ScanHistoryModel** | **`scan_history_box`** | **신규** |

### 5.2 hive_config.dart 변경

```dart
// 추가:
import '../../features/scan_history/data/models/scan_history_model.dart';
import '../../features/scan_history/data/datasources/hive_scan_history_datasource.dart';

// initHive() 내부 추가:
if (!Hive.isAdapterRegistered(4)) {
  Hive.registerAdapter(ScanHistoryModelAdapter());
}

if (!Hive.isBoxOpen(ScanHistoryModel.boxName)) {
  await Hive.openBox<ScanHistoryModel>(ScanHistoryModel.boxName);
}
```

---

## 6. Dependency Changes

### 6.1 pubspec.yaml

```yaml
# 추가 (QR 스캔)
mobile_scanner: ^6.0.0
```

> **`permission_handler` 는 이미 `^11.3.1` 로 등록됨** — 추가 불필요.

### 6.2 WiFi 자동 연결 (FR-09) 범위 결정

**설계 결정**: WiFi 자동 연결은 **MVP에서 제외**. 양쪽 플랫폼 모두 "SSID 복사" + "비밀번호 복사" 만 지원.

**근거**:
- Android: `WifiManager` deprecated, `wifi_iot` 패키지는 Android 10+ 에서 제한적
- iOS: `NEHotspotConfiguration` 은 Network Extension entitlement + Apple 심사 필요
- 복사 → 설정 앱에서 수동 연결이 더 안정적이고 사용자 기대와 부합
- 후속 버전에서 `wifi_iot` (Android only) 추가 가능

### 6.3 Platform Manifests

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<!-- 확인: <uses-permission android:name="android.permission.CAMERA" /> 존재 여부 확인, 없으면 추가 -->
```

```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>QR 코드를 스캔하기 위해 카메라 접근이 필요합니다.</string>
```

---

## 7. Home Screen Tile Insertion

```dart
// home_screen.dart _buildTiles() 수정 — index 0 에 삽입
List<_TileItem> _buildTiles() {
  final l10n = AppLocalizations.of(context)!;
  return [
    // ─── 신규 ─────────────────────────
    _TileItem(
      key: 'scanner',
      icon: Icons.qr_code_scanner,
      label: l10n.tileScanner,         // app_ko.arb: "QR 스캐너"
      iconColor: Colors.white,
      bgColor: const Color(0xFF00897B), // teal 600
      onTap: () => context.push('/scanner'),
    ),
    // ─── 기존 타일들 ──────────────────
    _TileItem(key: 'app', ...),
    // ...
  ];
}
```

> 10개 타일 (2x5) 기존 `childAspectRatio` 1.1 유지.

---

## 8. l10n Additions (app_ko.arb)

```json
{
  "tileScanner": "QR 스캐너",
  "scannerPermissionTitle": "카메라 권한 필요",
  "scannerPermissionDesc": "QR 코드를 스캔하려면 카메라 접근 권한이 필요합니다.",
  "scannerPermissionOpenSettings": "설정으로 이동",
  "scannerPermissionGalleryFallback": "갤러리에서 선택",
  "scannerFlashOn": "플래시 켜기",
  "scannerFlashOff": "플래시 끄기",
  "scannerGalleryImport": "갤러리에서 QR 코드 불러오기",
  "scannerGalleryFail": "이미지에서 QR 코드를 인식할 수 없습니다.",
  "scanResultTitle": "스캔 결과",
  "scanActionOpenBrowser": "열기",
  "scanActionCopyLink": "링크 복사",
  "scanActionCopySsid": "SSID 복사",
  "scanActionCopyPassword": "비밀번호 복사",
  "scanActionCopyAll": "전체 복사",
  "scanActionShare": "공유",
  "scanActionOpenApp": "앱 열기",
  "scanActionCustomize": "꾸미기",
  "scanTypeUrl": "URL",
  "scanTypeWifi": "WiFi",
  "scanTypeContact": "연락처",
  "scanTypeSms": "SMS",
  "scanTypeEmail": "이메일",
  "scanTypeLocation": "위치",
  "scanTypeEvent": "일정",
  "scanTypeAppDeepLink": "앱 딥링크",
  "scanTypeText": "텍스트",
  "historyTabCreated": "생성이력",
  "historyTabScanned": "스캔이력",
  "historySearchHint": "검색...",
  "historyFilterAll": "전체",
  "historyEmpty": "이력이 없습니다.",
  "actionFavorite": "즐겨찾기",
  "wifiPasswordMasked": "••••"
}
```

---

## 9. Implementation Order

구현은 아래 순서로 진행. 각 단계는 독립적으로 컴파일/검증 가능하도록 설계.

| Phase | 파일 | 설명 | 예상 변경량 |
|:-----:|------|------|:-----------:|
| **P1** | `scan_detected_type.dart`, `scan_result.dart` | 엔티티 정의 | ~80줄 |
| **P2** | `parser/*.dart` (9개 파서 + 디스패처) | 타입 파서 구현 | ~400줄 |
| **P3** | `scanner_camera_state.dart`, `scanner_result_state.dart` | Sub-state 정의 | ~80줄 |
| **P4** | `scanner_provider.dart`, `camera_setters.dart`, `result_setters.dart` | 스캐너 상태 관리 | ~200줄 |
| **P5** | `scan_history_entry.dart`, `scan_history_model.dart`, `hive_scan_history_datasource.dart` | ScanHistory 도메인+데이터 | ~200줄 |
| **P6** | `scan_history_provider.dart`, `list_setters.dart`, `filter_setters.dart`, `scan_history_list_state.dart`, `scan_history_filter_state.dart` | ScanHistory 상태 관리 | ~250줄 |
| **P7** | `hive_config.dart`, `pubspec.yaml`, `AndroidManifest.xml`, `Info.plist` | 인프라 설정 | ~20줄 |
| **P8** | `qr_task.dart` isFavorite 추가, `qr_task_list_notifier.dart` 확장 | 기존 모듈 확장 | ~40줄 |
| **P9** | `scanner_screen.dart`, `scanning_reticle.dart`, `scanner_control_bar.dart`, `permission_fallback_view.dart` | 스캐너 UI | ~350줄 |
| **P10** | `result_sheet.dart`, `data_type_tag.dart`, `preview_area.dart`, `primary_actions.dart` | Bottom Sheet UI | ~300줄 |
| **P11** | `history_screen.dart` 2탭 개편, `history_list_view.dart`, `history_tile.dart`, `history_search_bar.dart`, `history_filter_chips.dart` | History UI | ~400줄 |
| **P12** | `router.dart` (태그 화면 prefill 포함), `home_screen.dart` | 라우팅 + 홈 타일 | ~60줄 |
| **P13** | 태그 화면 9종 prefill 수신 (`WebsiteTagScreen`, `WifiTagScreen`, ...) | 기존 화면 수정 | ~100줄 |
| **P14** | `app_ko.arb` | l10n 문자열 | ~40줄 |

**총 예상**: ~2,520줄 신규/수정

---

## 10. R-series Hard Rules 준수 체크리스트

| # | Rule | scanner | scan_history | qr_task 수정 |
|---|------|:-------:|:------------:|:------------:|
| 1 | No flat fields on composite state | ✅ `state.camera.flashOn` | ✅ `state.list.items` | N/A |
| 2 | No `_sentinel` — `clearXxx: bool` | ✅ `clearErrorMessage`, `clearCurrentResult` | ✅ `clearSelectedType` | N/A |
| 3 | No backward-compat getters | ✅ | ✅ | ✅ |
| 4 | No re-exports | ✅ | ✅ | N/A |
| 5 | Mixin `_` prefix | ✅ `_CameraSetters`, `_ResultSetters` | ✅ `_ListSetters`, `_FilterSetters` | N/A |
| 6 | 각 sub-state = 단일 관심사 | ✅ camera / result | ✅ list / filter | N/A |
| 7 | Notifier body = lifecycle only | ✅ `initialize()`, `dispose()` | ✅ `_loadAll()`, `dispose()` | N/A |
| 8 | 파일 크기 준수 | ✅ 메인≤200, mixin≤150 | ✅ 메인≤200, mixin≤150 | N/A |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-21 | 초안 — Plan 기반 상세 설계. R-series 고정, typeId 4 할당, WiFi 자동연결 MVP 제외, isFavorite payloadJson 내 관리 | tawool83 |
