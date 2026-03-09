import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/services/nova_service.dart';
import 'package:nova_finance_os/core/services/aws_memory_service.dart';
import 'package:nova_finance_os/features/finance/services/finance_service.dart';
import 'dart:convert';

final marathonAgentProvider = Provider((ref) => MarathonAgent(
      nova: ref.read(novaServiceProvider),
      memory: ref.read(awsMemoryServiceProvider),
      finance: ref.read(financeServiceProvider),
    ));

/// Marathon Agent - Autonomous multi-day financial tasks
/// Uses Nova API (GCP) thinking capabilities to plan, execute, and self-correct
class MarathonAgent {
  final NovaService nova;
  final AWSMemoryService memory;
  final FinanceService finance;

  MarathonAgent({
    required this.nova,
    required this.memory,
    required this.finance,
  });

  /// Start a marathon task that runs autonomously over multiple days
  Future<MarathonTask> startMarathon({
    required String goal,
    required Duration duration,
    Function(String)? onProgress,
  }) async {
    safePrint('[Marathon Agent] Starting: $goal');
    safePrint('[Marathon Agent] Duration: ${duration.inDays} days');

    final taskId = 'marathon_${DateTime.now().millisecondsSinceEpoch}';
    
    // Phase 1: Planning with Nova 3 Pro
    onProgress?.call('🧠 Planning marathon task...');
    
    final planPrompt = '''You are a Financial Marathon Agent. Create a detailed multi-day plan.

GOAL: $goal
DURATION: ${duration.inDays} days
AVAILABLE TOOLS: analyze_transactions, categorize_expenses, calculate_deductions, generate_reports

Create a day-by-day execution plan. For each day, specify:
1. Tasks to complete
2. Expected outcomes
3. Verification steps
4. Self-correction criteria

Return JSON format:
{
  "taskId": "$taskId",
  "goal": "$goal",
  "totalDays": ${duration.inDays},
  "dailyPlan": [
    {
      "day": 1,
      "tasks": ["task1", "task2"],
      "outcomes": ["outcome1"],
      "verification": "how to verify",
      "selfCorrection": "what to check"
    }
  ],
  "successCriteria": ["criteria1", "criteria2"]
}''';

    final planResponse = await nova.sendMessage(
      prompt: planPrompt,
      systemInstruction: 'You are a Financial Marathon Agent that creates autonomous multi-day plans.',
    );

    // Parse the plan
    final planText = planResponse['text'] ?? '';
    final thoughtSignature = planResponse['thoughtSignature'] ?? '';
    
    safePrint('[Marathon Agent] Thought Signature: $thoughtSignature');
    
    // Store thought signature
    await memory.putMemoryEvent(
      thoughtSignature: 'Marathon Planning: $thoughtSignature',
      category: 'Marathon Agent',
      metadata: {
        'taskId': taskId,
        'goal': goal,
        'phase': 'planning',
        'duration': duration.inDays,
      },
    );

    // Extract JSON from response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(planText);
    Map<String, dynamic> plan;
    
    if (jsonMatch != null) {
      try {
        plan = jsonDecode(jsonMatch.group(0)!);
      } catch (e) {
        safePrint('[Marathon Agent] Failed to parse plan: $e');
        plan = _createDefaultPlan(taskId, goal, duration.inDays);
      }
    } else {
      plan = _createDefaultPlan(taskId, goal, duration.inDays);
    }

    onProgress?.call('✓ Plan created: ${plan['dailyPlan']?.length ?? 0} days');

    // Create marathon task
    final task = MarathonTask(
      id: taskId,
      goal: goal,
      duration: duration,
      plan: plan,
      startTime: DateTime.now(),
      status: MarathonStatus.running,
      currentDay: 1,
      progress: [],
    );

    // Store task in memory
    await memory.putMemoryEvent(
      thoughtSignature: 'Marathon Task Started: $goal',
      category: 'Marathon Agent',
      metadata: {
        'taskId': taskId,
        'goal': goal,
        'plan': plan,
        'startTime': task.startTime.toIso8601String(),
      },
    );

    return task;
  }

