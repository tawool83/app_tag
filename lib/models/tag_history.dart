import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

part 'tag_history.g.dart';

@HiveType(typeId: 0)
class TagHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String appName;

  @HiveField(2)
  final String deepLink;

  @HiveField(3)
  final String platform; // 'android' | 'ios'

  @HiveField(4)
  final String outputType; // 'qr' | 'nfc'

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? packageName; // Android only

  @HiveField(7)
  final Uint8List? appIconBytes; // Android app icon (PNG bytes)

  @HiveField(8)
  final String? qrLabel; // QR 하단 라벨 (커스텀 시)

  @HiveField(9)
  final int? qrColor; // QR 전경색 ARGB 값 (커스텀 시)

  @HiveField(10)
  final double? printSizeCm; // 인쇄 크기 (cm, 정사각형)

  @HiveField(11)
  final String? tagType; // 태그 유형: 'app' | 'clipboard' | 'website' | 'contact' | 'wifi' | 'location' | 'event' | 'email' | 'sms'

  @HiveField(12)
  final String? qrEyeShape; // 'square' | 'circle'

  @HiveField(13)
  final String? qrDataModuleShape; // 'square' | 'circle'

  @HiveField(14)
  final bool? qrEmbedIcon; // 중앙 아이콘 삽입 여부

  TagHistory({
    required this.id,
    required this.appName,
    required this.deepLink,
    required this.platform,
    required this.outputType,
    required this.createdAt,
    this.packageName,
    this.appIconBytes,
    this.qrLabel,
    this.qrColor,
    this.printSizeCm,
    this.tagType,
    this.qrEyeShape,
    this.qrDataModuleShape,
    this.qrEmbedIcon,
  });
}
