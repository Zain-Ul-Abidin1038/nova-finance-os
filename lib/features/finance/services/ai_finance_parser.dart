import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';
import 'package:nova_finance_os/features/finance/domain/income_entry.dart';
import 'package:nova_finance_os/features/finance/domain/expense_entry.dart';
import 'package:nova_finance_os/features/finance/domain/ledger_entry.dart';

final aiFinanceParserProvider = Provider((ref) => AIFinanceParser(
      novaService: ref.read(novaServiceV3Provider),
      financeService: ref.read(unifiedFinanceServiceProvider),
    ));

class AIFinanceParser {
  final NovaServiceV3 novaService;
  final UnifiedFinanceService financeService;

  AIFinanceParser({
    required this.novaService,
    required this.financeService,
  });

  /// Parse natural language and execute financial command
  Future<Map<String, dynamic>> parseAndExecute(String userMessage) async {
    safePrint('[AI Parser] Processing: $userMessage');

    // Check if message contains multiple transactions
    if (_containsMultipleTransactions(userMessage)) {
      return await _handleMultipleTransactions(userMessage);
    }

    // Process as single transaction
    return await _parseSingleTransaction(userMessage);
  }

  Future<Map<String, dynamic>> _executeAction(Map<String, dynamic> parsed) async {
    final action = parsed['action'];
    final amount = parsed['amount']?.toDouble();
    final category = parsed['category'] ?? 'other';
    final personName = parsed['personName'];
    final description = parsed['description'] ?? '';
    final vendor = parsed['vendor'] ?? personName ?? 'Unknown';

    try {
      switch (action) {
        case 'add_expense':
          if (amount == null) {
            return {'success': false, 'message': 'Amount is required'};
          }
          final entry = ExpenseEntry.create(
            amount: amount,
            vendor: vendor,
            description: description,
            category: category,
          );
          await financeService.addExpense(entry);
          return {
            'success': true,
            'message': '✓ Expense recorded: \$$amount at $vendor ($category)',
            'transaction': entry,
          };

        case 'add_income':
          if (amount == null) {
            return {'success': false, 'message': 'Amount is required'};
          }
          final entry = IncomeEntry.create(
            amount: amount,
            source: personName ?? 'Unknown',
            description: description,
            category: category,
          );
          await financeService.addIncome(entry);
          return {
            'success': true,
            'message': '✓ Income recorded: \$$amount from ${entry.source}',
            'transaction': entry,
          };

        case 'add_loan_given':
        case 'add_receivable':
          if (amount == null || personName == null) {
            return {
              'success': false,
              'message': 'Amount and person name are required'
            };
          }
          final entry = LedgerEntry.create(
            amount: amount,
            personOrCompany: personName,
            description: description,
            type: LedgerType.receivable,
          );
          await financeService.addLedgerEntry(entry);
          return {
            'success': true,
            'message': '✓ Receivable recorded: \$$amount from $personName',
            'transaction': entry,
          };

        case 'add_loan_received':
        case 'add_payable':
          if (amount == null || personName == null) {
            return {
              'success': false,
              'message': 'Amount and person name are required'
            };
          }
          final entry = LedgerEntry.create(
            amount: amount,
            personOrCompany: personName,
            description: description,
            type: LedgerType.payable,
          );
          await financeService.addLedgerEntry(entry);
          return {
            'success': true,
            'message': '✓ Payable recorded: \$$amount to $personName',
            'transaction': entry,
          };

        case 'query':
          final summary = financeService.getFinancialSummary();
          return {
            'success': true,
            'message': _formatSummary(summary),
            'summary': summary,
          };

        case 'unknown':
        default:
          // For non-financial messages, use Nova for general conversation
          return await _handleGeneralConversation(parsed, description);
      }
    } catch (e) {
      return {'success': false, 'message': 'Error executing command: $e'};
    }
  }

  String _formatSummary(Map<String, dynamic> summary) {
    return '''
📊 Financial Summary:

💰 Balance: \$${summary['balance'].toStringAsFixed(2)}
📤 Total Expenses: \$${summary['totalExpenses'].toStringAsFixed(2)}
📥 Total Income: \$${summary['totalIncome'].toStringAsFixed(2)}

💸 Money owed to you: \$${summary['totalReceivables'].toStringAsFixed(2)}
💳 Money you owe: \$${summary['totalPayables'].toStringAsFixed(2)}

🏦 Net Worth: \$${summary['netWorth'].toStringAsFixed(2)}

📊 Entries: ${summary['incomeCount']} income, ${summary['expenseCount']} expenses, ${summary['ledgerCount']} ledger
''';
  }

