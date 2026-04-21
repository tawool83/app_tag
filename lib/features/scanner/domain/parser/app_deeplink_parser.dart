import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

/// apptag:// 스키마 딥링크 파싱.
ScanResult? tryParseAppDeepLink(String raw) {
  if (!raw.startsWith('apptag://')) return null;

  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.appDeepLink,
    parsedMeta: {'uri': raw},
  );
}
