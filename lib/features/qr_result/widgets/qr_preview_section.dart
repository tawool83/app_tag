import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../domain/entities/qr_dot_style.dart';
import '../domain/entities/qr_template.dart';
import '../domain/entities/logo_source.dart' show LogoType;
import '../domain/entities/sticker_config.dart' show LogoPosition;
import '../data/services/qr_readability_service.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_shape_params.dart';
import '../domain/entities/qr_eye_shapes.dart';
import '../domain/entities/qr_preview_mode.dart';
import '../qr_result_provider.dart' show QrResultState, qrResultProvider, shapePreviewModeProvider;
import '../utils/polar_polygon.dart';
import '../utils/superellipse.dart';
import '../utils/qr_boundary_clipper.dart';
import '../utils/qr_margin_painter.dart';
import '../../../l10n/app_localizations.dart';
import 'qr_layer_stack.dart';

/// 소형(160px) QR 미리보기 + 돋보기 확대 버튼.
/// RepaintBoundary를 포함하여 캡처 기준이 됩니다.
///
/// ShapePreviewMode에 따라:
///   fullQr / dedicatedAnim → 전체 QR (QrLayerStack)
///   dedicatedDot → 단일 도트 확대 미리보기
///   dedicatedEye → 단일 finder pattern 확대 미리보기
///   dedicatedBoundary → 외곽 클리핑 윤곽선 미리보기
class QrPreviewSection extends ConsumerWidget {
  final GlobalKey repaintKey;
  final String deepLink;