  /// Handle general conversation (non-financial messages)
  Future<Map<String, dynamic>> _handleGeneralConversation(
    Map<String, dynamic> parsed,
    String originalMessage,
  ) async {
    try {
      // Use Nova V3 for conversational response (auto-selects Flash)
      final response = await novaService.sendMessage(
        prompt: originalMessage,
        systemInstruction: '''You are Finance OS, a friendly AI financial assistant.

When users greet you or have general conversation:
- Respond warmly and professionally
- Introduce yourself as their personal financial assistant
- Mention you can help with: tracking expenses, analyzing receipts, managing loans, financial insights
- Keep responses concise (2-3 sentences)

Examples:
- "hi" → "Hello! I'm Finance OS, your AI financial assistant. I can help you track expenses, scan receipts, manage loans, and provide financial insights. How can I assist you today?"
- "how are you" → "I'm doing great, thank you! Ready to help you manage your finances. Would you like to log an expense, check your balance, or analyze a receipt?"
- "what can you do" → "I can help you track expenses, scan and analyze receipts with AI, manage IOUs, calculate tax deductions, and provide financial insights. Just tell me what you spent or ask about your finances!"

For financial commands, users can say things like:
- "I spent \$50 on lunch"
- "Add 500 rupees given to bilal"
- "Show my balance"
''',
        deepReasoning: false, // Fast conversational response
        isParsing: false,
      );

      return {
        'success': true,
        'message': response['text'] ?? 'Hello! How can I help you with your finances today?',
        'thoughtSignature': response['thoughtSignature'] ?? '',
      };
    } catch (e) {
      return {
        'success': true,
        'message': 'Hello! I\'m Finance OS, your AI financial assistant. I can help you track expenses, scan receipts, and manage your finances. Try saying "I spent \$50 on lunch" or "show my balance".',
        'thoughtSignature': '',
      };
    }
  }

  /// Check if message contains multiple transactions
  bool _containsMultipleTransactions(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Count "and" occurrences which often separate transactions
    final andCount = ' and '.allMatches(lowerMessage).length;
    
    // Count transaction keywords
    int transactionIndicators = 0;
    
    // Income indicators
    final incomeKeywords = ['received', 'got', 'salary', 'income', 'payment', 'paid me', 'gave me'];
    for (final keyword in incomeKeywords) {
      if (lowerMessage.contains(keyword)) transactionIndicators++;
    }
    
    // Expense indicators
    final expenseKeywords = ['spent', 'paid', 'bought', 'purchase'];
    for (final keyword in expenseKeywords) {
      if (lowerMessage.contains(keyword)) transactionIndicators++;
    }
    
    // Payable indicators (future payments)
    final payableKeywords = ['have to pay', 'need to pay', 'have to give', 'need to give', 'owe', 'bill'];
    for (final keyword in payableKeywords) {
      if (lowerMessage.contains(keyword)) transactionIndicators++;
    }
    
    // Loan given indicators (money others owe you)
    final loanGivenKeywords = ['given to', 'lent', 'gave to', 'took from me', 'borrowed from me', 'took loan from me', 'have to give me', 'need to give me'];
    for (final keyword in loanGivenKeywords) {
      if (lowerMessage.contains(keyword)) transactionIndicators++;
    }
    
    // CRITICAL FIX: If we have ANY "and" with 2+ transaction indicators, it's multiple transactions
    if (andCount >= 1 && transactionIndicators >= 2) {
      safePrint('[AI Parser] Multi-transaction detected: $andCount "and" + $transactionIndicators indicators');
      return true;
    }
    
    // If we have 3+ transaction indicators even without "and", it's likely multiple
    if (transactionIndicators >= 3) {
      safePrint('[AI Parser] Multi-transaction detected: $transactionIndicators indicators (no "and" needed)');
      return true;
    }
    
    safePrint('[AI Parser] Single transaction: $andCount "and" + $transactionIndicators indicators');
    return false;
  }

