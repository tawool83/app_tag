import 'package:flutter/material.dart';

import '../../../domain/entities/scan_detected_type.dart';
import '../../../domain/entities/scan_result.dart';

class PreviewArea extends StatelessWidget {
  final ScanResult result;

  const PreviewArea({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Text(
      _previewText,
      style: Theme.of(context).textTheme.bodyLarge,
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }

  String get _previewText => switch (result.detectedType) {
        ScanDetectedType.url => result.parsedMeta['url'] as String? ?? result.rawValue,
        ScanDetectedType.wifi => result.parsedMeta['ssid'] as String? ?? result.rawValue,
        ScanDetectedType.contact => result.parsedMeta['name'] as String? ?? result.rawValue,
        ScanDetectedType.email => result.parsedMeta['address'] as String? ?? result.rawValue,
        ScanDetectedType.sms => result.parsedMeta['phone'] as String? ?? result.rawValue,
        ScanDetectedType.location => _locationText,
        ScanDetectedType.event => result.parsedMeta['title'] as String? ?? result.rawValue,
        _ => result.rawValue,
      };

  String get _locationText {
    final label = result.parsedMeta['label'] as String?;
    if (label != null && label.isNotEmpty) return label;
    return 'geo:${result.parsedMeta['lat']},${result.parsedMeta['lng']}';
  }
}
