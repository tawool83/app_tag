// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QrTaskModelAdapter extends TypeAdapter<QrTaskModel> {
  @override
  final int typeId = 2;

  @override
  QrTaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QrTaskModel(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      kind: fields[2] as String,
      payloadJson: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QrTaskModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.kind)
      ..writeByte(3)
      ..write(obj.payloadJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrTaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
