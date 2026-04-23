import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class HideAllFromHomeUseCase {
  final QrTaskRepository _repository;
  const HideAllFromHomeUseCase(this._repository);

  Future<Result<void>> call() => _repository.hideAllFromHome();
}
