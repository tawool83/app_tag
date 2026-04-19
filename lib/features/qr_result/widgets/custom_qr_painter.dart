import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:qr/qr.dart';

import '../domain/entities/qr_animation_params.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_shape_params.dart';
import '../utils/polar_polygon.dart';
import '../utils/qr_animation_engine.dart';
import '../utils/qr_boundary_clipper.dart';
import '../utils/qr_matrix_helper.dart';
import '../utils/superellipse.dart';

/// CustomPainter 기반 QR 통합 렌더러.
///
/// 도트(PolarPolygon) + 눈(Superellipse) + 외곽 클리핑(Boundary)
/// + 데이터 영역 애니메이션을 단일 paint() 에서 처리.
class CustomQrPainter extends CustomPainter {
  final QrImage qrImage;
  final Color color;
  final DotShapeParams dotParams;
  final EyeShapeParams eyeParams;
  final QrBoundaryParams boundaryParams;
  final QrAnimationParams animParams;
  final double animValue; // 0.0~1.0 from AnimationController
  final ui.Gradient? gradient; // non-null이면 그라디언트 렌더링

  late final QrMatrixHelper _helper;

  CustomQrPainter({
    required this.qrImage,
    required this.color,
    this.dotParams = const DotShapeParams(),
    this.eyeParams = const EyeShapeParams(),
    this.boundaryParams = const QrBoundaryParams(),
    this.animParams = const QrAnimationParams(),
    this.animValue = 0.0,
    this.gradient,
  }) {
    _helper = QrMatrixHelper(
      moduleCount: qrImage.moduleCount,
      typeNumber: qrImage.typeNumber,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = qrImage.moduleCount;
    final m = size.width / n;
    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (gradient != null) {
      basePaint.shader = gradient;
    } else {
      basePaint.color = color;
    }

    // 0. 외곽 클리핑
    canvas.save();
    QrBoundaryClipper.applyClip(canvas, size, boundaryParams);

    // 1. Finder Pattern (3개 코너 7x7)
    for (final bounds in _helper.finderBounds(m, Offset.zero)) {
      SuperellipsePath.paintEye(canvas, bounds, eyeParams, basePaint);
    }

    // 2. 데이터 + timing + alignment 도트
    for (int row = 0; row < n; row++) {
      for (int col = 0; col < n; col++) {
        if (!qrImage.isDark(row, col)) continue;

        final moduleType = _helper.classify(row, col);
        // finder는 위에서 렌더링, separator는 항상 white(isDark=false이므로 도달 안 함)
        if (moduleType == QrModuleType.finder ||
            moduleType == QrModuleType.separator) {
          continue;
        }

        final center = Offset(col * m + m / 2, row * m + m / 2);
        final radius = m / 2;

        // 타이밍/정렬/포맷/버전 패턴은 QR 스펙 유지를 위해 표준 사각형으로 렌더링
        final isStructural = moduleType == QrModuleType.timing ||
            moduleType == QrModuleType.alignment ||
            moduleType == QrModuleType.formatInfo ||
            moduleType == QrModuleType.versionInfo;

        // 애니메이션 (데이터 영역만)
        final frame = !isStructural && _helper.isAnimatable(row, col)
            ? QrAnimationEngine.compute(animParams, animValue, row, col, n)
            : DotAnimFrame.identity;

        canvas.save();

        // 회전 변형
        if (frame.rotationRad != 0) {
          canvas.translate(center.dx, center.dy);
          canvas.rotate(frame.rotationRad);
          canvas.translate(-center.dx, -center.dy);
        }

        // 페인트 (hueShift, opacity)
        final dotPaint = Paint()
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        if (gradient != null) {
          dotPaint.shader = gradient;
          if (frame.opacity < 1.0) {
            dotPaint.color = ui.Color.fromARGB(
              (frame.opacity * 255).round(), 255, 255, 255,
            );
          }
        } else {
          dotPaint.color = _applyHueShift(color, frame.hueShift)
              .withValues(alpha: frame.opacity);
        }

        if (isStructural) {
          // 타이밍/정렬 패턴: 표준 사각형으로 렌더링 (QR 인식률 보장)
          canvas.drawRect(
            Rect.fromCenter(center: center, width: m, height: m),
            dotPaint,
          );
        } else {
          final dotPath = PolarPolygon.buildPath(
            center, radius * frame.scale, dotParams,
          );
          canvas.drawPath(dotPath, dotPaint);
        }
        canvas.restore();
      }
    }

    // 3. 외곽 클리핑 복원
    canvas.restore();
  }

  Color _applyHueShift(Color base, double shift) {
    if (shift == 0) return base;
    final hsv = HSVColor.fromColor(base);
    return hsv.withHue((hsv.hue + shift * 360) % 360).toColor();
  }

  @override
  bool shouldRepaint(CustomQrPainter old) =>
      qrImage != old.qrImage ||
      color != old.color ||
      dotParams != old.dotParams ||
      eyeParams != old.eyeParams ||
      boundaryParams != old.boundaryParams ||
      animParams != old.animParams ||
      animValue != old.animValue ||
      gradient != old.gradient;
}
