# Design — SVG Logo Embed (SVG 로고 벡터 임베딩 + 에셋 관리 시스템)

> 생성일: 2026-04-24
> Feature ID: `svg-logo-embed`
> Plan: `docs/01-plan/features/svg-logo-embed.plan.md`

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | SVG 저장 시 중앙 로고/텍스트 누락 + 번들 에셋 46개가 앱 빌드에 묶여 추가/수정 시 앱 업데이트 필요 |
| **Solution** | QrSvgGenerator에 3종 로고 임베딩 + Supabase 기반 원격 에셋 동기화 |
| **Function UX Effect** | SVG 출력 완성도 100% + 앱 업데이트 없이 로고 추가/삭제 |
| **Core Value** | 벡터 품질 보존 + 에셋 운영 자율성 |

---

## 1. Architecture

### 1.1 디렉터리 구조

기존 `qr_result` feature 내 확장 + 신규 `logo_sync` feature 추가.

```
lib/features/qr_result/
├── domain/
│   └── entities/
│       └── svg_logo_params.dart          # 신규 — SVG 로고 임베딩 VO
├── utils/
│   ├── qr_svg_generator.dart             # 수정 — 로고/텍스트/이미지 렌더링 추가
│   └── svg_asset_loader.dart             # 신규 — compositeId → SVG 문자열 로드
├── domain/
│   └── repositories/
│       └── logo_manifest_repository.dart # 수정 — loadSvgContent() 추가

lib/features/logo_sync/                   # 신규 feature (Part B)
├── domain/
│   ├── entities/
│   │   └── remote_logo_asset.dart        # 신규 — Supabase logo_assets 행 표현
│   └── repositories/
│       └── logo_sync_repository.dart     # 신규 — 동기화 인터페이스
├── data/
│   ├── datasources/
│   │   ├── supabase_logo_datasource.dart # 신규 — Supabase REST 호출
│   │   └── logo_cache_datasource.dart    # 신규 — 로컬 파일 캐시
│   └── repositories/
│       └── logo_sync_repository_impl.dart# 신규 — 동기화 구현
└── presentation/
    └── providers/
        └── logo_sync_providers.dart      # 신규 — Riverpod providers
```

### 1.2 데이터 흐름도

```
[홈 갤러리 _saveAsSvg]
  │
  ├─ QrTask.customization.sticker → StickerSpec
  │    ├─ logoType: "logo" → logoAssetId → SvgAssetLoader.load() → SVG 문자열
  │    ├─ logoType: "text" → logoText (StickerTextSpec) → SvgLogoText VO
  │    ├─ logoType: "image" → centerIconBase64 → Base64 PNG
  │    └─ logoType: null/"none" → 로고 없음
  │
  ├─ QrSvgGenerator.generate(
  │    ..., logoSvgContent?, logoBase64Png?,
  │    logoText?, logoStyle?, topText?, bottomText?)
  │
  └─ SVG 문자열 → saveQrAsSvgUseCase → 파일 저장

[앱 시작 — LogoSyncService]
  │
  ├─ Supabase logo_assets 쿼리 (is_active=true)
  ├─ 로컬 캐시 updated_at 비교 → delta sync
  ├─ SVG 문자열 파일 캐시 저장
  └─ LogoManifest 재구성 → logoManifestProvider 갱신
```

---

## 2. 상세 설계

### 2.1 신규 Value Object: `svg_logo_params.dart`

