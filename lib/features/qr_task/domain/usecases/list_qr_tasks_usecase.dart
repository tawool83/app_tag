import '../../../../core/error/result.dart';
import '../entities/qr_task.dart';
import '../repositories/qr_task_repository.dart';

/// 전체 QrTask 조회 (updatedAt desc).
class ListQrTasksUseCase {
  final QrTaskRepository _repository;
  const ListQrTasksUseCase(this._repository);

  Future<Result<List<QrTask>>> call() => _repository.listAll();
}