  const QrPreviewSection({
    super.key,
    required this.repaintKey,
    required this.deepLink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final previewMode = ref.watch(shapePreviewModeProvider);

    // 고정 높이: QR 160 + padding 24 = 184 + deepLink 텍스트 ~18 = ~202
    // 미리보기 모드 전환 시 레이아웃 점프 방지
    const previewBoxHeight = 184.0;

    return Column(
      children: [
        GestureDetector(
          onTap: previewMode == ShapePreviewMode.fullQr
              ? () => _showQrZoomDialog(context, state, deepLink)
              : null,
          child: SizedBox(
            height: previewBoxHeight,
            child: ClipRect(
              child: RepaintBoundary(
                key: repaintKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    // 2-layer: fullQr 항상 bottom, dedicated overlay top.
                    // dedicated 진입 = 즉시 show, 이탈 = 500ms fade-out (비대칭).
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: QrLayerStack(deepLink: deepLink, size: 160),
                        ),
                        _OverlayedDedicatedPreview(
                          mode: previewMode,
                          state: state,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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

// ── Overlayed Dedicated Preview (비대칭 fade 제어) ───────────────────────────
//
// Layer 2 — dedicated 미리보기 overlay.
//   진입(→ dedicated*): 즉시 opacity=1 (fade 없음)
//   이탈(→ fullQr):     opacity 1→0 over 500ms
//   완전 fade 완료 시 내부 위젯 언마운트.
// AnimatedSwitcher 를 쓰지 않으므로 key 충돌 없음.

class _OverlayedDedicatedPreview extends StatefulWidget {
  final ShapePreviewMode mode;
  final QrResultState state;

  const _OverlayedDedicatedPreview({required this.mode, required this.state});

  @override
  State<_OverlayedDedicatedPreview> createState() =>
      _OverlayedDedicatedPreviewState();
}

class _OverlayedDedicatedPreviewState extends State<_OverlayedDedicatedPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  ShapePreviewMode? _activeMode;

  static bool _isDedicated(ShapePreviewMode m) =>
      m == ShapePreviewMode.dedicatedDot ||
      m == ShapePreviewMode.dedicatedEye ||
      m == ShapePreviewMode.dedicatedBoundary;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: _isDedicated(widget.mode) ? 1.0 : 0.0,
    );
    _fade.addStatusListener(_onFadeStatus);
    if (_isDedicated(widget.mode)) _activeMode = widget.mode;
  }

  @override
  void didUpdateWidget(_OverlayedDedicatedPreview old) {
    super.didUpdateWidget(old);
    if (_isDedicated(widget.mode)) {
      // dedicated 진입 또는 mode 간 전환, 혹은 드래그 중 param 업데이트.
      // 즉시 show (value=1). 기존 reverse 진행 중이면 취소.
      _activeMode = widget.mode;
      _fade.value = 1.0;
    } else if (_isDedicated(old.mode)) {
      // dedicated → fullQr 이탈 → 500ms fade out.
      _fade.reverse();
    }
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() => _activeMode = null);
    }
  }

  @override
  void dispose() {
    _fade.removeStatusListener(_onFadeStatus);
    _fade.dispose();
    super.dispose();
  }

  Widget _buildDedicatedFor(ShapePreviewMode mode) {
    final s = widget.state.style;
    return switch (mode) {
      ShapePreviewMode.dedicatedDot => _DotShapePreview(
          params: s.customDotParams ?? s.dotStyle.toDotShapeParams(),
          color: s.qrColor,
        ),
      ShapePreviewMode.dedicatedEye => _EyeShapePreview(
          params: s.customEyeParams ?? const EyeShapeParams(),
          color: s.qrColor,
        ),
      ShapePreviewMode.dedicatedBoundary => _BoundaryShapePreview(
          params: s.boundaryParams,
          color: s.qrColor,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final mode = _activeMode;
    if (mode == null) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _fade,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _buildDedicatedFor(mode),
      ),
    );
  }
}

// ── 전용 미리보기 위젯들 ──────────────────────────────────────────────────────

/// 단일 도트 확대 미리보기. 미리보기 영역의 80%.
class _DotShapePreview extends StatelessWidget {
  final DotShapeParams params;
  final Color color;

  const _DotShapePreview({required this.params, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _DotPreviewPainter(params: params, color: color),
      ),
    );
  }
}

class _DotPreviewPainter extends CustomPainter {
  final DotShapeParams params;
  final Color color;

  const _DotPreviewPainter({required this.params, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4 * params.scale;
    final path = PolarPolygon.buildPath(center, radius, params);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_DotPreviewPainter old) =>
      params != old.params || color != old.color;
}

/// 단일 finder pattern 확대 미리보기. 미리보기 영역의 80%.
class _EyeShapePreview extends StatelessWidget {
  final EyeShapeParams params;
  final Color color;

  const _EyeShapePreview({required this.params, required this.color});

  static const _labelStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF424242), // grey.shade800 — 밝은 배경 위 가독성
    fontWeight: FontWeight.w700,
  );

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xE6FFFF00), // white 90%
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: _labelStyle),
      );

  @override
  Widget build(BuildContext context) {
    // 슬라이더 Q1~Q4 의 위치를 미리보기 사분면에 "1,2,3,4" 숫자 라벨로 표시.
    // Q1 = top-right(1), Q2 = top-left(2), Q3 = bottom-left(3), Q4 = bottom-right(4).
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _EyePreviewPainter(params: params, color: color),
            ),
          ),
          Positioned(top: 4, right: 6, child: _chip('1')),
          Positioned(top: 4, left: 6, child: _chip('2')),
          Positioned(bottom: 4, left: 6, child: _chip('3')),
          Positioned(bottom: 4, right: 6, child: _chip('4')),
        ],
      ),
    );
  }
}

class _EyePreviewPainter extends CustomPainter {
  final EyeShapeParams params;
  final Color color;

  const _EyePreviewPainter({required this.params, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final eyeSize = size.width * 0.8;
    final bounds = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: eyeSize,
      height: eyeSize,
    );
    final paint = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    // 편집기 1-eye preview 는 local 좌표 표시 (회전 0).
    // 3-eye 회전 시각화는 상단 QR 미리보기에서 확인.
    SuperellipsePath.paintEye(canvas, bounds, params, paint, rotationDeg: 0.0);
  }

  @override
  bool shouldRepaint(_EyePreviewPainter old) =>
      params != old.params || color != old.color;
}

/// 외곽 클리핑 윤곽선 미리보기. 미리보기 영역의 90%.
class _BoundaryShapePreview extends StatelessWidget {
  final QrBoundaryParams params;
  final Color color;

  const _BoundaryShapePreview({required this.params, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _BoundaryPreviewPainter(params: params, color: color),
      ),
    );
  }
}

class _BoundaryPreviewPainter extends CustomPainter {
  final QrBoundaryParams params;
  final Color color;

