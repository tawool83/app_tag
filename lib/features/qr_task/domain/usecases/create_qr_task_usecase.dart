import '../../../../core/error/result.dart';
import '../entities/qr_task.dart';
import '../entities/qr_task_kind.dart';
import '../entities/qr_task_meta.dart';
import '../repositories/qr_task_repository.dart';

/// 신규 QrTask 발급. QR 화면 진입 시 1회 호출.
class CreateQrTaskUseCase {
  final QrTaskRepository _repository;
  const CreateQrTaskUseCase(this._repository);

  Future<Result<QrTask>> call({
    required QrTaskKind kind,
    required QrTaskMeta meta,
  }) =>
      _repository.createNew(kind: kind, meta: meta);
}
