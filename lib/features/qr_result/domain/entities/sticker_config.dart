import 'dart:ui' show Color;

const _stickerSentinel = Object();

enum LogoPosition { center, bottomRight }

enum LogoBackground { none, square, circle }

/// 스티커 텍스트 (상단 또는 하단).
class StickerText {
  final String content;
  final Color color;
  final String fontFamily; // 'sans-serif' | 'serif' | 'monospace'
  final double fontSize;   // 10 ~ 64

  const StickerText({
    required this.content,
    this.color = const Color(0xFF000000),
    this.fontFamily = 'sans-serif',
    this.fontSize = 14,
  });

  bool get isEmpty => content.trim().isEmpty;

  StickerText copyWith({
    String? content,
    Color? color,
    String? fontFamily,
    double? fontSize,
  }) =>
      StickerText(
        content: content ?? this.content,
        color: color ?? this.color,
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
      );
}

/// QR 스티커 레이어 설정 (최상단 레이어).
/// 로고 위치/배경 + 상단/하단 텍스트를 관리합니다.
class StickerConfig {
  final LogoPosition logoPosition;
  final LogoBackground logoBackground;
  final StickerText? topText;
  final StickerText? bottomText;

  const StickerConfig({
    this.logoPosition = LogoPosition.center,
    this.logoBackground = LogoBackground.none,
    this.topText,
    this.bottomText,
  });

  bool get hasTopText => topText != null && !topText!.isEmpty;
  bool get hasBottomText => bottomText != null && !bottomText!.isEmpty;

  StickerConfig copyWith({
    LogoPosition? logoPosition,
    LogoBackground? logoBackground,
    Object? topText = _stickerSentinel,
    Object? bottomText = _stickerSentinel,
  }) =>
      StickerConfig(
        logoPosition: logoPosition ?? this.logoPosition,
        logoBackground: logoBackground ?? this.logoBackground,
        topText: topText == _stickerSentinel ? this.topText : topText as StickerText?,
        bottomText:
            bottomText == _stickerSentinel ? this.bottomText : bottomText as StickerText?,
      );
}
