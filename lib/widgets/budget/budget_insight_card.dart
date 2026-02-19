import 'package:flutter/material.dart';

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
    return Card(
      elevation: 0,
      color: isWarning
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber : Icons.lightbulb,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onTertiaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
