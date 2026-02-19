import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mrmoney/models/bank_account.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
// import 'package:mrmoney/services/sms_parsing_service.dart'; // Removed unused

class SmsConfigScreen extends StatefulWidget {
  final BankAccount account;

  const SmsConfigScreen({super.key, required this.account});

  @override
  State<SmsConfigScreen> createState() => _SmsConfigScreenState();
}

class _SmsConfigScreenState extends State<SmsConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _testSmsController = TextEditingController();
  String _testResult = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _testSmsController.dispose();
    super.dispose();
  }

  void _addRegex(bool isDebit) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(isDebit ? 'Add Debit Pattern' : 'Add Credit Pattern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter Regex Pattern.\nUse capture groups: (Amount), (Account), (Merchant/Info)",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: r'Debited\s([0-9.]+)\s.*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    if (isDebit) {
                      widget.account.customDebitRegex.add(controller.text);
                    } else {
                      widget.account.customCreditRegex.add(controller.text);
                    }
                  });
                  _saveAccount();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveAccount() {
    Provider.of<BankAccountProvider>(
      context,
      listen: false,
    ).updateAccount(widget.account);
  }

  void _testParser() {
    if (_testSmsController.text.isEmpty) return;

    // We need to temporarily mock the service or expose a test method?
    // Let's create a temporary service instance or static method helper?
    // SmsParsingService.parseSms() uses HARDCODED patterns.
    // We need to update SmsParsingService to accept custom patterns first.
    // For now, let's just simulate what we WANT to happen or update Service first.
    // Actually, I should update Service first.
    // But I can implement the UI logic assuming the service will be updated.

    // Let's manually test with the patterns in the account for now to verify regex validity.
    final body = _testSmsController.text;
    String result = "No match found.";

    // Test Debits
    for (var pattern in widget.account.customDebitRegex) {
      try {
        final reg = RegExp(pattern, caseSensitive: false);
        final match = reg.firstMatch(body);
        if (match != null) {
          result = "Matched Debit Pattern!\n\n";
          for (int i = 1; i <= match.groupCount; i++) {
            result += "Group $i: ${match.group(i)}\n";
          }
          setState(() => _testResult = result);
          return;
        }
      } catch (e) {
        result = "Invalid Regex: $pattern\nError: $e";
      }
    }

    // Test Credits
    for (var pattern in widget.account.customCreditRegex) {
      try {
        final reg = RegExp(pattern, caseSensitive: false);
        final match = reg.firstMatch(body);
        if (match != null) {
          result = "Matched Credit Pattern!\n\n";
          for (int i = 1; i <= match.groupCount; i++) {
            result += "Group $i: ${match.group(i)}\n";
          }
          setState(() => _testResult = result);
          return;
        }
      } catch (e) {
        result = "Invalid Regex: $pattern\nError: $e";
      }
    }

    setState(() => _testResult = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.bankName} SMS Rules'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Debit Rules"),
            Tab(text: "Credit Rules"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildRuleList(true), _buildRuleList(false)],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Test Sandbox",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _testSmsController,
                  decoration: const InputDecoration(
                    hintText: "Paste a sample SMS here...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _testParser,
                        child: const Text("Test Configuration"),
                      ),
                    ),
                  ],
                ),
                if (_testResult.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade200,
                    child: Text(
                      _testResult,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleList(bool isDebit) {
    final rules = isDebit
        ? widget.account.customDebitRegex
        : widget.account.customCreditRegex;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length + 1,
      itemBuilder: (context, index) {
        if (index == rules.length) {
          return Center(
            child: TextButton.icon(
              onPressed: () => _addRegex(isDebit),
              icon: const Icon(Icons.add),
              label: const Text("Add Pattern"),
            ),
          );
        }
        final rule = rules[index];
        return Card(
          child: ListTile(
            title: Text(rule, style: const TextStyle(fontFamily: 'monospace')),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  if (isDebit) {
                    widget.account.customDebitRegex.removeAt(index);
                  } else {
                    widget.account.customCreditRegex.removeAt(index);
                  }
                });
                _saveAccount();
              },
            ),
          ),
        );
      },
    );
  }
}
