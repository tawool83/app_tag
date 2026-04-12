import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/qr_template.dart';

/// 그라디언트 색상을 적용한 QR 코드 CustomPainter.
///
/// 렌더링 순서:
/// 1. saveLayer로 격리 레이어 생성
/// 2. QrPainter로 흑백 QR 도트 렌더링
/// 3. 그라디언트 셰이더를 BlendMode.srcIn으로 덮어씌움
///    → 도트 모양은 유지되고 색상만 그라디언트로 대체됨
class GradientQrPainter extends CustomPainter {
  final String data;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final QrGradient gradient;
  final int errorCorrectionLevel;

  const GradientQrPainter({
    required this.data,
    required this.eyeShape,
    required this.dataModuleShape,
    required this.gradient,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 격리 레이어: srcIn 블렌드가 이 레이어 밖으로 새지 않도록
    canvas.saveLayer(rect, Paint());

    // QR 흑백 렌더링
    QrPainter(
      data: data,
      version: QrVersions.auto,
      eyeStyle: QrEyeStyle(eyeShape: eyeShape, color: Colors.black),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: dataModuleShape,
        color: Colors.black,
      ),
      errorCorrectionLevel: errorCorrectionLevel,
    ).paint(canvas, size);

    // 그라디언트 적용 (도트 형상 마스크로 사용)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = _createShader(rect)
        ..blendMode = BlendMode.srcIn,
    );

    canvas.restore();
  }

  Shader _createShader(Rect rect) {
    switch (gradient.type) {
      case 'radial':
        return RadialGradient(
          colors: gradient.colors,
          stops: gradient.stops,
        ).createShader(rect);

      case 'sweep':
        return SweepGradient(
          colors: gradient.colors,
          stops: gradient.stops,
        ).createShader(rect);

      case 'linear':
      default:
        final angle = gradient.angleDegrees * pi / 180;
        final dx = cos(angle);
        final dy = sin(angle);
        return LinearGradient(
          begin: Alignment(-dx, -dy),
          end: Alignment(dx, dy),
          colors: gradient.colors,
          stops: gradient.stops,
        ).createShader(rect);
    }
  }

  @override
  bool shouldRepaint(GradientQrPainter old) =>
      data != old.data ||
      eyeShape != old.eyeShape ||
      dataModuleShape != old.dataModuleShape ||
      gradient != old.gradient ||
      errorCorrectionLevel != old.errorCorrectionLevel;
}
