import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:hive/hive.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/repositories/transaction_repository.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
import 'package:mrmoney/services/home_widget_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _repository;
  BankAccountProvider _accountProvider; // To update balances

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  StreamSubscription? _boxSubscription;

  TransactionProvider(this._repository, this._accountProvider) {
    loadTransactions();
    _initListener();
  }

  void _initListener() {
    _boxSubscription = _repository.box.watch().listen((_) {
      loadTransactions();
    });
  }

  Future<void> refresh() async {
    // Close and Re-open box to force sync from disk (Background Service writes)
    if (_repository.box.isOpen) await _repository.box.close();

    final newBox = await Hive.openBox<Transaction>('transactions');
    _repository.box = newBox;

    _boxSubscription?.cancel();
    _initListener();

    loadTransactions();
  }

  @override
  void dispose() {
    _boxSubscription?.cancel();
    super.dispose();
  }

  void updateAccountProvider(BankAccountProvider provider) {
    _accountProvider = provider;
  }

  void loadTransactions() {
    _transactions = _repository.getAll();
    // Sort by date desc
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    HomeWidgetService.updateWidgetData(_transactions);
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _repository.add(transaction);

    // Update account balance
    if (transaction.bankAccountId != null) {
      bool isCredit = transaction.type == TransactionType.credit;
      await _accountProvider.updateBalance(
        transaction.bankAccountId!,
        transaction.amount,
        isCredit,
      );
    }

    loadTransactions();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    // Revert balance change
    if (transaction.bankAccountId != null) {
      bool isCredit = transaction.type == TransactionType.credit;
      // If it was credit, we subtract to revert. If debit, we add.
      await _accountProvider.updateBalance(
        transaction.bankAccountId!,
        transaction.amount,
        !isCredit,
      );
    }

    await transaction.delete();
    loadTransactions();
  }

  List<Transaction> processTransactions({
    required List<Transaction> transactions,
    TransactionType? filterType,
    SortOrder sortOrder = SortOrder.newestFirst,
  }) {
    // 1. Filter by Type
    var filtered = transactions;
    if (filterType != null) {
      filtered = filtered.where((t) => t.type == filterType).toList();
    }

    // 2. Sort
    filtered.sort((a, b) {
      switch (sortOrder) {
        case SortOrder.newestFirst:
          return b.date.compareTo(a.date);
        case SortOrder.oldestFirst:
          return a.date.compareTo(b.date);
        case SortOrder.highestAmount:
          return b.amount.compareTo(a.amount);
        case SortOrder.lowestAmount:
          return a.amount.compareTo(b.amount);
      }
    });

    return filtered;
  }

  List<Transaction> getTransactionsForMonth(DateTime month) {
    return _transactions.where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  Map<String, double> calculateMonthlyTotals(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.credit) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'total': totalIncome - totalExpense,
    };
  }

  static Map<String, List<Transaction>> groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final Map<String, List<Transaction>> grouped = {};
    for (var t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(t);
    }
    return grouped;
  }

  List<Transaction> get recentTransactions {
    return _transactions.take(10).toList();
  }

  double get todayExpense {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.type == TransactionType.debit &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day,
        )
        .fold(0, (sum, t) => sum + t.amount);
  }
}

enum SortOrder { newestFirst, oldestFirst, highestAmount, lowestAmount }
