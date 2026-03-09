import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/analytics/domain/financial_snapshot.dart';
import 'package:nova_finance_os/features/analytics/domain/coach_action.dart';
import 'package:nova_finance_os/features/analytics/services/financial_insights_engine.dart';
import 'package:nova_finance_os/features/analytics/services/anomaly_detector.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

final financialCoachProvider = Provider((ref) => FinancialCoach(
      insights: ref.read(financialInsightsEngineProvider),
      anomalies: ref.read(anomalyDetectorProvider),
    ));

/// Financial Coach Engine
/// 
/// Evaluates financial health and provides actionable recommendations
/// - Savings rate analysis
/// - Cashflow warnings
/// - AI-powered insights
/// - Priority-based actions
class FinancialCoach {
  final FinancialInsightsEngine insights;
  final AnomalyDetector anomalies;

  static const String _dismissedActionsBox = 'dismissed_coach_actions';
  Box<String>? _dismissedBox;

  FinancialCoach({
    required this.insights,
    required this.anomalies,
  });

  Future<void> initialize() async {
    _dismissedBox = await Hive.openBox<String>(_dismissedActionsBox);
  }

  /// Evaluate financial health and generate coach actions
  Future<List<CoachAction>> evaluate(FinancialSnapshot snapshot) async {
    safePrint('[FinancialCoach] Evaluating financial health...');

    final actions = <CoachAction>[];

    // 1. Check savings rate
    final savingsRate = snapshot.savingsRate;
    
    if (savingsRate < 0.2) {
      actions.add(CoachAction(
        type: 'increase_savings',
        message: '💰 Your savings rate is ${(savingsRate * 100).toStringAsFixed(0)}% - aim for 20%+. '
                 'Consider reducing spending in ${_getTopCategory(snapshot.topCategories)}.',
        priority: 8,
        actionUrl: '/analytics/categories',
      ));
    } else if (savingsRate >= 0.3) {
      actions.add(CoachAction(
        type: 'great_savings',
        message: '🎉 Excellent ${(savingsRate * 100).toStringAsFixed(0)}% savings rate! '
                 'You\'re building wealth effectively.',
        priority: 3,
      ));
    }

    // 2. Check cashflow
    if (snapshot.monthlyExpenses > snapshot.monthlyIncome) {
      final deficit = snapshot.monthlyExpenses - snapshot.monthlyIncome;
      actions.add(CoachAction(
        type: 'negative_cashflow',
        message: '⚠️ You\'re spending \$${deficit.toStringAsFixed(2)} more than you earn this month. '
                 'Review expenses immediately.',
        priority: 10,
        actionUrl: '/expenses',
      ));
    }

    // 3. Check runway
    if (snapshot.daysOfRunway < 30) {
      actions.add(CoachAction(
        type: 'low_runway',
        message: '🚨 Only ${snapshot.daysOfRunway} days of runway left at current burn rate. '
                 'Increase income or reduce expenses urgently.',
        priority: 9,
        actionUrl: '/analytics/runway',
      ));
    } else if (snapshot.daysOfRunway < 90) {
      actions.add(CoachAction(
        type: 'moderate_runway',
        message: '⚡ ${snapshot.daysOfRunway} days of runway. Consider building emergency fund.',
        priority: 6,
      ));
    }

    // 4. Check burn rate
    if (snapshot.burnRate > snapshot.monthlyIncome / 30) {
      actions.add(CoachAction(
        type: 'high_burn_rate',
        message: '🔥 Daily burn rate (\$${snapshot.burnRate.toStringAsFixed(2)}) exceeds daily income. '
                 'Unsustainable spending pattern.',
        priority: 8,
      ));
    }

    // 5. Get AI insights
    try {
      final aiInsights = await insights.generateInsights(snapshot);
      for (int i = 0; i < aiInsights.length; i++) {
        actions.add(CoachAction(
          type: 'ai_insight_$i',
          message: aiInsights[i],
          priority: 5,
        ));
      }
    } catch (e) {
      safePrint('[FinancialCoach] Failed to get AI insights: $e');
    }

    // 6. Filter out dismissed actions
    final filteredActions = actions.where((action) {
      final key = '${action.type}_${action.message.hashCode}';
      return !_isDismissed(key);
    }).toList();

    // 7. Sort by priority (highest first)
    filteredActions.sort((a, b) => b.priority.compareTo(a.priority));

    safePrint('[FinancialCoach] Generated ${filteredActions.length} actions');
    return filteredActions;
  }

  /// Generate weekly financial health brief
  Future<String> generateWeeklyBrief(FinancialSnapshot snapshot) async {
    final actions = await evaluate(snapshot);
    final urgentActions = actions.where((a) => a.isUrgent).toList();
    
    final brief = StringBuffer();
    brief.writeln('📊 Weekly Financial Health Brief\n');
    
    // Overall health
    final health = _calculateHealthScore(snapshot);
    brief.writeln('Health Score: ${health.toStringAsFixed(0)}/100\n');
    
    // Urgent items
    if (urgentActions.isNotEmpty) {
      brief.writeln('🚨 Urgent Actions:');
      for (final action in urgentActions) {
        brief.writeln('• ${action.message}');
      }
      brief.writeln();
    }
    
    // Key metrics
    brief.writeln('📈 Key Metrics:');
    brief.writeln('• Savings Rate: ${(snapshot.savingsRate * 100).toStringAsFixed(0)}%');
    brief.writeln('• Days of Runway: ${snapshot.daysOfRunway}');
    brief.writeln('• Burn Rate: \$${snapshot.burnRate.toStringAsFixed(2)}/day');
    
    return brief.toString();
  }

  /// Dismiss a coach action
  Future<void> dismissAction(CoachAction action) async {
    final key = '${action.type}_${action.message.hashCode}';
    await _dismissedBox?.put(key, DateTime.now().toIso8601String());
    safePrint('[FinancialCoach] Dismissed action: ${action.type}');
  }

  /// Clear dismissed actions (reset)
  Future<void> clearDismissed() async {
    await _dismissedBox?.clear();
    safePrint('[FinancialCoach] Cleared all dismissed actions');
  }

  bool _isDismissed(String key) {
    final dismissedDate = _dismissedBox?.get(key);
    if (dismissedDate == null) return false;
    
    // Auto-expire dismissals after 30 days
    final dismissed = DateTime.parse(dismissedDate);
    final daysSince = DateTime.now().difference(dismissed).inDays;
    return daysSince < 30;
  }

  String _getTopCategory(Map<String, double> categories) {
    if (categories.isEmpty) return 'your top expense category';
    
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }

  double _calculateHealthScore(FinancialSnapshot snapshot) {
    double score = 50.0; // Base score
    
    // Savings rate (0-30 points)
    score += snapshot.savingsRate * 100 * 0.3;
    
    // Runway (0-20 points)
    if (snapshot.daysOfRunway >= 90) {
      score += 20;
    } else if (snapshot.daysOfRunway >= 30) {
      score += 10;
    }
    
    // Positive cashflow (0-20 points)
    if (snapshot.monthlyIncome > snapshot.monthlyExpenses) {
      score += 20;
    }
    
    // Balance (0-10 points)
    if (snapshot.balance > 0) {
      score += 10;
    }
    
    return score.clamp(0, 100);
  }
}
