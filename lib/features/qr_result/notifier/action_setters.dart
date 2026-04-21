part of '../qr_result_provider.dart';

/// 액션(capture/save/share/print) 관련 setter.
/// `_ref`, `_schedulePush`, `_disposed` 등 private 멤버는 `part of`로 공유됨.
mixin _ActionSetters on StateNotifier<QrResultState> {
  Ref get _ref;

  void setCapturedImage(Uint8List bytes) {
    state = state.copyWith(action: state.action.copyWith(capturedImage: bytes));
  }

  Future<void> saveToGallery(String appName) async {
    if (state.action.capturedImage == null) return;
    state = state.copyWith(
      action: state.action.copyWith(saveStatus: QrActionStatus.loading),
    );
    final result = await _ref
        .read(saveQrToGalleryUseCaseProvider)(state.action.capturedImage!, appName);
    result.fold(
      (success) => state = state.copyWith(
        action: state.action.copyWith(
          saveStatus: success ? QrActionStatus.success : QrActionStatus.error,
          errorMessage: success ? null : '이미지 저장에 실패했습니다.',
          clearError: success,
        ),
      ),
      (_) => state = state.copyWith(
        action: state.action.copyWith(
          saveStatus: QrActionStatus.error,
          errorMessage: '이미지 저장에 실패했습니다.',
        ),
      ),
    );
  }

  Future<void> shareImage(String appName) async {
    if (state.action.capturedImage == null) return;
    state = state.copyWith(
      action: state.action.copyWith(shareStatus: QrActionStatus.loading),
    );
    final result = await _ref
        .read(shareQrImageUseCaseProvider)(state.action.capturedImage!, appName);
    result.fold(
      (_) => state = state.copyWith(
        action: state.action.copyWith(shareStatus: QrActionStatus.success),
      ),
      (_) => state = state.copyWith(
        action: state.action.copyWith(shareStatus: QrActionStatus.error),
      ),
    );
  }

  Future<void> printQrCode(String appName, {double? sizeCm}) async {
    if (state.action.capturedImage == null) return;
    state = state.copyWith(
      action: state.action.copyWith(printStatus: QrActionStatus.loading),
    );
    final result = await _ref.read(printQrCodeUseCaseProvider)(
      imageBytes: state.action.capturedImage!,
      appName: appName,
      sizeCm: sizeCm ?? state.meta.printSizeCm,
    );
    result.fold(
      (_) => state = state.copyWith(
        action: state.action.copyWith(printStatus: QrActionStatus.success),
      ),
      (_) => state = state.copyWith(
        action: state.action.copyWith(
          printStatus: QrActionStatus.error,
          errorMessage: '인쇄에 실패했습니다. 프린터 연결을 확인해주세요.',
        ),
      ),
    );
  }
}
