import 'package:nfc_manager/nfc_manager.dart';

class NdefRecordHelper {
  /// Android URI 레코드 여부 (package: 스킴)
  static bool isAndroidRecord(NdefRecord record) {
    final uri = _extractUri(record);
    return uri != null && uri.startsWith('package:');
  }

  /// iOS URI 레코드 여부 (shortcuts:// 스킴)
  static bool isIosRecord(NdefRecord record) {
    final uri = _extractUri(record);
    return uri != null && uri.startsWith('shortcuts://');
  }

  /// 기존 레코드 목록에서 현재 플랫폼 레코드만 교체, 나머지 보존
  static List<NdefRecord> merge({
    required List<NdefRecord> existing,
    required NdefRecord newRecord,
    required bool isAndroid,
  }) {
    final preserved = existing.where((r) {
      return isAndroid ? !isAndroidRecord(r) : !isIosRecord(r);
    }).toList();
    return [...preserved, newRecord];
  }

  /// URI Well-Known 레코드에서 URI 문자열 추출
  static String? _extractUri(NdefRecord record) {
    try {
      if (record.typeNameFormat != NdefTypeNameFormat.nfcWellknown) return null;
      if (record.type.length != 1 || record.type[0] != 0x55) return null; // 'U'
      if (record.payload.isEmpty) return null;
      final prefixCode = record.payload[0];
      final prefix = _uriPrefix(prefixCode);
      final body = String.fromCharCodes(record.payload.sublist(1));
      return '$prefix$body';
    } catch (_) {
      return null;
    }
  }

  /// NFC Forum URI prefix table (RFC 3987)
  static String _uriPrefix(int code) {
    const prefixes = {
      0x00: '',
      0x01: 'http://www.',
      0x02: 'https://www.',
      0x03: 'http://',
      0x04: 'https://',
      0x05: 'tel:',
      0x06: 'mailto:',
    };
    return prefixes[code] ?? '';
  }
}
