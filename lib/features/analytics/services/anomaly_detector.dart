import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:math';

final anomalyDetectorProvider = Provider((ref) => AnomalyDetector());

final anomalyExplainerProvider = Provider((ref) => AnomalyExplainer(
      nova: ref.read(novaServiceV3Provider),
    ));

/// Statistical Anomaly Detector
/// 
/// Detects unusual spending without AI first → AI explains
class AnomalyDetector {
  /// Check if expense amount is unusual based on history
  bool isUnusualExpense(double amount, List<double> history) {
    if (history.length < 5) {
      safePrint('[AnomalyDetector] Insufficient history');
      return false;
    }

    final avg = _calculateAverage(history);
    final stdDev = _calculateStdDev(history, avg);
    
    // Threshold: 2.2 standard deviations above mean
    final threshold = avg + (2.2 * stdDev);

    final isAnomaly = amount > threshold;
    
    if (isAnomaly) {
      safePrint('[AnomalyDetector] Anomaly detected!');
      safePrint('[AnomalyDetector] Amount: \$${amount.toStringAsFixed(2)}');
      safePrint('[AnomalyDetector] Average: \$${avg.toStringAsFixed(2)}');
      safePrint('[AnomalyDetector] Threshold: \$${threshold.toStringAsFixed(2)}');
    }

    return isAnomaly;
  }

  /// Check if spending frequency is unusual
  bool isUnusualFrequency(int transactionsThisWeek, List<int> weeklyHistory) {
    if (weeklyHistory.length < 4) return false;

    final avg = _calculateAverage(weeklyHistory.map((e) => e.toDouble()).toList());
    final threshold = avg * 1.8;

    return transactionsThisWeek > threshold;
  }

  /// Check if category spending is unusual
  bool isUnusualCategorySpending(
    String category,
    double amount,
    Map<String, List<double>> categoryHistory,
  ) {
    final history = categoryHistory[category];
    if (history == null || history.length < 3) return false;

    return isUnusualExpense(amount, history);
  }

  /// Detect sudden spending spike
  bool isSuddenSpike(List<double> last7Days) {
    if (last7Days.length < 7) return false;

    final recent3 = last7Days.sublist(last7Days.length - 3);
    final previous4 = last7Days.sublist(0, last7Days.length - 3);

    final recentAvg = _calculateAverage(recent3);
    final previousAvg = _calculateAverage(previous4);

    // Spike if recent average is 2x previous
    return recentAvg > (previousAvg * 2);
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateStdDev(List<double> values, double mean) {
    if (values.length < 2) return 0;
    
    final variance = values
        .map((x) => pow(x - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return sqrt(variance);
  }
}

/// AI Anomaly Explainer
/// 
/// Explains why an expense is unusual using AI
class AnomalyExplainer {
  final NovaServiceV3 nova;

  AnomalyExplainer({required this.nova});

  /// Explain why an expense is unusual
  Future<String> explain({
    required double amount,
    required String category,
    required double average,
    String? vendor,
  }) async {
    safePrint('[AnomalyExplainer] Explaining anomaly...');

    final prompt = '''Unusual Expense Detected:
- Amount: \$${amount.toStringAsFixed(2)}
- Category: $category
- Your Average: \$${average.toStringAsFixed(2)}
${vendor != null ? '- Vendor: $vendor' : ''}

Explain in one sentence why this might be unusual and if it's concerning.''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: '''You are Finance OS's anomaly analyst.

Explain anomalies in a helpful, non-alarming way:
- Acknowledge the unusual amount
- Suggest possible reasons
- Indicate if action is needed
- Use emoji prefix (⚠️ for concerning, 💡 for informational)

Keep it to one sentence.''',
        deepReasoning: true, // Uses Pro for better analysis
      );

      return response['text'] ?? 'This expense is higher than usual';
    } catch (e) {
      safePrint('[AnomalyExplainer] Error: $e');
      return '⚠️ This expense is ${((amount / average - 1) * 100).toStringAsFixed(0)}% higher than your average';
    }
  }

  /// Explain spending spike
  Future<String> explainSpike({
    required double recentTotal,
    required double previousTotal,
    required List<String> topCategories,
  }) async {
    final increasePercent = ((recentTotal / previousTotal - 1) * 100).toStringAsFixed(0);

    final prompt = '''Spending Spike Detected:
- Recent 3 days: \$${recentTotal.toStringAsFixed(2)}
- Previous 4 days: \$${previousTotal.toStringAsFixed(2)}
- Increase: $increasePercent%
- Top categories: ${topCategories.join(', ')}

Explain this spike in one sentence.''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: 'Explain the spending spike with emoji. Be helpful, not judgmental.',
        deepReasoning: false,
      );

      return response['text'] ?? '📈 Your spending increased by $increasePercent% recently';
    } catch (e) {
      return '📈 Your spending increased by $increasePercent% in the last 3 days';
    }
  }

  /// Suggest action for anomaly
  Future<String> suggestAction({
    required String anomalyType,
    required Map<String, dynamic> context,
  }) async {
    final prompt = '''Anomaly Type: $anomalyType
Context: ${context.entries.map((e) => '${e.key}: ${e.value}').join(', ')}

Suggest one specific action the user should take.''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: 'Provide one actionable suggestion with emoji.',
        deepReasoning: false,
      );

      return response['text'] ?? 'Review this transaction and adjust budget if needed';
    } catch (e) {
      return '💡 Review this transaction and adjust your budget if needed';
    }
  }
}
