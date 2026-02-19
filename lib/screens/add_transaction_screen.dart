import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
import 'package:mrmoney/providers/friend_provider.dart';
import 'package:mrmoney/providers/budget_provider.dart';
import 'package:mrmoney/repositories/category_repository.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/models/friend_loan.dart';
import 'package:mrmoney/models/category.dart';
import 'package:mrmoney/services/notification_service.dart';
import 'package:mrmoney/services/budget_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  // Friend Lending controllers
  final _newFriendController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.debit;
  String? _selectedAccountId;

  // Lending specific
  String? _selectedFriend;
  bool _isNewFriend = false;
  // true = I paid for them (Debit from my account, They owe me)
  // false = They paid for me (I owe them, No impact on my bank unless settling)
  bool _iPaid = true;

  // Hardcoded categories now handled differently, but kept for dropdown list source if needed
  // Ideally we should pull from repo
  final List<String> _defaultCategories = [
    'Food',
    'Transport',
    'Bills',
    'Entertainment',
    'Shopping',
    'Health',
    'Investment',
    'Salary',
    'Lending',
    'Other',
  ];

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

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final transactionId = const Uuid().v4();

      Transaction? transaction;
      FriendLoan? friendLoan;

      // Logic for Lending
      if (_categoryController.text == 'Lending') {
        if (_isNewFriend && _newFriendController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter friend name')),
          );
          return;
        }
        if (!_isNewFriend && _selectedFriend == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a friend')),
          );
          return;
        }

        final friendName = _isNewFriend
            ? _newFriendController.text
            : _selectedFriend!;

        if (_iPaid && _selectedAccountId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a bank account since you paid'),
            ),
          );
          return;
        }

        transaction = Transaction(
          id: transactionId,
          amount: amount,
          type: _selectedType,
          category: 'Lending',
          description: _descriptionController.text.isEmpty
              ? 'Loan with $friendName'
              : _descriptionController.text,
          date: _selectedDate,
          bankAccountId: _iPaid ? _selectedAccountId : null,
        );

        friendLoan = FriendLoan(
          id: const Uuid().v4(),
          friendName: friendName,
          amount: amount,
          type: _iPaid ? FriendLoanType.owed : FriendLoanType.owe,
          description: _descriptionController.text,
          date: _selectedDate,
          transactionId: transactionId,
        );
      } else {
        // Normal Transaction
        if (_selectedAccountId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a bank account')),
          );
          return;
        }

        transaction = Transaction(
          id: transactionId,
          amount: amount,
          type: _selectedType,
          category: _categoryController.text.isEmpty
              ? 'Other'
              : _categoryController.text,
          description: _descriptionController.text,
          date: _selectedDate,
          bankAccountId: _selectedAccountId,
        );
      }

      // Check Budget Warning (Only for Expenses and not Lending for now, or maybe check Lending if I paid?)
      // Let's focus on essential categories
      if (_selectedType == TransactionType.debit &&
          _categoryController.text != 'Lending') {
        _checkBudgetAndFinalize(transaction, friendLoan);
      } else {
        _finalizeSave(transaction, friendLoan);
      }
    }
  }

  void _checkBudgetAndFinalize(
    Transaction transaction,
    FriendLoan? friendLoan,
  ) {
    final categoryName = transaction.category;
    final categoryRepo = Provider.of<CategoryRepository>(
      context,
      listen: false,
    );
    // budgetProvider removed
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final now = DateTime.now();

    // 1. Check Category Limits
    // Details: Notifications at 80% and 100%
    Category? category;
    try {
      category = categoryRepo.getAll().firstWhere(
        (c) => c.name == categoryName,
      );
    } catch (e) {
      // Category might not exist
    }

    if (category != null &&
        category.budgetLimit != null &&
        category.budgetLimit! > 0) {
      final catSpent = txProvider.transactions
          .where(
            (t) =>
                t.category == categoryName &&
                t.type == TransactionType.debit &&
                t.date.year == now.year &&
                t.date.month == now.month,
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      final newTotal = catSpent + transaction.amount;
      final limit = category.budgetLimit!;

      if (newTotal > limit) {
        NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: "Category Limit Exceeded",
          body:
              "You exceeded your $categoryName budget by ₹${(newTotal - limit).toStringAsFixed(0)}.",
        );
        _showBudgetDialog(
          context,
          "⚠️ Category Limit Exceeded",
          "This expense will exceed your $categoryName budget by ₹${(newTotal - limit).toStringAsFixed(0)}.\n\nLimit: ₹${limit.toStringAsFixed(0)}\nNew Total: ₹${newTotal.toStringAsFixed(0)}",
          () => _checkGlobalSavingsGoal(transaction, friendLoan),
        );
        return;
      } else if (newTotal > (limit * 0.8) && catSpent <= (limit * 0.8)) {
        NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: "Approaching Limit",
          body: "You have used over 80% of your $categoryName budget.",
        );
        _showBudgetDialog(
          context,
          "⚠️ Approaching Category Limit",
          "You have used over 80% of your $categoryName budget.\n\nLimit: ₹${limit.toStringAsFixed(0)}\nNew Total: ₹${newTotal.toStringAsFixed(0)}",
          () => _checkGlobalSavingsGoal(transaction, friendLoan),
        );
        return;
      }
    }

    _checkGlobalSavingsGoal(transaction, friendLoan);
  }

  void _checkGlobalSavingsGoal(
    Transaction transaction,
    FriendLoan? friendLoan,
  ) {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final now = DateTime.now();

    final goal = budgetProvider.savingsGoal;
    if (goal > 0) {
      // Calculate Current Month Balance (Income - Expense)
      final currentMonthTxs = txProvider.transactions
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();

      double income = 0;
      double expense = 0;
      for (var t in currentMonthTxs) {
        if (t.type == TransactionType.credit) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }

      final currentBalance = income - expense;
      final result = budgetProvider.checkGlobalStatus(
        currentBalance,
        transaction.amount,
      );

      if (result.status != BudgetStatus.safe) {
        final message = BudgetService.getBudgetWarningMessage(
          status: result.status,
          remainingAfterExpense: result.remainingSafeAmount,
          savingsGoal: goal,
        );
        _showBudgetDialog(
          context,
          result.status == BudgetStatus.exceeded
              ? "⚠️ Savings Goal Breach"
              : "⚠️ Approach Warning",
          message,
          () => _finalizeSave(transaction, friendLoan),
        );
        return;
      }
    }

    _finalizeSave(transaction, friendLoan);
  }

  void _showBudgetDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text("Proceed Anyway"),
          ),
        ],
      ),
    );
  }

  void _finalizeSave(Transaction transaction, FriendLoan? friendLoan) {
    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).addTransaction(transaction);
    if (friendLoan != null) {
      Provider.of<FriendProvider>(context, listen: false).addLoan(friendLoan);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLending = _categoryController.text == 'Lending';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount Input
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Type Selection
            if (!isLending)
              SegmentedButton<TransactionType>(
                segments: const <ButtonSegment<TransactionType>>[
                  ButtonSegment<TransactionType>(
                    value: TransactionType.debit,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.credit,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: <TransactionType>{_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
            if (!isLending) const SizedBox(height: 16),

            // Category Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              initialValue: _categoryController.text.isNotEmpty
                  ? _categoryController.text
                  : null,
              items: _defaultCategories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _categoryController.text = newValue ?? '';
                  if (_categoryController.text != 'Lending') {
                    _selectedFriend = null;
                    _isNewFriend = false;
                  }
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),

            // LENDING SECTION
            if (isLending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Friend Details",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("I paid"),
                            subtitle: const Text("(They owe me)"),
                            value: true,
                            groupValue: _iPaid,
                            onChanged: (val) => setState(() => _iPaid = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("They paid"),
                            subtitle: const Text("(I owe them)"),
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
                            if (friends.isNotEmpty && !_isNewFriend)
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Friend',
                                  border: OutlineInputBorder(),
                                ),
                                initialValue: _selectedFriend,
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
                            if (friends.isNotEmpty && !_isNewFriend)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      setState(() => _isNewFriend = true),
                                  child: const Text("Add New Friend"),
                                ),
                              ),

                            if (friends.isEmpty || _isNewFriend)
                              TextFormField(
                                controller: _newFriendController,
                                decoration: InputDecoration(
                                  labelText: 'Friend Name',
                                  border: const OutlineInputBorder(),
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
            ],

            // Date
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Bank Account
            if (!isLending || (isLending && _iPaid))
              Consumer<BankAccountProvider>(
                builder: (context, provider, child) {
                  if (provider.accounts.isEmpty) {
                    return const Text(
                      'No accounts found.',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.accounts.map((BankAccount account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(
                          account.type == 'bank'
                              ? '${account.bankName} (**** ${account.accountNumber.length > 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber})'
                              : account.bankName,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() => _selectedAccountId = newValue);
                    },
                    validator: (value) {
                      if (isLending && !_iPaid) return null;
                      return value == null ? 'Please select an account' : null;
                    },
                  );
                },
              ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save
            FilledButton(
              onPressed: _saveTransaction,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
