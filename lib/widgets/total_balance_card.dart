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
        // Let's stick to what was there:
        final expenseValue = transactionProvider.todayExpense;

        final formattedBalance = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        ).format(totalBalance);

        final formattedExpense = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        ).format(expenseValue);

        return NeoCard(
          color: NeoColors.primary, // Black background
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: NeoStyle.regular(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedBalance,
                style: NeoStyle.bold(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Spend',
                        style: NeoStyle.regular(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        formattedExpense,
                        style: NeoStyle.bold(fontSize: 16, color: Colors.white),
                      ),
                    ],
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
