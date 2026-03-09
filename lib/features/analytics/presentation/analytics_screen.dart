import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/analytics/widgets/runway_gauge.dart';
import 'package:nova_finance_os/features/analytics/services/pdf_export_service.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    // Watch reactive finance streams
    final incomeAsync = ref.watch(incomeEntriesProvider);
    final expenseAsync = ref.watch(expenseEntriesProvider);
    final ledgerAsync = ref.watch(ledgerEntriesProvider);
    
    // Theme-aware colors
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;
    final successColor = isDark ? AppColors.success : LightColors.success;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: incomeAsync.when(
          data: (incomeEntries) => expenseAsync.when(
            data: (expenseEntries) => ledgerAsync.when(
              data: (ledgerEntries) {
                final isEmpty = incomeEntries.isEmpty && expenseEntries.isEmpty;
                return isEmpty
                    ? _buildEmptyState(context, textColor, secondaryTextColor, secondaryAccent, accentColor, isDark)
                    : _buildReactiveAnalyticsContent(
                        context,
                        ref,
                        incomeEntries,
                        expenseEntries,
                        ledgerEntries,
                        textColor,
                        secondaryTextColor,
                        accentColor,
                        secondaryAccent,
                        successColor,
                        isDark,
                      );
              },
              loading: () => Center(child: CircularProgressIndicator(color: accentColor)),
              error: (_, __) => _buildEmptyState(context, textColor, secondaryTextColor, secondaryAccent, accentColor, isDark),
            ),
            loading: () => Center(child: CircularProgressIndicator(color: accentColor)),
            error: (_, __) => _buildEmptyState(context, textColor, secondaryTextColor, secondaryAccent, accentColor, isDark),
          ),
          loading: () => Center(child: CircularProgressIndicator(color: accentColor)),
          error: (_, __) => _buildEmptyState(context, textColor, secondaryTextColor, secondaryAccent, accentColor, isDark),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textColor, Color secondaryTextColor, Color secondaryAccent, Color accentColor, bool isDark) {
    return Stack(
      children: [
        // Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                secondaryAccent.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        // Empty State Content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          secondaryAccent.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: secondaryAccent.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: secondaryAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'No Data Yet',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start scanning receipts to see your analytics and insights',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/chat'),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Start Adding Transactions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactiveAnalyticsContent(
    BuildContext context,
    WidgetRef ref,
    List incomeEntries,
    List expenseEntries,
    List ledgerEntries,
    Color textColor,
    Color secondaryTextColor,
    Color accentColor,
    Color secondaryAccent,
    Color successColor,
    bool isDark,
  ) {
    // Calculate metrics
    final totalIncome = incomeEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    final totalExpenses = expenseEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    final balance = totalIncome - totalExpenses;
    
    // Calculate category breakdown from expenses
    final Map<String, double> categoryBreakdown = {};
    for (final expense in expenseEntries) {
      categoryBreakdown[expense.category] = 
          (categoryBreakdown[expense.category] ?? 0.0) + expense.amount;
    }
    
    // Calculate runway (months of expenses covered by current balance)
    final monthlyBurn = totalExpenses > 0 ? totalExpenses / 30 * 30 : 0.0; // Approximate monthly
    final runway = monthlyBurn > 0 ? balance / monthlyBurn : 0.0;
    
    return Stack(
      children: [
        // Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                secondaryAccent.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Main Content
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Actions Row
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.analytics_outlined,
                            color: secondaryAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analytics',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentColor, secondaryAccent],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () => _downloadReport(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Runway Gauge
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: RunwayGauge(
                  currentBalance: balance,
                  monthlyBurn: monthlyBurn,
                  predictedRunway: runway,
                ),
              ),
              const SizedBox(height: 32),

              // Spending Trends
              FadeInUp(
                duration: const Duration(milliseconds: 900),
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Spending Trends',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 200),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: expenseEntries.isEmpty
                      ? SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'No spending data yet',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 200,
                          child: LineChart(
                            _buildReactiveSpendingChart(expenseEntries, isDark, accentColor, secondaryAccent, secondaryTextColor),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Category Breakdown
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Category Breakdown',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FadeInUp(
                duration: const Duration(milliseconds: 1100),
                delay: const Duration(milliseconds: 400),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: categoryBreakdown.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No categories yet',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: categoryBreakdown.entries.map((entry) {
                            final percentage = totalExpenses > 0
                                ? entry.value / totalExpenses
                                : 0.0;
                            final color = _getCategoryColor(entry.key, isDark);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildCategoryRow(
                                entry.key,
                                entry.value,
                                percentage,
                                color,
                                textColor,
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // AI Insights
              if (incomeEntries.isNotEmpty || expenseEntries.isNotEmpty)
                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  delay: const Duration(milliseconds: 500),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: accentColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'AI Insights',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Total income: \$${totalIncome.toStringAsFixed(2)}\n'
                          '• Total expenses: \$${totalExpenses.toStringAsFixed(2)}\n'
                          '• Current balance: \$${balance.toStringAsFixed(2)}\n'
                          '• Expense entries: ${expenseEntries.length}\n'
                          '• Income entries: ${incomeEntries.length}\n'
                          '• Predicted runway: ${runway.toStringAsFixed(1)} months at current burn rate',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(String label, double amount, double percentage, Color color, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '\${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category, bool isDark) {
    final colors = isDark ? [
      AppColors.neonTeal,
      AppColors.softPurple,
      AppColors.success,
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCB77),
    ] : [
      LightColors.neonTeal,
      LightColors.softPurple,
      LightColors.success,
      const Color(0xFFE53935),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
    ];
    return colors[category.hashCode % colors.length];
  }

  Future<void> _downloadReport(BuildContext context, WidgetRef ref) async {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.neonTeal : LightColors.neonTeal,
        ),
      ),
    );

    try {
      final pdfService = ref.read(pdfExportServiceProvider);
      final filePath = await pdfService.generateAndSaveReport();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to: $filePath'),
            backgroundColor: isDark ? AppColors.success : LightColors.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: isDark ? AppColors.error : LightColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  LineChartData _buildReactiveSpendingChart(List expenseEntries, bool isDark, Color accentColor, Color secondaryAccent, Color secondaryTextColor) {
    // Generate spots from expense entries (last 7 entries)
    final spots = <FlSpot>[];
    if (expenseEntries.isNotEmpty) {
      final recentExpenses = expenseEntries.length > 7 
          ? expenseEntries.sublist(expenseEntries.length - 7) 
          : expenseEntries;
      
      for (var i = 0; i < recentExpenses.length; i++) {
        spots.add(FlSpot(i.toDouble(), recentExpenses[i].amount));
      }
    } else {
      spots.add(const FlSpot(0, 0));
    }

    final maxY = expenseEntries.isNotEmpty
        ? expenseEntries.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2
        : 200.0;

    final gridColor = isDark ? AppColors.glassBorder : LightColors.glassBorder;
    final chartBackground = isDark ? AppColors.background : LightColors.background;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: gridColor.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < spots.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '#${value.toInt() + 1}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 4,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '\$${value.toInt()}',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 6,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.8),
              secondaryAccent.withValues(alpha: 0.8),
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: accentColor,
                strokeWidth: 2,
                strokeColor: chartBackground,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.2),
                secondaryAccent.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
