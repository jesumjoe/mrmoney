import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';

import 'package:mrmoney/delegates/transaction_search_delegate.dart';
import 'package:mrmoney/widgets/transaction_filter_modal.dart';
import 'package:mrmoney/widgets/transactions/daily_transactions_list.dart';
import 'package:mrmoney/widgets/transactions/monthly_transactions_list.dart';
import 'package:mrmoney/widgets/transactions/calendar_view.dart';
import 'package:mrmoney/widgets/monthly_summary_card.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _activeTab = 'Daily';

  // Filter & Sort State
  TransactionType? _filterType;
  SortOrder _sortOrder = SortOrder.newestFirst;

  void _changeMonth(int i) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + i,
        _selectedMonth.day,
      );
    });
  }

  void _showCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
        _activeTab = 'Daily'; // Switch to Daily view on date select
      });
    }
  }

  void _showSearch(List<Transaction> transactions) {
    showSearch(
      context: context,
      delegate: TransactionSearchDelegate(transactions),
    );
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFilterModal(
        currentTypeFilter: _filterType,
        currentSortOrder: _sortOrder,
        onApply: (type, sort) {
          setState(() {
            _filterType = type;
            _sortOrder = sort;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final allTransactions = provider.transactions;
        final processedTransactions = provider.processTransactions(
          transactions: allTransactions,
          filterType: _filterType,
          sortOrder: _sortOrder,
        );

        // Filter for specific month (for Daily/Calendar)
        final monthTransactions = processedTransactions.where((t) {
          return t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month;
        }).toList();

        // Calculate Monthly Totals (for Header)
        final totals = provider.calculateMonthlyTotals(monthTransactions);

        return Column(
          children: [
            // Month Selector & Header (Hide if Monthly View)
            if (_activeTab != 'Monthly' &&
                _activeTab != 'Total' &&
                _activeTab != 'Note')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Month Navigation Group
                    Expanded(
                      // Allow this to take available space but shrink if needed
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Flexible(
                            // Allow text to shrink if really needed
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: GestureDetector(
                                onTap: _showCalendar,
                                child: Text(
                                  DateFormat('MMM yyyy').format(_selectedMonth),
                                  style: NeoStyle.bold(fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ),

                    // Search & Filter Group
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8), // Gap between groups
                        IconButton(
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.search,
                            color: NeoColors.textSecondary,
                          ),
                          onPressed: () => _showSearch(allTransactions),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.tune,
                            color: NeoColors.textSecondary,
                          ),
                          onPressed: _showFilter,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Tab Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTab('Daily'),
                  _buildTab('Calendar'),
                  _buildTab('Monthly'),
                  _buildTab('Total'),
                  _buildTab('Note'),
                ],
              ),
            ),
            const Divider(height: 1, color: NeoColors.border),

            // Monthly Summary (Only show in Daily/Calendar view)
            if (_activeTab != 'Monthly' &&
                _activeTab != 'Total' &&
                _activeTab != 'Note') ...[
              MonthlySummaryCard(
                income: totals['income']!,
                expense: totals['expense']!,
                total: totals['total']!,
              ),
              const Divider(height: 1, color: NeoColors.border),
            ],

            // Content
            Expanded(
              child: Builder(
                builder: (_) {
                  switch (_activeTab) {
                    case 'Daily':
                      return DailyTransactionsList(
                        transactions: monthTransactions,
                      );
                    case 'Calendar':
                      return SingleChildScrollView(
                        child: CalendarTransactionsView(
                          currentMonth: _selectedMonth,
                          transactions: monthTransactions,
                        ),
                      );
                    case 'Monthly':
                      return MonthlyTransactionsList(
                        transactions:
                            processedTransactions, // Pass all valid transactions
                        onMonthSelected: (date) {
                          setState(() {
                            _selectedMonth = date;
                            _activeTab = 'Daily';
                          });
                        },
                      );
                    case 'Total':
                    case 'Note':
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.construction_rounded,
                              size: 64,
                              color: NeoColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$_activeTab View Coming Soon',
                              style: NeoStyle.bold(
                                color: NeoColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    default:
                      return const SizedBox();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(String text) {
    final bool isActive = _activeTab == text;
    return GestureDetector(
      onTap: () {
        if (text == 'Calendar' && _activeTab != 'Calendar') {
          setState(() => _activeTab = 'Calendar');
        } else if (text == 'Daily' && _activeTab != 'Daily') {
          setState(() => _activeTab = 'Daily');
        } else if (text == 'Monthly' && _activeTab != 'Monthly') {
          setState(() => _activeTab = 'Monthly');
        } else if (text == 'Total' || text == 'Note') {
          setState(() => _activeTab = text);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: NeoColors.error, width: 2),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? NeoColors.text : NeoColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
