import 'package:flutter/foundation.dart';

import '../../../scanner/domain/entities/scan_detected_type.dart';

@immutable
class ScanHistoryEntry {
  final String id;
  final DateTime scannedAt;
  final String rawValue;
  final ScanDetectedType detectedType;
  final Map<String, dynamic> parsedMeta;
  final bool isFavorite;

  const ScanHistoryEntry({
    required this.id,
    required this.scannedAt,
    required this.rawValue,
    required this.detectedType,
    required this.parsedMeta,
    this.isFavorite = false,
  });

  ScanHistoryEntry copyWith({
    bool? isFavorite,
  }) =>
      ScanHistoryEntry(
        id: id,
        scannedAt: scannedAt,
        rawValue: rawValue,
        detectedType: detectedType,
        parsedMeta: parsedMeta,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  /// 프리뷰 제목 추출 (타입별).
  String get displayTitle => switch (detectedType) {
        ScanDetectedType.url => parsedMeta['url'] as String? ?? rawValue,
        ScanDetectedType.wifi => parsedMeta['ssid'] as String? ?? rawValue,
        ScanDetectedType.contact => parsedMeta['name'] as String? ?? rawValue,
        ScanDetectedType.sms => parsedMeta['phone'] as String? ?? rawValue,
        ScanDetectedType.email => parsedMeta['address'] as String? ?? rawValue,
        ScanDetectedType.location => parsedMeta['label'] as String? ?? 'geo:${parsedMeta['lat']},${parsedMeta['lng']}',
        ScanDetectedType.event => parsedMeta['title'] as String? ?? rawValue,
        ScanDetectedType.appDeepLink => parsedMeta['uri'] as String? ?? rawValue,
        ScanDetectedType.text => rawValue,
      };
}
