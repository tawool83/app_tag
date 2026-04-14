import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/sticker_config.dart';
import '../qr_result_provider.dart';
import 'qr_preview_section.dart' show buildPrettyQr, centerImageProvider;

/// QR 결과 화면의 3-레이어 렌더링 위젯.
///
/// 렌더링 순서 (아래 → 위):
///   Layer 0: BackgroundLayer  — 갤러리 이미지 or 흰 배경
///   Layer 1: QrLayer          — 콰이어트 존 + buildPrettyQr()
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
    final bg = state.background;
    final sticker = state.sticker;
    final iconProvider = centerImageProvider(state);

    // 콰이어트 존 패딩: QR 크기의 5% (최소 8px, 최대 20px)
    final quietPadding = (size * 0.05).clamp(8.0, 20.0);
    final qrSize = size - quietPadding * 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Layer 0: 배경 ──────────────────────────────────────────────
          Positioned.fill(
            child: bg.hasImage
                ? Transform.scale(
                    scale: bg.scale,
                    child: Image.memory(
                      bg.imageBytes!,
                      fit: bg.fit,
                      width: size,
                      height: size,
                    ),
                  )
                : Container(color: Colors.white),
          ),

          // ── Layer 1: QR (콰이어트 존 + buildPrettyQr) ──────────────────
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

          // ── Layer 2: 스티커 ────────────────────────────────────────────
          // 상단 텍스트
          if (sticker.hasTopText)
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: _StickerTextWidget(text: sticker.topText!),
            ),

          // 로고
          if (iconProvider != null)
            _LogoWidget(
              sticker: sticker,
              iconProvider: iconProvider,
              size: size,
              hasBottomText: sticker.hasBottomText,
            ),

          // 하단 텍스트
          if (sticker.hasBottomText)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: _StickerTextWidget(text: sticker.bottomText!),
            ),
        ],
      ),
    );
  }
}

// ── 스티커 텍스트 위젯 ─────────────────────────────────────────────────────────

class _StickerTextWidget extends StatelessWidget {
  final StickerText text;

  const _StickerTextWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.content,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: text.color,
        fontFamily: text.fontFamily,
        fontSize: text.fontSize,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(color: Colors.white, blurRadius: 3),
          Shadow(color: Colors.white, blurRadius: 6),
        ],
      ),
    );
  }
}

// ── 로고 위젯 ──────────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final StickerConfig sticker;
  final ImageProvider iconProvider;
  final double size;
  final bool hasBottomText;

  const _LogoWidget({
    required this.sticker,
    required this.iconProvider,
    required this.size,
    required this.hasBottomText,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.22;
    final Widget iconWidget = _buildIconWithBackground(iconSize);

    if (sticker.logoPosition == LogoPosition.center) {
      return Positioned.fill(child: Center(child: iconWidget));
    } else {
      // bottomRight — 하단 텍스트가 있으면 위로 올림
      final bottom = hasBottomText ? size * 0.12 : 8.0;
      return Positioned(
        right: 8,
        bottom: bottom,
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
