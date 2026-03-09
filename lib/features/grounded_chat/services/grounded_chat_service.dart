import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:nova_finance_os/features/grounded_chat/services/grounded_search_service.dart';
import 'package:nova_finance_os/features/chat/services/simple_chat_service.dart';

final groundedChatServiceProvider = Provider((ref) => GroundedChatService(
      novaService: ref.read(novaServiceV3Provider),
      groundedSearch: ref.read(groundedSearchServiceProvider),
      chatService: ref.read(simpleChatServiceProvider),
    ));

/// Grounded Chat Service - Enhanced chat with factual grounding
/// 
/// Automatically detects when to use:
/// - Regular AI responses for conversational queries
/// - Web grounding for real-time factual questions
/// - Document grounding for domain-specific knowledge
class GroundedChatService {
  final NovaServiceV3 novaService;
  final GroundedSearchService groundedSearch;
  final SimpleChatService chatService;

  GroundedChatService({
    required this.novaService,
    required this.groundedSearch,
    required this.chatService,
  });

  /// Process message with intelligent grounding selection
  Future<Map<String, dynamic>> processMessage(String message) async {
    try {
      safePrint('[Grounded Chat] Processing: $message');

      // Determine if grounding is needed
      final needsGrounding = groundedSearch.shouldUseGrounding(message);

      if (needsGrounding) {
        safePrint('[Grounded Chat] Using grounded search');
        return await _processWithGrounding(message);
      } else {
        safePrint('[Grounded Chat] Using regular AI');
        return await chatService.processMessage(message);
      }
    } catch (e) {
      safePrint('[Grounded Chat] Error: $e');
      return {
        'success': false,
        'message': 'Sorry, I encountered an error processing your message.',
        'error': e.toString(),
      };
    }
  }

  /// Process with grounding (web or document search)
  Future<Map<String, dynamic>> _processWithGrounding(String message) async {
    try {
      // Check if it's a tax/accounting question (use document grounding)
      final isDomainSpecific = _isDomainSpecificQuery(message);

      Map<String, dynamic> result;

      if (isDomainSpecific) {
        // Use document grounding for tax/accounting questions
        result = await groundedSearch.searchWithDocumentGrounding(
          query: message,
          context: 'You are Finance OS, an AI financial assistant.',
        );
      } else {
        // Use web grounding for general factual questions
        result = await groundedSearch.searchWithWebGrounding(
          query: message,
          context: 'You are Finance OS, an AI financial assistant.',
        );
      }

      if (result['success'] == true) {
        // Format response with citations
        final answer = result['answer'] as String;
        final citations = result['citations'] as List<Map<String, dynamic>>?;
        final hasGrounding = result['hasGrounding'] as bool? ?? false;

        String formattedMessage = answer;

        // Add citation footer if available
        if (hasGrounding && citations != null && citations.isNotEmpty) {
          formattedMessage += '\n\n📚 Sources:\n';
          for (int i = 0; i < citations.length && i < 3; i++) {
            final citation = citations[i];
            final title = citation['title'] as String? ?? 'Source ${i + 1}';
            final url = citation['url'] as String? ?? '';
            formattedMessage += '${i + 1}. $title\n   $url\n';
          }
        }

        return {
          'success': true,
          'message': formattedMessage,
          'isGrounded': hasGrounding,
          'citations': citations,
          'searchType': result['searchType'],
        };
      } else {
        // Fallback to regular AI if grounding fails
        return await chatService.processMessage(message);
      }
    } catch (e) {
      safePrint('[Grounded Chat] Grounding error: $e');
      // Fallback to regular AI
      return await chatService.processMessage(message);
    }
  }

  /// Check if query is domain-specific (tax/accounting)
  bool _isDomainSpecificQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    final domainKeywords = [
      'tax',
      'deduction',
      'deductible',
      'irs',
      'accounting',
      'expense',
      'income',
      'revenue',
      'depreciation',
      'amortization',
      'gaap',
      'ifrs',
      'audit',
      'financial statement',
      'balance sheet',
      'cash flow',
    ];

    return domainKeywords.any((keyword) => lowerQuery.contains(keyword));
  }

  /// Stream responses with live grounding (for voice/streaming)
  Stream<Map<String, dynamic>> streamGroundedResponse(String message) async* {
    yield {'status': 'analyzing', 'message': 'Analyzing your question...'};

    final needsGrounding = groundedSearch.shouldUseGrounding(message);

    if (needsGrounding) {
      yield {'status': 'searching', 'message': 'Searching for factual information...'};

      final result = await _processWithGrounding(message);

      yield {
        'status': 'complete',
        'message': result['message'],
        'isGrounded': result['isGrounded'] ?? false,
        'citations': result['citations'],
      };
    } else {
      yield {'status': 'thinking', 'message': 'Thinking...'};

      final result = await chatService.processMessage(message);

      yield {
        'status': 'complete',
        'message': result['message'],
        'isGrounded': false,
      };
    }
  }
}
