import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:nova_finance_os/features/receipts/services/hive_transaction_provider.dart';

final demoDataServiceProvider = Provider((ref) => DemoDataService(ref));

/// Demo Data Service (AWS Amplify removed)
class DemoDataService {
  final Ref _ref;

  DemoDataService(this._ref);

  Future<void> loadDemoData() async {
    final transactionNotifier = _ref.read(hiveTransactionProvider.notifier);

    // Create demo receipts
    final demoReceipts = [
      Receipt(
        id: 'demo-1',
        vendor: 'Starbucks',
        total: 15.50,
        tax: 1.24,
        category: 'Business Meal',
        deductibleAmount: 7.75,
        alcoholAmount: 0.0,
        thoughtSignature: 'demo-receipt-1',
        thoughtSummary: 'Demo data - Coffee meeting',
        currency: 'USD',
        confidence: 0.95,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        requiresReview: false,
      ),
      Receipt(
        id: 'demo-2',
        vendor: 'Office Depot',
        total: 89.99,
        tax: 7.20,
        category: 'Office Supplies',
        deductibleAmount: 89.99,
        alcoholAmount: 0.0,
        thoughtSignature: 'demo-receipt-2',
        thoughtSummary: 'Demo data - Office supplies',
        currency: 'USD',
        confidence: 0.98,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        requiresReview: false,
      ),
      Receipt(
        id: 'demo-3',
        vendor: 'Uber',
        total: 32.50,
        tax: 2.60,
        category: 'Transportation',
        deductibleAmount: 32.50,
        alcoholAmount: 0.0,
        thoughtSignature: 'demo-receipt-3',
        thoughtSummary: 'Demo data - Client meeting transport',
        currency: 'USD',
        confidence: 0.92,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        requiresReview: false,
      ),
    ];

    // Add demo receipts to local storage
    for (final receipt in demoReceipts) {
      await transactionNotifier.addReceipt(receipt);
    }
  }

  Future<void> clearDemoData() async {
    final transactionNotifier = _ref.read(hiveTransactionProvider.notifier);
    await transactionNotifier.clearReceipts();
  }
}
