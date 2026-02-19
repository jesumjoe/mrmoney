import 'package:flutter/material.dart';
import 'package:mrmoney/repositories/category_repository.dart';
import 'package:mrmoney/services/budget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepo;
  double _savingsGoal = 0;

  BudgetProvider(this._categoryRepo) {
    _loadSavingsGoal();
  }

  double get savingsGoal => _savingsGoal;

  Future<void> _loadSavingsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _savingsGoal = prefs.getDouble('savings_goal') ?? 0;
    notifyListeners();
  }

  Future<void> setSavingsGoal(double goal) async {
    _savingsGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('savings_goal', goal);
    notifyListeners();
  }

  Future<void> setCategoryLimit(String categoryId, double limit) async {
    final category = _categoryRepo.getAll().firstWhere(
      (c) => c.id == categoryId,
    );
    category.budgetLimit = limit;
    category.save(); // Hive save
    notifyListeners();
  }

  // Helper to check status for UI
  BudgetStatusResult checkGlobalStatus(
    double currentBalance,
    double newExpense,
  ) {
    return BudgetService.checkGlobalBudgetStatus(
      currentBalance: currentBalance,
      savingsGoal: _savingsGoal,
      newExpenseAmount: newExpense,
    );
  }
}
