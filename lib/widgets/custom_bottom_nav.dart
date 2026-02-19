import 'package:flutter/material.dart';
import 'package:mrmoney/theme/neo_style.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool showChartMiddleButton;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.showChartMiddleButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: NeoColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(0, Icons.home_rounded, Icons.home_rounded),
          _buildNavItem(1, Icons.history_rounded, Icons.history_rounded),

          // Stats Icon (Middle) - OR Placeholder
          if (showChartMiddleButton)
            _buildNavItem(
              2,
              Icons.pie_chart_outline_rounded,
              Icons.pie_chart_rounded,
            )
          else
            const SizedBox(width: 48, height: 48), // Placeholder for FAB

          _buildNavItem(3, Icons.people_rounded, Icons.people_rounded),
          _buildNavItem(
            4,
            Icons.account_balance_wallet_rounded,
            Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }
}
