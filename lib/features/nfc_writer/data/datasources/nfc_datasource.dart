import 'package:nfc_manager/nfc_manager.dart';

/// Platform NFC operations contract.
/// 플랫폼 NFC 작업 계약.
abstract class NfcDataSource {
  Future<bool> isAvailable();
  Future<bool> isWriteSupported();
  Future<List<NdefRecord>> readRecords(NfcTag tag);
  Future<void> writeRecords(NfcTag tag, List<NdefRecord> records);
  Future<void> stopSession({String? errorMessage});

  /// Start NFC discovery session. Calls [onDiscovered] when a tag is found.
  /// NFC 디스커버리 세션 시작. 태그 발견 시 [onDiscovered] 호출.
  void startSession({required Future<void> Function(NfcTag) onDiscovered});
}
