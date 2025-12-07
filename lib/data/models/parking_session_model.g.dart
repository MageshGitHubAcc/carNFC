// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parking_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParkingSessionModelAdapter extends TypeAdapter<ParkingSessionModel> {
  @override
  final int typeId = 1;

  @override
  ParkingSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParkingSessionModel(
      id: fields[0] as String,
      carNumber: fields[1] as String,
      ownerName: fields[2] as String,
      mobile: fields[3] as String,
      slotId: fields[4] as String,
      checkInTime: fields[5] as DateTime,
      checkOutTime: fields[6] as DateTime?,
      amountPaid: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ParkingSessionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.carNumber)
      ..writeByte(2)
      ..write(obj.ownerName)
      ..writeByte(3)
      ..write(obj.mobile)
      ..writeByte(4)
      ..write(obj.slotId)
      ..writeByte(5)
      ..write(obj.checkInTime)
      ..writeByte(6)
      ..write(obj.checkOutTime)
      ..writeByte(7)
      ..write(obj.amountPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
