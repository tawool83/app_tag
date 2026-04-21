library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../scan_history/scan_history_provider.dart';
import 'domain/parser/scan_payload_parser.dart';
import 'domain/state/scanner_camera_state.dart';
import 'domain/state/scanner_result_state.dart';

part 'notifier/camera_setters.dart';
part 'notifier/result_setters.dart';

class ScannerState {
  final ScannerCameraState camera;
  final ScannerResultState result;

  const ScannerState({
    this.camera = const ScannerCameraState(),
    this.result = const ScannerResultState(),
  });

  ScannerState copyWith({
    ScannerCameraState? camera,
    ScannerResultState? result,
  }) =>
      ScannerState(
        camera: camera ?? this.camera,
        result: result ?? this.result,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerState &&
          other.camera == camera &&
          other.result == result;

  @override
  int get hashCode => Object.hash(camera, result);
}

class ScannerNotifier extends StateNotifier<ScannerState>
    with _CameraSetters, _ResultSetters {
  @override
  final Ref _ref;

  ScannerNotifier(this._ref) : super(const ScannerState());

  Future<void> initialize() async {
    await checkPermission();
  }
}

final scannerProvider =
    StateNotifierProvider.autoDispose<ScannerNotifier, ScannerState>(
  (ref) => ScannerNotifier(ref),
);