```dart
/// SVG 로고 임베딩 스타일 (위치, 배경, 크기).
/// QrSvgGenerator 전용 — presentation 레이어 StickerConfig 와 독립.
class SvgLogoStyle {
  /// QR 전체 크기 대비 로고 비율 (기본 0.22 — _LogoWidget 동일).
  final double sizeRatio;

  /// 'center' | 'bottomRight'
  final String position;

  /// 'none' | 'square' | 'circle' | 'rectangle' | 'roundedRectangle'
  final String background;

  /// 배경 fill 색상 ARGB. null = 흰색 (0xFFFFFFFF).
  final int? backgroundColorArgb;

  const SvgLogoStyle({
    this.sizeRatio = 0.22,
    this.position = 'center',
    this.background = 'none',
    this.backgroundColorArgb,
  });
}

/// SVG 텍스트 로고 정보 (LogoType.text 용).
class SvgLogoText {
  final String content;
  final int colorArgb;
  final String fontFamily;
  final double fontSize;

  const SvgLogoText({
    required this.content,
    this.colorArgb = 0xFF000000,
    this.fontFamily = 'sans-serif',
    this.fontSize = 14,
  });
}

/// SVG 스티커 텍스트 (상단/하단).
class SvgStickerText {
  final String content;
  final int colorArgb;
  final String fontFamily;
  final double fontSize;

  const SvgStickerText({
    required this.content,
    this.colorArgb = 0xFF000000,
    this.fontFamily = 'sans-serif',
    this.fontSize = 14,
  });
}
```

### 2.2 QrSvgGenerator 확장 시그니처

```dart
static String generate({
  // ── 기존 파라미터 (변경 없음) ──
  required String data,
  int ecLevel = 2,
  DotShapeParams dotParams = const DotShapeParams(),
  EyeShapeParams eyeParams = const EyeShapeParams(),
  QrBoundaryParams boundaryParams = const QrBoundaryParams(),
  int colorArgb = 0xFF000000,
  QrGradientData? gradient,
  double cellSize = 10.0,

  // ── 신규: 로고 임베딩 ──
  String? logoSvgContent,       // LogoType.logo: SVG 문자열 (인라인)
  String? logoBase64Png,        // LogoType.image: PNG Base64 문자열
  SvgLogoText? logoText,        // LogoType.text: 텍스트 정보
  SvgLogoStyle? logoStyle,      // 공통 스타일 (위치/배경/크기)

  // ── 신규: 상/하단 텍스트 ──
  SvgStickerText? topText,
  SvgStickerText? bottomText,
})
```

### 2.3 SVG 렌더링 로직 상세

#### 2.3.1 viewBox 확장 (상/하단 텍스트)

```
topText 존재 시:    viewBox Y offset -= textHeight
bottomText 존재 시: viewBox height += textHeight
textHeight = fontSize * 1.6 (line-height + padding)

viewBox="0 -{topH} {totalSize} {totalSize + topH + bottomH}"
```

#### 2.3.2 로고 배치 좌표 계산

```dart
// logoStyle.position == 'center'
final logoSize = totalSize * logoStyle.sizeRatio;  // 기본 22%
final logoX = (totalSize - logoSize) / 2;
final logoY = (totalSize - logoSize) / 2;

// logoStyle.position == 'bottomRight'
final logoX = totalSize - logoSize - padding;
final logoY = totalSize - logoSize - padding;
```

#### 2.3.3 로고 배경 SVG 렌더링

```dart
String _buildLogoBackground(
  double x, double y, double size,
  SvgLogoStyle style,
) {
  final bgColor = _colorHex(style.backgroundColorArgb ?? 0xFFFFFFFF);
  final pad = size * 0.1;  // 배경 패딩
  return switch (style.background) {
    'none'     => '',
    'circle'   => '<circle cx="${x+size/2}" cy="${y+size/2}" r="${size/2+pad}" fill="$bgColor"/>',
    'square'   => '<rect x="${x-pad}" y="${y-pad}" width="${size+pad*2}" height="${size+pad*2}" rx="4" fill="$bgColor"/>',
    'roundedRectangle' => '<rect x="${x-pad}" y="${y-pad}" width="${size+pad*2}" height="${size+pad*2}" rx="10" fill="$bgColor"/>',
    'rectangle'=> '<rect x="${x-pad}" y="${y-pad}" width="${size+pad*2}" height="${size+pad*2}" rx="2" fill="$bgColor"/>',
    _          => '',
  };
}
```

