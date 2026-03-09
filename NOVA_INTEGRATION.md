# Amazon Nova Integration Guide

## Finance OS - Amazon Nova AI Hackathon Project

---

## Overview

This document provides comprehensive details on how Finance OS integrates with Amazon Nova AI services through AWS Bedrock. It covers all models used, API endpoints, request/response formats, and best practices.

---

## Amazon Nova Models Used

### 1. Amazon Nova 2 Lite
**Model ID:** `amazon.nova-lite-v1:0`  
**Purpose:** Fast, cost-effective reasoning engine  
**Pricing:** ~$0.06 per 1M input tokens, ~$0.24 per 1M output tokens

**Capabilities:**
- Text generation
- Financial reasoning
- Conversational AI
- Decision synthesis
- Insight generation

**Best For:**
- Chat responses
- Quick financial insights
- Budget analysis
- Cashflow predictions
- Category classification

---

### 2. Amazon Nova Pro
**Model ID:** `amazon.nova-pro-v1:0`  
**Purpose:** Advanced multimodal AI  
**Pricing:** ~$0.80 per 1M input tokens, ~$3.20 per 1M output tokens

**Capabilities:**
- Multimodal understanding (text + images)
- Complex reasoning
- Agent task planning
- Structured output generation

**Best For:**
- Receipt OCR and analysis
- Complex financial scenarios
- Agent task execution
- Multi-step workflows

---

### 3. Amazon Titan Embeddings v2
**Model ID:** `amazon.titan-embed-text-v2:0`  
**Purpose:** Semantic search and retrieval  
**Pricing:** ~$0.02 per 1M input tokens

**Capabilities:**
- 1024-dimensional embeddings
- Normalized vectors
- Semantic similarity
- Knowledge retrieval

**Best For:**
- Financial knowledge search
- Tax policy retrieval
- Receipt similarity
- Memory retrieval
- Document search

---

## API Integration

### Base Configuration

```dart
class NovaConfig {
  static const String baseUrl = 'https://bedrock-runtime';
  static const String region = 'us-east-1'; // Configurable
  static const String apiVersion = 'v1';
  
  // Model IDs
  static const String novaLite = 'amazon.nova-lite-v1:0';
  static const String novaPro = 'amazon.nova-pro-v1:0';
  static const String titanEmbed = 'amazon.titan-embed-text-v2:0';
}
```

---

## Service Implementations

### 1. NovaLiteService

#### Send Message

```dart
Future<Map<String, dynamic>> sendMessage({
  required String prompt,
  Map<String, dynamic>? context,
  bool deepReasoning = false,
}) async {
  final endpoint = '${NovaConfig.baseUrl}.${NovaConfig.region}.amazonaws.com'
                  '/model/${NovaConfig.novaLite}/invoke';
  
  final requestBody = {
    'messages': [
      {
        'role': 'user',
        'content': [
          {'text': prompt}
        ]
      }
    ],
    'inferenceConfig': {
      'temperature': deepReasoning ? 0.3 : 0.7,
      'maxTokens': 2048,
      'topP': 0.9,
    },
    if (context != null) 'system': [
      {
        'text': 'Financial context: ${jsonEncode(context)}'
      }
    ],
  };

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'X-Amz-Bedrock-Model-Id': NovaConfig.novaLite,
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'success': true,
      'message': data['output']['message']['content'][0]['text'],
      'usage': data['usage'],
      'stopReason': data['stopReason'],
    };
  } else {
    throw Exception('Nova Lite API error: ${response.statusCode}');
  }
}
```

#### Generate Financial Insight

```dart
Future<Map<String, dynamic>> generateFinancialInsight({
  required Map<String, dynamic> financialData,
  required String insightType,
}) async {
  final prompt = '''
Analyze the following financial data and provide ${insightType} insights:

Financial Data:
${jsonEncode(financialData)}

Provide:
1. Key findings
2. Trends and patterns
3. Actionable recommendations
4. Risk factors
5. Opportunities

Format as JSON with clear structure.
''';

  return await sendMessage(
    prompt: prompt,
    context: financialData,
    deepReasoning: true,
  );
}
```

