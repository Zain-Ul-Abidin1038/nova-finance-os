import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/crypto/services/crypto_service.dart';
import 'package:uuid/uuid.dart';

class CryptoDashboardScreen extends ConsumerWidget {
  const CryptoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cryptoAsync = ref.watch(cryptoPortfolioProvider);

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
              title: Row(
                children: [
                  const Text('Crypto Portfolio', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('₿', style: TextStyle(color: AppColors.neonTeal, fontSize: 16)),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.neonTeal),
                  onPressed: () => _showAddCryptoDialog(context, ref),
                ),
              ],
            ),
            cryptoAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('₿', style: TextStyle(fontSize: 64, color: AppColors.textMuted)),
                          const SizedBox(height: 16),
                          const Text('No crypto assets yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 24),
                          NovaActionButton(
                            label: 'Add Crypto',
                            icon: Icons.add,
                            onPressed: () => _showAddCryptoDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final totalValue = assets.fold(0.0, (sum, a) => sum + a.currentValue);
                final totalInvested = assets.fold(0.0, (sum, a) => sum + a.totalInvested);
                final totalPL = totalValue - totalInvested;
                final plPercentage = (totalPL / totalInvested) * 100;

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSummaryCard(totalValue, totalInvested, totalPL, plPercentage),
                      const SizedBox(height: 20),
                      _buildAssetsList(assets, ref),
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

  Widget _buildSummaryCard(double totalValue, double totalInvested, double totalPL, double plPercentage) {
    final isProfit = totalPL >= 0;
    return GlassCard(
      borderColor: isProfit ? AppColors.success.withOpacity(0.4) : AppColors.error.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Portfolio Value', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text('\$${totalValue.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invested', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${totalInvested.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('P/L', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    '${isProfit ? '+' : ''}\$${totalPL.toStringAsFixed(2)} (${plPercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(color: isProfit ? AppColors.success : AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsList(List assets, WidgetRef ref) {
    return Column(
      children: assets.map((asset) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.neonTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(child: Text(asset.symbol.substring(0, 1), style: const TextStyle(color: AppColors.neonTeal, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.symbol, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${asset.quantity.toStringAsFixed(4)} ${asset.symbol}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${asset.currentValue.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                  Text(
                    '${asset.isProfit ? '+' : ''}${asset.profitLossPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(color: asset.isProfit ? AppColors.success : AppColors.error, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  void _showAddCryptoDialog(BuildContext context, WidgetRef ref) {
    final symbolController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Add Crypto Asset', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Symbol (e.g., BTC)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
              ),
            ),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
              ),
            ),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Purchase Price (USD)',
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
              final symbol = symbolController.text.toUpperCase();
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;

              if (symbol.isNotEmpty && quantity > 0 && price > 0) {
                final service = ref.read(cryptoServiceProvider);
                final asset = CryptoAsset(
                  id: const Uuid().v4(),
                  userId: 'current_user',
                  symbol: symbol,
                  name: symbol,
                  quantity: quantity,
                  purchasePrice: price,
                  currentPrice: price,
                  purchaseDate: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await service.addCryptoAsset(asset);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.neonTeal)),
          ),
        ],
      ),
    );
  }
}
