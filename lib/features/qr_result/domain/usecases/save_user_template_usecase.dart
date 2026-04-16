import '../../../../core/error/result.dart';
import '../entities/user_qr_template.dart';
import '../repositories/user_template_repository.dart';

class SaveUserTemplateUseCase {
  final UserTemplateRepository _repository;
  const SaveUserTemplateUseCase(this._repository);

  Future<Result<void>> call(UserQrTemplate template) =>
      _repository.save(template);
}
