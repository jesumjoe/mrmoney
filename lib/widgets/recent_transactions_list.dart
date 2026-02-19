import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = provider.recentTransactions;

        if (transactions.isEmpty) {
          return Center(
            child: Text(
              'No transactions yet.',
              style: NeoStyle.bold(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isCredit = transaction.type == TransactionType.credit;

            return NeoCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCredit ? NeoColors.mint : NeoColors.salmon,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.black,
                  ),
                ),
                title: Text(
                  transaction.category,
                  style: NeoStyle.bold(fontSize: 16),
                ),
                subtitle: Text(
                  DateFormat('MMM d, h:mm a').format(transaction.date),
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                trailing: Text(
                  '${isCredit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
                  style: NeoStyle.bold(
                    fontSize: 16,
                    color: isCredit ? Colors.black : Colors.black,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
