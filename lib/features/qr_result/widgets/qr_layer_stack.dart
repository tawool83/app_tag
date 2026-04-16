import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/sticker_config.dart';
import '../qr_result_provider.dart';
import 'qr_preview_section.dart' show buildPrettyQr, centerImageProvider;

/// QR 결과 화면의 레이어 렌더링 위젯.
///
/// 렌더링 순서 (아래 → 위):
///   Layer 0: 흰 배경 (qr 배경 이미지 기능은 제거됨)
///   Layer 1: QrLayer          — 콰이어트 존 + buildPrettyQr() (size×size, 중앙)
///   Layer 2: StickerLayer     — 로고 + 상/하단 텍스트
class QrLayerStack extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final sticker = state.sticker;
    final iconProvider = centerImageProvider(state);

    // 콰이어트 존 패딩: QR 크기의 5% (최소 8px, 최대 20px)
    final quietPadding = (size * 0.05).clamp(8.0, 20.0);
    final qrSize = size - quietPadding * 2;

    // ── Layer 1+2: QR + 로고 (size×size) ─────────────────────────────
    final Widget qrAndLogo = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Container(
              color: state.quietZoneColor == Colors.transparent
                  ? null
                  : state.quietZoneColor,
              padding: EdgeInsets.all(quietPadding),
              child: buildPrettyQr(
                state,
                deepLink: deepLink,
                size: qrSize,
                isDialog: isDialog,
              ),
            ),
          ),
          if (iconProvider != null)
            _LogoWidget(
              sticker: sticker,
              iconProvider: iconProvider,
              size: size,
            ),
        ],
      ),
    );

    // 상단/하단 텍스트는 캔버스 밖 Column으로 배치
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sticker.hasTopText)
          _StickerTextWidget(text: sticker.topText!, width: size),
        qrAndLogo,
        if (sticker.hasBottomText)
          _StickerTextWidget(text: sticker.bottomText!, width: size),
      ],
    );
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
