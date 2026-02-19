import 'package:hive/hive.dart';
import 'transaction_type.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String category;

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? bankAccountId;

  @HiveField(7)
  bool isFromSMS;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.bankAccountId,
    this.isFromSMS = false,
  });
}
