import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/shared_goals/services/shared_goal_service.dart';
import 'package:nova_live_nova_finance_os/features/shared_goals/domain/shared_goal.dart';
import 'package:uuid/uuid.dart';

class SharedGoalsScreen extends ConsumerWidget {
  const SharedGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(sharedGoalsProvider);

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
              title: const Text('Shared Goals', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.softPurple),
                  onPressed: () => _showAddGoalDialog(context, ref),
                ),
              ],
            ),
            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No shared goals yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Create Goal',
                            icon: Icons.add,
                            baseColor: AppColors.softPurple,
                            onPressed: () => _showAddGoalDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final activeGoals = goals.where((g) => !g.isCompleted).toList();
                final completedGoals = goals.where((g) => g.isCompleted).toList();

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (activeGoals.isNotEmpty) ...[
                        const Text('Active Goals', style: TextStyle(color: AppColors.softPurple, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...activeGoals.map((goal) => _buildGoalCard(goal, ref)),
                      ],
                      if (completedGoals.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Completed Goals', style: TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...completedGoals.map((goal) => _buildGoalCard(goal, ref)),
                      ],
                    ]),
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

  Widget _buildGoalCard(SharedGoal goal, WidgetRef ref) {
    final progress = goal.progressPercentage.clamp(0.0, 100.0);
    final isCompleted = goal.isCompleted;
    final color = isCompleted ? AppColors.success : AppColors.softPurple;

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
                  child: Icon(isCompleted ? Icons.check_circle : Icons.flag, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (goal.description.isNotEmpty)
                        Text(goal.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${goal.currentAmount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('of \$${goal.targetAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: AppColors.textMuted.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${progress.toStringAsFixed(1)}% complete', style: TextStyle(color: color, fontSize: 12)),
                if (!isCompleted)
                  Text('${goal.daysRemaining} days left', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showContributeDialog(context, ref, goal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.2),
                    foregroundColor: color,
                    elevation: 0,
                  ),
                  child: const Text('Contribute'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Create Shared Goal', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
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
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
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
              final name = nameController.text;
              final description = descriptionController.text;
              final target = double.tryParse(targetController.text) ?? 0;

              if (name.isNotEmpty && target > 0) {
                final service = ref.read(sharedGoalServiceProvider);
                final goal = SharedGoal(
                  id: const Uuid().v4(),
                  familyAccountId: 'family_id',
                  name: name,
                  description: description,
                  targetAmount: target,
                  currentAmount: 0,
                  deadline: DateTime.now().add(const Duration(days: 365)),
                  createdAt: DateTime.now(),
                  contributorIds: [],
                );
                await service.addGoal(goal);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.softPurple)),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog(BuildContext context, WidgetRef ref, SharedGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Contribute to ${goal.name}', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Amount',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                final service = ref.read(sharedGoalServiceProvider);
                await service.addContribution(goal.id, amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Contribute', style: TextStyle(color: AppColors.softPurple)),
          ),
        ],
      ),
    );
  }
}
