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
      qrLabel: fields[8] as String?,
      qrColor: fields[9] as int?,
      printSizeCm: fields[10] as double?,
      tagType: fields[11] as String?,
      qrEyeShape: fields[12] as String?,
      qrDataModuleShape: fields[13] as String?,
      qrEmbedIcon: fields[14] as bool?,
      qrCenterEmoji: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TagHistory obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.appIconBytes)
      ..writeByte(8)
      ..write(obj.qrLabel)
      ..writeByte(9)
      ..write(obj.qrColor)
      ..writeByte(10)
      ..write(obj.printSizeCm)
      ..writeByte(11)
      ..write(obj.tagType)
      ..writeByte(12)
      ..write(obj.qrEyeShape)
      ..writeByte(13)
      ..write(obj.qrDataModuleShape)
      ..writeByte(14)
      ..write(obj.qrEmbedIcon)
      ..writeByte(15)
      ..write(obj.qrCenterEmoji);
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
