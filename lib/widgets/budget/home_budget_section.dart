import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/budget_provider.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/repositories/category_repository.dart';
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
        // We use txProvider as a rebuild trigger, but data comes from budgetProvider.
        final summary = budgetProvider.budgetSummary;
        final goal = budgetProvider.savingsGoal;

        if (goal <= 0 || summary == null) return const SizedBox.shrink();

        final now = DateTime.now();

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
                          (summary.currentBalance > 0 &&
                                      summary.currentBalance >= goal
                                  ? 1.0
                                  : (summary.currentBalance > 0
                                        ? summary.currentBalance / goal
                                        : 0.0))
                              .clamp(0.0, 1.0);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                summary.isSafe ? 'On Track' : 'Off Track',
                                style: NeoStyle.bold(
                                  fontSize: 12,
                                  color: summary.isSafe
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
                                  color: summary.isSafe
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
                    summary.isSafe
                        ? 'Safe: ₹${summary.safeToSpend.toStringAsFixed(0)} left'
                        : 'Over by ₹${summary.safeToSpend.abs().toStringAsFixed(0)}',
                    style: NeoStyle.regular(
                      fontSize: 12,
                      color: NeoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (summary.insights.isNotEmpty) ...[
              ...summary.insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: BudgetInsightCard(
                    title: insight.title,
                    message: insight.message,
                    isWarning: insight.isWarning,
                  ),
                ),
              ),
            ],

            ...catRepo.getAll().where((c) => (c.budgetLimit ?? 0) > 0).map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CategoryBudgetCard(
                  category: c,
                  spent: summary.categorySpent[c.name] ?? 0,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
