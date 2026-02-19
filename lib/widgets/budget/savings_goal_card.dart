import 'package:flutter/material.dart';

class SavingsGoalCard extends StatelessWidget {
  final double safeToSpend;
  final double savingsGoal;
  final double currentBalance;

  const SavingsGoalCard({
    super.key,
    required this.safeToSpend,
    required this.savingsGoal,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    if (savingsGoal <= 0) return const SizedBox.shrink();

    final isSafe = safeToSpend > 0;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Savings Goal: ₹${savingsGoal.toStringAsFixed(0)}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              "Safe to Spend: ₹${safeToSpend.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isSafe ? null : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: currentBalance > 0
                  ? (safeToSpend / currentBalance).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            const SizedBox(height: 4),
            Text(
              isSafe
                  ? "You are on track!"
                  : "You are dipping into your savings.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSafe ? null : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
