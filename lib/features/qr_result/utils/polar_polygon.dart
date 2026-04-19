import 'dart:math';
import 'dart:ui';

import '../domain/entities/qr_shape_params.dart';

/// 극좌표 다각형 + Superformula 기반 도트 Path 생성.
class PolarPolygon {
  PolarPolygon._();

  /// [center] 도트 중심, [radius] 셀 반지름, [params] 형태 파라미터.
  static Path buildPath(
      Offset center, double radius, DotShapeParams params) {
    return switch (params.mode) {
      DotShapeMode.symmetric => _buildSymmetricPath(center, radius, params),
      DotShapeMode.asymmetric => _buildSuperformulaPath(center, radius, params),
    };
  }

  // ── 대칭 모드: 극좌표 다각형 ──

  static Path _buildSymmetricPath(
      Offset center, double radius, DotShapeParams params) {
    final n = params.vertices;
    final rot = params.rotation * pi / 180;

    // 1. 꼭짓점 좌표 계산 (outer/inner 교대)
    final verts = <Offset>[];
    for (int i = 0; i < n * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? radius : radius * params.innerRadius;
      final angle = (i * pi / n) - pi / 2 + rot;
      verts.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }

    // innerRadius == 1 이면 outer/inner 같은 반지름 → 꼭짓점 절반만 사용
    final vertices =
        params.innerRadius >= 0.999 ? _collapseVertices(verts) : verts;

    // 2. Path 생성 (roundness 적용)
    final path = Path();
    if (params.roundness <= 0.001) {
      path.moveTo(vertices[0].dx, vertices[0].dy);
      for (int i = 1; i < vertices.length; i++) {
        path.lineTo(vertices[i].dx, vertices[i].dy);
      }
    } else {
      _addRoundedPolygon(path, vertices, params.roundness);
    }
    path.close();
    return path;
  }

  /// innerRadius=1 일 때, 짝수 인덱스 꼭짓점만 추출.
  static List<Offset> _collapseVertices(List<Offset> verts) {
    final result = <Offset>[];
    for (int i = 0; i < verts.length; i += 2) {
      result.add(verts[i]);
    }
    return result;
  }

  /// cubicTo 보간으로 둥근 다각형 생성.
  static void _addRoundedPolygon(
      Path path, List<Offset> verts, double roundness) {
    final n = verts.length;
    final t = roundness.clamp(0.0, 1.0) * 0.5; // 0~0.5

    // 첫 점: 이전 점과 현재 점 사이의 보간 위치에서 시작
    final first = Offset.lerp(verts[n - 1], verts[0], 0.5 + t)!;
    path.moveTo(first.dx, first.dy);

    for (int i = 0; i < n; i++) {
      final curr = verts[i];
      final next = verts[(i + 1) % n];

      // 현재 꼭짓점 쪽으로 접근
      final p1 = Offset.lerp(verts[(i + n - 1) % n], curr, 1.0 - t)!;
      // 현재 꼭짓점에서 다음 꼭짓점 쪽으로 출발
      final p2 = Offset.lerp(curr, next, t)!;

      // 현재 꼭짓점 근처의 라인 → 꼭짓점 → 다음 라인 시작
      path.lineTo(p1.dx, p1.dy);
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
  }

  // ── 비대칭 모드: Superformula (Gielis, 1999) ──

  static Path _buildSuperformulaPath(
      Offset center, double radius, DotShapeParams params) {
    final rot = params.rotation * pi / 180;
    const steps = 128;

    // Superformula로 극좌표 점 생성
    final rawPoints = <Offset>[];
    for (int i = 0; i < steps; i++) {
      final theta = (i / steps) * 2 * pi;
      final r = _superformula(
          theta, params.sfM, params.sfN1, params.sfN2, params.sfN3,
          params.sfA, params.sfB);
      if (r.isNaN || r.isInfinite || r <= 0) continue;
      rawPoints.add(Offset(r * cos(theta), r * sin(theta)));
    }

    // 안전장치: 유효한 점이 없으면 원으로 폴백
    if (rawPoints.length < 3) {
      return Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius));
    }

    // bounding box 정규화 → 셀 크기에 맞춤 → rotation 적용
    final normalized = _normalizeAndTransform(rawPoints, center, radius, rot);

    final path = Path();
    path.moveTo(normalized[0].dx, normalized[0].dy);
    for (int i = 1; i < normalized.length; i++) {
      path.lineTo(normalized[i].dx, normalized[i].dy);
    }
    path.close();
    return path;
  }

  /// Superformula: r(θ) = ( |cos(mθ/4)/a|^n2 + |sin(mθ/4)/b|^n3 )^(-1/n1)
  static double _superformula(
      double theta, double m, double n1, double n2, double n3,
      double a, double b) {
    final cosVal = cos(m * theta / 4);
    final sinVal = sin(m * theta / 4);
    final t1 = pow((cosVal / a).abs(), n2);
    final t2 = pow((sinVal / b).abs(), n3);
    final sum = t1 + t2;
    if (sum == 0) return 1.0;
    return pow(sum, -1.0 / n1).toDouble();
  }

  /// 원시 좌표 → bounding box 정규화 → 셀 크기 맞춤 → rotation
  static List<Offset> _normalizeAndTransform(
    List<Offset> points, Offset center, double radius, double rot,
  ) {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final p in points) {
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
      minY = min(minY, p.dy);
      maxY = max(maxY, p.dy);
    }
    final w = maxX - minX;
    final h = maxY - minY;
    if (w == 0 || h == 0) return points;

    final scale = radius / max(w, h) * 2 * 0.9; // 90% fill
    return points.map((p) {
      var x = (p.dx - (minX + maxX) / 2) * scale;
      var y = (p.dy - (minY + maxY) / 2) * scale;
      if (rot != 0) {
        final rx = x * cos(rot) - y * sin(rot);
        final ry = x * sin(rot) + y * cos(rot);
        x = rx;
        y = ry;
      }
      return Offset(center.dx + x, center.dy + y);
    }).toList();
  }

  /// 채움률 검증: 도형 면적 / 셀 면적 (근사값)
  static double computeFillRatio(Path path, double cellSize) {
    final bounds = path.getBounds();
    return (bounds.width * bounds.height) / (cellSize * cellSize);
  }
}
