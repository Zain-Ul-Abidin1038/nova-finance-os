import 'package:flutter_test/flutter_test.dart';
import 'package:nova_finance_os/features/sync/services/safe_layer_service.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';

void main() {
  group('Safe Layer Logic (SafeLayerService)', () {
    test('syncToSafeLayer returns success', () async {
      final service = SafeLayerService();
      final receipt = Receipt(total: 50, tax: 5, category: 'Test');
      
      final success = await service.syncToSafeLayer(receipt);
      expect(success, isTrue);
    });
  });
  
  group('Receipt Domain Model', () {
    test('Receipt model creates correctly', () {
      final receipt = Receipt(
        total: 142.50,
        tax: 10.0,
        category: 'Business Dinner',
        thoughtSignature: '[ThinkingLevel.high] Test signature',
      );
      
      expect(receipt.total, 142.50);
      expect(receipt.tax, 10.0);
      expect(receipt.category, 'Business Dinner');
      expect(receipt.thoughtSignature, contains('[ThinkingLevel.high]'));
    });
  });
}
