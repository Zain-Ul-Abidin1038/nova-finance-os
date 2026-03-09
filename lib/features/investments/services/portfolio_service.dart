import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_live_nova_finance_os/features/investments/domain/investment.dart';
import 'package:nova_live_nova_finance_os/features/investments/domain/portfolio.dart';
import 'package:uuid/uuid.dart';

final portfolioServiceProvider = Provider((ref) => PortfolioService());

final portfolioProvider = StreamProvider<Portfolio?>((ref) {
  final service = ref.watch(portfolioServiceProvider);
  return service.watchPortfolio();
});

class PortfolioService {
  static const String _boxName = 'investments';
  Box<Investment>? _investmentsBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    safePrint('[PortfolioService] Initializing...');
    
    if (!Hive.isAdapterRegistered(21)) {
      // Hive.registerAdapter(InvestmentAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      // Hive.registerAdapter(InvestmentTypeAdapter());
    }

    _investmentsBox = await Hive.openBox<Investment>(_boxName);
    _initialized = true;
    safePrint('[PortfolioService] Initialized successfully');
  }

  Stream<Portfolio?> watchPortfolio() async* {
    await initialize();
    
    yield* _investmentsBox!.watch().map((_) {
      final investments = _investmentsBox!.values.toList();
      if (investments.isEmpty) return null;
      
      return Portfolio(
        id: 'default',
        userId: 'current_user',
        name: 'My Portfolio',
        investments: investments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<Portfolio?> getPortfolio() async {
    await initialize();
    
    final investments = _investmentsBox!.values.toList();
    if (investments.isEmpty) return null;
    
    return Portfolio(
      id: 'default',
      userId: 'current_user',
      name: 'My Portfolio',
      investments: investments,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> addInvestment(Investment investment) async {
    await initialize();
    await _investmentsBox!.put(investment.id, investment);
    safePrint('[PortfolioService] Investment added: ${investment.symbol}');
  }

  Future<void> updateInvestment(Investment investment) async {
    await initialize();
    await _investmentsBox!.put(investment.id, investment);
    safePrint('[PortfolioService] Investment updated: ${investment.symbol}');
  }

  Future<void> deleteInvestment(String id) async {
    await initialize();
    await _investmentsBox!.delete(id);
    safePrint('[PortfolioService] Investment deleted: $id');
  }

  Future<Investment> createInvestment({
    required InvestmentType type,
    required String symbol,
    required String name,
    required double quantity,
    required double purchasePrice,
    String? notes,
  }) async {
    final investment = Investment(
      id: const Uuid().v4(),
      userId: 'current_user',
      type: type,
      symbol: symbol,
      name: name,
      quantity: quantity,
      purchasePrice: purchasePrice,
      currentPrice: purchasePrice,
      purchaseDate: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: notes,
    );

    await addInvestment(investment);
    return investment;
  }

  Future<void> updatePrices(Map<String, double> prices) async {
    await initialize();
    
    for (final investment in _investmentsBox!.values) {
      final newPrice = prices[investment.symbol];
      if (newPrice != null && newPrice != investment.currentPrice) {
        final updated = investment.copyWith(
          currentPrice: newPrice,
          updatedAt: DateTime.now(),
        );
        await updateInvestment(updated);
      }
    }
    
    safePrint('[PortfolioService] Prices updated');
  }

  List<Investment> getInvestmentsByType(InvestmentType type) {
    return _investmentsBox!.values.where((i) => i.type == type).toList();
  }

  Future<void> clearAll() async {
    await initialize();
    await _investmentsBox!.clear();
    safePrint('[PortfolioService] All investments cleared');
  }
}
