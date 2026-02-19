import 'package:flutter/material.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/repositories/transaction_repository.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _repository;
  BankAccountProvider _accountProvider; // To update balances

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  TransactionProvider(this._repository, this._accountProvider) {
    loadTransactions();
  }

  void updateAccountProvider(BankAccountProvider provider) {
    _accountProvider = provider;
  }

  void loadTransactions() {
    _transactions = _repository.getAll();
    // Sort by date desc
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
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
