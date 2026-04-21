import 'package:flutter/foundation.dart';

import 'scan_detected_type.dart';

/// 스캔 1건의 파싱 결과.
///
/// [parsedMeta] 키 규격은 [ScanDetectedType] 별로 다름:
/// - url:        { 'url': String }
/// - wifi:       { 'ssid': String, 'password': String?, 'securityType': String }
/// - contact:    { 'name': String, 'phone': String?, 'email': String? }
/// - sms:        { 'phone': String, 'message': String? }
/// - email:      { 'address': String, 'subject': String?, 'body': String? }
/// - location:   { 'lat': double, 'lng': double, 'label': String? }
/// - event:      { 'title': String, 'start': String, 'end': String, 'location': String?, 'description': String? }
/// - appDeepLink:{ 'uri': String }
/// - text:       { 'text': String }
@immutable
class ScanResult {
  final String rawValue;
  final ScanDetectedType detectedType;
  final Map<String, dynamic> parsedMeta;

  const ScanResult({
    required this.rawValue,
    required this.detectedType,
    required this.parsedMeta,
  });
}
