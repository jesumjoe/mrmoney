import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/screens/edit_transaction_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const DailyTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: NeoColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions this month',
              style: NeoStyle.regular(color: NeoColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Group by day using Provider static method
    final groupedTransactions = TransactionProvider.groupTransactionsByDate(
      transactions,
    );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final dailyTransactions = groupedTransactions[dateKey] ?? [];
        final date = DateTime.parse(dateKey);

        // Daily Calculations
        double dailyIncome = 0;
        double dailyExpense = 0;
        for (var t in dailyTransactions) {
          if (t.type == TransactionType.credit) {
            dailyIncome += t.amount;
          } else {
            dailyExpense += t.amount;
          }
        }

        return Column(
              children: [
                // Day Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: NeoColors.background,
                  child: Row(
                    children: [
                      Text(
                        DateFormat('dd').format(date),
                        style: NeoStyle.bold(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NeoColors.textSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          DateFormat('E').format(date),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MM.yyyy').format(date),
                        style: const TextStyle(
                          color: NeoColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      // Daily Income & Expense
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (dailyIncome > 0)
                              Flexible(
                                child: Text(
                                  NumberFormat('#,##0').format(dailyIncome),
                                  style: const TextStyle(
                                    color: NeoColors.primary,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (dailyIncome > 0 && dailyExpense > 0)
                              const SizedBox(width: 8),

                            if (dailyExpense > 0)
                              Flexible(
                                child: Text(
                                  NumberFormat('#,##0').format(dailyExpense),
                                  style: const TextStyle(
                                    color: NeoColors.error,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: NeoColors.border),

                // Transactions for the day
                ...dailyTransactions.map((t) {
                  final isCredit = t.type == TransactionType.credit;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditTransactionScreen(transaction: t),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                t.category,
                                style: const TextStyle(
                                  color: NeoColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                t.description.isNotEmpty
                                    ? t.description
                                    : 'Cash/Bank',
                                style: const TextStyle(
                                  color: NeoColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Hero(
                              tag: 'amount_${t.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  '₹${NumberFormat('#,##0.00').format(t.amount)}',
                                  style: TextStyle(
                                    color: isCredit
                                        ? NeoColors.success
                                        : NeoColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Divider(height: 1, color: NeoColors.border),
              ],
            )
            .animate(delay: (50 * index).ms)
            .fade()
            .slideY(
              begin: 0.1,
              end: 0,
              curve: Curves.easeOutQuad,
              duration: 300.ms,
            );
      },
    );
  }
}