  const _BoundaryPreviewPainter({required this.params, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final previewSize = size.width * 0.9;
    final offset = (size.width - previewSize) / 2;
    final previewRect = Size.square(previewSize);
    final clipPath = QrBoundaryClipper.buildClipPath(previewRect, params);

    canvas.save();
    canvas.translate(offset, offset);

    if (params.isFrameMode && clipPath != null) {
      _drawFramePreview(canvas, previewRect, clipPath);
    } else if (clipPath != null) {
      // 기존 clip 모드 미리보기
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..isAntiAlias = true;
      canvas.drawPath(clipPath, strokePaint);

      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawPath(clipPath, fillPaint);

      canvas.clipPath(clipPath);
      _drawGridPattern(canvas, previewRect, color);
    } else {
      final rect = Offset.zero & previewRect;
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0);
      _drawGridPattern(canvas, previewRect, color);
    }

    canvas.restore();
  }

  /// 프레임 모드 미리보기: 프레임 + 마진 패턴 + 중앙 QR placeholder
  void _drawFramePreview(Canvas canvas, Size previewRect, Path framePath) {
    final qrAreaSize = previewRect.width / params.frameScale;
    final center = previewRect.center(Offset.zero);

    // 1. 프레임 내부 배경
    canvas.save();
    canvas.clipPath(framePath);
    canvas.drawRect(
      Offset.zero & previewRect,
      Paint()..color = color.withValues(alpha: 0.08),
    );

    // 2. 마진 패턴 (QR 영역 제외)
    final qrRect = Rect.fromCenter(
      center: center,
      width: qrAreaSize,
      height: qrAreaSize,
    );
    final qrPath = Path()..addRect(qrRect);
    final marginClip = Path.combine(PathOperation.difference, framePath, qrPath);
    canvas.save();
    canvas.clipPath(marginClip);
    QrMarginPatternEngine.drawGrid(
      canvas, previewRect, color.withValues(alpha: 0.3), params.patternDensity,
    );
    canvas.restore();

    // 3. QR placeholder (체커보드)
    canvas.save();
    canvas.clipRect(qrRect);
    _drawGridPattern(canvas, previewRect, color, qrRect);
    canvas.restore();

    // 4. 프레임 외곽선
    canvas.drawPath(framePath, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true);

    canvas.restore();
  }

