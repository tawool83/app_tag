import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/qr_template.dart';
import '../services/supabase_service.dart';
import '../services/template_service.dart';

/// 템플릿 데이터 접근 단일 창구.
/// - 즉시 반환: 로컬 캐시 또는 빌트인 JSON
/// - 백그라운드: Supabase와 diff 비교 후 갱신
class TemplateRepository {
  /// 로컬 우선 로드 + 백그라운드 Supabase 동기화.
  /// [onRefresh]: 동기화 완료 시 UI 갱신 콜백 (nullable)
  static Future<QrTemplateManifest> getTemplates({
    void Function(QrTemplateManifest updated)? onRefresh,
  }) async {
    final local = await TemplateService.getTemplates();

    // 백그라운드 동기화 (await 없이)
    _syncFromSupabase(local, onRefresh);

    return local;
  }

  // ── private ────────────────────────────────────────────────────────────────

  static Future<void> _syncFromSupabase(
    QrTemplateManifest local,
    void Function(QrTemplateManifest)? onRefresh,
  ) async {
    if (!SupabaseService.isConfigured) return;

    try {
      // 가장 최근 updated_at 확인
      final row = await SupabaseService.client
          .from('qr_templates')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return;
      final remoteUpdatedAt = DateTime.tryParse(row['updated_at'] as String);
      if (remoteUpdatedAt == null) return;

      final cacheTs = await TemplateService.getCacheTimestamp();
      if (cacheTs != null && !remoteUpdatedAt.isAfter(cacheTs)) return;

      // 전체 템플릿 + 카테고리 로드
      final templateRows = await SupabaseService.client
          .from('qr_templates')
          .select('*, qr_template_categories(id, name, display_order)')
          .order('display_order');

      final categoryRows = await SupabaseService.client
          .from('qr_template_categories')
          .select()
          .order('display_order');

      final manifest = _parseRows(templateRows, categoryRows);
      await TemplateService.saveToCache(manifest);
      onRefresh?.call(manifest);
    } catch (_) {
      // 동기화 실패는 무시 (로컬 데이터 유지)
    }
  }

  static QrTemplateManifest _parseRows(
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

  /// URL에서 이미지 bytes 로드 (5초 타임아웃)
  static Future<Uint8List?> loadImageBytes(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }
}
