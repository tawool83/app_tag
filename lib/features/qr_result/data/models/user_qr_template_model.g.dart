// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_qr_template_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserQrTemplateModelAdapter extends TypeAdapter<UserQrTemplateModel> {
  @override
  final int typeId = 1;

  @override
  UserQrTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserQrTemplateModel(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      backgroundImageBytes: fields[3] as Uint8List?,
      backgroundScale: fields[4] as double,
      backgroundAlignX: fields[27] as double,
      backgroundAlignY: fields[28] as double,
      qrColorValue: fields[5] as int,
      gradientJson: fields[6] as String?,
      roundFactor: fields[7] as double,
      eyeStyleIndex: fields[8] as int,
      quietZoneColorValue: fields[9] as int,
      logoPositionIndex: fields[10] as int,
      logoBackgroundIndex: fields[11] as int,
      topTextContent: fields[12] as String?,
      topTextColorValue: fields[13] as int?,
      topTextFont: fields[14] as String?,
      topTextSize: fields[15] as double?,
      bottomTextContent: fields[16] as String?,
      bottomTextColorValue: fields[17] as int?,
      bottomTextFont: fields[18] as String?,
      bottomTextSize: fields[19] as double?,
      remoteId: fields[20] as String?,
      syncedToCloud: fields[21] as bool,
      thumbnailBytes: fields[22] as Uint8List?,
      dotStyleIndex: fields[23] as int,
      eyeOuterIndex: fields[24] as int,
      eyeInnerIndex: fields[25] as int,
      randomEyeSeed: fields[26] as int?,
      updatedAt: fields[29] as DateTime?,
      logoType: fields[30] as String?,
      logoAssetId: fields[31] as String?,
      logoImageBytes: fields[32] as Uint8List?,
      logoTextContent: fields[33] as String?,
      logoTextColorValue: fields[34] as int?,
      logoTextFont: fields[35] as String?,
      logoTextSize: fields[36] as double?,
      logoBackgroundColorValue: fields[37] as int?,
      customDotParamsJson: fields[38] as String?,
      customEyeParamsJson: fields[39] as String?,
      boundaryParamsJson: fields[40] as String?,
      schemaVersion: fields[41] as int?,
      minEngineVersion: fields[42] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UserQrTemplateModel obj) {
    writer
      ..writeByte(43)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.backgroundImageBytes)
      ..writeByte(4)
      ..write(obj.backgroundScale)
      ..writeByte(5)
      ..write(obj.qrColorValue)
      ..writeByte(6)
      ..write(obj.gradientJson)
      ..writeByte(7)
      ..write(obj.roundFactor)
      ..writeByte(8)
      ..write(obj.eyeStyleIndex)
      ..writeByte(9)
      ..write(obj.quietZoneColorValue)
      ..writeByte(10)
      ..write(obj.logoPositionIndex)
      ..writeByte(11)
      ..write(obj.logoBackgroundIndex)
      ..writeByte(12)
      ..write(obj.topTextContent)
      ..writeByte(13)
      ..write(obj.topTextColorValue)
      ..writeByte(14)
      ..write(obj.topTextFont)
      ..writeByte(15)
      ..write(obj.topTextSize)
      ..writeByte(16)
      ..write(obj.bottomTextContent)
      ..writeByte(17)
      ..write(obj.bottomTextColorValue)
      ..writeByte(18)
      ..write(obj.bottomTextFont)
      ..writeByte(19)
      ..write(obj.bottomTextSize)
      ..writeByte(20)
      ..write(obj.remoteId)
      ..writeByte(21)
      ..write(obj.syncedToCloud)
      ..writeByte(22)
      ..write(obj.thumbnailBytes)
      ..writeByte(23)
      ..write(obj.dotStyleIndex)
      ..writeByte(24)
      ..write(obj.eyeOuterIndex)
      ..writeByte(25)
      ..write(obj.eyeInnerIndex)
      ..writeByte(26)
      ..write(obj.randomEyeSeed)
      ..writeByte(27)
      ..write(obj.backgroundAlignX)
      ..writeByte(28)
      ..write(obj.backgroundAlignY)
      ..writeByte(29)
      ..write(obj.updatedAt)
      ..writeByte(30)
      ..write(obj.logoType)
      ..writeByte(31)
      ..write(obj.logoAssetId)
      ..writeByte(32)
      ..write(obj.logoImageBytes)
      ..writeByte(33)
      ..write(obj.logoTextContent)
      ..writeByte(34)
      ..write(obj.logoTextColorValue)
      ..writeByte(35)
      ..write(obj.logoTextFont)
      ..writeByte(36)
      ..write(obj.logoTextSize)
      ..writeByte(37)
      ..write(obj.logoBackgroundColorValue)
      ..writeByte(38)
      ..write(obj.customDotParamsJson)
      ..writeByte(39)
      ..write(obj.customEyeParamsJson)
      ..writeByte(40)
      ..write(obj.boundaryParamsJson)
      ..writeByte(41)
      ..write(obj.schemaVersion)
      ..writeByte(42)
      ..write(obj.minEngineVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserQrTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
