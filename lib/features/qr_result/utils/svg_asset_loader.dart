import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// compositeId ("social/twitter") → 번들 SVG 문자열 로드.
/// 메모리 캐시 내장. 외부(logo_sync)에서 putCache 로 원격 SVG 주입 가능.
class SvgAssetLoader {
  final AssetBundle _bundle;
  final Map<String, String> _cache = {};

  SvgAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// compositeId → SVG 문자열. 캐시 히트 시 즉시 반환.
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
