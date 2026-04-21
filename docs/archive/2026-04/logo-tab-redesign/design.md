---
template: design
version: 1.3
feature: logo-tab-redesign
date: 2026-04-21
author: tawool83
project: app_tag
---

# logo-tab-redesign Design Document

> **Summary**: 로고 탭을 재설계하여 상단 표시 토글 + 우측 `로고/이미지/텍스트` 드롭다운을 도입하고, 타입별 전용 편집기(번들 SVG 카테고리 그리드 / 갤러리+전체화면 크롭 / 문구+스타일) 제공. 로고 배경(square/circle)의 **fill 색상** 설정 기능 추가 (기본 흰색 → 사용자 지정 가능). 클린 아키텍처로 domain sealed class + repository + use case 분리.
>
> **Revision history**:
> - **v1.3 (2026-04-21)** — Act-1~6 누적 반영
>   - Act-1: `CropLogoImageUseCase` 단일 압축 (`compressFormat: png` + `encodeJpg Q85`) / `loadFromCustomization` 후 `_rehydrateLogoAssetIfNeeded` (logoAssetId → PNG 재래스터화)
>   - Act-2: `logoBackgroundBorderColor*` → `logoBackgroundColor*` rename. 렌더링 `Border.all` → `Container.color` (fill). 라벨 "배경 테두리" → "색상"
>   - Act-3: `LogoBackground` 에 `rectangle`, `roundedRectangle` append (텍스트 전용). `ConstrainedBox(maxWidth: size × 0.6)` + `IntrinsicWidth`
>   - Act-4: 라벨 단순화 — `optionRectangle` "사각", `optionRoundedRectangle` "원형", `labelLogoBackgroundColor` "색상". 힌트 제거. `_BackgroundColorRow` → `_BackgroundColorColumn`
>   - Act-5: **Switch + "표시" 라벨 완전 제거**. `LogoType` 에 `none` append (first). 드롭다운 첫 옵션 "없음". `setLogoType()` / `applyLogo*()` 에서 `embedIcon` 자동 동기화. 레이아웃 재구성: Row1 = `[유형 ▾ | 위치]`, Row2 = `[배경 | 색상]`. `IndexedStack(index: currentType.index - 1)`, `isNoneType` 시 숨김
>   - Act-6 (M1~M3 cleanup): `labelLogoTabShow` ARB orphan 제거 (10 로케일). `_logoTypeFromName` 에 null vs `LogoType.none` 시맨틱 차이 docstring. 본 Revision history 추가
>
> **※ 아래 본문(§1~§7)의 일부 다이어그램·표는 v1.0 초안 표현을 일부 유지. 구현 상태와의 차이는 본 Revision history + `docs/03-analysis/logo-tab-redesign.analysis.md` §7~§9 를 정본으로 참조.**
>
> ## 구현 상태 표 (Current, v1.3)
>
> | 영역 | 상태 |
> |------|------|
> | LogoType | `{ none, logo, image, text }` — none 이 드롭다운 첫 옵션 |
> | LogoBackground | `{ none, square, circle, rectangle, roundedRectangle }` — 마지막 2개는 텍스트 전용 |
> | UI 레이아웃 | Row1: `[유형 ▾] [위치]` / Row2: `[배경] [색상]` / Divider / IndexedStack |
> | Switch | **없음** (v1.3). 드롭다운 "없음" 선택이 표시 OFF 역할 |
> | embedIcon 필드 | 유지(내부 state). `setLogoType()` / `applyLogo*()` 에서 자동 동기화 |
> | 로고 배경 | Fill 색상 (Border 없음). `logoBackgroundColor == null` → `Colors.white` |
> | 배경 모양 (텍스트) | rectangle / roundedRectangle — `ConstrainedBox(maxWidth: size × 0.6)` |
> | 배경 모양 (이미지/로고) | square(radius 6) / circle |
> | 영속화 JSON | `logoType`, `logoAssetId`, `logoImageBase64`, `logoText`, `logoBackgroundColorArgb`. 레거시 키 `logoBackgroundBorderColorArgb` fromJson fallback 유지 |
> | Hive `@HiveField` | 30~37 (초안 21~28 에서 기존 0~29 점유로 인해 shift) |
> | i18n | 10 로케일 × 약 22 키. `labelLogoTabShow` 제거됨(v1.3) |
>
> **Planning Doc**: [logo-tab-redesign.plan.md](../../01-plan/features/logo-tab-redesign.plan.md)
> **Architecture**: Option B — Clean Architecture (sealed class + repository + use cases + PNG 래스터화 통합)

---

## 1. 위젯 구조

### 1.1 변경 전 (StickerTab)

```
StickerTab (ConsumerWidget)
├── Row (MainAxisAlignment.spaceBetween)
│   ├── _SectionLabel("아이콘 표시")
│   └── Switch(embedIcon)
├── Row(Expanded×2)
│   ├── _SectionLabel("로고 위치") + _SegmentRow<LogoPosition>
│   └── _SectionLabel("로고 배경") + _SegmentRow<LogoBackground>
└── (끝)
```

### 1.2 변경 후 (StickerTab — 오케스트레이터)

