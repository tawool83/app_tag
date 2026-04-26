import 'dart:ui';

/// [source] Path 를 [dashArray] 패턴으로 변환.
///
/// [dashArray] 는 `[on, off, on, off, ...]` 반복 패턴.
/// 예: `[8, 4]` → 8px 선, 4px 간격.
Path dashPath(Path source, List<double> dashArray) {
  final result = Path();
  if (dashArray.isEmpty) return result;

  for (final metric in source.computeMetrics()) {
    double distance = 0.0;
    int idx = 0;
    bool draw = true;

    while (distance < metric.length) {
      final len = dashArray[idx % dashArray.length];
      final next = (distance + len).clamp(0.0, metric.length);
      if (draw) {
        result.addPath(metric.extractPath(distance, next), Offset.zero);
      }
      distance = next;
      idx++;
      draw = !draw;
    }
  }
  return result;
}
