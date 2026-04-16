import 'package:hive/hive.dart';

import '../models/qr_task_model.dart';
import 'qr_task_local_datasource.dart';

class HiveQrTaskDataSource implements QrTaskLocalDataSource {
  static const boxName = 'qr_tasks';

  final Box<QrTaskModel> _box;

  const HiveQrTaskDataSource(this._box);

  @override
  List<QrTaskModel> readAll() => _box.values.toList();

  @override
  QrTaskModel? readById(String id) => _box.get(id);

  @override
  Future<void> put(QrTaskModel model) => _box.put(model.id, model);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> clearAll() => _box.clear();
}
