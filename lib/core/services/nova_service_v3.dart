// Legacy adapter for NovaServiceV3
// Redirects to new NovaAIOrchestrator

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'nova_ai_orchestrator.dart';

/// Legacy NovaServiceV3 - now uses NovaAIOrchestrator
class NovaServiceV3 {
  final NovaAIOrchestrator orchestrator;
  
  NovaServiceV3({
    required String accessKeyId,
    required String secretAccessKey,
    required String region,
  }) : orchestrator = NovaAIOrchestrator(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          region: region,
        );

  // Legacy method - redirects to orchestrator
  Future<Map<String, dynamic>> sendMessage({
    required String prompt,
    Map<String, dynamic>? context,
    String? systemInstruction,
    bool? deepReasoning, // Ignored - for compatibility
    bool? thinkingLevel, // Ignored - for compatibility
  }) async {
    // Add system instruction to context if provided
    final fullContext = context ?? {};
    if (systemInstruction != null) {
      fullContext['systemInstruction'] = systemInstruction;
    }
    
    final result = await orchestrator.processFinancialMessage(
      message: prompt,
      context: fullContext,
    );
    
    // Normalize response keys for callers that expect 'text' instead of 'message'
    result['text'] = result['message'] ?? '';
    return result;
  }

  // Structured message with schema
  Future<Map<String, dynamic>> sendStructuredMessage({
    required String prompt,
    Map<String, dynamic>? context,
    String? systemInstruction,
    Map<String, dynamic>? responseSchema,
  }) async {
    final fullContext = context ?? {};
    if (systemInstruction != null) {
      fullContext['systemInstruction'] = systemInstruction;
    }
    if (responseSchema != null) {
      fullContext['responseSchema'] = responseSchema;
    }
    
    final result = await orchestrator.processFinancialMessage(
      message: prompt,
      context: fullContext,
    );
    
    // Normalize: callers expect 'text' and 'data' (parsed JSON from the response)
    final messageText = result['message'] ?? '';
    result['text'] = messageText;
    
    // Try to parse the AI response text as JSON for structured data
    if (result['success'] == true && messageText is String && messageText.isNotEmpty) {
      try {
        // Extract JSON from the response text
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(messageText);
        if (jsonMatch != null) {
          final parsed = jsonDecode(jsonMatch.group(0)!);
          if (parsed is Map<String, dynamic>) {
            result['data'] = parsed;
          }
        }
      } catch (_) {
        // If JSON parsing fails, set data to null — caller handles it
        result['data'] = null;
      }
    }
    
    return result;
  }

  // Legacy method for receipt analysis
  Future<Map<String, dynamic>> analyzeReceipt({
    required String base64Image,
    required String region,
  }) async {
    return await orchestrator.analyzeReceipt(
      base64Image: base64Image,
      region: region,
    );
  }

  // Receipt image analysis (alias)
  Future<Map<String, dynamic>> analyzeReceiptImage({
    required String base64Image,
    required String region,
  }) async {
    return await analyzeReceipt(
      base64Image: base64Image,
      region: region,
    );
  }

  // Legacy method for insights
  Future<Map<String, dynamic>> generateInsights({
    required Map<String, dynamic> financialData,
    required String insightType,
  }) async {
    return await orchestrator.generateInsights(
      financialData: financialData,
      insightType: insightType,
    );
  }

  // Legacy method for cashflow
  Future<Map<String, dynamic>> forecastCashflow({
    required List<Map<String, dynamic>> transactions,
    required int daysAhead,
  }) async {
    return await orchestrator.forecastCashflow(
      transactions: transactions,
      daysAhead: daysAhead,
    );
  }
}

/// Nova Schemas for structured responses
class NovaSchemas {
  static const Map<String, dynamic> financeCommand = {
    'type': 'object',
    'properties': {
      'action': {'type': 'string'},
      'amount': {'type': 'number'},
      'category': {'type': 'string'},
      'description': {'type': 'string'},
    },
  };
}

/// Provider for NovaServiceV3 (legacy compatibility)
final novaServiceV3Provider = Provider<NovaServiceV3>((ref) {
  final accessKeyId = dotenv.env['AWS_ACCESS_KEY_ID'] ?? '';
  final secretAccessKey = dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '';
  final region = dotenv.env['AWS_REGION'] ?? 'us-east-1';
  
  if (accessKeyId.isEmpty || secretAccessKey.isEmpty || 
      accessKeyId == 'your_aws_access_key_id_here' || 
      secretAccessKey == 'your_aws_secret_access_key_here') {
    print('[NovaServiceV3] ⚠️ AWS credentials not configured in .env file');
    print('[NovaServiceV3] Chat will use local fallback responses');
  }
  
  return NovaServiceV3(
    accessKeyId: accessKeyId,
    secretAccessKey: secretAccessKey,
    region: region,
  );
});
