import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/qr_template.dart';
import '../shared/constants/app_config.dart';

class TemplateService {
  static const String _boxName = 'qr_templates_cache';
  static const String _keyData = 'data';
  static const String _keyFetchedAt = 'fetched_at';

  /// 지원 가능한 템플릿 매니페스트 반환.
  /// 우선순위: 유효 캐시 → 원격 JSON → 만료 캐시 → 빌트인 기본값
  static Future<QrTemplateManifest> getTemplates() async {
    final box = await Hive.openBox<String>(_boxName);

    // 1. 캐시 유효성 검사
    final fetchedAtStr = box.get(_keyFetchedAt);
    if (fetchedAtStr != null) {
      final fetchedAt = DateTime.tryParse(fetchedAtStr);
      if (fetchedAt != null &&
          DateTime.now().difference(fetchedAt) < kTemplateCacheTtl) {
        final cached = box.get(_keyData);
        if (cached != null) {
          return _parseAndFilter(cached);
        }
      }
    }

    // 2. 원격 로드 시도
    try {
      final response = await http
          .get(Uri.parse(kQrTemplatesUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await box.put(_keyData, response.body);
        await box.put(_keyFetchedAt, DateTime.now().toIso8601String());
        return _parseAndFilter(response.body);
      }
    } catch (_) {}

    // 3. 만료된 캐시라도 사용
    final staleCache = box.get(_keyData);
    if (staleCache != null) {
      return _parseAndFilter(staleCache);
    }

    // 4. 빌트인 기본 템플릿 (오프라인 + 캐시 없음)
    return _loadBuiltin();
  }

  /// 캐시 무시하고 강제 갱신
  static Future<QrTemplateManifest> refreshTemplates() async {
    final box = await Hive.openBox<String>(_boxName);
    await box.delete(_keyFetchedAt); // TTL 만료로 처리
    return getTemplates();
  }

  /// URL 이미지를 bytes로 로드 (5초 타임아웃, 실패 시 null)
  static Future<Uint8List?> loadImageBytes(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  // ── private ────────────────────────────────────────────────────────────────

  static QrTemplateManifest _parseAndFilter(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final manifest = QrTemplateManifest.fromJson(decoded);
      // 엔진 버전 필터 적용
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
}
