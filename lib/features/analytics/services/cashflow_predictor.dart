import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/analytics/domain/cashflow_point.dart';
import 'package:nova_finance_os/features/finance/domain/transaction_model.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final cashflowPredictorProvider = Provider((ref) => CashflowPredictor(
      nova: ref.read(novaServiceV3Provider),
    ));

/// Predictive Cashflow Model
/// 
/// Hybrid prediction strategy:
/// 1. Statistical trend analysis
/// 2. Recurring income detection
/// 3. AI reasoning refinement
class CashflowPredictor {
  final NovaServiceV3 nova;

  CashflowPredictor({required this.nova});

  /// Predict cashflow for next N days
  Future<List<CashflowPoint>> predict({
    required List<FinancialTransaction> history,
    required double currentBalance,
    int days = 30,
  }) async {
    safePrint('[CashflowPredictor] Predicting $days days...');

    // 1. Calculate statistical trends
    final avgDailyExpense = _avgDailyExpense(history);
    final avgDailyIncome = _avgDailyIncome(history);

    safePrint('[CashflowPredictor] Avg daily expense: \$${avgDailyExpense.toStringAsFixed(2)}');
    safePrint('[CashflowPredictor] Avg daily income: \$${avgDailyIncome.toStringAsFixed(2)}');

    // 2. Detect recurring patterns
    final recurringIncome = _detectRecurringIncome(history);
    final recurringExpenses = _detectRecurringExpenses(history);

    // 3. Generate predictions
    final points = <CashflowPoint>[];
    var balance = currentBalance;

    for (int day = 1; day <= days; day++) {
      // Apply recurring income
      for (final recurring in recurringIncome) {
        if (day % recurring['frequency'] == 0) {
          balance += recurring['amount'];
        }
      }

      // Apply recurring expenses
      for (final recurring in recurringExpenses) {
        if (day % recurring['frequency'] == 0) {
          balance -= recurring['amount'];
        }
      }

      // Apply average daily changes
      balance += avgDailyIncome;
      balance -= avgDailyExpense;

      // Calculate confidence (decreases over time)
      final confidence = _calculateConfidence(day, history.length);

      points.add(CashflowPoint(
        day: day,
        predictedBalance: balance,
        confidence: confidence,
      ));
    }

    safePrint('[CashflowPredictor] Generated ${points.length} predictions');

    // 4. Check for critical points
    final criticalDay = _findCriticalDay(points);
    if (criticalDay != null) {
      safePrint('[CashflowPredictor] ⚠️ Balance will reach zero on day $criticalDay');
    }

    return points;
  }

  /// Generate AI-enhanced prediction summary
  Future<String> generatePredictionSummary(List<CashflowPoint> predictions) async {
    final lastPoint = predictions.last;
    final firstPoint = predictions.first;
    final criticalDay = _findCriticalDay(predictions);

    final prompt = '''Cashflow Prediction Summary:
- Current Balance: \$${firstPoint.predictedBalance.toStringAsFixed(2)}
- Predicted Balance (30 days): \$${lastPoint.predictedBalance.toStringAsFixed(2)}
- Change: \$${(lastPoint.predictedBalance - firstPoint.predictedBalance).toStringAsFixed(2)}
${criticalDay != null ? '- Critical: Balance reaches zero on day $criticalDay' : ''}

Provide a one-sentence summary with emoji and actionable advice.''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: 'Provide concise cashflow prediction summary with emoji.',
        deepReasoning: false,
      );

      return response['text'] ?? 'Cashflow prediction generated';
    } catch (e) {
      safePrint('[CashflowPredictor] AI summary failed: $e');
      
      if (criticalDay != null) {
        return '⚠️ You will run out of cash in $criticalDay days at current spending rate';
      } else if (lastPoint.predictedBalance > firstPoint.predictedBalance) {
        return '📈 Your balance will grow by \$${(lastPoint.predictedBalance - firstPoint.predictedBalance).toStringAsFixed(2)} over 30 days';
      } else {
        return '📉 Your balance will decrease by \$${(firstPoint.predictedBalance - lastPoint.predictedBalance).toStringAsFixed(2)} over 30 days';
      }
    }
  }

  double _avgDailyExpense(List<FinancialTransaction> tx) {
    final expenses = tx.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) return 0;

    final total = expenses.fold(0.0, (sum, t) => sum + t.amount);
    return total / 30; // Assume 30-day period
  }

  double _avgDailyIncome(List<FinancialTransaction> tx) {
    final income = tx.where((t) => t.type == 'income').toList();
    if (income.isEmpty) return 0;

    final total = income.fold(0.0, (sum, t) => sum + t.amount);
    return total / 30; // Assume 30-day period
  }

  List<Map<String, dynamic>> _detectRecurringIncome(List<FinancialTransaction> history) {
    // Detect monthly salary (every 30 days)
    final salaryTransactions = history
        .where((t) => t.type == 'income' && t.amount > 1000)
        .toList();

    if (salaryTransactions.length >= 2) {
      final avgSalary = salaryTransactions
          .fold(0.0, (sum, t) => sum + t.amount) / salaryTransactions.length;

      return [
        {'frequency': 30, 'amount': avgSalary}
      ];
    }

    return [];
  }

  List<Map<String, dynamic>> _detectRecurringExpenses(List<FinancialTransaction> history) {
    // Detect subscriptions (monthly recurring expenses)
    final Map<String, List<FinancialTransaction>> categoryGroups = {};

    for (final tx in history.where((t) => t.type == 'expense')) {
      final category = tx.category;
      categoryGroups.putIfAbsent(category, () => []).add(tx);
    }

    final recurring = <Map<String, dynamic>>[];

    for (final entry in categoryGroups.entries) {
      if (entry.value.length >= 2) {
        final avgAmount = entry.value
            .fold(0.0, (sum, t) => sum + t.amount) / entry.value.length;

        // Assume monthly if consistent
        recurring.add({'frequency': 30, 'amount': avgAmount});
      }
    }

    return recurring;
  }

  double _calculateConfidence(int day, int historyLength) {
    // Confidence decreases with prediction distance and limited history
    final historyFactor = (historyLength / 90).clamp(0.5, 1.0);
    final distanceFactor = (1 - (day / 60)).clamp(0.3, 1.0);
    return historyFactor * distanceFactor;
  }

  int? _findCriticalDay(List<CashflowPoint> points) {
    for (final point in points) {
      if (point.predictedBalance <= 0) {
        return point.day;
      }
    }
    return null;
  }
}
