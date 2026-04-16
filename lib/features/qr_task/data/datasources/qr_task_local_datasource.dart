import '../models/qr_task_model.dart';

abstract class QrTaskLocalDataSource {
  /// 전체 (저장 순서 그대로 — 정렬은 Repository 책임).
  List<QrTaskModel> readAll();

  QrTaskModel? readById(String id);

  Future<void> put(QrTaskModel model);

  Future<void> delete(String id);

  Future<void> clearAll();
}
