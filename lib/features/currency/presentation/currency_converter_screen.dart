import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/currency/services/currency_service.dart';
import 'package:nova_live_nova_finance_os/features/currency/domain/currency_rate.dart';

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends ConsumerState<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCurrency();
  }

  Future<void> _initializeCurrency() async {
    final service = ref.read(currencyServiceProvider);
    await service.initialize();
    
    // Update rates if needed
    if (service.needsUpdate()) {
      await ref.read(currencyConverterProvider.notifier).updateRates();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final converterState = ref.watch(currencyConverterProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final availableCurrencies = currencyService.getAllRates();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Currency Converter',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: converterState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neonTeal,
                          ),
                        )
                      : const Icon(Icons.refresh, color: AppColors.neonTeal),
                  onPressed: converterState.isLoading
                      ? null
                      : () => ref.read(currencyConverterProvider.notifier).updateRates(),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Last Update Info
                  _buildLastUpdateInfo(currencyService),
                  const SizedBox(height: 24),

                  // Amount Input
                  _buildAmountInput(converterState),
                  const SizedBox(height: 24),

                  // From Currency
                  _buildCurrencySelector(
                    label: 'From',
                    selectedCurrency: converterState.fromCurrency,
                    currencies: availableCurrencies,
                    onChanged: (currency) {
                      ref.read(currencyConverterProvider.notifier).setFromCurrency(currency);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Swap Button
                  _buildSwapButton(),
                  const SizedBox(height: 16),

                  // To Currency
                  _buildCurrencySelector(
                    label: 'To',
                    selectedCurrency: converterState.toCurrency,
                    currencies: availableCurrencies,
                    onChanged: (currency) {
                      ref.read(currencyConverterProvider.notifier).setToCurrency(currency);
                    },
                  ),
                  const SizedBox(height: 32),

                  // Result
                  _buildResult(converterState, currencyService),
                  const SizedBox(height: 32),

                  // Exchange Rate Info
                  _buildExchangeRateInfo(converterState, currencyService),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdateInfo(CurrencyService service) {
    final lastUpdate = service.getLastUpdateTime();
    if (lastUpdate == null) return const SizedBox.shrink();

    final timeAgo = _getTimeAgo(lastUpdate);

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated $timeAgo',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(CurrencyConverterState state) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 32,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              ref.read(currencyConverterProvider.notifier).setAmount(amount);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String label,
    required String selectedCurrency,
    required List<CurrencyRate> currencies,
    required Function(String) onChanged,
  }) {
    final selectedRate = currencies.firstWhere(
      (c) => c.code == selectedCurrency,
      orElse: () => currencies.first,
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showCurrencyPicker(
              context,
              currencies,
              selectedCurrency,
              onChanged,
            ),
            child: Row(
              children: [
                Text(
                  selectedRate.flag ?? '🌍',
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedRate.code,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedRate.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.neonTeal,
                  size: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonTeal.withOpacity(0.2),
              AppColors.softPurple.withOpacity(0.2),
            ],
          ),
          border: Border.all(
            color: AppColors.neonTeal.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonTeal.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.swap_vert,
            color: AppColors.neonTeal,
          ),
          onPressed: () {
            ref.read(currencyConverterProvider.notifier).swapCurrencies();
          },
        ),
      ),
    );
  }

  Widget _buildResult(CurrencyConverterState state, CurrencyService service) {
    if (state.convertedAmount == null) {
      return const SizedBox.shrink();
    }

    final formattedAmount = service.formatAmount(
      amount: state.convertedAmount!,
      currencyCode: state.toCurrency,
      decimals: 2,
    );

    return GlassCard(
      borderColor: AppColors.neonTeal.withOpacity(0.4),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.neonTeal.withOpacity(0.1),
          Colors.transparent,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Converted Amount',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formattedAmount,
            style: const TextStyle(
              color: AppColors.neonTeal,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateInfo(CurrencyConverterState state, CurrencyService service) {
    final fromRate = service.getRate(state.fromCurrency);
    final toRate = service.getRate(state.toCurrency);

    if (fromRate == null || toRate == null) {
      return const SizedBox.shrink();
    }

    final rate = toRate.exchangeRate / fromRate.exchangeRate;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '1 ${state.fromCurrency} = ${rate.toStringAsFixed(4)} ${state.toCurrency}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    List<CurrencyRate> currencies,
    String selectedCurrency,
    Function(String) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Currency',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  final isSelected = currency.code == selectedCurrency;

                  return ListTile(
                    leading: Text(
                      currency.flag ?? '🌍',
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      currency.code,
                      style: TextStyle(
                        color: isSelected ? AppColors.neonTeal : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      currency.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.neonTeal)
                        : null,
                    onTap: () {
                      onChanged(currency.code);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