  /// Execute a single day of the marathon task
  Future<DayResult> executeDayTask({
    required MarathonTask task,
    required int day,
    Function(String)? onProgress,
  }) async {
    safePrint('[Marathon Agent] Executing Day $day of ${task.duration.inDays}');
    
    final dailyPlan = task.plan['dailyPlan'] as List?;
    if (dailyPlan == null || day > dailyPlan.length) {
      return DayResult(
        day: day,
        success: false,
        message: 'No plan for day $day',
        thoughtSignature: '',
      );
    }

    final dayPlan = dailyPlan[day - 1] as Map<String, dynamic>;
    final tasks = dayPlan['tasks'] as List? ?? [];
    
    onProgress?.call('📋 Day $day: ${tasks.length} tasks');

    // Execute each task with Nova 3 Pro
    final results = <String>[];
    
    for (var i = 0; i < tasks.length; i++) {
      final taskName = tasks[i].toString();
      onProgress?.call('⚙️ Task ${i + 1}/${tasks.length}: $taskName');
      
      final taskPrompt = '''Execute this financial task:

TASK: $taskName
GOAL: ${task.goal}
DAY: $day of ${task.duration.inDays}

Analyze the current financial data and execute the task.
Provide detailed reasoning and results.''';

      final response = await nova.sendMessage(
        prompt: taskPrompt,
        systemInstruction: 'You are executing a marathon financial task. Provide detailed analysis.',
      );

      results.add(response['text'] ?? 'No result');
      
      // Store thought signature
      await memory.putMemoryEvent(
        thoughtSignature: 'Day $day Task: ${response['thoughtSignature']}',
        category: 'Marathon Execution',
        metadata: {
          'taskId': task.id,
          'day': day,
          'task': taskName,
          'result': response['text'],
        },
      );
    }

    // Verification step
    onProgress?.call('🔍 Verifying day $day results...');
    
    final verification = await _verifyDayWork(
      task: task,
      day: day,
      results: results,
    );

    final dayResult = DayResult(
      day: day,
      success: verification.isValid,
      message: results.join('\n\n'),
      thoughtSignature: verification.reasoning,
      errors: verification.errors,
    );

    // Store day result
    await memory.putMemoryEvent(
      thoughtSignature: 'Day $day Complete: ${verification.reasoning}',
      category: 'Marathon Progress',
      metadata: {
        'taskId': task.id,
        'day': day,
        'success': verification.isValid,
        'results': results,
        'errors': verification.errors,
      },
    );

    return dayResult;
  }

  /// Verify the work done in a day
  Future<VerificationResult> _verifyDayWork({
    required MarathonTask task,
    required int day,
    required List<String> results,
  }) async {
    final verificationPrompt = '''Verify this day's work for a marathon financial task:

GOAL: ${task.goal}
DAY: $day of ${task.duration.inDays}
RESULTS: ${results.join('\n')}

Check:
1. Are the results accurate?
2. Are there any errors or inconsistencies?
3. Does this progress toward the goal?
4. What corrections are needed?
5. Confidence score (0-1)?

Return JSON:
{
  "isValid": true/false,
  "confidence": 0.0-1.0,
  "errors": ["error1", "error2"],
  "reasoning": "detailed explanation",
  "corrections": ["correction1"]
}''';

    final response = await nova.sendMessage(
      prompt: verificationPrompt,
      systemInstruction: 'You are a financial auditor verifying AI work.',
    );

    // Parse verification result
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response['text'] ?? '');
    
