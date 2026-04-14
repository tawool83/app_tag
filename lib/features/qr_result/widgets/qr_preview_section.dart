import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../models/qr_dot_style.dart';
import '../../../models/qr_template.dart';
import '../../../models/sticker_config.dart' show LogoPosition;
import '../../../services/qr_readability_service.dart';
import '../qr_result_provider.dart' show QrResultState, qrResultProvider, QrEyeOuter, QrEyeInner;
import 'qr_layer_stack.dart';

/// 소형(160px) QR 미리보기 + 돋보기 확대 버튼 + 인식률 배지.
/// RepaintBoundary를 포함하여 캡처 기준이 됩니다.
class QrPreviewSection extends ConsumerWidget {
  final GlobalKey repaintKey;
  final String deepLink;
  final ReadabilityScore score;

  const QrPreviewSection({
    super.key,
    required this.repaintKey,
    required this.deepLink,
    required this.score,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 왼쪽 영역 70%: QR 코드 (중앙 배치)
            // LayoutBuilder로 가용 폭에 맞게 qrSize 계산:
            //   bgSize = qrSize * kQrBgExpandFactor (배경 있을 때)
            //   bgSize + 24 (패딩) = qrSize (배경 없을 때)
            Expanded(
              flex: 7,
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final hasBg = state.background.hasImage;
                  final double qrSize = hasBg
                      ? (constraints.maxWidth / kQrBgExpandFactor)
                          .floorToDouble()
                          .clamp(80.0, 160.0)
                      : 160.0;
                  return Align(
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 캡처 영역
                        // 배경 이미지가 있으면 흰 여백 없이 이미지가 외곽까지 채움
                        RepaintBoundary(
                          key: repaintKey,
                          child: Container(
                            color: hasBg ? null : Colors.white,
                            padding: hasBg
                                ? EdgeInsets.zero
                                : const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                QrLayerStack(deepLink: deepLink, size: qrSize),
                              ],
                            ),
                          ),
                        ),
                        // 돋보기 버튼 (우하단)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  _showQrZoomDialog(context, state, deepLink),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.zoom_in, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 오른쪽 영역 30%: 인식률 배지 (가운데 정렬)
            Expanded(
              flex: 3,
              child: Center(child: _ReadabilityBadge(score: score)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          deepLink,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

}

// ── 인식률 배지 ────────────────────────────────────────────────────────────────

class _ReadabilityBadge extends StatelessWidget {
  final ReadabilityScore score;
  const _ReadabilityBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score.color;
    final isDanger = score.isDanger;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '인식률',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDanger ? Colors.red.shade600 : Colors.grey.shade300,
              width: isDanger ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDanger)
                Icon(Icons.warning_amber_rounded, size: 16, color: color),
              if (isDanger) const SizedBox(height: 4),
              Text(
                '${score.total}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 확대 다이얼로그 ────────────────────────────────────────────────────────────

void _showQrZoomDialog(
    BuildContext context, QrResultState state, String deepLink) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        // LayoutBuilder: 다이얼로그 실제 가용 폭에 맞게 qrSize 결정
        // bgSize = qrSize * kQrBgExpandFactor 이므로 bgSize <= maxWidth 보장
        child: LayoutBuilder(
          builder: (_, constraints) {
            final hasBg = state.background.hasImage;
            final double qrSize = hasBg
                ? (constraints.maxWidth / kQrBgExpandFactor)
                    .floorToDouble()
                    .clamp(100.0, 300.0)
                : constraints.maxWidth.clamp(100.0, 300.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrLayerStack(deepLink: deepLink, size: qrSize, isDialog: true),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// QrResultState 기반 PrettyQrView 위젯 빌더.
/// QrPreviewSection과 확대 팝업에서 공용 사용.
Widget buildPrettyQr(
  QrResultState state, {
  required String deepLink,
  required double size,
  bool isDialog = false,
}) {
  final centerImage = centerImageProvider(state);
  // 로고 위치가 center일 때만 QR 내부에 embed (bottomRight는 _LogoWidget이 담당)
  final embedInQr = centerImage != null &&
      state.sticker.logoPosition == LogoPosition.center;
  // 템플릿 그라디언트 우선, 없으면 사용자 커스텀 그라디언트
  final activeGradient = state.templateGradient ?? state.customGradient;
  final hasGradient = activeGradient != null;
  final ecLevel =
      embedInQr ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
  final dotColor = hasGradient ? Colors.black : state.qrColor;

  final dotShape = buildDotShape(state.dotStyle, dotColor);

  // finder pattern 결정: 랜덤 시드 우선, 아니면 outer+inner 조합
  // circleRound 외각 선택 시 hole도 원형으로 자동 파생
  final PrettyQrShape finderPattern = state.randomEyeSeed != null
      ? _RandomFinderPattern(color: dotColor, seed: state.randomEyeSeed!)
      : _ComboFinderPattern(
          color: dotColor,
          outer: _outerShapeFrom(state.eyeOuter),
          inner: _innerShapeFrom(state.eyeInner),
          hole: _holeFromOuter(state.eyeOuter),
        );
  final qrShape = PrettyQrShape.custom(dotShape, finderPattern: finderPattern);

  // ValueKey: decoration 관련 state가 변경될 때 위젯을 강제 재생성해
  // PrettyQrRenderView 내부 repaint boundary 이슈를 우회합니다.
  // isDialog: 팝업에서 같은 key 충돌 방지
  final qrKey = ValueKey(Object.hash(
    isDialog,
    deepLink,
    state.dotStyle,
    state.eyeOuter,
    state.eyeInner,
    state.randomEyeSeed,
    state.qrColor,
    state.embedIcon,
    centerImage != null,
    state.templateGradient,
    state.customGradient,
    state.activeTemplateId,
  ));

  // 그라디언트 활성 시 아이콘을 ShaderMask 바깥으로 분리해야 함.
  // BlendMode.srcIn이 PrettyQrView 내부 이미지까지 그라디언트로 물들이기 때문.
  final useIconOverlay = hasGradient && embedInQr;

  final qrWidget = PrettyQrView.data(
    key: qrKey,
    data: deepLink,
    errorCorrectLevel: ecLevel,
    decoration: PrettyQrDecoration(
      shape: qrShape,
      // center 위치 + 그라디언트 없을 때만 QR 내부에 embed
      image: !useIconOverlay && embedInQr
          ? PrettyQrDecorationImage(
              image: centerImage!,
              position: PrettyQrDecorationImagePosition.embedded,
            )
          : null,
    ),
  );

  if (hasGradient) {
    Widget gradientQr = SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => buildQrGradientShader(activeGradient, bounds),
        child: qrWidget,
      ),
    );

    if (useIconOverlay) {
      // 아이콘을 흰 원형 배지로 중앙에 오버레이 (그라디언트 영향 없음)
      // embedInQr == true이면 centerImage != null 보장됨
      final iconSize = size * 0.22;
      gradientQr = Stack(
        alignment: Alignment.center,
        children: [
          gradientQr,
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 2),
              ],
            ),
            padding: EdgeInsets.all(iconSize * 0.08),
            child: ClipOval(
              child: Image(image: centerImage!, fit: BoxFit.contain),
            ),
          ),
        ],
      );
    }

    return gradientQr;
  }

  return SizedBox(width: size, height: size, child: qrWidget);
}

ImageProvider? centerImageProvider(QrResultState state) {
  if (!state.embedIcon) return null;
  if (state.templateCenterIconBytes != null) {
    return MemoryImage(state.templateCenterIconBytes!);
  }
  if (state.emojiIconBytes != null) return MemoryImage(state.emojiIconBytes!);
  if (state.defaultIconBytes != null) return MemoryImage(state.defaultIconBytes!);
  return null;
}

// ── Finder Pattern 헬퍼 ────────────────────────────────────────────────────────

enum _OuterShape { square, rounded, circle, smooth }
enum _InnerShape  { square, circle, diamond, star }
enum _HoleShape   { square, circle }

_OuterShape _outerShapeFrom(QrEyeOuter v) {
  switch (v) {
    case QrEyeOuter.square:      return _OuterShape.square;
    case QrEyeOuter.rounded:     return _OuterShape.rounded;
    case QrEyeOuter.circle:      return _OuterShape.circle;
    case QrEyeOuter.circleRound: return _OuterShape.circle;
    case QrEyeOuter.smooth:      return _OuterShape.smooth;
  }
}

_InnerShape _innerShapeFrom(QrEyeInner v) {
  switch (v) {
    case QrEyeInner.square:  return _InnerShape.square;
    case QrEyeInner.circle:  return _InnerShape.circle;
    case QrEyeInner.diamond: return _InnerShape.diamond;
    case QrEyeInner.star:    return _InnerShape.star;
  }
}

/// 외각 선택에서 여백(hole) 모양을 자동 파생.
/// circleRound는 원형 여백, 나머지는 사각 여백.
_HoleShape _holeFromOuter(QrEyeOuter v) {
  return v == QrEyeOuter.circleRound ? _HoleShape.circle : _HoleShape.square;
}

/// 3개 finder pattern의 7m×7m bounding box를 반환.
/// positionDetectionPatterns를 직접 사용해 모든 QR 버전에서 정확히 동작.
List<Rect> _groupFinderBounds(PrettyQrPaintingContext context) {
  final m = context.moduleDimension;
  final offset = context.estimatedBounds.topLeft;
  return context.matrix.positionDetectionPatterns.map((pdp) {
    return Rect.fromLTWH(
      offset.dx + pdp.left * m,
      offset.dy + pdp.top * m,
      (pdp.width + 1) * m,
      (pdp.height + 1) * m,
    );
  }).toList();
}

/// 외곽 모양과 내부 채움 모양을 독립적으로 지정할 수 있는 커스텀 finder pattern.
///
/// 구조:
///   • 외곽 링:  7×7 영역  PathFillType.evenOdd (외곽 도형 - 5×5 구멍)
///   • 내부 채움: 3×3 영역  지정한 inner 도형
///
/// context.matrix 는 3개 코너 파인더 패턴 전체 모듈을 포함하므로,
/// 7m×7m 블록 단위로 그룹화하여 각각 독립적으로 렌더링합니다.
class _ComboFinderPattern extends PrettyQrShape {
  final Color color;
  final _OuterShape outer;
  final _InnerShape inner;
  final _HoleShape hole;

  const _ComboFinderPattern({
    required this.color,
    required this.outer,
    required this.inner,
    this.hole = _HoleShape.square,
  });

  @override
  void paint(PrettyQrPaintingContext context) {
    final paint = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    for (final bounds in _groupFinderBounds(context)) {
      _drawOne(context.canvas, bounds, paint);
    }
  }

  void _drawOne(Canvas canvas, Rect bounds, Paint paint) {
    final m = bounds.width / 7;
    final holeRect  = bounds.deflate(m);       // 5×5 구멍
    final innerRect = bounds.deflate(m * 2);   // 3×3 내부

    // 외곽 링: evenOdd (외곽 도형 + 구멍 → 링 모양)
    final ringPath = Path()..fillType = PathFillType.evenOdd;
    _addShape(ringPath, bounds, outer, radius: m * 1.2);
    switch (hole) {
      case _HoleShape.square: ringPath.addRect(holeRect);
      case _HoleShape.circle: ringPath.addOval(holeRect);
    }
    canvas.drawPath(ringPath, paint);

    // 내부 채움
    canvas.drawPath(_buildInnerPath(innerRect), paint);
  }

  void _addShape(Path path, Rect rect, _OuterShape shape, {double radius = 4}) {
    switch (shape) {
      case _OuterShape.square:
        path.addRect(rect);
      case _OuterShape.rounded:
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
      case _OuterShape.circle:
        path.addOval(rect);
      case _OuterShape.smooth:
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius * 2.0)));
    }
  }

  Path _buildInnerPath(Rect r) {
    switch (inner) {
      case _InnerShape.square:
        return Path()..addRect(r);
      case _InnerShape.circle:
        return Path()..addOval(r);
      case _InnerShape.diamond:
        return Path()
          ..moveTo(r.center.dx, r.top)
          ..lineTo(r.right, r.center.dy)
          ..lineTo(r.center.dx, r.bottom)
          ..lineTo(r.left, r.center.dy)
          ..close();
      case _InnerShape.star:
        return _starPath(r.center, r.width / 2, r.width * 0.22, 4);
    }
  }

  static Path _starPath(Offset center, double outer, double inner, int points) {
    final path = Path();
    final total = points * 2;
    for (int i = 0; i < total; i++) {
      final r = i.isEven ? outer : inner;
      final angle = (i * math.pi / points) - math.pi / 2;
      final pt = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool operator ==(Object other) =>
      other is _ComboFinderPattern &&
      color == other.color &&
      outer == other.outer &&
      inner == other.inner &&
      hole == other.hole;

  @override
  int get hashCode => Object.hash(color, outer, inner, hole);
}

// ── 랜덤 Finder Pattern ─────────────────────────────────────────────────────

/// 시드 기반으로 코너별 독립 곡률 + 내부 채움 형태를 랜덤 결정하는 finder pattern.
/// QR 1:1:3:1:1 스펙(외곽 링 1모듈 / 흰 갭 1모듈 / 내부 3×3)은 항상 준수합니다.
class _RandomFinderPattern extends PrettyQrShape {
  final Color color;
  final int seed;

  const _RandomFinderPattern({required this.color, required this.seed});

  @override
  void paint(PrettyQrPaintingContext context) {
    final allBounds = _groupFinderBounds(context);
    if (allBounds.isEmpty) return;

    final paint = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    final canvas = context.canvas;

    final m = allBounds.first.width / 7;
    final maxOuterR = m * 1.8;
    final rng = math.Random(seed);

    // ── 3개 눈 공통 파라미터: 루프 밖에서 한 번만 생성 ──
    final outerTL = Radius.circular(rng.nextDouble() * maxOuterR);
    final outerTR = Radius.circular(rng.nextDouble() * maxOuterR);
    final outerBL = Radius.circular(rng.nextDouble() * maxOuterR);
    final outerBR = Radius.circular(rng.nextDouble() * maxOuterR);
    final innerType = _InnerShape.values[rng.nextInt(_InnerShape.values.length)];
    // inner square 코너 비율도 미리 고정 (0.0~1.0)
    final innerCorners = [
      rng.nextDouble(), rng.nextDouble(),
      rng.nextDouble(), rng.nextDouble(),
    ];

    for (final bounds in allBounds) {
      final im = bounds.width / 7;

      // 외곽 링 (evenOdd)
      final ringPath = Path()..fillType = PathFillType.evenOdd;
      ringPath.addRRect(RRect.fromRectAndCorners(
        bounds,
        topLeft: outerTL, topRight: outerTR,
        bottomLeft: outerBL, bottomRight: outerBR,
      ));
      ringPath.addRect(bounds.deflate(im));
      canvas.drawPath(ringPath, paint);

      // 내부 채움 (동일 파라미터 적용)
      canvas.drawPath(_innerPath(bounds.deflate(im * 2), innerType, innerCorners), paint);
    }
  }

  Path _innerPath(Rect r, _InnerShape shape, List<double> cornerRatios) {
    switch (shape) {
      case _InnerShape.square:
        final maxR = r.width * 0.4;
        return Path()..addRRect(RRect.fromRectAndCorners(r,
          topLeft:     Radius.circular(cornerRatios[0] * maxR),
          topRight:    Radius.circular(cornerRatios[1] * maxR),
          bottomLeft:  Radius.circular(cornerRatios[2] * maxR),
          bottomRight: Radius.circular(cornerRatios[3] * maxR),
        ));
      case _InnerShape.circle:
        return Path()..addOval(r);
      case _InnerShape.diamond:
        return Path()
          ..moveTo(r.center.dx, r.top)
          ..lineTo(r.right, r.center.dy)
          ..lineTo(r.center.dx, r.bottom)
          ..lineTo(r.left, r.center.dy)
          ..close();
      case _InnerShape.star:
        return _ComboFinderPattern._starPath(r.center, r.width / 2, r.width * 0.22, 4);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _RandomFinderPattern && color == other.color && seed == other.seed;

  @override
  int get hashCode => Object.hash(color, seed);
}

/// 템플릿 썸네일에서도 공용 사용 가능한 그라디언트 셰이더 빌더.
Shader buildQrGradientShader(QrGradient gradient, Rect bounds) {
  final colors = gradient.colors;
  final stops = gradient.stops;

  if (gradient.type == 'radial') {
    return RadialGradient(
      colors: colors,
      stops: stops,
    ).createShader(bounds);
  }

  // linear (기본)
  final rad = gradient.angleDegrees * 3.14159 / 180;
  return LinearGradient(
    colors: colors,
    stops: stops,
    transform: GradientRotation(rad),
  ).createShader(bounds);
}
