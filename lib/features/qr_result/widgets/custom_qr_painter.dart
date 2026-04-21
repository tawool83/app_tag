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

  // 애니메이션과 무관한 dark 모듈을 구조(structural)/데이터(data) 두 그룹으로 분류 →
  // 구조 모듈은 매 paint 마다 classify 반복하지 않고 사전 계산한 좌표를 재사용.
  late final List<_ModuleCell> _structuralCells;
  late final List<_ModuleCell> _dataCells;

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
    final structural = <_ModuleCell>[];
    final data = <_ModuleCell>[];
    final n = qrImage.moduleCount;
    for (int row = 0; row < n; row++) {
      for (int col = 0; col < n; col++) {
        if (!qrImage.isDark(row, col)) continue;
        final moduleType = _helper.classify(row, col);
        if (moduleType == QrModuleType.finder ||
            moduleType == QrModuleType.separator) {
          continue;
        }
        final isStructural = moduleType == QrModuleType.timing ||
            moduleType == QrModuleType.alignment ||
            moduleType == QrModuleType.formatInfo ||
            moduleType == QrModuleType.versionInfo;
        final cell = _ModuleCell(row, col);
        if (isStructural) {
          structural.add(cell);
        } else {
          data.add(cell);
        }
      }
    }
    _structuralCells = structural;
    _dataCells = data;
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

    // 2a. 구조(timing/alignment/formatInfo/versionInfo) 모듈 — 애니메이션 없음, 단일 Paint 재사용.
    if (_structuralCells.isNotEmpty) {
      final structPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      if (gradient != null) {
        structPaint.shader = gradient;
      } else {
        structPaint.color = color;
      }
      for (final cell in _structuralCells) {
        final center = Offset(cell.col * m + m / 2, cell.row * m + m / 2);
        canvas.drawRect(
          Rect.fromCenter(center: center, width: m, height: m),
          structPaint,
        );
      }
    }

    // 2b. 데이터 모듈 — 애니메이션/회전/hueShift 적용.
    final radius = m / 2;
    for (final cell in _dataCells) {
      final center = Offset(cell.col * m + m / 2, cell.row * m + m / 2);
      final frame = _helper.isAnimatable(cell.row, cell.col)
          ? QrAnimationEngine.compute(animParams, animValue, cell.row, cell.col, n)
          : DotAnimFrame.identity;

      canvas.save();
      if (frame.rotationRad != 0) {
        canvas.translate(center.dx, center.dy);
        canvas.rotate(frame.rotationRad);
        canvas.translate(-center.dx, -center.dy);
      }

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

      final dotPath = PolarPolygon.buildPath(
        center, radius * frame.scale * dotParams.scale, dotParams,
      );
      canvas.drawPath(dotPath, dotPaint);
      canvas.restore();
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

class _ModuleCell {
  final int row;
  final int col;
  const _ModuleCell(this.row, this.col);
}
