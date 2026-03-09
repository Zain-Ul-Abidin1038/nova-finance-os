import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/business/services/business_expense_service.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/business/domain/business_expense.dart';
import 'package:uuid/uuid.dart';

class BusinessExpensesScreen extends ConsumerWidget {
  const BusinessExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(businessExpensesProvider);

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
              title: const Text('Business Expenses', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.success),
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
                          const Icon(Icons.business_center, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No business expenses yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Add Expense',
                            icon: Icons.add,
                            baseColor: AppColors.success,
                            onPressed: () => _showAddExpenseDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final pending = expenses.where((e) => e.isPending).toList();
                final approved = expenses.where((e) => e.isApproved).toList();
                final rejected = expenses.where((e) => e.isRejected).toList();

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSummaryCards(pending.length, approved.length, rejected.length),
                      const SizedBox(height: 20),
                      if (pending.isNotEmpty) ...[
                        const Text('Pending Approval', style: TextStyle(color: AppColors.warning, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...pending.map((e) => _buildExpenseCard(e, ref)),
                        const SizedBox(height: 20),
                      ],
                      if (approved.isNotEmpty) ...[
                        const Text('Approved', style: TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...approved.map((e) => _buildExpenseCard(e, ref)),
                      ],
                    ]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.success))),
              error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(int pending, int approved, int rejected) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.warning.withOpacity(0.4),
            child: Column(
              children: [
                Text('$pending', style: const TextStyle(color: AppColors.warning, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Pending', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.success.withOpacity(0.4),
            child: Column(
              children: [
                Text('$approved', style: const TextStyle(color: AppColors.success, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Approved', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.error.withOpacity(0.4),
            child: Column(
              children: [
                Text('$rejected', style: const TextStyle(color: AppColors.error, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Rejected', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(BusinessExpense expense, WidgetRef ref) {
    final statusColor = expense.isPending ? AppColors.warning : expense.isApproved ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: statusColor.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.category, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('${expense.department} • ${expense.project}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Text('\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(expense.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Submitted by ${expense.submittedBy}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    expense.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (expense.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final service = ref.read(businessExpenseServiceProvider);
                        await service.approveExpense(expense.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success.withOpacity(0.2),
                        foregroundColor: AppColors.success,
                        elevation: 0,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final service = ref.read(businessExpenseServiceProvider);
                        await service.rejectExpense(expense.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.2),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final departmentController = TextEditingController(text: 'Engineering');
    final projectController = TextEditingController(text: 'Project Alpha');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Submit Business Expense', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Category',
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
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                ),
              ),
              TextField(
                controller: departmentController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Department',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                ),
              ),
              TextField(
                controller: projectController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Project',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                ),
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
              final category = categoryController.text;
              final description = descriptionController.text;
              final amount = double.tryParse(amountController.text) ?? 0;
              final department = departmentController.text;
              final project = projectController.text;

              if (category.isNotEmpty && amount > 0) {
                final service = ref.read(businessExpenseServiceProvider);
                final expense = BusinessExpense(
                  id: const Uuid().v4(),
                  businessEntityId: 'entity_id',
                  department: department,
                  project: project,
                  category: category,
                  amount: amount,
                  description: description,
                  submittedBy: 'Current User',
                  status: ApprovalStatus.pending,
                  submittedAt: DateTime.now(),
                );
                await service.addExpense(expense);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}
