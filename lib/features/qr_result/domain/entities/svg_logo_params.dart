/// SVG 로고 임베딩 스타일 (위치, 배경, 크기).
/// QrSvgGenerator 전용 — presentation 레이어 StickerConfig 와 독립.
class SvgLogoStyle {
  /// QR 전체 크기 대비 로고 비율 (기본 0.22 — _LogoWidget 동일).
  final double sizeRatio;

  /// 'center' | 'bottomRight'
  final String position;

  /// 'none' | 'square' | 'circle' | 'rectangle' | 'roundedRectangle'
  final String background;

  /// 배경 fill 색상 ARGB. null = 흰색 (0xFFFFFFFF).
  final int? backgroundColorArgb;

  const SvgLogoStyle({
    this.sizeRatio = 0.22,
    this.position = 'center',
    this.background = 'none',
    this.backgroundColorArgb,
  });
}

/// SVG 텍스트 로고 정보 (LogoType.text 용).
class SvgLogoText {
  final String content;
  final int colorArgb;
  final String fontFamily;
  final double fontSize;

  const SvgLogoText({
    required this.content,
    this.colorArgb = 0xFF000000,
    this.fontFamily = 'sans-serif',
    this.fontSize = 14,
  });
}

/// SVG 스티커 텍스트 (상단/하단).
class SvgStickerText {
  final String content;
  final int colorArgb;
  final String fontFamily;
  final double fontSize;

  const SvgStickerText({
    required this.content,
    this.colorArgb = 0xFF000000,
    this.fontFamily = 'sans-serif',
    this.fontSize = 14,
  });
}
