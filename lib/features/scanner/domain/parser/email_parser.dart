import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

/// mailto:addr?subject=...&body=... 또는 MATMSG:TO:addr;SUB:...;BODY:...;;
ScanResult? tryParseEmail(String raw) {
  if (raw.startsWith('mailto:')) {
    return _parseMailto(raw);
  }
  if (raw.toUpperCase().startsWith('MATMSG:')) {
    return _parseMatmsg(raw);
  }
  return null;
}

ScanResult _parseMailto(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) {
    return ScanResult(
      rawValue: raw,
      detectedType: ScanDetectedType.email,
      parsedMeta: {'address': raw.substring(7), 'subject': null, 'body': null},
    );
  }
  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.email,
    parsedMeta: {
      'address': uri.path,
      'subject': uri.queryParameters['subject'],
      'body': uri.queryParameters['body'],
    },
  );
}

ScanResult _parseMatmsg(String raw) {
  String? address;
  String? subject;
  String? body;

  final content = raw.substring(7); // 'MATMSG:' 이후
  for (final part in content.split(';')) {
    if (part.isEmpty) continue;
    final colonIdx = part.indexOf(':');
    if (colonIdx < 0) continue;
    final key = part.substring(0, colonIdx).toUpperCase();
    final value = part.substring(colonIdx + 1);
    switch (key) {
      case 'TO':
        address = value;
      case 'SUB':
        subject = value.isEmpty ? null : value;
      case 'BODY':
        body = value.isEmpty ? null : value;
    }
  }

  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.email,
    parsedMeta: {
      'address': address ?? '',
      'subject': subject,
      'body': body,
    },
  );
}
