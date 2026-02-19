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
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        title: Text('Accounts', style: NeoStyle.bold(fontSize: 24)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            color: NeoColors.text,
            onPressed: () {
              // TODO: Analytics
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            color: NeoColors.text,
            onPressed: () {
              // TODO: More options
            },
          ),
        ],
      ),
      body: Consumer<BankAccountProvider>(
        builder: (context, provider, child) {
          if (provider.accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts added yet.',
                    style: NeoStyle.regular(
                      color: Colors.grey.shade600,
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
          final totalLiabilities = 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                NeoCard(
                  color: NeoColors.text, // Dark Slate / Navy
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assets',
                                style: NeoStyle.regular(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.currency(
                                  locale: 'en_IN',
                                  symbol: '₹',
                                ).format(totalAssets),
                                style: NeoStyle.bold(
                                  color: NeoColors.accent,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Liabilities',
                                style: NeoStyle.regular(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.currency(
                                  locale: 'en_IN',
                                  symbol: '₹',
                                ).format(totalLiabilities),
                                style: NeoStyle.bold(
                                  color: NeoColors.error,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24, thickness: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: NeoStyle.bold(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'en_IN',
                              symbol: '₹',
                            ).format(totalAssets - totalLiabilities),
                            style: NeoStyle.bold(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Accounts (Bank & Cash)
                if (bankAndCash.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Accounts',
                    bankAndCash.fold(
                      0,
                      (sum, item) => sum + item.currentBalance,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...bankAndCash.map(
                    (account) => _buildAccountTile(context, account),
                  ),
                  const SizedBox(height: 24),
                ],

                // Investments
                if (investments.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Investments',
                    investments.fold(
                      0,
                      (sum, item) => sum + item.currentBalance,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...investments.map(
                    (account) => _buildAccountTile(context, account),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeoColors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NeoColors.border, width: 2),
        ),
        onPressed: () => _showAddEditAccountDialog(context),
        child: const Icon(Icons.add, color: NeoColors.text),
      ),
    );
  }

  Widget _buildSectionHeader(String title, double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: NeoStyle.bold(fontSize: 18, color: NeoColors.text)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: NeoStyle.box(
            color: NeoColors.surface,
            radius: 12,
            noShadow: true,
          ),
          child: Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(total),
            style: NeoStyle.bold(fontSize: 14, color: NeoColors.text),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile(BuildContext context, BankAccount account) {
    return NeoCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: () => _showAccountOptions(context, account),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: NeoStyle.circle(color: NeoColors.background),
              child: Icon(
                account.type == 'cash'
                    ? Icons.money
                    : (account.type == 'investment'
                          ? Icons.trending_up
                          : Icons.account_balance),
                color: NeoColors.text,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.bankName, style: NeoStyle.bold(fontSize: 16)),
                  const SizedBox(height: 4),
                  account.type == 'bank'
                      ? Text(
                          '**** ${account.accountNumber}',
                          style: NeoStyle.regular(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : HelperText(account.type),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
              ).format(account.currentBalance),
              style: NeoStyle.bold(fontSize: 16, color: NeoColors.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget HelperText(String type) {
    String text = type[0].toUpperCase() + type.substring(1);
    return Text(
      text,
      style: NeoStyle.regular(fontSize: 14, color: Colors.grey.shade600),
    );
  }

  void _showAccountOptions(BuildContext context, BankAccount account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: NeoStyle.box(
          color: Colors.white,
          radius: 24,
          noShadow: true,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: NeoColors.text),
              title: Text('Edit Account', style: NeoStyle.bold()),
              onTap: () {
                Navigator.pop(context);
                _showAddEditAccountDialog(context, account: account);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: NeoColors.text),
              title: Text('Configure SMS Rules', style: NeoStyle.bold()),
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
              leading: const Icon(Icons.delete, color: NeoColors.error),
              title: Text(
                'Delete Account',
                style: NeoStyle.bold(color: NeoColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                NeoStyle.showNeoDialog(
                  context: context,
                  title: 'Delete Account?',
                  content: Text(
                    'Are you sure you want to delete ${account.bankName}?',
                    textAlign: TextAlign.center,
                    style: NeoStyle.regular(),
                  ),
                  actions: [
                    NeoButton(
                      text: 'Cancel',
                      color: Colors.transparent,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    NeoButton(
                      text: 'Delete',
                      color: NeoColors.error,
                      onPressed: () {
                        Provider.of<BankAccountProvider>(
                          context,
                          listen: false,
                        ).deleteAccount(account);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
  final _smsKeywordController = TextEditingController();
  String _type = 'bank';
  bool _isSmsParsingEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _bankNameController.text = widget.account!.bankName;
      _accountNumberController.text = widget.account!.accountNumber;
      _balanceController.text = widget.account!.currentBalance.toString();
      _smsKeywordController.text = widget.account!.smsKeyword;
      _isSmsParsingEnabled = widget.account!.isSmsParsingEnabled;
      _type = widget.account!.type;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _balanceController.dispose();
    _smsKeywordController.dispose();
    super.dispose();
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
                isEditing ? 'Edit Bank Account' : 'Add Bank Account',
                style: NeoStyle.bold(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _bankNameController,
                decoration: NeoStyle.inputDecoration(
                  hintText: 'Bank Name (e.g. HDFC)',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter bank name'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: NeoStyle.inputDecoration(hintText: 'Account Type'),
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
                    hintText: 'Account Number (Last 4)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter account number'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _smsKeywordController,
                  decoration: NeoStyle.inputDecoration(
                    hintText: 'SMS Keyword (Optional)',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: NeoStyle.box(
                    color: Colors.white,
                    radius: NeoStyle.radius,
                  ),
                  child: SwitchListTile(
                    title: Text('Enable SMS Parsing', style: NeoStyle.bold()),
                    value: _isSmsParsingEnabled,
                    activeThumbColor: NeoColors.primary,
                    onChanged: (val) =>
                        setState(() => _isSmsParsingEnabled = val),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _balanceController,
                decoration: NeoStyle.inputDecoration(
                  hintText: 'Current Balance',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter balance'
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NeoButton(
                    text: 'Cancel',
                    color: Colors.transparent,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  NeoButton(
                    text: 'Save',
                    color: NeoColors.primary,
                    onPressed: _saveAccount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        widget.account!.smsKeyword = _smsKeywordController.text;
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
          smsKeyword: _smsKeywordController.text,
          isSmsParsingEnabled: _isSmsParsingEnabled,
          type: _type,
        );
        provider.addAccount(account);
      }

      Navigator.pop(context);
    }
  }
}
