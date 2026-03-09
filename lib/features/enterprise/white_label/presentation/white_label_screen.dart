import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/white_label/domain/tenant.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/white_label/services/white_label_service.dart';
import 'package:intl/intl.dart';

class WhiteLabelScreen extends ConsumerStatefulWidget {
  const WhiteLabelScreen({super.key});

  @override
  ConsumerState<WhiteLabelScreen> createState() => _WhiteLabelScreenState();
}

class _WhiteLabelScreenState extends ConsumerState<WhiteLabelScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(whiteLabelServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(tenantsStreamProvider);

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
              title: const Text('White-Label Solution', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: _showCreateTenantDialog,
                ),
              ],
            ),
            tenantsAsync.when(
              data: (tenants) {
                if (tenants.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text('No tenants', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text('Create your first tenant', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildTenantCard(tenants[index]),
                    ),
                    childCount: tenants.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
              error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantCard(Tenant tenant) {
    final primaryColor = _parseColor(tenant.branding.primaryColor);
    final secondaryColor = _parseColor(tenant.branding.secondaryColor);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.business, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenant.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(tenant.domain, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: tenant.isActive,
                onChanged: (value) => ref.read(whiteLabelServiceProvider).toggleTenant(tenant.id),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branding', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('App Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(tenant.branding.appName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Features', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tenant.features.entries.map((entry) {
              return InkWell(
                onTap: () => ref.read(whiteLabelServiceProvider).toggleFeature(tenant.id, entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: entry.value ? AppColors.success.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: entry.value ? AppColors.success : AppColors.textSecondary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: entry.value ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: entry.value ? AppColors.success : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Users', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text(
                      NumberFormat('#,###').format(tenant.userCount),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Created', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text(
                      DateFormat('MMM dd, yyyy').format(tenant.createdAt),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditBrandingDialog(tenant),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Branding', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                onPressed: () => _deleteTenant(tenant.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  void _showCreateTenantDialog() {
    final nameController = TextEditingController();
    final domainController = TextEditingController();
    final appNameController = TextEditingController();
    final primaryColorController = TextEditingController(text: '#00F2FF');
    final secondaryColorController = TextEditingController(text: '#B388FF');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create Tenant', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: domainController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Domain',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: 'company.novaaccountant.com',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: appNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'App Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: primaryColorController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Primary Color',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: '#00F2FF',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secondaryColorController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Secondary Color',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: '#B388FF',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || domainController.text.isEmpty || appNameController.text.isEmpty) return;
              
              await ref.read(whiteLabelServiceProvider).createTenant(
                name: nameController.text,
                domain: domainController.text,
                appName: appNameController.text,
                primaryColor: primaryColorController.text,
                secondaryColor: secondaryColorController.text,
              );
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant created!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditBrandingDialog(Tenant tenant) {
    final appNameController = TextEditingController(text: tenant.branding.appName);
    final primaryColorController = TextEditingController(text: tenant.branding.primaryColor);
    final secondaryColorController = TextEditingController(text: tenant.branding.secondaryColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Branding', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: appNameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'App Name',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: primaryColorController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Primary Color',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: secondaryColorController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Secondary Color',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final branding = BrandConfig(
                appName: appNameController.text,
                primaryColor: primaryColorController.text,
                secondaryColor: secondaryColorController.text,
                logoUrl: tenant.branding.logoUrl,
              );
              
              await ref.read(whiteLabelServiceProvider).updateBranding(tenant.id, branding);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branding updated!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTenant(String tenantId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Tenant?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This will permanently delete the tenant.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(whiteLabelServiceProvider).deleteTenant(tenantId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant deleted')));
    }
  }
}
