import 'package:hive/hive.dart';
import 'package:mrmoney/models/friend_loan.dart';
import 'package:mrmoney/repositories/base_repository.dart';

class FriendLoanRepository extends BaseRepository<FriendLoan> {
  FriendLoanRepository() : super(Hive.box<FriendLoan>('friend_loans'));

  List<FriendLoan> getLoansForFriend(String friendName) {
    return box.values.where((l) => l.friendName == friendName).toList();
  }
}
