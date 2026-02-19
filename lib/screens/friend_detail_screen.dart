import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mrmoney/providers/friend_provider.dart';
import 'package:mrmoney/models/friend_loan.dart';

class FriendDetailScreen extends StatelessWidget {
  final String friendName;
  const FriendDetailScreen({super.key, required this.friendName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final provider = Provider.of<FriendProvider>(
                context,
                listen: false,
              );
              final balance = provider.friendBalances[friendName] ?? 0;
              final status = balance > 0 ? "You owe me" : "I owe you";
              Share.share(
                "Hey $friendName, here is our summary: $status ₹${balance.abs().toStringAsFixed(2)} on Mr. Money.",
              );
            },
          ),
        ],
      ),
      body: Consumer<FriendProvider>(
        builder: (context, provider, child) {
          final loans = provider.getLoansForFriend(friendName);
          final balance = provider.friendBalances[friendName] ?? 0;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.primaryContainer,
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      "Net Balance",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${balance.abs().toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: balance == 0
                            ? Colors.grey
                            : (balance > 0 ? Colors.green : Colors.red),
                      ),
                    ),
                    Text(
                      balance == 0
                          ? "Settled"
                          : (balance > 0 ? "They owe you" : "You owe them"),
                      style: TextStyle(
                        color: balance == 0
                            ? Colors.grey
                            : (balance > 0 ? Colors.green : Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (balance != 0)
                      FilledButton(
                        onPressed: () => _showSettleDialog(context, balance),
                        child: const Text("Settle Up"),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final isOwe = loan.type == FriendLoanType.owe; // I owe them

                    if (loan.isSettled && balance != 0) {
                      // Maybe hide settled if we are looking at active ones?
                      // Or show them dimmed.
                    }

                    return ListTile(
                      title: Text(
                        loan.description.isNotEmpty ? loan.description : "Loan",
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy').format(loan.date),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${loan.amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: loan.isSettled
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: loan.isSettled
                                  ? Colors.grey
                                  : (isOwe ? Colors.red : Colors.green),
                            ),
                          ),
                          Text(
                            isOwe ? "You borrowed" : "You lent",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSettleDialog(BuildContext context, double currentBalance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settle Up?"),
        content: Text(
          "Mark all transactions with $friendName as settled? Net amount: ₹${currentBalance.abs().toStringAsFixed(2)}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final provider = Provider.of<FriendProvider>(
                context,
                listen: false,
              );
              final loans = provider.getLoansForFriend(friendName);
              for (var loan in loans) {
                if (!loan.isSettled) provider.settleLoan(loan);
              }
              Navigator.pop(context);
              Navigator.pop(context); // Go back to list
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
