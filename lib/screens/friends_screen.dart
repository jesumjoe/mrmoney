import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mrmoney/providers/friend_provider.dart';
import 'package:mrmoney/screens/friend_detail_screen.dart';
import 'package:mrmoney/theme/neo_style.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold provided by HomeScreen
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        final balances = provider.friendBalances;

        if (balances.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: NeoColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.supervised_user_circle_rounded,
                    size: 48,
                    color: NeoColors.text.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No friends added yet",
                  style: NeoStyle.bold(
                    color: NeoColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add a 'Lending' transaction to start.",
                  style: NeoStyle.regular(
                    color: NeoColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final friends = balances.keys.toList();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            100,
          ), // Reduced top padding
          itemCount: friends.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: NeoColors.border,
            indent: 72,
            endIndent: 0,
          ),
          itemBuilder: (context, index) {
            final friend = friends[index];
            final balance = balances[friend]!;
            final isOweMe = balance > 0;
            final isSettled = balance == 0;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FriendDetailScreen(friendName: friend),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: NeoColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: NeoColors.border),
                      ),
                      child: Center(
                        child: Text(
                          friend[0].toUpperCase(),
                          style: NeoStyle.bold(
                            fontSize: 20,
                            color: NeoColors.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(friend, style: NeoStyle.bold(fontSize: 18)),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isSettled
                              ? "Settled"
                              : "₹${balance.abs().toStringAsFixed(0)}",
                          style: NeoStyle.bold(
                            color: isSettled
                                ? NeoColors.textSecondary
                                : (isOweMe
                                      ? NeoColors.success
                                      : NeoColors.error),
                            fontSize: 16,
                          ),
                        ),
                        if (!isSettled)
                          Text(
                            isOweMe ? "owes you" : "you owe",
                            style: NeoStyle.regular(
                              color: NeoColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: NeoColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