```
StickerTab (ConsumerWidget)
│
├── Row 1: 표시 토글 + 타입 드롭다운
│   ├── Switch(embedIcon) + Text("표시")     ← 좌측
│   └── DropdownButton<LogoType>             ← 우측, embedIcon일 때만 활성
│       ├── LogoType.logo   (기본)
│       ├── LogoType.image
│       └── LogoType.text
│
├── Row 2: 공통 설정 (embedIcon ON + logoType != null 일 때만)
│   ├── Column: _SectionLabel("위치") + _SegmentRow<LogoPosition>
│   └── Column: _SectionLabel("배경") + _SegmentRow<LogoBackground>
│       ※ logoType == text 일 때 "배경" 숨김
│
├── Row 3: 배경 테두리 색상 (logoBackground != none 일 때만)
│   ├── _SectionLabel("배경 테두리")
│   ├── GestureDetector → HSV ColorPicker dialog
│   │   └── Circle swatch (size 32) + 현재 색상 or 대각선 빗금(null)
│   └── TextButton("없음") → logoBackgroundColor = null
│
└── Row 4: 타입별 편집기 (IndexedStack 으로 상태 유지 + 깜빡임 방지)
    ├── LogoLibraryEditor       (LogoType.logo)
    ├── LogoImageEditor          (LogoType.image)
    └── LogoTextEditor           (LogoType.text)

편집기들은 각각 ConsumerWidget. 부모 상태 의존 없이 ref.watch(qrResultProvider)로 자체 구독.
```

### 1.3 편집기 위젯 상세

#### LogoLibraryEditor (lib/features/qr_result/tabs/logo_editors/logo_library_editor.dart)

```
LogoLibraryEditor (ConsumerStatefulWidget)
│ state: selectedCategoryId (로컬 UI 상태)
│
├── FutureBuilder<LogoManifest>  (repositoryProvider 로부터 단일 fetch + 캐시)
│   ├── loading → CircularProgressIndicator (높이 180)
│   ├── error   → "아이콘을 불러올 수 없습니다" + 재시도
│   └── data    →
│       ├── 카테고리 칩 Row (SingleChildScrollView + horizontal)
│       │   └── LogoCategoryChip × N  (선택 시 Primary color)
│       └── 아이콘 그리드 (GridView.count, crossAxisCount: 5)
│           └── LogoIconTile × M
│               ├── flutter_svg: SvgPicture.asset(iconAssetPath)
│               ├── 선택 시: 파란 2px 테두리 + 체크 배지
│               └── onTap: selectLogoAssetUseCase(category/id)
```

#### LogoImageEditor (lib/features/qr_result/tabs/logo_editors/logo_image_editor.dart)

```
LogoImageEditor (ConsumerWidget)
│
├── Column
│   ├── 썸네일 미리보기 (96×96)
│   │   ├── state.sticker.logoImageBytes != null → MemoryImage
│   │   └── null → 회색 플레이스홀더 + Icon(Icons.image)
│   ├── SizedBox(height: 12)
│   └── Row
│       ├── FilledButton.icon(Icons.photo_library, "갤러리에서 선택")
│       │   └── onPressed: cropLogoImageUseCase(source: gallery)
│       └── TextButton.icon(Icons.crop, "다시 자르기")  ← logoImageBytes != null 시만
│           └── onPressed: cropLogoImageUseCase(source: lastImage) ※ 원본 보존 시
```

#### LogoTextEditor (lib/features/qr_result/tabs/logo_editors/logo_text_editor.dart)

```
LogoTextEditor (ConsumerStatefulWidget)
│ state: TextEditingController, draftStickerText
│ ※ text_tab.dart 의 _TextEditor 패턴 참조 (복제 아님 — 로고 전용 제약 적용)
│
├── Row: 라벨 "문구" + TextField(maxLength: 6)
│   └── onChanged → _emit → setLogoTextUseCase(...)
├── Row
│   ├── GestureDetector(color circle, size 32) → HSV dialog → color
│   ├── DropdownButton<String>(sans/serif/mono)
│   └── StepperRow(10~40sp, 초기 20sp)
```

### 1.4 렌더링 파이프라인 변경 (qr_layer_stack.dart)

```
_QrLayerStackState.build
└── StickerLayer (로고 렌더링)
    │
    ├── iconProvider = resolveLogoImageProvider(state)       ← centerImageProvider 대체
    │   │
    │   ├── if (!state.embedIcon) return null
    │   ├── state.sticker.logoType == text   → null (Widget 오버레이로 처리)
    │   ├── state.sticker.logoType == image  → MemoryImage(sticker.logoImageBytes)
    │   ├── state.sticker.logoType == logo   → MemoryImage(state.logoAssetBytes)  ← 래스터화 결과 캐시
    │   ├── state.sticker.logoType == null (레거시) → 기존 로직
    │   │   (templateCenterIconBytes > emojiIconBytes > defaultIconBytes)
    │   └── else → null
    │
    ├── bgContainer = _buildLogoBackground(
    │     sticker.logoBackground,
    │     borderColor: sticker.logoBackgroundColor,
    │   )
    │   ├── LogoBackground.none   → SizedBox (투명)
    │   ├── LogoBackground.square → Container(
    │   │     color: Colors.white,
    │   │     borderRadius: BorderRadius.circular(6),
    │   │     border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
    │   │     boxShadow: [BoxShadow(Colors.black12, blurRadius: 2)]
    │   │   )
    │   └── LogoBackground.circle → Container(
    │         shape: BoxShape.circle,
    │         + border: Border.all(... 1.5) if borderColor != null
    │       )
    │
    └── StackedContent:
        ├── bgContainer
        ├── iconProvider → Image (크기 iconSize)
        └── logoType == text:
            → Positioned.fill → Center → Text(sticker.logoText.content,
                 style: TextStyle(color, fontFamily, fontSize, ...))
```

---

## 2. 도메인 레이어 (Clean Architecture)

### 2.1 sealed class — LogoSource

