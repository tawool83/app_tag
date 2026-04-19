import 'dart:typed_data';

/// 사용자가 저장한 나만의 QR 템플릿 (domain entity).
/// 순수 Dart — Flutter/Hive 의존 없음.
/// 색상은 ARGB int, 열거형은 index(int) 로 저장.
class UserQrTemplate {
  final String id;
  final String name;
  final DateTime createdAt;

  // 배경 레이어
  final Uint8List? backgroundImageBytes;
  final double backgroundScale;
  final double backgroundAlignX;
  final double backgroundAlignY;

  // QR 레이어
  final int qrColorValue;        // ARGB int
  final String? gradientJson;
  final double roundFactor;
  final int eyeStyleIndex;       // 레거시 (QrEyeStyle 미사용)
  final int dotStyleIndex;       // QrDotStyle.index
  final int eyeOuterIndex;       // QrEyeOuter.index
  final int eyeInnerIndex;       // QrEyeInner.index
  final int? randomEyeSeed;
  final int quietZoneColorValue; // ARGB int

  // 스티커 레이어
  final int logoPositionIndex;
  final int logoBackgroundIndex;
  final String? topTextContent;
  final int? topTextColorValue;
  final String? topTextFont;
  final double? topTextSize;
  final String? bottomTextContent;
  final int? bottomTextColorValue;
  final String? bottomTextFont;
  final double? bottomTextSize;

  // 메타
  final Uint8List? thumbnailBytes;
  final DateTime updatedAt;

  // 동기화 메타
  final String? remoteId;
  final bool syncedToCloud;

  const UserQrTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    this.backgroundImageBytes,
    this.backgroundScale = 1.0,
    this.backgroundAlignX = 0.0,
    this.backgroundAlignY = 0.0,
    this.qrColorValue = 0xFF000000,
    this.gradientJson,
    this.roundFactor = 0.0,
    this.eyeStyleIndex = 0,
    this.dotStyleIndex = 0,
    this.eyeOuterIndex = 0,
    this.eyeInnerIndex = 0,
    this.randomEyeSeed,
    this.quietZoneColorValue = 0xFFFFFFFF,
    this.logoPositionIndex = 0,
    this.logoBackgroundIndex = 0,
    this.topTextContent,
    this.topTextColorValue,
    this.topTextFont,
    this.topTextSize,
    this.bottomTextContent,
    this.bottomTextColorValue,
    this.bottomTextFont,
    this.bottomTextSize,
    this.thumbnailBytes,
    DateTime? updatedAt,
    this.remoteId,
    this.syncedToCloud = false,
  }) : updatedAt = updatedAt ?? createdAt;
}
