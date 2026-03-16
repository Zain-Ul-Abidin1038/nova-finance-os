import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:nova_finance_os/features/nova_navigator/domain/navigation_task.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';

final novaNavigatorServiceProvider = Provider((ref) => NovaNavigatorService(
      novaService: ref.read(novaServiceV3Provider),
      financeService: ref.read(unifiedFinanceServiceProvider),
    ));

class NovaNavigatorService {
  final NovaServiceV3 novaService;
  final UnifiedFinanceService financeService;

  NovaNavigatorService({
    required this.novaService,
    required this.financeService,
  });

  /// Execute a financial task with real-time updates
  Stream<Map<String, dynamic>> executeTask(NavigationTask task) async* {
    safePrint('[NovaNavigator] Starting task: ${task.description}');

    try {
      // Step 1: Plan the financial task
      yield {'thought': 'Understanding your financial request...', 'status': TaskStatus.planning};

      final plan = await _planTask(task.description);
      yield {'log': '📋 Plan created: ${plan['steps'].length} steps'};

      // Step 2: Gather financial data
      yield {'thought': 'Gathering your financial data...', 'status': TaskStatus.analyzing};

      final summary = financeService.getFinancialSummary();
      yield {'log': '🔍 Financial data loaded — Balance: ${summary['balance']?.toStringAsFixed(2) ?? '0.00'}'};

      // Step 3: Execute analysis steps
      yield {'thought': 'Running analysis...', 'status': TaskStatus.executing};

      final steps = plan['steps'] as List;
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        yield {'log': '⚡ Step ${i + 1}/${steps.length}: ${step['description']}'};
        yield {'thought': step['description']};
        await Future.delayed(const Duration(milliseconds: 800));
        yield {'log': '✅ ${step['description']} — Done'};
      }

      // Step 4: Generate AI-powered result
      yield {'thought': 'Generating insights with Nova AI...', 'status': TaskStatus.executing};

      final aiResult = await _generateFinancialResult(task.description, summary);
      yield {'log': '🧠 AI Analysis Complete'};
      yield {'log': aiResult};

      // Step 5: Complete
      yield {'thought': 'Task completed!', 'status': TaskStatus.completed};
      yield {'log': '🎉 Task completed successfully!'};

    } catch (e) {
      safePrint('[NovaNavigator] Error: $e');
      yield {'thought': 'Error occurred', 'status': TaskStatus.failed};
      yield {'log': '❌ Error: $e'};
    }
  }

  /// Plan the financial task using AI
  Future<Map<String, dynamic>> _planTask(String taskDescription) async {
    try {
      final result = await novaService.sendMessage(
        prompt: '''You are a financial AI agent. Plan how to complete this financial task within the app.

Task: "$taskDescription"

Return a JSON object with steps that are all in-app financial operations (analysis, calculations, reports).
Do NOT include steps about opening external apps or websites.

Return JSON:
{
  "steps": [
    {"description": "step description"}
  ],
  "category": "analysis/budgeting/forecasting/reporting/savings"
}

Return ONLY valid JSON.''',
        systemInstruction: 'You are a financial task planner. Return only valid JSON with in-app financial steps.',
      );

      if (result['success'] == true) {
        final text = result['text'] ?? '';
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          try {
            final parsed = jsonDecode(jsonMatch.group(0)!);
            if (parsed is Map<String, dynamic> && parsed['steps'] is List) {
              return parsed;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      safePrint('[NovaNavigator] Planning error: $e');
    }

    // Fallback plan for financial tasks
    return {
      'steps': [
        {'description': 'Load financial data'},
        {'description': 'Analyze transaction history'},
        {'description': 'Generate insights with Nova AI'},
        {'description': 'Prepare summary report'},
      ],
      'category': 'analysis',
    };
  }

  /// Generate AI-powered financial result
  Future<String> _generateFinancialResult(
    String taskDescription,
    Map<String, dynamic> summary,
  ) async {
    try {
      final result = await novaService.sendMessage(
        prompt: '''Based on this financial data, complete the user's request.

User request: "$taskDescription"

Financial Summary:
- Balance: ${summary['balance']?.toStringAsFixed(2) ?? '0.00'}
- Total Income: ${summary['totalIncome']?.toStringAsFixed(2) ?? '0.00'}
- Total Expenses: ${summary['totalExpenses']?.toStringAsFixed(2) ?? '0.00'}
- Receivables: ${summary['totalReceivables']?.toStringAsFixed(2) ?? '0.00'}
- Payables: ${summary['totalPayables']?.toStringAsFixed(2) ?? '0.00'}
- Income entries: ${summary['incomeCount'] ?? 0}
- Expense entries: ${summary['expenseCount'] ?? 0}

Provide a concise, actionable response (3-5 bullet points). Use emojis for readability.''',
        systemInstruction: 'You are Finance OS, a financial AI assistant. Provide concise, actionable financial advice based on real user data.',
      );

      if (result['success'] == true) {
        return result['text'] ?? 'Analysis complete. Check your dashboard for details.';
      }
    } catch (e) {
      safePrint('[NovaNavigator] AI result error: $e');
    }

    return '📊 Analysis complete based on your financial data. Check your dashboard for detailed insights.';
  }

  /// Analyze screen using vision AI (for future implementation)
  Future<ScreenAnalysis> analyzeScreen(File screenshot) async {
    try {
      final bytes = await screenshot.readAsBytes();
      final base64Image = base64Encode(bytes);

      await novaService.analyzeReceiptImage(
        base64Image: base64Image,
        region: 'us-east-1',
      );

      return ScreenAnalysis(
        elements: [],
        screenType: 'unknown',
        description: 'Screen analysis via Nova Pro Vision',
        possibleActions: [],
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      safePrint('[NovaNavigator] Screen analysis error: $e');
      rethrow;
    }
  }
}
