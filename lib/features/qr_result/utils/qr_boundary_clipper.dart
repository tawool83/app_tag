import 'dart:math';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart' show Matrix4;

import '../domain/entities/qr_boundary_params.dart';
import 'superellipse.dart';

/// QR 전체 외곽 클리핑.
class QrBoundaryClipper {
  QrBoundaryClipper._();

  /// 외곽 클리핑 Path 생성. square(기본)면 null 반환 (클리핑 불요).
  static Path? buildClipPath(Size size, QrBoundaryParams params) {
    if (params.isDefault) return null;

    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    final rot = params.rotation * pi / 180;

    switch (params.type) {
      case QrBoundaryType.square:
        return null;
      case QrBoundaryType.circle:
        return Path()..addOval(rect);
      case QrBoundaryType.superellipse:
        return SuperellipsePath.buildPath(
          rect,
          params.superellipseN,
          rotation: params.rotation,
        );
      case QrBoundaryType.star:
        return _starPath(
          center, radius, params.starVertices,
          params.starInnerRadius, rot, params.roundness,
        );
      case QrBoundaryType.heart:
        return _heartPath(center, radius, rot);
      case QrBoundaryType.hexagon:
        return _regularPolygonPath(center, radius, 6, rot, params.roundness);
      case QrBoundaryType.custom:
        return SuperellipsePath.buildPath(
          rect,
          params.superellipseN,
          rotation: params.rotation,
        );
    }
  }

  /// Canvas에 외곽 클리핑 적용. paint() 시작 시 호출.
  static void applyClip(
    Canvas canvas,
    Size size,
    QrBoundaryParams params, {
    Color? bgColor,
  }) {
    final clipPath = buildClipPath(size, params);
    if (clipPath == null) return;

    if (bgColor != null) {
      canvas.drawPath(clipPath, Paint()..color = bgColor);
    }
    canvas.clipPath(clipPath);
  }

  // ── private helpers ──

  static Path _starPath(
    Offset center, double radius, int n,
    double innerR, double rot, double roundness,
  ) {
    final vertices = <Offset>[];
    for (int i = 0; i < n * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? radius : radius * innerR;
      final angle = (i * pi / n) - pi / 2 + rot;
      vertices.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }
    return _buildPolygonPath(vertices, roundness);
  }

  static Path _regularPolygonPath(
    Offset center, double radius, int sides,
    double rot, double roundness,
  ) {
    final vertices = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2 + rot;
      vertices.add(Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ));
    }
    return _buildPolygonPath(vertices, roundness);
  }

  static Path _heartPath(Offset center, double radius, double rot) {
    final cx = center.dx;
    final cy = center.dy;
    final w = radius;
    final h = radius;

    final path = Path();
    // 하트 상단 중앙에서 시작
    path.moveTo(cx, cy + h * 0.7);
    // 왼쪽 곡선
    path.cubicTo(
      cx - w, cy + h * 0.1,
      cx - w, cy - h * 0.5,
      cx - w * 0.5, cy - h * 0.5,
    );
    // 상단 왼쪽 → 중앙
    path.cubicTo(
      cx, cy - h * 0.8,
      cx, cy - h * 0.8,
      cx + w * 0.5, cy - h * 0.5,
    );
    // 오른쪽 곡선
    path.cubicTo(
      cx + w, cy - h * 0.5,
      cx + w, cy + h * 0.1,
      cx, cy + h * 0.7,
    );
    path.close();

    if (rot != 0) {
      final matrix = Matrix4.identity()
        ..translate(cx, cy)
        ..rotateZ(rot)
        ..translate(-cx, -cy);
      return path.transform(matrix.storage);
    }
    return path;
  }

  static Path _buildPolygonPath(List<Offset> vertices, double roundness) {
    final path = Path();
    if (roundness <= 0.001) {
      path.moveTo(vertices[0].dx, vertices[0].dy);
      for (int i = 1; i < vertices.length; i++) {
        path.lineTo(vertices[i].dx, vertices[i].dy);
      }
    } else {
      _addRoundedPolygon(path, vertices, roundness);
    }
    path.close();
    return path;
  }

  static void _addRoundedPolygon(
    Path path, List<Offset> verts, double roundness,
  ) {
    final n = verts.length;
    final t = roundness.clamp(0.0, 1.0) * 0.5;

    final first = Offset.lerp(verts[n - 1], verts[0], 0.5 + t)!;
    path.moveTo(first.dx, first.dy);

    for (int i = 0; i < n; i++) {
      final curr = verts[i];
      final next = verts[(i + 1) % n];
      final p1 = Offset.lerp(verts[(i + n - 1) % n], curr, 1.0 - t)!;
      final p2 = Offset.lerp(curr, next, t)!;
      path.lineTo(p1.dx, p1.dy);
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
  }
}