#### 2.3.4 LogoType.logo — SVG 인라인 임베딩

```dart
// 1. SVG 문자열에서 viewBox 파싱
final viewBox = _parseViewBox(logoSvgContent);  // [minX, minY, w, h]
// 폴백: viewBox 없으면 [0, 0, 96, 96]

// 2. scale 계산
final scaleX = logoSize / viewBox[2];
final scaleY = logoSize / viewBox[3];
final scale = min(scaleX, scaleY);

// 3. SVG 내용 중 <svg ...> 태그 제거, 내부 요소만 추출
final innerContent = _extractSvgInner(logoSvgContent);

// 4. <g> 래핑 + transform
buf.writeln('  <g transform="translate($logoX,$logoY) scale($scale)">');
buf.writeln('    $innerContent');
buf.writeln('  </g>');
```

**viewBox 파싱 정규식:**
```dart
static List<double> _parseViewBox(String svg) {
  final match = RegExp(r'viewBox="([^"]+)"').firstMatch(svg);
  if (match == null) return [0, 0, 96, 96];
  final parts = match.group(1)!.trim().split(RegExp(r'[\s,]+'));
  if (parts.length < 4) return [0, 0, 96, 96];
  return parts.map(double.parse).toList();
}
```

**SVG 내부 요소 추출:**
```dart
static String _extractSvgInner(String svg) {
  // <?xml ...?> 제거
  var s = svg.replaceAll(RegExp(r'<\?xml[^?]*\?>'), '');
  // <svg ...> 여는 태그 제거
  s = s.replaceFirst(RegExp(r'<svg[^>]*>'), '');
  // </svg> 닫는 태그 제거
  s = s.replaceFirst(RegExp(r'</svg>\s*$'), '');
  return s.trim();
}
```

**id 충돌 방지:**
```dart
// SVG 내부 id 속성에 접두사 추가 (선택적, 복수 로고 임베딩 시 필요)
innerContent = innerContent.replaceAllMapped(
  RegExp(r'id="([^"]+)"'),
  (m) => 'id="logo-${m.group(1)}"',
);
// url(#...) 참조도 동시 치환
innerContent = innerContent.replaceAllMapped(
  RegExp(r'url\(#([^)]+)\)'),
  (m) => 'url(#logo-${m.group(1)})',
);
```

#### 2.3.5 LogoType.text — SVG `<text>` 임베딩

```dart
// 배경 렌더링 후
buf.writeln('  <text'
  ' x="${logoX + logoSize / 2}"'
  ' y="${logoY + logoSize / 2}"'
  ' text-anchor="middle"'
  ' dominant-baseline="central"'
  ' font-family="${logoText.fontFamily}"'
  ' font-size="${logoText.fontSize}"'
  ' font-weight="600"'
  ' fill="${_colorHex(logoText.colorArgb)}"'
  '>${_escapeXml(logoText.content)}</text>');
```

#### 2.3.6 LogoType.image — Base64 `<image>` 임베딩

```dart
// 배경 렌더링 후
buf.writeln('  <image'
  ' href="data:image/png;base64,$logoBase64Png"'
  ' x="$logoX" y="$logoY"'
  ' width="$logoSize" height="$logoSize"'
  ' preserveAspectRatio="xMidYMid meet"/>');
```

#### 2.3.7 상/하단 스티커 텍스트

