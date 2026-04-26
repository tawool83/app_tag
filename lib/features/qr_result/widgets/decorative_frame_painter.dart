import 'package:flutter/rendering.dart';

import '../domain/entities/qr_border_style.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_margin_pattern.dart';
import '../domain/entities/qr_shape_params.dart';
import '../utils/dash_path_util.dart';
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
  final Shader? patternShader;
  final Color borderColor;
  final Shader? borderShader;
  final DotShapeParams? dotParams;

  const DecorativeFramePainter({
    required this.boundaryParams,
    required this.qrAreaSize,
    required this.frameColor,
    required this.patternColor,
    this.patternShader,
    required this.borderColor,
    this.borderShader,
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

    // ── 외곽선 stroke ──
    _drawBorder(canvas, size, framePath);
  }

  void _drawBorder(Canvas canvas, Size size, Path framePath) {
    final style = boundaryParams.borderStyle;
    if (style == QrBorderStyle.none) return;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = boundaryParams.borderWidth
      ..isAntiAlias = true;
    if (borderShader != null) borderPaint.shader = borderShader;

    switch (style) {
      case QrBorderStyle.solid:
        canvas.drawPath(framePath, borderPaint);
      case QrBorderStyle.dashed:
        canvas.drawPath(dashPath(framePath, [8, 4]), borderPaint);
      case QrBorderStyle.dotted:
        borderPaint.strokeCap = StrokeCap.round;
        canvas.drawPath(dashPath(framePath, [2, 3]), borderPaint);
      case QrBorderStyle.dashDot:
        canvas.drawPath(dashPath(framePath, [8, 4, 2, 4]), borderPaint);
      case QrBorderStyle.double_:
        final w = boundaryParams.borderWidth * 0.4;
        borderPaint.strokeWidth = w;
        canvas.drawPath(framePath, borderPaint);
        final scale = 1.0 - (boundaryParams.borderWidth * 3 / size.width);
        final cx = size.width / 2;
        final cy = size.height / 2;
        // ignore: deprecated_member_use
        final matrix = Matrix4.identity()
          ..translate(cx, cy) // ignore: deprecated_member_use
          ..scale(scale, scale) // ignore: deprecated_member_use
          ..translate(-cx, -cy);
        canvas.drawPath(framePath.transform(matrix.storage), borderPaint);
      case QrBorderStyle.none:
        break;
    }
  }

  void _drawPattern(Canvas canvas, Size size) {
    final density = boundaryParams.patternDensity;
    final s = patternShader;
    switch (boundaryParams.marginPattern) {
      case QrMarginPattern.none:
        return;
      case QrMarginPattern.qrDots:
        QrMarginPatternEngine.drawQrDots(
          canvas, size, patternColor, dotParams, density,
          shader: s,
        );
      case QrMarginPattern.maze:
        QrMarginPatternEngine.drawMaze(canvas, size, patternColor, density,
            shader: s);
      case QrMarginPattern.zigzag:
        QrMarginPatternEngine.drawZigzag(canvas, size, patternColor, density,
            shader: s);
      case QrMarginPattern.wave:
        QrMarginPatternEngine.drawWave(canvas, size, patternColor, density,
            shader: s);
      case QrMarginPattern.grid:
        QrMarginPatternEngine.drawGrid(canvas, size, patternColor, density,
            shader: s);
    }
  }

  @override
  bool shouldRepaint(DecorativeFramePainter old) =>
      boundaryParams != old.boundaryParams ||
      qrAreaSize != old.qrAreaSize ||
      frameColor != old.frameColor ||
      patternColor != old.patternColor ||
      patternShader != old.patternShader ||
      borderColor != old.borderColor ||
      borderShader != old.borderShader ||
      dotParams != old.dotParams;
}
