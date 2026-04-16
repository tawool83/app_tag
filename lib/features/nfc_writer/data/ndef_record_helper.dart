import 'package:nfc_manager/nfc_manager.dart';

/// NDEF record classification and merge utility.
/// NDEF 레코드 분류 및 병합 유틸리티.
class NdefRecordHelper {
  /// Whether this is an Android URI record (Play Store link).
  /// Android URI 레코드 여부 (Play Store 링크).
  static bool isAndroidRecord(NdefRecord record) {
    final uri = _extractUri(record);
    return uri != null &&
        uri.contains('play.google.com/store/apps/details');
  }

  /// Whether this is an iOS URI record (shortcuts:// scheme).
  /// iOS URI 레코드 여부 (shortcuts:// 스킴).
  static bool isIosRecord(NdefRecord record) {
    final uri = _extractUri(record);
    return uri != null && uri.startsWith('shortcuts://');
  }

  /// Replace only the current platform record, preserve others.
  /// 현재 플랫폼 레코드만 교체, 나머지 보존.
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

  static String? _extractUri(NdefRecord record) {
    try {
      if (record.typeNameFormat != NdefTypeNameFormat.nfcWellknown) return null;
      if (record.type.length != 1 || record.type[0] != 0x55) return null;
      if (record.payload.isEmpty) return null;
      final prefixCode = record.payload[0];
      final prefix = _uriPrefix(prefixCode);
      final body = String.fromCharCodes(record.payload.sublist(1));
      return '$prefix$body';
    } catch (_) {
      return null;
    }
  }

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
