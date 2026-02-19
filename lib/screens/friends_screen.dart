import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mrmoney/providers/friend_provider.dart';
import 'package:mrmoney/screens/friend_detail_screen.dart'; // Will create

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FriendProvider>(
        builder: (context, provider, child) {
          final balances = provider.friendBalances;

          if (balances.isEmpty) {
            return const Center(child: Text("No friends added yet."));
          }

          final friends = balances.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final balance = balances[friend]!;
              final isOweMe = balance > 0;
              final isSettled = balance == 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSettled
                        ? Colors.grey
                        : (isOweMe
                              ? Colors.green.shade100
                              : Colors.red.shade100),
                    child: Text(friend[0].toUpperCase()),
                  ),
                  title: Text(friend),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isSettled
                            ? "Settled"
                            : "₹${balance.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          color: isSettled
                              ? Colors.grey
                              : (isOweMe ? Colors.green : Colors.red),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!isSettled)
                        Text(
                          isOweMe ? "owes you" : "you owe",
                          style: TextStyle(
                            color: isSettled
                                ? Colors.grey
                                : (isOweMe ? Colors.green : Colors.red),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FriendDetailScreen(friendName: friend),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Shortcut to add friend transaction?
          // Usually we add transaction first.
          // Maybe just show a snackbar saying "Add transaction with Lending category"
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('To add a friend, create a "Lending" transaction.'),
            ),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