**위치**: `lib/features/qr_result/domain/entities/logo_source.dart`

```dart
/// 로고 소스의 3가지 변종. UI의 드롭다운 선택을 도메인 타입으로 승격.
/// sealed class로 패턴 매칭 + null 방어.
sealed class LogoSource {
  const LogoSource();
}

class LogoSourceLibrary extends LogoSource {
  final String assetId;           // "social/twitter"
  final String category;          // "social"
  final String iconId;            // "twitter"
  const LogoSourceLibrary({
    required this.assetId,
    required this.category,
    required this.iconId,
  });
}

class LogoSourceImage extends LogoSource {
  final Uint8List croppedBytes;   // 256x256 JPEG Q85
  const LogoSourceImage(this.croppedBytes);
}

class LogoSourceText extends LogoSource {
  final StickerText text;         // 기존 StickerText 재사용
  const LogoSourceText(this.text);
}

/// UI 드롭다운용 enum (StickerConfig 영속 필드)
enum LogoType { logo, image, text }

extension LogoTypeMapping on LogoSource {
  LogoType get type => switch (this) {
    LogoSourceLibrary _ => LogoType.logo,
    LogoSourceImage _ => LogoType.image,
    LogoSourceText _ => LogoType.text,
  };
}
```

### 2.2 LogoManifest 엔티티

**위치**: `lib/features/qr_result/domain/entities/logo_manifest.dart`

```dart
class LogoManifest {
  final List<LogoCategory> categories;
  const LogoManifest(this.categories);
  static const empty = LogoManifest([]);
}

class LogoCategory {
  final String id;                // "social"
  final String nameKo;            // "소셜"
  final List<LogoAsset> icons;
  const LogoCategory({required this.id, required this.nameKo, required this.icons});
}

class LogoAsset {
  final String id;                // "twitter"
  final String assetPath;         // "assets/logos/social/twitter.svg"
  const LogoAsset({required this.id, required this.assetPath});

  /// Composite id: "social/twitter"
  String compositeId(String categoryId) => '$categoryId/$id';
}
```

### 2.3 Repository 인터페이스

**위치**: `lib/features/qr_result/domain/repositories/logo_manifest_repository.dart`

```dart
import '../../../../core/error/result.dart';
import '../entities/logo_manifest.dart';

abstract class LogoManifestRepository {
  /// assets/logos/manifest.json 을 로드. 결과는 메모리 캐시.
  Future<Result<LogoManifest>> load();

  /// Composite id("social/twitter") 로부터 PNG bytes 래스터화 (96×96).
  /// 결과는 LRU 캐시 (최대 32개).
  Future<Result<Uint8List>> rasterize(String compositeId, {double size = 96});
}
```

### 2.4 UseCase 시그니처

**위치**: `lib/features/qr_result/domain/usecases/`

```dart
/// select_logo_asset_usecase.dart
class SelectLogoAssetUseCase {
  final LogoManifestRepository _repo;
  const SelectLogoAssetUseCase(this._repo);

  /// 1) manifest 검증
  /// 2) SVG → PNG 래스터화
  /// 3) LogoSourceLibrary 반환 + PNG bytes 반환
  Future<Result<({LogoSourceLibrary source, Uint8List pngBytes})>> call({
    required String category,
    required String iconId,
  });
}

/// crop_logo_image_usecase.dart
class CropLogoImageUseCase {
  /// 1) image_picker (gallery) → XFile
  /// 2) image_cropper(aspectRatio 1:1, CropStyle.rectangle, full-screen modal)
  /// 3) CroppedFile → package:image 재인코딩 (256x256 JPEG Q85)
  /// 4) LogoSourceImage(croppedBytes) 반환
  /// null 반환 시 사용자가 취소한 것
  Future<Result<LogoSourceImage?>> call({required BuildContext ctx});
}

/// rasterize_text_logo_usecase.dart (선택적)
/// 텍스트 로고를 저장·공유 시 동일 픽셀 로직으로 캡처하기 위한 도구.
/// 탭 미리보기는 Widget 오버레이(저비용), 저장/공유/인쇄는 이 use case로 PNG 생성.
class RasterizeTextLogoUseCase {
  /// TextPainter로 Canvas에 그려 96×96 PNG 반환.
  Future<Result<Uint8List>> call(StickerText text);
}
```

### 2.5 Data 레이어 구현

**위치**: `lib/features/qr_result/data/repositories/logo_manifest_repository_impl.dart`

```dart
class LogoManifestRepositoryImpl implements LogoManifestRepository {
  final AssetBundle _bundle;
  LogoManifest? _cachedManifest;
  final _pngCache = <String, Uint8List>{}; // LRU max 32

  LogoManifestRepositoryImpl(this._bundle);

  @override
  Future<Result<LogoManifest>> load() async {
    if (_cachedManifest != null) return Result.success(_cachedManifest!);
    try {
      final raw = await _bundle.loadString('assets/logos/manifest.json');
      final json = jsonDecode(raw);
      final manifest = _parseManifest(json);
      _cachedManifest = manifest;
      return Result.success(manifest);
    } catch (e, st) {
      return Result.failure(AppException('Failed to load logo manifest', cause: e));
    }
  }

  @override
  Future<Result<Uint8List>> rasterize(String compositeId, {double size = 96}) async {
    if (_pngCache.containsKey(compositeId)) {
      return Result.success(_pngCache[compositeId]!);
    }
    try {
      // 1) manifest에서 assetPath 찾기
      final manifest = (await load()).valueOrNull;
      final asset = _findAsset(manifest, compositeId);
      if (asset == null) return Result.failure(AppException('Asset not found'));

      // 2) SVG 로드 + Canvas 래스터화 (flutter_svg 의 PictureInfo 활용)
      final svgStr = await _bundle.loadString(asset.assetPath);
      final pictureInfo = await vg.loadPicture(SvgStringLoader(svgStr), null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // 원본 viewBox → size 스케일
      final sx = size / pictureInfo.size.width;
      final sy = size / pictureInfo.size.height;
      canvas.scale(sx, sy);
      canvas.drawPicture(pictureInfo.picture);
      final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = bd!.buffer.asUint8List();
      pictureInfo.picture.dispose();

      _enforceLru(compositeId);
      _pngCache[compositeId] = bytes;
      return Result.success(bytes);
    } catch (e) {
      return Result.failure(AppException('Failed to rasterize $compositeId', cause: e));
    }
  }

  void _enforceLru(String newKey) {
    if (_pngCache.length >= 32) {
      final oldest = _pngCache.keys.first;
      _pngCache.remove(oldest);
    }
  }
}
```

