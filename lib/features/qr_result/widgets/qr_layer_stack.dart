import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';
import '../domain/entities/logo_source.dart' show LogoType;
import '../domain/entities/qr_dot_style.dart' show QrDotStyleToParams;
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

  // (deepLink, ecLevel) 키가 같을 때 QrImage 재사용 — 애니메이션 중 parent rebuild 로
  // 60fps 재계산되던 QrCode.fromData() 를 제거해 매 프레임 비용을 0 에 가깝게 낮춘다.
  String? _cachedDeepLink;
  int? _cachedEcLevel;
  QrImage? _cachedQrImage;

  QrImage _qrImageFor(String deepLink, int ecLevel) {
    if (_cachedDeepLink == deepLink &&
        _cachedEcLevel == ecLevel &&
        _cachedQrImage != null) {
      return _cachedQrImage!;
    }
    final qrCode = QrCode.fromData(data: deepLink, errorCorrectLevel: ecLevel);
    final img = QrImage(qrCode);
    _cachedDeepLink = deepLink;
    _cachedEcLevel = ecLevel;
    _cachedQrImage = img;
    return img;
  }

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
    return state.style.customEyeParams != null ||
        !state.style.boundaryParams.isDefault ||
        state.style.animationParams.isAnimated;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrResultProvider);
    final sticker = state.sticker;
    final iconProvider = centerImageProvider(state);
    final isTextLogo = state.logo.embedIcon && sticker.logoType == LogoType.text;
    final useCustom = _useCustomPainter(state);

    _ensureAnimController(state.style.animationParams.isAnimated);

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
              color: state.style.quietZoneColor == Colors.transparent
                  ? null
                  : state.style.quietZoneColor,
              padding: EdgeInsets.all(quietPadding),
              child: qrWidget,
            ),
          ),
          if (iconProvider != null)
            _LogoWidget(
              sticker: sticker,
              iconProvider: iconProvider,
              size: widget.size,
            )
          else if (isTextLogo && sticker.logoText != null &&
              !sticker.logoText!.isEmpty)
            _LogoWidget.text(
              sticker: sticker,
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
    final embedInQr = state.logo.embedIcon &&
        centerImageProvider(state) != null &&
        state.sticker.logoPosition == LogoPosition.center;
    final ecLevel =
        embedInQr ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
    final qrImage = _qrImageFor(widget.deepLink, ecLevel);

    // 그라디언트 셰이더
    final activeGradient = state.template.templateGradient ?? state.style.customGradient;
    final color = activeGradient != null ? Colors.black : state.style.qrColor;

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
            dotParams: state.style.customDotParams ?? state.style.dotStyle.toDotShapeParams(),
            eyeParams: state.style.customEyeParams ?? const EyeShapeParams(),
            boundaryParams: state.style.boundaryParams,
            animParams: state.style.animationParams,
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
          dotParams: state.style.customDotParams ?? state.style.dotStyle.toDotShapeParams(),
          eyeParams: state.style.customEyeParams ?? const EyeShapeParams(),
          boundaryParams: state.style.boundaryParams,
          animParams: state.style.animationParams,
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
  final ImageProvider? iconProvider;
  final double size;
  final bool isText;

  const _LogoWidget({
    required this.sticker,
    required this.iconProvider,
    required this.size,
  }) : isText = false;

  const _LogoWidget.text({
    required this.sticker,
    required this.size,
  })  : iconProvider = null,
        isText = true;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.22;
    final Widget iconWidget = _buildIconWithBackground(iconSize);

    if (sticker.logoPosition == LogoPosition.center) {
      return Positioned.fill(child: Center(child: iconWidget));
    } else {
      return Positioned(
        right: 8,
        bottom: 8,
        child: iconWidget,
      );
    }
  }

  /// 아이콘(이미지 or 텍스트) 컨텐츠 빌드.
  /// [wrapWidth] == true 이면 텍스트 폭에 맞춰 Intrinsic 으로 렌더 (rectangle 배경용).
  Widget _buildContent(double iconSize, {bool wrapWidth = false}) {
    if (isText) {
      final t = sticker.logoText!;
      final textStyle = TextStyle(
        color: t.color,
        fontFamily: t.fontFamily,
        fontSize: t.fontSize,
        fontWeight: FontWeight.w600,
        height: 1.1,
      );
      if (wrapWidth) {
        // rectangle / roundedRectangle: 폭은 텍스트 자연 크기, height는 텍스트 기준.
        return Text(
          t.content,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
      }
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: Center(
          child: Text(
            t.content,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      );
    }
    return ClipOval(
      child: Image(
        image: iconProvider!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildIconWithBackground(double iconSize) {
    // 로고 배경 fill 색상. null = 기본 흰색 (레거시 호환).
    final bgColor = sticker.logoBackgroundColor ?? Colors.white;
    const shadow = BoxShadow(color: Colors.black12, blurRadius: 2);

    switch (sticker.logoBackground) {
      case LogoBackground.none:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: _buildContent(iconSize),
        );
      case LogoBackground.square:
        return Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [shadow],
          ),
          padding: const EdgeInsets.all(4),
          child: _buildContent(iconSize),
        );
      case LogoBackground.circle:
        return Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: const [shadow],
          ),
          padding: const EdgeInsets.all(4),
          child: _buildContent(iconSize),
        );
      case LogoBackground.rectangle:
      case LogoBackground.roundedRectangle:
        // 텍스트 폭에 맞추는 직사각형 배경.
        // 비-텍스트 타입에도 정의는 유효 (iconSize × iconSize+padding 기본 사각으로 렌더).
        final radius = sticker.logoBackground == LogoBackground.roundedRectangle
            ? 14.0
            : 4.0;
        // QR 가독성 보호: 로고 영역이 너무 커지지 않도록 maxWidth 제한 (QR 60%)
        final maxW = size * 0.6;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [shadow],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: isText
                ? _buildContent(iconSize, wrapWidth: true)
                : SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: _buildContent(iconSize),
                  ),
          ),
        );
    }
  }
}
