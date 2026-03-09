import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/trace/services/nova_trace_service.dart';
import 'package:nova_finance_os/core/services/demo_data_service.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traceAsync = ref.watch(novaTraceProvider);
    final traceText = traceAsync.value ?? "Nova AI Active. Secure link established.";
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    // Watch finance streams for reactive updates
    final incomeAsync = ref.watch(incomeEntriesProvider);
    final expenseAsync = ref.watch(expenseEntriesProvider);
    final ledgerAsync = ref.watch(ledgerEntriesProvider);

    // Theme-aware colors
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final mutedTextColor = isDark ? AppColors.textMuted : LightColors.textMuted;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;
    final successColor = isDark ? AppColors.success : LightColors.success;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Dynamic Background
          _buildBackground(isDark, accentColor, secondaryAccent),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium App Bar
                _buildSliverAppBar(context, accentColor, textColor, secondaryTextColor, isDark),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      
                      // Hero Balance Card - Reactive
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: _buildReactiveHeroBalance(
                          incomeAsync, 
                          expenseAsync, 
                          ledgerAsync,
                          accentColor, 
                          textColor, 
                          secondaryTextColor, 
                          isDark
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Orchestration Label
                      FadeInUp(
                        duration: const Duration(milliseconds: 900),
                        child: _buildSectionLabel('SYSTEM ORCHESTRATION', secondaryTextColor),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Grid
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: _buildActionGrid(context, accentColor, secondaryAccent, secondaryTextColor),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Recent Activity Label
                      FadeInUp(
                        duration: const Duration(milliseconds: 1100),
                        child: _buildSectionLabel('SECURE VAULT ACTIVITY', secondaryTextColor),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Activity List - Reactive
                      _buildReactiveActivitySection(
                        context, 
                        incomeAsync, 
                        expenseAsync, 
                        ledgerAsync,
                        textColor, 
                        secondaryTextColor, 
                        mutedTextColor, 
                        accentColor, 
                        successColor, 
                        isDark
                      ),
                      
                      const SizedBox(height: 120), // Padding for trace widget
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Persistent Nova Trace
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 1200),
              child: GlassNotification(
                title: 'GHOST TRACE • LIVE REASONING',
                message: traceText,
                icon: Icons.biotech_outlined,
                accentColor: secondaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark, Color accentColor, Color secondaryAccent) {
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryAccent.withValues(alpha: 0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Color accentColor, Color textColor, Color secondaryTextColor, bool isDark) {
    final borderColor = isDark ? AppColors.glassBorder : LightColors.glassBorder;
    final surfaceColor = isDark ? AppColors.surfaceDark : LightColors.surface;
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GHOST ACCOUNTANT',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: surfaceColor,
                  child: Icon(Icons.person_outline, color: secondaryTextColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBalance(double balance, Color accentColor, Color textColor, Color secondaryTextColor, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AUDITED TAX DEDUCTIONS',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(Icons.shield_outlined, color: accentColor.withValues(alpha: 0.6), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                balance.toStringAsFixed(2),
                style: TextStyle(
                  color: textColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  'SAFE LAYER ACTIVE',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactiveHeroBalance(
    AsyncValue incomeAsync,
    AsyncValue expenseAsync,
    AsyncValue ledgerAsync,
    Color accentColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    // Combine all async values
    return incomeAsync.when(
      data: (incomeEntries) => expenseAsync.when(
        data: (expenseEntries) => ledgerAsync.when(
          data: (ledgerEntries) {
            final totalIncome = incomeEntries.fold(0.0, (sum, entry) => sum + entry.amount);
            final totalExpenses = expenseEntries.fold(0.0, (sum, entry) => sum + entry.amount);
            final balance = totalIncome - totalExpenses;
            
            return GlassCard(
              padding: const EdgeInsets.all(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT BALANCE',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Icon(Icons.account_balance_wallet_outlined, color: accentColor.withValues(alpha: 0.6), size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        balance.toStringAsFixed(2),
                        style: TextStyle(
                          color: balance >= 0 ? textColor : Colors.red.shade400,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INCOME',
                              style: TextStyle(
                                color: secondaryTextColor.withValues(alpha: 0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalIncome.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.green.shade400,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPENSES',
                              style: TextStyle(
                                color: secondaryTextColor.withValues(alpha: 0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalExpenses.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: accentColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE UPDATES',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildLoadingBalance(accentColor, textColor, secondaryTextColor),
          error: (error, stackTrace) => _buildHeroBalance(0.0, accentColor, textColor, secondaryTextColor, isDark),
        ),
        loading: () => _buildLoadingBalance(accentColor, textColor, secondaryTextColor),
        error: (error, stackTrace) => _buildHeroBalance(0.0, accentColor, textColor, secondaryTextColor, isDark),
      ),
      loading: () => _buildLoadingBalance(accentColor, textColor, secondaryTextColor),
      error: (error, stackTrace) => _buildHeroBalance(0.0, accentColor, textColor, secondaryTextColor, isDark),
    );
  }

  Widget _buildLoadingBalance(Color accentColor, Color textColor, Color secondaryTextColor) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: CircularProgressIndicator(color: accentColor, strokeWidth: 2),
      ),
    );
  }

  Widget _buildOldHeroBalance(double balance, Color accentColor, Color textColor, Color secondaryTextColor, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AUDITED TAX DEDUCTIONS',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(Icons.shield_outlined, color: accentColor.withValues(alpha: 0.6), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                balance.toStringAsFixed(2),
                style: TextStyle(
                  color: textColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  'SAFE LAYER ACTIVE',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color secondaryTextColor) {
    return Text(
      text,
      style: TextStyle(
        color: secondaryTextColor.withValues(alpha: 0.6),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, Color accentColor, Color secondaryAccent, Color secondaryTextColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            NeonButton(
              icon: Icons.arrow_downward,
              label: 'Income',
              onPressed: () => context.go('/income'),
              neonColor: accentColor,
            ),
            NeonButton(
              icon: Icons.arrow_upward,
              label: 'Expense',
              neonColor: Colors.red.shade400,
              onPressed: () => context.go('/expense'),
            ),
            NeonButton(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Ledger',
              neonColor: secondaryAccent,
              onPressed: () => context.go('/ledger'),
            ),
            NeonButton(
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              neonColor: Colors.orange.shade400,
              onPressed: () => context.go('/analytics'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // AI Features Row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/vision-nova'),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      secondaryAccent.withValues(alpha: 0.1),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.visibility_outlined, color: accentColor, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'VISION GHOST',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live Receipt Analysis',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/nova-navigator'),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  gradient: LinearGradient(
                    colors: [
                      secondaryAccent.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.smart_toy_outlined, color: secondaryAccent, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'GHOST NAVIGATOR',
                        style: TextStyle(
                          color: secondaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI Agent Actions',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Chat button - prominent
        GestureDetector(
          onTap: () => context.go('/chat'),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            gradient: LinearGradient(
              colors: [
                secondaryAccent.withValues(alpha: 0.2),
                accentColor.withValues(alpha: 0.1),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, color: secondaryAccent, size: 22),
                const SizedBox(width: 12),
                Text(
                  'CHAT WITH GHOST AI',
                  style: TextStyle(
                    color: secondaryAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: secondaryAccent, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactiveActivitySection(
    BuildContext context,
    AsyncValue incomeAsync,
    AsyncValue expenseAsync,
    AsyncValue ledgerAsync,
    Color textColor,
    Color secondaryTextColor,
    Color mutedTextColor,
    Color accentColor,
    Color successColor,
    bool isDark,
  ) {
    final surfaceLight = isDark ? AppColors.surfaceLight : LightColors.surfaceLight;
    final glassBorder = isDark ? AppColors.glassBorder : LightColors.glassBorder;

    return incomeAsync.when(
      data: (incomeEntries) => expenseAsync.when(
        data: (expenseEntries) => ledgerAsync.when(
          data: (ledgerEntries) {
            // Combine all entries with timestamps
            final allEntries = <Map<String, dynamic>>[];
            
            for (final income in incomeEntries) {
              allEntries.add({
                'type': 'income',
                'timestamp': income.timestamp,
                'amount': income.amount,
                'description': income.source,
                'category': income.category,
                'entry': income,
              });
            }
            
            for (final expense in expenseEntries) {
              allEntries.add({
                'type': 'expense',
                'timestamp': expense.timestamp,
                'amount': expense.amount,
                'description': expense.vendor,
                'category': expense.category,
                'entry': expense,
              });
            }
            
            for (final ledger in ledgerEntries) {
              allEntries.add({
                'type': ledger.type.toString().split('.').last,
                'timestamp': ledger.createdAt, // LedgerEntry uses createdAt instead of timestamp
                'amount': ledger.amount,
                'description': ledger.personOrCompany,
                'category': 'loan',
                'entry': ledger,
              });
            }
            
            // Sort by timestamp (most recent first)
            allEntries.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
            
            // Show empty state if no entries
            if (allEntries.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, color: mutedTextColor, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'NO RECENT RECORDS',
                        style: TextStyle(color: mutedTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start chatting with Nova AI to add transactions',
                        style: TextStyle(color: mutedTextColor, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Show latest 3 entries
            final recentEntries = allEntries.take(3).toList();
            
            return Column(
              children: recentEntries.map((entry) {
                final type = entry['type'] as String;
                final amount = entry['amount'] as double;
                final description = entry['description'] as String;
                final category = entry['category'] as String;
                
                IconData icon;
                Color iconColor;
                String prefix;
                
                switch (type) {
                  case 'income':
                    icon = Icons.arrow_downward;
                    iconColor = Colors.green.shade400;
                    prefix = '+';
                    break;
                  case 'expense':
                    icon = Icons.arrow_upward;
                    iconColor = Colors.red.shade400;
                    prefix = '-';
                    break;
                  case 'receivable':
                    icon = Icons.account_balance_wallet_outlined;
                    iconColor = accentColor;
                    prefix = '';
                    break;
                  case 'payable':
                    icon = Icons.account_balance_wallet_outlined;
                    iconColor = Colors.orange.shade400;
                    prefix = '';
                    break;
                  default:
                    icon = Icons.receipt_outlined;
                    iconColor = accentColor;
                    prefix = '';
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: glassBorder),
                          ),
                          child: Icon(icon, color: iconColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description.toUpperCase(),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category.toUpperCase(),
                                style: TextStyle(color: secondaryTextColor, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$prefix₹${amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: iconColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => GlassCard(
            padding: const EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2)),
          ),
          error: (error, stackTrace) => GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Error loading activity', style: TextStyle(color: mutedTextColor)),
            ),
          ),
        ),
        loading: () => GlassCard(
          padding: const EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2)),
        ),
        error: (error, stackTrace) => GlassCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('Error loading activity', style: TextStyle(color: mutedTextColor)),
          ),
        ),
      ),
      loading: () => GlassCard(
        padding: const EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2)),
      ),
      error: (error, stackTrace) => GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Error loading activity', style: TextStyle(color: mutedTextColor)),
        ),
      ),
    );
  }

  Widget _buildActivitySection(
    BuildContext context,
    WidgetRef ref,
    dynamic latestReceipt, 
    Color textColor, 
    Color secondaryTextColor, 
    Color mutedTextColor, 
    Color accentColor, 
    Color successColor,
    bool isDark,
  ) {
    final surfaceLight = isDark ? AppColors.surfaceLight : LightColors.surfaceLight;
    final glassBorder = isDark ? AppColors.glassBorder : LightColors.glassBorder;
    
    if (latestReceipt == null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, color: mutedTextColor, size: 40),
              const SizedBox(height: 12),
              Text(
                'NO RECENT RECORDS',
                style: TextStyle(color: mutedTextColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  debugPrint('[HomeScreen] Loading demo data...');
                  try {
                    final demoService = ref.read(demoDataServiceProvider);
                    await demoService.loadDemoData();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✓ Demo data loaded! Check Dashboard & Analytics'),
                          backgroundColor: successColor,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('[HomeScreen] Error loading demo data: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error loading demo data: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.science_outlined),
                label: const Text('LOAD DEMO DATA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Test with realistic receipts',
                style: TextStyle(color: mutedTextColor, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: glassBorder),
            ),
            child: Icon(Icons.receipt_outlined, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latestReceipt.vendor.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  latestReceipt.category,
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${latestReceipt.total.toStringAsFixed(2)}',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              Text(
                'AUDITED',
                style: TextStyle(color: successColor, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
