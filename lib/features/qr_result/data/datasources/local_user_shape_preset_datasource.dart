import 'dart:convert';

import 'package:hive/hive.dart';

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

  const LocalUserShapePresetDatasource(this._boxes);

  /// 모든 박스를 열고 인스턴스를 반환.
  static Future<LocalUserShapePresetDatasource> init() async {
    final boxes = <ShapePresetType, Box<String>>{};
    for (final entry in _boxNames.entries) {
      boxes[entry.key] = await Hive.openBox<String>(entry.value);
    }
    return LocalUserShapePresetDatasource(boxes);
  }

  /// 특정 타입의 프리셋 전체 조회 (생성일 내림차순).
  List<UserShapePreset> readAll(ShapePresetType type) {
    final box = _boxes[type]!;
    final presets = box.values
        .map((jsonStr) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          return UserShapePreset.fromJson(map);
        })
        .toList();
    presets.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return presets;
  }

  /// 프리셋 저장 (id 기준 upsert).
  Future<void> save(UserShapePreset preset) async {
    final box = _boxes[preset.type]!;
    await box.put(preset.id, jsonEncode(preset.toJson()));
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
  }

  /// 특정 타입의 프리셋 전체 삭제.
  Future<void> clearAll(ShapePresetType type) async {
    await _boxes[type]!.clear();
  }
}
