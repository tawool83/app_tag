import 'dart:typed_data';

import '../../domain/entities/qr_template.dart';

abstract class DefaultTemplateDataSource {
  Future<QrTemplateManifest> getLocal();
  Future<void> saveCache(QrTemplateManifest manifest);
  Future<DateTime?> getCacheTimestamp();
  Future<QrTemplateManifest?> fetchRemote(DateTime? localTimestamp);
  Future<Uint8List?> loadImageBytes(String url);
}
