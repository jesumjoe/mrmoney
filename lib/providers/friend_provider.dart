import 'package:flutter/material.dart';
import 'package:mrmoney/models/friend_loan.dart';
import 'package:mrmoney/repositories/friend_loan_repository.dart';

class FriendProvider with ChangeNotifier {
  final FriendLoanRepository _repository;

  List<FriendLoan> _loans = [];
  List<FriendLoan> get loans => _loans;

  // Grouped friends data
  Map<String, double> get friendBalances {
    final Map<String, double> balances = {};
    for (var loan in _loans) {
      if (loan.isSettled) continue;

      if (!balances.containsKey(loan.friendName)) {
        balances[loan.friendName] = 0.0;
      }

      // type 0 = owe ( I owe them, so negative)
      // type 1 = owed ( They owe me, so positive)
      // Wait, let's check Enum
      // owe = I owe them
      // owed = They owe me

      if (loan.type == FriendLoanType.owe) {
        balances[loan.friendName] = balances[loan.friendName]! - loan.amount;
      } else {
        balances[loan.friendName] = balances[loan.friendName]! + loan.amount;
      }
    }
    return balances;
  }

  FriendProvider(this._repository) {
    loadLoans();
  }

  void loadLoans() {
    _loans = _repository.getAll();
    // Sort by date desc
    _loans.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  List<FriendLoan> getLoansForFriend(String name) {
    return _loans.where((l) => l.friendName == name).toList();
  }

  Future<void> addLoan(FriendLoan loan) async {
    await _repository.add(loan);
    loadLoans();
  }

  Future<void> settleLoan(FriendLoan loan) async {
    loan.isSettled = true;
    await loan.save();
    notifyListeners();
  }

  Future<void> deleteLoan(FriendLoan loan) async {
    await loan.delete();
    loadLoans();
  }
}
