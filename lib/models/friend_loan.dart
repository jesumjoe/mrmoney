import 'package:hive/hive.dart';

part 'friend_loan.g.dart';

@HiveType(typeId: 5)
enum FriendLoanType {
  @HiveField(0)
  owe, // I owe them
  @HiveField(1)
  owed, // They owe me
}

@HiveType(typeId: 6)
class FriendLoan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String friendName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  FriendLoanType type;

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? transactionId;

  @HiveField(7)
  bool isSettled;

  FriendLoan({
    required this.id,
    required this.friendName,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    this.transactionId,
    this.isSettled = false,
  });
}