```dart
// topText — viewBox 상단 확장 영역에 배치
if (topText != null) {
  final ty = -topTextHeight / 2;  // viewBox 음수 영역 중앙
  buf.writeln('  <text'
    ' x="${totalSize / 2}" y="$ty"'
    ' text-anchor="middle" dominant-baseline="central"'
    ' font-family="${topText.fontFamily}"'
    ' font-size="${topText.fontSize}"'
    ' font-weight="600"'
    ' fill="${_colorHex(topText.colorArgb)}"'
    '>${_escapeXml(topText.content)}</text>');
}

// bottomText — viewBox 하단 확장 영역에 배치
if (bottomText != null) {
  final by = totalSize + bottomTextHeight / 2;
  buf.writeln('  <text'
    ' x="${totalSize / 2}" y="$by"'
    ' text-anchor="middle" dominant-baseline="central"'
    ' font-family="${bottomText.fontFamily}"'
    ' font-size="${bottomText.fontSize}"'
    ' font-weight="600"'
    ' fill="${_colorHex(bottomText.colorArgb)}"'
    '>${_escapeXml(bottomText.content)}</text>');
}
```

#### 2.3.8 XML 이스케이프 헬퍼

```dart
static String _escapeXml(String text) {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}
```

### 2.4 SVG 에셋 로더: `svg_asset_loader.dart`

```dart
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// compositeId ("social/twitter") → SVG 문자열 로드.
/// 번들 에셋 우선, 캐시 폴백.
class SvgAssetLoader {
  final AssetBundle _bundle;
  final Map<String, String> _cache = {};

  SvgAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// compositeId → SVG 문자열 반환.
  /// 캐시 히트 시 즉시 반환, 미스 시 번들에서 로드.
  Future<String?> load(String compositeId) async {
    if (_cache.containsKey(compositeId)) return _cache[compositeId];
    final parts = compositeId.split('/');
    if (parts.length != 2) return null;
    final path = 'assets/logos/${parts[0]}/${parts[1]}.svg';
    try {
      final svg = await _bundle.loadString(path);
      _cache[compositeId] = svg;
      return svg;
    } catch (_) {
      return null;
    }
  }

  /// 외부 캐시(logo_sync)에서 SVG 문자열 직접 등록.
  void putCache(String compositeId, String svgContent) {
    _cache[compositeId] = svgContent;
  }
}
```

### 2.5 `_saveAsSvg` 호출부 수정 (`qr_task_action_sheet.dart`)

```dart
Future<void> _saveAsSvg(BuildContext context, WidgetRef ref) async {
  Navigator.pop(context);
  final l10n = AppLocalizations.of(context)!;
  if (task.meta.deepLink.isEmpty) {
    context.showSnack(l10n.msgNoThumbnail);
    return;
  }

  final c = task.customization;
  final s = c.sticker;  // StickerSpec

  // ── 기존 파라미터 (변경 없음) ──
  final dotParams = c.customDotParams != null
      ? DotShapeParams.fromJson(c.customDotParams!)
      : _dotStyleToParams(c.dotStyle);
  final eyeParams = c.customEyeParams != null
      ? EyeShapeParams.fromJson(c.customEyeParams!)
      : const EyeShapeParams();
  final boundaryParams = c.boundaryParams != null
      ? QrBoundaryParams.fromJson(c.boundaryParams!)
      : const QrBoundaryParams();

  // ── 신규: 로고 데이터 추출 ──
  String? logoSvgContent;
  String? logoBase64Png;
  SvgLogoText? logoText;
  SvgLogoStyle? logoStyle;

  if (c.embedIcon && s.logoType != null && s.logoType != 'none') {
    logoStyle = SvgLogoStyle(
      position: s.logoPosition,
      background: s.logoBackground,
      backgroundColorArgb: s.logoBackgroundColorArgb,
    );

    switch (s.logoType) {
      case 'logo':
        if (s.logoAssetId != null) {
          final loader = ref.read(svgAssetLoaderProvider);
          logoSvgContent = await loader.load(s.logoAssetId!);
        }
      case 'image':
        logoBase64Png = c.centerIconBase64;
      case 'text':
        if (s.logoText != null) {
          logoText = SvgLogoText(
            content: s.logoText!.content,
            colorArgb: s.logoText!.colorArgb,
            fontFamily: s.logoText!.fontFamily,
            fontSize: s.logoText!.fontSize,
          );
        }
    }
  }

  // ── 신규: 상/하단 텍스트 ──
  SvgStickerText? topText;
  SvgStickerText? bottomText;
  if (s.topText != null && s.topText!.content.isNotEmpty) {
    topText = SvgStickerText(
      content: s.topText!.content,
      colorArgb: s.topText!.colorArgb,
      fontFamily: s.topText!.fontFamily,
      fontSize: s.topText!.fontSize,
    );
  }
  if (s.bottomText != null && s.bottomText!.content.isNotEmpty) {
    bottomText = SvgStickerText(
      content: s.bottomText!.content,
      colorArgb: s.bottomText!.colorArgb,
      fontFamily: s.bottomText!.fontFamily,
      fontSize: s.bottomText!.fontSize,
    );
  }

  final svgString = QrSvgGenerator.generate(
    data: task.meta.deepLink,
    dotParams: dotParams,
    eyeParams: eyeParams,
    boundaryParams: boundaryParams,
    colorArgb: c.qrColorArgb,
    gradient: c.gradient,
    logoSvgContent: logoSvgContent,
    logoBase64Png: logoBase64Png,
    logoText: logoText,
    logoStyle: logoStyle,
    topText: topText,
    bottomText: bottomText,
  );

  final result = await ref.read(saveQrAsSvgUseCaseProvider)(svgString, task.name);
  if (!context.mounted) return;
  result.fold(
    (path) => context.showSnack(l10n.msgSvgSaved),
    (failure) => context.showSnack('SVG 저장 실패'),
  );
}
```

