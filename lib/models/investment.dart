import 'package:hive/hive.dart';

part 'investment.g.dart';

@HiveType(typeId: 4)
class Investment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String type; // e.g., Stocks, Mutual Funds, Gold, etc.

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime date;

  Investment({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
  });
}
