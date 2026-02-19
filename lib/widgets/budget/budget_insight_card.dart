import 'package:flutter/material.dart';
import 'package:mrmoney/theme/neo_style.dart';

class BudgetInsightCard extends StatelessWidget {
  final String title;
  final String message;
  final bool isWarning;

  const BudgetInsightCard({
    super.key,
    required this.title,
    required this.message,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      color: isWarning ? NeoColors.surface : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWarning
                  ? NeoColors.error.withOpacity(0.1)
                  : NeoColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWarning
                  ? Icons.priority_high_rounded
                  : Icons.lightbulb_outline_rounded,
              color: isWarning ? NeoColors.error : NeoColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NeoStyle.bold(fontSize: 14, color: NeoColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: NeoStyle.regular(
                    fontSize: 13,
                    color: NeoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
