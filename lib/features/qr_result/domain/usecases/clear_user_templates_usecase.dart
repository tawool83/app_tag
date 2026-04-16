import '../../../../core/error/result.dart';
import '../repositories/user_template_repository.dart';

class ClearUserTemplatesUseCase {
  final UserTemplateRepository _repository;
  const ClearUserTemplatesUseCase(this._repository);

  Future<Result<void>> call() => _repository.clearAll();
}
