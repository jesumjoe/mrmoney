import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mrmoney/models/bank_account.dart';
import 'package:hive/hive.dart';
import 'package:mrmoney/repositories/bank_account_repository.dart';

class BankAccountProvider with ChangeNotifier {
  final BankAccountRepository _repository;

  List<BankAccount> _accounts = [];
  List<BankAccount> get accounts => _accounts;

  // Track cash on hand separately or as a special account?
  // User req: "User can track cash on hand". maybe a specific account "Cash".

  double get totalBalance =>
      _accounts.fold(0, (sum, item) => sum + item.currentBalance);

  StreamSubscription? _boxSubscription;

  BankAccountProvider(this._repository) {
    loadAccounts();
    _initListener();
  }

  void _initListener() {
    _boxSubscription = _repository.box.watch().listen((_) {
      loadAccounts();
    });
  }

  Future<void> refresh() async {
    if (_repository.box.isOpen) await _repository.box.close();

    final newBox = await Hive.openBox<BankAccount>('bank_accounts');
    _repository.box = newBox;

    _boxSubscription?.cancel();
    _initListener();

    loadAccounts();
  }

  @override
  void dispose() {
    _boxSubscription?.cancel();
    super.dispose();
  }

  void loadAccounts() {
    _accounts = _repository.getAll();
    notifyListeners();
  }

  Future<void> addAccount(BankAccount account) async {
    await _repository.add(account);
    loadAccounts();
  }

  Future<void> updateAccount(BankAccount account) async {
    await account.save(); // HiveObject method
    loadAccounts();
  }

  Future<void> deleteAccount(BankAccount account) async {
    await account.delete(); // HiveObject method
    loadAccounts();
  }

  // Define a method to update balance when transaction happens
  Future<void> updateBalance(
    String accountId,
    double amount,
    bool isCredit,
  ) async {
    final accountIndex = _accounts.indexWhere((a) => a.id == accountId);
    if (accountIndex != -1) {
      final account = _accounts[accountIndex];
      if (isCredit) {
        account.currentBalance += amount;
      } else {
        account.currentBalance -= amount;
      }
      await account.save();
      notifyListeners();
    }
  }

  BankAccount? getAccountBySmsKeyword(String keyword) {
    if (keyword.isEmpty) return null;
    try {
      return _accounts.firstWhere(
        (a) =>
            a.smsKeyword.isNotEmpty &&
            a.smsKeyword.toUpperCase() == keyword.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