### 2.6 LogoManifestRepository 인터페이스 확장

```dart
abstract class LogoManifestRepository {
  Future<Result<LogoManifest>> load();
  Future<Result<Uint8List>> rasterize(String compositeId, {double size = 96});

  /// 신규: compositeId → SVG 문자열 로드 (인라인 임베딩용).
  Future<Result<String>> loadSvgContent(String compositeId);
}
```

`LogoManifestRepositoryImpl` 에서 기존 `_bundle.loadString()` 로직을 `loadSvgContent()` 으로 분리:

```dart
@override
Future<Result<String>> loadSvgContent(String compositeId) async {
  final manifestRes = await load();
  if (manifestRes is Err<LogoManifest>) return Err(manifestRes.failure);
  final manifest = (manifestRes as Success<LogoManifest>).value;
  final asset = manifest.findByCompositeId(compositeId);
  if (asset == null) {
    return Err(UnexpectedFailure('Logo asset not found: $compositeId'));
  }
  try {
    final svgStr = await _bundle.loadString(asset.assetPath);
    return Success(svgStr);
  } catch (e, st) {
    return Err(UnexpectedFailure('Failed to load SVG: $e', cause: e, stackTrace: st));
  }
}
```

---

## 3. Part B: 원격 에셋 관리 시스템

### 3.1 Supabase 테이블 스키마

```sql
-- Migration: 001_create_logo_assets.sql
CREATE TABLE logo_assets (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  category    text NOT NULL,
  icon_id     text NOT NULL,
  name_ko     text,
  name_en     text,
  tags        text[] DEFAULT '{}',
  storage_path text,           -- Supabase Storage 경로 (참고용)
  svg_content  text NOT NULL,  -- SVG 문자열 직접 저장
  is_active   boolean DEFAULT true,
  sort_order  int DEFAULT 0,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now(),
  UNIQUE(category, icon_id)
);

-- RLS
ALTER TABLE logo_assets ENABLE ROW LEVEL SECURITY;

-- 읽기: 모든 사용자 (anon key)
CREATE POLICY "logo_assets_read" ON logo_assets
  FOR SELECT USING (is_active = true);

-- 쓰기: service_role 만 (Supabase Dashboard 에서 직접 관리)
-- RLS 기본 deny → service_role 은 RLS 우회

-- 인덱스
CREATE INDEX idx_logo_assets_category ON logo_assets(category, sort_order);
CREATE INDEX idx_logo_assets_updated ON logo_assets(updated_at);

-- updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER logo_assets_updated_at
  BEFORE UPDATE ON logo_assets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### 3.2 엔티티: `remote_logo_asset.dart`

```dart
/// Supabase logo_assets 테이블 행의 도메인 표현.
class RemoteLogoAsset {
  final String id;
  final String category;
  final String iconId;
  final String? nameKo;
  final String? nameEn;
  final List<String> tags;
  final String svgContent;
  final int sortOrder;
  final DateTime updatedAt;

