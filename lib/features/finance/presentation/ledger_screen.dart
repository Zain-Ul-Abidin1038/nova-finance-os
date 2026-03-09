import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';
import 'package:nova_finance_os/features/finance/domain/ledger_entry.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;
    final successColor = isDark ? AppColors.success : LightColors.success;
    final errorColor = Colors.red.shade400;

    // Watch the stream provider for reactive updates
    final ledgerEntriesAsync = ref.watch(ledgerEntriesProvider);

    return ledgerEntriesAsync.when(
      data: (ledgerEntries) {
        final receivables = ledgerEntries.where((e) => e.type == LedgerType.receivable && !e.isPaid).toList();
        final payables = ledgerEntries.where((e) => e.type == LedgerType.payable && !e.isPaid).toList();
        final totalReceivables = receivables.fold(0.0, (sum, entry) => sum + entry.amount);
        final totalPayables = payables.fold(0.0, (sum, entry) => sum + entry.amount);

        return Scaffold(
          backgroundColor: backgroundColor,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppColors.glassWhite 
                          : Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.glassBorder : LightColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.arrow_back, color: textColor, size: 20),
                  ),
                ),
              ),
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ledger',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Future payments tracker',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          gradient: LinearGradient(
                            colors: [
                              successColor.withValues(alpha: 0.15),
                              accentColor.withValues(alpha: 0.1),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_downward, color: successColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TO RECEIVE',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalReceivables.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: successColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          gradient: LinearGradient(
                            colors: [
                              errorColor.withValues(alpha: 0.15),
                              Colors.orange.withValues(alpha: 0.1),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_upward, color: errorColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TO PAY',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalPayables.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: errorColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, secondaryAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: secondaryTextColor,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        Tab(text: 'Receivables (${receivables.length})'),
                        Tab(text: 'Payables (${payables.length})'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLedgerList(receivables, LedgerType.receivable, successColor, textColor, secondaryTextColor, accentColor),
                      _buildLedgerList(payables, LedgerType.payable, errorColor, textColor, secondaryTextColor, accentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/chat'),
            backgroundColor: secondaryAccent,
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: const Text(
              'Add Entry',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text('Error: $error', style: TextStyle(color: textColor)),
        ),
      ),
    );
  }

  Widget _buildLedgerList(
    List<LedgerEntry> entries,
    LedgerType type,
    Color typeColor,
    Color textColor,
    Color secondaryTextColor,
    Color accentColor,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: secondaryTextColor, size: 48),
            const SizedBox(height: 16),
            Text(
              'No ${type == LedgerType.receivable ? 'receivables' : 'payables'} yet',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chat with Nova AI to track payments',
              style: TextStyle(
                color: secondaryTextColor.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[entries.length - 1 - index];
        final isOverdue = entry.dueDate != null && 
                          entry.dueDate!.isBefore(DateTime.now()) && 
                          !entry.isPaid;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: isOverdue 
                ? Colors.orange.withValues(alpha: 0.5)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        type == LedgerType.receivable 
                            ? Icons.arrow_downward 
                            : Icons.arrow_upward,
                        color: typeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.personOrCompany,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.description,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${type == LedgerType.receivable ? '+' : '-'}\$${entry.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (entry.dueDate != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isOverdue ? Colors.orange : secondaryTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(entry.dueDate!)}',
                        style: TextStyle(
                          color: isOverdue ? Colors.orange : secondaryTextColor,
                          fontSize: 11,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
