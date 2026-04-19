// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_color_palette_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserColorPaletteModelAdapter extends TypeAdapter<UserColorPaletteModel> {
  @override
  final int typeId = 3;

  @override
  UserColorPaletteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserColorPaletteModel(
      id: fields[0] as String,
      name: fields[1] as String,
      typeIndex: fields[2] as int,
      solidColorArgb: fields[3] as int?,
      gradientColorArgbs: (fields[4] as List?)?.cast<int>(),
      gradientStops: (fields[5] as List?)?.cast<double>(),
      gradientType: fields[6] as String?,
      gradientAngle: fields[7] as int?,
      sortOrder: fields[8] as int,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      remoteId: fields[11] as String?,
      syncedToCloud: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserColorPaletteModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.typeIndex)
      ..writeByte(3)
      ..write(obj.solidColorArgb)
      ..writeByte(4)
      ..write(obj.gradientColorArgbs)
      ..writeByte(5)
      ..write(obj.gradientStops)
      ..writeByte(6)
      ..write(obj.gradientType)
      ..writeByte(7)
      ..write(obj.gradientAngle)
      ..writeByte(8)
      ..write(obj.sortOrder)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.remoteId)
      ..writeByte(12)
      ..write(obj.syncedToCloud);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserColorPaletteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
