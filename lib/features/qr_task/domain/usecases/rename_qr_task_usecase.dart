import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class RenameQrTaskUseCase {
  final QrTaskRepository _repository;
  const RenameQrTaskUseCase(this._repository);

  Future<Result<void>> call(String taskId, String newName) async {
    final result = await _repository.getById(taskId);
    final task = result.valueOrNull;
    if (task == null) return Err(StorageFailure('QrTask 미존재: $taskId'));
    final updated = task.copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
    return _repository.update(updated);
  }
}
