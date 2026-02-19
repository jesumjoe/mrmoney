import 'package:hive/hive.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/repositories/base_repository.dart';

class TransactionRepository extends BaseRepository<Transaction> {
  TransactionRepository() : super(Hive.box<Transaction>('transactions'));

  List<Transaction> getTransactionsForAccount(String accountId) {
    return box.values.where((t) => t.bankAccountId == accountId).toList();
  }
}
