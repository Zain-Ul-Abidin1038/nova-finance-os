import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/analytics/domain/financial_snapshot.dart';
import 'package:nova_finance_os/features/analytics/domain/user_financial_profile.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final budgetAutopilotProvider = Provider((ref) => BudgetAutopilot());
final behaviorChangeEngineProvider = Provider((ref) => BehaviorChangeEngine());
final investorAnalyticsEngineProvider = Provider((ref) => InvestorAnalyticsEngine());
final financialRiskEngineProvider = Provider((ref) => FinancialRiskEngine());

// ============================================================================
// 1. AI-DRIVEN BUDGETING AUTOPILOT
// ============================================================================

/// Budget Plan Model
class BudgetPlan {
  final Map<String, double> recommendedBudgets;
  final double totalLimit;
  final String reasoning;

  BudgetPlan({
    required this.recommendedBudgets,
    required this.totalLimit,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() {
    return {
      'recommendedBudgets': recommendedBudgets,
      'totalLimit': totalLimit,
      'reasoning': reasoning,
    };
  }
}

/// Budget Autopilot
/// 
/// Automatically adjusts budgets based on behavior:
/// 1. Analyze last 30 days
/// 2. Detect overspending categories
/// 3. Rebalance budget
/// 4. Propose automatic limits
class BudgetAutopilot {
  /// Generate budget plan
  BudgetPlan generatePlan(FinancialSnapshot snapshot) {
    safePrint('[BudgetAutopilot] Generating budget plan...');

    final budgets = <String, double>{};
    final overspendingCategories = <String>[];

    // Analyze each category
    snapshot.topCategories.forEach((category, spend) {
      // Gradual tightening: recommend 90% of current spend
      final recommended = spend * 0.9;
      budgets[category] = recommended;

      // Flag if spending is high
      if (spend > snapshot.monthlyIncome * 0.2) {
        overspendingCategories.add(category);
      }
    });

    // Total limit: 80% of income (20% savings target)
    final totalLimit = snapshot.monthlyIncome * 0.8;

    // Generate reasoning
    final reasoning = overspendingCategories.isEmpty
        ? 'Budgets optimized for 20% savings rate'
        : 'Reduced ${overspendingCategories.join(", ")} to improve savings';

    safePrint('[BudgetAutopilot] Generated plan with ${budgets.length} categories');

    return BudgetPlan(
      recommendedBudgets: budgets,
      totalLimit: totalLimit,
      reasoning: reasoning,
    );
  }

  /// Check if category is over budget
  bool isOverBudget(String category, double spent, BudgetPlan plan) {
    final budget = plan.recommendedBudgets[category];
    if (budget == null) return false;
    return spent > budget;
  }

  /// Get budget utilization percentage
  double getBudgetUtilization(String category, double spent, BudgetPlan plan) {
    final budget = plan.recommendedBudgets[category];
    if (budget == null || budget == 0) return 0;
    return (spent / budget) * 100;
  }
}

// ============================================================================
// 2. PERSONALIZED BEHAVIOR CHANGE SYSTEM
// ============================================================================

/// Behavior Profile Model
class BehaviorProfile {
  double adherenceScore; // 0-1
  double foodThreshold;
  List<String> riskPatterns;
  int nudgesAccepted;
  int nudgesIgnored;

  BehaviorProfile({
    required this.adherenceScore,
    required this.foodThreshold,
    required this.riskPatterns,
    this.nudgesAccepted = 0,
    this.nudgesIgnored = 0,
  });

  double get nudgeAcceptanceRate {
    final total = nudgesAccepted + nudgesIgnored;
    if (total == 0) return 0;
    return nudgesAccepted / total;
  }
}

/// Behavior Change Engine
/// 
/// Tracks:
/// - Spending triggers
/// - Habits
/// - Response to advice
/// - Adherence score
class BehaviorChangeEngine {
  static const String _boxName = 'behavior_profile';

  Future<void> initialize() async {
    await Hive.openBox(_boxName);
  }

  /// Update profile based on transaction
  BehaviorProfile updateProfile(
    BehaviorProfile profile,
    Transaction tx,
  ) {
    // Detect impulse spending patterns
    if (tx.category == 'food' && tx.amount.abs() > profile.foodThreshold) {
      if (!profile.riskPatterns.contains('impulse_food_spending')) {
        profile.riskPatterns.add('impulse_food_spending');
        safePrint('[BehaviorEngine] Detected: impulse_food_spending');
      }
    }

    // Detect late-night spending
    if (tx.date.hour >= 22 || tx.date.hour <= 2) {
      if (!profile.riskPatterns.contains('late_night_spending')) {
        profile.riskPatterns.add('late_night_spending');
        safePrint('[BehaviorEngine] Detected: late_night_spending');
      }
    }

    // Detect weekend splurges
    if (tx.date.weekday >= 6 && tx.amount.abs() > profile.foodThreshold * 1.5) {
      if (!profile.riskPatterns.contains('weekend_splurge')) {
        profile.riskPatterns.add('weekend_splurge');
        safePrint('[BehaviorEngine] Detected: weekend_splurge');
      }
    }

    return profile;
  }

  /// Generate personalized nudges
  List<String> generateNudges(BehaviorProfile profile) {
    final nudges = <String>[];

    if (profile.riskPatterns.contains('impulse_food_spending')) {
      nudges.add('💡 Try a weekly food budget cap of \$${(profile.foodThreshold * 7).toStringAsFixed(0)}');
    }

    if (profile.riskPatterns.contains('late_night_spending')) {
      nudges.add('🌙 Consider a spending freeze after 10 PM');
    }

    if (profile.riskPatterns.contains('weekend_splurge')) {
      nudges.add('📅 Plan weekend activities with a set budget');
    }

    if (profile.adherenceScore < 0.5) {
      nudges.add('🎯 Start with a small savings goal this week: \$50');
    } else if (profile.adherenceScore >= 0.8) {
      nudges.add('🎉 Great progress! Consider increasing your savings goal');
    }

    if (profile.nudgeAcceptanceRate < 0.3 && profile.nudgesAccepted + profile.nudgesIgnored > 5) {
      nudges.add('💬 Let\'s adjust your goals to be more achievable');
    }

    return nudges;
  }

  /// Record nudge response
  void recordNudgeResponse(BehaviorProfile profile, bool accepted) {
    if (accepted) {
      profile.nudgesAccepted++;
      profile.adherenceScore = (profile.adherenceScore + 0.1).clamp(0, 1);
    } else {
      profile.nudgesIgnored++;
      profile.adherenceScore = (profile.adherenceScore - 0.05).clamp(0, 1);
    }
  }
}

// ============================================================================
// 3. INVESTOR-GRADE ANALYTICS ENGINE
// ============================================================================

/// Investor Metrics Model
class InvestorMetrics {
  final double runwayMonths;
  final double savingsVelocity;
  final String netWorthTrend;
  final double expenseVolatility;
  final double incomeStability;

  InvestorMetrics({
    required this.runwayMonths,
    required this.savingsVelocity,
    required this.netWorthTrend,
    required this.expenseVolatility,
    required this.incomeStability,
  });

  Map<String, dynamic> toJson() {
    return {
      'runwayMonths': runwayMonths,
      'savingsVelocity': savingsVelocity,
      'netWorthTrend': netWorthTrend,
      'expenseVolatility': expenseVolatility,
      'incomeStability': incomeStability,
    };
  }
}

/// Investor Analytics Engine
/// 
/// Transforms data into financial analytics similar to wealth platforms:
/// - Net worth trend
/// - Expense volatility
/// - Income stability
/// - Savings velocity
/// - Financial runway
class InvestorAnalyticsEngine {
  /// Analyze financial profile
  InvestorMetrics analyze(UserFinancialProfile profile) {
    safePrint('[InvestorAnalytics] Analyzing profile...');

    final snapshot = profile.snapshot;

    // Runway in months
    final runwayMonths = snapshot.monthlyExpenses > 0
        ? (snapshot.balance / snapshot.monthlyExpenses).toDouble()
        : 0.0;

    // Savings velocity (monthly)
    final savingsVelocity = (snapshot.monthlyIncome - snapshot.monthlyExpenses).toDouble();

    // Net worth trend
    final netWorthTrend = _calculateTrend(profile.netWorthHistory);

    // Expense volatility (coefficient of variation)
    final expenseVolatility = _calculateVolatility(profile.recentExpenses);

    // Income stability (inverse of volatility)
    final incomeStabilityValue = 1.0 - expenseVolatility;
    final incomeStability = incomeStabilityValue < 0.0 ? 0.0 : (incomeStabilityValue > 1.0 ? 1.0 : incomeStabilityValue);

    return InvestorMetrics(
      runwayMonths: runwayMonths,
      savingsVelocity: savingsVelocity,
      netWorthTrend: netWorthTrend,
      expenseVolatility: expenseVolatility,
      incomeStability: incomeStability,
    );
  }

  String _calculateTrend(List<double> history) {
    if (history.length < 2) return 'stable';
    
    final first = history.first;
    final last = history.last;
    
    if (last > first * 1.1) return 'growing';
    if (last < first * 0.9) return 'declining';
    return 'stable';
  }

  double _calculateVolatility(List<double> values) {
    if (values.length < 2) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((x) => (x - mean) * (x - mean))
        .reduce((a, b) => a + b) / values.length;
    
    final stdDev = variance > 0 ? variance.toDouble() : 0.0;
    
    // Coefficient of variation
    return mean > 0 ? stdDev / mean : 0;
  }
}

// ============================================================================
// 4. BANK-GRADE RISK ENGINE
// ============================================================================

/// Risk Report Model
class RiskReport {
  final double liquidityRisk; // 0-1
  final double volatilityRisk; // 0-1
  final double debtPressure; // 0-1
  final double anomalyRisk; // 0-1
  final double overallRisk; // 0-1

  RiskReport({
    required this.liquidityRisk,
    required this.volatilityRisk,
    required this.debtPressure,
    required this.anomalyRisk,
    required this.overallRisk,
  });

  String get riskLevel {
    if (overallRisk >= 0.7) return 'High';
    if (overallRisk >= 0.4) return 'Medium';
    return 'Low';
  }

  Map<String, dynamic> toJson() {
    return {
      'liquidityRisk': liquidityRisk,
      'volatilityRisk': volatilityRisk,
      'debtPressure': debtPressure,
      'anomalyRisk': anomalyRisk,
      'overallRisk': overallRisk,
      'riskLevel': riskLevel,
    };
  }
}

/// Financial Risk Engine
/// 
/// Evaluates financial risk like lending systems:
/// - Liquidity risk (running out of cash)
/// - Spending volatility (unstable behavior)
/// - Debt pressure (repayment risk)
/// - Income stability (predictability)
/// - Anomaly frequency (behavioral risk)
class FinancialRiskEngine {
  /// Evaluate risk profile
  RiskReport evaluate(UserFinancialProfile profile) {
    safePrint('[RiskEngine] Evaluating risk...');

    final snapshot = profile.snapshot;

    // 1. Liquidity risk
    final liquidityRisk = snapshot.balance < snapshot.monthlyExpenses
        ? 0.8
        : snapshot.balance < snapshot.monthlyExpenses * 2
            ? 0.5
            : 0.2;

    // 2. Volatility risk
    final avgExpense = snapshot.monthlyExpenses;
    final volatilityRisk = profile.expenseStdDev > avgExpense * 0.5
        ? 0.7
        : profile.expenseStdDev > avgExpense * 0.3
            ? 0.4
            : 0.2;

    // 3. Debt pressure (placeholder - would analyze loans)
    final debtPressure = 0.3; // Default moderate

    // 4. Anomaly risk
    final anomalyCount = profile.transactions.isNotEmpty
        ? profile.recentExpenses.where((e) => e > avgExpense * 2).length
        : 0;
    final anomalyRisk = anomalyCount > 3 ? 0.6 : anomalyCount > 1 ? 0.3 : 0.1;

    // 5. Overall risk (weighted average)
    final overallRisk = (liquidityRisk * 0.4 +
            volatilityRisk * 0.3 +
            debtPressure * 0.2 +
            anomalyRisk * 0.1)
        .clamp(0.0, 1.0);

    safePrint('[RiskEngine] Overall risk: ${(overallRisk * 100).toStringAsFixed(0)}%');

    return RiskReport(
      liquidityRisk: liquidityRisk,
      volatilityRisk: volatilityRisk,
      debtPressure: debtPressure,
      anomalyRisk: anomalyRisk,
      overallRisk: overallRisk,
    );
  }

  /// Get risk recommendations
  List<String> getRecommendations(RiskReport report) {
    final recommendations = <String>[];

    if (report.liquidityRisk >= 0.7) {
      recommendations.add('🚨 Critical: Build emergency fund immediately');
    } else if (report.liquidityRisk >= 0.4) {
      recommendations.add('⚠️ Increase cash reserves to 3 months expenses');
    }

    if (report.volatilityRisk >= 0.6) {
      recommendations.add('📊 Stabilize spending with monthly budgets');
    }

    if (report.debtPressure >= 0.6) {
      recommendations.add('💳 Prioritize debt repayment');
    }

    if (report.anomalyRisk >= 0.5) {
      recommendations.add('🔍 Review unusual transactions and adjust habits');
    }

    if (report.overallRisk < 0.3) {
      recommendations.add('✅ Financial risk is well-managed');
    }

    return recommendations;
  }
}

// ============================================================================
// HELPER: Transaction Model (if not already defined)
// ============================================================================

class Transaction {
  final double amount;
  final String? category;
  final DateTime date;

  Transaction({
    required this.amount,
    this.category,
    required this.date,
  });
}