#### Forecast Cashflow

```dart
Future<Map<String, dynamic>> forecastCashflow({
  required List<Map<String, dynamic>> transactions,
  required int daysAhead,
}) async {
  final prompt = '''
Based on these historical transactions, forecast cashflow for the next $daysAhead days:

Transactions:
${jsonEncode(transactions)}

Provide:
1. Daily balance predictions
2. Expected income
3. Expected expenses
4. Potential shortfalls
5. Confidence intervals

Return as JSON with daily breakdown.
''';

  return await sendMessage(
    prompt: prompt,
    deepReasoning: true,
  );
}
```

---

### 2. NovaEmbeddingService

#### Generate Embedding

```dart
Future<List<double>> generateEmbedding(String text) async {
  final endpoint = '${NovaConfig.baseUrl}.${NovaConfig.region}.amazonaws.com'
                  '/model/${NovaConfig.titanEmbed}/invoke';
  
  final requestBody = {
    'inputText': text,
    'dimensions': 1024,
    'normalize': true,
  };

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<double>.from(data['embedding']);
  } else {
    throw Exception('Embedding generation error: ${response.statusCode}');
  }
}
```

#### Search Knowledge Base

```dart
Future<List<Map<String, dynamic>>> searchFinancialKnowledge({
  required String query,
  required List<Map<String, dynamic>> knowledgeBase,
  int topK = 5,
}) async {
  // Generate query embedding
  final queryEmbedding = await generateEmbedding(query);
  
  // Calculate similarity scores
  final results = <Map<String, dynamic>>[];
  for (final doc in knowledgeBase) {
    final docEmbedding = doc['embedding'] as List<double>;
    final similarity = _cosineSimilarity(queryEmbedding, docEmbedding);
    
    results.add({
      ...doc,
      'similarity': similarity,
    });
  }
  
  // Sort by similarity and return top K
  results.sort((a, b) => 
    (b['similarity'] as double).compareTo(a['similarity'] as double)
  );
  
  return results.take(topK).toList();
}
```

---

### 3. NovaAgentExecutor

#### Execute Task

```dart
Future<Map<String, dynamic>> executeTask({
  required String taskDescription,
  required String taskType,
  Map<String, dynamic>? parameters,
}) async {
  final endpoint = '${NovaConfig.baseUrl}.${NovaConfig.region}.amazonaws.com'
                  '/model/${NovaConfig.novaPro}/invoke';
  
  final requestBody = {
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'text': '''
Execute the following task autonomously:

Task: $taskDescription
Type: $taskType
Parameters: ${parameters != null ? jsonEncode(parameters) : 'None'}

Provide:
1. Step-by-step execution plan
2. Expected outcomes
3. Potential risks
4. Validation checks
5. Rollback procedures

Execute and report results.
'''
          }
        ]
      }
    ],
    'inferenceConfig': {
      'temperature': 0.1, // Low temperature for precise execution
      'maxTokens': 4096,
    },
  };

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'success': true,
      'result': data['output']['message']['content'][0]['text'],
      'steps': _parseExecutionSteps(data['output']['message']['content'][0]['text']),
    };
  } else {
    throw Exception('Nova Act error: ${response.statusCode}');
  }
}
```

#### Pay Bill

```dart
Future<Map<String, dynamic>> payBill({
  required String billProvider,
  required double amount,
  required String accountNumber,
}) async {
  return await executeTask(
    taskDescription: 'Pay $billProvider bill of \$$amount',
    taskType: 'bill_payment',
    parameters: {
      'provider': billProvider,
      'amount': amount,
      'account': accountNumber,
      'safetyChecks': [
        'Verify account balance',
        'Confirm bill amount',
        'Check payment history',
      ],
    },
  );
}
```

---

### 4. NovaReceiptAnalyzer

#### Analyze Receipt

