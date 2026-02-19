// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BankAccountAdapter extends TypeAdapter<BankAccount> {
  @override
  final int typeId = 0;

  @override
  BankAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankAccount(
      id: fields[0] as String,
      bankName: fields[1] as String,
      accountNumber: fields[2] as String,
      currentBalance: fields[3] as double,
      smsKeyword: fields[4] as String,
      isSmsParsingEnabled: fields[5] as bool,
      customDebitRegex: (fields[6] as List).cast<String>(),
      customCreditRegex: (fields[7] as List).cast<String>(),
      logoPath: fields[8] as String?,
      type: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BankAccount obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.accountNumber)
      ..writeByte(3)
      ..write(obj.currentBalance)
      ..writeByte(4)
      ..write(obj.smsKeyword)
      ..writeByte(5)
      ..write(obj.isSmsParsingEnabled)
      ..writeByte(6)
      ..write(obj.customDebitRegex)
      ..writeByte(7)
      ..write(obj.customCreditRegex)
      ..writeByte(8)
      ..write(obj.logoPath)
      ..writeByte(9)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
