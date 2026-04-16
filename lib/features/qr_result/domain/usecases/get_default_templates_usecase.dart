import '../../../../core/error/result.dart';
import '../../../../models/qr_template.dart';
import '../repositories/default_template_repository.dart';

class GetDefaultTemplatesUseCase {
  final DefaultTemplateRepository _repository;
  const GetDefaultTemplatesUseCase(this._repository);

  Future<Result<QrTemplateManifest>> call() => _repository.getTemplates();
}
