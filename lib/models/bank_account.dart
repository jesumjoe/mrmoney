import 'package:hive/hive.dart';

part 'bank_account.g.dart';

@HiveType(typeId: 0)
class BankAccount extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String bankName;

  @HiveField(2)
  String accountNumber;

  @HiveField(3)
  double currentBalance;

  @HiveField(4)
  String smsKeyword;

  @HiveField(5)
  bool isSmsParsingEnabled;

  @HiveField(6)
  List<String> customDebitRegex;

  @HiveField(7)
  List<String> customCreditRegex;

  @HiveField(8)
  String? logoPath;

  @HiveField(9)
  String type; // 'bank', 'cash', 'investment'

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.currentBalance,
    required this.smsKeyword,
    this.isSmsParsingEnabled = true,
    this.customDebitRegex = const [],
    this.customCreditRegex = const [],
    this.logoPath,
    this.type = 'bank',
  });
}
