import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/qr_template.dart';
import '../shared/constants/app_config.dart';

class TemplateService {
  static const String _boxName = 'qr_templates_cache';
  static const String _keyData = 'data';
  static const String _keyFetchedAt = 'fetched_at';

  /// 캐시 또는 빌트인 기본값을 반환.
  /// Supabase 동기화는 TemplateRepository가 담당.
  static Future<QrTemplateManifest> getTemplates() async {
    final box = await Hive.openBox<String>(_boxName);

    // 캐시 유효성 검사
    final fetchedAtStr = box.get(_keyFetchedAt);
    if (fetchedAtStr != null) {
      final fetchedAt = DateTime.tryParse(fetchedAtStr);
      if (fetchedAt != null &&
          DateTime.now().difference(fetchedAt) < kTemplateCacheTtl) {
        final cached = box.get(_keyData);
        if (cached != null) return _parseAndFilter(cached);
      }
    }

    // 만료된 캐시라도 사용
    final staleCache = box.get(_keyData);
    if (staleCache != null) return _parseAndFilter(staleCache);

    // 빌트인 기본 템플릿
    return _loadBuiltin();
  }

  /// 캐시 타임스탬프 반환 (Supabase diff 비교용)
  static Future<DateTime?> getCacheTimestamp() async {
    final box = await Hive.openBox<String>(_boxName);
    final str = box.get(_keyFetchedAt);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Supabase에서 받은 manifest를 캐시에 저장
  static Future<void> saveToCache(QrTemplateManifest manifest) async {
    final box = await Hive.openBox<String>(_boxName);
    final json = _manifestToJson(manifest);
    await box.put(_keyData, jsonEncode(json));
    await box.put(_keyFetchedAt, DateTime.now().toIso8601String());
  }

  /// URL 이미지를 bytes로 로드 (5초 타임아웃, 실패 시 null)
  static Future<Uint8List?> loadImageBytes(String url) async {
    try {
      // http 패키지는 TemplateRepository에서만 사용
      // 여기서는 단순 선언만 유지
      return null;
    } catch (_) {}
    return null;
  }

  // ── private ────────────────────────────────────────────────────────────────

  static QrTemplateManifest _parseAndFilter(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final manifest = QrTemplateManifest.fromJson(decoded);
      final supported = manifest.templates
          .where((t) => t.minEngineVersion <= kTemplateEngineVersion)
          .toList();
      return QrTemplateManifest(
        schemaVersion: manifest.schemaVersion,
        categories: manifest.categories,
        templates: supported,
      );
    } catch (_) {
      return QrTemplateManifest.empty;
    }
  }

  static Future<QrTemplateManifest> _loadBuiltin() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/default_templates.json');
      return _parseAndFilter(jsonStr);
    } catch (_) {
      return QrTemplateManifest.empty;
    }
  }

  static Map<String, dynamic> _manifestToJson(QrTemplateManifest manifest) {
    return {
      'schemaVersion': manifest.schemaVersion,
      'categories': manifest.categories
          .map((c) => {'id': c.id, 'name': c.name, 'order': c.order})
          .toList(),
      'templates': manifest.templates
          .map((t) => {
                'id': t.id,
                'minEngineVersion': t.minEngineVersion,
                'name': t.name,
                'categoryId': t.categoryId,
                'order': t.order,
                'thumbnailUrl': t.thumbnailUrl,
                'isPremium': t.isPremium,
                'tagTypes': t.tagTypes,
                'roundFactor': t.roundFactor,
                'style': _styleToJson(t.style),
              })
          .toList(),
    };
  }

  static Map<String, dynamic> _styleToJson(QrStyleData style) {
    return {
      'dataModuleShape': style.dataModuleShape,
      'eyeShape': style.eyeShape,
      'backgroundColor':
          '#${style.backgroundColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'foreground': _foregroundToJson(style.foreground),
      'eyeColor':
          style.eyeColor != null ? _foregroundToJson(style.eyeColor!) : null,
      'centerIcon': {
        'type': style.centerIcon.type,
        'url': style.centerIcon.url,
        'emoji': style.centerIcon.emoji,
        'sizeRatio': style.centerIcon.sizeRatio,
      },
    };
  }

  static Map<String, dynamic> _foregroundToJson(QrForeground fg) {
    if (fg.isGradient && fg.gradient != null) {
      final g = fg.gradient!;
      return {
        'type': 'gradient',
        'gradient': {
          'type': g.type,
          'colors': g.colors
              .map((c) =>
                  '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}')
              .toList(),
          'stops': g.stops,
          'angleDegrees': g.angleDegrees,
        },
      };
    }
    final c = fg.solidColor;
    return {
      'type': 'solid',
      'solidColor': c != null
          ? '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
          : '#000000',
    };
  }
}
