import 'dart:convert';
import 'aws_bedrock_client.dart';

/// Nova 2 Lite Reasoning Engine
/// Handles financial insights, decision synthesis, budget analysis,
/// cashflow forecasting, and chat assistance using Amazon Nova 2 Lite
/// 
/// Real AWS Bedrock Integration with Signature V4 Authentication
class NovaLiteService {
  final AWSBedrockClient bedrockClient;
  static const String modelId = 'us.amazon.nova-lite-v1:0';
  
  NovaLiteService({
    required String accessKeyId,
    required String secretAccessKey,
    required String region,
    String? sessionToken,
  }) : bedrockClient = AWSBedrockClient(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          region: region,
          sessionToken: sessionToken,
        );

  /// Send a message to Nova Lite for financial reasoning
  Future<Map<String, dynamic>> sendMessage({
    required String prompt,
    Map<String, dynamic>? context,
    bool deepReasoning = false,
    double? temperature,
    int? maxTokens,
  }) async {
    try {
      final messages = [
        {
          'role': 'user',
          'content': [
            {'text': prompt}
          ]
        }
      ];

      final requestBody = {
        'messages': messages,
        'inferenceConfig': {
          'temperature': temperature ?? (deepReasoning ? 0.3 : 0.7),
          'maxTokens': maxTokens ?? 2048,
          'topP': 0.9,
        },
      };

      // Add system context if provided
      if (context != null) {
        requestBody['system'] = [
          {
            'text': 'Financial context: ${jsonEncode(context)}'
          }
        ];
      }

      final response = await bedrockClient.invokeModel(
        modelId: modelId,
        body: requestBody,
      );

      if (response['success'] == true) {
        final data = response['data'];
        return {
          'success': true,
          'message': data['output']['message']['content'][0]['text'],
          'usage': data['usage'],
          'stopReason': data['stopReason'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'],
          'statusCode': response['statusCode'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Nova Lite service error: $e',
      };
    }
  }

  /// Generate financial insights using Nova Lite
  Future<Map<String, dynamic>> generateFinancialInsight({
    required Map<String, dynamic> financialData,
    required String insightType,
  }) async {
    final prompt = '''
Analyze the following financial data and provide $insightType insights:

${jsonEncode(financialData)}

Provide actionable recommendations and predictions in a clear, structured format.
''';

    return await sendMessage(
      prompt: prompt,
      context: financialData,
      deepReasoning: true,
    );
  }

  /// Forecast cashflow using Nova Lite reasoning
  Future<Map<String, dynamic>> forecastCashflow({
    required List<Map<String, dynamic>> transactions,
    required int daysAhead,
  }) async {
    final prompt = '''
Based on these transactions, forecast cashflow for the next $daysAhead days:

${jsonEncode(transactions)}

Provide:
1. Daily balance predictions
2. Potential shortfalls with dates
3. Spending pattern analysis
4. Recommendations to avoid negative balance
''';

    return await sendMessage(
      prompt: prompt,
      deepReasoning: true,
    );
  }

  /// Analyze budget performance
  Future<Map<String, dynamic>> analyzeBudget({
    required Map<String, dynamic> budgetData,
    required Map<String, dynamic> spendingData,
  }) async {
    final prompt = '''
Compare budget vs actual spending:

Budget: ${jsonEncode(budgetData)}
Spending: ${jsonEncode(spendingData)}

Provide:
1. Overspending categories with amounts
2. Underspending categories
3. Budget optimization suggestions
4. Spending trends
''';

    return await sendMessage(
      prompt: prompt,
      deepReasoning: true,
    );
  }

  /// Process chat message with financial context
  Future<Map<String, dynamic>> processChat({
    required String message,
    required Map<String, dynamic> financialContext,
    List<Map<String, String>>? conversationHistory,
  }) async {
    return await sendMessage(
      prompt: message,
      context: financialContext,
      deepReasoning: false,
    );
  }
}
