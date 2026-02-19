import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
import 'package:mrmoney/providers/friend_provider.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/models/friend_loan.dart';
import 'package:mrmoney/theme/neo_style.dart';

enum TransactionEditMode { expense, income, lending }

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  // Lending specific
  final _newFriendController = TextEditingController();

  late DateTime _selectedDate;
  TransactionEditMode _selectedMode = TransactionEditMode.expense;
  String? _selectedAccountId;

  // Lending State
  FriendLoan? _existingLoan;
  String? _selectedFriend;
  bool _isNewFriend = false;
  bool _iPaid =
      true; // true = I paid (they owe me), false = They paid (I owe them)

  final List<String> _defaultCategories = [
    'Food',
    'Transport',
    'Bills',
    'Entertainment',
    'Shopping',
    'Health',
    'Investment',
    'Salary',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _categoryController = TextEditingController(
      text: widget.transaction.category,
    );
    _selectedDate = widget.transaction.date;
    _selectedAccountId = widget.transaction.bankAccountId;

    // Determine initial mode
    if (widget.transaction.category == 'Lending') {
      _selectedMode = TransactionEditMode.lending;
      // Loan loading happens in didChangeDependencies
    } else if (widget.transaction.type == TransactionType.credit) {
      _selectedMode = TransactionEditMode.income;
    } else {
      _selectedMode = TransactionEditMode.expense;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedMode == TransactionEditMode.lending && _existingLoan == null) {
      // Try to find the associated loan
      final friendProvider = Provider.of<FriendProvider>(
        context,
        listen: false,
      );
      try {
        // Note: Accessing .loans directly might be empty if not loaded, but typically it is.
        // We can use a safer approach if needed, but for now assuming provider is loaded.
        _existingLoan = friendProvider.loans.firstWhere(
          (l) => l.transactionId == widget.transaction.id,
          orElse: () =>
              throw Exception("Loan not found"), // Handled by try/catch
        );

        if (_existingLoan != null) {
          _selectedFriend = _existingLoan!.friendName;
          _iPaid = _existingLoan!.type == FriendLoanType.owed;
        }
      } catch (e) {
        // No loan found, maybe manual category set to Lending?
        // We start "fresh" for lending fields
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _newFriendController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final accountProvider = Provider.of<BankAccountProvider>(
        context,
        listen: false,
      );
      final friendProvider = Provider.of<FriendProvider>(
        context,
        listen: false,
      );

      // 1. Revert Old Balance Effect
      if (widget.transaction.bankAccountId != null) {
        bool wasCredit = widget.transaction.type == TransactionType.credit;
        accountProvider.updateBalance(
          widget.transaction.bankAccountId!,
          widget.transaction.amount,
          !wasCredit, // Revert
        );
      }

      // 2. Handle Friend Loan Updates
      if (_selectedMode == TransactionEditMode.lending) {
        final friends = friendProvider.friendBalances.keys.toList();
        final isAddingNew = _isNewFriend || friends.isEmpty;

        // Validate Friend
        String friendName = '';
        if (isAddingNew) {
          if (_newFriendController.text.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Enter friend name')));
            return;
          }
          friendName = _newFriendController.text;
        } else {
          if (_selectedFriend == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Select a friend')));
            return;
          }
          friendName = _selectedFriend!;
        }

        if (_existingLoan != null) {
          // Update existing loan
          _existingLoan!.amount = amount;
          _existingLoan!.friendName = friendName;
          _existingLoan!.type = _iPaid
              ? FriendLoanType.owed
              : FriendLoanType.owe;
          _existingLoan!.description = _descriptionController.text;
          _existingLoan!.date = _selectedDate;
          await _existingLoan!.save();
        } else {
          // Create new loan linked to this transaction
          final newLoan = FriendLoan(
            id: const Uuid().v4(),
            friendName: friendName,
            amount: amount,
            type: _iPaid ? FriendLoanType.owed : FriendLoanType.owe,
            description: _descriptionController.text,
            date: _selectedDate,
            transactionId: widget.transaction.id,
          );
          await friendProvider.addLoan(newLoan);
        }
      } else {
        // Not lending
        // If we switched FROM lending, delete the old loan
        if (_existingLoan != null) {
          await friendProvider.deleteLoan(_existingLoan!);
        }
      }

      // 3. Update Transaction Fields
      widget.transaction.amount = amount;
      widget.transaction.description = _descriptionController.text;
      widget.transaction.date = _selectedDate;

      if (_selectedMode == TransactionEditMode.lending) {
        widget.transaction.category = 'Lending';
        widget.transaction.type = _iPaid
            ? TransactionType.debit
            : TransactionType.credit;
        // If "They Paid", usually no bank impact, so maybe null?
        // But AddTransactionScreen logic says:
        // if _iPaid is true -> selectedAccount (Debit)
        // if _iPaid is false -> null account (No bank impact)
        widget.transaction.bankAccountId = _iPaid ? _selectedAccountId : null;
      } else {
        widget.transaction.category = _categoryController.text.isEmpty
            ? 'Other'
            : _categoryController.text;
        widget.transaction.type = _selectedMode == TransactionEditMode.income
            ? TransactionType.credit
            : TransactionType.debit;
        widget.transaction.bankAccountId = _selectedAccountId;
      }

      // 4. Apply New Balance Effect
      if (widget.transaction.bankAccountId != null) {
        bool isCredit = widget.transaction.type == TransactionType.credit;
        accountProvider.updateBalance(
          widget.transaction.bankAccountId!,
          widget.transaction.amount,
          isCredit,
        );
      }

      // 5. Save & Refresh
      await widget.transaction.save();
      provider.loadTransactions(); // Refresh list

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLending = _selectedMode == TransactionEditMode.lending;
    bool isSMS = widget.transaction.isFromSMS;

    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount Input
            TextFormField(
              controller: _amountController,
              decoration: NeoStyle.inputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: NeoStyle.bold(fontSize: 24),
              validator: (val) =>
                  (val == null || val.isEmpty) ? 'Enter amount' : null,
            ),
            const SizedBox(height: 16),

            // Mode Selection
            // Mode Selection
            Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    mode: TransactionEditMode.expense,
                    label: 'Expense',
                    icon: Icons.arrow_downward,
                    color: NeoColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeButton(
                    mode: TransactionEditMode.income,
                    label: 'Income',
                    icon: Icons.arrow_upward,
                    color: NeoColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeButton(
                    mode: TransactionEditMode.lending,
                    label: 'Lending',
                    icon: Icons.people,
                    color: NeoColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // LENDING UI
            if (isLending) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: NeoStyle.box(color: NeoColors.surface),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Friend Details", style: NeoStyle.bold(fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("I Paid (They owe)"),
                            value: true,
                            groupValue: _iPaid,
                            onChanged: (val) => setState(() => _iPaid = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("They Paid (I owe)"),
                            value: false,
                            groupValue: _iPaid,
                            onChanged: (val) => setState(() => _iPaid = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Consumer<FriendProvider>(
                      builder: (context, provider, child) {
                        final friends = provider.friendBalances.keys.toList();
                        return Column(
                          children: [
                            // Dropdown for existing friends
                            if (friends.isNotEmpty && !_isNewFriend)
                              DropdownButtonFormField<String>(
                                decoration: NeoStyle.inputDecoration(
                                  labelText: 'Select Friend',
                                ),
                                value: (friends.contains(_selectedFriend))
                                    ? _selectedFriend
                                    : null,
                                items: friends
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedFriend = val),
                              ),

                            // Add New Toggle
                            if (friends.isNotEmpty && !_isNewFriend)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      setState(() => _isNewFriend = true),
                                  child: const Text(" + Add New User"),
                                ),
                              ),

                            // New Friend Input
                            if (friends.isEmpty || _isNewFriend)
                              TextFormField(
                                controller: _newFriendController,
                                decoration: NeoStyle.inputDecoration(
                                  labelText: 'New Friend Name',
                                  suffixIcon: friends.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () => setState(
                                            () => _isNewFriend = false,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // CATEGORY UI (Only for Expense/Income)
              DropdownButtonFormField<String>(
                decoration: NeoStyle.inputDecoration(labelText: 'Category'),
                value: _defaultCategories.contains(_categoryController.text)
                    ? _categoryController.text
                    : 'Other',
                items: _defaultCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _categoryController.text = val ?? ''),
              ),
              const SizedBox(height: 16),
            ],

            // Date
            NeoCard(
              child: ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(height: 16),

            // Bank Account
            // If Lending & I Paid -> Need Bank Account
            // If Lending & They Paid -> No Bank Account (usually)
            // If Expense/Income -> Need Bank Account
            if (!isLending || (isLending && _iPaid))
              Consumer<BankAccountProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<String>(
                    decoration: NeoStyle.inputDecoration(
                      labelText: 'Account',
                      // Add Lock Icon if SMS
                      suffixIcon: isSMS
                          ? const Tooltip(
                              message: "Detected from SMS",
                              child: Icon(Icons.lock, size: 18),
                            )
                          : null,
                    ),
                    value: _selectedAccountId,
                    items: provider.accounts.map((BankAccount account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(
                          account.type == 'bank'
                              ? '${account.bankName} (...${account.accountNumber.length > 3 ? account.accountNumber.substring(account.accountNumber.length - 3) : account.accountNumber})'
                              : account.bankName,
                        ),
                      );
                    }).toList(),
                    onChanged: isSMS
                        ? null // Disable if SMS
                        : (val) => setState(() => _selectedAccountId = val),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: NeoStyle.inputDecoration(
                labelText: 'Description / Notes',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save
            NeoButton(text: 'Save Changes', onPressed: _saveTransaction),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required TransactionEditMode mode,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          // Reset category text if moving away from Lending
          if (_selectedMode != TransactionEditMode.lending &&
              _categoryController.text == 'Lending') {
            _categoryController.text = 'Other';
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : NeoColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : NeoColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: isSelected
                    ? NeoStyle.bold(color: color, fontSize: 14)
                    : NeoStyle.regular(
                        color: NeoColors.textSecondary,
                        fontSize: 14,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
