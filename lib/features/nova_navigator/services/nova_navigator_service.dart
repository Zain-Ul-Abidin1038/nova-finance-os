import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:nova_finance_os/features/nova_navigator/domain/navigation_task.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';
import 'package:nova_finance_os/features/finance/domain/expense_entry.dart';
import 'package:nova_finance_os/features/finance/domain/income_entry.dart';
import 'package:nova_finance_os/features/finance/domain/ledger_entry.dart';

final novaNavigatorServiceProvider = Provider((ref) => NovaNavigatorService(
      novaService: ref.read(novaServiceV3Provider),
      financeService: ref.read(unifiedFinanceServiceProvider),
    ));

class NovaNavigatorService {
  final NovaServiceV3 novaService;
  final UnifiedFinanceService financeService;

  // Callback for navigation — set by the screen
  void Function(String route)? onNavigate;

  NovaNavigatorService({
    required this.novaService,
    required this.financeService,
  });

  /// Execute a task autonomously with real actions
  Stream<Map<String, dynamic>> executeTask(NavigationTask task) async* {
    safePrint('[NovaNavigator] Starting task: ${task.description}');
    final desc = task.description.toLowerCase();

    try {
      // Step 1: Understand the task
      yield {
        'thought': 'Understanding your request...',
        'status': TaskStatus.planning
      };
      await Future.delayed(const Duration(milliseconds: 500));

      final action = _classifyTask(desc);
      yield {'log': '🎯 Task: ${task.description}'};
      yield {'log': '📋 Action: ${action['type']}'};

      // Step 2: Execute the real action
      yield {
        'thought': 'Executing: ${action['description']}...',
        'status': TaskStatus.executing
      };
      await Future.delayed(const Duration(milliseconds: 300));

      switch (action['type']) {
        case 'add_expense':
          yield* _handleAddExpense(desc, task.description);
          break;
        case 'add_income':
          yield* _handleAddIncome(desc, task.description);
          break;
        case 'add_loan':
          yield* _handleAddLoan(desc, task.description);
          break;
        case 'show_balance':
          yield* _handleShowBalance();
          break;
        case 'navigate':
          yield* _handleNavigation(action['route'] as String, action['description'] as String);
          break;
        case 'analyze':
          yield* _handleAnalyze(desc);
          break;
        default:
          yield* _handleGenericTask(task.description);
      }

      yield {'thought': 'Done!', 'status': TaskStatus.completed};
    } catch (e) {
      safePrint('[NovaNavigator] Error: $e');
      yield {'thought': 'Error occurred', 'status': TaskStatus.failed};
      yield {'log': '❌ Error: $e'};
    }
  }

  /// Classify what the user wants to do
  Map<String, dynamic> _classifyTask(String desc) {
    // Add expense
    if (desc.contains('spent') || desc.contains('bought') || desc.contains('purchased') || desc.contains('paid for')) {
      return {'type': 'add_expense', 'description': 'Recording expense'};
    }
    // Add income
    if (desc.contains('received') || desc.contains('got') || desc.contains('salary') || desc.contains('income') || desc.contains('earned')) {
      return {'type': 'add_income', 'description': 'Recording income'};
    }
    // Loans
    if (desc.contains('given to') || desc.contains('lent') || desc.contains('borrowed') || desc.contains('loan') || desc.contains('owe')) {
      return {'type': 'add_loan', 'description': 'Recording loan/ledger entry'};
    }
    // Balance / summary
    if (desc.contains('balance') || desc.contains('summary') || desc.contains('how much') || desc.contains('total')) {
      return {'type': 'show_balance', 'description': 'Showing financial summary'};
    }
    // Navigation to specific screens
    if (desc.contains('expense') && (desc.contains('screen') || desc.contains('page') || desc.contains('open') || desc.contains('go to') || desc.contains('show'))) {
      return {'type': 'navigate', 'route': '/expense', 'description': 'Opening Expenses screen'};
    }
    if (desc.contains('income') && (desc.contains('screen') || desc.contains('page') || desc.contains('open') || desc.contains('go to') || desc.contains('show'))) {
      return {'type': 'navigate', 'route': '/income', 'description': 'Opening Income screen'};
    }
    if (desc.contains('ledger') || desc.contains('loans')) {
      return {'type': 'navigate', 'route': '/ledger', 'description': 'Opening Ledger screen'};
    }
    if (desc.contains('analytics') || desc.contains('chart') || desc.contains('graph') || desc.contains('report')) {
      return {'type': 'navigate', 'route': '/analytics', 'description': 'Opening Analytics'};
    }
    if (desc.contains('profile') || desc.contains('settings') || desc.contains('account')) {
      return {'type': 'navigate', 'route': '/profile', 'description': 'Opening Profile'};
    }
    if (desc.contains('currency') || desc.contains('convert') || desc.contains('exchange rate')) {
      return {'type': 'navigate', 'route': '/currency-converter', 'description': 'Opening Currency Converter'};
    }
    if (desc.contains('portfolio') || desc.contains('investment')) {
      return {'type': 'navigate', 'route': '/portfolio', 'description': 'Opening Portfolio'};
    }
    if (desc.contains('crypto') || desc.contains('bitcoin')) {
      return {'type': 'navigate', 'route': '/crypto', 'description': 'Opening Crypto Dashboard'};
    }
    if (desc.contains('scan') || desc.contains('receipt') || desc.contains('camera')) {
      return {'type': 'navigate', 'route': '/camera', 'description': 'Opening Receipt Scanner'};
    }
    if (desc.contains('chat') || desc.contains('talk') || desc.contains('ask')) {
      return {'type': 'navigate', 'route': '/chat', 'description': 'Opening Chat'};
    }
    if (desc.contains('home') || desc.contains('dashboard')) {
      return {'type': 'navigate', 'route': '/', 'description': 'Going to Home'};
    }
    if (desc.contains('calendar') || desc.contains('schedule')) {
      return {'type': 'navigate', 'route': '/calendar', 'description': 'Opening Calendar'};
    }
    // Analyze spending
    if (desc.contains('analyze') || desc.contains('analysis') || desc.contains('insight') || desc.contains('pattern') || desc.contains('forecast') || desc.contains('budget')) {
      return {'type': 'analyze', 'description': 'Running financial analysis'};
    }
    return {'type': 'generic', 'description': 'Processing request'};
  }

