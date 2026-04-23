import 'dart:typed_data';

import '../../../../core/error/result.dart';

abstract class QrOutputRepository {
  Future<Result<bool>> saveToGallery(Uint8List imageBytes, String appName);
  Future<Result<void>> shareImage(Uint8List imageBytes, String appName);
  Future<Result<void>> printQrCode({
    required Uint8List imageBytes,
    required String appName,
    double sizeCm = 5.0,
    String? printTitle,
  });
  Future<Result<String>> saveAsSvg(String svgString, String appName);
}
