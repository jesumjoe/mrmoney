import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyTrendBarChart extends StatelessWidget {
  final Map<DateTime, double> dailyData;

  const DailyTrendBarChart({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No data for this period")),
      );
    }

    final sortedDates = dailyData.keys.toList()..sort();
    final maxY = dailyData.values.fold(
      0.0,
      (prev, curr) => curr > prev ? curr : prev,
    );

    // Prepare bar groups
    final barGroups = List.generate(sortedDates.length, (index) {
      final date = sortedDates[index];
      final amount = dailyData[date] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 100 : maxY * 1.2, // Add some headroom
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = sortedDates[group.x.toInt()];
                return BarTooltipItem(
                  '${DateFormat('MM/dd').format(date)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '₹${rod.toY.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedDates.length) {
                    return const SizedBox.shrink();
                  }

                  // Show only some labels to avoid overcrowding
                  if (sortedDates.length > 7 && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }

                  final date = sortedDates[index];
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('d').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}
