import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';
import 'package:nova_finance_os/features/finance/domain/expense_entry.dart';

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final errorColor = Colors.red.shade400;

    // Watch the stream provider for reactive updates
    final expenseEntriesAsync = ref.watch(expenseEntriesProvider);
    
    return expenseEntriesAsync.when(
      data: (expenseEntries) {
        final totalExpenses = expenseEntries.fold(0.0, (sum, entry) => sum + entry.amount);
        final categoryBreakdown = _calculateCategoryBreakdown(expenseEntries);
        return _buildContent(context, expenseEntries, totalExpenses, categoryBreakdown, backgroundColor, textColor, secondaryTextColor, accentColor, errorColor, isDark);
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

  Map<String, double> _calculateCategoryBreakdown(List<ExpenseEntry> expenses) {
    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    return categoryTotals;
  }

  Widget _buildContent(
    BuildContext context,
    List<ExpenseEntry> expenseEntries,
    double totalExpenses,
    Map<String, double> categoryBreakdown,
    Color backgroundColor,
    Color textColor,
    Color secondaryTextColor,
    Color accentColor,
    Color errorColor,
    bool isDark,
  ) {
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
              'Expenses',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'All outgoing amounts',
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
            
            // Total Expenses Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                gradient: LinearGradient(
                  colors: [
                    errorColor.withValues(alpha: 0.15),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL EXPENSES',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${totalExpenses.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: errorColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward, color: errorColor, size: 28),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category Breakdown
            if (categoryBreakdown.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BY CATEGORY',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...categoryBreakdown.entries.map((entry) {
                        final percentage = (entry.value / totalExpenses * 100).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${entry.value.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Expense List
            Expanded(
              child: expenseEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, color: secondaryTextColor, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses recorded yet',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chat with Nova AI to add expenses',
                            style: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: expenseEntries.length,
                      itemBuilder: (context, index) {
                        final entry = expenseEntries[expenseEntries.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: errorColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.arrow_upward, color: errorColor, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.vendor,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
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
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy • HH:mm').format(entry.timestamp),
                                        style: TextStyle(
                                          color: secondaryTextColor.withValues(alpha: 0.6),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '-\$${entry.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: errorColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        entry.category.toUpperCase(),
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/chat'),
        backgroundColor: errorColor,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text(
          'Add Expense',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
