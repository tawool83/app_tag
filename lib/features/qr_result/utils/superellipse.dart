import 'dart:math';
import 'dart:ui';

import '../domain/entities/qr_shape_params.dart';

/// Superellipse |x/a|^n + |y/b|^n = 1 Path 생성 + Eye 전용 렌더러.
class SuperellipsePath {
  SuperellipsePath._();

  /// Superellipse path ([n]=2 원, =4 squircle, ≈20 사각). [rotation] 은 각도(도).
  static Path buildPath(Rect rect, double n, {double rotation = 0.0}) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final a = rect.width / 2;
    final b = rect.height / 2;
    final rot = rotation * pi / 180;
    final exp = 2.0 / n;

    final path = Path();
    const steps = 100;
    for (int i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * pi;
      final cosT = cos(t);
      final sinT = sin(t);
      var x = a * cosT.sign * pow(cosT.abs(), exp);
      var y = b * sinT.sign * pow(sinT.abs(), exp);
      if (rot != 0) {
        final rx = x * cos(rot) - y * sin(rot);
        final ry = x * sin(rot) + y * cos(rot);
        x = rx;
        y = ry;
      }
      final px = cx + x;
      final py = cy + y;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    return path;
  }

  /// 눈(finder pattern) 렌더러.
  ///
  /// 구조:
  ///   - 외곽 ring: 4 모서리 독립 RRect (cornerQ1~Q4)
  ///     cornerValue 0.0 → 완전 둥근 (radius = bounds/2)
  ///     cornerValue 1.0 → 완전 각진 (radius = 0)
  ///   - 내부 fill: uniform superellipse (innerN)
  ///
  /// [rotationDeg] 적용 시 canvas 를 중심점 기준 회전. finder 위치별 ±90° 적용용.
  static void paintEye(
    Canvas canvas,
    Rect bounds,
    EyeShapeParams params,
    Paint paint, {
    double rotationDeg = 0.0,
  }) {
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;

    // ── 1. 회전 적용 (중심점 기준) ──
    canvas.save();
    if (rotationDeg != 0.0) {
      canvas.translate(cx, cy);
      canvas.rotate(rotationDeg * pi / 180);
      canvas.translate(-cx, -cy);
    }

    final m = bounds.width / 7; // QR 스펙: finder = 7 모듈
    final outerMaxR = bounds.width / 2;

    // ── 2. 외곽 ring: RRect per-corner (evenOdd fill 로 1모듈 구멍) ──
    //    radius = (1 - cornerValue) × maxR  →  cornerValue 낮을수록 둥글다
    final outerRRect = RRect.fromRectAndCorners(
      bounds,
      topLeft:     Radius.circular((1.0 - params.cornerQ2) * outerMaxR),
      topRight:    Radius.circular((1.0 - params.cornerQ1) * outerMaxR),
      bottomLeft:  Radius.circular((1.0 - params.cornerQ3) * outerMaxR),
      bottomRight: Radius.circular((1.0 - params.cornerQ4) * outerMaxR),
    );
    final holeRect = bounds.deflate(m);
    final holeMaxR = holeRect.width / 2;
    final holeRRect = RRect.fromRectAndCorners(
      holeRect,
      topLeft:     Radius.circular((1.0 - params.cornerQ2) * holeMaxR),
      topRight:    Radius.circular((1.0 - params.cornerQ1) * holeMaxR),
      bottomLeft:  Radius.circular((1.0 - params.cornerQ3) * holeMaxR),
      bottomRight: Radius.circular((1.0 - params.cornerQ4) * holeMaxR),
    );
    final ringPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outerRRect)
      ..addRRect(holeRRect);
    canvas.drawPath(ringPath, paint);

    // ── 3. 내부 fill: uniform superellipse (innerN) ──
    final innerRect = bounds.deflate(m * 2);
    canvas.drawPath(buildPath(innerRect, params.innerN), paint);

    canvas.restore();
  }
}
