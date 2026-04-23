import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class ToggleFavoriteUseCase {
  final QrTaskRepository _repository;
  const ToggleFavoriteUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.toggleFavorite(id);
}
