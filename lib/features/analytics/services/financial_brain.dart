import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/analytics/services/financial_coach.dart';
import 'package:nova_finance_os/features/analytics/services/cashflow_predictor.dart';
import 'package:nova_finance_os/features/analytics/services/tax_optimizer.dart';
import 'package:nova_finance_os/features/analytics/services/financial_health_engine.dart';
import 'package:nova_finance_os/features/analytics/services/anomaly_detector.dart';
import 'package:nova_finance_os/features/analytics/domain/user_financial_profile.dart';
import 'package:nova_finance_os/features/analytics/domain/brain_state.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final financialBrainProvider = Provider((ref) => FinancialBrain(
      coach: ref.read(financialCoachProvider),
      predictor: ref.read(cashflowPredictorProvider),
      taxOptimizer: ref.read(taxOptimizerProvider),
      healthEngine: ref.read(financialHealthEngineProvider),
      anomalyDetector: ref.read(anomalyDetectorProvider),
    ));

/// Financial Brain - Master AI Orchestrator
/// 
/// Coordinates all AI systems to provide comprehensive financial intelligence:
/// - Health scoring
/// - Coach recommendations
/// - Cashflow predictions
/// - Tax optimization
/// - Anomaly detection
class FinancialBrain {
  final FinancialCoach coach;
  final CashflowPredictor predictor;
  final TaxOptimizer taxOptimizer;
  final FinancialHealthEngine healthEngine;
  final AnomalyDetector anomalyDetector;

  FinancialBrain({
    required this.coach,
    required this.predictor,
    required this.taxOptimizer,
    required this.healthEngine,
    required this.anomalyDetector,
  });

  /// Evaluate complete financial state
  Future<BrainState> evaluate(UserFinancialProfile profile) async {
    safePrint('[FinancialBrain] Starting comprehensive evaluation...');

    final snapshot = profile.snapshot;

    // 1. Calculate health score
    final healthScore = healthEngine.calculate(snapshot);
    safePrint('[FinancialBrain] Health score: $healthScore/100');

    // 2. Get coach actions
    final coachActions = await coach.evaluate(snapshot);
    safePrint('[FinancialBrain] Coach actions: ${coachActions.length}');

    // 3. Predict cashflow
    final predictions = await predictor.predict(
      history: profile.transactions,
      currentBalance: snapshot.balance,
      days: 30,
    );
    safePrint('[FinancialBrain] Predictions: ${predictions.length} days');

    // 4. Generate tax plan
    final taxPlan = await taxOptimizer.generatePlan(
      receipts: profile.receipts,
    );
    safePrint('[FinancialBrain] Tax deductions: \$${taxPlan.deductibleTotal}');

    // 5. Detect anomalies
    final anomalies = profile.transactions.where((tx) {
      return anomalyDetector.isUnusualExpense(
        tx.amount.abs(),
        profile.recentExpenses,
      );
    }).toList();
    safePrint('[FinancialBrain] Anomalies detected: ${anomalies.length}');

    final state = BrainState(
      healthScore: healthScore,
      coachActions: coachActions,
      predictions: predictions,
      taxPlan: taxPlan,
      anomalies: anomalies,
    );

    safePrint('[FinancialBrain] Evaluation complete');
    
    return state;
  }

  /// Quick health check (lightweight)
  Future<Map<String, dynamic>> quickCheck(UserFinancialProfile profile) async {
    final healthScore = healthEngine.calculate(profile.snapshot);
    final urgentActions = (await coach.evaluate(profile.snapshot))
        .where((a) => a.isUrgent)
        .toList();

    return {
      'healthScore': healthScore,
      'healthStatus': healthEngine.getHealthStatus(healthScore),
      'urgentActionCount': urgentActions.length,
      'hasAnomalies': profile.transactions.any((tx) =>
          anomalyDetector.isUnusualExpense(
            tx.amount.abs(),
            profile.recentExpenses,
          )),
    };
  }

  /// Generate executive summary
  Future<String> generateExecutiveSummary(BrainState state) async {
    final summary = StringBuffer();
    
    summary.writeln('🧠 Financial Intelligence Summary\n');
    
    // Health
    final healthStatus = healthEngine.getHealthStatus(state.healthScore);
    summary.writeln('Health: $healthStatus (${state.healthScore}/100)');
    
    // Urgent items
    if (state.hasUrgentActions) {
      summary.writeln('⚠️ ${state.urgentActionCount} urgent action(s) required');
    }
    
    // Anomalies
    if (state.hasAnomalies) {
      summary.writeln('🔍 ${state.anomalies.length} unusual transaction(s) detected');
    }
    
    // Tax
    summary.writeln('💰 Tax deductions: \$${state.taxPlan.deductibleTotal.toStringAsFixed(2)}');
    
    // Cashflow
    final lastPrediction = state.predictions.last;
    final balanceChange = lastPrediction.predictedBalance - state.predictions.first.predictedBalance;
    summary.writeln('📈 30-day forecast: ${balanceChange >= 0 ? "+" : ""}\$${balanceChange.toStringAsFixed(2)}');
    
    return summary.toString();
  }
}
