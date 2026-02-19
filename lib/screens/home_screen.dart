import 'package:flutter/material.dart';
import 'package:mrmoney/widgets/total_balance_card.dart';
import 'package:mrmoney/widgets/recent_transactions_list.dart';
import 'package:mrmoney/screens/accounts_screen.dart';
import 'package:mrmoney/screens/add_transaction_screen.dart';
import 'package:mrmoney/screens/transactions_screen.dart';

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
    const FriendsScreen(),
    const AccountsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Allow body to go behind app bar area if needed
      appBar: AppBar(
        title: const Text('Mr. Money'),
        centerTitle:
            false, // Left align for a change or keep center? Let's go Left for "Header" feel
        backgroundColor: Colors.transparent,
        titleTextStyle: NeoStyle.bold(fontSize: 24, color: NeoColors.text),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: NeoStyle.circle(color: Colors.white),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              color: NeoColors.text,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Pattern or Gradient (Optional, keeping simple for now)

          // Main Content
          Padding(
            padding: const EdgeInsets.only(
              top: kToolbarHeight + 16,
              bottom: 100,
            ), // Space for AppBar and BottomNav
            child: _widgetOptions.elementAt(_selectedIndex),
          ),

          // Floating Bottom Navigation
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: NeoStyle.box(
                color: Colors.white, // White pill
                radius: 32, // Fully rounded pill
                borderColor: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, Icons.home_rounded, Icons.home_rounded),
                  _buildNavItem(
                    1,
                    Icons.history_rounded,
                    Icons.history_rounded,
                  ),

                  // Middle space for FAB (if we want to dock it, but floating is better)
                  const SizedBox(width: 48),

                  _buildNavItem(2, Icons.people_rounded, Icons.people_rounded),
                  _buildNavItem(
                    3,
                    Icons.account_balance_wallet_rounded,
                    Icons.account_balance_wallet_rounded,
                  ),
                ],
              ),
            ),
          ),

          // Floating Action Button (Centered above the nav)
          Positioned(
            bottom: 48, // Slightly overlapping or just above
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 64,
                width: 64,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTransactionScreen(),
                      ),
                    );
                  },
                  backgroundColor: NeoColors.secondary, // Yellow
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    // Mapping index to correct widget index since we have a gap
    // indices: 0, 1, (gap), 2, 3 -> implies widget indices 0, 1, 2, 3 (wait, 4 screens? Accounts, Trans, Analytics, Friends)
    // Original had 5 items. Let's stick to 4 main tabs + FAB for Add.
    // 0: Home, 1: Transactions, 2: Friends, 3: Accounts. (Analytics can be in Home or separate)
    // Let's re-map:
    // 0 -> Home
    // 1 -> Transactions
    // 2 -> Friends
    // 3 -> Accounts

    // We need to update _widgetOptions and _selectedIndex logic if we change item count.
    // Original had 5: Home, Trans, Analytics, Friends, Accounts.
    // Let's keep 5 but maybe Analytics is top right or hidden? Or just put Analytics as 2nd item.
    // Let's try to fit 4 items for cleaner look + FAB.
    // 0: Home, 1: Analytics (or Stats), 2: Friends (or Split), 3: Accounts (or Profile/Settings)
    // Access transactions via FAB or "See All" on Home.

    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? NeoColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? NeoColors.primaryDark : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TotalBalanceCard(),
          const SizedBox(height: 16),
          const HomeBudgetSection(),
          const SizedBox(height: 24),
          Text(
            'Recent Transactions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const RecentTransactionsList(),
        ],
      ),
    );
  }
}
