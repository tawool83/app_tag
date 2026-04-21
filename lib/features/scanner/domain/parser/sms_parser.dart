import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

/// SMSTO:+123:message 또는 sms:+123?body=message
ScanResult? tryParseSms(String raw) {
  final upper = raw.toUpperCase();

  if (upper.startsWith('SMSTO:') || upper.startsWith('SMS:')) {
    final body = raw.substring(raw.indexOf(':') + 1);

    // SMSTO:phone:message 형식
    if (upper.startsWith('SMSTO:')) {
      final parts = body.split(':');
      return ScanResult(
        rawValue: raw,
        detectedType: ScanDetectedType.sms,
        parsedMeta: {
          'phone': parts[0],
          'message': parts.length > 1 ? parts.sublist(1).join(':') : null,
        },
      );
    }

    // sms:phone?body=message 형식
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      return ScanResult(
        rawValue: raw,
        detectedType: ScanDetectedType.sms,
        parsedMeta: {
          'phone': uri.path,
          'message': uri.queryParameters['body'],
        },
      );
    }

    return ScanResult(
      rawValue: raw,
      detectedType: ScanDetectedType.sms,
      parsedMeta: {'phone': body, 'message': null},
    );
  }

  return null;
}
