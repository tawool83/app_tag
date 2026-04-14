import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// QR 도트 모양 프리셋
enum QrDotStyle {
  square,   // ■
  circle,   // ●
  diamond,  // ◆
  triangle, // ▼
  heart,    // ♥
  star,     // ★
  spade,    // ♠
  club,     // ♣
  sun,      // ☀️
  moon,     // 🌑
  drop,     // 💧
  fire,     // 🔥
  globe,    // 🌏
}

const kQrDotStyleLabels = {
  QrDotStyle.square:   '■',
  QrDotStyle.circle:   '●',
  QrDotStyle.diamond:  '◆',
  QrDotStyle.triangle: '▼',
  QrDotStyle.heart:    '♥',
  QrDotStyle.star:     '★',
  QrDotStyle.spade:    '♠',
  QrDotStyle.club:     '♣',
  QrDotStyle.sun:      '☀',
  QrDotStyle.moon:     '🌑',
  QrDotStyle.drop:     '💧',
  QrDotStyle.fire:     '🔥',
  QrDotStyle.globe:    '🌏',
};

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
    // 여백을 조금 줘서 QR 스캔 안전성 확보 (4% inset)
    final w = r.width * 0.92;
    final h = r.height * 0.92;
    final hw = w / 2;
    final hh = h / 2;

    switch (style) {
      case QrDotStyle.diamond:
        return Path()
          ..moveTo(cx, cy - hh)
          ..lineTo(cx + hw, cy)
          ..lineTo(cx, cy + hh)
          ..lineTo(cx - hw, cy)
          ..close();

      case QrDotStyle.triangle:
        return Path()
          ..moveTo(cx - hw, cy - hh)
          ..lineTo(cx + hw, cy - hh)
          ..lineTo(cx, cy + hh)
          ..close();

      case QrDotStyle.star:
        return _starPath(cx, cy, hw * 0.95, hw * 0.42, 5);

      case QrDotStyle.heart:
        return _heartPath(cx, cy, hw, hh);

      case QrDotStyle.spade:
        return _spadePath(cx, cy, hw, hh);

      case QrDotStyle.club:
        return _clubPath(cx, cy, hw * 0.7, hh);

      case QrDotStyle.sun:
        return _sunPath(cx, cy, hw * 0.55, hw * 0.78, 8);

      case QrDotStyle.moon:
        return _moonPath(cx, cy, hw, hh);

      case QrDotStyle.drop:
        return _dropPath(cx, cy, hw, hh);

      case QrDotStyle.fire:
        return _firePath(cx, cy, hw, hh);

      case QrDotStyle.globe:
        return _globePath(cx, cy, hw * 0.92);

      // covered by buildDotShape
      case QrDotStyle.square:
      case QrDotStyle.circle:
        return Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
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

  // ── 스페이드 ──────────────────────────────────────────────────────────────────
  Path _spadePath(double cx, double cy, double hw, double hh) {
    final path = Path();
    // 역삼각형 잎 상단
    path.moveTo(cx, cy - hh);
    path.cubicTo(cx + hw, cy - hh * 0.2, cx + hw, cy + hh * 0.2, cx, cy + hh * 0.1);
    path.cubicTo(cx - hw, cy + hh * 0.2, cx - hw, cy - hh * 0.2, cx, cy - hh);
    // 줄기
    path.moveTo(cx - hw * 0.3, cy + hh * 0.1);
    path.lineTo(cx - hw * 0.45, cy + hh);
    path.lineTo(cx + hw * 0.45, cy + hh);
    path.lineTo(cx + hw * 0.3, cy + hh * 0.1);
    path.close();
    return path;
  }

  // ── 클로버 ────────────────────────────────────────────────────────────────────
  Path _clubPath(double cx, double cy, double r, double hh) {
    final path = Path();
    // 3개 원
    final offset = r * 0.7;
    path.addOval(Rect.fromCenter(center: Offset(cx, cy - offset), width: r * 1.6, height: r * 1.6));
    path.addOval(Rect.fromCenter(center: Offset(cx - offset, cy + offset * 0.3), width: r * 1.6, height: r * 1.6));
    path.addOval(Rect.fromCenter(center: Offset(cx + offset, cy + offset * 0.3), width: r * 1.6, height: r * 1.6));
    // 줄기
    path.addRect(Rect.fromCenter(center: Offset(cx, cy + hh * 0.6), width: r * 0.4, height: hh * 0.7));
    return path;
  }

  // ── 태양 ──────────────────────────────────────────────────────────────────────
  Path _sunPath(double cx, double cy, double inner, double outer, int rays) {
    return _starPath(cx, cy, outer, inner, rays);
  }

  // ── 달 ────────────────────────────────────────────────────────────────────────
  Path _moonPath(double cx, double cy, double hw, double hh) {
    final path = Path();
    path.addOval(Rect.fromCenter(center: Offset(cx, cy), width: hw * 2, height: hh * 2));
    // subtract inner circle to make crescent
    final cutPath = Path();
    cutPath.addOval(Rect.fromCenter(center: Offset(cx + hw * 0.4, cy - hh * 0.1), width: hw * 1.6, height: hh * 1.6));
    return Path.combine(PathOperation.difference, path, cutPath);
  }

  // ── 물방울 ────────────────────────────────────────────────────────────────────
  Path _dropPath(double cx, double cy, double hw, double hh) {
    return Path()
      ..moveTo(cx, cy - hh)
      ..cubicTo(cx + hw * 0.8, cy - hh * 0.1, cx + hw, cy + hh * 0.2, cx, cy + hh)
      ..cubicTo(cx - hw, cy + hh * 0.2, cx - hw * 0.8, cy - hh * 0.1, cx, cy - hh)
      ..close();
  }

  // ── 불꽃 ──────────────────────────────────────────────────────────────────────
  Path _firePath(double cx, double cy, double hw, double hh) {
    return Path()
      ..moveTo(cx, cy - hh)
      ..cubicTo(cx + hw * 0.6, cy - hh * 0.3, cx + hw, cy + hh * 0.2, cx + hw * 0.4, cy + hh)
      ..cubicTo(cx + hw * 0.2, cy + hh * 0.4, cx, cy + hh * 0.6, cx - hw * 0.2, cy + hh)
      ..cubicTo(cx - hw, cy + hh * 0.2, cx - hw * 0.6, cy - hh * 0.3, cx, cy - hh)
      ..close();
  }

  // ── 지구 (원 + 격자선) ────────────────────────────────────────────────────────
  Path _globePath(double cx, double cy, double r) {
    final path = Path();
    path.addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2));
    return path;
  }

  @override
  bool operator ==(Object other) =>
      other is _CustomDotSymbol && style == other.style && color == other.color;

  @override
  int get hashCode => Object.hash(style, color);
}
