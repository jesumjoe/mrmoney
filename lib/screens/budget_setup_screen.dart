import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mrmoney/providers/budget_provider.dart';
import 'package:mrmoney/repositories/category_repository.dart';
import 'package:mrmoney/models/category.dart';
import 'package:mrmoney/theme/neo_style.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    _goalController.text = provider.savingsGoal.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        title: Text('Budget Setup', style: NeoStyle.bold(fontSize: 24)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: NeoColors.text),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Savings Goal Section
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Savings Goal',
                      style: NeoStyle.bold(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      decoration: NeoStyle.inputDecoration(
                        hintText: 'Amount (₹)',
                      ).copyWith(prefixText: '₹ '),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          provider.setSavingsGoal(double.parse(val));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This amount will be reserved from your spending capacity.',
                      style: NeoStyle.regular(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Total Allocation Visual
              // TODO: Implement a visual bar if we have total income?
              // For now, let's just show Total Category Limits + Goal
              // ...

              // Category Limits
              Text('Category Limits', style: NeoStyle.bold(fontSize: 20)),
              const SizedBox(height: 16),

              Consumer<CategoryRepository>(
                builder: (context, repo, child) {
                  final categories = repo.getAll();
                  return Column(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: NeoCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: NeoStyle.circle(
                                  color: NeoColors.background,
                                ),
                                child: Icon(
                                  IconData(
                                    category.iconCode,
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  color: NeoColors.text,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: NeoStyle.bold(fontSize: 16),
                                    ),
                                    Text(
                                      category.budgetLimit != null
                                          ? 'Limit: ₹${category.budgetLimit!.toStringAsFixed(0)}'
                                          : 'No Limit',
                                      style: NeoStyle.regular(
                                        color: category.budgetLimit != null
                                            ? NeoColors.primaryDark
                                            : Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: NeoColors.text,
                                ),
                                onPressed: () => _showLimitDialog(
                                  context,
                                  provider,
                                  category,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLimitDialog(
    BuildContext context,
    BudgetProvider provider,
    Category category,
  ) {
    final controller = TextEditingController(
      text: category.budgetLimit?.toStringAsFixed(0) ?? '',
    );

    NeoStyle.showNeoDialog(
      context: context,
      title: 'Set Limit for ${category.name}',
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: NeoStyle.inputDecoration(
          hintText: 'Monthly Limit (₹)',
        ).copyWith(prefixText: '₹ '),
      ),
      actions: [
        NeoButton(
          text: 'Cancel',
          color: Colors.transparent,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        NeoButton(
          text: 'Save',
          onPressed: () {
            final limit = double.tryParse(controller.text);
            if (limit != null) {
              provider.setCategoryLimit(category.id, limit);
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
