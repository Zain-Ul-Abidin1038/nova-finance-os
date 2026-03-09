import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final receiptRepositoryProvider = Provider((ref) => ReceiptRepository());

class ReceiptRepository {
  static const String _boxName = 'receipts';
  Box<Receipt>? _box;

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ReceiptAdapter());
    }
    _box = await Hive.openBox<Receipt>(_boxName);
  }

  Future<void> save(Receipt receipt) async {
    await _box?.put(receipt.id, receipt);
    safePrint('[ReceiptRepo] Saved receipt: ${receipt.id}');
  }

  Future<void> update(Receipt receipt) async {
    await _box?.put(receipt.id, receipt);
    safePrint('[ReceiptRepo] Updated receipt: ${receipt.id}');
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
    safePrint('[ReceiptRepo] Deleted receipt: $id');
  }

  Receipt? getById(String id) {
    return _box?.get(id);
  }

  List<Receipt> getAll() {
    return _box?.values.toList() ?? [];
  }

  List<Receipt> getPendingReview() {
    return _box?.values
        .where((r) => r.requiresReview && !r.isApproved)
        .toList() ?? [];
  }

  List<Receipt> getApproved() {
    return _box?.values
        .where((r) => r.isApproved)
        .toList() ?? [];
  }

  double getTotalDeductions() {
    return _box?.values
        .where((r) => r.isApproved)
        .fold(0.0, (sum, r) => sum + r.deductibleAmount) ?? 0.0;
  }

  Map<String, double> getDeductionsByCategory() {
    final receipts = _box?.values.where((r) => r.isApproved) ?? [];
    final Map<String, double> result = {};

    for (final receipt in receipts) {
      result[receipt.category] = 
          (result[receipt.category] ?? 0.0) + receipt.deductibleAmount;
    }

    return result;
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
