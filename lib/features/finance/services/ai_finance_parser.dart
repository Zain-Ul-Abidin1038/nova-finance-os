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
      // Use Nova V3 for conversational response
      final response = await novaService.sendMessage(
        prompt: originalMessage,
        systemInstruction: '''You are Finance OS, a friendly AI financial assistant.

When users greet you or have general conversation:
- Respond warmly and professionally
- Introduce yourself as their personal financial assistant
- Mention you can help with: tracking expenses, analyzing receipts, managing loans, financial insights
- Keep responses concise (2-3 sentences)

For financial commands, users can say things like:
- "I spent 50 on lunch"
- "Add 500 given to bilal"
- "Show my balance"
''',
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['text'] ?? response['message'] ?? _localConversationResponse(originalMessage),
          'thoughtSignature': response['thoughtSignature'] ?? '',
        };
      }
      
      // Bedrock unavailable — use local response
      return {
        'success': true,
        'message': _localConversationResponse(originalMessage),
        'thoughtSignature': '',
      };
    } catch (e) {
      return {
        'success': true,
        'message': _localConversationResponse(originalMessage),
        'thoughtSignature': '',
      };
    }
  }

  /// Local conversation response when AI is unavailable
  String _localConversationResponse(String message) {
    final msg = message.toLowerCase().trim();
    
    if (msg.contains('hi') || msg.contains('hello') || msg.contains('hey') || msg.contains('assalam') || msg == 'yo') {
      return 'Hello! I\'m Finance OS, your AI financial assistant. I can help you track expenses, manage loans, and provide financial insights.\n\nTry saying:\n• "I spent 500 on food"\n• "Received 50000 salary"\n• "Given 2000 to Ahmed"\n• "Show my balance"';
    }
    
    if (msg.contains('how are you') || msg.contains('what\'s up') || msg.contains('how do you do')) {
      return 'I\'m doing great, thanks for asking! Ready to help you manage your finances. What would you like to do?';
    }
    
    if (msg.contains('what can you do') || msg.contains('help') || msg.contains('features')) {
      return 'I can help you with:\n\n• Track expenses — "I spent 1200 on groceries"\n• Record income — "Got 50000 salary"\n• Manage loans — "Given 5000 to Ali"\n• Track payables — "Have to pay 12000 rent"\n• View balance — "Show my balance"\n\nJust type naturally and I\'ll handle the rest!';
    }
    
    if (msg.contains('thank') || msg.contains('thanks')) {
      return 'You\'re welcome! Let me know if you need anything else. 😊';
    }
    
    return 'I\'m Finance OS, your financial assistant. I can track expenses, income, loans, and more.\n\nTry: "I spent 500 on food" or "Show my balance"';
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
    // First try local keyword parsing (works without AI)
    final localParsed = _localParse(userMessage);
    
    // If local parsing found a clear financial action, use it directly
    if (localParsed != null && localParsed['action'] != 'unknown') {
      safePrint('[AI Parser] Local parse: $localParsed');
      final result = await _executeAction(localParsed);
      result['thoughtSignature'] = 'Parsed locally';
      return result;
    }

    // Try AI parsing via Bedrock
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
- "I spent 1200 on groceries" → {"action":"add_expense","amount":1200,"currency":"INR","category":"groceries","description":"groceries"}
- "received 5000 salary" → {"action":"add_income","amount":5000,"currency":"INR","category":"salary","description":"salary"}
- "given 40000 to ahmed" → {"action":"add_loan_given","amount":40000,"currency":"INR","category":"loan","personName":"ahmed","description":"loan to ahmed"}
- "ali took 30000 from me" → {"action":"add_receivable","amount":30000,"currency":"INR","category":"loan","personName":"ali","description":"loan to ali"}
- "have to pay 12000 gas bill" → {"action":"add_payable","amount":12000,"currency":"INR","category":"utilities","personName":"gas company","description":"gas bill"}

Return ONLY the JSON object, no other text.''';

    try {
      final response = await novaService.sendStructuredMessage(
        prompt: prompt,
        responseSchema: NovaSchemas.financeCommand,
        systemInstruction: 'You are a financial data parser. Extract structured financial data from user messages. Return ONLY valid JSON.',
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data == null || data is! Map<String, dynamic>) {
          // AI returned text but not parseable JSON — treat as general conversation
          return await _handleGeneralConversation(
            {'action': 'unknown'},
            userMessage,
          );
        }
        final parsed = data;
        final thoughtSignature = response['thoughtSignature'] ?? '';
        
        safePrint('[AI Parser] Parsed: $parsed');

        // Execute the action
        final result = await _executeAction(parsed);
        result['thoughtSignature'] = thoughtSignature;
        
        return result;
      } else {
        // Bedrock failed — if local parse found unknown, handle as conversation
        if (localParsed != null && localParsed['action'] == 'unknown') {
          return await _handleGeneralConversation(localParsed, userMessage);
        }
        return {
          'success': false,
          'message': 'Could not parse command: ${response['error']}',
          'thoughtSignature': '',
        };
      }
    } catch (e) {
      safePrint('[AI Parser] Error: $e');
      // Fallback to local parse result or conversation
      if (localParsed != null && localParsed['action'] == 'unknown') {
        return await _handleGeneralConversation(localParsed, userMessage);
      }
      return {
        'success': false,
        'message': 'Error: $e',
        'thoughtSignature': '',
      };
    }
  }

  /// Local keyword-based parser — works without AI/Bedrock
  Map<String, dynamic>? _localParse(String userMessage) {
    final msg = userMessage.toLowerCase().trim();
    
    // Extract amount using regex
    final amountMatch = RegExp(r'[\$₹]?\s*(\d+[\d,]*\.?\d*)').firstMatch(msg);
    final amount = amountMatch != null 
        ? double.tryParse(amountMatch.group(1)!.replaceAll(',', ''))
        : null;

    // Query commands
    if (msg.contains('balance') || msg.contains('summary') || msg.contains('show') || msg.contains('how much')) {
      return {'action': 'query', 'amount': null, 'category': 'query', 'description': userMessage};
    }

    // Expense keywords
    if (msg.contains('spent') || msg.contains('bought') || msg.contains('purchased')) {
      if (amount != null) {
        final category = _inferCategory(msg);
        return {
          'action': 'add_expense',
          'amount': amount,
          'category': category,
          'description': userMessage,
          'personName': null,
        };
      }
    }

    // Income keywords
    if (msg.contains('received') || msg.contains('got') || msg.contains('salary') || msg.contains('income') || msg.contains('earned')) {
      if (amount != null) {
        final category = msg.contains('salary') ? 'salary' : 'income';
        return {
          'action': 'add_income',
          'amount': amount,
          'category': category,
          'description': userMessage,
          'personName': null,
        };
      }
    }

    // Loan given / receivable
    if (msg.contains('given to') || msg.contains('lent to') || msg.contains('gave to') || msg.contains('took from me') || msg.contains('borrowed from me')) {
      if (amount != null) {
        final person = _extractPerson(msg);
        return {
          'action': 'add_loan_given',
          'amount': amount,
          'category': 'loan',
          'description': userMessage,
          'personName': person,
        };
      }
    }

    // Receivable (someone owes you)
    if (msg.contains('have to give me') || msg.contains('owes me') || msg.contains('need to give me')) {
      if (amount != null) {
        final person = _extractPerson(msg);
        return {
          'action': 'add_receivable',
          'amount': amount,
          'category': 'loan',
          'description': userMessage,
          'personName': person,
        };
      }
    }

    // Payable (you owe someone)
    if (msg.contains('have to pay') || msg.contains('need to pay') || msg.contains('have to give') || msg.contains('owe')) {
      if (amount != null) {
        final person = _extractPerson(msg);
        final category = _inferCategory(msg);
        return {
          'action': 'add_payable',
          'amount': amount,
          'category': category,
          'description': userMessage,
          'personName': person ?? 'Unknown',
        };
      }
    }

    // Paid (expense with vendor)
    if (msg.contains('paid')) {
      if (amount != null) {
        final category = _inferCategory(msg);
        return {
          'action': 'add_expense',
          'amount': amount,
          'category': category,
          'description': userMessage,
          'personName': null,
        };
      }
    }

    // No financial action detected — mark as unknown for general conversation
    return {'action': 'unknown', 'description': userMessage};
  }

  String _inferCategory(String msg) {
    if (msg.contains('food') || msg.contains('lunch') || msg.contains('dinner') || msg.contains('breakfast') || msg.contains('pizza') || msg.contains('restaurant')) return 'food';
    if (msg.contains('groceries') || msg.contains('grocery')) return 'groceries';
    if (msg.contains('transport') || msg.contains('uber') || msg.contains('taxi') || msg.contains('fuel') || msg.contains('gas')) return 'transport';
    if (msg.contains('rent') || msg.contains('house')) return 'rent';
    if (msg.contains('bill') || msg.contains('electricity') || msg.contains('water') || msg.contains('internet')) return 'utilities';
    if (msg.contains('phone') || msg.contains('laptop') || msg.contains('electronics')) return 'electronics';
    if (msg.contains('shopping') || msg.contains('clothes') || msg.contains('shoes')) return 'shopping';
    if (msg.contains('entertainment') || msg.contains('movie') || msg.contains('game')) return 'entertainment';
    if (msg.contains('medical') || msg.contains('doctor') || msg.contains('hospital') || msg.contains('medicine')) return 'medical';
    return 'other';
  }

  String? _extractPerson(String msg) {
    // Try patterns like "to X", "from X", "X took", "X owes"
    final patterns = [
      RegExp(r'(?:given to|lent to|gave to|paid to)\s+(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s+(?:took|borrowed|owes)', caseSensitive: false),
      RegExp(r'(?:from)\s+(\w+)', caseSensitive: false),
      RegExp(r'(?:to)\s+(\w+)', caseSensitive: false),
    ];
    
    final stopWords = {'me', 'my', 'i', 'the', 'a', 'an', 'pay', 'give', 'get', 'have', 'need', 'will', 'next', 'this', 'that'};
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(msg);
      if (match != null) {
        final name = match.group(1)!.toLowerCase();
        if (!stopWords.contains(name) && name.length > 1) {
          return match.group(1)!;
        }
      }
    }
    return null;
  }
}