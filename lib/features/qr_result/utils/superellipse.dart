import 'dart:math';
import 'dart:ui';

import '../domain/entities/qr_shape_params.dart';

/// Superellipse |x/a|^n + |y/b|^n = 1 Path 생성.
class SuperellipsePath {
  SuperellipsePath._();

  /// [rect] bounding rect, [n] 형태 (2=원, 4=squircle, 20≈사각).
  /// [rotation] 회전 각도(도).
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
      // 회전 적용
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

  /// 눈 프레임 렌더링: 외곽 링(evenOdd) + 내부 채움.
  static void paintEye(
    Canvas canvas,
    Rect bounds,
    EyeShapeParams params,
    Paint paint,
  ) {
    final m = bounds.width / 7; // QR 스펙: finder pattern = 7 모듈

    // 외곽 링: 전체 bounds → 1모듈 안쪽 구멍 (evenOdd fill)
    final holeRect = bounds.deflate(m);
    final ringPath = Path()..fillType = PathFillType.evenOdd;
    ringPath.addPath(
      buildPath(bounds, params.outerN, rotation: params.rotation),
      Offset.zero,
    );
    ringPath.addPath(
      buildPath(holeRect, params.outerN, rotation: params.rotation),
      Offset.zero,
    );
    canvas.drawPath(ringPath, paint);

    // 내부 채움 (3/7 비율 기본, innerScale로 조절)
    final innerRect = bounds.deflate(m * 2);
    final scaleFactor = params.innerScale / 0.43; // 기본 비율 대비 스케일
    final innerScaled = Rect.fromCenter(
      center: innerRect.center,
      width: innerRect.width * scaleFactor,
      height: innerRect.height * scaleFactor,
    );
    canvas.drawPath(
      buildPath(innerScaled, params.innerN, rotation: params.rotation),
      paint,
    );
  }
}
