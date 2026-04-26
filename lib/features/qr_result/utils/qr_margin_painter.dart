import 'dart:math';
import 'dart:ui';

import '../domain/entities/qr_shape_params.dart';
import 'polar_polygon.dart';

/// 마진 영역 장식 패턴 렌더 엔진. 모든 메서드는 static, 순수 함수.
///
/// canvas 는 호출자가 이미 마진 영역으로 clip 한 상태에서 호출한다.
/// 따라서 각 메서드는 size 전체를 대상으로 그리면 마진에만 표시된다.
class QrMarginPatternEngine {
  QrMarginPatternEngine._();

  /// QR 도트 패턴: 실제 QR 코드 데이터 영역처럼 보이는 무작위 on/off 그리드.
  ///
  /// 고정 시드 RNG 로 ~50% 셀만 그려 실제 QR 모듈과 유사한 무작위 느낌을 낸다.
  static void drawQrDots(
    Canvas canvas,
    Size size,
    Color color,
    DotShapeParams? dotParams,
    double density, {
    Shader? shader,
  }) {
    final dp = dotParams ?? const DotShapeParams();
    final spacing = (size.width * 0.04 / density).clamp(4.0, 16.0);
    final radius = spacing * 0.35;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (shader != null) paint.shader = shader;

    final cols = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();
    final rng = _seededRng(cols * rows);

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        if (!rng.nextBool()) continue; // ~50% 확률로 skip → 무작위 QR 느낌
        final center = Offset(x, y);
        final path = PolarPolygon.buildPath(center, radius * dp.scale, dp);
        canvas.drawPath(path, paint);
      }
    }
  }

  /// 미로 패턴: 시드 고정 대각선 교차 패턴.
  static void drawMaze(
    Canvas canvas,
    Size size,
    Color color,
    double density, {
    Shader? shader,
  }) {
    final cellSize = (size.width * 0.05 / density).clamp(6.0, 20.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    if (shader != null) paint.shader = shader;
    final cols = (size.width / cellSize).floor();
    final rows = (size.height / cellSize).floor();
    final rng = _seededRng(cols * rows);
    final path = Path();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * cellSize;
        final y = r * cellSize;
        if (rng.nextBool()) {
          path.moveTo(x, y);
          path.lineTo(x + cellSize, y + cellSize);
        } else {
          path.moveTo(x + cellSize, y);
          path.lineTo(x, y + cellSize);
        }
      }
    }
    canvas.drawPath(path, paint);
  }

  /// 지그재그 선 패턴.
  static void drawZigzag(
    Canvas canvas,
    Size size,
    Color color,
    double density, {
    Shader? shader,
  }) {
    final spacing = (size.width * 0.06 / density).clamp(6.0, 20.0);
    final amp = spacing * 0.4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    if (shader != null) paint.shader = shader;
    final path = Path();
    for (double y = 0; y < size.height; y += spacing) {
      path.moveTo(0, y);
      bool up = true;
      for (double x = 0; x < size.width; x += amp) {
        final yOff = up ? y : y + amp;
        path.lineTo(x + amp, yOff);
        up = !up;
      }
    }
    canvas.drawPath(path, paint);
  }

  /// 사인 곡선 물결 패턴.
  static void drawWave(
    Canvas canvas,
    Size size,
    Color color,
    double density, {
    Shader? shader,
  }) {
    final spacing = (size.width * 0.06 / density).clamp(8.0, 24.0);
    final amp = spacing * 0.3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    if (shader != null) paint.shader = shader;
    final path = Path();
    for (double y = spacing; y < size.height; y += spacing) {
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 2) {
        path.lineTo(x, y + amp * sin(x / spacing * 2 * pi));
      }
    }
    canvas.drawPath(path, paint);
  }

  /// 격자 점 패턴.
  static void drawGrid(
    Canvas canvas,
    Size size,
    Color color,
    double density, {
    Shader? shader,
  }) {
    final spacing = (size.width * 0.05 / density).clamp(6.0, 18.0);
    final dotR = spacing * 0.12;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (shader != null) paint.shader = shader;
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, paint);
      }
    }
  }

  static Random _seededRng(int seed) => Random(seed.hashCode ^ 0xDEADBEEF);
}
