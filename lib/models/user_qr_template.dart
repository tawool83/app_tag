import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'user_qr_template.g.dart';

/// 사용자가 저장한 나만의 QR 템플릿.
/// 배경·QR·스티커 3개 레이어 설정을 Hive에 영구 저장합니다.
/// remoteId / syncedToCloud 필드는 향후 유료 클라우드 동기화를 위한 예약 필드입니다.
@HiveType(typeId: 1)
class UserQrTemplate extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  // 배경 레이어
  @HiveField(3)
  Uint8List? backgroundImageBytes;

  @HiveField(4)
  double backgroundScale;

  // QR 레이어
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

  // 스티커 레이어
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

  // 클라우드 동기화 대비 (현재 미사용)
  @HiveField(20)
  String? remoteId;

  @HiveField(21)
  bool syncedToCloud;

  // 나의 템플릿 그리드 썸네일
  @HiveField(22)
  Uint8List? thumbnailBytes;

  // 도트 모양 (QrDotStyle.index)
  @HiveField(23)
  int dotStyleIndex;

  // 눈 모양 독립 선택
  @HiveField(24)
  int eyeOuterIndex; // QrEyeOuter.index

  @HiveField(25)
  int eyeInnerIndex; // QrEyeInner.index

  @HiveField(26)
  int? randomEyeSeed; // non-null → 랜덤 눈 모양

  UserQrTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    this.backgroundImageBytes,
    this.backgroundScale = 1.0,
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
  });
}