### 2.6 Provider 와이어업

**위치**: `lib/features/qr_result/presentation/providers/qr_result_providers.dart`

```dart
final logoManifestRepositoryProvider = Provider<LogoManifestRepository>((ref) {
  return LogoManifestRepositoryImpl(rootBundle);
});

final logoManifestProvider = FutureProvider<LogoManifest>((ref) async {
  final res = await ref.read(logoManifestRepositoryProvider).load();
  return res.valueOrNull ?? LogoManifest.empty;
});

final selectLogoAssetUseCaseProvider = Provider<SelectLogoAssetUseCase>((ref) {
  return SelectLogoAssetUseCase(ref.read(logoManifestRepositoryProvider));
});

final cropLogoImageUseCaseProvider = Provider<CropLogoImageUseCase>((ref) {
  return CropLogoImageUseCase();
});

final rasterizeTextLogoUseCaseProvider = Provider<RasterizeTextLogoUseCase>((ref) {
  return RasterizeTextLogoUseCase();
});
```

---

## 3. 데이터 모델 변경

### 3.1 StickerConfig (sticker_config.dart)

```dart
enum LogoType { logo, image, text }   // 신규

class StickerConfig {
  // 기존 4개
  final LogoPosition logoPosition;
  final LogoBackground logoBackground;
  final StickerText? topText;
  final StickerText? bottomText;

  // 신규 6개 (모두 nullable)
  final LogoType? logoType;                   // null = 레거시 경로
  final String? logoAssetId;                  // "social/twitter"
  final Uint8List? logoImageBytes;            // 256×256 JPEG
  final StickerText? logoText;                // 로고용 텍스트
  final Uint8List? logoAssetPngBytes;         // 래스터화 결과 캐시 (메모리 전용, 영속X)
  final Color? logoBackgroundColor;     // null = 테두리 없음

  const StickerConfig({
    this.logoPosition = LogoPosition.center,
    this.logoBackground = LogoBackground.none,
    this.topText,
    this.bottomText,
    this.logoType,
    this.logoAssetId,
    this.logoImageBytes,
    this.logoText,
    this.logoAssetPngBytes,
    this.logoBackgroundColor,
  });

  /// copyWith — sentinel 기반으로 명시적 null 설정 허용
  StickerConfig copyWith({
    LogoPosition? logoPosition,
    LogoBackground? logoBackground,
    Object? topText = _stickerSentinel,
    Object? bottomText = _stickerSentinel,
    Object? logoType = _stickerSentinel,
    Object? logoAssetId = _stickerSentinel,
    Object? logoImageBytes = _stickerSentinel,
    Object? logoText = _stickerSentinel,
    Object? logoAssetPngBytes = _stickerSentinel,
    Object? logoBackgroundColor = _stickerSentinel,
  }) => StickerConfig(
    logoPosition: logoPosition ?? this.logoPosition,
    logoBackground: logoBackground ?? this.logoBackground,
    topText: topText == _stickerSentinel ? this.topText : topText as StickerText?,
    bottomText: bottomText == _stickerSentinel ? this.bottomText : bottomText as StickerText?,
    logoType: logoType == _stickerSentinel ? this.logoType : logoType as LogoType?,
    logoAssetId: logoAssetId == _stickerSentinel ? this.logoAssetId : logoAssetId as String?,
    logoImageBytes: logoImageBytes == _stickerSentinel ? this.logoImageBytes : logoImageBytes as Uint8List?,
    logoText: logoText == _stickerSentinel ? this.logoText : logoText as StickerText?,
    logoAssetPngBytes: logoAssetPngBytes == _stickerSentinel ? this.logoAssetPngBytes : logoAssetPngBytes as Uint8List?,
    logoBackgroundColor: logoBackgroundColor == _stickerSentinel ? this.logoBackgroundColor : logoBackgroundColor as Color?,
  );
}
```

### 3.2 QrResultNotifier 신규 메서드

**위치**: `lib/features/qr_result/qr_result_provider.dart`

