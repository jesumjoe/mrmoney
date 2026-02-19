import 'package:hive/hive.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/repositories/base_repository.dart';

class BankAccountRepository extends BaseRepository<BankAccount> {
  BankAccountRepository() : super(Hive.box<BankAccount>('bank_accounts'));
}
