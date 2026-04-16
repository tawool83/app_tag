import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../repositories/qr_output_repository.dart';

class PrintQrCodeUseCase {
  final QrOutputRepository _repository;
  const PrintQrCodeUseCase(this._repository);

  Future<Result<void>> call({
    required Uint8List imageBytes,
    required String appName,
    double sizeCm = 5.0,
    String? printTitle,
  }) =>
      _repository.printQrCode(
        imageBytes: imageBytes,
        appName: appName,
        sizeCm: sizeCm,
        printTitle: printTitle,
      );
}
