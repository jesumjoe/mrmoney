import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showIncome = false; // Toggle between Expense (false) and Income (true)
  int _touchedIndex = -1;

  void _changeMonth(int months) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + months,
        _selectedDate.day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions.where((t) {
            return t.date.year == _selectedDate.year &&
                t.date.month == _selectedDate.month &&
                t.type ==
                    (_showIncome
                        ? TransactionType.credit
                        : TransactionType.debit);
          }).toList();

          final totalAmount = transactions.fold(
            0.0,
            (sum, t) => sum + t.amount,
          );

          // Group by catergory
          final Map<String, double> categoryTotals = {};
          for (var t in transactions) {
            categoryTotals[t.category] =
                (categoryTotals[t.category] ?? 0) + t.amount;
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Colors for chart
          final List<Color> chartColors = [
            const Color(0xFFEF4444), // Red
            const Color(0xFFF59E0B), // Amber
            const Color(0xFF10B981), // Emerald
            const Color(0xFF3B82F6), // Blue
            const Color(0xFF8B5CF6), // Violet
            const Color(0xFFEC4899), // Pink
            const Color(0xFF6366F1), // Indigo
            const Color(0xFF14B8A6), // Teal
            const Color(0xFFF97316), // Orange
            const Color(0xFF64748B), // Slate
          ];

          return Column(
            children: [
              // Date Selector
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMM yyyy').format(_selectedDate),
                      style: NeoStyle.bold(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                    const SizedBox(width: 8),
                    // Breakdown Type Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Monthly View',
                        style: NeoStyle.regular(
                          fontSize: 12,
                          color: NeoColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Type Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Expense',
                        isSelected: !_showIncome,
                        onTap: () => setState(() => _showIncome = false),
                      ),
                    ),
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Income',
                        isSelected: _showIncome,
                        onTap: () => setState(() => _showIncome = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Total Amount Display
              Text(
                _showIncome ? 'Total Income' : 'Total Expenses',
                style: NeoStyle.regular(
                  color: NeoColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${NumberFormat('#,##0').format(totalAmount)}',
                style: NeoStyle.bold(fontSize: 24),
              ),
              const SizedBox(height: 24),

              // Chart
              if (transactions.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No data for this month',
                      style: NeoStyle.regular(color: NeoColors.textSecondary),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 240,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                      centerSpaceRadius: 0, // Full pie as per screenshot
                      sections: List.generate(sortedCategories.length, (i) {
                        final entry = sortedCategories[i];
                        final isTouched = i == _touchedIndex;
                        final fontSize = isTouched ? 16.0 : 12.0;
                        final radius = isTouched ? 110.0 : 100.0;
                        final color = chartColors[i % chartColors.length];
                        final percentage = (entry.value / totalAmount * 100);

                        return PieChartSectionData(
                          color: color,
                          value: entry.value,
                          title: percentage > 5
                              ? '${percentage.toStringAsFixed(1)}%\n${entry.key}'
                              : '',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                          titlePositionPercentageOffset: 0.55,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // List Breakdown
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: 100,
                      left: 24,
                      right: 24,
                    ),
                    itemCount: sortedCategories.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: NeoColors.border),
                    itemBuilder: (context, index) {
                      final entry = sortedCategories[index];
                      final color = chartColors[index % chartColors.length];
                      final percentage = (entry.value / totalAmount * 100);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            // Percentage Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color:
                                      color, // Use distinct chart color for text too if readable, or black
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Icon/Color dot
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Name
                            Expanded(
                              child: Text(
                                entry.key,
                                style: NeoStyle.bold(fontSize: 16),
                              ),
                            ),

                            // Amount
                            Text(
                              '₹${NumberFormat('#,##0.00').format(entry.value)}',
                              style: NeoStyle.bold(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? NeoColors.error
                  : Colors
                        .transparent, // Default to error color for active tab line like screenshot
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: isSelected
                ? NeoStyle.bold(color: NeoColors.text, fontSize: 16)
                : NeoStyle.regular(
                    color: NeoColors.textSecondary,
                    fontSize: 16,
                  ),
          ),
        ),
      ),
    );
  }
}
