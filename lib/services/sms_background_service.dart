import 'package:another_telephony/telephony.dart';
import 'package:mrmoney/services/sms_parsing_service.dart';
import 'package:mrmoney/services/notification_service.dart';

// Top-level function for background execution
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  // Parsing and notification logic here
  // Note: Hive might not be open in background isolate.
  // We should just show notification. When user taps, app opens and saves data.

  if (message.body == null) return;

  final parser = SmsParsingService();
  // Pass empty list for accounts in background/foreground for now.
  final parsed = parser.parseSms(message.body!, DateTime.now(), []);

  if (parsed != null) {
    // It's a transaction!
    // Initialize notifications (needs to be done in background isolate too?)
    // Actually, local_notifications plugin might need initialization here.

    // For simplicity, let's assume we can just trigger a notification if we init.
    // In a real app, might need more robust background setup.

    // Validating if it's from a bank? Maybe check sender ID length or characters?
    // Bank senders usually: VD-HDFCBK, JM-SBIINB etc. (6 chars, alpha)
    if ((message.address?.length ?? 0) > 9 ||
        (message.address?.contains(RegExp(r'[a-zA-Z]')) ?? false)) {
      // Likely a Service transaction
      // We initialized NotificationService in main, but background isolate is different.
      // Re-init for safety if needed, or just try showing.
      // NotificationService.init() might be needed.
    }
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
