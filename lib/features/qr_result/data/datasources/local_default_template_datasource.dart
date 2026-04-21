import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/utils/color_hex.dart';
import '../../domain/entities/qr_template.dart';
import '../../../../core/services/supabase_service.dart';
import 'default_template_datasource.dart';

class LocalDefaultTemplateDataSource implements DefaultTemplateDataSource {
  static const String _boxName = 'qr_templates_cache';
  static const String _keyData = 'data';
  static const String _keyFetchedAt = 'fetched_at';

  @override
  Future<QrTemplateManifest> getLocal() async {
    final box = await Hive.openBox<String>(_boxName);
    final fetchedAtStr = box.get(_keyFetchedAt);
    if (fetchedAtStr != null) {
      final fetchedAt = DateTime.tryParse(fetchedAtStr);
      if (fetchedAt != null &&
          DateTime.now().difference(fetchedAt) < kTemplateCacheTtl) {
        final cached = box.get(_keyData);
        if (cached != null) return _parseAndFilter(cached);
      }
    }
    final staleCache = box.get(_keyData);
    if (staleCache != null) return _parseAndFilter(staleCache);
    return _loadBuiltin();
  }

  @override
  Future<void> saveCache(QrTemplateManifest manifest) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_keyData, jsonEncode(_manifestToJson(manifest)));
    await box.put(_keyFetchedAt, DateTime.now().toIso8601String());
  }

  @override
  Future<DateTime?> getCacheTimestamp() async {
    final box = await Hive.openBox<String>(_boxName);
    final str = box.get(_keyFetchedAt);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  @override
  Future<QrTemplateManifest?> fetchRemote(DateTime? localTimestamp) async {
    if (!SupabaseService.isConfigured) return null;
    try {
      final client = SupabaseService.client;
      final row = await client
          .from('qr_templates')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      final remoteUpdatedAt =
          DateTime.tryParse(row['updated_at'] as String? ?? '');
      if (remoteUpdatedAt == null) return null;
      if (localTimestamp != null &&
          !remoteUpdatedAt.isAfter(localTimestamp)) return null;

      final templateRows = await client
          .from('qr_templates')
          .select('*, qr_template_categories(id, name, display_order)')
          .order('display_order');
      final categoryRows = await client
          .from('qr_template_categories')
          .select()
          .order('display_order');

      return _parseRows(templateRows, categoryRows);
    } on PostgrestException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> loadImageBytes(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  // ── private ────────────────────────────────────────────────────────────────

  QrTemplateManifest _parseAndFilter(String jsonStr) {
    try {
      final manifest =
          QrTemplateManifest.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      return QrTemplateManifest(
        schemaVersion: manifest.schemaVersion,
        categories: manifest.categories,
        templates: manifest.templates
            .where((t) => t.minEngineVersion <= kTemplateEngineVersion)
            .toList(),
      );
    } catch (_) {
      return QrTemplateManifest.empty;
    }
  }

  Future<QrTemplateManifest> _loadBuiltin() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/default_templates.json');
      return _parseAndFilter(jsonStr);
    } catch (_) {
      return QrTemplateManifest.empty;
    }
  }

  QrTemplateManifest _parseRows(
    List<dynamic> templateRows,
    List<dynamic> categoryRows,
  ) {
    final categories = categoryRows.map((r) {
      final m = r as Map<String, dynamic>;
      return QrTemplateCategory(
        id: m['id'] as String,
        name: m['name'] as String,
        order: m['display_order'] as int? ?? 0,
      );
    }).toList();
    final templates = templateRows.map((r) {
      final m = r as Map<String, dynamic>;
      return QrTemplate.fromJson({
        'id': m['id'],
        'minEngineVersion': m['min_engine_version'] ?? 1,
        'name': m['name'],
        'categoryId': m['category_id'],
        'order': m['display_order'] ?? 0,
        'thumbnailUrl': m['thumbnail_url'],
        'isPremium': m['is_premium'] ?? false,
        'tagTypes': m['tag_types'] ?? [],
        'roundFactor': m['round_factor'],
        'style': m['style'] is String
            ? jsonDecode(m['style'] as String)
            : m['style'],
      });
    }).toList();
    return QrTemplateManifest(
      schemaVersion: 1,
      categories: categories,
      templates: templates,
    );
  }

  Map<String, dynamic> _manifestToJson(QrTemplateManifest manifest) => {
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

  Map<String, dynamic> _styleToJson(QrStyleData style) => {
        'dataModuleShape': style.dataModuleShape,
        'eyeShape': style.eyeShape,
        'backgroundColor': colorToHex(style.backgroundColor),
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

  Map<String, dynamic> _foregroundToJson(QrForeground fg) {
    if (fg.isGradient && fg.gradient != null) {
      final g = fg.gradient!;
      return {
        'type': 'gradient',
        'gradient': {
          'type': g.type,
          'colors': g.colors.map((c) => colorToHex(c)).toList(),
          'stops': g.stops,
          'angleDegrees': g.angleDegrees,
          if (g.center != null) 'center': g.center,
        },
      };
    }
    final c = fg.solidColor;
    return {
      'type': 'solid',
      'solidColor': c != null ? colorToHex(c) : '#000000',
    };
  }
}
