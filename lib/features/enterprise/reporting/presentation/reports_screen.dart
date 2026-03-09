import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/reporting/domain/report.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/reporting/services/report_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType? _filterType;

  @override
  void initState() {
    super.initState();
    ref.read(reportServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsStreamProvider);

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
              title: const Text('Advanced Reports', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: _showGenerateReportDialog,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('Expense', ReportType.expense),
                      _buildFilterChip('Income', ReportType.income),
                      _buildFilterChip('P&L', ReportType.profitLoss),
                      _buildFilterChip('Cash Flow', ReportType.cashFlow),
                      _buildFilterChip('Tax', ReportType.tax),
                    ],
                  ),
                ),
              ),
            ),
            reportsAsync.when(
              data: (reports) {
                final filtered = _filterType == null ? reports : ref.read(reportServiceProvider).filterByType(_filterType);
                
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics_outlined, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text('No reports yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text('Generate your first report', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildReportCard(filtered[index]),
                    ),
                    childCount: filtered.length,
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

  Widget _buildFilterChip(String label, ReportType? type) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _filterType = selected ? type : null),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.3),
        labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary),
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getReportColor(report.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getReportIcon(report.type), color: _getReportColor(report.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${DateFormat('MMM dd').format(report.startDate)} - ${DateFormat('MMM dd, yyyy').format(report.endDate)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReportColor(report.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  report.type.name.toUpperCase(),
                  style: TextStyle(color: _getReportColor(report.type), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildReportData(report),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () => _deleteReport(report.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReportData(Report report) {
    final widgets = <Widget>[];
    report.data.forEach((key, value) {
      if (value is num) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                Text(
                  key.contains('percentage') || key.contains('Margin') ? '${value.toStringAsFixed(1)}%' : '\$${value.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }
    });
    return widgets;
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.expense:
        return AppColors.error;
      case ReportType.income:
        return AppColors.success;
      case ReportType.profitLoss:
        return AppColors.primary;
      case ReportType.cashFlow:
        return AppColors.accent;
      case ReportType.tax:
        return AppColors.warning;
      case ReportType.custom:
        return AppColors.textSecondary;
    }
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.expense:
        return Icons.trending_down;
      case ReportType.income:
        return Icons.trending_up;
      case ReportType.profitLoss:
        return Icons.analytics;
      case ReportType.cashFlow:
        return Icons.water_drop;
      case ReportType.tax:
        return Icons.receipt_long;
      case ReportType.custom:
        return Icons.dashboard_customize;
    }
  }

  void _showGenerateReportDialog() {
    final nameController = TextEditingController();
    ReportType selectedType = ReportType.expense;
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Generate Report', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Report Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportType>(
                  value: selectedType,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  items: ReportType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate), style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  title: const Text('End Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(endDate), style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => endDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                await ref.read(reportServiceProvider).generateReport(
                  name: nameController.text,
                  type: selectedType,
                  startDate: startDate,
                  endDate: endDate,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report generated!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Report?', style: TextStyle(color: AppColors.textPrimary)),
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
      await ref.read(reportServiceProvider).deleteReport(reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted')));
      }
    }
  }
}
