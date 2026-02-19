import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';
import 'package:mrmoney/screens/edit_transaction_screen.dart';

class CalendarTransactionsView extends StatefulWidget {
  final DateTime currentMonth;
  final List<Transaction> transactions;

  const CalendarTransactionsView({
    super.key,
    required this.currentMonth,
    required this.transactions,
  });

  @override
  State<CalendarTransactionsView> createState() =>
      _CalendarTransactionsViewState();
}

class _CalendarTransactionsViewState extends State<CalendarTransactionsView> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      widget.currentMonth.year,
      widget.currentMonth.month,
    );
    final firstDayOfMonth = DateTime(
      widget.currentMonth.year,
      widget.currentMonth.month,
      1,
    );

    // DateTime.weekday returns 1=Mon, 7=Sun.
    // If we want Sun as first column (index 0), then for Mon(1), offset is 1.
    // For Sun(7), offset is 0.
    final offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    return Column(
      children: [
        // Weekday Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        d,
                        style: NeoStyle.bold(
                          color: NeoColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + offset,
          itemBuilder: (context, index) {
            if (index < offset) {
              return const SizedBox();
            }
            final day = index - offset + 1;
            final date = DateTime(
              widget.currentMonth.year,
              widget.currentMonth.month,
              day,
            );

            // Check for transactions
            final dayTransactions = widget.transactions.where((t) {
              return t.date.year == date.year &&
                  t.date.month == date.month &&
                  t.date.day == date.day;
            }).toList();

            bool hasIncome = dayTransactions.any(
              (t) => t.type == TransactionType.credit,
            );
            bool hasExpense = dayTransactions.any(
              (t) => t.type == TransactionType.debit,
            );

            final isSelected =
                _selectedDate != null &&
                _selectedDate!.year == date.year &&
                _selectedDate!.month == date.month &&
                _selectedDate!.day == date.day;

            final isToday =
                DateTime.now().year == date.year &&
                DateTime.now().month == date.month &&
                DateTime.now().day == date.day;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? NeoColors.primary
                      : (isToday
                            ? NeoColors.primary.withOpacity(0.1)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: NeoColors.primary, width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected ? Colors.white : NeoColors.text,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (hasIncome || hasExpense)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasIncome)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: const BoxDecoration(
                                  color: NeoColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasExpense)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: const BoxDecoration(
                                  color: NeoColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const Divider(height: 32, color: NeoColors.border),

        // Selected Date Transactions
        if (_selectedDate != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(_selectedDate!),
                  style: NeoStyle.bold(fontSize: 16),
                ),
                if (widget.transactions
                    .where((t) => isSameDay(t.date, _selectedDate!))
                    .isEmpty) ...[
                  const Spacer(),
                  Text(
                    'No transactions',
                    style: NeoStyle.regular(
                      color: NeoColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildDayList(),
        ] else
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Select a date to view details',
              style: NeoStyle.regular(color: NeoColors.textSecondary),
            ),
          ),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDayList() {
    final dayTransactions = widget.transactions.where((t) {
      return isSameDay(t.date, _selectedDate!);
    }).toList();

    return Column(
      children: dayTransactions.map((t) {
        final isCredit = t.type == TransactionType.credit;
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditTransactionScreen(transaction: t),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.category,
                    style: NeoStyle.regular(color: NeoColors.text),
                  ),
                ),
                Text(
                  '${isCredit ? '+' : '-'} ₹${NumberFormat('#,##0.00').format(t.amount)}',
                  style: TextStyle(
                    color: isCredit ? NeoColors.success : NeoColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
