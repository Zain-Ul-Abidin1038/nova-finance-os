import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/api/domain/api_key.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/api/services/api_service.dart';
import 'package:intl/intl.dart';

class ApiManagementScreen extends ConsumerStatefulWidget {
  const ApiManagementScreen({super.key});

  @override
  ConsumerState<ApiManagementScreen> createState() => _ApiManagementScreenState();
}

class _ApiManagementScreenState extends ConsumerState<ApiManagementScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(apiServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeysAsync = ref.watch(apiKeysStreamProvider);

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
              title: const Text('API Management', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: _showCreateApiKeyDialog,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('API Documentation', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Base URL: https://api.novaaccountant.com/v1',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Include API key in header: Authorization: Bearer YOUR_API_KEY',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            apiKeysAsync.when(
              data: (keys) {
                if (keys.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.key_off, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text('No API keys', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text('Create your first API key', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildApiKeyCard(keys[index]),
                    ),
                    childCount: keys.length,
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

  Widget _buildApiKeyCard(ApiKey apiKey) {
    final isExpired = apiKey.expiresAt != null && apiKey.expiresAt!.isBefore(DateTime.now());
    final daysUntilExpiry = apiKey.expiresAt?.difference(DateTime.now()).inDays ?? 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (apiKey.isActive && !isExpired) ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.key,
                  color: (apiKey.isActive && !isExpired) ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(apiKey.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'Created ${DateFormat('MMM dd, yyyy').format(apiKey.createdAt)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: apiKey.isActive,
                onChanged: (value) => ref.read(apiServiceProvider).toggleApiKey(apiKey.id),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    apiKey.key,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: apiKey.key));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API key copied!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: apiKey.permissions.map((perm) => Chip(
              label: Text(perm, style: const TextStyle(fontSize: 10)),
              backgroundColor: AppColors.primary.withOpacity(0.2),
              labelStyle: const TextStyle(color: AppColors.primary),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Requests', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text(
                      NumberFormat('#,###').format(apiKey.requestCount),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expires', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text(
                      isExpired ? 'Expired' : '$daysUntilExpiry days',
                      style: TextStyle(
                        color: isExpired ? AppColors.error : (daysUntilExpiry < 30 ? AppColors.warning : AppColors.textPrimary),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (apiKey.lastUsed != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Used', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text(
                        DateFormat('MMM dd').format(apiKey.lastUsed!),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
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
                  onPressed: () => _regenerateKey(apiKey.id),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                onPressed: () => _deleteKey(apiKey.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateApiKeyDialog() {
    final nameController = TextEditingController();
    final selectedPermissions = <String>{'read'};
    DateTime? expiresAt = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Create API Key', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Key Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Permissions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                CheckboxListTile(
                  title: const Text('Read', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  value: selectedPermissions.contains('read'),
                  onChanged: (value) => setState(() {
                    if (value!) selectedPermissions.add('read'); else selectedPermissions.remove('read');
                  }),
                  activeColor: AppColors.primary,
                ),
                CheckboxListTile(
                  title: const Text('Write', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  value: selectedPermissions.contains('write'),
                  onChanged: (value) => setState(() {
                    if (value!) selectedPermissions.add('write'); else selectedPermissions.remove('write');
                  }),
                  activeColor: AppColors.primary,
                ),
                CheckboxListTile(
                  title: const Text('Delete', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  value: selectedPermissions.contains('delete'),
                  onChanged: (value) => setState(() {
                    if (value!) selectedPermissions.add('delete'); else selectedPermissions.remove('delete');
                  }),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                await ref.read(apiServiceProvider).createApiKey(
                  name: nameController.text,
                  permissions: selectedPermissions.toList(),
                  expiresAt: expiresAt,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key created!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerateKey(String keyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Regenerate API Key?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This will invalidate the old key.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(apiServiceProvider).regenerateApiKey(keyId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key regenerated')));
    }
  }

  Future<void> _deleteKey(String keyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete API Key?', style: TextStyle(color: AppColors.textPrimary)),
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
      await ref.read(apiServiceProvider).deleteApiKey(keyId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key deleted')));
    }
  }
}
