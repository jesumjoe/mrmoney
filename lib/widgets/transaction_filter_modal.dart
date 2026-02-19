import 'package:flutter/material.dart';
import 'package:mrmoney/theme/neo_style.dart';
import 'package:mrmoney/models/transaction_type.dart';

import 'package:mrmoney/providers/transaction_provider.dart';

class TransactionFilterModal extends StatefulWidget {
  final TransactionType? currentTypeFilter;
  final SortOrder currentSortOrder;
  final Function(TransactionType?, SortOrder) onApply;

  const TransactionFilterModal({
    super.key,
    required this.currentTypeFilter,
    required this.currentSortOrder,
    required this.onApply,
  });

  @override
  State<TransactionFilterModal> createState() => _TransactionFilterModalState();
}

class _TransactionFilterModalState extends State<TransactionFilterModal> {
  late TransactionType? _selectedType;
  late SortOrder _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentTypeFilter;
    _selectedSort = widget.currentSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NeoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Filter Transactions', style: NeoStyle.bold(fontSize: 20)),
              const SizedBox(height: 24),

              // Type Filter
              Text('Transaction Type', style: NeoStyle.bold(fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFilterChip('All', null),
                  _buildFilterChip('Income', TransactionType.credit),
                  _buildFilterChip('Expense', TransactionType.debit),
                ],
              ),

              const SizedBox(height: 24),

              // Sort Order
              Text('Sort By', style: NeoStyle.bold(fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSortChip('Newest First', SortOrder.newestFirst),
                  _buildSortChip('Oldest First', SortOrder.oldestFirst),
                  _buildSortChip('Highest Amount', SortOrder.highestAmount),
                  _buildSortChip('Lowest Amount', SortOrder.lowestAmount),
                ],
              ),

              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // Reset
                        setState(() {
                          _selectedType = null;
                          _selectedSort = SortOrder.newestFirst;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: NeoStyle.bold(color: NeoColors.textSecondary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_selectedType, _selectedSort);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NeoColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: NeoStyle.bold(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionType? type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = type;
        });
      },
      selectedColor: NeoColors.primary,
      backgroundColor: NeoColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : NeoColors.text,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? NeoColors.primary : NeoColors.border,
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, SortOrder sort) {
    final isSelected = _selectedSort == sort;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSort = sort;
        });
      },
      selectedColor: NeoColors.primary,
      backgroundColor: NeoColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : NeoColors.text,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? NeoColors.primary : NeoColors.border,
        ),
      ),
    );
  }
}
