part of '../scanner_provider.dart';

mixin _CameraSetters on StateNotifier<ScannerState> {
  Future<void> checkPermission() async {
    final status = await Permission.camera.status;
    state = state.copyWith(
      camera: state.camera.copyWith(
        permissionStatus: status.name,
        isActive: status.isGranted,
      ),
    );
  }

  Future<void> requestPermission() async {
    final status = await Permission.camera.request();
    state = state.copyWith(
      camera: state.camera.copyWith(
        permissionStatus: status.name,
        isActive: status.isGranted,
      ),
    );
  }

  void toggleFlash() {
    state = state.copyWith(
      camera: state.camera.copyWith(flashOn: !state.camera.flashOn),
    );
  }

  void setCameraError(String message) {
    state = state.copyWith(
      camera: state.camera.copyWith(errorMessage: message, isActive: false),
    );
  }

  void setCameraActive(bool active) {
    state = state.copyWith(
      camera: state.camera.copyWith(isActive: active),
    );
  }
}
