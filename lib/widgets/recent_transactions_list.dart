import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';
import 'package:mrmoney/screens/edit_transaction_screen.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = provider.recentTransactions;

        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No transactions yet.',
                style: NeoStyle.regular(color: NeoColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: NeoColors.border,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isCredit = transaction.type == TransactionType.credit;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditTransactionScreen(transaction: transaction),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: NeoColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isCredit
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isCredit ? NeoColors.success : NeoColors.text,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.category,
                            style: NeoStyle.bold(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMM d, h:mm a',
                            ).format(transaction.date),
                            style: NeoStyle.regular(
                              color: NeoColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Text(
                      '${isCredit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(0)}',
                      style: NeoStyle.bold(
                        fontSize: 16,
                        color: isCredit ? NeoColors.success : NeoColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
