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
    final catRepo = Provider.of<CategoryRepository>(context, listen: false);

    return Consumer2<BudgetProvider, TransactionProvider>(
      builder: (context, budgetProvider, txProvider, child) {
        final goal = budgetProvider.savingsGoal;
        if (goal <= 0) return const SizedBox.shrink();

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
            final catName = t.category;
            categorySpent[catName] = (categorySpent[catName] ?? 0) + t.amount;
          }
        }

        final projected = BudgetService.calculateProjectedSpending(
          currentSpent: expense,
          currentMonth: now,
        );

        final currentBalance = income - expense;
        final safeToSpend = currentBalance - goal;
        final isSafe = safeToSpend > 0;

        final warnings = <Widget>[];

        if (safeToSpend < 0) {
          warnings.add(
            BudgetInsightCard(
              title: "Goal at Risk",
              message:
                  "You have dipped into your savings by ₹${safeToSpend.abs().toStringAsFixed(0)}.",
              isWarning: true,
            ),
          );
        } else if (safeToSpend < (goal * 0.2)) {
          warnings.add(
            BudgetInsightCard(
              title: "Approaching Limit",
              message:
                  "Only ₹${safeToSpend.toStringAsFixed(0)} left before touching your savings.",
              isWarning: true,
            ),
          );
        }

        if (currentBalance > 0 && (income - projected) < goal) {
          final potentialShortfall = goal - (income - projected);
          if (potentialShortfall > 0) {
            warnings.add(
              BudgetInsightCard(
                title: "Projected Shortfall",
                message:
                    "At this rate, you might miss your goal by ₹${potentialShortfall.toStringAsFixed(0)}.",
                isWarning: true,
              ),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget Overview', style: NeoStyle.bold(fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: NeoStyle.box(
                    color: NeoColors.surface,
                    radius: 20,
                    noShadow: true,
                  ),
                  child: Text(
                    DateFormat('MMMM').format(now),
                    style: NeoStyle.bold(
                      fontSize: 12,
                      color: NeoColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Goal Card
            NeoCard(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Savings Goal',
                        style: NeoStyle.regular(
                          fontSize: 14,
                          color: NeoColors.textSecondary,
                        ),
                      ),
                      Icon(Icons.flag_rounded, color: NeoColors.text, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                      decimalDigits: 0,
                    ).format(goal),
                    style: NeoStyle.bold(fontSize: 24),
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double progress =
                          (currentBalance > 0 && currentBalance >= goal
                                  ? 1.0
                                  : (currentBalance > 0
                                        ? currentBalance / goal
                                        : 0.0))
                              .clamp(0.0, 1.0);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isSafe ? 'On Track' : 'Off Track',
                                style: NeoStyle.bold(
                                  fontSize: 12,
                                  color: isSafe
                                      ? NeoColors.success
                                      : NeoColors.error,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: NeoStyle.bold(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                width: constraints.maxWidth,
                                decoration: BoxDecoration(
                                  color: NeoColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 8,
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(
                                  color: isSafe
                                      ? NeoColors.primary
                                      : NeoColors.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSafe
                        ? 'Safe: ₹${safeToSpend.toStringAsFixed(0)} left'
                        : 'Over by ₹${safeToSpend.abs().toStringAsFixed(0)}',
                    style: NeoStyle.regular(
                      fontSize: 12,
                      color: NeoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (warnings.isNotEmpty) ...[
              ...warnings,
              const SizedBox(height: 24),
            ],

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
