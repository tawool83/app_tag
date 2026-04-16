import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/result.dart';
import 'presentation/providers/nfc_writer_providers.dart';

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
  final Ref _ref;

  NfcWriterNotifier(this._ref) : super(const NfcWriterState());

  /// Read-Merge-Write via UseCase. Blocks until tag is found and written.
  /// UseCase를 통한 읽기-병합-쓰기. 태그 발견 및 기록 완료까지 대기.
  Future<void> startWrite({
    required String deepLink,
    String? iosShortcutName,
  }) async {
    state = state.copyWith(status: NfcWriteStatus.waiting);

    final result = await _ref.read(writeNfcTagUseCaseProvider)(
      deepLink: deepLink,
      iosShortcutName: iosShortcutName,
    );

    if (!mounted) return;

    result.fold(
      (writeResult) => state = state.copyWith(
        status: NfcWriteStatus.success,
        hasCrossPlatformRecord: writeResult.hasCrossPlatformRecord,
      ),
      (failure) => state = state.copyWith(
        status: NfcWriteStatus.error,
        errorMessage: failure.message,
      ),
    );
  }

  void reset() {
    state = const NfcWriterState();
  }

  @override
  void dispose() {
    _ref.read(nfcRepositoryProvider).stopSession();
    super.dispose();
  }
}

final nfcWriterProvider =
    StateNotifierProvider.autoDispose<NfcWriterNotifier, NfcWriterState>(
  (ref) => NfcWriterNotifier(ref),
);
