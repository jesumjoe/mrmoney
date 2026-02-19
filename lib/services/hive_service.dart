import 'package:hive_flutter/hive_flutter.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/models/category.dart';
import 'package:mrmoney/models/investment.dart';
import 'package:mrmoney/models/friend_loan.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0))
      Hive.registerAdapter(BankAccountAdapter()); // TypeId: 0
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(TransactionAdapter()); // TypeId: 1
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(TransactionTypeAdapter()); // TypeId: 2
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(CategoryAdapter()); // TypeId: 3
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(InvestmentAdapter()); // TypeId: 4
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(FriendLoanTypeAdapter()); // TypeId: 5
    if (!Hive.isAdapterRegistered(6))
      Hive.registerAdapter(FriendLoanAdapter()); // TypeId: 6

    await Hive.openBox<BankAccount>('bank_accounts');
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<Category>('categories');
    await Hive.openBox<Investment>('investments');
    await Hive.openBox<FriendLoan>('friend_loans');
  }
}
