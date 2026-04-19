import 'dart:math';

import '../domain/entities/qr_animation_params.dart';

/// 데이터 영역 도트 애니메이션 계산.
class QrAnimationEngine {
  QrAnimationEngine._();

  /// 도트(row, col)의 애니메이션 변형 계산.
  /// [t] AnimationController value (0.0~1.0), [gridSize] moduleCount.
  static DotAnimFrame compute(
    QrAnimationParams params,
    double t,
    int row,
    int col,
    int gridSize,
  ) {
    if (!params.isAnimated) return DotAnimFrame.identity;

    switch (params.type) {
      case QrAnimationType.wave:
        final phase = (row + col) * params.frequency;
        final raw = sin(t * 2 * pi + phase) * params.amplitude * 0.4 + 0.8;
        return DotAnimFrame(scale: raw.clamp(0.6, 1.2));

      case QrAnimationType.rainbow:
        final hueShift = ((t + col / gridSize) * params.frequency) % 1.0;
        return DotAnimFrame(hueShift: hueShift);

      case QrAnimationType.pulse:
        final raw = sin(t * 2 * pi) * params.amplitude * 0.3 + 0.85;
        return DotAnimFrame(scale: raw.clamp(0.6, 1.2));

      case QrAnimationType.sequential:
        final delay = (row + col * gridSize) / (gridSize * gridSize);
        final raw = ((t * params.speed - delay) * 3).clamp(0.0, 1.0);
        return DotAnimFrame(opacity: raw.clamp(0.5, 1.0));

      case QrAnimationType.rotationWave:
        final dist = sqrt(
          pow(row - gridSize / 2, 2) + pow(col - gridSize / 2, 2),
        );
        final rot =
            sin(t * 2 * pi + dist * params.frequency) * params.amplitude * pi / 4;
        return DotAnimFrame(rotationRad: rot);

      case QrAnimationType.none:
        return DotAnimFrame.identity;
    }
  }
}