```dart
// 드롭다운 타입 변경 (편집기 전환)
void setLogoType(LogoType? type) {
  state = state.copyWith(sticker: state.sticker.copyWith(logoType: type));
}

// 로고 라이브러리 선택
Future<void> applyLogoLibrary(LogoSourceLibrary src, Uint8List pngBytes) async {
  state = state.copyWith(
    sticker: state.sticker.copyWith(
      logoType: LogoType.logo,
      logoAssetId: src.assetId,
      logoAssetPngBytes: pngBytes,
    ),
  );
}

// 이미지 크롭 적용
void applyLogoImage(LogoSourceImage src) {
  state = state.copyWith(
    sticker: state.sticker.copyWith(
      logoType: LogoType.image,
      logoImageBytes: src.croppedBytes,
    ),
  );
}

// 텍스트 로고 적용
void applyLogoText(StickerText text) {
  state = state.copyWith(
    sticker: state.sticker.copyWith(
      logoType: LogoType.text,
      logoText: text,
    ),
  );
}

// 배경 테두리 색상
void setLogoBackgroundBorderColor(Color? color) {
  state = state.copyWith(
    sticker: state.sticker.copyWith(logoBackgroundColor: color),
  );
}
```

### 3.3 QrCustomization (영속) 필드

**위치**: `lib/features/qr_task/domain/entities/qr_customization.dart`

추가 필드(JSON 키):
```json
{
  "logoType": "logo" | "image" | "text" | null,
  "logoAssetId": "social/twitter" | null,
  "logoImageBase64": "<256x256 JPEG base64>" | null,
  "logoText": { "content": "...", "color": 0xFF000000, "fontFamily": "sans-serif", "fontSize": 20 } | null,
  "logoBackgroundColor": 0xFF0066CC | null
}
```

### 3.4 customization_mapper 양방향 매핑

**위치**: `lib/features/qr_result/utils/customization_mapper.dart`

```dart
// state → customization (저장)
QrCustomization toCustomization(QrResultState s) {
  return QrCustomization(
    // ... 기존 필드
    logoType: s.sticker.logoType?.name,
    logoAssetId: s.sticker.logoAssetId,
    logoImageBase64: s.sticker.logoImageBytes != null
        ? base64Encode(s.sticker.logoImageBytes!) : null,
    logoText: s.sticker.logoText != null ? _encodeLogoText(s.sticker.logoText!) : null,
    logoBackgroundColor: s.sticker.logoBackgroundColor?.toARGB32(),
  );
}

// customization → state (로드, 레거시 호환)
QrResultState fromCustomization(QrCustomization c) {
  // 신규 필드가 모두 null이면 기존 로직 유지 (logoType=null)
  final logoType = c.logoType != null
      ? LogoType.values.byName(c.logoType!) : null;
  // ...
}
```

### 3.5 UserQrTemplate (Hive)

**위치**: `lib/features/qr_result/domain/entities/user_qr_template.dart`
**Model**: `lib/features/qr_result/data/models/user_qr_template_model.dart`

Hive `@HiveField` 번호 신규 할당 (기존 필드 번호 유지, 새로 21 ~ 27 할당):

```dart
@HiveField(21) final String? logoType;
@HiveField(22) final String? logoAssetId;
@HiveField(23) final Uint8List? logoImageBytes;
@HiveField(24) final String? logoTextContent;
@HiveField(25) final int? logoTextColorValue;
@HiveField(26) final String? logoTextFont;
@HiveField(27) final double? logoTextSize;
@HiveField(28) final int? logoBackgroundColorValue;
```

**build_runner 재실행 필요**: `dart run build_runner build --delete-conflicting-outputs`

---

## 4. 자산 구조 및 Manifest

### 4.1 디렉터리 구조

```
assets/logos/
├── manifest.json
├── social/
│   ├── twitter.svg    instagram.svg    facebook.svg
│   ├── tiktok.svg     youtube.svg      linkedin.svg
│   ├── github.svg     discord.svg      whatsapp.svg
│   └── telegram.svg   (10개)
├── coin/
│   ├── btc.svg        eth.svg          sol.svg
│   ├── xrp.svg        ada.svg          doge.svg
│   ├── usdt.svg       bnb.svg          (8개)
├── brand/
│   ├── apple.svg      android.svg      google.svg
│   ├── microsoft.svg  amazon.svg       paypal.svg
│   ├── visa.svg       mastercard.svg   (8개)
└── emoji/
    ├── smile.svg      heart.svg        star.svg
    ├── fire.svg       check.svg        warning.svg
    ├── info.svg       celebrate.svg    cake.svg
    ├── gift.svg       rocket.svg       leaf.svg
    ├── sun.svg        moon.svg         music.svg
    ├── camera.svg     phone.svg        mail.svg
    ├── home.svg       bookmark.svg     (20개)
```

