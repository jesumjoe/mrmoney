import 'package:hive/hive.dart';
import 'package:mrmoney/models/category.dart';
import 'package:mrmoney/repositories/base_repository.dart';

class CategoryRepository extends BaseRepository<Category> {
  CategoryRepository() : super(Hive.box<Category>('categories'));

  void initDefaultCategories() {
    if (box.isEmpty) {
      final defaults = [
        Category(
          id: 'food',
          name: 'Food',
          iconCode: 0xe532,
          colorHex: '#FFFF5722',
        ), // fastfood, DeepOrange
        Category(
          id: 'transport',
          name: 'Transport',
          iconCode: 0xe570,
          colorHex: '#FF2196F3', // Blue
        ), // directions_bus
        Category(
          id: 'bills',
          name: 'Bills',
          iconCode: 0xe54e,
          colorHex: '#FFF44336',
        ), // receipt_long, Red
        Category(
          id: 'entertainment',
          name: 'Entertainment',
          iconCode: 0xe415,
          colorHex: '#FF9C27B0', // Purple
        ), // movie
        Category(
          id: 'shopping',
          name: 'Shopping',
          iconCode: 0xe59c,
          colorHex: '#FFE91E63', // Pink
        ), // shopping_bag
        Category(
          id: 'health',
          name: 'Health',
          iconCode: 0xf1bb,
          colorHex: '#FF009688', // Teal
        ), // medical_services
        Category(
          id: 'investment',
          name: 'Investment',
          iconCode: 0xe6e9,
          colorHex: '#FF4CAF50', // Green
        ), // trending_up
        Category(
          id: 'salary',
          name: 'Salary',
          iconCode: 0xe056,
          colorHex: '#FFFFC107', // Amber
        ), // attach_money
      ];
      box.addAll(defaults);
    }
  }

  void updateCategory(Category category) {
    category.save();
  }
}
