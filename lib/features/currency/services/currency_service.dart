import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/currency/domain/currency_rate.dart';

final currencyServiceProvider = Provider((ref) => CurrencyService());

/// Currency Service - Real-time exchange rates and conversion
/// 
/// Features:
/// - Real-time exchange rates from multiple APIs
/// - Offline caching with Hive
/// - Automatic rate updates
/// - Multi-currency conversion
class CurrencyService {
  static const String _boxName = 'currency_rates';
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';
  static const String _fallbackApiUrl = 'https://open.er-api.com/v6/latest/USD';
  
  Box<CurrencyRate>? _ratesBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    safePrint('[CurrencyService] Initializing...');
    
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(20)) {
      // Hive.registerAdapter(CurrencyRateAdapter());
    }

    // Open box
    _ratesBox = await Hive.openBox<CurrencyRate>(_boxName);

    // Load initial rates if empty
    if (_ratesBox!.isEmpty) {
      await updateRates();
    }

    _initialized = true;
    safePrint('[CurrencyService] Initialized successfully');
  }

  /// Update exchange rates from API
  Future<bool> updateRates() async {
    try {
      safePrint('[CurrencyService] Updating exchange rates...');

      // Try primary API
      http.Response? response;
      try {
        response = await http.get(Uri.parse(_apiUrl)).timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        safePrint('[CurrencyService] Primary API failed, trying fallback...');
        response = await http.get(Uri.parse(_fallbackApiUrl)).timeout(
          const Duration(seconds: 10),
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final timestamp = DateTime.now();

        // Save rates to Hive
        for (final currency in PopularCurrencies.currencies) {
          final code = currency['code']!;
          final rate = rates[code] as num? ?? 1.0;

          final currencyRate = CurrencyRate(
            code: code,
            name: currency['name']!,
            symbol: currency['symbol']!,
            exchangeRate: rate.toDouble(),
            updatedAt: timestamp,
            flag: currency['flag'],
          );

          await _ratesBox?.put(code, currencyRate);
        }

        safePrint('[CurrencyService] Rates updated successfully');
        return true;
      } else {
        safePrint('[CurrencyService] API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      safePrint('[CurrencyService] Update error: $e');
      return false;
    }
  }

  /// Get exchange rate for a currency
  CurrencyRate? getRate(String currencyCode) {
    return _ratesBox?.get(currencyCode);
  }

  /// Get all available currencies
  List<CurrencyRate> getAllRates() {
    return _ratesBox?.values.toList() ?? [];
  }

  /// Convert amount from one currency to another
  double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = getRate(fromCurrency);
    final toRate = getRate(toCurrency);

    if (fromRate == null || toRate == null) {
      safePrint('[CurrencyService] Currency rate not found');
      return amount;
    }

    // Convert to USD first, then to target currency
    final amountInUSD = amount / fromRate.exchangeRate;
    final convertedAmount = amountInUSD * toRate.exchangeRate;

    return convertedAmount;
  }

  /// Format amount with currency symbol
  String formatAmount({
    required double amount,
    required String currencyCode,
    int decimals = 2,
  }) {
    final rate = getRate(currencyCode);
    if (rate == null) {
      return '${amount.toStringAsFixed(decimals)} $currencyCode';
    }

    return '${rate.symbol}${amount.toStringAsFixed(decimals)}';
  }

  /// Check if rates need update (older than 24 hours)
  bool needsUpdate() {
    final rates = getAllRates();
    if (rates.isEmpty) return true;

    return rates.any((rate) => rate.isStale());
  }

  /// Get last update time
  DateTime? getLastUpdateTime() {
    final rates = getAllRates();
    if (rates.isEmpty) return null;

    return rates.first.updatedAt;
  }

  /// Clear all cached rates
  Future<void> clearCache() async {
    await _ratesBox?.clear();
    safePrint('[CurrencyService] Cache cleared');
  }
}

/// Currency Converter Widget Provider
final currencyConverterProvider = StateNotifierProvider<CurrencyConverterNotifier, CurrencyConverterState>(
  (ref) => CurrencyConverterNotifier(ref.read(currencyServiceProvider)),
);

class CurrencyConverterState {
  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final double? convertedAmount;
  final bool isLoading;

  CurrencyConverterState({
    this.amount = 0.0,
    this.fromCurrency = 'USD',
    this.toCurrency = 'INR',
    this.convertedAmount,
    this.isLoading = false,
  });

  CurrencyConverterState copyWith({
    double? amount,
    String? fromCurrency,
    String? toCurrency,
    double? convertedAmount,
    bool? isLoading,
  }) {
    return CurrencyConverterState(
      amount: amount ?? this.amount,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CurrencyConverterNotifier extends StateNotifier<CurrencyConverterState> {
  final CurrencyService _currencyService;

  CurrencyConverterNotifier(this._currencyService) : super(CurrencyConverterState());

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
    _convert();
  }

  void setFromCurrency(String currency) {
    state = state.copyWith(fromCurrency: currency);
    _convert();
  }

  void setToCurrency(String currency) {
    state = state.copyWith(toCurrency: currency);
    _convert();
  }

  void swapCurrencies() {
    state = state.copyWith(
      fromCurrency: state.toCurrency,
      toCurrency: state.fromCurrency,
    );
    _convert();
  }

  void _convert() {
    if (state.amount == 0) {
      state = state.copyWith(convertedAmount: 0.0);
      return;
    }

    final converted = _currencyService.convert(
      amount: state.amount,
      fromCurrency: state.fromCurrency,
      toCurrency: state.toCurrency,
    );

    state = state.copyWith(convertedAmount: converted);
  }

  Future<void> updateRates() async {
    state = state.copyWith(isLoading: true);
    await _currencyService.updateRates();
    state = state.copyWith(isLoading: false);
    _convert();
  }
}
