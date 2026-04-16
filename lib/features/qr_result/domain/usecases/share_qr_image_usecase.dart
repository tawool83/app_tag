import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../repositories/qr_output_repository.dart';

class ShareQrImageUseCase {
  final QrOutputRepository _repository;
  const ShareQrImageUseCase(this._repository);

  Future<Result<void>> call(Uint8List imageBytes, String appName) =>
      _repository.shareImage(imageBytes, appName);
}
