import 'dart:ui';

enum QrModuleType { finder, separator, timing, alignment, formatInfo, versionInfo, data }

/// QR 스펙 기반 모듈 영역 분류기.
class QrMatrixHelper {
  final int moduleCount;
  final int typeNumber; // QR 버전 (1~40)

  QrMatrixHelper({required this.moduleCount, required this.typeNumber});

  QrModuleType classify(int row, int col) {
    if (_isFinderRegion(row, col)) return QrModuleType.finder;
    if (_isSeparator(row, col)) return QrModuleType.separator;
    if (_isTiming(row, col)) return QrModuleType.timing;
    if (_isAlignment(row, col)) return QrModuleType.alignment;
    if (_isFormatInfo(row, col)) return QrModuleType.formatInfo;
    if (typeNumber >= 7 && _isVersionInfo(row, col)) {
      return QrModuleType.versionInfo;
    }
    return QrModuleType.data;
  }

  bool isAnimatable(int row, int col) => classify(row, col) == QrModuleType.data;

  bool isProtected(int row, int col) => classify(row, col) != QrModuleType.data;

  /// Finder pattern 3개의 7x7 bounding box.
  List<Rect> finderBounds(double moduleSize, Offset origin) {
    final m = moduleSize;
    return [
      Rect.fromLTWH(origin.dx, origin.dy, 7 * m, 7 * m), // top-left
      Rect.fromLTWH(
        origin.dx + (moduleCount - 7) * m, origin.dy, 7 * m, 7 * m,
      ), // top-right
      Rect.fromLTWH(
        origin.dx, origin.dy + (moduleCount - 7) * m, 7 * m, 7 * m,
      ), // bottom-left
    ];
  }

  // ── private helpers ──

  bool _isFinderRegion(int r, int c) {
    return (r < 7 && c < 7) ||
        (r < 7 && c >= moduleCount - 7) ||
        (r >= moduleCount - 7 && c < 7);
  }

  bool _isSeparator(int r, int c) {
    return (r == 7 && c < 8) ||
        (r < 8 && c == 7) ||
        (r == 7 && c >= moduleCount - 8) ||
        (r < 8 && c == moduleCount - 8) ||
        (r == moduleCount - 8 && c < 8) ||
        (r >= moduleCount - 8 && c == 7);
  }

  bool _isTiming(int r, int c) {
    return (r == 6 && c >= 8 && c < moduleCount - 8) ||
        (c == 6 && r >= 8 && r < moduleCount - 8);
  }

  bool _isAlignment(int r, int c) {
    final positions = _alignmentPositions[typeNumber];
    if (positions == null) return false;
    for (final pr in positions) {
      for (final pc in positions) {
        if (_isFinderRegion(pr, pc)) continue;
        if (r >= pr - 2 && r <= pr + 2 && c >= pc - 2 && c <= pc + 2) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isFormatInfo(int r, int c) {
    return (r == 8 && (c < 9 || c >= moduleCount - 8)) ||
        (c == 8 && (r < 9 || r >= moduleCount - 8));
  }

  bool _isVersionInfo(int r, int c) {
    return (r < 6 && c >= moduleCount - 11 && c < moduleCount - 8) ||
        (c < 6 && r >= moduleCount - 11 && r < moduleCount - 8);
  }

  // QR 스펙: 버전별 alignment pattern 중심 좌표
  static const _alignmentPositions = <int, List<int>>{
    2: [6, 18],
    3: [6, 22],
    4: [6, 26],
    5: [6, 30],
    6: [6, 34],
    7: [6, 22, 38],
    8: [6, 24, 42],
    9: [6, 26, 46],
    10: [6, 28, 50],
    11: [6, 30, 54],
    12: [6, 32, 58],
    13: [6, 34, 62],
    14: [6, 26, 46, 66],
    15: [6, 26, 48, 70],
    16: [6, 26, 50, 74],
    17: [6, 30, 54, 78],
    18: [6, 30, 56, 82],
    19: [6, 30, 58, 86],
    20: [6, 34, 62, 90],
    21: [6, 28, 50, 72, 94],
    22: [6, 26, 50, 74, 98],
    23: [6, 30, 54, 78, 102],
    24: [6, 28, 54, 80, 106],
    25: [6, 32, 58, 84, 110],
    26: [6, 30, 58, 86, 114],
    27: [6, 34, 62, 90, 118],
    28: [6, 26, 50, 74, 98, 122],
    29: [6, 30, 54, 78, 102, 126],
    30: [6, 26, 52, 78, 104, 130],
    31: [6, 30, 56, 82, 108, 134],
    32: [6, 34, 60, 86, 112, 138],
    33: [6, 30, 58, 86, 114, 142],
    34: [6, 34, 62, 90, 118, 146],
    35: [6, 30, 54, 78, 102, 126, 150],
    36: [6, 24, 50, 76, 102, 128, 154],
    37: [6, 28, 54, 80, 106, 132, 158],
    38: [6, 32, 58, 84, 110, 136, 162],
    39: [6, 26, 54, 82, 110, 138, 166],
    40: [6, 30, 58, 86, 114, 142, 170],
  };
}
