import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';

// Transaction state that holds all receipts
class TransactionState {
  final List<Receipt> receipts;
  final double totalBalance;
  final double totalDeductible;
  final bool isSyncing;
  final DateTime? lastSyncTime;

  TransactionState({
    required this.receipts,
    required this.totalBalance,
    required this.totalDeductible,
    this.isSyncing = false,
    this.lastSyncTime,
  });

  TransactionState copyWith({
    List<Receipt>? receipts,
    double? totalBalance,
    double? totalDeductible,
    bool? isSyncing,
    DateTime? lastSyncTime,
  }) {
    return TransactionState(
      receipts: receipts ?? this.receipts,
      totalBalance: totalBalance ?? this.totalBalance,
      totalDeductible: totalDeductible ?? this.totalDeductible,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// Local-Only Transaction Provider
/// - Speed Layer: Hive (local, fast, offline-first)
/// - Cloud sync removed (Firestore removed)
class HiveTransactionNotifier extends Notifier<TransactionState> {
  static const String _boxName = 'receipts';
  late Box<Receipt> _box;

  @override
  TransactionState build() {
    _initializeBox();
    return TransactionState(
      receipts: [],
      totalBalance: 0.0,
      totalDeductible: 0.0,
    );
  }

  Future<void> _initializeBox() async {
    try {
      _box = await Hive.openBox<Receipt>(_boxName);
      print('[Speed Layer] Hive box opened: ${_box.length} receipts');
      _loadReceipts();
    } catch (e) {
      print('[Speed Layer] ERROR initializing Hive box: $e');
    }
  }

  void _loadReceipts() {
    final receipts = _box.values.toList();
    final totalBalance = receipts.fold<double>(0.0, (sum, r) => sum + r.total);
    final totalDeductible = receipts.fold<double>(0.0, (sum, r) => sum + r.deductibleAmount);

    state = TransactionState(
      receipts: receipts,
      totalBalance: totalBalance,
      totalDeductible: totalDeductible,
      lastSyncTime: state.lastSyncTime,
    );
    
    print('[Speed Layer] Loaded ${receipts.length} receipts. Total: \$totalBalance, Deductible: \$totalDeductible');
  }

  /// Add receipt to local storage (Hive)
  Future<void> addReceipt(Receipt receipt) async {
    try {
      print('[Local Storage] Adding receipt ${receipt.id}...');
      
      // Save to Hive
      await _box.put(receipt.id, receipt);
      print('[Speed Layer] ✓ Receipt saved to Hive');
      
      // Update local state immediately for UI responsiveness
      final updatedReceipts = _box.values.toList();
      final totalBalance = updatedReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
      final totalDeductible = updatedReceipts.fold<double>(0.0, (sum, r) => sum + r.deductibleAmount);

      state = TransactionState(
        receipts: updatedReceipts,
        totalBalance: totalBalance,
        totalDeductible: totalDeductible,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      print('[Local Storage] ERROR adding receipt: $e');
      rethrow;
    }
  }

  /// Delete receipt from local storage
  Future<void> deleteReceipt(String id) async {
    try {
      print('[Local Storage] Deleting receipt $id...');
      
      // Delete from Hive
      await _box.delete(id);
      print('[Speed Layer] ✓ Receipt deleted from Hive');
      
      // Update local state
      _loadReceipts();
    } catch (e) {
      print('[Local Storage] ERROR deleting receipt: $e');
      rethrow;
    }
  }

  /// Clear all receipts from local storage
  Future<void> clearReceipts() async {
    try {
      print('[Local Storage] Clearing all receipts...');
      
      await _box.clear();
      state = TransactionState(
        receipts: [],
        totalBalance: 0.0,
        totalDeductible: 0.0,
        lastSyncTime: DateTime.now(),
      );
      
      print('[Speed Layer] ✓ All receipts cleared from Hive');
    } catch (e) {
      print('[Local Storage] ERROR clearing receipts: $e');
      rethrow;
    }
  }

  /// Get receipt by ID
  Receipt? getReceipt(String id) {
    return _box.get(id);
  }

  /// Get all receipts
  List<Receipt> getAllReceipts() {
    return _box.values.toList();
  }

  /// Get receipts by category
  List<Receipt> getReceiptsByCategory(String category) {
    return _box.values.where((r) => r.category == category).toList();
  }

  /// Get receipts by date range
  List<Receipt> getReceiptsByDateRange(DateTime start, DateTime end) {
    return _box.values.where((r) {
      return r.timestamp.isAfter(start) && r.timestamp.isBefore(end);
    }).toList();
  }

  /// Get total for a specific category
  double getTotalByCategory(String category) {
    return _box.values
        .where((r) => r.category == category)
        .fold<double>(0.0, (sum, r) => sum + r.total);
  }

  /// Get total deductible for a specific category
  double getDeductibleByCategory(String category) {
    return _box.values
        .where((r) => r.category == category)
        .fold<double>(0.0, (sum, r) => sum + r.deductibleAmount);
  }

  /// Get receipts count
  int getReceiptsCount() {
    return _box.length;
  }

  /// Check if receipt exists
  bool hasReceipt(String id) {
    return _box.containsKey(id);
  }

  /// Update receipt
  Future<void> updateReceipt(Receipt receipt) async {
    try {
      await _box.put(receipt.id, receipt);
      _loadReceipts();
      print('[Speed Layer] ✓ Receipt updated');
    } catch (e) {
      print('[Local Storage] ERROR updating receipt: $e');
      rethrow;
    }
  }

  /// Get receipts sorted by date (newest first)
  List<Receipt> getReceiptsSortedByDate() {
    final receipts = _box.values.toList();
    receipts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return receipts;
  }

  /// Get receipts sorted by amount (highest first)
  List<Receipt> getReceiptsSortedByAmount() {
    final receipts = _box.values.toList();
    receipts.sort((a, b) => b.total.compareTo(a.total));
    return receipts;
  }

  /// Get monthly total
  double getMonthlyTotal(int year, int month) {
    return _box.values.where((r) {
      return r.timestamp.year == year && r.timestamp.month == month;
    }).fold<double>(0.0, (sum, r) => sum + r.total);
  }

  /// Get monthly deductible
  double getMonthlyDeductible(int year, int month) {
    return _box.values.where((r) {
      return r.timestamp.year == year && r.timestamp.month == month;
    }).fold<double>(0.0, (sum, r) => sum + r.deductibleAmount);
  }

  /// Get yearly total
  double getYearlyTotal(int year) {
    return _box.values.where((r) {
      return r.timestamp.year == year;
    }).fold<double>(0.0, (sum, r) => sum + r.total);
  }

  /// Get yearly deductible
  double getYearlyDeductible(int year) {
    return _box.values.where((r) {
      return r.timestamp.year == year;
    }).fold<double>(0.0, (sum, r) => sum + r.deductibleAmount);
  }

  /// Get category breakdown
  Map<String, double> getCategoryBreakdown() {
    final Map<String, double> breakdown = {};
    for (final receipt in _box.values) {
      breakdown[receipt.category] = (breakdown[receipt.category] ?? 0.0) + receipt.total;
    }
    return breakdown;
  }

  /// Calculate runway (months of expenses covered by current balance)
  double calculateRunway() {
    if (_box.isEmpty) return 0.0;
    
    // Calculate average monthly expenses from last 3 months
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    final recentReceipts = _box.values.where((r) {
      return r.timestamp.isAfter(threeMonthsAgo);
    }).toList();
    
    if (recentReceipts.isEmpty) return 0.0;
    
    final totalSpent = recentReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
    final monthsOfData = 3.0;
    final avgMonthlyExpense = totalSpent / monthsOfData;
    
    if (avgMonthlyExpense == 0) return 0.0;
    
    // Assuming current balance is total deductible (simplified)
    return state.totalDeductible / avgMonthlyExpense;
  }
}

// Provider for Hive-backed transaction state (local only)
final hiveTransactionProvider = NotifierProvider<HiveTransactionNotifier, TransactionState>(
  HiveTransactionNotifier.new,
);
