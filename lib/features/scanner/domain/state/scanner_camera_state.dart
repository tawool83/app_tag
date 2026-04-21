import 'package:flutter/foundation.dart';

@immutable
class ScannerCameraState {
  final bool isActive;
  final bool flashOn;
  final String permissionStatus; // 'granted' | 'denied' | 'permanentlyDenied' | 'undetermined'
  final String? errorMessage;

  const ScannerCameraState({
    this.isActive = false,
    this.flashOn = false,
    this.permissionStatus = 'undetermined',
    this.errorMessage,
  });

  ScannerCameraState copyWith({
    bool? isActive,
    bool? flashOn,
    String? permissionStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) =>
      ScannerCameraState(
        isActive: isActive ?? this.isActive,
        flashOn: flashOn ?? this.flashOn,
        permissionStatus: permissionStatus ?? this.permissionStatus,
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerCameraState &&
          other.isActive == isActive &&
          other.flashOn == flashOn &&
          other.permissionStatus == permissionStatus &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(isActive, flashOn, permissionStatus, errorMessage);
}
