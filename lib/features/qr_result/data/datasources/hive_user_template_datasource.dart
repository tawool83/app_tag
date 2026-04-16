import 'package:hive/hive.dart';

import '../models/user_qr_template_model.dart';
import 'user_template_local_datasource.dart';

class HiveUserTemplateDataSource implements UserTemplateLocalDataSource {
  static const String boxName = 'user_qr_templates';

  final Box<UserQrTemplateModel> _box;
  const HiveUserTemplateDataSource(this._box);

  @override
  List<UserQrTemplateModel> readAll() {
    final items = _box.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  UserQrTemplateModel? readById(String id) => _box.get(id);

  @override
  Future<void> write(UserQrTemplateModel model) => _box.put(model.id, model);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> clear() => _box.clear();
}
