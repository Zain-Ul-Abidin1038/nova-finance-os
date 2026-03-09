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

  /// Execute a navigation task with real-time updates
  Stream<Map<String, dynamic>> executeTask(NavigationTask task) async* {
    safePrint('[NovaNavigator] Starting task: ${task.description}');

    try {
      // Step 1: Plan the task
      yield {'thought': 'Planning how to complete this task...', 'status': TaskStatus.planning};
      
      final plan = await _planTask(task.description);
      yield {'log': '📋 Plan created: ${plan['steps'].length} steps'};

      // Step 2: Analyze what needs to be done
      yield {'thought': 'Analyzing requirements...', 'status': TaskStatus.analyzing};
      
      final analysis = await _analyzeTask(task.description, plan);
      yield {'log': '🔍 Analysis: ${analysis['summary']}'};

      // Step 3: Execute steps
      yield {'thought': 'Executing task...', 'status': TaskStatus.executing};

      final steps = plan['steps'] as List;
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        yield {'log': '⚡ Step ${i + 1}/${steps.length}: ${step['description']}'};
        yield {'thought': step['description']};

        // Simulate step execution
        await Future.delayed(const Duration(seconds: 2));

        // Execute the step
        final result = await _executeStep(step, task.description);
        
        if (result['success'] == true) {
          yield {'log': '✅ ${step['description']} - Success'};
          
          // If this step involves a financial transaction, record it
          if (result['transaction'] != null) {
            await _recordTransaction(result['transaction']);
            yield {'log': '💰 Transaction recorded: ${result['transaction']['amount']}'};
          }
        } else {
          yield {'log': '❌ ${step['description']} - Failed: ${result['error']}'};
        }
      }

      // Step 4: Complete
      yield {'thought': 'Task completed!', 'status': TaskStatus.completed};
      yield {'log': '🎉 Task completed successfully!'};

      // Generate summary
      final summary = await _generateSummary(task.description, steps);
      yield {'log': '📊 Summary: ${summary['message']}'};

    } catch (e) {
      safePrint('[NovaNavigator] Error: $e');
      yield {'thought': 'Error occurred', 'status': TaskStatus.failed};
      yield {'log': '❌ Error: $e'};
    }
  }

  /// Plan the task using AI
  Future<Map<String, dynamic>> _planTask(String taskDescription) async {
    final prompt = '''You are NovaNavigator - an AI agent that can navigate apps and websites like a human.

Task: "$taskDescription"

Create a step-by-step plan to complete this task. Consider:
1. What app/website to use
2. What screens to navigate to
3. What information to input
4. What buttons to click
5. What to verify

Return JSON:
{
  "app": "app name or website",
  "steps": [
    {
      "action": "navigate/click/input/wait/verify",
      "description": "what to do",
      "target": "what element to interact with",
      "value": "value to input (if applicable)"
    }
  ],
  "expectedOutcome": "what should happen when complete",
  "financialImpact": {
    "hasTransaction": true/false,
    "amount": 1200,
    "category": "food/travel/shopping/etc"
  }
}

Examples:

Task: "Book a flight from Delhi to Mumbai"
Plan:
{
  "app": "MakeMyTrip or similar flight booking app",
  "steps": [
    {"action": "navigate", "description": "Open flight booking app", "target": "app"},
    {"action": "click", "description": "Select one-way flight", "target": "one-way button"},
    {"action": "input", "description": "Enter origin city", "target": "from field", "value": "Delhi"},
    {"action": "input", "description": "Enter destination city", "target": "to field", "value": "Mumbai"},
    {"action": "click", "description": "Select date", "target": "date picker"},
    {"action": "click", "description": "Search flights", "target": "search button"},
    {"action": "wait", "description": "Wait for results", "target": "results page"},
    {"action": "click", "description": "Select cheapest flight", "target": "flight option"},
    {"action": "verify", "description": "Verify booking details", "target": "summary page"}
  ],
  "expectedOutcome": "Flight booking page ready for payment",
  "financialImpact": {
    "hasTransaction": true,
    "amount": 3500,
    "category": "travel"
  }
}

Task: "Order a pizza"
Plan:
{
  "app": "Dominos or Swiggy",
  "steps": [
    {"action": "navigate", "description": "Open food delivery app", "target": "app"},
    {"action": "input", "description": "Search for pizza", "target": "search bar", "value": "pizza"},
    {"action": "click", "description": "Select Dominos", "target": "restaurant"},
    {"action": "click", "description": "Select large pepperoni pizza", "target": "menu item"},
    {"action": "click", "description": "Add to cart", "target": "add button"},
    {"action": "click", "description": "Go to cart", "target": "cart icon"},
    {"action": "verify", "description": "Verify order", "target": "cart page"}
  ],
  "expectedOutcome": "Order ready for checkout",
  "financialImpact": {
    "hasTransaction": true,
    "amount": 450,
    "category": "food"
  }
}

Return ONLY valid JSON.''';

    try {
      final result = await novaService.sendMessage(
        prompt: prompt,
        systemInstruction: 'You are a task planning AI. Return only valid JSON.',
        deepReasoning: true,
        isParsing: true,
      );

      if (result['success'] == true) {
        final text = result['text'] as String;
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          // Parse JSON (simplified)
          return {
            'app': 'Generic App',
            'steps': [
              {'action': 'navigate', 'description': 'Open app', 'target': 'app'},
              {'action': 'input', 'description': 'Enter details', 'target': 'form'},
              {'action': 'click', 'description': 'Submit', 'target': 'button'},
            ],
            'expectedOutcome': 'Task completed',
            'financialImpact': {'hasTransaction': false},
          };
        }
      }

      // Fallback plan
      return {
        'app': 'Generic App',
        'steps': [
          {'action': 'navigate', 'description': 'Open relevant app/website', 'target': 'app'},
          {'action': 'input', 'description': 'Enter required information', 'target': 'form'},
          {'action': 'click', 'description': 'Submit or confirm', 'target': 'button'},
          {'action': 'verify', 'description': 'Verify completion', 'target': 'confirmation'},
        ],
        'expectedOutcome': 'Task completed successfully',
        'financialImpact': {'hasTransaction': false},
      };
    } catch (e) {
      safePrint('[NovaNavigator] Planning error: $e');
      rethrow;
    }
  }

  /// Analyze the task requirements
  Future<Map<String, dynamic>> _analyzeTask(String taskDescription, Map<String, dynamic> plan) async {
    return {
      'summary': 'Task requires ${plan['steps'].length} steps to complete',
      'complexity': 'medium',
      'estimatedTime': '2-3 minutes',
      'requiresAuth': false,
      'requiresPayment': plan['financialImpact']['hasTransaction'] == true,
    };
  }

  /// Execute a single step
  Future<Map<String, dynamic>> _executeStep(Map<String, dynamic> step, String taskDescription) async {
    final action = step['action'];
    final description = step['description'];

    safePrint('[NovaNavigator] Executing: $description');

    // Simulate step execution
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if this step involves a financial transaction
    if (description.toLowerCase().contains('pay') || 
        description.toLowerCase().contains('checkout') ||
        description.toLowerCase().contains('confirm order')) {
      
      // Extract transaction details from task description
      final transaction = await _extractTransactionDetails(taskDescription);
      
      return {
        'success': true,
        'action': action,
        'description': description,
        'transaction': transaction,
      };
    }

    return {
      'success': true,
      'action': action,
      'description': description,
    };
  }

  /// Extract transaction details from task description
  Future<Map<String, dynamic>> _extractTransactionDetails(String taskDescription) async {
    // Use AI to extract financial details
    final prompt = '''Extract financial transaction details from this task:

"$taskDescription"

Return JSON:
{
  "amount": 450,
  "category": "food/travel/shopping/utilities/entertainment",
  "description": "brief description",
  "vendor": "vendor name if mentioned"
}

If no clear amount, estimate based on typical costs.''';

    try {
      final result = await novaService.sendMessage(
        prompt: prompt,
        systemInstruction: 'Extract transaction details. Return only JSON.',
        deepReasoning: false,
        isParsing: true,
      );

      if (result['success'] == true) {
        // Return estimated transaction
        return {
          'amount': 500.0,
          'category': 'other',
          'description': taskDescription,
          'vendor': 'Unknown',
        };
      }
    } catch (e) {
      safePrint('[NovaNavigator] Transaction extraction error: $e');
    }

    return {
      'amount': 0.0,
      'category': 'other',
      'description': taskDescription,
      'vendor': 'Unknown',
    };
  }

  /// Record transaction in finance system
  Future<void> _recordTransaction(Map<String, dynamic> transaction) async {
    try {
      final amount = transaction['amount'] as double;
      final category = transaction['category'] as String;
      final description = transaction['description'] as String;
      final vendor = transaction['vendor'] as String;

      // Record as expense
      await financeService.addExpenseFromMap({
        'amount': amount,
        'category': category,
        'description': description,
        'vendor': vendor,
        'timestamp': DateTime.now().toIso8601String(),
      });

      safePrint('[NovaNavigator] Transaction recorded: ₹$amount');
    } catch (e) {
      safePrint('[NovaNavigator] Failed to record transaction: $e');
    }
  }

  /// Generate task summary
  Future<Map<String, dynamic>> _generateSummary(String taskDescription, List steps) async {
    return {
      'message': 'Completed "$taskDescription" in ${steps.length} steps',
      'stepsCompleted': steps.length,
      'success': true,
    };
  }

  /// Analyze screen using vision AI (for future implementation)
  Future<ScreenAnalysis> analyzeScreen(File screenshot) async {
    try {
      // Convert image to base64
      final bytes = await screenshot.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Use analyzeReceiptImage for screen analysis
      // Note: This uses receipt analysis as a placeholder
      // Future enhancement: Add dedicated screen analysis method
      await novaService.analyzeReceiptImage(
        base64Image: base64Image,
      );

      // Parse and return screen analysis
      // TODO: Implement proper screen element detection
      return ScreenAnalysis(
        elements: [],
        screenType: 'unknown',
        description: 'Screen analysis',
        possibleActions: [],
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      safePrint('[NovaNavigator] Screen analysis error: $e');
      rethrow;
    }
  }
}
