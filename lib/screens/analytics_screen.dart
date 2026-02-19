import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/services/analytics_service.dart';
import 'package:mrmoney/widgets/analytics/spending_pie_chart.dart';
import 'package:mrmoney/widgets/analytics/daily_trend_bar_chart.dart';
import 'package:mrmoney/widgets/analytics/balance_line_chart.dart';
import 'package:mrmoney/widgets/analytics/stat_card.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

enum TimePeriod { thisWeek, thisMonth, lastMonth, custom }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  TimePeriod _selectedPeriod = TimePeriod.thisMonth;
  DateTimeRange? _customRange;

  // Cache stats
  Map<String, double> _totals = {};
  Map<String, double> _categorySpending = {};
  Map<DateTime, double> _dailySpending = {};
  List<Map<String, dynamic>> _balanceTrend = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final range = _getDateRange();
          final transactions = AnalyticsService.filterTransactions(
            provider.transactions,
            range.start,
            range.end,
          );

          if (transactions.isEmpty) {
            return Column(
              children: [
                _buildPeriodSelector(),
                const Expanded(
                  child: Center(child: Text("No transactions in this period")),
                ),
              ],
            );
          }

          // Calculate Stats
          // Calculate Stats
          _totals = AnalyticsService.calculateTotals(transactions);
          _categorySpending = AnalyticsService.calculateCategorySpending(
            transactions,
          );
          _dailySpending = AnalyticsService.calculateDailySpending(
            transactions,
          );

          final openingBalance = AnalyticsService.calculateOpeningBalance(
            provider.transactions,
            range.start,
          );
          _balanceTrend = AnalyticsService.calculateBalanceTrend(
            transactions,
            openingBalance,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 16),

              // Stat Cards
              // Row 1: Income/Expense
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Income',
                      value: '₹${_totals['income']!.toStringAsFixed(0)}',
                      icon: Icons.arrow_downward,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      title: 'Expense',
                      value: '₹${_totals['expense']!.toStringAsFixed(0)}',
                      icon: Icons.arrow_upward,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: Balance/Avg
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Balance',
                      value: '₹${_totals['balance']!.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      title: 'Avg Daily',
                      value:
                          '₹${(_totals['expense']! / (range.duration.inDays + 1)).toStringAsFixed(0)}',
                      icon: Icons.show_chart,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Charts
              _buildSectionTitle("Spending by Category"),
              SpendingPieChart(data: _categorySpending),

              const SizedBox(height: 24),
              _buildSectionTitle("Daily Spending Trend"),
              DailyTrendBarChart(dailyData: _dailySpending),

              const SizedBox(height: 24),
              _buildSectionTitle("Balance Trend"),
              BalanceLineChart(points: _balanceTrend),

              const SizedBox(height: 24),
              _buildSectionTitle("Category Breakdown"),
              _buildCategoryList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _periodChip("This Week", TimePeriod.thisWeek),
          _periodChip("This Month", TimePeriod.thisMonth),
          _periodChip("Last Month", TimePeriod.lastMonth),
          _periodChip("Custom", TimePeriod.custom),
        ],
      ),
    );
  }

  Widget _periodChip(String label, TimePeriod period) {
    final isSelected = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) async {
          if (period == TimePeriod.custom) {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedPeriod = period;
                _customRange = picked;
              });
            }
          } else {
            setState(() {
              _selectedPeriod = period;
            });
          }
        },
      ),
    );
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.thisWeek:
        // Find Monday
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(monday.year, monday.month, monday.day),
          end: now,
        );
      case TimePeriod.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case TimePeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0); // Last day of prev month
        return DateTimeRange(start: start, end: end);
      case TimePeriod.custom:
        return _customRange ?? DateTimeRange(start: now, end: now);
    }
  }

  Widget _buildCategoryList() {
    final sorted = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _totals['expense'] ?? 1;

    return Column(
      children: sorted.map((e) {
        final pct = (e.value / total);
        return ListTile(
          title: Text(e.key),
          subtitle: LinearProgressIndicator(value: pct),
          trailing: Text(
            '₹${e.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)',
          ),
          onTap: () {
            // Show transactions for this category
            _showCategoryTransactions(e.key);
          },
        );
      }).toList(),
    );
  }

  void _showCategoryTransactions(String category) {
    final range = _getDateRange();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text('$category Transactions')),
            body: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final txs = AnalyticsService.filterTransactions(
                  provider.transactions,
                  range.start,
                  range.end,
                ).where((t) => t.category == category).toList();

                return ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final t = txs[index];
                    return ListTile(
                      title: Text(t.description),
                      subtitle: Text(DateFormat('MMM d').format(t.date)),
                      trailing: Text('₹${t.amount.toStringAsFixed(2)}'),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export to CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export Report as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPDF();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportCSV() async {
    final range = _getDateRange();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = AnalyticsService.filterTransactions(
      provider.transactions,
      range.start,
      range.end,
    );

    List<List<dynamic>> rows = [];
    rows.add([
      "Date",
      "Description",
      "Category",
      "Type",
      "Amount",
      "Bank Account",
    ]);
    for (var t in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(t.date),
        t.description,
        t.category,
        t.type.name,
        t.amount,
        t.bankAccountId ?? "Cash/None",
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
    await file.writeAsString(csv);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Transaction Report (CSV)');
  }

  Future<void> _exportPDF() async {
    final range = _getDateRange();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = AnalyticsService.filterTransactions(
      provider.transactions,
      range.start,
      range.end,
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text("Spending Report")),
            pw.Paragraph(
              text:
                  "Period: ${DateFormat('yyyy-MM-dd').format(range.start)} to ${DateFormat('yyyy-MM-dd').format(range.end)}",
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Date', 'Description', 'Category', 'Amount'],
                ...transactions.map(
                  (t) => [
                    DateFormat('MM/dd').format(t.date),
                    t.description,
                    t.category,
                    t.amount.toStringAsFixed(2),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Spending Report (PDF)');
  }
}