  /// Handle multiple transactions by splitting and processing each
  Future<Map<String, dynamic>> _handleMultipleTransactions(String userMessage) async {
    safePrint('[AI Parser] Detected multiple transactions, splitting...');
    
    // Use Nova to split the message into individual transactions
    final splitPrompt = '''Split this complex financial message into separate individual transactions.

User said: "$userMessage"

Return ONLY a JSON array where each item is ONE separate transaction description.

Examples:
Input: "I spent 500 on food and given 40000 to ahmed as loan and got 90000 salary"
Output: ["I spent 500 on food", "given 40000 to ahmed as loan", "got 90000 salary"]

Input: "i got 20000 from client and ali have to give me 2000 next week he took loan from me"
Output: ["i got 20000 from client", "ali have to give me 2000 next week he took loan from me"]

Input: "i got payment from client which is 200000 and i have to pay gas bill next week to gas company which is 12000 and have to give house rent which is 50000 and ali took 30000 from me he will return to me next month and i spent 20000 to get new smart phone"
Output: ["i got payment from client which is 200000", "i have to pay gas bill next week to gas company which is 12000", "have to give house rent which is 50000", "ali took 30000 from me he will return to me next month", "i spent 20000 to get new smart phone"]

IMPORTANT: Return ONLY the JSON array with transaction strings, no other text or explanation.''';

    try {
      final splitResponse = await novaService.sendMessage(
        prompt: splitPrompt,
        systemInstruction: '''You are a transaction splitter. Your ONLY job is to split complex financial messages into individual transactions.

Rules:
1. Return ONLY a valid JSON array
2. Each array item is ONE transaction
3. Keep the original wording for each transaction
4. No explanations, no markdown, just the JSON array
5. Look for keywords like "and", "also", "then" to identify separate transactions
6. Can handle up to 50+ transactions in one message''',
        isParsing: true,
        deepReasoning: false,
        isMultiTransaction: true, // Use higher token limit for large arrays
      );

      if (splitResponse['success'] != true) {
        safePrint('[AI Parser] Could not split transactions, processing as single');
        return await _parseSingleTransaction(userMessage);
      }

      final splitText = splitResponse['text'] ?? '';
      safePrint('[AI Parser] Split response: $splitText');
      
      // Extract JSON array - try multiple patterns
      List<dynamic>? transactions;
      
      // Try direct JSON parse
      try {
        transactions = jsonDecode(splitText.trim()) as List;
      } catch (_) {
        // Try to extract JSON array from text
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(splitText);
        if (jsonMatch != null) {
          try {
            transactions = jsonDecode(jsonMatch.group(0)!) as List;
          } catch (e) {
            safePrint('[AI Parser] Could not parse JSON array: $e');
          }
        }
      }
      
      if (transactions == null || transactions.isEmpty) {
        safePrint('[AI Parser] Could not extract transactions array, processing as single');
        return await _parseSingleTransaction(userMessage);
      }

      safePrint('[AI Parser] Split into ${transactions.length} transactions');

      // Process each transaction sequentially
      final results = <Map<String, dynamic>>[];
      final messages = <String>[];
      final failedTransactions = <String>[];
      
      // Reduce delay for faster processing (100ms instead of 200ms)
      const delayBetweenTransactions = Duration(milliseconds: 100);
      
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i].toString();
        safePrint('[AI Parser] Processing transaction ${i + 1}/${transactions.length}: $transaction');
        
        try {
          final result = await _parseSingleTransaction(transaction);
          if (result['success'] == true) {
            results.add(result);
            messages.add(result['message']);
          } else {
            failedTransactions.add(transaction);
            safePrint('[AI Parser] Failed to process: $transaction');
          }
        } catch (e) {
          failedTransactions.add(transaction);
          safePrint('[AI Parser] Error processing transaction: $e');
        }
        
        // Small delay between transactions to avoid rate limiting
        // Reduced to 100ms for faster processing
        if (i < transactions.length - 1) {
          await Future.delayed(delayBetweenTransactions);
        }
      }

      if (results.isEmpty) {
        return {
          'success': false,
          'message': 'Could not process any of the ${transactions.length} transactions. Please try describing them one at a time.',
          'thoughtSignature': '',
        };
      }

      // Build success message
      String finalMessage = '✓ Successfully recorded ${results.length} out of ${transactions.length} transactions:\n\n${messages.join('\n\n')}';
      
      if (failedTransactions.isNotEmpty) {
        finalMessage += '\n\n⚠️ Could not process ${failedTransactions.length} transaction(s). Please try again separately.';
      }