**총: 4카테고리, 46 아이콘** (성공 기준 #6 충족: ≥4 / ≥40)

### 4.2 manifest.json 스키마

```json
{
  "version": 1,
  "categories": [
    {
      "id": "social",
      "name_ko": "소셜",
      "icons": [
        { "id": "twitter",   "file": "twitter.svg" },
        { "id": "instagram", "file": "instagram.svg" }
      ]
    }
  ]
}
```

### 4.3 pubspec.yaml 변경

```yaml
dependencies:
  flutter_svg: ^2.0.10+1    # 신규

flutter:
  assets:
    - assets/logos/manifest.json
    - assets/logos/social/
    - assets/logos/coin/
    - assets/logos/brand/
    - assets/logos/emoji/
```

---

## 5. 렌더링 통합 (qr_layer_stack.dart)

### 5.1 변경 전 로고 배경 switch

```dart
switch (sticker.logoBackground) {
  case LogoBackground.none:
    return SizedBox(width: iconSize, height: iconSize, child: imgWidget);
  case LogoBackground.square:
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      ...
    );
  case LogoBackground.circle:
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      ...
    );
}
```

### 5.2 변경 후 (배경 테두리 추가)

```dart
Widget _buildLogoBackground(Widget child, LogoBackground bg, Color? borderColor, double iconSize) {
  final border = borderColor != null
      ? Border.all(color: borderColor, width: 1.5)
      : null;
  switch (bg) {
    case LogoBackground.none:
      return SizedBox(width: iconSize, height: iconSize, child: child);
    case LogoBackground.square:
      return Container(
        width: iconSize + 8,
        height: iconSize + 8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: border,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        padding: const EdgeInsets.all(4),
        child: child,
      );
    case LogoBackground.circle:
      return Container(
        width: iconSize + 8,
        height: iconSize + 8,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: border,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        padding: const EdgeInsets.all(4),
        child: child,
      );
  }
}
```

### 5.3 텍스트 로고 렌더링

**미리보기 경로**: Widget 오버레이 (탭·미리보기 성능 우선)
```dart
// LogoType.text → Image 대신 Text 위젯
if (sticker.logoType == LogoType.text && sticker.logoText != null) {
  final t = sticker.logoText!;
  logoContent = SizedBox(
    width: iconSize, height: iconSize,
    child: Center(child: Text(
      t.content,
      style: TextStyle(color: t.color, fontFamily: t.fontFamily, fontSize: t.fontSize),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    )),
  );
}
```

**저장/공유 경로**: RepaintBoundary 캡처가 위젯 트리를 그대로 렌더 → 자연스럽게 Canvas 변환됨.
RasterizeTextLogoUseCase 는 백엔드/이미지 처리에서 별도 PNG가 필요할 때 사용 (옵션).

### 5.4 아이콘 소스 해석 (centerImageProvider 변경)

```dart
// qr_preview_section.dart
ImageProvider? centerImageProvider(QrResultState state) {
  if (!state.embedIcon) return null;
  final sticker = state.sticker;
  switch (sticker.logoType) {
    case LogoType.text:   return null;   // Widget 오버레이
    case LogoType.image:  return sticker.logoImageBytes != null ? MemoryImage(sticker.logoImageBytes!) : null;
    case LogoType.logo:   return sticker.logoAssetPngBytes != null ? MemoryImage(sticker.logoAssetPngBytes!) : null;
    case null:
      // 레거시 경로 (기존 저장 QR 호환)
      if (state.templateCenterIconBytes != null) return MemoryImage(state.templateCenterIconBytes!);
      if (state.emojiIconBytes != null) return MemoryImage(state.emojiIconBytes!);
      if (state.defaultIconBytes != null) return MemoryImage(state.defaultIconBytes!);
      return null;
  }
}
```

---

## 6. 상호작용 플로우

### 6.1 로고 라이브러리 선택

```
사용자 → LogoLibraryEditor
  → 카테고리 칩 탭  → setState(selectedCategoryId)
  → 아이콘 타일 탭
     → ref.read(selectLogoAssetUseCaseProvider).call(category, iconId)
        → 1) LogoManifestRepository.load() (캐시)
        → 2) LogoManifestRepository.rasterize(compositeId) → Uint8List
        → 3) (LogoSourceLibrary, pngBytes) 반환
     → notifier.applyLogoLibrary(src, pngBytes)
     → state.sticker.{logoType=logo, logoAssetId, logoAssetPngBytes} 업데이트
     → QrLayerStack rebuild → centerImageProvider 반영
     → onChanged() → _recapture() (QrResultScreen에서)
```

### 6.2 이미지 선택 + 크롭

```
사용자 → LogoImageEditor → [갤러리에서 선택]
  → ref.read(cropLogoImageUseCaseProvider).call(ctx: context)
     → ImagePicker().pickImage(source: gallery, maxWidth: 1024)
     → ImageCropper().cropImage(
          sourcePath, aspectRatio: 1:1, cropStyle: rectangle,
          uiSettings: [AndroidUiSettings(...), IOSUiSettings(...)]
        )
     → package:image로 재인코딩 (256×256 JPEG Q85)
     → LogoSourceImage(croppedBytes) 반환 (취소 시 null)
  → notifier.applyLogoImage(src)
  → state.sticker.{logoType=image, logoImageBytes} 업데이트
  → LogoImageEditor 리빌드 → 썸네일 갱신
```

### 6.3 텍스트 로고 편집

```
사용자 → LogoTextEditor → TextField onChanged (debounce 200ms)
  → notifier.applyLogoText(StickerText(content, color, fontFamily, fontSize))
  → state.sticker.{logoType=text, logoText} 업데이트
  → QrLayerStack rebuild → Text 위젯 오버레이로 렌더
```

### 6.4 배경 테두리 색상

```
사용자 → 배경 테두리 섹션 → 색상 원형 버튼 탭
  → showDialog(ColorPicker)
  → 확인 → notifier.setLogoBackgroundBorderColor(color)
  → qr_layer_stack _buildLogoBackground 리빌드 → Border.all 적용

[없음] 버튼 → notifier.setLogoBackgroundBorderColor(null) → Border 제거
배경이 none으로 변경 시 → 테두리 섹션 disabled (색상값은 유지)
```

### 6.5 타입 전환 시 데이터 보존

```
드롭다운 변경 (예: image → text)
  → notifier.setLogoType(LogoType.text)
  → logoType만 갱신, logoImageBytes/logoAssetId/logoText 는 그대로 유지
  → 다시 image로 돌아오면 이전 이미지 복원
  ※ 렌더링은 현재 logoType 기준 1개 소스만 사용
```

---

## 7. 국제화 (l10n)

11개 로케일(app_ko/en/ja/zh/es/fr/de/pt/vi/th/th) 각각에 신규 키 추가:

| 키 | 한국어 | 영어 (예) |
|---|--------|----------|
| `labelLogoTabShow` | 표시 | Show |
| `optionLogoTypeLogo` | 로고 | Logo |
| `optionLogoTypeImage` | 이미지 | Image |
| `optionLogoTypeText` | 텍스트 | Text |
| `labelLogoTabPosition` | 위치 | Position |
| `labelLogoTabBackground` | 배경 | Background |
| `labelLogoBackgroundBorder` | 배경 테두리 | Background Border |
| `hintLogoBackgroundBorderDisabled` | 배경을 선택하면 활성화됩니다 | Select a background to enable |
| `actionLogoBorderNone` | 없음 | None |
| `labelLogoCategory` | 카테고리 | Category |
| `labelLogoGallery` | 갤러리에서 선택 | Choose from gallery |
| `labelLogoRecrop` | 다시 자르기 | Re-crop |
| `labelLogoTextContent` | 문구 | Text |
| `hintLogoTextContent` | 로고에 넣을 글자 | Text for logo |
| `categorySocial` | 소셜 | Social |
| `categoryCoin` | 코인 | Coin |
| `categoryBrand` | 브랜드 | Brand |
| `categoryEmoji` | 이모지 | Emoji |

---

## 8. 변경 파일 요약

| 파일 | 유형 | 변경 |
|------|------|------|
| `lib/features/qr_result/domain/entities/logo_source.dart` | **신규** | sealed class + LogoType enum + mapping |
| `lib/features/qr_result/domain/entities/logo_manifest.dart` | **신규** | LogoManifest, LogoCategory, LogoAsset |
| `lib/features/qr_result/domain/repositories/logo_manifest_repository.dart` | **신규** | Repository 인터페이스 |
| `lib/features/qr_result/domain/usecases/select_logo_asset_usecase.dart` | **신규** | use case |
| `lib/features/qr_result/domain/usecases/crop_logo_image_usecase.dart` | **신규** | use case |
| `lib/features/qr_result/domain/usecases/rasterize_text_logo_usecase.dart` | **신규** | use case (옵션) |
| `lib/features/qr_result/data/repositories/logo_manifest_repository_impl.dart` | **신규** | SVG 래스터화 + LRU 캐시 |
| `lib/features/qr_result/tabs/logo_editors/logo_library_editor.dart` | **신규** | 카테고리 + 그리드 |
| `lib/features/qr_result/tabs/logo_editors/logo_image_editor.dart` | **신규** | 썸네일 + 크롭 버튼 |
| `lib/features/qr_result/tabs/logo_editors/logo_text_editor.dart` | **신규** | 문구/색/폰트/크기 |
| `lib/features/qr_result/tabs/sticker_tab.dart` | 재작성 | 오케스트레이터 (토글+드롭다운+공통설정+편집기 스위칭) |
| `lib/features/qr_result/domain/entities/sticker_config.dart` | 확장 | LogoType + 6필드 + copyWith sentinel |
| `lib/features/qr_result/qr_result_provider.dart` | 확장 | 신규 notifier 메서드 × 5 |
| `lib/features/qr_result/widgets/qr_layer_stack.dart` | 확장 | _buildLogoBackground (border) + 텍스트 오버레이 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | 확장 | centerImageProvider 분기 |
| `lib/features/qr_result/utils/customization_mapper.dart` | 확장 | 5개 필드 양방향 매핑 |
| `lib/features/qr_result/presentation/providers/qr_result_providers.dart` | 확장 | 4개 provider 추가 |
| `lib/features/qr_task/domain/entities/qr_customization.dart` | 확장 | 5개 필드 추가 |
| `lib/features/qr_result/domain/entities/user_qr_template.dart` | 확장 | 8개 Hive 필드 |
| `lib/features/qr_result/data/models/user_qr_template_model.dart` | 확장 | @HiveField 21~28 |
| `lib/features/qr_result/data/models/user_qr_template_model.g.dart` | **자동생성** | build_runner |
| `pubspec.yaml` | 확장 | flutter_svg 의존성 + assets/logos/* 등록 |
| `assets/logos/manifest.json` | **신규** | 카테고리·아이콘 메타 |
| `assets/logos/{4 categories}/*.svg` | **신규** | 46개 SVG 파일 |
| `lib/l10n/app_*.arb` (11개) | 확장 | 18개 신규 키 |

**총계**: 신규 10파일 + 자산 47파일 + 기존 확장 13파일

---

## 9. 구현 순서 (do 단계에서 사용)

1. **P0 — 도메인 + Repository 골격** (1~2h)
   - logo_source.dart, logo_manifest.dart
   - logo_manifest_repository.dart (인터페이스)
   - 3개 use case 시그니처 + DI provider
2. **P1 — StickerConfig 확장 + Notifier 메서드** (1h)
   - LogoType enum + 6필드 추가, copyWith 갱신
   - QrResultNotifier: setLogoType/applyLogoLibrary/applyLogoImage/applyLogoText/setLogoBackgroundBorderColor
3. **P2 — flutter_svg 의존성 + 자산 번들** (30min + 자산 준비)
   - pubspec.yaml flutter_svg 추가 + assets/logos/* 등록
   - manifest.json + SVG 46개 (임시 자산으로 진행 가능)
   - `dart run build_runner build` (Hive 필드 추가는 P5에서)
4. **P3 — LogoManifestRepositoryImpl** (2h)
   - manifest.json 파싱
   - SVG → PNG 래스터화 (flutter_svg vg.loadPicture + Canvas)
   - LRU 캐시 (32개 제한)
5. **P4 — 3개 편집기 위젯** (3~4h 순차)
   - LogoLibraryEditor (FutureBuilder + Grid)
   - LogoImageEditor (썸네일 + image_cropper 호출)
   - LogoTextEditor (_TextEditor 패턴 참조)
6. **P5 — StickerTab 재작성** (2h)
   - Row 1 토글+드롭다운, Row 2 공통 설정, Row 3 테두리, Row 4 편집기 스위치
   - IndexedStack으로 편집기 상태 보존
7. **P6 — qr_layer_stack 렌더링** (1h)
   - _buildLogoBackground(borderColor) 교체
   - 텍스트 로고 Widget 오버레이 경로
   - centerImageProvider logoType 분기
8. **P7 — 영속화 매핑** (1~2h)
   - customization_mapper 양방향
   - Hive 필드 8개 추가 + build_runner 재실행
   - 기존 저장 QR 로드 회귀 테스트 (logoType=null 경로)
9. **P8 — i18n + 정리** (1h)
   - 11개 .arb 에 18개 키 추가
   - flutter gen-l10n
   - 추가 Hint/Semantics 라벨

**예상 총 소요**: ~14시간 (1.5~2일)

---

## 10. 테스트 전략

### 10.1 Unit (Repository + UseCase)
- `LogoManifestRepositoryImpl.load()` — 정상 / 불완전 JSON / 파일 없음
- `LogoManifestRepositoryImpl.rasterize()` — 캐시 hit/miss / 비존재 id
- `SelectLogoAssetUseCase` — 성공 / repo 실패 전파
- `CropLogoImageUseCase` — ImagePicker mock (취소/선택), ImageCropper mock

### 10.2 Widget
- `LogoLibraryEditor` — manifest loading/error/data 3상태, 선택 하이라이트
- `LogoImageEditor` — 빈 상태 / 이미지 로드됨 상태 / "다시 자르기" 보이기
- `LogoTextEditor` — maxLength 6 강제, 색상 버튼 → dialog 오픈, 스텝퍼 10~40 clamp
- `StickerTab` — 토글 ON/OFF + 드롭다운 enable, 텍스트 타입 시 배경·테두리 숨김

### 10.3 Golden / Integration (선택)
- `qr_layer_stack` — square+테두리 파랑 / circle+테두리 빨강 / text 오버레이 3개 Golden
- 기존 저장 QR 파일 로드 → 레거시 경로 렌더 회귀 테스트

### 10.4 회귀 체크리스트 (Check 단계)
- [ ] 기존 저장 QrTask 로드 시 `logoType=null` 로 정상 렌더
- [ ] 기존 `UserQrTemplate` 로드 시 `logoType=null` 경로 확인
- [ ] 신규 템플릿 저장 시 모든 신규 필드 직렬화
- [ ] 드롭다운 전환 시 이전 타입 데이터 보존
- [ ] 크롭 후 JSON 크기 ≤ 50KB (성공 기준 #4)
- [ ] 11개 로케일 번역 키 누락 없음

---

## 11. 위험 + 완화

| 위험 | 완화 |
|------|------|
| SVG → PNG 래스터화 Android/iOS 렌더링 차이 | rasterize 시 size를 logical pixel로 통일, 테스트 기기 2종 이상 검증. 문제 시 PNG 폴백(동일 경로에 .png 배치, SVG 없으면 .png 우선) |
| `flutter_svg` 버전 호환성 | 현재 최신 안정 2.0.x, pubspec에 `^2.0.10+1` 고정 |
| Hive 필드 21~28 번호 충돌 | build_runner 실행 전 `user_qr_template_model.dart`의 기존 최대 HiveField 번호 확인 후 +1부터 할당 |
| image_cropper 네이티브 권한 (iOS Info.plist) | `NSPhotoLibraryUsageDescription` 존재 여부 확인 (`ios/Runner/Info.plist`에 이미 있는지 검증, 없으면 추가) |
| 텍스트 로고 위젯 오버레이 vs 캡처 일관성 | RepaintBoundary 캡처는 Widget tree 그대로이므로 자연 일관. 별도 래스터화는 use case로 유지하되 Phase 2에서 필요 시 활성 |
| 자산 크기 증가 (SVG 46개) | SVG는 각 ~1KB 내외 → 총 ~50KB 증가. simplify (SVGO 최적화) 적용 |
| 레거시 fromCustomization 누락 | 모든 신규 필드는 nullable, null-safe 기본 경로 추가 + 단위 테스트로 고정 |

---

## 12. 성공 기준 추적

| Plan 성공 기준 | Design 반영 |
|---------------|-------------|
| #1 3가지 타입 드롭다운 전환 | StickerTab Row1 + IndexedStack (1.2) |
| #2 500ms 이내 미리보기 반영 | Riverpod 리빌드 + LRU 캐시 (2.5) + _recapture 기존 경로 |
| #3 기존 QR 회귀 없음 | logoType=null 레거시 경로 (5.4, 3.4) + 회귀 체크리스트 (10.4) |
| #4 JSON 저장 ≤ 50KB | 256×256 JPEG Q85 고정 (CropLogoImageUseCase) |
| #5 11개 로케일 번역 | 18개 키 (§7) |
| #6 카테고리 ≥4, 아이콘 ≥40 | 4카테고리 × 46아이콘 (§4.1) |
| #7 배경 테두리 색상 설정·해제·미리보기 반영 | §5.2 Border.all + §6.4 플로우 + §10.4 회귀 |
