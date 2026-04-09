import 'package:hive_flutter/hive_flutter.dart';
import '../models/tag_history.dart';

class HistoryService {
  static const _boxName = 'tag_history';

  Box<TagHistory> get _box => Hive.box<TagHistory>(_boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TagHistoryAdapter());
    await Hive.openBox<TagHistory>(_boxName);
  }

  Future<void> saveHistory(TagHistory history) async {
    await _box.put(history.id, history);
  }

  List<TagHistory> getHistory() {
    final items = _box.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> deleteHistory(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
