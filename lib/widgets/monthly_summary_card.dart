import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/theme/neo_style.dart';

class MonthlySummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double total;

  const MonthlySummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: NeoColors.surface.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(
            label: 'Income',
            amount: income,
            color: NeoColors.primary, // Or success color if preferred
          ),
          _buildSummaryItem(
            label: 'Expenses',
            amount: expense,
            color: NeoColors.error,
          ),
          _buildSummaryItem(
            label: 'Total',
            amount: total,
            color: total >= 0 ? NeoColors.text : NeoColors.text,
            alignEnd: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required Color color,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : (label == 'Expenses'
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start),
      children: [
        Text(
          label,
          style: const TextStyle(color: NeoColors.textSecondary, fontSize: 12),
        ),
        Text(
          NumberFormat('#,##0.00').format(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
