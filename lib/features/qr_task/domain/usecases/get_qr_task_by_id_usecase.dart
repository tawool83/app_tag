import '../../../../core/error/result.dart';
import '../entities/qr_task.dart';
import '../repositories/qr_task_repository.dart';

class GetQrTaskByIdUseCase {
  final QrTaskRepository _repository;
  const GetQrTaskByIdUseCase(this._repository);

  Future<Result<QrTask?>> call(String id) => _repository.getById(id);
}
