import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:flutter/foundation.dart';

class ParsedSms {
  final double amount;
  final TransactionType type;
  final String accountLastDigits;
  final String? merchant;
  final DateTime date;

  ParsedSms({
    required this.amount,
    required this.type,
    required this.accountLastDigits,
    this.merchant,
    required this.date,
  });

  @override
  String toString() {
    return 'ParsedSms(amount: $amount, type: $type, account: $accountLastDigits, merchant: $merchant)';
  }
}

class SmsParsingService {
  // Regex patterns for common Indian banks
  // Capture groups: 1=Amount, 2=Account, 3=Merchant/Info
  static final List<RegExp> _debitPatterns = [
    // SIB: UPI debit:Rs.110.00,A/c X4258, ...
    RegExp(
      r'UPI\s*debit:(?:INR|Rs\.?)\s*([0-9,.]+),.*A\/c\s+([0-9X]+).*',
      caseSensitive: false,
      dotAll: true,
    ),
    // Canara: An amount of INR 55.00 has been DEBITED to your account XXX584 ...
    RegExp(
      r'An\s+amount\s+of\s+(?:INR|Rs\.?)\s*([0-9,.]+)\s+has\s+been\s+DEBITED\s+to\s+your\s+account\s+([0-9X]+).*',
      caseSensitive: false,
      dotAll: true,
    ),
    // HDFC: Debited INR 500.00 from A/c XX1234 on 22-01-25. Info: AMAZON PAY
    RegExp(
      r'Debited\s+(?:INR|Rs\.?)\s*([0-9,.]+)\s+from\s+.*A\/c\s+([0-9X]+).+Info:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ),
    // SBI: Txn of INR 500.00 done on A/C ending 1234 at AMAZON
    RegExp(
      r'Txn\s+of\s+(?:INR|Rs\.?)\s*([0-9,.]+)\s+done\s+on\s+A\/C\s+ending\s+([0-9X]+).+at\s+(.*)',
      caseSensitive: false,
      dotAll: true,
    ),
    // ICICI: Acct XX1234 debited with INR 500.00 on 22-Jan. Info: UPI-12345
    RegExp(
      r'Acct\s+([0-9X]+)\s+debited\s+with\s+(?:INR|Rs\.?)\s*([0-9,.]+).+Info:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ),
    // Generic UPI
    RegExp(
      r'Debited\s+by\s+([0-9,.]+)\s+.*Top\s+.*VPA\s+(.*)',
      caseSensitive: false,
      dotAll: true,
    ),
    // Paid thru UPI
    RegExp(
      r'(?:INR|Rs\.?)\s*([0-9,.]+)\s+paid\s+thru\s+A\/C\s+([0-9X]+).*',
      caseSensitive: false,
      dotAll: true,
    ),
  ];

  static final List<RegExp> _creditPatterns = [
    // SIB: UPI Credit:INR Rs.170.00 in A/c X4258. Info:...
    RegExp(
      r'UPI\s*Credit:(?:INR|Rs\.?)\s*([0-9,.]+)\s+in\s+A\/c\s+([0-9X]+).*',
      caseSensitive: false,
      dotAll: true,
    ),
    // Canara: Your a/c no. XX2584 has been credited with Rs.20090.00 ... from a/c no. XX4258
    RegExp(
      r'Your\s+a\/c\s+no\.\s+([0-9X]+)\s+has\s+been\s+credited\s+with\s+(?:INR|Rs\.?)\s*([0-9,.]+).*',
      caseSensitive: false,
      dotAll: true,
    ),
    // HDFC: Credited INR 500.00 to A/c XX1234
    RegExp(
      r'Credited\s+(?:INR|Rs\.?)\s*([0-9,.]+)\s+to\s+.*A\/c\s+([0-9X]+).+Info:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ),
    // Generic Credit
    RegExp(
      r'Credited\s+by\s+([0-9,.]+)\s+.*Info:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ),
    // Received via UPI
    RegExp(
      r'Received\s+(?:INR|Rs\.?)\s*([0-9,.]+)\s+from\s+(.*)\s+in\s+A\/c\s+([0-9X]+).*',
      caseSensitive: false,
      dotAll: true,
    ),
    // Deposited
    RegExp(
      r'(?:INR|Rs\.?)\s*([0-9,.]+)\s+deposited\s+to\s+A\/c\s+([0-9X]+).*',
      caseSensitive: false,
      dotAll: true,
    ),
  ];

  ParsedSms? parseSms(
    String body,
    DateTime receivedDate,
    List<BankAccount> accounts,
  ) {
    // 1. Check if SMS matches any account keyword
    BankAccount? matchedAccount;
    for (var acc in accounts) {
      if (acc.smsKeyword.isNotEmpty &&
          body.toUpperCase().contains(acc.smsKeyword.toUpperCase()) &&
          acc.isSmsParsingEnabled) {
        matchedAccount = acc;
        break;
      }
    }

    if (matchedAccount != null) {
      // Try custom patterns first
      final customResult = _tryParseCustom(body, receivedDate, matchedAccount);
      if (customResult != null) return customResult;
    }

    // 2. Fallback to default patterns if no custom match or no account match
    // Determine Type (Debit/Credit)
    bool isDebit =
        body.toLowerCase().contains('debit') ||
        body.toLowerCase().contains('dr') ||
        body.toLowerCase().contains('paid');
    bool isCredit =
        body.toLowerCase().contains('credit') ||
        body.toLowerCase().contains('cr') ||
        body.toLowerCase().contains('deposited') ||
        body.toLowerCase().contains('received');

    if (!isDebit && !isCredit) return null; // Likely not a transaction SMS

    TransactionType type = isDebit
        ? TransactionType.debit
        : TransactionType.credit;

    // If we matched an account, we can prioritize its context, but standard regex
    // might still be needed.

    List<RegExp> patterns = isDebit ? _debitPatterns : _creditPatterns;

    for (var regex in patterns) {
      final match = regex.firstMatch(body);
      if (match != null) {
        try {
          String amountStr = '';
          String accountStr = 'Unknown';
          String merchantStr = matchedAccount?.bankName ?? 'Unknown';

          for (int i = 1; i <= match.groupCount; i++) {
            final group = match.group(i);
            if (group == null) continue;

            // Heuristics
            if (RegExp(r'^[0-9,.]+$').hasMatch(group) && amountStr.isEmpty) {
              amountStr = group; // Likely amount
            } else if (RegExp(r'[0-9X]+').hasMatch(group) &&
                group.length > 2 &&
                (accountStr == 'Unknown' ||
                    // Robust check: does one end with the other?
                    (matchedAccount != null &&
                        (matchedAccount.accountNumber.endsWith(group) ||
                            group.endsWith(matchedAccount.accountNumber))))) {
              // If we already know the account, we might not need this, but good to verify
              if (group.toUpperCase().contains('X') || group.length >= 3) {
                accountStr = group;
              }
            } else {
              merchantStr = group;
            }
          }

          if (amountStr.isEmpty) continue; // Must have amount

          final amount = double.parse(amountStr.replaceAll(',', ''));

          return ParsedSms(
            amount: amount,
            type: type,
            accountLastDigits: matchedAccount?.accountNumber ?? accountStr,
            merchant: merchantStr.trim(),
            date: receivedDate,
          );
        } catch (e) {
          debugPrint("Error parsing SMS match: $e");
          continue;
        }
      }
    }

    // Fallback: If no strict regex matched, try to just find "INR XXX"
    final fallbackAmount = RegExp(
      r'(?:INR|Rs\.?)\s*([0-9,.]+)',
    ).firstMatch(body);
    if (fallbackAmount != null) {
      final amount = double.tryParse(
        fallbackAmount.group(1)?.replaceAll(',', '') ?? '',
      );
      if (amount != null) {
        return ParsedSms(
          amount: amount,
          type: type,
          accountLastDigits: matchedAccount?.accountNumber ?? 'Unknown',
          merchant: matchedAccount?.bankName ?? 'Unknown',
          date: receivedDate,
        );
      }
    }

    return null;
  }

  ParsedSms? _tryParseCustom(String body, DateTime date, BankAccount account) {
    // Custom Debit
    for (var pattern in account.customDebitRegex) {
      final res = _parseWithPattern(
        body,
        date,
        pattern,
        TransactionType.debit,
        account,
      );
      if (res != null) return res;
    }
    // Custom Credit
    for (var pattern in account.customCreditRegex) {
      final res = _parseWithPattern(
        body,
        date,
        pattern,
        TransactionType.credit,
        account,
      );
      if (res != null) return res;
    }
    return null;
  }

  ParsedSms? _parseWithPattern(
    String body,
    DateTime date,
    String pattern,
    TransactionType type,
    BankAccount account,
  ) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(body);
      if (match != null) {
        // Assume Group 1 is Amount.
        // Ideally, we need named groups or configuration.
        // For now, let's assume standard capture group order or just find the amount-like group.
        // Or user provides regex with groups.
        // Let's assume: Group 1 = Amount. Group 2 or others = Optional info.

        String amountStr = '';
        String merchantStr = '';

        for (int i = 1; i <= match.groupCount; i++) {
          final g = match.group(i);
          if (g == null) continue;
          if (RegExp(r'^[0-9,.]+$').hasMatch(g) && amountStr.isEmpty) {
            amountStr = g;
          } else {
            merchantStr += "$g ";
          }
        }

        if (amountStr.isNotEmpty) {
          final amount = double.tryParse(amountStr.replaceAll(',', ''));
          if (amount != null) {
            return ParsedSms(
              amount: amount,
              type: type,
              accountLastDigits: account.accountNumber,
              merchant: merchantStr.trim().isEmpty
                  ? account.bankName
                  : merchantStr.trim(),
              date: date,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Custom regex error: $e");
    }
    return null;
  }
}
