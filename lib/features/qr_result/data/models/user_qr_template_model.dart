import 'dart:typed_data';
import 'package:hive/hive.dart';

import '../../domain/entities/user_qr_template.dart';

part 'user_qr_template_model.g.dart';

/// 사용자 QR 템플릿 Hive DTO.
/// @HiveType(typeId: 1) — 절대 변경 금지 (기존 저장 데이터 호환).
@HiveType(typeId: 1)
class UserQrTemplateModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  Uint8List? backgroundImageBytes;

  @HiveField(4)
  double backgroundScale;

  @HiveField(5)
  int qrColorValue;

  @HiveField(6)
  String? gradientJson;

  @HiveField(7)
  double roundFactor;

  @HiveField(8)
  int eyeStyleIndex;

  @HiveField(9)
  int quietZoneColorValue;

  @HiveField(10)
  int logoPositionIndex;

  @HiveField(11)
  int logoBackgroundIndex;

  @HiveField(12)
  String? topTextContent;

  @HiveField(13)
  int? topTextColorValue;

  @HiveField(14)
  String? topTextFont;

  @HiveField(15)
  double? topTextSize;

  @HiveField(16)
  String? bottomTextContent;

  @HiveField(17)
  int? bottomTextColorValue;

  @HiveField(18)
  String? bottomTextFont;

  @HiveField(19)
  double? bottomTextSize;

  @HiveField(20)
  String? remoteId;

  @HiveField(21)
  bool syncedToCloud;

  @HiveField(22)
  Uint8List? thumbnailBytes;

  @HiveField(23)
  int dotStyleIndex;

  @HiveField(24)
  int eyeOuterIndex;

  @HiveField(25)
  int eyeInnerIndex;

  @HiveField(26)
  int? randomEyeSeed;

  @HiveField(27)
  double backgroundAlignX;

  @HiveField(28)
  double backgroundAlignY;

  @HiveField(29)
  DateTime? updatedAt;

  UserQrTemplateModel({
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
    this.remoteId,
    this.syncedToCloud = false,
    this.thumbnailBytes,
    this.dotStyleIndex = 0,
    this.eyeOuterIndex = 0,
    this.eyeInnerIndex = 0,
    this.randomEyeSeed,
    this.updatedAt,
  });

  UserQrTemplate toEntity() => UserQrTemplate(
        id: id,
        name: name,
        createdAt: createdAt,
        backgroundImageBytes: backgroundImageBytes,
        backgroundScale: backgroundScale,
        backgroundAlignX: backgroundAlignX,
        backgroundAlignY: backgroundAlignY,
        qrColorValue: qrColorValue,
        gradientJson: gradientJson,
        roundFactor: roundFactor,
        eyeStyleIndex: eyeStyleIndex,
        dotStyleIndex: dotStyleIndex,
        eyeOuterIndex: eyeOuterIndex,
        eyeInnerIndex: eyeInnerIndex,
        randomEyeSeed: randomEyeSeed,
        quietZoneColorValue: quietZoneColorValue,
        logoPositionIndex: logoPositionIndex,
        logoBackgroundIndex: logoBackgroundIndex,
        topTextContent: topTextContent,
        topTextColorValue: topTextColorValue,
        topTextFont: topTextFont,
        topTextSize: topTextSize,
        bottomTextContent: bottomTextContent,
        bottomTextColorValue: bottomTextColorValue,
        bottomTextFont: bottomTextFont,
        bottomTextSize: bottomTextSize,
        thumbnailBytes: thumbnailBytes,
        updatedAt: updatedAt,
        remoteId: remoteId,
        syncedToCloud: syncedToCloud,
      );

  factory UserQrTemplateModel.fromEntity(UserQrTemplate e) =>
      UserQrTemplateModel(
        id: e.id,
        name: e.name,
        createdAt: e.createdAt,
        backgroundImageBytes: e.backgroundImageBytes,
        backgroundScale: e.backgroundScale,
        backgroundAlignX: e.backgroundAlignX,
        backgroundAlignY: e.backgroundAlignY,
        qrColorValue: e.qrColorValue,
        gradientJson: e.gradientJson,
        roundFactor: e.roundFactor,
        eyeStyleIndex: e.eyeStyleIndex,
        dotStyleIndex: e.dotStyleIndex,
        eyeOuterIndex: e.eyeOuterIndex,
        eyeInnerIndex: e.eyeInnerIndex,
        randomEyeSeed: e.randomEyeSeed,
        quietZoneColorValue: e.quietZoneColorValue,
        logoPositionIndex: e.logoPositionIndex,
        logoBackgroundIndex: e.logoBackgroundIndex,
        topTextContent: e.topTextContent,
        topTextColorValue: e.topTextColorValue,
        topTextFont: e.topTextFont,
        topTextSize: e.topTextSize,
        bottomTextContent: e.bottomTextContent,
        bottomTextColorValue: e.bottomTextColorValue,
        bottomTextFont: e.bottomTextFont,
        bottomTextSize: e.bottomTextSize,
        thumbnailBytes: e.thumbnailBytes,
        updatedAt: e.updatedAt,
        remoteId: e.remoteId,
        syncedToCloud: e.syncedToCloud,
      );
}
