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

  // ── 로고 타입 확장 (logo-tab-redesign) — 모두 optional ─────────────────
  /// 'logo' | 'image' | 'text' — null 이면 레거시 경로.
  final String? logoType;

  /// LogoType.logo: "social/twitter" 형식.
  final String? logoAssetId;

  /// LogoType.image: 256×256 JPEG Q85 base64.
  final String? logoImageBase64;

  /// LogoType.text: 로고 전용 텍스트.
  final StickerTextSpec? logoText;

  /// 배경 fill 색상 ARGB int. null = 기본 흰색.
  final int? logoBackgroundColorArgb;

  const StickerSpec({
    this.logoPosition = 'center',
    this.logoBackground = 'none',
    this.topText,
    this.bottomText,
    this.logoType,
    this.logoAssetId,
    this.logoImageBase64,
    this.logoText,
    this.logoBackgroundColorArgb,
  });

  Map<String, dynamic> toJson() => {
        'logoPosition': logoPosition,
        'logoBackground': logoBackground,
        'topText': topText?.toJson(),
        'bottomText': bottomText?.toJson(),
        if (logoType != null) 'logoType': logoType,
        if (logoAssetId != null) 'logoAssetId': logoAssetId,
        if (logoImageBase64 != null) 'logoImageBase64': logoImageBase64,
        if (logoText != null) 'logoText': logoText!.toJson(),
        if (logoBackgroundColorArgb != null)
          'logoBackgroundColorArgb': logoBackgroundColorArgb,
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
        logoType: json['logoType'] as String?,
        logoAssetId: json['logoAssetId'] as String?,
        logoImageBase64: json['logoImageBase64'] as String?,
        logoText: json['logoText'] != null
            ? StickerTextSpec.fromJson(json['logoText'] as Map<String, dynamic>)
            : null,
        // 레거시 키 `logoBackgroundBorderColorArgb` 도 읽어서 신 키로 매핑
        // (pre-release 데이터 호환용)
        logoBackgroundColorArgb:
            (json['logoBackgroundColorArgb'] as num?)?.toInt() ??
                (json['logoBackgroundBorderColorArgb'] as num?)?.toInt(),
      );
}
