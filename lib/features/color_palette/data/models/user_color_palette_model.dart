import 'package:hive/hive.dart';

import '../../domain/entities/user_color_palette.dart';

part 'user_color_palette_model.g.dart';

/// 사용자 색상 팔레트 Hive DTO.
/// @HiveType(typeId: 3) — 절대 변경 금지 (기존 저장 데이터 호환).
@HiveType(typeId: 3)
class UserColorPaletteModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int typeIndex; // PaletteType.index

  @HiveField(3)
  int? solidColorArgb;

  @HiveField(4)
  List<int>? gradientColorArgbs;

  @HiveField(5)
  List<double>? gradientStops;

  @HiveField(6)
  String? gradientType;

  @HiveField(7)
  int? gradientAngle;

  @HiveField(8)
  int sortOrder;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  String? remoteId;

  @HiveField(12)
  bool syncedToCloud;

  UserColorPaletteModel({
    required this.id,
    required this.name,
    required this.typeIndex,
    this.solidColorArgb,
    this.gradientColorArgbs,
    this.gradientStops,
    this.gradientType,
    this.gradientAngle,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedToCloud = false,
  });

  UserColorPalette toEntity() => UserColorPalette(
        id: id,
        name: name,
        type: PaletteType.values[typeIndex.clamp(0, 1)],
        solidColorArgb: solidColorArgb,
        gradientColorArgbs: gradientColorArgbs,
        gradientStops: gradientStops,
        gradientType: gradientType,
        gradientAngle: gradientAngle,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
        remoteId: remoteId,
        syncedToCloud: syncedToCloud,
      );

  factory UserColorPaletteModel.fromEntity(UserColorPalette e) =>
      UserColorPaletteModel(
        id: e.id,
        name: e.name,
        typeIndex: e.type.index,
        solidColorArgb: e.solidColorArgb,
        gradientColorArgbs: e.gradientColorArgbs,
        gradientStops: e.gradientStops,
        gradientType: e.gradientType,
        gradientAngle: e.gradientAngle,
        sortOrder: e.sortOrder,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        remoteId: e.remoteId,
        syncedToCloud: e.syncedToCloud,
      );
}
