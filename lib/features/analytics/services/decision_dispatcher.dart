import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../domain/financial_decision.dart';

final decisionDispatcherProvider = Provider((ref) => DecisionDispatcher());

/// Decision Dispatcher
/// Routes decisions to appropriate channels (notifications, dashboard, storage)
class DecisionDispatcher {
  static const String _boxName = 'financial_decisions';
  Box<FinancialDecision>? _box;

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(FinancialDecisionAdapter());
    }
    _box = await Hive.openBox<FinancialDecision>(_boxName);
  }

  /// Dispatch decision to appropriate channel
  Future<void> dispatch(FinancialDecision decision) async {
    safePrint('[DecisionDispatcher] Dispatching: ${decision.type} (priority: ${decision.priority})');

    // Store all decisions
    await _storeDecision(decision);

    // High priority (8+) → Notify user immediately
    if (decision.priority >= 8) {
      await _notifyUser(decision);
    }

    // Medium priority (5-7) → Dashboard badge
    else if (decision.priority >= 5) {
      await _updateDashboardBadge();
    }

    // Low priority (1-4) → Silent storage for dashboard
    else {
      safePrint('[DecisionDispatcher] Low priority - stored for dashboard');
    }
  }

  /// Dispatch multiple decisions
  Future<void> dispatchBatch(List<FinancialDecision> decisions) async {
    for (final decision in decisions) {
      await dispatch(decision);
    }
  }

  /// Store decision in Hive
  Future<void> _storeDecision(FinancialDecision decision) async {
    await _box?.put(decision.id, decision);
    safePrint('[DecisionDispatcher] Stored decision: ${decision.id}');
  }

  /// Notify user (push notification or in-app alert)
  Future<void> _notifyUser(FinancialDecision decision) async {
    safePrint('[DecisionDispatcher] 🔔 NOTIFICATION: ${decision.message}');
    
    // TODO: Integrate with push notification service
    // For now, just log
    // In production, use:
    // - Amazon SNS (Simple Notification Service)
    // - Local notifications
    // - In-app alert dialog
  }

  /// Update dashboard badge count
  Future<void> _updateDashboardBadge() async {
    final unreadCount = await getUnreadDecisionCount();
    safePrint('[DecisionDispatcher] 📊 Dashboard badge: $unreadCount unread');
    
    // TODO: Update app badge
    // In production, use:
    // - flutter_local_notifications for badge
    // - StateProvider for in-app badge
  }

  /// Get all decisions
  List<FinancialDecision> getAllDecisions() {
    return _box?.values.toList() ?? [];
  }

  /// Get unread decisions (not dismissed, not accepted)
  List<FinancialDecision> getUnreadDecisions() {
    return getAllDecisions()
        .where((d) => !d.dismissed && !d.accepted)
        .toList();
  }

  /// Get unread count
  Future<int> getUnreadDecisionCount() async {
    return getUnreadDecisions().length;
  }

  /// Get decisions by type
  List<FinancialDecision> getDecisionsByType(String type) {
    return getAllDecisions().where((d) => d.type == type).toList();
  }

  /// Get high priority decisions
  List<FinancialDecision> getHighPriorityDecisions() {
    return getAllDecisions()
        .where((d) => d.priority >= 8 && !d.dismissed)
        .toList();
  }

  /// Mark decision as dismissed
  Future<void> dismissDecision(String decisionId) async {
    final decision = _box?.get(decisionId);
    if (decision != null) {
      await _box?.put(
        decisionId,
        decision.copyWith(dismissed: true),
      );
      safePrint('[DecisionDispatcher] Dismissed: $decisionId');
    }
  }

  /// Mark decision as accepted
  Future<void> acceptDecision(String decisionId) async {
    final decision = _box?.get(decisionId);
    if (decision != null) {
      await _box?.put(
        decisionId,
        decision.copyWith(accepted: true),
      );
      safePrint('[DecisionDispatcher] Accepted: $decisionId');
    }
  }

  /// Clear old decisions (older than 30 days)
  Future<void> clearOldDecisions() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final decisions = getAllDecisions();
    
    for (final decision in decisions) {
      if (decision.timestamp.isBefore(cutoff)) {
        await _box?.delete(decision.id);
      }
    }
    
    safePrint('[DecisionDispatcher] Cleared old decisions');
  }

  /// Get decision statistics
  Map<String, dynamic> getStatistics() {
    final decisions = getAllDecisions();
    final unread = getUnreadDecisions();
    final highPriority = getHighPriorityDecisions();

    final typeBreakdown = <String, int>{};
    for (final decision in decisions) {
      typeBreakdown[decision.type] = (typeBreakdown[decision.type] ?? 0) + 1;
    }

    return {
      'total': decisions.length,
      'unread': unread.length,
      'highPriority': highPriority.length,
      'typeBreakdown': typeBreakdown,
    };
  }
}
