import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/insurance/services/insurance_service.dart';
import 'package:nova_live_nova_finance_os/features/insurance/domain/policy.dart';
import 'package:uuid/uuid.dart';

class InsuranceDashboardScreen extends ConsumerWidget {
  const InsuranceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(policiesProvider);

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
              title: const Text('Insurance Policies', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.neonTeal),
                  onPressed: () => _showAddPolicyDialog(context, ref),
                ),
              ],
            ),
            policiesAsync.when(
              data: (policies) {
                if (policies.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No insurance policies yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Add Policy',
                            icon: Icons.add,
                            onPressed: () => _showAddPolicyDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final service = ref.read(insuranceServiceProvider);
                final totalPremium = service.getTotalAnnualPremium();
                final totalCoverage = service.getTotalCoverage();
                final expiringPolicies = service.getExpiringPolicies();

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSummaryCard(totalPremium, totalCoverage, expiringPolicies.length),
                      const SizedBox(height: 20),
                      if (expiringPolicies.isNotEmpty) ...[
                        _buildExpiringPoliciesWarning(expiringPolicies),
                        const SizedBox(height: 20),
                      ],
                      _buildPoliciesList(policies),
                    ]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.neonTeal))),
              error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalPremium, double totalCoverage, int expiringCount) {
    return GlassCard(
      borderColor: AppColors.softPurple.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Coverage', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text('\$${totalCoverage.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Annual Premium', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${totalPremium.toStringAsFixed(0)}/year', style: const TextStyle(color: AppColors.softPurple, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (expiringCount > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Expiring Soon', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('$expiringCount ${expiringCount == 1 ? 'policy' : 'policies'}', style: const TextStyle(color: AppColors.warning, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringPoliciesWarning(List<InsurancePolicy> policies) {
    return GlassCard(
      borderColor: AppColors.warning.withOpacity(0.4),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.warning.withOpacity(0.1), Colors.transparent],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.warning, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Policies Expiring Soon', style: TextStyle(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${policies.length} ${policies.length == 1 ? 'policy expires' : 'policies expire'} within 30 days', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesList(List<InsurancePolicy> policies) {
    return Column(
      children: policies.map((policy) {
        final icon = _getPolicyIcon(policy.type);
        final color = policy.isExpiringSoon ? AppColors.warning : AppColors.neonTeal;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: policy.isExpiringSoon ? AppColors.warning.withOpacity(0.3) : null,
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
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getPolicyTypeLabel(policy.type), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(policy.provider, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Coverage', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text('\$${policy.coverage.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Premium', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text('\$${policy.premium.toStringAsFixed(0)}/mo', style: const TextStyle(color: AppColors.softPurple, fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Expires', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text(
                          _formatDate(policy.expiryDate),
                          style: TextStyle(
                            color: policy.isExpiringSoon ? AppColors.warning : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: policy.isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getPolicyIcon(PolicyType type) {
    switch (type) {
      case PolicyType.life:
        return Icons.favorite;
      case PolicyType.health:
        return Icons.local_hospital;
      case PolicyType.auto:
        return Icons.directions_car;
      case PolicyType.home:
        return Icons.home;
      case PolicyType.travel:
        return Icons.flight;
    }
  }

  String _getPolicyTypeLabel(PolicyType type) {
    switch (type) {
      case PolicyType.life:
        return 'Life Insurance';
      case PolicyType.health:
        return 'Health Insurance';
      case PolicyType.auto:
        return 'Auto Insurance';
      case PolicyType.home:
        return 'Home Insurance';
      case PolicyType.travel:
        return 'Travel Insurance';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showAddPolicyDialog(BuildContext context, WidgetRef ref) {
    final providerController = TextEditingController();
    final policyNumberController = TextEditingController();
    final premiumController = TextEditingController();
    final coverageController = TextEditingController();
    PolicyType selectedType = PolicyType.health;
    DateTime expiryDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Add Insurance Policy', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PolicyType>(
                  value: selectedType,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                  items: PolicyType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(_getPolicyTypeLabel(type)),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                TextField(
                  controller: providerController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
                TextField(
                  controller: policyNumberController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Policy Number',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
                TextField(
                  controller: premiumController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Premium',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                  ),
                ),
                TextField(
                  controller: coverageController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Coverage Amount',
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
                final provider = providerController.text;
                final policyNumber = policyNumberController.text;
                final premium = double.tryParse(premiumController.text) ?? 0;
                final coverage = double.tryParse(coverageController.text) ?? 0;

                if (provider.isNotEmpty && policyNumber.isNotEmpty && premium > 0 && coverage > 0) {
                  final service = ref.read(insuranceServiceProvider);
                  final policy = InsurancePolicy(
                    id: const Uuid().v4(),
                    userId: 'current_user',
                    type: selectedType,
                    provider: provider,
                    policyNumber: policyNumber,
                    premium: premium,
                    coverage: coverage,
                    expiryDate: expiryDate,
                    createdAt: DateTime.now(),
                  );
                  await service.addPolicy(policy);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: AppColors.neonTeal)),
            ),
          ],
        ),
      ),
    );
  }
}
