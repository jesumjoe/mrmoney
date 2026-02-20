import 'package:flutter_test/flutter_test.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';

void main() {
  group('TransactionProvider Logic', () {
    test('groupTransactionsByDate groups correctly', () {
      final t1 = Transaction(
        id: '1',
        amount: 100,
        type: TransactionType.debit,
        category: 'Food',
        date: DateTime(2023, 10, 25, 10, 0),
        description: 'Lunch',
      );
      final t2 = Transaction(
        id: '2',
        amount: 200,
        type: TransactionType.debit,
        category: 'Transport',
        date: DateTime(2023, 10, 25, 15, 0),
        description: 'Bus',
      );
      final t3 = Transaction(
        id: '3',
        amount: 500,
        type: TransactionType.credit,
        category: 'Salary',
        date: DateTime(2023, 10, 24, 9, 0),
        description: 'Work',
      );

      final grouped = TransactionProvider.groupTransactionsByDate([t1, t2, t3]);

      expect(grouped.keys.length, 2);
      expect(grouped['2023-10-25']!.length, 2);
      expect(grouped['2023-10-24']!.length, 1);
    });
  });
}
