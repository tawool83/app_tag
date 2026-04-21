part of '../scanner_provider.dart';

mixin _ResultSetters on StateNotifier<ScannerState> {
  Ref get _ref;

  /// QR 인식 성공 시 호출. 파싱 + 히스토리 저장 + Bottom Sheet 표시.
  Future<void> onBarcodeDetected(String rawValue) async {
    if (state.result.sheetVisible) return;

    final parsed = ScanPayloadParser.parse(rawValue);

    state = state.copyWith(
      result: state.result.copyWith(
        currentResult: parsed,
        sheetVisible: true,
      ),
      camera: state.camera.copyWith(isActive: false),
    );

    // ScanHistory 에 자동 저장
    _ref.read(scanHistoryProvider.notifier).addEntry(
          rawValue: rawValue,
          detectedType: parsed.detectedType,
          parsedMeta: parsed.parsedMeta,
        );
  }

  /// Bottom Sheet 닫힘 시 스캐너 재개.
  void dismissResult() {
    state = state.copyWith(
      result: state.result.copyWith(
        clearCurrentResult: true,
        sheetVisible: false,
      ),
      camera: state.camera.copyWith(isActive: true),
    );
  }
}
