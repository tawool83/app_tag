import 'dart:typed_data';

import '../entities/qr_action_status.dart';

export '../entities/qr_action_status.dart' show QrActionStatus;

/// 액션(save/share/print) 비동기 상태 + 에러.
///
/// `errorMessage` null 재설정은 `clearError: true` 플래그로 수행 (sentinel 제거).
class QrActionState {
  final Uint8List? capturedImage;
  final QrActionStatus saveStatus;
  final QrActionStatus shareStatus;
  final QrActionStatus printStatus;
  final String? errorMessage;

  const QrActionState({
    this.capturedImage,
    this.saveStatus = QrActionStatus.idle,
    this.shareStatus = QrActionStatus.idle,
    this.printStatus = QrActionStatus.idle,
    this.errorMessage,
  });

  QrActionState copyWith({
    Uint8List? capturedImage,
    QrActionStatus? saveStatus,
    QrActionStatus? shareStatus,
    QrActionStatus? printStatus,
    String? errorMessage,
    bool clearError = false,
  }) =>
      QrActionState(
        capturedImage: capturedImage ?? this.capturedImage,
        saveStatus: saveStatus ?? this.saveStatus,
        shareStatus: shareStatus ?? this.shareStatus,
        printStatus: printStatus ?? this.printStatus,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrActionState &&
          other.capturedImage == capturedImage &&
          other.saveStatus == saveStatus &&
          other.shareStatus == shareStatus &&
          other.printStatus == printStatus &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
      capturedImage, saveStatus, shareStatus, printStatus, errorMessage);
}
