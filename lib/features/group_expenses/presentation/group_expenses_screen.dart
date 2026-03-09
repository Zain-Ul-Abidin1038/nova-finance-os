import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/group_expenses/services/group_expense_service.dart';
import 'package:nova_live_nova_finance_os/features/group_expenses/domain/group_expense.dart';
import 'package:uuid/uuid.dart';

class GroupExpensesScreen extends ConsumerWidget {
  const GroupExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Group Expenses', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.softPurple),
                  onPressed: () => _showAddExpenseDialog(context, ref),
                ),
              ],
            ),
            expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No group expenses yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Split Expense',
                            icon: Icons.add,
                            baseColor: AppColors.softPurple,
                            onPressed: () => _showAddExpenseDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      expenses.map((expense) => _buildExpenseCard(expense, ref)).toList(),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.softPurple))),
              error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(GroupExpense expense, WidgetRef ref) {
    final paidCount = expense.participants.where((p) => p.paid).length;
    final totalCount = expense.participants.length;
    final isFullyPaid = expense.isFullyPaid;
    final color = isFullyPaid ? AppColors.success : AppColors.softPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderColor: color.withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(isFullyPaid ? Icons.check_circle : Icons.group, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (expense.description.isNotEmpty)
                        Text(expense.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text('\$${expense.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text('$paidCount/$totalCount paid', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Participants', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...expense.participants.map((participant) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    participant.paid ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: participant.paid ? AppColors.success : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(participant.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  ),
                  Text('\$${participant.shareAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  if (!participant.paid) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final service = ref.read(groupExpenseServiceProvider);
                        await service.markParticipantPaid(expense.id, participant.userId);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Mark Paid', style: TextStyle(color: AppColors.softPurple, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final List<Map<String, dynamic>> participants = [
      {'name': '', 'share': 0.0},
      {'name': '', 'share': 0.0},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Split Expense', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Expense Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                  onChanged: (value) {
                    final total = double.tryParse(value) ?? 0;
                    if (total > 0) {
                      final share = total / participants.length;
                      setState(() {
                        for (var p in participants) {
                          p['share'] = share;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Participants', style: TextStyle(color: AppColors.softPurple, fontSize: 14, fontWeight: FontWeight.bold)),
                ...List.generate(participants.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Name ${index + 1}',
                              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                            ),
                            onChanged: (value) => participants[index]['name'] = value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: Text('\$${participants[index]['share'].toStringAsFixed(2)}', style: const TextStyle(color: AppColors.softPurple, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton(
                  onPressed: () {
                    setState(() {
                      participants.add({'name': '', 'share': 0.0});
                      final total = double.tryParse(amountController.text) ?? 0;
                      if (total > 0) {
                        final share = total / participants.length;
                        for (var p in participants) {
                          p['share'] = share;
                        }
                      }
                    });
                  },
                  child: const Text('+ Add Participant', style: TextStyle(color: AppColors.softPurple)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                final description = descriptionController.text;
                final amount = double.tryParse(amountController.text) ?? 0;

                if (name.isNotEmpty && amount > 0 && participants.every((p) => p['name'].toString().isNotEmpty)) {
                  final service = ref.read(groupExpenseServiceProvider);
                  final expense = GroupExpense(
                    id: const Uuid().v4(),
                    name: name,
                    description: description,
                    totalAmount: amount,
                    createdBy: 'current_user',
                    participants: participants.map((p) => ExpenseParticipant(
                      userId: const Uuid().v4(),
                      name: p['name'] as String,
                      shareAmount: p['share'] as double,
                      paid: false,
                    )).toList(),
                    createdAt: DateTime.now(),
                    isSettled: false,
                  );
                  await service.addExpense(expense);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create', style: TextStyle(color: AppColors.softPurple)),
            ),
          ],
        ),
      ),
    );
  }
}
