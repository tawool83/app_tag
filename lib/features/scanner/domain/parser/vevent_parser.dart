import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';

/// BEGIN:VEVENT 블록 파싱.
ScanResult? tryParseEvent(String raw) {
  if (!raw.contains('BEGIN:VEVENT')) return null;

  String? title;
  String? start;
  String? end;
  String? location;
  String? description;

  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final upper = line.toUpperCase();
    if (upper.startsWith('SUMMARY:')) {
      title = line.substring(8).trim();
    } else if (upper.startsWith('DTSTART')) {
      start = _extractDateValue(line);
    } else if (upper.startsWith('DTEND')) {
      end = _extractDateValue(line);
    } else if (upper.startsWith('LOCATION:')) {
      location = line.substring(9).trim();
    } else if (upper.startsWith('DESCRIPTION:')) {
      description = line.substring(12).trim();
    }
  }

  return ScanResult(
    rawValue: raw,
    detectedType: ScanDetectedType.event,
    parsedMeta: {
      'title': title ?? '',
      'start': start ?? '',
      'end': end ?? '',
      'location': location,
      'description': description,
    },
  );
}

/// DTSTART:20260421T140000 또는 DTSTART;VALUE=DATE:20260421 형식에서 값 추출.
String _extractDateValue(String line) {
  final colonIdx = line.lastIndexOf(':');
  if (colonIdx < 0) return '';
  return line.substring(colonIdx + 1).trim();
}
