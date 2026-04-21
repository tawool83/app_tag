import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/logo_manifest.dart';
import '../../domain/repositories/logo_manifest_repository.dart';

/// [LogoManifestRepository] 의 번들 자산 기반 구현.
///
/// - manifest.json 1회 로드 후 메모리 캐시
/// - SVG → PNG 래스터화 결과 LRU 캐시 (최대 32 항목)
class LogoManifestRepositoryImpl implements LogoManifestRepository {
  static const String manifestPath = 'assets/logos/manifest.json';
  static const int _pngCacheMax = 32;

  final AssetBundle _bundle;

  LogoManifest? _cachedManifest;
  // 간이 LRU: insertion order 가 곧 recency. access 시 재삽입.
  final Map<String, Uint8List> _pngCache = <String, Uint8List>{};

  LogoManifestRepositoryImpl({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  @override
  Future<Result<LogoManifest>> load() async {
    if (_cachedManifest != null) return Success(_cachedManifest!);
    try {
      final raw = await _bundle.loadString(manifestPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final manifest = _parseManifest(json);
      _cachedManifest = manifest;
      return Success(manifest);
    } catch (e, st) {
      return Err(UnexpectedFailure(
        'Failed to load logo manifest',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<Uint8List>> rasterize(
    String compositeId, {
    double size = 96,
  }) async {
    final cacheKey = '$compositeId@${size.toInt()}';
    final cached = _pngCache.remove(cacheKey);
    if (cached != null) {
      // LRU: 최근 접근이므로 재삽입
      _pngCache[cacheKey] = cached;
      return Success(cached);
    }

    // 1) manifest 확인
    final manifestRes = await load();
    if (manifestRes is Err<LogoManifest>) {
      return Err(manifestRes.failure);
    }
    final manifest = (manifestRes as Success<LogoManifest>).value;
    final asset = manifest.findByCompositeId(compositeId);
    if (asset == null) {
      return Err(UnexpectedFailure('Logo asset not found: $compositeId'));
    }

    try {
      // 2) SVG 로드
      final svgStr = await _bundle.loadString(asset.assetPath);

      // 3) SVG → PictureInfo → Canvas 에 scale 후 PNG bytes
      final pictureInfo = await vg.loadPicture(SvgStringLoader(svgStr), null);
      try {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final srcW = pictureInfo.size.width;
        final srcH = pictureInfo.size.height;
        if (srcW > 0 && srcH > 0) {
          canvas.scale(size / srcW, size / srcH);
        }
        canvas.drawPicture(pictureInfo.picture);
        final pic = recorder.endRecording();
        final img = await pic.toImage(size.toInt(), size.toInt());
        final byteData =
            await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          return const Err(
              UnexpectedFailure('Failed to encode logo PNG'));
        }
        final bytes = byteData.buffer.asUint8List();
        _putLru(cacheKey, bytes);
        img.dispose();
        pic.dispose();
        return Success(bytes);
      } finally {
        pictureInfo.picture.dispose();
      }
    } catch (e, st) {
      return Err(UnexpectedFailure(
        'Failed to rasterize $compositeId: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  LogoManifest _parseManifest(Map<String, dynamic> json) {
    final cats = (json['categories'] as List? ?? []).map((c) {
      final cm = c as Map<String, dynamic>;
      final catId = cm['id'] as String;
      final icons = (cm['icons'] as List? ?? []).map((i) {
        final im = i as Map<String, dynamic>;
        final iconId = im['id'] as String;
        final file = im['file'] as String;
        return LogoAsset(
          id: iconId,
          assetPath: 'assets/logos/$catId/$file',
        );
      }).toList();
      return LogoCategory(
        id: catId,
        nameKo: cm['name_ko'] as String? ?? catId,
        icons: icons,
      );
    }).toList();
    return LogoManifest(cats);
  }

  void _putLru(String key, Uint8List bytes) {
    if (_pngCache.length >= _pngCacheMax) {
      // 가장 오래된 키 제거
      final oldest = _pngCache.keys.first;
      _pngCache.remove(oldest);
    }
    _pngCache[key] = bytes;
  }
}
