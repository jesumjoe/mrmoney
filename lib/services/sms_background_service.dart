import 'package:another_telephony/telephony.dart';
import 'package:flutter/widgets.dart';
import 'package:mrmoney/services/sms_parsing_service.dart';
import 'package:mrmoney/services/notification_service.dart';
import 'package:mrmoney/services/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mrmoney/services/home_widget_service.dart';

Future<void> _log(String message) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sms_debug.log');
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('$timestamp: $message\n', mode: FileMode.append);
    print(message); // Still print to console just in case
  } catch (e) {
    print("Logging Error: $e");
  }
}

// Top-level function for background execution
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  if (message.body == null) return;

  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _log("Background SMS received: ${message.body}"); // Debug Log

    // 1. Initialize Hive in Background Isolate
    await HiveService.init();
    await _log("Background Hive initialized");

    // 1.5 Initialize Notification Service in Background Isolate
    // Required for showing notifications from background
    await NotificationService().init();
    await _log("Background NotificationService initialized");

    // 2. Get Accounts for parsing context
    final accountBox = Hive.box<BankAccount>('bank_accounts');
    final accounts = accountBox.values.toList();
    await _log("Loaded ${accounts.length} accounts for parsing");

    final parser = SmsParsingService();
    final parsed = parser.parseSms(message.body!, DateTime.now(), accounts);

    if (parsed != null) {
      await _log("SMS Parsed Successfully: ${parsed.amount} ${parsed.type}");
      // 3. Save Transaction
      final transactionBox = Hive.box<Transaction>('transactions');

      // Attempt to find the account ID if matched
      String? accountId;
      if (parsed.accountLastDigits != 'Unknown') {
        // Try to find account by last 4 digits
        // This is a heuristic. Ideally we use the matchedAccount from parsing,
        // but ParsedSms only stores accountLastDigits currently.
        // We might need to improve ParsedSms to store ID or look it up again.
        // Let's look it up.
        try {
          final account = accounts.firstWhere((a) {
            // Parsed usually has 4 digits (e.g. 1234), User has 3 (e.g. 234).
            return parsed.accountLastDigits.endsWith(a.accountNumber) ||
                a.accountNumber.endsWith(parsed.accountLastDigits);
          });
          accountId = account.id;
        } catch (_) {}
      }

      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: parsed.amount,
        type: parsed.type,
        category: 'Uncategorized', // Default
        description: parsed.merchant ?? 'SMS Transaction',
        date: parsed.date,
        bankAccountId: accountId,
        isFromSMS: true,
      );

      await transactionBox.add(transaction);

      // Update Home Widget
      await HomeWidgetService.updateWidgetData(transactionBox.values.toList());

      // 4. Update Account Balance
      if (accountId != null) {
        final account = accountBox.values.firstWhere((a) => a.id == accountId);
        if (parsed.type == TransactionType.credit) {
          account.currentBalance += parsed.amount;
        } else {
          account.currentBalance -= parsed.amount;
        }
        await account.save();
      }

      // 5. Show Notification
      NotificationService().showTransactionNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'New Transaction Detected',
        body:
            '${parsed.type.name.toUpperCase()}: ₹${parsed.amount} at ${parsed.merchant ?? "Unknown"}',
        payload: transaction.id, // Payload is now the Transaction ID
      );
      await _log("Notification shown for transaction ${transaction.id}");
    } else {
      await _log("SMS failed to parse");
    }
  } catch (e) {
    await _log("Background SMS Error: $e");
    debugPrint("Background SMS Error: $e");
  }
}

class SmsBackgroundService {
  final Telephony telephony = Telephony.instance;

  Future<void> init() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) return;

    telephony.listenIncomingSms(
      onNewMessage: _onForegroundMessage,
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  void _onForegroundMessage(SmsMessage message) {
    // When app is open, we can directly process or just show notification too.
    if (message.body == null) return;

    final parser = SmsParsingService();
    // Pass empty list for accounts in background/foreground for now.
    // TODO: Initialize Hive to access custom rules in background.
    final parsed = parser.parseSms(message.body!, DateTime.now(), []);

    if (parsed != null) {
      NotificationService().showTransactionNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'New Transaction Detected',
        body:
            '${parsed.type.name.toUpperCase()}: ₹${parsed.amount} at ${parsed.merchant ?? "Unknown"}',
        payload:
            '${parsed.amount}|${parsed.type.name}|${parsed.accountLastDigits}|${parsed.merchant}|${parsed.date.toIso8601String()}',
      );
    }
  }
}
