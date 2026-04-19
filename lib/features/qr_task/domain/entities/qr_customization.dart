import 'qr_gradient_data.dart';
import 'sticker_spec.dart';

/// QR 꾸미기 상태 (도메인 순수 표현, JSON 직렬화 단위).
///
/// 모든 색상은 ARGB int. 모든 enum 은 String name.
/// presentation 매핑 레이어가 Flutter Color/enum 으로 변환.
class QrCustomization {
  final int qrColorArgb;
  final QrGradientData? gradient;
  final double roundFactor;

  /// QrEyeOuter.name : 'square' | 'rounded' | 'circle' | 'circleRound' | 'smooth'
  final String eyeOuter;

  /// QrEyeInner.name : 'square' | 'circle' | 'diamond' | 'star'
  final String eyeInner;

  final int? randomEyeSeed;
  final int quietZoneColorArgb;

  /// QrDotStyle.name : 'square' | 'rounded' | 'dots' | 'classy' | ...
  final String dotStyle;

  final bool embedIcon;

  /// 중앙 이모지 문자.
  final String? centerEmoji;

  /// 중앙 아이콘(렌더링된 이모지 또는 로고) PNG bytes 의 Base64.
  final String? centerIconBase64;

  final double printSizeCm;
  final StickerSpec sticker;
  final String? activeTemplateId;

  // 커스텀 모양 (qr-custom-shape). null = 기존 enum 사용.
  final Map<String, dynamic>? customDotParams;
  final Map<String, dynamic>? customEyeParams;
  final Map<String, dynamic>? boundaryParams;
  final Map<String, dynamic>? animationParams;

  const QrCustomization({
    this.qrColorArgb = 0xFF000000,
    this.gradient,
    this.roundFactor = 0.0,
    this.eyeOuter = 'square',
    this.eyeInner = 'square',
    this.randomEyeSeed,
    this.quietZoneColorArgb = 0xFFFFFFFF,
    this.dotStyle = 'square',
    this.embedIcon = false,
    this.centerEmoji,
    this.centerIconBase64,
    this.printSizeCm = 5.0,
    this.sticker = const StickerSpec(),
    this.activeTemplateId,
    this.customDotParams,
    this.customEyeParams,
    this.boundaryParams,
    this.animationParams,
  });

  Map<String, dynamic> toJson() => {
        'qrColorArgb': qrColorArgb,
        'gradient': gradient?.toJson(),
        'roundFactor': roundFactor,
        'eyeOuter': eyeOuter,
        'eyeInner': eyeInner,
        'randomEyeSeed': randomEyeSeed,
        'quietZoneColorArgb': quietZoneColorArgb,
        'dotStyle': dotStyle,
        'embedIcon': embedIcon,
        'centerEmoji': centerEmoji,
        'centerIconBase64': centerIconBase64,
        'printSizeCm': printSizeCm,
        'sticker': sticker.toJson(),
        'activeTemplateId': activeTemplateId,
        if (customDotParams != null) 'customDotParams': customDotParams,
        if (customEyeParams != null) 'customEyeParams': customEyeParams,
        if (boundaryParams != null) 'boundaryParams': boundaryParams,
        if (animationParams != null) 'animationParams': animationParams,
      };

  factory QrCustomization.fromJson(Map<String, dynamic> json) => QrCustomization(
        qrColorArgb:
            (json['qrColorArgb'] as num?)?.toInt() ?? 0xFF000000,
        gradient: json['gradient'] != null
            ? QrGradientData.fromJson(json['gradient'] as Map<String, dynamic>)
            : null,
        roundFactor: (json['roundFactor'] as num?)?.toDouble() ?? 0.0,
        eyeOuter: json['eyeOuter'] as String? ?? 'square',
        eyeInner: json['eyeInner'] as String? ?? 'square',
        randomEyeSeed: (json['randomEyeSeed'] as num?)?.toInt(),
        quietZoneColorArgb:
            (json['quietZoneColorArgb'] as num?)?.toInt() ?? 0xFFFFFFFF,
        dotStyle: json['dotStyle'] as String? ?? 'square',
        embedIcon: json['embedIcon'] as bool? ?? false,
        centerEmoji: json['centerEmoji'] as String?,
        centerIconBase64: json['centerIconBase64'] as String?,
        printSizeCm:
            (json['printSizeCm'] as num?)?.toDouble() ?? 5.0,
        sticker: json['sticker'] != null
            ? StickerSpec.fromJson(json['sticker'] as Map<String, dynamic>)
            : const StickerSpec(),
        activeTemplateId: json['activeTemplateId'] as String?,
        customDotParams: json['customDotParams'] as Map<String, dynamic>?,
        customEyeParams: json['customEyeParams'] as Map<String, dynamic>?,
        boundaryParams: json['boundaryParams'] as Map<String, dynamic>?,
        animationParams: json['animationParams'] as Map<String, dynamic>?,
      );

  QrCustomization copyWith({
    int? qrColorArgb,
    QrGradientData? gradient,
    bool clearGradient = false,
    double? roundFactor,
    String? eyeOuter,
    String? eyeInner,
    int? randomEyeSeed,
    bool clearRandomEyeSeed = false,
    int? quietZoneColorArgb,
    String? dotStyle,
    bool? embedIcon,
    String? centerEmoji,
    bool clearCenterEmoji = false,
    String? centerIconBase64,
    bool clearCenterIconBase64 = false,
    double? printSizeCm,
    StickerSpec? sticker,
    String? activeTemplateId,
    bool clearActiveTemplateId = false,
    Map<String, dynamic>? customDotParams,
    bool clearCustomDotParams = false,
    Map<String, dynamic>? customEyeParams,
    bool clearCustomEyeParams = false,
    Map<String, dynamic>? boundaryParams,
    bool clearBoundaryParams = false,
    Map<String, dynamic>? animationParams,
    bool clearAnimationParams = false,
  }) =>
      QrCustomization(
        qrColorArgb: qrColorArgb ?? this.qrColorArgb,
        gradient: clearGradient ? null : (gradient ?? this.gradient),
        roundFactor: roundFactor ?? this.roundFactor,
        eyeOuter: eyeOuter ?? this.eyeOuter,
        eyeInner: eyeInner ?? this.eyeInner,
        randomEyeSeed:
            clearRandomEyeSeed ? null : (randomEyeSeed ?? this.randomEyeSeed),
        quietZoneColorArgb: quietZoneColorArgb ?? this.quietZoneColorArgb,
        dotStyle: dotStyle ?? this.dotStyle,
        embedIcon: embedIcon ?? this.embedIcon,
        centerEmoji:
            clearCenterEmoji ? null : (centerEmoji ?? this.centerEmoji),
        centerIconBase64: clearCenterIconBase64
            ? null
            : (centerIconBase64 ?? this.centerIconBase64),
        printSizeCm: printSizeCm ?? this.printSizeCm,
        sticker: sticker ?? this.sticker,
        activeTemplateId: clearActiveTemplateId
            ? null
            : (activeTemplateId ?? this.activeTemplateId),
        customDotParams: clearCustomDotParams
            ? null
            : (customDotParams ?? this.customDotParams),
        customEyeParams: clearCustomEyeParams
            ? null
            : (customEyeParams ?? this.customEyeParams),
        boundaryParams: clearBoundaryParams
            ? null
            : (boundaryParams ?? this.boundaryParams),
        animationParams: clearAnimationParams
            ? null
            : (animationParams ?? this.animationParams),
      );
}