  /// Extract amount from text
  double? _extractAmount(String text) {
    final match = RegExp(r'[\$₹]?\s*(\d+[\d,]*\.?\d*)').firstMatch(text);
    return match != null ? double.tryParse(match.group(1)!.replaceAll(',', '')) : null;
  }

  /// Handle adding an expense
  Stream<Map<String, dynamic>> _handleAddExpense(String desc, String original) async* {
    final amount = _extractAmount(desc);
    if (amount == null) {
      yield {'log': '⚠️ Could not find an amount. Please include a number.'};
      return;
    }

    String category = 'other';
    if (desc.contains('food') || desc.contains('lunch') || desc.contains('dinner')) category = 'food';
    else if (desc.contains('groceries')) category = 'groceries';
    else if (desc.contains('transport') || desc.contains('uber') || desc.contains('fuel')) category = 'transport';
    else if (desc.contains('rent')) category = 'rent';
    else if (desc.contains('bill') || desc.contains('electricity')) category = 'utilities';
    else if (desc.contains('shopping') || desc.contains('clothes')) category = 'shopping';
    else if (desc.contains('phone') || desc.contains('electronics')) category = 'electronics';

    yield {'log': '💳 Adding expense: ₹${amount.toStringAsFixed(0)} ($category)'};

    try {
      await financeService.initialize();
      final entry = ExpenseEntry.create(
        amount: amount,
        vendor: 'Via Navigator',
        description: original,
        category: category,
      );
      await financeService.addExpense(entry);
      yield {'log': '✅ Expense recorded: ₹${amount.toStringAsFixed(0)} in $category'};

      // Navigate to expense screen
      if (onNavigate != null) {
        yield {'log': '📱 Navigating to Expenses screen...'};
        onNavigate!('/expense');
      }
    } catch (e) {
      yield {'log': '❌ Failed to add expense: $e'};
    }
  }

  /// Handle adding income
  Stream<Map<String, dynamic>> _handleAddIncome(String desc, String original) async* {
    final amount = _extractAmount(desc);
    if (amount == null) {
      yield {'log': '⚠️ Could not find an amount. Please include a number.'};
      return;
    }

    String category = desc.contains('salary') ? 'salary' : 'income';
    String source = 'Unknown';
    final fromMatch = RegExp(r'from\s+(\w+)', caseSensitive: false).firstMatch(desc);
    if (fromMatch != null) source = fromMatch.group(1)!;

    yield {'log': '📥 Adding income: ₹${amount.toStringAsFixed(0)} from $source'};

    try {
      await financeService.initialize();
      final entry = IncomeEntry.create(
        amount: amount,
        source: source,
        description: original,
        category: category,
      );
      await financeService.addIncome(entry);
      yield {'log': '✅ Income recorded: ₹${amount.toStringAsFixed(0)} ($category)'};

      if (onNavigate != null) {
        yield {'log': '📱 Navigating to Income screen...'};
        onNavigate!('/income');
      }
    } catch (e) {
      yield {'log': '❌ Failed to add income: $e'};
    }
  }

