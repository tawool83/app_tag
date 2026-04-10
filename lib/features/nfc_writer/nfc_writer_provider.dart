import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../services/ndef_record_helper.dart';
import '../../services/nfc_service.dart';
import '../app_picker/app_picker_provider.dart';

enum NfcWriteStatus { idle, waiting, success, error }

class NfcWriterState {
  final NfcWriteStatus status;
  final String? errorMessage;
  final bool hasCrossPlatformRecord;

  const NfcWriterState({
    this.status = NfcWriteStatus.idle,
    this.errorMessage,
    this.hasCrossPlatformRecord = false,
  });

  NfcWriterState copyWith({
    NfcWriteStatus? status,
    String? errorMessage,
    bool? hasCrossPlatformRecord,
  }) =>
      NfcWriterState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        hasCrossPlatformRecord:
            hasCrossPlatformRecord ?? this.hasCrossPlatformRecord,
      );
}

class NfcWriterNotifier extends StateNotifier<NfcWriterState> {
  final NfcService _nfcService;

  NfcWriterNotifier(this._nfcService) : super(const NfcWriterState());

  /// Read-Merge-Write: 태그를 먼저 읽어 기존 레코드를 보존하고
  /// 현재 플랫폼 레코드만 교체하여 기록
  void startWrite({
    required String deepLink,
    String? iosShortcutName,
  }) {
    state = state.copyWith(status: NfcWriteStatus.waiting);
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // 1. 기존 레코드 읽기
          final existing = await _nfcService.readNdefRecords(tag);

          // 1-1. 다른 플랫폼 레코드 존재 여부 확인
          final isAndroid = Platform.isAndroid;
          final hasCross = existing.any(
            (r) => isAndroid
                ? NdefRecordHelper.isIosRecord(r)
                : NdefRecordHelper.isAndroidRecord(r),
          );
          if (mounted) {
            state = state.copyWith(hasCrossPlatformRecord: hasCross);
          }

          // 2. 현재 플랫폼 레코드 생성
          final myRecord = NdefRecord.createUri(Uri.parse(deepLink));

          // 3. 현재 플랫폼 레코드만 교체, 나머지 보존
          var records = NdefRecordHelper.merge(
            existing: existing,
            newRecord: myRecord,
            isAndroid: isAndroid,
          );

          // 4. Android에서 iOS 단축어도 함께 기록
          if (isAndroid &&
              iosShortcutName != null &&
              iosShortcutName.isNotEmpty) {

            final iosUri =
                'shortcuts://run-shortcut?name=${Uri.encodeComponent(iosShortcutName)}';
            final iosRecord = NdefRecord.createUri(Uri.parse(iosUri));
            records = NdefRecordHelper.merge(
              existing: records,
              newRecord: iosRecord,
              isAndroid: false,
            );
          }

          // 5. 병합된 레코드 쓰기
          await _nfcService.writeNdefMessage(tag: tag, records: records);
          await NfcManager.instance.stopSession();

          if (mounted) {
            state = state.copyWith(status: NfcWriteStatus.success);
          }
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: '$e');
          if (mounted) {
            state = state.copyWith(
              status: NfcWriteStatus.error,
              errorMessage: _resolveErrorMessage(e.toString()),
            );
          }
        }
      },
    );
  }

  String _resolveErrorMessage(String error) {
    if (error.contains('쓰기 불가능') || error.contains('not writable')) {
      return '쓰기 불가능한 태그입니다.';
    }
    if (error.contains('capacity') ||
        error.contains('overflow') ||
        error.contains('too large') ||
        error.contains('size')) {
      return '태그 용량이 부족합니다. 더 큰 용량의 태그를 사용해주세요.';
    }
    return 'NFC 기록에 실패했습니다.';
  }

  void reset() {
    state = const NfcWriterState();
  }

  @override
  void dispose() {
    _nfcService.stopNfcSession();
    super.dispose();
  }
}

final nfcWriterProvider =
    StateNotifierProvider.autoDispose<NfcWriterNotifier, NfcWriterState>(
  (ref) {
    final service = ref.read(nfcServiceProvider);
    return NfcWriterNotifier(service);
  },
);
