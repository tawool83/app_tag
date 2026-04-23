import '../../../../core/error/result.dart';
import '../entities/qr_task.dart';
import '../repositories/qr_task_repository.dart';

class ListHomeVisibleUseCase {
  final QrTaskRepository _repository;
  const ListHomeVisibleUseCase(this._repository);

  Future<Result<List<QrTask>>> call() => _repository.listHomeVisible();
}