  /// Handle adding loan/ledger entry
  Stream<Map<String, dynamic>> _handleAddLoan(String desc, String original) async* {
    final amount = _extractAmount(desc);
    if (amount == null) {
      yield {'log': '⚠️ Could not find an amount. Please include a number.'};
      return;
    }

    // Extract person name
    String person = 'Unknown';
    final toMatch = RegExp(r'(?:to|from)\s+(\w+)', caseSensitive: false).firstMatch(desc);
    if (toMatch != null) person = toMatch.group(1)!;

    final isGiven = desc.contains('given') || desc.contains('lent') || desc.contains('gave');
    final type = isGiven ? LedgerType.receivable : LedgerType.payable;
    final typeLabel = isGiven ? 'Receivable (they owe you)' : 'Payable (you owe them)';

    yield {'log': '📒 Adding ledger: ₹${amount.toStringAsFixed(0)} — $typeLabel — $person'};

    try {
      await financeService.initialize();
      final entry = LedgerEntry.create(
        amount: amount,
        personOrCompany: person,
        description: original,
        type: type,
      );
      await financeService.addLedgerEntry(entry);
      yield {'log': '✅ Ledger entry recorded: ₹${amount.toStringAsFixed(0)} with $person'};

      if (onNavigate != null) {
        yield {'log': '📱 Navigating to Ledger screen...'};
        onNavigate!('/ledger');
      }
    } catch (e) {
      yield {'log': '❌ Failed to add ledger entry: $e'};
    }
  }

  /// Handle showing balance
  Stream<Map<String, dynamic>> _handleShowBalance() async* {
    try {
      await financeService.initialize();
      final summary = financeService.getFinancialSummary();

      yield {'log': '📊 Financial Summary:'};
      yield {'log': '💰 Balance: ₹${(summary['balance'] as num).toStringAsFixed(2)}'};
      yield {'log': '📥 Total Income: ₹${(summary['totalIncome'] as num).toStringAsFixed(2)}'};
      yield {'log': '📤 Total Expenses: ₹${(summary['totalExpenses'] as num).toStringAsFixed(2)}'};
      yield {'log': '💸 Receivables: ₹${(summary['totalReceivables'] as num).toStringAsFixed(2)}'};
      yield {'log': '💳 Payables: ₹${(summary['totalPayables'] as num).toStringAsFixed(2)}'};
      yield {'log': '🏦 Net Worth: ₹${(summary['netWorth'] as num).toStringAsFixed(2)}'};

      if (onNavigate != null) {
        yield {'log': '📱 Navigating to Analytics...'};
        onNavigate!('/analytics');
      }
    } catch (e) {
      yield {'log': '❌ Failed to load summary: $e'};
    }
  }

  /// Handle navigation to a screen
  Stream<Map<String, dynamic>> _handleNavigation(String route, String description) async* {
    yield {'log': '📱 $description'};
    if (onNavigate != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      onNavigate!(route);
      yield {'log': '✅ Navigated to $route'};
    } else {
      yield {'log': '⚠️ Navigation not available from this context'};
    }
  }

  /// Handle financial analysis
  Stream<Map<String, dynamic>> _handleAnalyze(String desc) async* {
    try {
      await financeService.initialize();
      final summary = financeService.getFinancialSummary();
      final expenses = financeService.getExpensesByCategory();

      yield {'log': '🔍 Analyzing your finances...'};
      await Future.delayed(const Duration(milliseconds: 500));

      yield {'log': '📊 Balance: ₹${(summary['balance'] as num).toStringAsFixed(2)}'};

      if (expenses.isNotEmpty) {
        yield {'log': '\n📂 Spending by Category:'};
        final sorted = expenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final entry in sorted) {
          yield {'log': '  • ${entry.key}: ₹${entry.value.toStringAsFixed(0)}'};
        }

        final topCategory = sorted.first;
        yield {'log': '\n💡 Insight: Your highest spending is ${topCategory.key} at ₹${topCategory.value.toStringAsFixed(0)}'};
      } else {
        yield {'log': 'No expenses recorded yet. Start by adding some transactions!'};
      }

      if (onNavigate != null) {
        yield {'log': '\n📱 Opening Analytics for detailed view...'};
        onNavigate!('/analytics');
      }
    } catch (e) {
      yield {'log': '❌ Analysis failed: $e'};
    }
  }

  /// Handle generic/unknown tasks
  Stream<Map<String, dynamic>> _handleGenericTask(String description) async* {
    yield {'log': '🤔 Processing: $description'};

    // Try AI if available
    try {
      final result = await novaService.sendMessage(
        prompt: 'User asked: "$description". Provide a brief helpful response as a financial assistant. 2-3 sentences max.',
        systemInstruction: 'You are Finance OS navigator agent. Help users with financial tasks. Be concise.',
      );

      if (result['success'] == true) {
        final text = result['text'] ?? result['message'] ?? '';
        if (text.isNotEmpty) {
          yield {'log': '🧠 $text'};
          return;
        }
      }
    } catch (_) {}

    // Fallback
    yield {'log': '💡 I can help you with:'};
    yield {'log': '  • "I spent 500 on food" — record expenses'};
    yield {'log': '  • "Received 50000 salary" — record income'};
    yield {'log': '  • "Show my balance" — view summary'};
    yield {'log': '  • "Open analytics" — navigate to screens'};
    yield {'log': '  • "Analyze my spending" — get insights'};
  }

  /// Analyze screen using vision AI
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
