import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/qr_service.dart';
import '../../services/history_service.dart';

final qrServiceProvider = Provider<QrService>((ref) => QrService());
final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());

enum QrActionStatus { idle, loading, success, error }

class QrResultState {
  final Uint8List? capturedImage;
  final QrActionStatus saveStatus;
  final QrActionStatus shareStatus;
  final QrActionStatus printStatus;
  final String? errorMessage;

  const QrResultState({
    this.capturedImage,
    this.saveStatus = QrActionStatus.idle,
    this.shareStatus = QrActionStatus.idle,
    this.printStatus = QrActionStatus.idle,
    this.errorMessage,
  });

  QrResultState copyWith({
    Uint8List? capturedImage,
    QrActionStatus? saveStatus,
    QrActionStatus? shareStatus,
    QrActionStatus? printStatus,
    String? errorMessage,
  }) =>
      QrResultState(
        capturedImage: capturedImage ?? this.capturedImage,
        saveStatus: saveStatus ?? this.saveStatus,
        shareStatus: shareStatus ?? this.shareStatus,
        printStatus: printStatus ?? this.printStatus,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class QrResultNotifier extends StateNotifier<QrResultState> {
  final QrService _qrService;

  QrResultNotifier(this._qrService) : super(const QrResultState());

  void setCapturedImage(Uint8List bytes) {
    state = state.copyWith(capturedImage: bytes);
  }

  Future<void> saveToGallery(String appName) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(saveStatus: QrActionStatus.loading);
    try {
      final success =
          await _qrService.saveToGallery(state.capturedImage!, appName);
      state = state.copyWith(
        saveStatus: success ? QrActionStatus.success : QrActionStatus.error,
        errorMessage: success ? null : '이미지 저장에 실패했습니다.',
      );
    } catch (_) {
      state = state.copyWith(
        saveStatus: QrActionStatus.error,
        errorMessage: '이미지 저장에 실패했습니다.',
      );
    }
  }

  Future<void> shareImage(String appName) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(shareStatus: QrActionStatus.loading);
    try {
      await _qrService.shareImage(state.capturedImage!, appName);
      state = state.copyWith(shareStatus: QrActionStatus.success);
    } catch (_) {
      state = state.copyWith(shareStatus: QrActionStatus.error);
    }
  }

  Future<void> printQrCode(String appName) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(printStatus: QrActionStatus.loading);
    try {
      await _qrService.printQrCode(
        imageBytes: state.capturedImage!,
        appName: appName,
      );
      state = state.copyWith(printStatus: QrActionStatus.success);
    } catch (_) {
      state = state.copyWith(
        printStatus: QrActionStatus.error,
        errorMessage: '인쇄에 실패했습니다. 프린터 연결을 확인해주세요.',
      );
    }
  }
}

final qrResultProvider =
    StateNotifierProvider.autoDispose<QrResultNotifier, QrResultState>(
  (ref) => QrResultNotifier(ref.read(qrServiceProvider)),
);
