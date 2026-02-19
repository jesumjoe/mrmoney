import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';

class AnalyticsService {
  // Calculate Opening Balance (Sum of all txs before start date)
  static double calculateOpeningBalance(
    List<Transaction> allTransactions,
    DateTime start,
  ) {
    double balance = 0;
    for (var t in allTransactions) {
      if (t.date.isBefore(start)) {
        if (t.type == TransactionType.credit) {
          balance += t.amount;
        } else {
          balance -= t.amount;
        }
      }
    }
    return balance;
  }

  // Filter transactions by date range
  static List<Transaction> filterTransactions(
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Calculate totals
  static Map<String, double> calculateTotals(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.credit) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // Group by Category (Expenses only usually, or split)
  static Map<String, double> calculateCategorySpending(
    List<Transaction> transactions,
  ) {
    final Map<String, double> categoryTotals = {};

    for (var t in transactions) {
      if (t.type == TransactionType.debit) {
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      }
    }

    return categoryTotals;
  }

  // Daily Spending Trend
  static Map<DateTime, double> calculateDailySpending(
    List<Transaction> transactions,
  ) {
    final Map<DateTime, double> dailyTotals = {};

    for (var t in transactions) {
      if (t.type == TransactionType.debit) {
        final date = DateTime(t.date.year, t.date.month, t.date.day);
        dailyTotals[date] = (dailyTotals[date] ?? 0) + t.amount;
      }
    }
    return dailyTotals;
  }

  // Balance Over Time (Cumulative)
  static List<Map<String, dynamic>> calculateBalanceTrend(
    List<Transaction> transactions,
    double openingBalance,
  ) {
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<Map<String, dynamic>> points = [];
    double currentBalance = openingBalance;

    // Add starting point if needed, or just points for transactions
    // Let's add a point at the very start of the graph?
    // For simplicity, just points for transactions.

    for (var t in sorted) {
      if (t.type == TransactionType.credit) {
        currentBalance += t.amount;
      } else {
        currentBalance -= t.amount;
      }
      points.add({'date': t.date, 'balance': currentBalance});
    }

    return points;
  }
}
