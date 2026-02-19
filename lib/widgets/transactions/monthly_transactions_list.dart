import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';

class MonthlyTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(DateTime) onMonthSelected;

  const MonthlyTransactionsList({
    super.key,
    required this.transactions,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions yet',
          style: NeoStyle.regular(color: NeoColors.textSecondary),
        ),
      );
    }

    // Group by Month (yyyy-MM)
    final Map<String, List<Transaction>> groupedByMonth = {};
    for (var t in transactions) {
      final key = DateFormat('yyyy-MM').format(t.date);
      if (!groupedByMonth.containsKey(key)) {
        groupedByMonth[key] = [];
      }
      groupedByMonth[key]!.add(t);
    }

    // Sort months descending
    final sortedKeys = groupedByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final monthKey = sortedKeys[index];
        final monthTransactions = groupedByMonth[monthKey]!;
        final date = DateTime.parse('$monthKey-01');

        double income = 0;
        double expense = 0;
        for (var t in monthTransactions) {
          if (t.type == TransactionType.credit) {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
        final net = income - expense;

        return InkWell(
          onTap: () => onMonthSelected(date),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeoColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeoColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(date),
                      style: NeoStyle.bold(fontSize: 18),
                    ),
                    Icon(Icons.chevron_right, color: NeoColors.textSecondary),
                  ],
                ),
                const Divider(height: 24, color: NeoColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income',
                          style: NeoStyle.regular(
                            fontSize: 12,
                            color: NeoColors.textSecondary,
                          ),
                        ),
                        Text(
                          '+₹${NumberFormat('#,##0').format(income)}',
                          style: NeoStyle.bold(
                            color: NeoColors.success,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense',
                          style: NeoStyle.regular(
                            fontSize: 12,
                            color: NeoColors.textSecondary,
                          ),
                        ),
                        Text(
                          '-₹${NumberFormat('#,##0').format(expense)}',
                          style: NeoStyle.bold(
                            color: NeoColors.error,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Net',
                          style: NeoStyle.regular(
                            fontSize: 12,
                            color: NeoColors.textSecondary,
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##0').format(net)}',
                          style: NeoStyle.bold(
                            color: net >= 0 ? NeoColors.text : NeoColors.error,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
