import 'package:flutter/foundation.dart';

import '../entities/scan_result.dart';

@immutable
class ScannerResultState {
  final ScanResult? currentResult;
  final bool sheetVisible;

  const ScannerResultState({
    this.currentResult,
    this.sheetVisible = false,
  });

  ScannerResultState copyWith({
    ScanResult? currentResult,
    bool? sheetVisible,
    bool clearCurrentResult = false,
  }) =>
      ScannerResultState(
        currentResult: clearCurrentResult
            ? null
            : (currentResult ?? this.currentResult),
        sheetVisible: sheetVisible ?? this.sheetVisible,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerResultState &&
          other.currentResult == currentResult &&
          other.sheetVisible == sheetVisible;

  @override
  int get hashCode => Object.hash(currentResult, sheetVisible);
}