      return {
        'success': true,
        'message': finalMessage,
        'thoughtSignature': splitResponse['thoughtSignature'] ?? '',
        'transactions': results,
        'failedCount': failedTransactions.length,
      };
    } catch (e) {
      safePrint('[AI Parser] Error splitting transactions: $e');
      // Fall back to single transaction processing
      return await _parseSingleTransaction(userMessage);
    }
  }

  /// Parse and execute a single transaction
  Future<Map<String, dynamic>> _parseSingleTransaction(String userMessage) async {
    final prompt = '''Parse this financial command and extract structured data.

User said: "$userMessage"

Return ONLY a JSON object with these fields:
- action: one of [add_expense, add_income, add_loan_given, add_loan_received, add_receivable, add_payable, query, unknown]
- amount: numeric value (required for transactions)
- currency: "INR" or "USD" etc
- category: expense/income category
- personName: person's name (for loans/receivables/payables)
- description: brief description

Examples:
- "add 500 rupees which I have given to my friend bilal as in help category" 
  → {"action":"add_loan_given","amount":500,"currency":"INR","category":"help","personName":"bilal","description":"help"}

- "I spent 1200 on groceries"
  → {"action":"add_expense","amount":1200,"currency":"INR","category":"groceries","personName":null,"description":"groceries"}

- "received 5000 salary"
  → {"action":"add_income","amount":5000,"currency":"INR","category":"salary","personName":null,"description":"salary"}

- "I got payment from client which is 200000"
  → {"action":"add_income","amount":200000,"currency":"INR","category":"client payment","personName":"client","description":"client payment"}

- "i have to pay gas bill next week to gas company which is 12000"
  → {"action":"add_payable","amount":12000,"currency":"INR","category":"utilities","personName":"gas company","description":"gas bill"}

- "have to give house rent which is 50000"
  → {"action":"add_payable","amount":50000,"currency":"INR","category":"rent","personName":"landlord","description":"house rent"}

- "ali took 30000 from me he will return to me next month"
  → {"action":"add_loan_given","amount":30000,"currency":"INR","category":"loan","personName":"ali","description":"loan to ali"}

- "ali have to give me 2000 next week he took loan from me"
  → {"action":"add_receivable","amount":2000,"currency":"INR","category":"loan","personName":"ali","description":"loan repayment from ali"}

- "i spent 20000 to get new smart phone"
  → {"action":"add_expense","amount":20000,"currency":"INR","category":"electronics","personName":null,"description":"new smart phone"}

IMPORTANT: 
- "have to give me" or "need to give me" = add_receivable (money coming to you)
- "have to give" or "need to give" (without "me") = add_payable (money you owe)
- "took from me" or "borrowed from me" = add_loan_given or add_receivable

Return ONLY the JSON object, no other text.''';

    try {
      final response = await novaService.sendStructuredMessage(
        prompt: prompt,
        responseSchema: NovaSchemas.financeCommand,
        systemInstruction: '''You are a financial data parser. Extract structured financial data from user messages.

Rules:
1. Return ONLY valid JSON matching the schema
2. Use "add_income" for money received (salary, payment, etc)
3. Use "add_expense" for money spent (purchases, bills paid immediately)
4. Use "add_payable" for bills/debts to pay in future (I have to pay, I need to give)
5. Use "add_receivable" or "add_loan_given" for money others owe you (have to give ME, took from ME, borrowed from ME)
6. Use "add_loan_received" for money you borrowed
7. Always include amount as a number
8. Set personName for loans and receivables/payables
9. Infer category from context (utilities, rent, loan, salary, etc)

CRITICAL: 
- "X have to give me Y" = add_receivable (X owes you)
- "I have to give X Y" = add_payable (you owe X)
- "X took Y from me" = add_receivable (X owes you)''',
        isParsing: true,
      );

      if (response['success'] == true) {
        final parsed = response['data'] as Map<String, dynamic>;
        final thoughtSignature = response['thoughtSignature'] ?? '';
        
        safePrint('[AI Parser] Parsed: $parsed');

        // Execute the action
        final result = await _executeAction(parsed);
        result['thoughtSignature'] = thoughtSignature;
        
        return result;
      } else {
        return {
          'success': false,
          'message': 'Could not parse command: ${response['error']}',
          'thoughtSignature': '',
        };
      }
    } catch (e) {
      safePrint('[AI Parser] Error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'thoughtSignature': '',
      };
    }
  }
}