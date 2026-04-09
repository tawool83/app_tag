import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/nfc_service.dart';
import '../app_picker/app_picker_provider.dart';

enum NfcWriteStatus { idle, waiting, success, error }

class NfcWriterState {
  final NfcWriteStatus status;
  final String? errorMessage;

  const NfcWriterState({
    this.status = NfcWriteStatus.idle,
    this.errorMessage,
  });

  NfcWriterState copyWith({
    NfcWriteStatus? status,
    String? errorMessage,
  }) =>
      NfcWriterState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

class NfcWriterNotifier extends StateNotifier<NfcWriterState> {
  final NfcService _nfcService;

  NfcWriterNotifier(this._nfcService) : super(const NfcWriterState());

  void startWrite(String deepLink) {
    state = state.copyWith(status: NfcWriteStatus.waiting);
    _nfcService.writeNdefTag(
      deepLink: deepLink,
      onSuccess: () {
        if (mounted) {
          state = state.copyWith(status: NfcWriteStatus.success);
        }
      },
      onError: (error) {
        if (mounted) {
          state = state.copyWith(
            status: NfcWriteStatus.error,
            errorMessage: error,
          );
        }
      },
    );
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
