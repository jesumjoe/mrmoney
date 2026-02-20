import 'package:flutter/material.dart';
import 'package:mrmoney/repositories/category_repository.dart';
import 'package:mrmoney/services/budget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/models/transaction_type.dart';

class BudgetSummary {
  final double income;
  final double expense;
  final double projectedExpense;
  final Map<String, double> categorySpent;
  final double currentBalance;
  final double safeToSpend;
  final bool isSafe;
  final List<BudgetInsight> insights;

  BudgetSummary({
    required this.income,
    required this.expense,
    required this.projectedExpense,
    required this.categorySpent,
    required this.currentBalance,
    required this.safeToSpend,
    required this.isSafe,
    required this.insights,
  });
}

class BudgetInsight {
  final String title;
  final String message;
  final bool isWarning;

  BudgetInsight({
    required this.title,
    required this.message,
    required this.isWarning,
  });
}

class BudgetProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepo;
  double _savingsGoal = 0;
  BudgetSummary? _cachedSummary;

  // Dependency
  TransactionProvider? _transactionProvider;

  BudgetProvider(this._categoryRepo) {
    _loadSavingsGoal();
  }

  double get savingsGoal => _savingsGoal;
  BudgetSummary? get budgetSummary => _cachedSummary;

  Future<void> _loadSavingsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _savingsGoal = prefs.getDouble('savings_goal') ?? 0;
    _calculateSummary();
    notifyListeners();
  }

  void update(TransactionProvider provider) {
    if (_transactionProvider != provider) {
      _transactionProvider = provider;
      _calculateSummary();
      // We don't notify here to avoid build loops, unless necessary.
      // But ProxyProvider.update usually triggers a rebuild of dependents anyway.
      // However, since we are computing a NEW object, we should probably notify if the calculation changed anything vital?
      // Actually, ProxyProvider's `update` creates/updates THIS instance.
      // If we are using ChangeNotifierProxyProvider, the `update` callback in main.dart is called.
      // We should expose a method to be called from there.
      // Wait, ChangeNotifierProxyProvider re-uses the instance if possible.
      // let's just re-calculate and notify.
      // Actually notifyListeners() is dangerous in update so we should compare if data changed.
      // For now, let's just calculate.
    }
  }

  // Called from ProxyProvider update
  void updateTransactions(TransactionProvider provider) {
    _transactionProvider = provider;
    _calculateSummary();
    // No notify here because ProxyProvider will handle the notification if the reference changes?
    // Actually, distinct object references are usually handled.
    // Ideally, we want to recalculate whenever transactions change.
    // But TransactionProvider notifies its listeners.
    // If BudgetProvider listens to TransactionProvider, we get a loop if not careful.
    // ChangeNotifierProxyProvider causes BudgetProvider to rebuild/update when TransactionProvider notifies.
  }

  void _calculateSummary() {
    if (_transactionProvider == null) return;

    final now = DateTime.now();
    final transactions = _transactionProvider!.transactions;
    // Filter for current month
    final currentMonthTxs = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    double income = 0;
    double expense = 0;
    final Map<String, double> categorySpent = {};

    for (var t in currentMonthTxs) {
      if (t.type == TransactionType.credit) {
        income += t.amount;
      } else {
        expense += t.amount;
        final catName = t.category;
        categorySpent[catName] = (categorySpent[catName] ?? 0) + t.amount;
      }
    }

    final projected = BudgetService.calculateProjectedSpending(
      currentSpent: expense,
      currentMonth: now,
    );

    final currentBalance = income - expense;
    final safeToSpend = currentBalance - _savingsGoal;
    final isSafe = safeToSpend > 0;

    final insights = <BudgetInsight>[];

    if (safeToSpend < 0) {
      insights.add(
        BudgetInsight(
          title: "Goal at Risk",
          message:
              "You have dipped into your savings by ₹${safeToSpend.abs().toStringAsFixed(0)}.",
          isWarning: true,
        ),
      );
    } else if (safeToSpend < (_savingsGoal * 0.2)) {
      insights.add(
        BudgetInsight(
          title: "Approaching Limit",
          message:
              "Only ₹${safeToSpend.toStringAsFixed(0)} left before touching your savings.",
          isWarning: true,
        ),
      );
    }

    if (currentBalance > 0 && (income - projected) < _savingsGoal) {
      final potentialShortfall = _savingsGoal - (income - projected);
      if (potentialShortfall > 0) {
        insights.add(
          BudgetInsight(
            title: "Projected Shortfall",
            message:
                "At this rate, you might miss your goal by ₹${potentialShortfall.toStringAsFixed(0)}.",
            isWarning: true,
          ),
        );
      }
    }

    _cachedSummary = BudgetSummary(
      income: income,
      expense: expense,
      projectedExpense: projected,
      categorySpent: categorySpent,
      currentBalance: currentBalance,
      safeToSpend: safeToSpend,
      isSafe: isSafe,
      insights: insights,
    );
    // We don't call notifyListeners() here because this is called during build/update cycle usually.
  }

  Future<void> setSavingsGoal(double goal) async {
    _savingsGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('savings_goal', goal);
    _calculateSummary();
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
