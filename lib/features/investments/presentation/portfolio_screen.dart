import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/investments/services/portfolio_service.dart';
import 'package:nova_live_nova_finance_os/features/investments/domain/investment.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);

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
              title: const Text(
                'Investment Portfolio',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.neonTeal),
                  onPressed: () => _showAddInvestmentDialog(context, ref),
                ),
              ],
            ),
            portfolioAsync.when(
              data: (portfolio) {
                if (portfolio == null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.trending_up, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text(
                            'No investments yet',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Add Investment',
                            icon: Icons.add,
                            onPressed: () => _showAddInvestmentDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSummaryCard(portfolio),
                      const SizedBox(height: 20),
                      _buildInvestmentsList(portfolio.investments),
                    ]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.neonTeal)),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Text('Error: $error', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(portfolio) {
    return GlassCard(
      borderColor: portfolio.isProfit ? AppColors.success.withOpacity(0.4) : AppColors.error.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Value', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '\$${portfolio.currentValue.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invested', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${portfolio.totalInvested.toStringAsFixed(2)}', 
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('P/L', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    '${portfolio.isProfit ? '+' : ''}\$${portfolio.totalProfitLoss.toStringAsFixed(2)} (${portfolio.totalProfitLossPercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: portfolio.isProfit ? AppColors.success : AppColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList(List<Investment> investments) {
    return Column(
      children: investments.map((inv) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(inv.type.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.symbol, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(inv.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${inv.currentValue.toStringAsFixed(2)}', 
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                  Text(
                    '${inv.isProfit ? '+' : ''}${inv.profitLossPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(color: inv.isProfit ? AppColors.success : AppColors.error, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  void _showAddInvestmentDialog(BuildContext context, WidgetRef ref) {
    // Minimal dialog - full implementation would have form fields
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Add Investment', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Investment form coming soon', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.neonTeal)),
          ),
        ],
      ),
    );
  }
}
