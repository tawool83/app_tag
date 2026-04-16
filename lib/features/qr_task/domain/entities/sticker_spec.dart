/// QR 스티커 텍스트 (도메인 순수 표현).
class StickerTextSpec {
  final String content;
  final int colorArgb;
  final String fontFamily;
  final double fontSize;

  const StickerTextSpec({
    required this.content,
    this.colorArgb = 0xFF000000,
    this.fontFamily = 'sans-serif',
    this.fontSize = 14,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'colorArgb': colorArgb,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
      };

  factory StickerTextSpec.fromJson(Map<String, dynamic> json) => StickerTextSpec(
        content: json['content'] as String? ?? '',
        colorArgb: (json['colorArgb'] as num?)?.toInt() ?? 0xFF000000,
        fontFamily: json['fontFamily'] as String? ?? 'sans-serif',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
      );
}

/// QR 스티커 레이어 사양 (로고 + 상/하단 텍스트).
class StickerSpec {
  /// 'center' | 'bottomRight'
  final String logoPosition;

  /// 'none' | 'square' | 'circle'
  final String logoBackground;

  final StickerTextSpec? topText;
  final StickerTextSpec? bottomText;

  const StickerSpec({
    this.logoPosition = 'center',
    this.logoBackground = 'none',
    this.topText,
    this.bottomText,
  });

  Map<String, dynamic> toJson() => {
        'logoPosition': logoPosition,
        'logoBackground': logoBackground,
        'topText': topText?.toJson(),
        'bottomText': bottomText?.toJson(),
      };

  factory StickerSpec.fromJson(Map<String, dynamic> json) => StickerSpec(
        logoPosition: json['logoPosition'] as String? ?? 'center',
        logoBackground: json['logoBackground'] as String? ?? 'none',
        topText: json['topText'] != null
            ? StickerTextSpec.fromJson(json['topText'] as Map<String, dynamic>)
            : null,
        bottomText: json['bottomText'] != null
            ? StickerTextSpec.fromJson(json['bottomText'] as Map<String, dynamic>)
            : null,
      );
}
