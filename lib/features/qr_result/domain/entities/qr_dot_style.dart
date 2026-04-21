import 'dart:math' as math;
import 'dart:ui' show Color, Offset, Paint, PaintingStyle, Path, Rect;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'qr_shape_params.dart';
import '../../utils/polar_polygon.dart';

/// QR 도트 모양 프리셋
enum QrDotStyle {
  square,   // ■
  circle,   // ●
  diamond,  // ◆
  heart,    // ♥
  star,     // ★
}

const kQrDotStyleLabels = {
  QrDotStyle.square:   '■',
  QrDotStyle.circle:   '●',
  QrDotStyle.diamond:  '◆',
  QrDotStyle.heart:    '♥',
  QrDotStyle.star:     '★',
};

/// 기존 QrDotStyle enum → DotShapeParams 매핑 (하위 호환).
extension QrDotStyleToParams on QrDotStyle {
  DotShapeParams toDotShapeParams() => switch (this) {
    QrDotStyle.square  => DotShapeParams.square,
    QrDotStyle.circle  => DotShapeParams.circle,
    QrDotStyle.diamond => DotShapeParams.diamond,
    QrDotStyle.heart   => DotShapeParams.sfHeart,
    QrDotStyle.star    => DotShapeParams.star,
  };
}

/// [QrDotStyle] → [PrettyQrShape] 빌더
PrettyQrShape buildDotShape(QrDotStyle style, Color color) {
  switch (style) {
    case QrDotStyle.square:
      return PrettyQrSmoothSymbol(roundFactor: 0.0, color: color);
    case QrDotStyle.circle:
      return PrettyQrDotsSymbol(color: color);
    default:
      return _CustomDotSymbol(style: style, color: color);
  }
}

/// [DotShapeParams] → [PrettyQrShape] 빌더 (맞춤 도트용).
///
/// PrettyQrView 내부에서 렌더링되므로 finder pattern·timing·alignment 등
/// QR 스펙이 자동으로 보존됩니다. 기본 제공 도트(■●◆♥★)와 동일한 원리.
PrettyQrShape buildCustomDotShape(DotShapeParams params, Color color) {
  return _PolarDotSymbol(params: params, color: color);
}

/// PolarPolygon 기반 맞춤 도트를 PrettyQrShape 로 렌더링.
class _PolarDotSymbol extends PrettyQrShape {
  final DotShapeParams params;
  final Color color;

  const _PolarDotSymbol({required this.params, required this.color});

  @override
  void paint(PrettyQrPaintingContext context) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final module in context.matrix) {
      if (!module.isDark) continue;
      final rect = module.resolveRect(context);
      final center = rect.center;
      final radius = rect.width / 2 * params.scale;
      final path = PolarPolygon.buildPath(center, radius, params);
      context.canvas.drawPath(path, paint);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _PolarDotSymbol &&
      params == other.params &&
      color == other.color;

  @override
  int get hashCode => Object.hash(params, color);
}

// ── 커스텀 도트 심볼 ───────────────────────────────────────────────────────────

class _CustomDotSymbol extends PrettyQrShape {
  final QrDotStyle style;
  final Color color;

  const _CustomDotSymbol({required this.style, required this.color});

  @override
  void paint(PrettyQrPaintingContext context) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final module in context.matrix) {
      if (!module.isDark) continue;
      final rect = module.resolveRect(context);
      final path = _buildPath(rect);
      context.canvas.drawPath(path, paint);
    }
  }

  Path _buildPath(Rect r) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    // 네모/원과 동일한 시각적 크기를 위해 full cell 사용 (inset 없음)
    final hw = r.width / 2;
    final hh = r.height / 2;

    switch (style) {
      case QrDotStyle.diamond:
        return Path()
          ..moveTo(cx, cy - hh)
          ..lineTo(cx + hw, cy)
          ..lineTo(cx, cy + hh)
          ..lineTo(cx - hw, cy)
          ..close();

      case QrDotStyle.star:
        return _starPath(cx, cy, hw, hw * 0.45, 5);

      case QrDotStyle.heart:
        return _heartPath(cx, cy, hw, hh);

      // covered by buildDotShape
      case QrDotStyle.square:
      case QrDotStyle.circle:
        return Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: r.width, height: r.height));
    }
  }

  // ── 별 ────────────────────────────────────────────────────────────────────────
  Path _starPath(double cx, double cy, double outer, double inner, int points) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  // ── 하트 ──────────────────────────────────────────────────────────────────────
  Path _heartPath(double cx, double cy, double hw, double hh) {
    final top = cy - hh * 0.5;
    final bottom = cy + hh;
    final left = cx - hw;
    final right = cx + hw;
    final midLeft = cx - hw * 0.5;
    final midRight = cx + hw * 0.5;

    return Path()
      ..moveTo(cx, bottom)
      ..cubicTo(left, cy, left, top, midLeft, top)
      ..cubicTo(cx, top - hh * 0.3, cx, top - hh * 0.3, midRight, top)
      ..cubicTo(right, top, right, cy, cx, bottom)
      ..close();
  }

  @override
  bool operator ==(Object other) =>
      other is _CustomDotSymbol && style == other.style && color == other.color;

  @override
  int get hashCode => Object.hash(style, color);
}
