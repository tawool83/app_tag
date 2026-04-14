import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_qr_template.dart';

/// 사용자 QR 템플릿 로컬 저장소 (Hive 기반).
class UserTemplateRepository {
  static const _boxName = 'user_qr_templates';

  Box<UserQrTemplate> get _box => Hive.box<UserQrTemplate>(_boxName);

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserQrTemplateAdapter());
    }
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<UserQrTemplate>(_boxName);
    }
  }

  /// 저장 (신규 또는 덮어쓰기)
  Future<void> save(UserQrTemplate template) async {
    await _box.put(template.id, template);
  }

  /// 전체 목록 (최신순)
  List<UserQrTemplate> getAll() {
    final items = _box.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// 단건 조회
  UserQrTemplate? getById(String id) => _box.get(id);

  /// 삭제
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 전체 삭제
  Future<void> clearAll() async {
    await _box.clear();
  }
}
