import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../repositories/default_template_repository.dart';

class LoadTemplateImageUseCase {
  final DefaultTemplateRepository _repository;
  const LoadTemplateImageUseCase(this._repository);

  Future<Result<Uint8List?>> call(String url) =>
      _repository.loadImageBytes(url);
}
