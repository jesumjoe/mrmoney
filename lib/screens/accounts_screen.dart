import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/screens/sms_config_screen.dart';
import 'package:mrmoney/theme/neo_style.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold provided by HomeScreen
    return Consumer<BankAccountProvider>(
      builder: (context, provider, child) {
        if (provider.accounts.isEmpty) {
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
                    Icons.account_balance_wallet_rounded,
                    size: 48,
                    color: NeoColors.text.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No accounts added yet',
                  style: NeoStyle.bold(
                    color: NeoColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                NeoButton(
                  onPressed: () => _showAddEditAccountDialog(context),
                  text: 'Add Account',
                  color: NeoColors.primary,
                ),
              ],
            ),
          );
        }

        // Group Accounts
        final bankAndCash = provider.accounts
            .where((a) => a.type == 'bank' || a.type == 'cash')
            .toList();
        final investments = provider.accounts
            .where((a) => a.type == 'investment')
            .toList();

        final totalAssets = provider.totalBalance;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            100,
          ), // Reduced top padding
          children: [
            // Summary Card
            NeoCard(
              color: NeoColors.primary, // Black
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Assets',
                    style: NeoStyle.regular(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                      decimalDigits: 0,
                    ).format(totalAssets),
                    style: NeoStyle.bold(color: Colors.white, fontSize: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Accounts (Bank & Cash)
            if (bankAndCash.isNotEmpty) ...[
              _buildSectionHeader('Accounts'),
              const SizedBox(height: 16),
              ...bankAndCash.map(
                (account) => _buildAccountTile(context, account),
              ),
              const SizedBox(height: 24),
            ],

            // Investments
            if (investments.isNotEmpty) ...[
              _buildSectionHeader('Investments'),
              const SizedBox(height: 16),
              ...investments.map(
                (account) => _buildAccountTile(context, account),
              ),
              const SizedBox(height: 24),
            ],

            // Add Account Button
            NeoButton(
              text: 'Add New Account',
              onPressed: () => _showAddEditAccountDialog(context),
              color: Colors.transparent,
              textColor: NeoColors.text,
              outline: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: NeoStyle.bold(fontSize: 18, color: NeoColors.text),
    );
  }

  Widget _buildAccountTile(BuildContext context, BankAccount account) {
    return NeoCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero, // Padding handled by internal Padding widget
      onTap: () => _showAccountOptions(context, account),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: NeoColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: NeoColors.border),
              ),
              child: Center(
                child: Icon(
                  account.type == 'cash'
                      ? Icons.payments_outlined
                      : (account.type == 'investment'
                            ? Icons.trending_up_rounded
                            : Icons.account_balance_rounded),
                  color: NeoColors.text,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.bankName, style: NeoStyle.bold(fontSize: 16)),
                  if (account.type == 'bank')
                    Text(
                      '**** ${account.accountNumber}',
                      style: NeoStyle.regular(
                        fontSize: 12,
                        color: NeoColors.textSecondary,
                      ),
                    )
                  else
                    Text(
                      account.type[0].toUpperCase() + account.type.substring(1),
                      style: NeoStyle.regular(
                        fontSize: 12,
                        color: NeoColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
                decimalDigits: 0,
              ).format(account.currentBalance),
              style: NeoStyle.bold(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountOptions(BuildContext context, BankAccount account) {
    NeoStyle.showNeoDialog(
      context: context,
      title: account.bankName,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text('Edit Account', style: NeoStyle.bold(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              _showAddEditAccountDialog(context, account: account);
            },
          ),
          ListTile(
            leading: const Icon(Icons.message_outlined),
            title: Text('SMS Rules', style: NeoStyle.bold(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SmsConfigScreen(account: account),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: NeoColors.error),
            title: Text(
              'Delete',
              style: NeoStyle.bold(fontSize: 16, color: NeoColors.error),
            ),
            onTap: () {
              Navigator.pop(context); // Close selection dialog
              // Show confirmation
              Future.delayed(const Duration(milliseconds: 200), () {
                if (context.mounted) {
                  _showDeleteConfirmation(context, account);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, BankAccount account) {
    NeoStyle.showNeoDialog(
      context: context,
      title: 'Delete Account?',
      content: Text(
        'Are you sure you want to delete ${account.bankName}? This action cannot be undone.',
        textAlign: TextAlign.center,
        style: NeoStyle.regular(color: NeoColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: NeoStyle.bold(color: NeoColors.text)),
        ),
        TextButton(
          onPressed: () {
            Provider.of<BankAccountProvider>(
              context,
              listen: false,
            ).deleteAccount(account);
            Navigator.pop(context);
          },
          child: Text('Delete', style: NeoStyle.bold(color: NeoColors.error)),
        ),
      ],
    );
  }

  void _showAddEditAccountDialog(BuildContext context, {BankAccount? account}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: AddEditAccountDialog(account: account),
      ),
    );
  }
}

class AddEditAccountDialog extends StatefulWidget {
  final BankAccount? account;
  const AddEditAccountDialog({super.key, this.account});

  @override
  State<AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends State<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _balanceController = TextEditingController();
  String _type = 'bank';
  bool _isSmsParsingEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _bankNameController.text = widget.account!.bankName;
      _accountNumberController.text = widget.account!.accountNumber;
      _balanceController.text = widget.account!.currentBalance.toString();
      _isSmsParsingEnabled = widget.account!.isSmsParsingEnabled;
      _type = widget.account!.type;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<BankAccountProvider>(context, listen: false);

      if (widget.account != null) {
        // Update
        widget.account!.bankName = _bankNameController.text;
        widget.account!.accountNumber = _accountNumberController.text;
        widget.account!.currentBalance =
            double.tryParse(_balanceController.text) ?? 0.0;
        widget.account!.isSmsParsingEnabled = _isSmsParsingEnabled;
        widget.account!.type = _type;

        provider.updateAccount(widget.account!);
      } else {
        // Create
        final account = BankAccount(
          id: const Uuid().v4(),
          bankName: _bankNameController.text,
          accountNumber: _accountNumberController.text,
          currentBalance: double.tryParse(_balanceController.text) ?? 0.0,
          smsKeyword: '', // Optional/Removed for now
          isSmsParsingEnabled: _isSmsParsingEnabled,
          type: _type,
        );
        provider.addAccount(account);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeoStyle.box(color: Colors.white, radius: 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Account' : 'Add Account',
                style: NeoStyle.bold(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _bankNameController,
                decoration: NeoStyle.inputDecoration(
                  hintText: 'Account Name',
                  prefixIcon: const Icon(Icons.account_balance_rounded),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: NeoStyle.inputDecoration(
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(
                    value: 'investment',
                    child: Text('Investment'),
                  ),
                ],
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 16),
              if (_type == 'bank') ...[
                TextFormField(
                  controller: _accountNumberController,
                  decoration: NeoStyle.inputDecoration(
                    hintText: 'Last 4 Digits',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                  ),
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.length < 4
                      ? 'Enter last 4 digits'
                      : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    'Enable SMS Parsing',
                    style: NeoStyle.bold(fontSize: 14),
                  ),
                  value: _isSmsParsingEnabled,
                  activeColor: NeoColors.primary,
                  onChanged: (val) =>
                      setState(() => _isSmsParsingEnabled = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _balanceController,
                decoration: NeoStyle.inputDecoration(
                  hintText: 'Current Balance',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      text: 'Cancel',
                      outline: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NeoButton(
                      text: 'Save',
                      color: NeoColors.primary,
                      onPressed: _saveAccount,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
