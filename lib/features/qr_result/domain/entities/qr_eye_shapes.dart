import 'qr_shape_params.dart';

/// QR finder pattern 외곽 링 모양.
/// circleRound: 원형 외각 + 원형 여백(도넛 링).
enum QrEyeOuter { square, rounded, circle, circleRound, smooth }

/// QR finder pattern 내부 채움 모양.
enum QrEyeInner { square, circle, diamond, star }

/// QrEyeOuter + QrEyeInner enum 조합 → EyeShapeParams 변환.
/// CustomQrPainter 경로에서 customEyeParams 가 null 일 때 사용.
EyeShapeParams eyeEnumsToParams(QrEyeOuter outer, QrEyeInner inner) {
  // outer → cornerQ + hole
  final (double cq, double innerN) = switch (outer) {
    QrEyeOuter.square      => (1.0, 20.0),
    QrEyeOuter.rounded     => (0.7, 20.0),
    QrEyeOuter.circle      => (0.0, 2.0),
    QrEyeOuter.circleRound => (0.0, 2.0),
    QrEyeOuter.smooth      => (0.2, 3.0),
  };

  // inner → innerN override
  final double resolvedInnerN = switch (inner) {
    QrEyeInner.square  => 20.0,
    QrEyeInner.circle  => 2.0,
    QrEyeInner.diamond => 1.0,
    QrEyeInner.star    => 0.5,
  };

  return EyeShapeParams(
    cornerQ1: cq,
    cornerQ2: cq,
    cornerQ3: cq,
    cornerQ4: cq,
    innerN: resolvedInnerN,
  );
}
