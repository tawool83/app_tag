import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

/// BEGIN:VCARD / MECARD: 형식 파싱.
ScanResult? tryParseContact(String raw) {
  if (raw.contains('BEGIN:VCARD')) {
    return _parseVCard(raw);
  }
  if (raw.toUpperCase().startsWith('MECARD:')) {
    return _parseMeCard(raw);
  }
  return null;
}

ScanResult _parseVCard(String raw) {
  String? name;
  String? phone;
  String? email;

  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final upper = line.toUpperCase();
    if (upper.startsWith('FN:')) {
      name = line.substring(3).trim();
    } else if (upper.startsWith('TEL') && line.contains(':')) {
      phone = line.substring(line.indexOf(':') + 1).trim();
    } else if (upper.startsWith('EMAIL') && line.contains(':')) {
      email = line.substring(line.indexOf(':') + 1).trim();
    }
  }

  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.contact,
    parsedMeta: {
      'name': name ?? '',
      'phone': phone,
      'email': email,
    },
  );
}

ScanResult _parseMeCard(String raw) {
  String? name;
  String? phone;
  String? email;

  // MECARD:N:Name;TEL:123;EMAIL:a@b.com;;
  final body = raw.substring(7); // 'MECARD:' 이후
  for (final part in body.split(';')) {
    if (part.isEmpty) continue;
    final colonIdx = part.indexOf(':');
    if (colonIdx < 0) continue;
    final key = part.substring(0, colonIdx).toUpperCase();
    final value = part.substring(colonIdx + 1);
    switch (key) {
      case 'N':
        name = value;
      case 'TEL':
        phone = value;
      case 'EMAIL':
        email = value;
    }
  }

  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.contact,
    parsedMeta: {
      'name': name ?? '',
      'phone': phone,
      'email': email,
    },
  );
}
