import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

ScanResult? tryParseUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return ScanResult(
      rawValue: raw,
      detectedType: ScanDetectedType.url,
      parsedMeta: {'url': trimmed},
    );
  }
  return null;
}
