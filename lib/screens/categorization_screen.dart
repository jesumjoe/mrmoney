import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
import 'package:mrmoney/providers/friend_provider.dart';
import 'package:mrmoney/models/transaction.dart';
import 'package:mrmoney/models/transaction_type.dart';
import 'package:mrmoney/models/friend_loan.dart';

class CategorizationScreen extends StatefulWidget {
  final TransactionType type;
  final double amount;
  final String? merchant;
  final String? accountLastDigits;
  final DateTime date;

  const CategorizationScreen({
    super.key,
    required this.type,
    required this.amount,
    this.merchant,
    this.accountLastDigits,
    required this.date,
  });

  @override
  State<CategorizationScreen> createState() => _CategorizationScreenState();
}

class _CategorizationScreenState extends State<CategorizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _newFriendController = TextEditingController();
  String? _selectedAccountId;

  // Lending
  String? _selectedFriend;
  bool _isNewFriend = false; // Add new friend mode

  final List<String> _categories = [
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
  void initState() {
    super.initState();
    _descriptionController.text = widget.merchant ?? '';
    // Auto-categorize generic logic
    if (widget.merchant != null) {
      final m = widget.merchant!.toUpperCase();
      if (m.contains('ZOMATO') || m.contains('SWIGGY')) {
        _categoryController.text = 'Food';
      } else if (m.contains('UBER') || m.contains('OLA'))
        _categoryController.text = 'Transport';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchAccount();
    });
  }

  void _matchAccount() {
    if (widget.accountLastDigits != null) {
      final accountProvider = Provider.of<BankAccountProvider>(
        context,
        listen: false,
      );
      try {
        final match = accountProvider.accounts.firstWhere(
          (acc) => acc.accountNumber.endsWith(widget.accountLastDigits!),
        );
        setState(() {
          _selectedAccountId = match.id;
        });
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLending = _categoryController.text == 'Lending';

    return Scaffold(
      appBar: AppBar(title: const Text('New Transaction detected')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Amount',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '₹${widget.amount}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: widget.type == TransactionType.credit
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(DateFormat('MMM d, h:mm a').format(widget.date)),
                    if (widget.merchant != null)
                      Text(
                        widget.merchant!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bank Account Selection
            Consumer<BankAccountProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Bank Account',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedAccountId,
                  items: provider.accounts.map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc.id,
                      child: Text(
                        '${acc.bankName} (**** ${acc.accountNumber})',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedAccountId = val;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select an account' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Category Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              initialValue: _categoryController.text.isNotEmpty
                  ? _categoryController.text
                  : null,
              items: _categories.map((String category) {
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

            // LENDING FRIEND SELECTOR
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
                child: Consumer<FriendProvider>(
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
                                      onPressed: () =>
                                          setState(() => _isNewFriend = false),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description / Merchant',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveTransaction,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transactionId = const Uuid().v4();

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

        // Determine FriendLoan Type
        // If Transaction is Debit (I spent), They Owe Me (OWED)
        // If Transaction is Credit (I received), I Owe Them (OWE) - (Repayment)
        final loanType = widget.type == TransactionType.debit
            ? FriendLoanType.owed
            : FriendLoanType.owe;

        final loan = FriendLoan(
          id: const Uuid().v4(),
          friendName: friendName,
          amount: widget.amount,
          type: loanType,
          description: _descriptionController.text.isEmpty
              ? 'SMS: ${widget.merchant ?? "Transaction"}'
              : _descriptionController.text,
          date: widget.date,
          transactionId: transactionId,
        );

        Provider.of<FriendProvider>(context, listen: false).addLoan(loan);
      }

      final transaction = Transaction(
        id: transactionId,
        amount: widget.amount,
        type: widget.type,
        category: _categoryController.text,
        description: _descriptionController.text,
        date: widget.date,
        bankAccountId: _selectedAccountId,
        isFromSMS: true,
      );

      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).addTransaction(transaction);
      Navigator.pop(context);
    }
  }
}
