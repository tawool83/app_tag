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

  TagHistory({
    required this.id,
    required this.appName,
    required this.deepLink,
    required this.platform,
    required this.outputType,
    required this.createdAt,
    this.packageName,
    this.appIconBytes,
  });
}
