import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:nova_finance_os/features/analytics/domain/financial_snapshot.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final financialInsightsEngineProvider = Provider((ref) => FinancialInsightsEngine(
      nova: ref.read(novaServiceV3Provider),
    ));

/// AI Financial Insights Engine
/// 
/// Turns raw transactions into intelligence:
/// - Spending trends
/// - Category drift
/// - Savings rate analysis
/// - Burn rate warnings
/// - Tax optimization suggestions
/// - Cashflow predictions
class FinancialInsightsEngine {
  final NovaServiceV3 nova;

  FinancialInsightsEngine({required this.nova});

  /// Generate comprehensive financial insights
  Future<List<String>> generateInsights(FinancialSnapshot snapshot) async {
    safePrint('[InsightsEngine] Generating insights...');

    final prompt = '''${snapshot.toPromptContext()}

Analyze this financial data and provide 3 concise, actionable insights.

Focus on:
1. Spending patterns and trends
2. Savings opportunities
3. Tax optimization or cashflow warnings

Format each insight as a single sentence with an emoji prefix.
Example: "💰 You're spending 40% on food - consider meal planning to save \$200/month"
''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: '''You are Finance OS's financial analyst.

Provide insights that are:
- Specific and actionable
- Based on the data provided
- Focused on improvement opportunities
- Concise (1 sentence each)
- Prefixed with relevant emoji

Avoid generic advice. Use actual numbers from the data.''',
        deepReasoning: true, // Uses Pro + high thinking
      );

      final text = response['text'] ?? '';
      
      // Parse insights (one per line)
      final insights = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .toList();

      safePrint('[InsightsEngine] Generated ${insights.length} insights');
      return insights;
    } catch (e) {
      safePrint('[InsightsEngine] Error: $e');
      return [
        '💡 Unable to generate insights at this time',
        '📊 Keep tracking your expenses for better analysis',
        '🎯 Check back after more transactions are recorded',
      ];
    }
  }

  /// Generate spending trend analysis
  Future<String> analyzeTrend(
    Map<String, double> currentMonth,
    Map<String, double> previousMonth,
  ) async {
    final prompt = '''Compare spending between months:

Current Month:
${currentMonth.entries.map((e) => '${e.key}: \$${e.value}').join('\n')}

Previous Month:
${previousMonth.entries.map((e) => '${e.key}: \$${e.value}').join('\n')}

Identify the biggest change and explain what it means.''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: 'Provide a single sentence trend analysis with emoji.',
        deepReasoning: false,
      );

      return response['text'] ?? 'No significant trend detected';
    } catch (e) {
      return 'Unable to analyze trend';
    }
  }

  /// Generate tax optimization suggestions
  Future<List<String>> suggestTaxOptimizations(
    double totalDeductions,
    double totalExpenses,
  ) async {
    final deductionRate = totalExpenses > 0 
        ? (totalDeductions / totalExpenses) * 100 
        : 0.0;

    final prompt = '''Tax Deduction Analysis:
- Total Expenses: \$${totalExpenses.toStringAsFixed(2)}
- Total Deductions: \$${totalDeductions.toStringAsFixed(2)}
- Deduction Rate: ${deductionRate.toStringAsFixed(1)}%

Suggest 2 ways to maximize tax deductions.''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: 'Provide 2 specific tax optimization tips with emoji.',
        deepReasoning: true,
      );

      final text = response['text'] ?? '';
      final suggestions = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(2)
          .toList();

      return suggestions;
    } catch (e) {
      return [
        '📋 Track all business meals (50% deductible)',
        '🏢 Consider home office deduction if eligible',
      ];
    }
  }

  /// Predict cashflow for next month
  Future<String> predictCashflow(FinancialSnapshot snapshot) async {
    final prompt = '''${snapshot.toPromptContext()}

Based on this data, predict next month's cashflow.
Will they have positive or negative cashflow? By how much?''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: 'Provide a single sentence cashflow prediction with emoji and specific amount.',
        deepReasoning: true,
      );

      return response['text'] ?? 'Cashflow prediction unavailable';
    } catch (e) {
      return 'Unable to predict cashflow';
    }
  }

  /// Detect category drift (spending shift)
  Future<String?> detectCategoryDrift(
    Map<String, double> current,
    Map<String, double> baseline,
  ) async {
    // Find biggest percentage change
    String? biggestChange;
    double maxChangePercent = 0;

    for (final category in current.keys) {
      final currentAmount = current[category] ?? 0;
      final baselineAmount = baseline[category] ?? 0;

      if (baselineAmount > 0) {
        final changePercent = 
            ((currentAmount - baselineAmount) / baselineAmount).abs() * 100;

        if (changePercent > maxChangePercent && changePercent > 30) {
          maxChangePercent = changePercent;
          biggestChange = category;
        }
      }
    }

    if (biggestChange == null) return null;

    final prompt = '''Spending in "$biggestChange" changed by ${maxChangePercent.toStringAsFixed(0)}%.

Current: \$${current[biggestChange]}
Baseline: \$${baseline[biggestChange]}

Explain this drift in one sentence.''';

    try {
      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: 'Explain the spending drift with emoji.',
        deepReasoning: false,
      );

      return response['text'];
    } catch (e) {
      return null;
    }
  }
}
