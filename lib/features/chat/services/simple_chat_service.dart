import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:nova_finance_os/features/finance/services/ai_finance_parser.dart';
import 'package:nova_finance_os/features/finance/services/unified_finance_service.dart';
import 'package:nova_finance_os/features/finance/domain/expense_entry.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:io';
import 'dart:convert';

part 'simple_chat_service.g.dart';

final simpleChatServiceProvider = Provider((ref) => SimpleChatService(
      novaService: ref.read(novaServiceV3Provider),
      financeParser: ref.read(aiFinanceParserProvider),
      financeService: ref.read(unifiedFinanceServiceProvider),
    ));

@HiveType(typeId: 3)
class ChatMessage {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool isUser;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String? thoughtSignature;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.thoughtSignature,
  });
}

class SimpleChatService {
  final NovaServiceV3 novaService;
  final AIFinanceParser financeParser;
  final UnifiedFinanceService financeService;
  
  static const String _boxName = 'chat_messages';
  Box<ChatMessage>? _box;
  
  // Conversation context for intelligent follow-ups
  final List<Map<String, String>> _conversationHistory = [];

  SimpleChatService({
    required this.novaService,
    required this.financeParser,
    required this.financeService,
  });

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    _box = await Hive.openBox<ChatMessage>(_boxName);
  }

  Future<void> saveMessage(ChatMessage message) async {
    await _box?.add(message);
  }

  List<ChatMessage> getMessages() {
    return _box?.values.toList() ?? [];
  }

  Future<void> clearMessages() async {
    await _box?.clear();
    _conversationHistory.clear();
  }

  /// Process user message with intelligent follow-ups
  Future<Map<String, dynamic>> processMessage(String userMessage) async {
    safePrint('[SimpleChatService] Processing: $userMessage');
    
    // Add to conversation history
    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });

    // Keep only last 10 messages for context
    if (_conversationHistory.length > 10) {
      _conversationHistory.removeAt(0);
    }

    try {
      // First, try to parse as financial command
      final parseResult = await financeParser.parseAndExecute(userMessage);
      
      safePrint('[SimpleChatService] Parse result: $parseResult');
      
      // Check if we need more information
      final needsFollowUp = _needsFollowUpQuestion(parseResult, userMessage);
      
      if (needsFollowUp != null) {
        // Ask intelligent follow-up question
        _conversationHistory.add({
          'role': 'assistant',
          'content': needsFollowUp,
        });
        
        return {
          'success': true,
          'message': needsFollowUp,
          'thoughtSignature': parseResult['thoughtSignature'] ?? '',
          'needsFollowUp': true,
        };
      }
      
      // If successful, add confirmation to history
      if (parseResult['success'] == true) {
        final response = parseResult['message'] ?? 'Done!';
        _conversationHistory.add({
          'role': 'assistant',
          'content': response,
        });
        
        return {
          'success': true,
          'message': response,
          'thoughtSignature': parseResult['thoughtSignature'] ?? '',
          'transaction': parseResult['transaction'],
        };
      }
      
      // If it's a general conversation, use context-aware response
      return await _handleContextualConversation(userMessage);
      
    } catch (e) {
      safePrint('[SimpleChatService] Error: $e');
      return {
        'success': false,
        'message': 'Sorry, I encountered an error. Please try again.',
        'thoughtSignature': 'error',
      };
    }
  }

  /// Determine if we need to ask a follow-up question
  String? _needsFollowUpQuestion(Map<String, dynamic> parseResult, String userMessage) {
    // If parsing failed, don't ask follow-up
    if (parseResult['success'] == false) {
      return null;
    }

    final message = userMessage.toLowerCase();
    
    // Check for incomplete expense information
    if (message.contains('spent') || message.contains('paid') || message.contains('bought')) {
      // Check if category is missing
      if (!message.contains('food') && 
          !message.contains('groceries') && 
          !message.contains('transport') &&
          !message.contains('entertainment') &&
          !message.contains('shopping') &&
          !message.contains('bills')) {
        return '${parseResult['message']}\n\nWhat category should I assign this to? (food, transport, entertainment, shopping, bills, or other)';
      }
    }
    
    // Check for loan without due date
    if (message.contains('given') || message.contains('lent') || message.contains('borrowed')) {
      if (!message.contains('monday') && 
          !message.contains('tuesday') &&
          !message.contains('tomorrow') &&
          !message.contains('next week')) {
        return '${parseResult['message']}\n\nWhen do you expect to get this back? (e.g., "next Monday", "in 2 weeks")';
      }
    }

    return null;
  }

  /// Handle general conversation with context awareness
  Future<Map<String, dynamic>> _handleContextualConversation(String userMessage) async {
    try {
      // Get recent financial summary for context
      await financeService.initialize();
      final summary = financeService.getFinancialSummary();
      
      // Build context-aware prompt
      final contextPrompt = '''User: $userMessage

<financial_context>
Balance: ₹${summary['balance']}
Total Expenses: ₹${summary['totalExpenses']}
Total Income: ₹${summary['totalIncome']}
Money owed to you: ₹${summary['totalReceivables']}
Money you owe: ₹${summary['totalPayables']}
Net Worth: ₹${summary['netWorth']}
</financial_context>

<conversation_history>
${_conversationHistory.map((m) => '${m['role']}: ${m['content']}').join('\n')}
</conversation_history>

Respond as Finance OS, a helpful financial AI assistant. Be conversational, ask clarifying questions when needed, and provide actionable insights.''';

      final response = await novaService.sendMessage(
        prompt: contextPrompt,
        systemInstruction: '''You are Finance OS, an intelligent financial AI assistant.

Key behaviors:
1. Ask clarifying questions when information is incomplete
2. Provide specific, actionable advice
3. Reference their financial data when relevant
4. Be conversational and friendly
5. Suggest next steps or actions

Examples:
- If they mention spending, ask about category if not specified
- If they ask about savings, suggest specific strategies based on their expenses
- If they mention a person, ask if it's a loan or expense
- Always be proactive and helpful''',
        isParsing: false, // Conversational response
      );

      final responseText = response['text'] ?? 'How can I help you with your finances?';
      
      _conversationHistory.add({
        'role': 'assistant',
        'content': responseText,
      });

      return {
        'success': true,
        'message': responseText,
        'thoughtSignature': response['thoughtSignature'] ?? '',
      };
    } catch (e) {
      return {
        'success': true,
        'message': 'Hello! I\'m Finance OS. I can help you track expenses, manage loans, and provide financial insights. What would you like to do?',
        'thoughtSignature': '',
      };
    }
  }

  /// Process image file (receipt, invoice, etc.)
  Future<Map<String, dynamic>> processImageFile(File imageFile) async {
    safePrint('[SimpleChatService] Processing image: ${imageFile.path}');
    
    try {
      // Read image as base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Analyze with Nova Vision
      final result = await novaService.analyzeReceiptImage(
        base64Image: base64Image,
        region: 'India', // Default region
      );
      
      safePrint('[SimpleChatService] Vision result: $result');
      
      // Extract data
      final vendor = result['vendor'] ?? 'Unknown';
      final total = result['total']?.toDouble() ?? 0.0;
      final category = result['category'] ?? 'other';
      final description = result['notes'] ?? 'Receipt from $vendor';
      
      if (total > 0) {
        // Create expense entry automatically
        await financeService.initialize();
        final entry = ExpenseEntry.create(
          amount: total,
          vendor: vendor,
          description: description,
          category: category,
          receiptImagePath: imageFile.path,
        );
        await financeService.addExpense(entry);
        
        final message = '''✓ Receipt analyzed and expense created!

📍 Vendor: $vendor
💰 Amount: ₹${total.toStringAsFixed(2)}
📂 Category: $category
📝 Description: $description

Your expense has been automatically recorded.''';
        
        return {
          'success': true,
          'message': message,
          'thoughtSignature': result['thoughtSignature'] ?? '',
          'transaction': entry,
        };
      } else {
        return {
          'success': false,
          'message': 'I couldn\'t extract the amount from this receipt. Could you tell me the total amount?',
          'thoughtSignature': result['thoughtSignature'] ?? '',
        };
      }
    } catch (e) {
      safePrint('[SimpleChatService] Image processing error: $e');
      return {
        'success': false,
        'message': 'I had trouble analyzing that image. Could you describe what you spent?',
        'thoughtSignature': '',
      };
    }
  }
}
