import 'package:nova_finance_os/features/analytics/domain/coach_action.dart';
import 'package:nova_finance_os/features/analytics/domain/cashflow_point.dart';
import 'package:nova_finance_os/features/analytics/domain/tax_plan.dart';
import 'package:nova_finance_os/features/finance/domain/transaction_model.dart';

/// Brain State - Complete Financial Intelligence Output
/// 
/// Aggregates all AI analysis into a single comprehensive state
class BrainState {
  final int healthScore;
  final List<CoachAction> coachActions;
  final List<CashflowPoint> predictions;
  final TaxPlan taxPlan;
  final List<FinancialTransaction> anomalies;
  final DateTime timestamp;

  BrainState({
    required this.healthScore,
    required this.coachActions,
    required this.predictions,
    required this.taxPlan,
    required this.anomalies,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasUrgentActions => coachActions.any((a) => a.isUrgent);
  bool get hasAnomalies => anomalies.isNotEmpty;
  bool get isHealthy => healthScore >= 70;

  int get urgentActionCount => coachActions.where((a) => a.isUrgent).length;

  Map<String, dynamic> toJson() {
    return {
      'healthScore': healthScore,
      'coachActions': coachActions.map((a) => a.toJson()).toList(),
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'taxPlan': taxPlan.toJson(),
      'anomalies': anomalies.map((a) => {
        'amount': a.amount,
        'category': a.category,
        'date': a.date.toIso8601String(),
      }).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
