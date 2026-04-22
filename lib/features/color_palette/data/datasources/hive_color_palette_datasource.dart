import 'package:hive/hive.dart';

import '../../domain/entities/user_color_palette.dart';
import '../models/user_color_palette_model.dart';

class HiveColorPaletteDataSource {
  static const String boxName = 'user_color_palettes';

  final Box<UserColorPaletteModel> _box;

  /// 타입별 in-memory cache. save/delete 시 해당 타입 무효화.
  /// 탭 재진입마다 전체 box decode 반복 방지.
  final Map<PaletteType, List<UserColorPalette>> _cacheByType = {};

  HiveColorPaletteDataSource(this._box);

  // ── 기존 (sync 용 유지) ──────────────────────────────────────────

  List<UserColorPaletteModel> readAll() {
    final items = _box.values.toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  UserColorPaletteModel? readById(String id) => _box.get(id);

  Future<void> write(UserColorPaletteModel model) async {
    await _box.put(model.id, model);
    _cacheByType.remove(PaletteType.values[model.typeIndex.clamp(0, 1)]);
  }

  Future<void> delete(String id) async {
    final model = _box.get(id);
    await _box.delete(id);
    if (model != null) {
      _cacheByType.remove(PaletteType.values[model.typeIndex.clamp(0, 1)]);
    }
  }

  Future<void> clear() async {
    await _box.clear();
    _cacheByType.clear();
  }

  // ── UI 용 확장 ──────────────────────────────────────────────────

  /// 타입별 필터링 + updatedAt desc 정렬. 캐시 적중 시 O(1).
  List<UserColorPalette> readAllSortedByRecency(PaletteType type) {
    return _cacheByType[type] ??= _loadFiltered(type);
  }

  List<UserColorPalette> _loadFiltered(PaletteType type) {
    final items = _box.values
        .where((m) => m.typeIndex == type.index)
        .map((m) => m.toEntity())
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  /// updatedAt 갱신 (select 시 호출). 캐시 무효화 포함.
  Future<void> touchLastUsed(String id) async {
    final model = _box.get(id);
    if (model == null) return;
    model.updatedAt = DateTime.now();
    await model.save();
    _cacheByType.remove(PaletteType.values[model.typeIndex.clamp(0, 1)]);
  }
}