```dart
Future<Map<String, dynamic>> analyzeReceipt({
  required String base64Image,
  required String region,
}) async {
  final endpoint = '${NovaConfig.baseUrl}.${NovaConfig.region}.amazonaws.com'
                  '/model/${NovaConfig.novaPro}/invoke';
  
  final requestBody = {
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'image': {
              'format': 'jpeg',
              'source': {
                'bytes': base64Image,
              }
            }
          },
          {
            'text': '''
Analyze this receipt and extract all financial information.

Region: $region

Extract:
1. Vendor name
2. Date (YYYY-MM-DD format)
3. Total amount
4. Currency
5. Line items with individual prices
6. Tax amount
7. Payment method
8. Category (dining, groceries, transportation, etc.)
9. Tax deductibility percentage (0-100)
10. Deduction category (meals, travel, office supplies, etc.)

Return as JSON:
{
  "vendor": "string",
  "date": "YYYY-MM-DD",
  "total": number,
  "currency": "string",
  "items": [{"name": "string", "price": number}],
  "tax": number,
  "paymentMethod": "string",
  "category": "string",
  "taxDeductible": number,
  "deductionCategory": "string",
  "confidence": number
}
'''
          }
        ]
      }
    ],
    'inferenceConfig': {
      'temperature': 0.1,
      'maxTokens': 2048,
    },
  };

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final resultText = data['output']['message']['content'][0]['text'];
    
    // Parse JSON from response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(resultText);
    if (jsonMatch != null) {
      final receiptData = jsonDecode(jsonMatch.group(0)!);
      return {
        'success': true,
        'receipt': receiptData,
      };
    }
  }
  
  throw Exception('Receipt analysis failed');
}
```

---

## Error Handling

### Retry Strategy

```dart
Future<T> retryWithBackoff<T>({
  required Future<T> Function() operation,
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int retries = 0;
  Duration delay = initialDelay;
  
  while (true) {
    try {
      return await operation();
    } catch (e) {
      if (retries >= maxRetries) {
        rethrow;
      }
      
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
      retries++;
    }
  }
}
```

### Fallback Handling

```dart
Future<Map<String, dynamic>> sendMessageWithFallback({
  required String prompt,
  Map<String, dynamic>? context,
}) async {
  try {
    // Try Nova Lite first
    return await novaLiteService.sendMessage(
      prompt: prompt,
      context: context,
    );
  } catch (e) {
    // Fallback to local processing
    return {
      'success': false,
      'error': 'Service unavailable',
      'fallback': true,
      'message': 'Using offline mode',
    };
  }
}
```

---

## Best Practices

### 1. Model Selection
- Use Nova Lite for fast, cheap tasks
- Use Nova Pro for complex multimodal tasks
- Use Titan Embeddings for semantic search

### 2. Cost Optimization
- Cache embeddings for reuse
- Batch similar requests
- Use appropriate temperature settings
- Limit max tokens based on need

### 3. Performance
- Implement request timeouts
- Use connection pooling
- Cache frequent queries
- Optimize prompt length

### 4. Security
- Never log API keys
- Use IAM roles when possible
- Encrypt sensitive data
- Validate all inputs

### 5. Monitoring
- Track API latency
- Monitor error rates
- Log usage metrics
- Set up cost alerts

---

## Testing

### Unit Tests

```dart
void main() {
  group('NovaLiteService', () {
    test('should generate financial insight', () async {
      final service = NovaLiteService(
        apiKey: 'test-key',
        region: 'us-east-1',
      );
      
      final result = await service.generateFinancialInsight(
        financialData: {'balance': 1000, 'expenses': 500},
        insightType: 'spending',
      );
      
      expect(result['success'], true);
      expect(result['message'], isNotEmpty);
    });
  });
}
```

---

## Cost Estimation

### Monthly Cost Breakdown (100 users)

| Service | Usage | Cost |
|---------|-------|------|
| Nova Lite | 10K requests | $3.00 |
| Nova Pro | 5K receipts | $16.00 |
| Titan Embeddings | 20K searches | $0.40 |
| **Total** | | **$19.40** |

**Per User:** ~$0.19/month

---

## Conclusion

Finance OS leverages the full power of Amazon Nova AI services to provide intelligent, autonomous financial management. The integration is designed for scalability, cost-efficiency, and reliability.

---

**Built with ❤️ for the Amazon Nova AI Hackathon**
