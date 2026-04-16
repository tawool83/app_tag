import '../../../../core/error/result.dart';
import '../repositories/user_template_repository.dart';

class DeleteUserTemplateUseCase {
  final UserTemplateRepository _repository;
  const DeleteUserTemplateUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.delete(id);
}
