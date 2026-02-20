import 'package:home_widget/home_widget.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';

class HomeWidgetService {
  static const String appGroupId =
      'group.mrmoney'; // Replace with actual app group if using iOS
  static const String iOSWidgetName = 'MrMoneyWidget';
  static const String androidWidgetName = 'HomeWidgetProvider';

  static Future<void> updateWidgetData(List<Transaction> transactions) async {
    final now = DateTime.now();
    double dailySpent = 0;
    double dailyReceived = 0;
    int pendingCount = 0;

    for (var t in transactions) {
      // Calculate Daily Totals
      if (t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        if (t.type == TransactionType.debit) {
          dailySpent += t.amount;
        } else if (t.type == TransactionType.credit) {
          dailyReceived += t.amount;
        }
      }

      // Calculate Pending Transactions (Uncategorized or empty category)
      // Assuming 'Uncategorized' is the key or empty string
      if (t.category == 'Uncategorized' || t.category.isEmpty) {
        pendingCount++;
      }
    }

    await HomeWidget.saveWidgetData<double>('daily_spent', dailySpent);
    await HomeWidget.saveWidgetData<double>('daily_received', dailyReceived);
    await HomeWidget.saveWidgetData<int>('pending_count', pendingCount);

    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
    /* print(
      "Widget Updated: Spent: $dailySpent, Received: $dailyReceived, Pending: $pendingCount",
    ); */
  }
}
