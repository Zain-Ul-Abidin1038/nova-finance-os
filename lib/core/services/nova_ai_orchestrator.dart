import 'nova_lite_service.dart';
import 'nova_embedding_service.dart';
import 'nova_receipt_analyzer.dart';

/// Nova AI Orchestrator
/// Master orchestrator for all Amazon Nova AI services
/// Real AWS Bedrock Integration
class NovaAIOrchestrator {
  final NovaLiteService liteService;
  final NovaEmbeddingService embeddingService;
  final NovaReceiptAnalyzer receiptAnalyzer;
  
  NovaAIOrchestrator({
    required String accessKeyId,
    required String secretAccessKey,
    required String region,
    String? sessionToken,
  })  : liteService = NovaLiteService(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          region: region,
          sessionToken: sessionToken,
        ),
        embeddingService = NovaEmbeddingService(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          region: region,
          sessionToken: sessionToken,
        ),
        receiptAnalyzer = NovaReceiptAnalyzer(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          region: region,
          sessionToken: sessionToken,
        );

  /// Process financial message with context
  Future<Map<String, dynamic>> processFinancialMessage({
    required String message,
    required Map<String, dynamic> context,
  }) async {
    return await liteService.sendMessage(
      prompt: message,
      context: context,
    );
  }

  /// Analyze receipt with full pipeline
  Future<Map<String, dynamic>> analyzeReceipt({
    required String base64Image,
    required String region,
  }) async {
    return await receiptAnalyzer.analyzeReceipt(
      base64Image: base64Image,
      userRegion: region,
    );
  }

  /// Search knowledge base
  Future<List<Map<String, dynamic>>> searchKnowledge({
    required String query,
    required List<Map<String, dynamic>> knowledgeBase,
  }) async {
    return await embeddingService.searchFinancialKnowledge(
      query: query,
      knowledgeBase: knowledgeBase,
    );
  }

  /// Generate financial insights
  Future<Map<String, dynamic>> generateInsights({
    required Map<String, dynamic> financialData,
    required String insightType,
  }) async {
    return await liteService.generateFinancialInsight(
      financialData: financialData,
      insightType: insightType,
    );
  }

  /// Forecast cashflow
  Future<Map<String, dynamic>> forecastCashflow({
    required List<Map<String, dynamic>> transactions,
    required int daysAhead,
  }) async {
    return await liteService.forecastCashflow(
      transactions: transactions,
      daysAhead: daysAhead,
    );
  }

  /// Analyze budget
  Future<Map<String, dynamic>> analyzeBudget({
    required Map<String, dynamic> budgetData,
    required Map<String, dynamic> spendingData,
  }) async {
    return await liteService.analyzeBudget(
      budgetData: budgetData,
      spendingData: spendingData,
    );
  }

  /// Process chat
  Future<Map<String, dynamic>> processChat({
    required String message,
    required Map<String, dynamic> financialContext,
  }) async {
    return await liteService.processChat(
      message: message,
      financialContext: financialContext,
    );
  }
}
