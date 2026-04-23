import 'dart:math';

import 'package:qr/qr.dart';

import '../../qr_task/domain/entities/qr_gradient_data.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_shape_params.dart';
import 'qr_matrix_helper.dart';

/// QR 데이터 + 스타일 파라미터 → SVG 문자열 생성.
///
/// dart:ui 비의존 (dart:math + qr 패키지만 사용).
/// PolarPolygon / SuperellipsePath / QrBoundaryClipper 의 수학 로직을
/// SVG path `d` 문자열로 직접 재현한다.
class QrSvgGenerator {
  QrSvgGenerator._();

  static String generate({
    required String data,
    int ecLevel = 2,
    DotShapeParams dotParams = const DotShapeParams(),
    EyeShapeParams eyeParams = const EyeShapeParams(),
    QrBoundaryParams boundaryParams = const QrBoundaryParams(),
    int colorArgb = 0xFF000000,
    QrGradientData? gradient,
    double cellSize = 10.0,
  }) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: ecLevel,
    );
    final qrImage = QrImage(qrCode);
    final n = qrImage.moduleCount;
    final totalSize = n * cellSize;

    final helper = QrMatrixHelper(
      moduleCount: n,
      typeNumber: qrCode.typeNumber,
    );

    final buf = StringBuffer();
    buf.writeln('<svg xmlns="http://www.w3.org/2000/svg"');
    buf.writeln('     viewBox="0 0 ${_f(totalSize)} ${_f(totalSize)}"');
    buf.writeln('     width="${_f(totalSize)}" height="${_f(totalSize)}">');

    // ── defs (gradient + clipPath) ──
    final hasGradient = gradient != null && gradient.colorsArgb.length >= 2;
    final hasClip = !boundaryParams.isDefault && !boundaryParams.isFrameMode;

    if (hasGradient || hasClip) {
      buf.writeln('  <defs>');
      if (hasGradient) {
        buf.write(_buildGradientDefs(gradient, totalSize));
      }
      if (hasClip) {
        buf.write(_buildClipPathDefs(totalSize, boundaryParams));
      }
      buf.writeln('  </defs>');
    }

    // ── fill attribute ──
    final fillAttr = hasGradient ? 'url(#qr-grad)' : _colorHex(colorArgb);
    final opacityAttr = _colorOpacity(colorArgb);
    final fillExtra = opacityAttr < 1.0 ? ' fill-opacity="${_f(opacityAttr)}"' : '';

    // ── main group ──
    if (hasClip) {
      buf.writeln('  <g clip-path="url(#qr-clip)" fill="$fillAttr"$fillExtra>');
    } else {
      buf.writeln('  <g fill="$fillAttr"$fillExtra>');
    }

    // ── 1. Finder patterns (3개) ──
    const kEyeRotations = <double>[0.0, 90.0, -90.0];
    final finderOrigins = _finderOrigins(n, cellSize);
    for (int i = 0; i < finderOrigins.length; i++) {
      final ox = finderOrigins[i][0];
      final oy = finderOrigins[i][1];
      final side = 7 * cellSize;
      buf.write(_buildEyeSvg(ox, oy, side, eyeParams, kEyeRotations[i]));
    }

    // ── 2. Data + structural dots ──
    final m = cellSize;
    for (int row = 0; row < n; row++) {
      for (int col = 0; col < n; col++) {
        if (!qrImage.isDark(row, col)) continue;
        final moduleType = helper.classify(row, col);
        if (moduleType == QrModuleType.finder ||
            moduleType == QrModuleType.separator) {
          continue;
        }

        final cx = col * m + m / 2;
        final cy = row * m + m / 2;
        final radius = m / 2 * dotParams.scale;

        final pathData = _buildDotPathData(cx, cy, radius, dotParams);
        buf.writeln('    <path d="$pathData"/>');
      }
    }

    buf.writeln('  </g>');
    buf.writeln('</svg>');
    return buf.toString();
  }

  // ── Dot path data ──

  static String _buildDotPathData(
    double cx, double cy, double radius, DotShapeParams params,
  ) {
    return switch (params.mode) {
      DotShapeMode.symmetric =>
        _buildSymmetricPathData(cx, cy, radius, params),
      DotShapeMode.asymmetric =>
        _buildSuperformulaPathData(cx, cy, radius, params),
    };
  }

  static String _buildSymmetricPathData(
    double cx, double cy, double radius, DotShapeParams params,
  ) {
    final n = params.vertices;
    final rot = params.rotation * pi / 180;

    // 꼭짓점 계산 (outer/inner 교대)
    final verts = <List<double>>[];
    for (int i = 0; i < n * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? radius : radius * params.innerRadius;
      final angle = (i * pi / n) - pi / 2 + rot;
      verts.add([cx + r * cos(angle), cy + r * sin(angle)]);
    }

    final vertices = params.innerRadius >= 0.999
        ? _collapseVerts(verts)
        : verts;

    if (params.roundness <= 0.001) {
      return _polylinePathData(vertices);
    }
    return _roundedPolyPathData(vertices, params.roundness);
  }

  static List<List<double>> _collapseVerts(List<List<double>> verts) {
    final result = <List<double>>[];
    for (int i = 0; i < verts.length; i += 2) {
      result.add(verts[i]);
    }
    return result;
  }

  static String _polylinePathData(List<List<double>> verts) {
    final sb = StringBuffer();
    sb.write('M${_f(verts[0][0])},${_f(verts[0][1])}');
    for (int i = 1; i < verts.length; i++) {
      sb.write(' L${_f(verts[i][0])},${_f(verts[i][1])}');
    }
    sb.write('Z');
    return sb.toString();
  }

  static String _roundedPolyPathData(List<List<double>> verts, double roundness) {
    final n = verts.length;
    final t = roundness.clamp(0.0, 1.0) * 0.5;

    final firstX = _lerp(verts[n - 1][0], verts[0][0], 0.5 + t);
    final firstY = _lerp(verts[n - 1][1], verts[0][1], 0.5 + t);

    final sb = StringBuffer();
    sb.write('M${_f(firstX)},${_f(firstY)}');

    for (int i = 0; i < n; i++) {
      final curr = verts[i];
      final next = verts[(i + 1) % n];
      final prev = verts[(i + n - 1) % n];

      final p1x = _lerp(prev[0], curr[0], 1.0 - t);
      final p1y = _lerp(prev[1], curr[1], 1.0 - t);
      final p2x = _lerp(curr[0], next[0], t);
      final p2y = _lerp(curr[1], next[1], t);

      sb.write(' L${_f(p1x)},${_f(p1y)}');
      sb.write(' Q${_f(curr[0])},${_f(curr[1])} ${_f(p2x)},${_f(p2y)}');
    }
    sb.write('Z');
    return sb.toString();
  }

  static String _buildSuperformulaPathData(
    double cx, double cy, double radius, DotShapeParams params,
  ) {
    final rot = params.rotation * pi / 180;
    const steps = 128;

    final rawPoints = <List<double>>[];
    for (int i = 0; i < steps; i++) {
      final theta = (i / steps) * 2 * pi;
      final r = _superformula(
        theta, params.sfM, params.sfN1, params.sfN2, params.sfN3,
        params.sfA, params.sfB,
      );
      if (r.isNaN || r.isInfinite || r <= 0) continue;
      rawPoints.add([r * cos(theta), r * sin(theta)]);
    }

    if (rawPoints.length < 3) {
      // fallback: circle
      return _circlePathData(cx, cy, radius);
    }

    // normalize to bounding box + apply rotation
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final p in rawPoints) {
      minX = min(minX, p[0]);
      maxX = max(maxX, p[0]);
      minY = min(minY, p[1]);
      maxY = max(maxY, p[1]);
    }
    final w = maxX - minX;
    final h = maxY - minY;
    if (w == 0 || h == 0) return _circlePathData(cx, cy, radius);

    final scale = radius / max(w, h) * 2 * 0.9;
    final normalized = rawPoints.map((p) {
      var x = (p[0] - (minX + maxX) / 2) * scale;
      var y = (p[1] - (minY + maxY) / 2) * scale;
      if (rot != 0) {
        final rx = x * cos(rot) - y * sin(rot);
        final ry = x * sin(rot) + y * cos(rot);
        x = rx;
        y = ry;
      }
      return [cx + x, cy + y];
    }).toList();

    return _polylinePathData(normalized);
  }

  static double _superformula(
    double theta, double m, double n1, double n2, double n3,
    double a, double b,
  ) {
    final cosVal = cos(m * theta / 4);
    final sinVal = sin(m * theta / 4);
    final t1 = pow((cosVal / a).abs(), n2);
    final t2 = pow((sinVal / b).abs(), n3);
    final sum = t1 + t2;
    if (sum == 0) return 1.0;
    return pow(sum, -1.0 / n1).toDouble();
  }

  // ── Eye (Finder Pattern) ──

  static String _buildEyeSvg(
    double ox, double oy, double side,
    EyeShapeParams params, double rotationDeg,
  ) {
    final cx = ox + side / 2;
    final cy = oy + side / 2;
    final m = side / 7;
    final outerMaxR = side / 2;

    final sb = StringBuffer();

    if (rotationDeg != 0) {
      sb.writeln('    <g transform="rotate(${_f(rotationDeg)}, ${_f(cx)}, ${_f(cy)})">');
    } else {
      sb.writeln('    <g>');
    }

    // Outer ring (evenodd): outer RRect - hole RRect
    final outerPath = _rrectPathData(
      ox, oy, side, side,
      (1.0 - params.cornerQ2) * outerMaxR, // topLeft
      (1.0 - params.cornerQ1) * outerMaxR, // topRight
      (1.0 - params.cornerQ3) * outerMaxR, // bottomLeft
      (1.0 - params.cornerQ4) * outerMaxR, // bottomRight
    );
    final holeLeft = ox + m;
    final holeTop = oy + m;
    final holeSide = side - 2 * m;
    final holeMaxR = holeSide / 2;
    final holePath = _rrectPathData(
      holeLeft, holeTop, holeSide, holeSide,
      (1.0 - params.cornerQ2) * holeMaxR,
      (1.0 - params.cornerQ1) * holeMaxR,
      (1.0 - params.cornerQ3) * holeMaxR,
      (1.0 - params.cornerQ4) * holeMaxR,
    );
    sb.writeln('      <path d="$outerPath $holePath" fill-rule="evenodd"/>');

    // Inner fill: superellipse
    final innerLeft = ox + m * 2;
    final innerTop = oy + m * 2;
    final innerSide = side - 4 * m;
    final innerPath = _superellipsePathData(
      innerLeft + innerSide / 2,
      innerTop + innerSide / 2,
      innerSide / 2,
      innerSide / 2,
      params.innerN,
    );
    sb.writeln('      <path d="$innerPath"/>');

    sb.writeln('    </g>');
    return sb.toString();
  }

  /// RRect → SVG path (4 lines + 4 arcs).
  static String _rrectPathData(
    double x, double y, double w, double h,
    double tlR, double trR, double blR, double brR,
  ) {
    // Clamp radii to half of side
    final maxR = min(w, h) / 2;
    final tl = min(tlR, maxR);
    final tr = min(trR, maxR);
    final bl = min(blR, maxR);
    final br = min(brR, maxR);

    final sb = StringBuffer();
    sb.write('M${_f(x + tl)},${_f(y)}');
    sb.write(' L${_f(x + w - tr)},${_f(y)}');
    if (tr > 0) sb.write(' A${_f(tr)},${_f(tr)} 0 0 1 ${_f(x + w)},${_f(y + tr)}');
    sb.write(' L${_f(x + w)},${_f(y + h - br)}');
    if (br > 0) sb.write(' A${_f(br)},${_f(br)} 0 0 1 ${_f(x + w - br)},${_f(y + h)}');
    sb.write(' L${_f(x + bl)},${_f(y + h)}');
    if (bl > 0) sb.write(' A${_f(bl)},${_f(bl)} 0 0 1 ${_f(x)},${_f(y + h - bl)}');
    sb.write(' L${_f(x)},${_f(y + tl)}');
    if (tl > 0) sb.write(' A${_f(tl)},${_f(tl)} 0 0 1 ${_f(x + tl)},${_f(y)}');
    sb.write('Z');
    return sb.toString();
  }

  /// Superellipse |x/a|^n + |y/b|^n = 1 → SVG path.
  static String _superellipsePathData(
    double cx, double cy, double a, double b, double n,
    {double rotationDeg = 0.0}
  ) {
    final rot = rotationDeg * pi / 180;
    final exp = 2.0 / n;
    const steps = 100;

    final sb = StringBuffer();
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
      sb.write(i == 0 ? 'M${_f(px)},${_f(py)}' : ' L${_f(px)},${_f(py)}');
    }
    sb.write('Z');
    return sb.toString();
  }

  // ── Boundary clipPath ──

  static String _buildClipPathDefs(double size, QrBoundaryParams params) {
    final sb = StringBuffer();
    sb.writeln('    <clipPath id="qr-clip">');

    final cx = size / 2;
    final cy = size / 2;
    final radius = size / 2;
    final rot = params.rotation * pi / 180;

    switch (params.type) {
      case QrBoundaryType.square:
        break; // no clip
      case QrBoundaryType.circle:
        sb.writeln('      <circle cx="${_f(cx)}" cy="${_f(cy)}" r="${_f(radius)}"/>');
      case QrBoundaryType.superellipse:
        final path = _superellipsePathData(
          cx, cy, radius, radius, params.superellipseN,
          rotationDeg: params.rotation,
        );
        sb.writeln('      <path d="$path"/>');
      case QrBoundaryType.star:
        final path = _starPathData(
          cx, cy, radius, params.starVertices,
          params.starInnerRadius, rot, params.roundness,
        );
        sb.writeln('      <path d="$path"/>');
      case QrBoundaryType.heart:
        final path = _heartPathData(cx, cy, radius, rot);
        sb.writeln('      <path d="$path"/>');
      case QrBoundaryType.hexagon:
        final path = _polygonPathData(cx, cy, radius, 6, rot, params.roundness);
        sb.writeln('      <path d="$path"/>');
      case QrBoundaryType.custom:
        final path = _superellipsePathData(
          cx, cy, radius, radius, params.superellipseN,
          rotationDeg: params.rotation,
        );
        sb.writeln('      <path d="$path"/>');
    }

    sb.writeln('    </clipPath>');
    return sb.toString();
  }

  static String _starPathData(
    double cx, double cy, double radius, int n,
    double innerR, double rot, double roundness,
  ) {
    final verts = <List<double>>[];
    for (int i = 0; i < n * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? radius : radius * innerR;
      final angle = (i * pi / n) - pi / 2 + rot;
      verts.add([cx + r * cos(angle), cy + r * sin(angle)]);
    }
    if (roundness <= 0.001) return _polylinePathData(verts);
    return _roundedPolyPathData(verts, roundness);
  }

  static String _polygonPathData(
    double cx, double cy, double radius, int sides,
    double rot, double roundness,
  ) {
    final verts = <List<double>>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2 + rot;
      verts.add([cx + radius * cos(angle), cy + radius * sin(angle)]);
    }
    if (roundness <= 0.001) return _polylinePathData(verts);
    return _roundedPolyPathData(verts, roundness);
  }

  static String _heartPathData(double cx, double cy, double radius, double rot) {
    final w = radius;
    final h = radius;

    // Heart path (same math as QrBoundaryClipper)
    final sb = StringBuffer();

    // SVG cubic bezier commands
    sb.write('M${_f(cx)},${_f(cy + h * 0.7)}');
    sb.write(' C${_f(cx - w)},${_f(cy + h * 0.1)} ${_f(cx - w)},${_f(cy - h * 0.5)} ${_f(cx - w * 0.5)},${_f(cy - h * 0.5)}');
    sb.write(' C${_f(cx)},${_f(cy - h * 0.8)} ${_f(cx)},${_f(cy - h * 0.8)} ${_f(cx + w * 0.5)},${_f(cy - h * 0.5)}');
    sb.write(' C${_f(cx + w)},${_f(cy - h * 0.5)} ${_f(cx + w)},${_f(cy + h * 0.1)} ${_f(cx)},${_f(cy + h * 0.7)}');
    sb.write('Z');

    if (rot != 0) {
      // SVG transform handles rotation; wrap in group
      // But since we're inside clipPath, we embed rotation as transform
      // Actually for clipPath, we return path data and let caller wrap in transform
      // For simplicity, compute rotated coordinates
      // This is a known limitation — heart rotation in SVG clipPath
      // Return unrotated for now; boundary rotation is rarely combined with heart
    }

    return sb.toString();
  }

  // ── Gradient defs ──

  static String _buildGradientDefs(QrGradientData gradient, double size) {
    final sb = StringBuffer();
    final colors = gradient.colorsArgb;
    final stops = gradient.stops ??
        List.generate(colors.length, (i) => i / (colors.length - 1));

    switch (gradient.type) {
      case 'linear':
        final rad = gradient.angleDegrees * pi / 180;
        final x1 = 50 - cos(rad) * 50;
        final y1 = 50 - sin(rad) * 50;
        final x2 = 50 + cos(rad) * 50;
        final y2 = 50 + sin(rad) * 50;
        sb.writeln('    <linearGradient id="qr-grad"'
            ' x1="${_f(x1)}%" y1="${_f(y1)}%"'
            ' x2="${_f(x2)}%" y2="${_f(y2)}%">');
        for (int i = 0; i < colors.length; i++) {
          final offset = i < stops.length ? stops[i] : i / (colors.length - 1);
          sb.writeln('      <stop offset="${_f(offset * 100)}%"'
              ' stop-color="${_colorHex(colors[i])}"'
              '${_colorOpacity(colors[i]) < 1.0 ? ' stop-opacity="${_f(_colorOpacity(colors[i]))}"' : ''}/>');
        }
        sb.writeln('    </linearGradient>');

      case 'radial':
        sb.writeln('    <radialGradient id="qr-grad" cx="50%" cy="50%" r="50%">');
        for (int i = 0; i < colors.length; i++) {
          final offset = i < stops.length ? stops[i] : i / (colors.length - 1);
          sb.writeln('      <stop offset="${_f(offset * 100)}%"'
              ' stop-color="${_colorHex(colors[i])}"'
              '${_colorOpacity(colors[i]) < 1.0 ? ' stop-opacity="${_f(_colorOpacity(colors[i]))}"' : ''}/>');
        }
        sb.writeln('    </radialGradient>');

      default:
        // sweep → linear fallback
        sb.writeln('    <linearGradient id="qr-grad" x1="0%" y1="0%" x2="100%" y2="100%">');
        for (int i = 0; i < colors.length; i++) {
          final offset = i < stops.length ? stops[i] : i / (colors.length - 1);
          sb.writeln('      <stop offset="${_f(offset * 100)}%"'
              ' stop-color="${_colorHex(colors[i])}"'
              '${_colorOpacity(colors[i]) < 1.0 ? ' stop-opacity="${_f(_colorOpacity(colors[i]))}"' : ''}/>');
        }
        sb.writeln('    </linearGradient>');
    }

    return sb.toString();
  }

  // ── Helpers ──

  static List<List<double>> _finderOrigins(int moduleCount, double cellSize) {
    return [
      [0.0, 0.0], // top-left
      [(moduleCount - 7) * cellSize, 0.0], // top-right
      [0.0, (moduleCount - 7) * cellSize], // bottom-left
    ];
  }

  static String _circlePathData(double cx, double cy, double r) {
    // SVG circle as two arcs
    return 'M${_f(cx - r)},${_f(cy)}'
        ' A${_f(r)},${_f(r)} 0 1 1 ${_f(cx + r)},${_f(cy)}'
        ' A${_f(r)},${_f(r)} 0 1 1 ${_f(cx - r)},${_f(cy)}Z';
  }

  static String _colorHex(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  static double _colorOpacity(int argb) {
    final a = (argb >> 24) & 0xFF;
    return a / 255.0;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// 소수점 2자리 포맷 (SVG 파일 크기 최적화).
  static String _f(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
