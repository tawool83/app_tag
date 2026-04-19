import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';
import '../domain/entities/qr_shape_params.dart';
import '../domain/entities/sticker_config.dart';
import '../qr_result_provider.dart';
import 'custom_qr_painter.dart';
import 'qr_preview_section.dart' show buildPrettyQr, centerImageProvider, buildQrGradientShader;

/// QR 결과 화면의 레이어 렌더링 위젯.
///
/// 렌더링 순서 (아래 → 위):
///   Layer 0: 흰 배경 (qr 배경 이미지 기능은 제거됨)
///   Layer 1: QrLayer          — 콰이어트 존 + CustomQrPainter (size×size, 중앙)
///   Layer 2: StickerLayer     — 로고 + 상/하단 텍스트
///
/// customDotParams 또는 customEyeParams가 설정된 경우 CustomQrPainter를 사용하고,
/// 그렇지 않으면 기존 buildPrettyQr()로 폴백합니다.
class QrLayerStack extends ConsumerStatefulWidget {
  final String deepLink;
  final double size;
  final bool isDialog;

  const QrLayerStack({
    super.key,
    required this.deepLink,
    this.size = 160,
    this.isDialog = false,
  });

  @override
  ConsumerState<QrLayerStack> createState() => _QrLayerStackState();
}

class _QrLayerStackState extends ConsumerState<QrLayerStack>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  void _ensureAnimController(bool needsAnim) {
    if (needsAnim && _animController == null) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
    } else if (!needsAnim && _animController != null) {
      _animController!.dispose();
      _animController = null;
    }
  }

  /// CustomQrPainter를 사용할지 여부 판단.
  /// customDotParams 는 PrettyQrView 경로(PolarDotSymbol)로 처리되므로 제외.
  bool _useCustomPainter(QrResultState state) {
    return state.customEyeParams != null ||
        !state.boundaryParams.isDefault ||
        state.animationParams.isAnimated;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrResultProvider);
    final sticker = state.sticker;
    final iconProvider = centerImageProvider(state);
    final useCustom = _useCustomPainter(state);

    _ensureAnimController(state.animationParams.isAnimated);

    // 콰이어트 존 패딩: QR 크기의 5% (최소 8px, 최대 20px)
    final quietPadding = (widget.size * 0.05).clamp(8.0, 20.0);
    final qrSize = widget.size - quietPadding * 2;

    // ── QR 렌더링 위젯 결정 ──
    final Widget qrWidget;
    if (useCustom) {
      qrWidget = _buildCustomQr(state, qrSize);
    } else {
      qrWidget = buildPrettyQr(
        state,
        deepLink: widget.deepLink,
        size: qrSize,
        isDialog: widget.isDialog,
      );
    }

    // ── Layer 1+2: QR + 로고 (size×size) ─────────────────────────────
    final Widget qrAndLogo = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Container(
              color: state.quietZoneColor == Colors.transparent
                  ? null
                  : state.quietZoneColor,
              padding: EdgeInsets.all(quietPadding),
              child: qrWidget,
            ),
          ),
          if (iconProvider != null)
            _LogoWidget(
              sticker: sticker,
              iconProvider: iconProvider,
              size: widget.size,
            ),
        ],
      ),
    );

    // 상단/하단 텍스트는 캔버스 밖 Column으로 배치
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sticker.hasTopText)
          _StickerTextWidget(text: sticker.topText!, width: widget.size),
        qrAndLogo,
        if (sticker.hasBottomText)
          _StickerTextWidget(text: sticker.bottomText!, width: widget.size),
      ],
    );
  }

  Widget _buildCustomQr(QrResultState state, double qrSize) {
    // QR 매트릭스 생성
    final embedInQr = state.embedIcon &&
        centerImageProvider(state) != null &&
        state.sticker.logoPosition == LogoPosition.center;
    final ecLevel =
        embedInQr ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
    final qrCode = QrCode.fromData(
      data: widget.deepLink,
      errorCorrectLevel: ecLevel,
    );
    final qrImage = QrImage(qrCode);

    // 그라디언트 셰이더
    final activeGradient = state.templateGradient ?? state.customGradient;
    final color = activeGradient != null ? Colors.black : state.qrColor;

    // 애니메이션이 있으면 AnimatedBuilder로 감싸기
    Widget painterWidget;
    if (_animController != null) {
      painterWidget = AnimatedBuilder(
        animation: _animController!,
        builder: (_, __) => CustomPaint(
          size: Size.square(qrSize),
          painter: CustomQrPainter(
            qrImage: qrImage,
            color: color,
            dotParams: state.customDotParams ?? const DotShapeParams(),
            eyeParams: state.customEyeParams ?? const EyeShapeParams(),
            boundaryParams: state.boundaryParams,
            animParams: state.animationParams,
            animValue: _animController!.value,
          ),
        ),
      );
    } else {
      painterWidget = CustomPaint(
        size: Size.square(qrSize),
        painter: CustomQrPainter(
          qrImage: qrImage,
          color: color,
          dotParams: state.customDotParams ?? const DotShapeParams(),
          eyeParams: state.customEyeParams ?? const EyeShapeParams(),
          boundaryParams: state.boundaryParams,
          animParams: state.animationParams,
        ),
      );
    }

    // 그라디언트 적용
    if (activeGradient != null) {
      return SizedBox(
        width: qrSize,
        height: qrSize,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              buildQrGradientShader(activeGradient, bounds),
          child: painterWidget,
        ),
      );
    }

    return SizedBox(width: qrSize, height: qrSize, child: painterWidget);
  }
}

// ── 스티커 텍스트 위젯 ─────────────────────────────────────────────────────────

class _StickerTextWidget extends StatelessWidget {
  final StickerText text;
  final double width;

  const _StickerTextWidget({required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          text.content,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: text.color,
            fontFamily: text.fontFamily,
            fontSize: text.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── 로고 위젯 ──────────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final StickerConfig sticker;
  final ImageProvider iconProvider;
  final double size;

  const _LogoWidget({
    required this.sticker,
    required this.iconProvider,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.22;
    final Widget iconWidget = _buildIconWithBackground(iconSize);

    if (sticker.logoPosition == LogoPosition.center) {
      return Positioned.fill(child: Center(child: iconWidget));
    } else {
      // bottomRight — 텍스트는 이제 Stack 밖이므로 고정 bottom 사용
      return Positioned(
        right: 8,
        bottom: 8,
        child: iconWidget,
      );
    }
  }

  Widget _buildIconWithBackground(double iconSize) {
    final imgWidget = ClipOval(
      child: Image(
        image: iconProvider,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );

    switch (sticker.logoBackground) {
      case LogoBackground.none:
        return SizedBox(width: iconSize, height: iconSize, child: imgWidget);
      case LogoBackground.square:
        return Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          padding: const EdgeInsets.all(4),
          child: imgWidget,
        );
      case LogoBackground.circle:
        return Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          padding: const EdgeInsets.all(4),
          child: imgWidget,
        );
    }
  }
}
