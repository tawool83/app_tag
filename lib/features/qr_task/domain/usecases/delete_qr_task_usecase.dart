import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class DeleteQrTaskUseCase {
  final QrTaskRepository _repository;
  const DeleteQrTaskUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.delete(id);
}
