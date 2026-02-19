import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent transactions.',
                    style: NeoStyle.regular(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isCredit = transaction.type == TransactionType.credit;

              return Dismissible(
                key: Key(transaction.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: NeoStyle.box(
                    color: NeoColors.error,
                    radius: NeoStyle.radius,
                    noShadow: true,
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onDismissed: (direction) {
                  provider.deleteTransaction(transaction);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Transaction deleted',
                        style: NeoStyle.bold(color: Colors.white),
                      ),
                      backgroundColor: NeoColors.text,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                },
                child: NeoCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: NeoStyle.circle(
                          color: isCredit
                              ? NeoColors.success.withOpacity(0.2)
                              : NeoColors.error.withOpacity(0.2),
                          borderColor: NeoColors.border,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: NeoColors.text,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
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
                              transaction.description.isNotEmpty
                                  ? transaction.description
                                  : DateFormat(
                                      'MMM d, yyyy',
                                    ).format(transaction.date),
                              style: NeoStyle.regular(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
                            style: NeoStyle.bold(
                              fontSize: 16,
                              color: isCredit
                                  ? NeoColors.success
                                  : NeoColors.error,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(transaction.date),
                            style: NeoStyle.regular(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
