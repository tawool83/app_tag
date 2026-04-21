import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

/// geo:lat,lng 또는 geo:lat,lng?q=label
ScanResult? tryParseLocation(String raw) {
  if (!raw.startsWith('geo:')) return null;

  final body = raw.substring(4); // 'geo:' 이후
  final queryIdx = body.indexOf('?');
  final coords = queryIdx >= 0 ? body.substring(0, queryIdx) : body;
  final parts = coords.split(',');

  if (parts.length < 2) return null;

  final lat = double.tryParse(parts[0]);
  final lng = double.tryParse(parts[1]);
  if (lat == null || lng == null) return null;

  String? label;
  if (queryIdx >= 0) {
    final query = Uri.tryParse('geo:$body')?.queryParameters;
    label = query?['q'];
  }

  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.location,
    parsedMeta: {
      'lat': lat,
      'lng': lng,
      'label': label,
    },
  );
}
