import 'dart:io';

import 'package:nfc_manager/nfc_manager.dart';

import 'nfc_datasource.dart';

/// NfcManager-based implementation of [NfcDataSource].
/// NfcManager 기반 [NfcDataSource] 구현.
class NfcManagerDataSource implements NfcDataSource {
  const NfcManagerDataSource();

  @override
  Future<bool> isAvailable() => NfcManager.instance.isAvailable();

  @override
  Future<bool> isWriteSupported() async {
    if (Platform.isAndroid) return true;
    // iOS: available == write-supported (iOS 13+ & XS+)
    return NfcManager.instance.isAvailable();
  }

  @override
  void startSession({
    required Future<void> Function(NfcTag) onDiscovered,
  }) {
    NfcManager.instance.startSession(onDiscovered: onDiscovered);
  }

  @override
  Future<List<NdefRecord>> readRecords(NfcTag tag) async {
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) return [];
      final message = await ndef.read();
      return message.records;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> writeRecords(NfcTag tag, List<NdefRecord> records) async {
    final ndef = Ndef.from(tag);
    if (ndef == null || !ndef.isWritable) {
      throw Exception('쓰기 불가능한 태그입니다.');
    }
    await ndef.write(NdefMessage(records));
  }

  @override
  Future<void> stopSession({String? errorMessage}) =>
      NfcManager.instance.stopSession(errorMessage: errorMessage);
}
