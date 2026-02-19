// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FriendLoanAdapter extends TypeAdapter<FriendLoan> {
  @override
  final int typeId = 6;

  @override
  FriendLoan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FriendLoan(
      id: fields[0] as String,
      friendName: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as FriendLoanType,
      description: fields[4] as String,
      date: fields[5] as DateTime,
      transactionId: fields[6] as String?,
      isSettled: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FriendLoan obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.friendName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.transactionId)
      ..writeByte(7)
      ..write(obj.isSettled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendLoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FriendLoanTypeAdapter extends TypeAdapter<FriendLoanType> {
  @override
  final int typeId = 5;

  @override
  FriendLoanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FriendLoanType.owe;
      case 1:
        return FriendLoanType.owed;
      default:
        return FriendLoanType.owe;
    }
  }

  @override
  void write(BinaryWriter writer, FriendLoanType obj) {
    switch (obj) {
      case FriendLoanType.owe:
        writer.writeByte(0);
        break;
      case FriendLoanType.owed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendLoanTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
