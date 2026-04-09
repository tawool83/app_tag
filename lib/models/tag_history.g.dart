// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagHistoryAdapter extends TypeAdapter<TagHistory> {
  @override
  final int typeId = 0;

  @override
  TagHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagHistory(
      id: fields[0] as String,
      appName: fields[1] as String,
      deepLink: fields[2] as String,
      platform: fields[3] as String,
      outputType: fields[4] as String,
      createdAt: fields[5] as DateTime,
      packageName: fields[6] as String?,
      appIconBytes: fields[7] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, TagHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.deepLink)
      ..writeByte(3)
      ..write(obj.platform)
      ..writeByte(4)
      ..write(obj.outputType)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.packageName)
      ..writeByte(7)
      ..write(obj.appIconBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