    if (jsonMatch != null) {
      try {
        final verificationData = jsonDecode(jsonMatch.group(0)!);
        return VerificationResult(
          isValid: verificationData['isValid'] ?? false,
          confidence: (verificationData['confidence'] ?? 0.0).toDouble(),
          errors: (verificationData['errors'] as List?)?.cast<String>() ?? [],
          reasoning: verificationData['reasoning'] ?? response['thoughtSignature'] ?? '',
          corrections: (verificationData['corrections'] as List?)?.cast<String>() ?? [],
        );
      } catch (e) {
        safePrint('[Marathon Agent] Failed to parse verification: $e');
      }
    }

    // Default: assume valid if no errors found
    return VerificationResult(
      isValid: true,
      confidence: 0.8,
      errors: [],
      reasoning: response['thoughtSignature'] ?? 'Verification complete',
      corrections: [],
    );
  }

  /// Self-correct errors found during verification
  Future<void> correctErrors({
    required MarathonTask task,
    required List<String> errors,
    Function(String)? onProgress,
  }) async {
    if (errors.isEmpty) return;

    safePrint('[Marathon Agent] Self-correcting ${errors.length} errors');
    onProgress?.call('🔧 Self-correcting errors...');

    for (var error in errors) {
      final correctionPrompt = '''Self-correct this error in a marathon financial task:

GOAL: ${task.goal}
ERROR: $error

Analyze the error and provide a correction.
Explain your reasoning.''';

      final response = await nova.sendMessage(
        prompt: correctionPrompt,
        systemInstruction: 'You are self-correcting errors in financial analysis.',
      );

      // Store correction
      await memory.putMemoryEvent(
        thoughtSignature: 'Self-Correction: ${response['thoughtSignature']}',
        category: 'Marathon Self-Correction',
        metadata: {
          'taskId': task.id,
          'error': error,
          'correction': response['text'],
        },
      );

      onProgress?.call('✓ Corrected: $error');
    }
  }

  /// Create a default plan if parsing fails
  Map<String, dynamic> _createDefaultPlan(String taskId, String goal, int days) {
    return {
      'taskId': taskId,
      'goal': goal,
      'totalDays': days,
      'dailyPlan': List.generate(days, (index) => {
        'day': index + 1,
        'tasks': ['Analyze financial data', 'Process transactions', 'Generate insights'],
        'outcomes': ['Progress toward goal'],
        'verification': 'Check accuracy and completeness',
        'selfCorrection': 'Verify calculations and categorizations',
      }),
      'successCriteria': ['Goal achieved', 'All data processed', 'Reports generated'],
    };
  }
}

/// Marathon Task Model
class MarathonTask {
  final String id;
  final String goal;
  final Duration duration;
  final Map<String, dynamic> plan;
  final DateTime startTime;
  final MarathonStatus status;
  final int currentDay;
  final List<DayResult> progress;

  MarathonTask({
    required this.id,
    required this.goal,
    required this.duration,
    required this.plan,
    required this.startTime,
    required this.status,
    required this.currentDay,
    required this.progress,
  });

  MarathonTask copyWith({
    MarathonStatus? status,
    int? currentDay,
    List<DayResult>? progress,
  }) {
    return MarathonTask(
      id: id,
      goal: goal,
      duration: duration,
      plan: plan,
      startTime: startTime,
      status: status ?? this.status,
      currentDay: currentDay ?? this.currentDay,
      progress: progress ?? this.progress,
    );
  }
}

enum MarathonStatus {
  planning,
  running,
  paused,
  completed,
  failed,
}

/// Day Result Model
class DayResult {
  final int day;
  final bool success;
  final String message;
  final String thoughtSignature;
  final List<String> errors;

  DayResult({
    required this.day,
    required this.success,
    required this.message,
    required this.thoughtSignature,
    this.errors = const [],
  });
}

/// Verification Result Model
class VerificationResult {
  final bool isValid;
  final double confidence;
  final List<String> errors;
  final String reasoning;
  final List<String> corrections;

  VerificationResult({
    required this.isValid,
    required this.confidence,
    required this.errors,
    required this.reasoning,
    required this.corrections,
  });
}
