import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> points;

  const BalanceLineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No balance data")),
      );
    }

    final flSpots = List<FlSpot>.generate(points.length, (index) {
      return FlSpot(index.toDouble(), points[index]['balance']);
    });

    final minY = points
        .map((e) => e['balance'] as double)
        .reduce((a, b) => a < b ? a : b);
    final maxY = points
        .map((e) => e['balance'] as double)
        .reduce((a, b) => a > b ? a : b);

    return AspectRatio(
      aspectRatio: 1.70,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Show sparse labels
                  if (points.length > 5 && index % (points.length ~/ 5) != 0) {
                    return const SizedBox.shrink();
                  }

                  final date = points[index]['date'] as DateTime;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('MM/dd').format(date),
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
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minY * 0.9,
          maxY: maxY * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: flSpots,
              isCurved: true,
              color: Theme.of(context).colorScheme.tertiary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = points[spot.x.toInt()]['date'] as DateTime;
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(date)}\n₹${spot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
