import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';

// Transaction state that holds all receipts
class TransactionState {
  final List<Receipt> receipts;
  final double totalBalance;
  final double totalDeductible;

  TransactionState({
    required this.receipts,
    required this.totalBalance,
    required this.totalDeductible,
  });

  TransactionState copyWith({
    List<Receipt>? receipts,
    double? totalBalance,
    double? totalDeductible,
  }) {
    return TransactionState(
      receipts: receipts ?? this.receipts,
      totalBalance: totalBalance ?? this.totalBalance,
      totalDeductible: totalDeductible ?? this.totalDeductible,
    );
  }
}

// Transaction notifier to manage state
class TransactionNotifier extends Notifier<TransactionState> {
  @override
  TransactionState build() {
    // Initialize with empty state - no phantom data
    return TransactionState(
      receipts: [],
      totalBalance: 0.0,
      totalDeductible: 0.0,
    );
  }

  void addReceipt(Receipt receipt) {
    final updatedReceipts = [...state.receipts, receipt];
    final totalBalance = updatedReceipts.fold<double>(
      0.0,
      (sum, r) => sum + r.total,
    );
    
    // Calculate deductible: (total - alcohol) * 0.5
    // For simplicity, we'll use 50% of total as deductible
    final totalDeductible = updatedReceipts.fold<double>(
      0.0,
      (sum, r) => sum + (r.total * 0.5),
    );

    state = TransactionState(
      receipts: updatedReceipts,
      totalBalance: totalBalance,
      totalDeductible: totalDeductible,
    );
  }

  void clearReceipts() {
    state = TransactionState(
      receipts: [],
      totalBalance: 0.0,
      totalDeductible: 0.0,
    );
  }

  // Get receipts by category
  List<Receipt> getReceiptsByCategory(String category) {
    return state.receipts.where((r) => r.category == category).toList();
  }

  // Get spending by category
  Map<String, double> getCategoryBreakdown() {
    final breakdown = <String, double>{};
    for (final receipt in state.receipts) {
      breakdown[receipt.category] = (breakdown[receipt.category] ?? 0.0) + receipt.total;
    }
    return breakdown;
  }

  // Calculate runway (months of operation based on current balance and burn rate)
  double calculateRunway(double monthlyBurn) {
    if (monthlyBurn <= 0) return 0.0;
    return state.totalDeductible / monthlyBurn;
  }
}

// Provider for transaction state
final transactionProvider = NotifierProvider<TransactionNotifier, TransactionState>(
  TransactionNotifier.new,
);