  const RemoteLogoAsset({
    required this.id,
    required this.category,
    required this.iconId,
    this.nameKo,
    this.nameEn,
    this.tags = const [],
    required this.svgContent,
    this.sortOrder = 0,
    required this.updatedAt,
  });

  String get compositeId => '$category/$iconId';

  factory RemoteLogoAsset.fromJson(Map<String, dynamic> json) =>
      RemoteLogoAsset(
        id: json['id'] as String,
        category: json['category'] as String,
        iconId: json['icon_id'] as String,
        nameKo: json['name_ko'] as String?,
        nameEn: json['name_en'] as String?,
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        svgContent: json['svg_content'] as String,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
```

### 3.3 동기화 리포지토리: `logo_sync_repository.dart`

```dart
abstract class LogoSyncRepository {
  /// Supabase에서 전체 활성 에셋 조회.
  Future<Result<List<RemoteLogoAsset>>> fetchAll();

  /// updated_at > [since] 인 에셋만 조회 (delta sync).
  Future<Result<List<RemoteLogoAsset>>> fetchUpdatedSince(DateTime since);

  /// 로컬 캐시에서 SVG 문자열 로드.
  Future<String?> loadCached(String compositeId);

  /// SVG 문자열을 로컬 캐시에 저장.
  Future<void> cacheAsset(RemoteLogoAsset asset);

  /// 로컬 캐시의 마지막 동기화 시각.
  DateTime? get lastSyncAt;
}
```

### 3.4 캐시 데이터소스: `logo_cache_datasource.dart`

```dart
/// 로컬 파일 기반 SVG 캐시.
/// 경로: {supportDir}/logo_cache/{category}/{iconId}.svg
class LogoCacheDatasource {
  final Directory _cacheDir;

  LogoCacheDatasource(this._cacheDir);

  File _file(String category, String iconId) =>
      File('${_cacheDir.path}/$category/$iconId.svg');

  Future<String?> read(String compositeId) async {
    final parts = compositeId.split('/');
    if (parts.length != 2) return null;
    final f = _file(parts[0], parts[1]);
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  Future<void> write(String compositeId, String svgContent) async {
    final parts = compositeId.split('/');
    if (parts.length != 2) return;
    final f = _file(parts[0], parts[1]);
    await f.parent.create(recursive: true);
    await f.writeAsString(svgContent);
  }

  Future<void> deleteAll() async {
    if (await _cacheDir.exists()) {
      await _cacheDir.delete(recursive: true);
    }
  }
}
```

### 3.5 Supabase 데이터소스: `supabase_logo_datasource.dart`

```dart
/// Supabase REST API 기반 logo_assets 조회.
/// supabase_flutter 패키지 사용.
class SupabaseLogoDatasource {
  final SupabaseClient _client;

  SupabaseLogoDatasource(this._client);

  Future<List<RemoteLogoAsset>> fetchActive() async {
    final res = await _client
        .from('logo_assets')
        .select()
        .eq('is_active', true)
        .order('category')
        .order('sort_order');
    return (res as List).map((e) =>
      RemoteLogoAsset.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RemoteLogoAsset>> fetchSince(DateTime since) async {
    final res = await _client
        .from('logo_assets')
        .select()
        .eq('is_active', true)
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
    return (res as List).map((e) =>
      RemoteLogoAsset.fromJson(e as Map<String, dynamic>)).toList();
  }
}
```

### 3.6 동기화 구현: `logo_sync_repository_impl.dart`

```dart
class LogoSyncRepositoryImpl implements LogoSyncRepository {
  final SupabaseLogoDatasource _remote;
  final LogoCacheDatasource _cache;
  final SvgAssetLoader _svgLoader;  // 캐시에 등록용

  DateTime? _lastSyncAt;

  LogoSyncRepositoryImpl(this._remote, this._cache, this._svgLoader);

  @override
  DateTime? get lastSyncAt => _lastSyncAt;

  @override
  Future<Result<List<RemoteLogoAsset>>> fetchAll() async {
    try {
      final assets = await _remote.fetchActive();
      for (final a in assets) {
        await cacheAsset(a);
      }
      _lastSyncAt = DateTime.now();
      return Success(assets);
    } catch (e, st) {
      return Err(UnexpectedFailure('Sync failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<List<RemoteLogoAsset>>> fetchUpdatedSince(DateTime since) async {
    try {
      final assets = await _remote.fetchSince(since);
      for (final a in assets) {
        await cacheAsset(a);
      }
      _lastSyncAt = DateTime.now();
      return Success(assets);
    } catch (e, st) {
      return Err(UnexpectedFailure('Delta sync failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<String?> loadCached(String compositeId) => _cache.read(compositeId);

  @override
  Future<void> cacheAsset(RemoteLogoAsset asset) async {
    await _cache.write(asset.compositeId, asset.svgContent);
    _svgLoader.putCache(asset.compositeId, asset.svgContent);
  }
}
```

### 3.7 LogoManifest 통합

앱 시작 시 동기화 후, 원격 에셋을 기존 `LogoManifest` 형식으로 변환하여 `logoManifestProvider` 에 주입:

```dart
LogoManifest remoteToManifest(List<RemoteLogoAsset> assets) {
  final grouped = <String, List<LogoAsset>>{};
  final categoryNames = <String, String>{};

  for (final a in assets) {
    grouped.putIfAbsent(a.category, () => []);
    grouped[a.category]!.add(LogoAsset(
      id: a.iconId,
      assetPath: '', // 원격이므로 번들 경로 없음. SVG는 캐시에서 로드.
    ));
    if (a.nameKo != null) categoryNames[a.category] = a.nameKo!;
  }

  return LogoManifest(
    grouped.entries.map((e) => LogoCategory(
      id: e.key,
      nameKo: categoryNames[e.key] ?? e.key,
      icons: e.value,
    )).toList(),
  );
}
```

### 3.8 검색 기능

`logo_library_editor.dart` 에 검색 TextField 추가:

```dart
// _LogoLibraryEditorState 에 추가
String _searchQuery = '';

// build() 내 카테고리 칩 위에:
TextField(
  decoration: InputDecoration(
    hintText: l10n.searchLogo,
    prefixIcon: const Icon(Icons.search, size: 20),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
  ),
  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
),

// 아이콘 필터링:
final filteredIcons = _searchQuery.isEmpty
    ? category.icons
    : category.icons.where((a) {
        final id = a.id.toLowerCase();
        return id.contains(_searchQuery);
        // Part B 원격 에셋 시: tags/name_ko 도 검색
      }).toList();
```

---

## 4. 구현 순서

### Phase 1: SVG 로고 임베딩 (Part A)

| Step | 파일 | 작업 | 예상 줄 |
|------|------|------|---------|
| 1 | `svg_logo_params.dart` (신규) | SvgLogoStyle, SvgLogoText, SvgStickerText VO | ~50 |
| 2 | `qr_svg_generator.dart` (수정) | 로고/텍스트/이미지/스티커텍스트 렌더링 추가 | +120 |
| 3 | `svg_asset_loader.dart` (신규) | compositeId → SVG 문자열 로드 + 캐시 | ~40 |
| 4 | `logo_manifest_repository.dart` (수정) | `loadSvgContent()` 인터페이스 추가 | +2 |
| 5 | `logo_manifest_repository_impl.dart` (수정) | `loadSvgContent()` 구현 | +15 |
| 6 | `qr_task_action_sheet.dart` (수정) | `_saveAsSvg` 로고 데이터 전달 | +40 |
| 7 | `qr_result_providers.dart` (수정) | `svgAssetLoaderProvider` 등록 | +5 |
| 8 | `app_ko.arb` (수정) | l10n 키 추가 | +2 |

### Phase 2: 원격 에셋 관리 (Part B)

| Step | 파일 | 작업 | 예상 줄 |
|------|------|------|---------|
| 1 | SQL migration | `logo_assets` 테이블 생성 | ~30 |
| 2 | `remote_logo_asset.dart` (신규) | 엔티티 | ~40 |
| 3 | `supabase_logo_datasource.dart` (신규) | REST 조회 | ~30 |
| 4 | `logo_cache_datasource.dart` (신규) | 파일 캐시 | ~40 |
| 5 | `logo_sync_repository.dart` (신규) | 인터페이스 | ~15 |
| 6 | `logo_sync_repository_impl.dart` (신규) | 동기화 구현 | ~60 |
| 7 | `logo_sync_providers.dart` (신규) | Riverpod providers | ~30 |
| 8 | `logo_library_editor.dart` (수정) | 검색 TextField + 필터링 | +20 |
| 9 | `app_ko.arb` (수정) | 검색 관련 l10n | +2 |

---

## 5. 기존 데이터 호환

- `QrCustomization.sticker.logoType == null` (레거시 QrTask): 로고 임베딩 건너뜀 → 기존 동작 유지
- `embedIcon == false`: 로고 없는 SVG 생성 → 기존 동작 유지
- Part B 동기화 실패 시: 번들 `assets/logos/` 폴백 → 기존 동작 유지
- `StickerSpec.logoImageBase64` → `QrCustomization.centerIconBase64` 양쪽에 PNG 데이터 존재 가능 → `centerIconBase64` 우선 사용

---

## 6. 에지 케이스

| Case | 처리 |
|------|------|
| SVG에 viewBox 없음 | 폴백 `[0,0,96,96]` |
| SVG에 네임스페이스 id 충돌 | `logo-` 접두사 자동 추가 |
| logoText 빈 문자열 | `isEmpty` 체크 → 렌더링 스킵 |
| centerIconBase64 null (LogoType.image) | 렌더링 스킵 |
| logoAssetId 에 해당하는 SVG 없음 (삭제됨) | `load()` 반환 null → 로고 없이 SVG 생성 |
| 오프라인 + 캐시 미스 + 번들에도 없음 | 로고 없이 SVG 생성 |
| 상/하단 텍스트에 XML 특수문자 (`<>&`) | `_escapeXml()` 처리 |
| logoStyle null (레거시 데이터) | 로고 렌더링 전체 스킵 |

---

## 7. 의존성

### 신규 패키지

| 패키지 | 용도 | Phase |
|--------|------|-------|
| `supabase_flutter` | Supabase REST 클라이언트 | Phase 2 (Part B) |
| `path_provider` | 캐시 디렉터리 | Phase 2 (이미 의존 중) |

### 기존 패키지 (변경 없음)

- `qr`, `flutter_svg`, `flutter_riverpod`, `go_router`, `hive`

---

_이 Design 은 Plan 문서의 FR-A01~A06, FR-B01~B05 를 구현 수준으로 상세화한 것입니다._
_R-series Provider 패턴 + Clean Architecture + l10n ko 선반영 규약 적용._
