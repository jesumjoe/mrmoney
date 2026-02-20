import 'package:flutter_test/flutter_test.dart';
import 'package:mrmoney/services/sms_parsing_service.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/models/transaction_type.dart';

void main() {
  test('Parses South Indian Bank multi-line SMS correctly', () {
    String sms = """UPI debit:Rs.10.00,A/c X4258,
20-02-26 18:35:28
RRN:641794759154.
Bal:Rs.264209.71 Block A/c?
Call18004251809/SMS BLK< A/c>to
9840777222-South Indian Bank""";

    final bankAccount = BankAccount(
      id: '1',
      bankName: 'South Indian Bank',
      accountNumber: '4258',
      currentBalance: 0,
      smsKeyword: 'South Indian Bank',
      isSmsParsingEnabled: true,
    );

    final parser = SmsParsingService();
    final result = parser.parseSms(sms, DateTime.now(), [bankAccount]);

    expect(result, isNotNull);
    expect(result!.amount, 10.00);
    expect(result.type, TransactionType.debit);
    expect(result.accountLastDigits, '4258');
  });
}
