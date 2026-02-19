import 'package:flutter/material.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/theme/neo_style.dart';
import 'package:intl/intl.dart';
import 'package:mrmoney/screens/edit_transaction_screen.dart';

class TransactionSearchDelegate extends SearchDelegate {
  final List<Transaction> transactions;

  TransactionSearchDelegate(this.transactions);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: NeoColors.surface,
        iconTheme: const IconThemeData(color: NeoColors.text),
        titleTextStyle: NeoStyle.bold(fontSize: 18, color: NeoColors.text),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: NeoColors.textSecondary),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: NeoColors.primary,
        selectionColor: NeoColors.primary,
        selectionHandleColor: NeoColors.primary,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: NeoColors.textSecondary),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: NeoColors.text),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = transactions.where((t) {
      final q = query.toLowerCase();
      return t.category.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.amount.toString().contains(q);
    }).toList();

    // Sort by date descending
    results.sort((a, b) => b.date.compareTo(a.date));

    if (results.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: NeoColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: NeoStyle.bold(fontSize: 18, color: NeoColors.text),
            ),
          ],
        ),
      );
    }

    return Container(
      color: NeoColors.background,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: NeoColors.border,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final transaction = results[index];
          final isCredit = transaction.type == TransactionType.credit;
          return InkWell(
            onTap: () {
              // Close search and view/edit transaction
              // Alternatively, navigate directly and keep search open?
              // Typically close or push. Let's push.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditTransactionScreen(transaction: transaction),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NeoColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isCredit
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isCredit ? NeoColors.success : NeoColors.text,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.category,
                          style: NeoStyle.bold(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.description.isNotEmpty
                              ? transaction.description
                              : DateFormat(
                                  'MMM d, yyyy',
                                ).format(transaction.date),
                          style: NeoStyle.regular(
                            fontSize: 13,
                            color: NeoColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? '+' : '-'} ₹${NumberFormat('#,##0.00').format(transaction.amount)}',
                        style: NeoStyle.bold(
                          fontSize: 16,
                          color: isCredit ? NeoColors.success : NeoColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM d',
                        ).format(transaction.date), // Show date in result
                        style: NeoStyle.regular(
                          fontSize: 12,
                          color: NeoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
