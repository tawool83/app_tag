import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../../../../models/qr_template.dart';

// Note: QrTemplateManifest은 lib/models/qr_template.dart에 정의됨.
// Flutter Color를 포함하므로 엄밀한 도메인 순수성을 지키지 못하지만
// 읽기 전용 값 객체로 취급하는 현실적 예외.
abstract class DefaultTemplateRepository {
  Future<Result<QrTemplateManifest>> getTemplates();
  Future<Result<Uint8List?>> loadImageBytes(String url);
}
