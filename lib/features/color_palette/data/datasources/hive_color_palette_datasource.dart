import 'package:hive/hive.dart';

import '../models/user_color_palette_model.dart';

class HiveColorPaletteDataSource {
  static const String boxName = 'user_color_palettes';

  final Box<UserColorPaletteModel> _box;
  const HiveColorPaletteDataSource(this._box);

  List<UserColorPaletteModel> readAll() {
    final items = _box.values.toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  UserColorPaletteModel? readById(String id) => _box.get(id);

  Future<void> write(UserColorPaletteModel model) => _box.put(model.id, model);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}
