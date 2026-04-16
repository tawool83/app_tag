import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class ClearQrTasksUseCase {
  final QrTaskRepository _repository;
  const ClearQrTasksUseCase(this._repository);

  Future<Result<void>> call() => _repository.clearAll();
}
