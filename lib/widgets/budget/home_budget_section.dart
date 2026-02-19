import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/budget_provider.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/repositories/category_repository.dart';
import 'package:mrmoney/services/budget_service.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';
import 'package:mrmoney/widgets/budget/budget_insight_card.dart';
import 'package:mrmoney/widgets/budget/category_budget_card.dart';

class HomeBudgetSection extends StatelessWidget {
  const HomeBudgetSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Access CategoryRepository without listening (it's a repository, likely not notifying directly or handled by BudgetProvider)
    final catRepo = Provider.of<CategoryRepository>(context, listen: false);

    return Consumer2<BudgetProvider, TransactionProvider>(
      builder: (context, budgetProvider, txProvider, child) {
        final goal = budgetProvider.savingsGoal;
        if (goal <= 0) return const SizedBox.shrink();

        // Calculate current month's totals
        final now = DateTime.now();
        final currentMonthTxs = txProvider.transactions
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();

        double income = 0;
        double expense = 0;
        final Map<String, double> categorySpent = {};

        for (var t in currentMonthTxs) {
          if (t.type == TransactionType.credit) {
            income += t.amount;
          } else {
            expense += t.amount;
            // Track category spending
            final catName = t.category;
            categorySpent[catName] = (categorySpent[catName] ?? 0) + t.amount;
          }
        }

        // Project spending
        final projected = BudgetService.calculateProjectedSpending(
          currentSpent: expense,
          currentMonth: now,
        );

        // Safe to spend logic
        final currentBalance = income - expense;
        final safeToSpend = currentBalance - goal;
        final isSafe = safeToSpend > 0;

        // Warnings
        final warnings = <Widget>[];

        // 1. Safe to spend warning
        if (safeToSpend < 0) {
          warnings.add(
            BudgetInsightCard(
              title: "Goal at Risk!",
              message:
                  "⚠️ You have dipped into your savings by ₹${safeToSpend.abs().toStringAsFixed(0)}.",
              isWarning: true,
            ),
          );
        } else if (safeToSpend < (goal * 0.2)) {
          warnings.add(
            BudgetInsightCard(
              title: "Approaching Limit",
              message:
                  "⚠️ You only have ₹${safeToSpend.toStringAsFixed(0)} left before touching your savings.",
              isWarning: true,
            ),
          );
        }

        // 2. Projected warning (General)
        if (currentBalance > 0 && (income - projected) < goal) {
          final potentialShortfall = goal - (income - projected);
          if (potentialShortfall > 0) {
            warnings.add(
              BudgetInsightCard(
                title: "Projected Shortfall",
                message:
                    "📉 At this rate, you might miss your goal by ₹${potentialShortfall.toStringAsFixed(0)}.",
                isWarning: true,
              ),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BUDGET & GOALS',
              style: NeoStyle.bold(color: Colors.black.withOpacity(0.5)),
            ),
            const SizedBox(height: 12),

            // Settings Goal Card (Neo Style)
            NeoCard(
              color: NeoColors.indigo,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Goal',
                        style: NeoStyle.bold(color: Colors.white70),
                      ),
                      const Icon(Icons.flag, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                    ).format(goal),
                    style: NeoStyle.bold(fontSize: 28, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentBalance > 0 && currentBalance >= goal
                          ? 1.0
                          : (currentBalance > 0 ? currentBalance / goal : 0.0),
                      color: isSafe ? NeoColors.mint : NeoColors.salmon,
                      backgroundColor: Colors.white24,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSafe ? NeoColors.mint : NeoColors.salmon,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      isSafe
                          ? 'Safe: ₹${safeToSpend.toStringAsFixed(0)} left'
                          : 'Over by ₹${safeToSpend.abs().toStringAsFixed(0)}',
                      style: NeoStyle.bold(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warnings
            if (warnings.isNotEmpty) ...[
              ...warnings,
              const SizedBox(height: 16),
            ],

            // Category Budgets
            ...catRepo.getAll().where((c) => (c.budgetLimit ?? 0) > 0).map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CategoryBudgetCard(
                  category: c,
                  spent: categorySpent[c.name] ?? 0,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
