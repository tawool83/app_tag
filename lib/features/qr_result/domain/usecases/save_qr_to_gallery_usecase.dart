import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../repositories/qr_output_repository.dart';

class SaveQrToGalleryUseCase {
  final QrOutputRepository _repository;
  const SaveQrToGalleryUseCase(this._repository);

  Future<Result<bool>> call(Uint8List imageBytes, String appName) =>
      _repository.saveToGallery(imageBytes, appName);
}
