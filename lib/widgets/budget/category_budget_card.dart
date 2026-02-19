import 'package:flutter/material.dart';
import 'package:mrmoney/models/category.dart';
import 'package:mrmoney/theme/neo_style.dart';

class CategoryBudgetCard extends StatelessWidget {
  final Category category;
  final double spent;

  const CategoryBudgetCard({
    super.key,
    required this.category,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    if (category.budgetLimit == null || category.budgetLimit == 0) {
      return const SizedBox.shrink();
    }

    final limit = category.budgetLimit!;
    final progress = (spent / limit).clamp(0.0, 1.0);
    final isOver = spent > limit;

    return NeoCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.name, style: NeoStyle.bold(fontSize: 14)),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: NeoStyle.bold(
                  fontSize: 12,
                  color: isOver ? NeoColors.error : NeoColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: NeoColors.surface,
              color: isOver ? NeoColors.error : NeoColors.primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${spent.toStringAsFixed(0)} spent',
                style: NeoStyle.regular(
                  fontSize: 12,
                  color: NeoColors.textSecondary,
                ),
              ),
              Text(
                'Limit: ₹${limit.toStringAsFixed(0)}',
                style: NeoStyle.regular(
                  fontSize: 12,
                  color: NeoColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
