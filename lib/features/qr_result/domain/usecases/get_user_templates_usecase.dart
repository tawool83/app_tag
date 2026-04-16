import '../../../../core/error/result.dart';
import '../entities/user_qr_template.dart';
import '../repositories/user_template_repository.dart';

class GetUserTemplatesUseCase {
  final UserTemplateRepository _repository;
  const GetUserTemplatesUseCase(this._repository);

  Future<Result<List<UserQrTemplate>>> call() => _repository.getAll();
}
