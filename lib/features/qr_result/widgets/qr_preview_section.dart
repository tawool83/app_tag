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
            Expanded(
              flex: 7,
              child: Align(
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 캡처 영역 (소형 QR)
                    RepaintBoundary(
                      key: repaintKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrLayerStack(deepLink: deepLink, size: 160),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrLayerStack(deepLink: deepLink, size: 300, isDialog: true),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
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
  final PrettyQrShape finderPattern = state.randomEyeSeed != null
      ? _RandomFinderPattern(color: dotColor, seed: state.randomEyeSeed!)
      : _ComboFinderPattern(
          color: dotColor,
          outer: _outerShapeFrom(state.eyeOuter),
          inner: _innerShapeFrom(state.eyeInner),
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

_OuterShape _outerShapeFrom(QrEyeOuter v) {
  switch (v) {
    case QrEyeOuter.square:  return _OuterShape.square;
    case QrEyeOuter.rounded: return _OuterShape.rounded;
    case QrEyeOuter.circle:  return _OuterShape.circle;
    case QrEyeOuter.smooth:  return _OuterShape.smooth;
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

/// 3개 finder pattern 모듈을 7m×7m 블록 단위로 분리해 각 bounding box 반환.
/// context.matrix는 3개 코너 전체 모듈을 포함하므로 개별 분리가 필수.
List<Rect> _groupFinderBounds(PrettyQrPaintingContext context) {
  final rects = <Rect>[];
  for (final module in context.matrix) {
    if (!module.isDark) continue;
    rects.add(module.resolveRect(context));
  }
  if (rects.isEmpty) return [];

  final m = rects.first.width;
  var minX = rects.first.left;
  var minY = rects.first.top;
  for (final r in rects) {
    if (r.left < minX) minX = r.left;
    if (r.top  < minY) minY = r.top;
  }

  final blocks = <String, Rect>{};
  for (final r in rects) {
    final bx = ((r.left - minX) / (m * 7)).floor();
    final by = ((r.top  - minY) / (m * 7)).floor();
    final key = '$bx,$by';
    final prev = blocks[key];
    blocks[key] = prev == null ? r : prev.expandToInclude(r);
  }
  return blocks.values.toList();
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

  const _ComboFinderPattern({
    required this.color,
    required this.outer,
    required this.inner,
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
    ringPath.addRect(holeRect); // 구멍은 사각형 유지
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
      inner == other.inner;

  @override
  int get hashCode => Object.hash(color, outer, inner);
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
    final rng = math.Random(seed);
    final paint = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    final canvas = context.canvas;

    for (final bounds in _groupFinderBounds(context)) {
      final m = bounds.width / 7;
      final maxR = m * 1.8;

      // 코너별 독립 곡률 (0 ~ 1.8 모듈)
      final tl = Radius.circular(rng.nextDouble() * maxR);
      final tr = Radius.circular(rng.nextDouble() * maxR);
      final bl = Radius.circular(rng.nextDouble() * maxR);
      final br = Radius.circular(rng.nextDouble() * maxR);

      // 내부 채움 모양: square / circle / diamond / star 중 랜덤
      final innerType = _InnerShape.values[rng.nextInt(_InnerShape.values.length)];

      // 외곽 링 (evenOdd: 외곽 RRect - 사각형 구멍 → 링)
      final ringPath = Path()..fillType = PathFillType.evenOdd;
      ringPath.addRRect(RRect.fromRectAndCorners(
        bounds, topLeft: tl, topRight: tr, bottomLeft: bl, bottomRight: br,
      ));
      ringPath.addRect(bounds.deflate(m));
      canvas.drawPath(ringPath, paint);

      // 내부 채움
      canvas.drawPath(_innerPath(bounds.deflate(m * 2), innerType, rng), paint);
    }
  }

  Path _innerPath(Rect r, _InnerShape shape, math.Random rng) {
    switch (shape) {
      case _InnerShape.square:
        final maxR = r.width * 0.4;
        return Path()..addRRect(RRect.fromRectAndCorners(r,
          topLeft:     Radius.circular(rng.nextDouble() * maxR),
          topRight:    Radius.circular(rng.nextDouble() * maxR),
          bottomLeft:  Radius.circular(rng.nextDouble() * maxR),
          bottomRight: Radius.circular(rng.nextDouble() * maxR),
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
