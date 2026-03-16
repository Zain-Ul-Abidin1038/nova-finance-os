import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/features/nova_navigator/domain/purchase_record.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';
import 'package:nova_finance_os/features/finance/domain/expense_entry.dart';

final purchaseTrackingServiceProvider = Provider((ref) {
  return PurchaseTrackingService(
    financeService: ref.read(unifiedFinanceServiceProvider),
  );
});

class PurchaseTrackingService {
  static const String _boxName = 'purchase_records';
  final UnifiedFinanceService financeService;
  Box<Map>? _box;
  bool _initialized = false;

  PurchaseTrackingService({required this.financeService});

  Future<void> initialize() async {
    if (_initialized) return;
    _box = await Hive.openBox<Map>(_boxName);
    _initialized = true;
    safePrint('[PurchaseTracking] Initialized');
  }

  /// Record a new purchase when an external app is launched
  Future<PurchaseRecord> recordPurchase(PurchaseRecord record) async {
    await initialize();
    await _box?.put(record.id, _toMap(record));
    safePrint('[PurchaseTracking] Recorded: ${record.appName} - ${record.taskDescription}');

    // Auto-record expense if amount is known
    if (record.estimatedAmount != null && record.estimatedAmount! > 0) {
      await _autoRecordExpense(record);
    }

    return record;
  }

  /// Auto-record the purchase as an expense in the finance ledger
  Future<void> _autoRecordExpense(PurchaseRecord record) async {
    final amount = record.actualAmount ?? record.estimatedAmount;
    if (amount == null || amount <= 0) return;

    try {
      await financeService.initialize();
      final expense = ExpenseEntry.create(
        amount: amount,
        vendor: record.appName,
        description: '${record.taskDescription} (via ${record.appName})',
        category: record.category,
        notes: 'Auto-recorded by NovaNavigator',
      );
      await financeService.addExpense(expense);

      // Update record as expense-recorded
      final updated = record.copyWith(
        expenseRecorded: true,
        status: 'recorded',
      );
      await _box?.put(record.id, _toMap(updated));

      safePrint('[PurchaseTracking] Auto-recorded expense: ₹${amount.toStringAsFixed(0)} to ${record.appName}');
    } catch (e) {
      safePrint('[PurchaseTracking] Failed to auto-record expense: $e');
    }
  }

  /// Update a purchase with actual amount (user comes back and enters it)
  Future<void> updateAmount(String recordId, double actualAmount) async {
    await initialize();
    final raw = _box?.get(recordId);
    if (raw == null) return;

    final record = _fromMap(Map<String, dynamic>.from(raw));
    final updated = record.copyWith(
      actualAmount: actualAmount,
      completedAt: DateTime.now(),
      status: 'recorded',
    );
    await _box?.put(recordId, _toMap(updated));

    // Record expense if not already done
    if (!record.expenseRecorded) {
      await _autoRecordExpense(updated);
    }
  }

  /// Get all purchase records
  Future<List<PurchaseRecord>> getAllRecords() async {
    await initialize();
    return _box?.values
            .map((raw) => _fromMap(Map<String, dynamic>.from(raw)))
            .toList() ??
        [];
  }

  /// Get records pending amount entry
  Future<List<PurchaseRecord>> getPendingRecords() async {
    final all = await getAllRecords();
    return all.where((r) => r.status == 'pending_amount').toList();
  }

  /// Get records by app
  Future<List<PurchaseRecord>> getRecordsByApp(String appId) async {
    final all = await getAllRecords();
    return all.where((r) => r.appId == appId).toList();
  }

  /// Get total spent via external apps
  Future<double> getTotalExternalSpending() async {
    final all = await getAllRecords();
    return all.fold(0.0, (sum, r) {
      final amount = r.actualAmount ?? r.estimatedAmount ?? 0;
      return sum + amount;
    });
  }

  /// Get spending by app category
  Future<Map<String, double>> getSpendingByCategory() async {
    final all = await getAllRecords();
    final Map<String, double> result = {};
    for (final r in all) {
      final amount = r.actualAmount ?? r.estimatedAmount ?? 0;
      result[r.category] = (result[r.category] ?? 0) + amount;
    }
    return result;
  }

  // Serialization helpers (simple Map-based since Hive adapters are commented out)
  Map<String, dynamic> _toMap(PurchaseRecord r) => {
        'id': r.id,
        'appId': r.appId,
        'appName': r.appName,
        'category': r.category,
        'taskDescription': r.taskDescription,
        'estimatedAmount': r.estimatedAmount,
        'actualAmount': r.actualAmount,
        'launchedAt': r.launchedAt.toIso8601String(),
        'completedAt': r.completedAt?.toIso8601String(),
        'status': r.status,
        'expenseRecorded': r.expenseRecorded,
        'notes': r.notes,
      };

  PurchaseRecord _fromMap(Map<String, dynamic> m) => PurchaseRecord(
        id: m['id'] ?? '',
        appId: m['appId'] ?? '',
        appName: m['appName'] ?? '',
        category: m['category'] ?? 'other',
        taskDescription: m['taskDescription'] ?? '',
        estimatedAmount: (m['estimatedAmount'] as num?)?.toDouble(),
        actualAmount: (m['actualAmount'] as num?)?.toDouble(),
        launchedAt: DateTime.tryParse(m['launchedAt'] ?? '') ?? DateTime.now(),
        completedAt: m['completedAt'] != null
            ? DateTime.tryParse(m['completedAt'])
            : null,
        status: m['status'] ?? 'launched',
        expenseRecorded: m['expenseRecorded'] ?? false,
        notes: m['notes'],
      );
}
