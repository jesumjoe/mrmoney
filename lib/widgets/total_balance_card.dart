import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/theme/neo_style.dart';

class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BankAccountProvider, TransactionProvider>(
      builder: (context, bankProvider, transactionProvider, child) {
        final totalBalance = bankProvider.totalBalance;
        final todayExpense = transactionProvider.todayExpense;
        final formattedBalance = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
        ).format(totalBalance);
        final formattedExpense = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
        ).format(todayExpense);

        return NeoCard(
          color: NeoColors.yellow, // Bright yellow for attention
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL BALANCE',
                style: NeoStyle.bold(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedBalance,
                style: NeoStyle.bold(fontSize: 32, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Wrap in Expanded to avoid overflow
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            // Wrap text
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TODAY',
                                  style: NeoStyle.bold(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  formattedExpense,
                                  style: NeoStyle.bold(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
