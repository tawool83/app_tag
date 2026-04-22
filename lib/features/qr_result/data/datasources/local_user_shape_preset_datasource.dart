import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/qr_shape_params.dart';
import '../../domain/entities/user_shape_preset.dart';

/// Hive 기반 사용자 모양 프리셋 저장소.
///
/// ShapePresetType별 독립 Box 사용:
///   - user_dot_presets
///   - user_eye_presets
///   - user_boundary_presets
///   - user_animation_presets
class LocalUserShapePresetDatasource {
  static const _boxNames = {
    ShapePresetType.dot: 'user_dot_presets',
    ShapePresetType.eye: 'user_eye_presets',
    ShapePresetType.boundary: 'user_boundary_presets',
    ShapePresetType.animation: 'user_animation_presets',
  };

  final Map<ShapePresetType, Box<String>> _boxes;

  // 디코드된 프리셋 목록 캐시. 탭 재진입마다 N개 jsonDecode 반복하지 않도록
  // 타입별 첫 readAll() 결과를 보관하고 save/delete/clear 시 무효화한다.
  final Map<ShapePresetType, List<UserShapePreset>> _cache = {};

  LocalUserShapePresetDatasource(this._boxes);

  /// 모든 박스를 열고 인스턴스를 반환.
  static Future<LocalUserShapePresetDatasource> init() async {
    final boxes = <ShapePresetType, Box<String>>{};
    for (final entry in _boxNames.entries) {
      boxes[entry.key] = await Hive.openBox<String>(entry.value);
    }
    return LocalUserShapePresetDatasource(boxes);
  }

  /// 특정 타입의 프리셋 전체 조회 (lastUsedAt 내림차순).
  List<UserShapePreset> readAll(ShapePresetType type) {
    return _cache[type] ??= _decodeBox(type);
  }

  List<UserShapePreset> _decodeBox(ShapePresetType type) {
    final box = _boxes[type]!;
    final legacyIds = <String>[];
    final presets = <UserShapePreset>[];
    for (final entry in box.toMap().entries) {
      final jsonStr = entry.value;
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        // eye legacy 감지: eyeParams.outerN 만 있고 cornerQ* 없음
        if (type == ShapePresetType.eye) {
          final eyeJson = map['eyeParams'] as Map<String, dynamic>?;
          if (eyeJson != null &&
              EyeShapeParams.fromJsonOrNull(eyeJson) == null) {
            legacyIds.add(entry.key as String);
            continue;
          }
        }
        presets.add(UserShapePreset.fromJson(map));
      } catch (_) {
        legacyIds.add(entry.key as String); // 디코드 실패도 제거
      }
    }
    // 비동기 cleanup (fire-and-forget)
    for (final id in legacyIds) {
      box.delete(id);
    }
    presets.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return presets;
  }

  /// 프리셋 저장 (id 기준 upsert).
  Future<void> save(UserShapePreset preset) async {
    final box = _boxes[preset.type]!;
    await box.put(preset.id, jsonEncode(preset.toJson()));
    _cache.remove(preset.type);
  }

  /// lastUsedAt 갱신.
  Future<void> touchLastUsed(ShapePresetType type, String id) async {
    final box = _boxes[type]!;
    final jsonStr = box.get(id);
    if (jsonStr == null) return;
    final preset = UserShapePreset.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
    await save(preset.withLastUsed(DateTime.now()));
  }

  /// 프리셋 삭제.
  Future<void> delete(ShapePresetType type, String id) async {
    final box = _boxes[type]!;
    await box.delete(id);
    _cache.remove(type);
  }

  /// 특정 타입의 프리셋 전체 삭제.
  Future<void> clearAll(ShapePresetType type) async {
    await _boxes[type]!.clear();
    _cache.remove(type);
  }
}
