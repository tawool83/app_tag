import 'package:flutter/rendering.dart';

import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_margin_pattern.dart';
import '../domain/entities/qr_shape_params.dart';
import '../utils/qr_boundary_clipper.dart';
import '../utils/qr_margin_painter.dart';

/// 장식 프레임 + 마진 패턴 렌더러.
///
/// 프레임 모양으로 clip → 배경 fill → QR 영역 제외한 마진에 패턴 렌더.
/// [qrAreaSize] 는 QR 코드 + quiet zone 을 포함한 내부 정사각형 크기.
class DecorativeFramePainter extends CustomPainter {
  final QrBoundaryParams boundaryParams;
  final double qrAreaSize;
  final Color frameColor;
  final Color patternColor;
  final DotShapeParams? dotParams;

  const DecorativeFramePainter({
    required this.boundaryParams,
    required this.qrAreaSize,
    required this.frameColor,
    required this.patternColor,
    this.dotParams,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 프레임 Path 생성 (기존 QrBoundaryClipper 재활용)
    final framePath = QrBoundaryClipper.buildClipPath(size, boundaryParams);
    if (framePath == null) return; // square = 프레임 없음

    // 1. 프레임 모양 외부를 투명하게 clip
    canvas.save();
    canvas.clipPath(framePath);

    // 2. 프레임 내부 배경 fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = frameColor,
    );

    // 3. 마진에 패턴 렌더 (QR 영역 제외)
    if (boundaryParams.marginPattern != QrMarginPattern.none) {
      final center = size.center(Offset.zero);
      final qrRect = Rect.fromCenter(
        center: center,
        width: qrAreaSize,
        height: qrAreaSize,
      );
      // 마진 = framePath - qrRect (차집합)
      final qrPath = Path()..addRect(qrRect);
      final marginClip = Path.combine(
        PathOperation.difference,
        framePath,
        qrPath,
      );
      canvas.save();
      canvas.clipPath(marginClip);
      _drawPattern(canvas, size);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawPattern(Canvas canvas, Size size) {
    final density = boundaryParams.patternDensity;
    switch (boundaryParams.marginPattern) {
      case QrMarginPattern.none:
        return;
      case QrMarginPattern.qrDots:
        QrMarginPatternEngine.drawQrDots(
          canvas, size, patternColor, dotParams, density,
        );
      case QrMarginPattern.maze:
        QrMarginPatternEngine.drawMaze(canvas, size, patternColor, density);
      case QrMarginPattern.zigzag:
        QrMarginPatternEngine.drawZigzag(canvas, size, patternColor, density);
      case QrMarginPattern.wave:
        QrMarginPatternEngine.drawWave(canvas, size, patternColor, density);
      case QrMarginPattern.grid:
        QrMarginPatternEngine.drawGrid(canvas, size, patternColor, density);
    }
  }

  @override
  bool shouldRepaint(DecorativeFramePainter old) =>
      boundaryParams != old.boundaryParams ||
      qrAreaSize != old.qrAreaSize ||
      frameColor != old.frameColor ||
      patternColor != old.patternColor ||
      dotParams != old.dotParams;
}
