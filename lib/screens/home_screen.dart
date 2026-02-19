import 'package:flutter/material.dart';
import 'package:mrmoney/widgets/total_balance_card.dart';
import 'package:mrmoney/widgets/recent_transactions_list.dart';
import 'package:mrmoney/screens/accounts_screen.dart';
import 'package:mrmoney/screens/add_transaction_screen.dart';
import 'package:mrmoney/screens/transactions_screen.dart';
import 'package:mrmoney/screens/stats_screen.dart';
import 'package:mrmoney/widgets/custom_bottom_nav.dart';

import 'package:mrmoney/screens/friends_screen.dart';
import 'package:mrmoney/screens/settings_screen.dart';
import 'package:mrmoney/widgets/budget/home_budget_section.dart';
import 'package:mrmoney/theme/neo_style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),
    const TransactionsScreen(),
    const StatsScreen(), // New Stats Screen
    const FriendsScreen(),
    const AccountsScreen(), // Or Profile/Settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String get _currentTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Mr. Money';
      case 1:
        return 'Transactions';
      case 2:
        return 'Statistics';
      case 3:
        return 'Friends';
      case 4:
        return 'Accounts';
      default:
        return 'Mr. Money';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_currentTitle, style: NeoStyle.bold(fontSize: 24)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: NeoColors.border),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: Colors.black,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _widgetOptions),

          // Bottom Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              showChartMiddleButton: _selectedIndex >= 2,
            ),
          ),

          // FAB - Only show on Home and Transactions, maybe Friends?
          // Definitely hide on Accounts to avoid conflict if we add a FAB there (or just one main FAB)
          // FAB - Only show on Home and Transactions (0 and 1)
          if (_selectedIndex < 2)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: () {
                    // Logic to open Add Transaction or Add Friend based on screen?
                    // For now, default to Add Transaction
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTransactionScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.black,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        24,
        16,
        24,
        120,
      ), // Bottom padding for nav bar
      children: [
        const TotalBalanceCard(),
        const SizedBox(height: 24),
        const HomeBudgetSection(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: NeoStyle.bold(fontSize: 18)),
            TextButton(
              onPressed: () {
                // Navigate to transactions tab (handled by parent usually, but here we can just let user tap the tab)
                // Or we can find ancestor State and set index.
                // For now simplicity:
              },
              child: Text(
                'See All',
                style: NeoStyle.regular(
                  fontSize: 14,
                  color: NeoColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const RecentTransactionsList(),
      ],
    );
  }
}