  void _drawGridPattern(Canvas canvas, Size size, Color color, [Rect? bounds]) {
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    const gridCount = 7;
    final area = bounds ?? (Offset.zero & size);
    final cellSize = area.width / gridCount;
    final margin = cellSize * 0.15;
    for (int r = 0; r < gridCount; r++) {
      for (int c = 0; c < gridCount; c++) {
        if ((r + c) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              area.left + c * cellSize + margin,
              area.top + r * cellSize + margin,
              cellSize - margin * 2,
              cellSize - margin * 2,
            ),
            gridPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoundaryPreviewPainter old) =>
      params != old.params || color != old.color;
}

// ── 확대 다이얼로그 ────────────────────────────────────────────────────────────

void _showQrZoomDialog(
    BuildContext context, QrResultState state, String deepLink) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (_, constraints) {
                // 기기가 지원하는 최대 크기 (가로/세로 중 작은 값, 패딩 제외)
                final maxSide =
                    constraints.biggest.shortestSide - 48; // 양쪽 24px 여백
                final double qrSize = maxSide.clamp(100.0, 600.0);
                return GestureDetector(
                  onTap: () {}, // 내부 탭 시 닫힘 방지
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrLayerStack(
                        deepLink: deepLink, size: qrSize, isDialog: true),
                  ),
                );
              },
            ),
          ),
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
  final activeGradient = state.template.templateGradient ?? state.style.customGradient;
  final hasGradient = activeGradient != null;
  final ecLevel =
      embedInQr ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
  final dotColor = hasGradient ? Colors.black : state.style.qrColor;

  // 맞춤 도트가 설정되면 PolarPolygon 기반 PrettyQrShape 사용 (QR 스펙 보존)
  final PrettyQrShape dotShape;
  if (state.style.customDotParams != null) {
    dotShape = buildCustomDotShape(state.style.customDotParams!, dotColor);
  } else {
    dotShape = buildDotShape(state.style.dotStyle, dotColor);
  }

  // finder pattern 결정: 랜덤 시드 우선, 아니면 outer+inner 조합
  // circleRound 외각 선택 시 hole도 원형으로 자동 파생
  final PrettyQrShape finderPattern = state.style.randomEyeSeed != null
      ? _RandomFinderPattern(color: dotColor, seed: state.style.randomEyeSeed!)
      : _ComboFinderPattern(
          color: dotColor,
          outer: _outerShapeFrom(state.style.eyeOuter),
          inner: _innerShapeFrom(state.style.eyeInner),
          hole: _holeFromOuter(state.style.eyeOuter),
        );
  final qrShape = PrettyQrShape.custom(dotShape, finderPattern: finderPattern);

  // ValueKey: decoration 관련 state가 변경될 때 위젯을 강제 재생성해
  // PrettyQrRenderView 내부 repaint boundary 이슈를 우회합니다.
  // isDialog: 팝업에서 같은 key 충돌 방지
  final qrKey = ValueKey(Object.hash(
    isDialog,
    deepLink,
    state.style.dotStyle,
    state.style.customDotParams,
    state.style.eyeOuter,
    state.style.eyeInner,
    state.style.randomEyeSeed,
    state.style.qrColor,
    state.logo.embedIcon,
    centerImage != null,
    state.template.templateGradient,
    state.style.customGradient,
    state.template.activeTemplateId,
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

// Uint8List 참조 기준 MemoryImage 캐시. 동일 바이트 참조가 넘어오면 같은 provider 반환 →
// ImageCache 가 hashCode 충돌 없이 히트해 매 프레임 재디코드를 방지.
// Expando 는 key 의 GC 와 함께 entry 가 자동 정리됨.
final Expando<MemoryImage> _memoryImageCache = Expando<MemoryImage>('_memImg');

ImageProvider _memImage(Uint8List bytes) =>
    _memoryImageCache[bytes] ??= MemoryImage(bytes);

ImageProvider? centerImageProvider(QrResultState state) {
  if (!state.logo.embedIcon) return null;
  final sticker = state.sticker;
  // 신규 로고 타입 경로 (logo-tab-redesign)
  switch (sticker.logoType) {
    case LogoType.none:
      // 사용자가 드롭다운에서 "없음" 명시적 선택 — 아이콘 표시 안 함
      return null;
    case LogoType.text:
      // 텍스트는 Image 가 아닌 Widget 오버레이로 렌더 → null 반환
      return null;
    case LogoType.image:
      if (sticker.logoImageBytes != null) {
        return _memImage(sticker.logoImageBytes!);
      }
      return null;
    case LogoType.logo:
      if (sticker.logoAssetPngBytes != null) {
        return _memImage(sticker.logoAssetPngBytes!);
      }
      // 래스터화 결과가 아직 없으면 래거시 fallback 으로 내려감
      break;
    case null:
      break;
  }
  // 레거시 경로 (기존 저장 QR 호환)
  if (state.template.templateCenterIconBytes != null) {
    return _memImage(state.template.templateCenterIconBytes!);
  }
  if (state.logo.emojiIconBytes != null) return _memImage(state.logo.emojiIconBytes!);
  if (state.logo.defaultIconBytes != null) return _memImage(state.logo.defaultIconBytes!);
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

Alignment _gradientCenter(String? center) {
  switch (center) {
    case 'topLeft':
      return Alignment.topLeft;
    case 'topRight':
      return Alignment.topRight;
    case 'bottomLeft':
      return Alignment.bottomLeft;
    case 'bottomRight':
      return Alignment.bottomRight;
    default:
      return Alignment.center;
  }
}

/// 템플릿 썸네일에서도 공용 사용 가능한 그라디언트 셰이더 빌더.
Shader buildQrGradientShader(QrGradient gradient, Rect bounds) {
  final colors = gradient.colors;
  final stops = gradient.stops;

  if (gradient.type == 'radial') {
    final align = _gradientCenter(gradient.center);
    // 코너 기준이면 대각선까지 커버하도록 radius 확대 (기본 0.5 → 1.4)
    final radius = (align == Alignment.center) ? 0.5 : 1.4;
    return RadialGradient(
      center: align,
      radius: radius,
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
