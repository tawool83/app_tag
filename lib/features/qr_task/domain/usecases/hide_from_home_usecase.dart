import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class HideFromHomeUseCase {
  final QrTaskRepository _repository;
  const HideFromHomeUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.hideFromHome(id);
}
