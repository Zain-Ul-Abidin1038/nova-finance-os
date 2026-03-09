import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/family/services/family_service.dart';
import 'package:nova_live_nova_finance_os/features/family/domain/family_account.dart';
import 'package:uuid/uuid.dart';

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(familyAccountProvider);
    final membersAsync = ref.watch(familyMembersProvider);

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
              title: const Text('Family Planning', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add, color: AppColors.softPurple),
                  onPressed: () => _showAddMemberDialog(context, ref),
                ),
              ],
            ),
            accountAsync.when(
              data: (account) {
                if (account == null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.family_restroom, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('Create your family account', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Create Family',
                            icon: Icons.add,
                            baseColor: AppColors.softPurple,
                            onPressed: () => _showCreateFamilyDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return membersAsync.when(
                  data: (members) {
                    final service = ref.read(familyServiceProvider);
                    final totalAllowances = service.getTotalAllowances();

                    return SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildFamilyCard(account, members.length),
                          const SizedBox(height: 20),
                          _buildAllowanceSummary(totalAllowances),
                          const SizedBox(height: 20),
                          _buildMembersList(members),
                        ]),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.softPurple))),
                  error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error)))),
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

  Widget _buildFamilyCard(FamilyAccount account, int memberCount) {
    return GlassCard(
      borderColor: AppColors.softPurple.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.softPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(Icons.family_restroom, color: AppColors.softPurple, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$memberCount ${memberCount == 1 ? 'member' : 'members'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceSummary(double totalAllowances) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Monthly Allowances', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text('\$${totalAllowances.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.softPurple, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<FamilyMember> members) {
    if (members.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No members yet. Add family members to get started.', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: members.map((member) {
        final roleColor = _getRoleColor(member.role);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(_getRoleIcon(member.role), color: roleColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(_getRoleLabel(member.role), style: TextStyle(color: roleColor, fontSize: 12)),
                    ],
                  ),
                ),
                if (member.allowance != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Allowance', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('\$${member.allowance!.toStringAsFixed(0)}/mo', style: const TextStyle(color: AppColors.softPurple, fontSize: 14)),
                    ],
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getRoleColor(FamilyRole role) {
    switch (role) {
      case FamilyRole.admin:
        return AppColors.neonTeal;
      case FamilyRole.parent:
        return AppColors.softPurple;
      case FamilyRole.child:
        return AppColors.success;
      case FamilyRole.viewer:
        return AppColors.textSecondary;
    }
  }

  IconData _getRoleIcon(FamilyRole role) {
    switch (role) {
      case FamilyRole.admin:
        return Icons.admin_panel_settings;
      case FamilyRole.parent:
        return Icons.person;
      case FamilyRole.child:
        return Icons.child_care;
      case FamilyRole.viewer:
        return Icons.visibility;
    }
  }

  String _getRoleLabel(FamilyRole role) {
    switch (role) {
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.parent:
        return 'Parent';
      case FamilyRole.child:
        return 'Child';
      case FamilyRole.viewer:
        return 'Viewer';
    }
  }

  void _showCreateFamilyDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Create Family Account', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Family Name',
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
              final name = nameController.text;
              if (name.isNotEmpty) {
                final service = ref.read(familyServiceProvider);
                final account = FamilyAccount(
                  id: const Uuid().v4(),
                  name: name,
                  createdBy: 'current_user',
                  memberIds: [],
                  createdAt: DateTime.now(),
                );
                await service.createFamilyAccount(account);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.softPurple)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final allowanceController = TextEditingController();
    FamilyRole selectedRole = FamilyRole.child;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Add Family Member', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FamilyRole>(
                value: selectedRole,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                ),
                items: FamilyRole.values.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(_getRoleLabel(role)),
                )).toList(),
                onChanged: (value) => setState(() => selectedRole = value!),
              ),
              TextField(
                controller: allowanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Monthly Allowance (optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                final allowance = double.tryParse(allowanceController.text);

                if (name.isNotEmpty) {
                  final service = ref.read(familyServiceProvider);
                  final member = FamilyMember(
                    id: const Uuid().v4(),
                    familyAccountId: 'family_id',
                    userId: const Uuid().v4(),
                    name: name,
                    role: selectedRole,
                    allowance: allowance,
                  );
                  await service.addMember(member);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: AppColors.softPurple)),
            ),
          ],
        ),
      ),
    );
  }
}
