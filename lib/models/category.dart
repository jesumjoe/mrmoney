import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 3)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCode;

  @HiveField(3)
  double? budgetLimit;

  @HiveField(4)
  String colorHex;

  Category({
    required this.id,
    required this.name,
    required this.iconCode,
    this.budgetLimit,
    this.colorHex = '#FF2196F3', // Default Blue
  });
}
