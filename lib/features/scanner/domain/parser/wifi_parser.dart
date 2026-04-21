import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

/// WIFI:T:WPA;S:MyNetwork;P:password123;;
ScanResult? tryParseWifi(String raw) {
  if (!raw.toUpperCase().startsWith('WIFI:')) return null;

  String? ssid;
  String? password;
  String securityType = 'WPA';

  // WIFI:T:WPA;S:SSID;P:PASS;H:true;; 형식 파싱
  final body = raw.substring(5); // 'WIFI:' 이후
  final parts = body.split(';');
  for (final part in parts) {
    if (part.isEmpty) continue;
    final colonIdx = part.indexOf(':');
    if (colonIdx < 0) continue;
    final key = part.substring(0, colonIdx).toUpperCase();
    final value = part.substring(colonIdx + 1);
    switch (key) {
      case 'T':
        securityType = value;
      case 'S':
        ssid = value;
      case 'P':
        password = value.isEmpty ? null : value;
    }
  }

  if (ssid == null || ssid.isEmpty) return null;

  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.wifi,
    parsedMeta: {
      'ssid': ssid,
      'password': password,
      'securityType': securityType,
    },
  );
}
