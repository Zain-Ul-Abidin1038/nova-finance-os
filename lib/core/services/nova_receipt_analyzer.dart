import 'dart:convert';
import 'aws_bedrock_client.dart';

/// Nova Receipt Analyzer
/// Uses Amazon Nova Pro (multimodal) for:
/// - Receipt OCR
/// - Expense classification
/// - Tax deduction detection
/// - Financial category mapping
/// 
/// Real AWS Bedrock Integration with Vision Capabilities
class NovaReceiptAnalyzer {
  final AWSBedrockClient bedrockClient;
  static const String modelId = 'us.amazon.nova-pro-v1:0';
  
  NovaReceiptAnalyzer({
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

  /// Analyze receipt image using Nova Pro multimodal
  Future<Map<String, dynamic>> analyzeReceipt({
    required String base64Image,
    required String userRegion,
  }) async {
    try {
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
Analyze this receipt and extract all information in JSON format:

{
  "vendor": "string (merchant name)",
  "date": "YYYY-MM-DD",
  "total": number,
  "currency": "string (USD, EUR, etc.)",
  "items": [{"name": "string", "price": number}],
  "tax": number,
  "paymentMethod": "string (cash, card, etc.)",
  "category": "string (dining, groceries, transportation, utilities, entertainment, healthcare, shopping, travel, education, other)",
  "taxDeductible": number (0-100 percentage),
  "deductionCategory": "string (meals, travel, office supplies, etc.)",
  "confidence": number (0-100)
}

Region: $userRegion

Be precise and extract all visible information. If unsure, set confidence lower.
'''
              }
            ]
          }
        ],
        'inferenceConfig': {
          'temperature': 0.1,
          'maxTokens': 2048,
          'topP': 0.9,
        },
      };

      final response = await bedrockClient.invokeModel(
        modelId: modelId,
        body: requestBody,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final resultText = data['output']['message']['content'][0]['text'];
        
        // Parse JSON from response
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(resultText);
        if (jsonMatch != null) {
          final receiptData = jsonDecode(jsonMatch.group(0)!);
          return {
            'success': true,
            'receipt': receiptData,
            'rawResponse': resultText,
          };
        } else {
          return {
            'success': false,
            'error': 'Could not parse receipt data from response',
            'rawResponse': resultText,
          };
        }
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
        'error': 'Nova receipt analyzer error: $e',
      };
    }
  }

  /// Classify expense category using Nova Lite
  Future<String> classifyExpense({
    required String description,
    required double amount,
  }) async {
    try {
      final requestBody = {
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'text': '''
Classify this expense into ONE category:
Description: $description
Amount: \$$amount

Categories: dining, groceries, transportation, utilities, entertainment, healthcare, shopping, travel, education, other

Return ONLY the category name, nothing else.
'''
              }
            ]
          }
        ],
        'inferenceConfig': {
          'temperature': 0.1,
          'maxTokens': 50,
        },
      };

      final response = await bedrockClient.invokeModel(
        modelId: 'us.amazon.nova-lite-v1:0',
        body: requestBody,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final category = data['output']['message']['content'][0]['text'].trim().toLowerCase();
        return category;
      } else {
        return 'other';
      }
    } catch (e) {
      return 'other';
    }
  }

  /// Detect tax deductions using Nova Lite
  Future<Map<String, dynamic>> detectTaxDeductions({
    required String category,
    required String description,
    required double amount,
  }) async {
    try {
      final requestBody = {
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'text': '''
Determine tax deductibility for this expense:
Category: $category
Description: $description
Amount: \$$amount

Return JSON:
{
  "deductible": true/false,
  "percentage": 0-100,
  "deductionType": "string (meals, travel, office, etc.)",
  "notes": "string (brief explanation)"
}
'''
              }
            ]
          }
        ],
        'inferenceConfig': {
          'temperature': 0.1,
          'maxTokens': 256,
        },
      };

      final response = await bedrockClient.invokeModel(
        modelId: 'us.amazon.nova-lite-v1:0',
        body: requestBody,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final resultText = data['output']['message']['content'][0]['text'];
        
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(resultText);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
      }
      
      return {
        'deductible': false,
        'percentage': 0,
        'deductionType': 'none',
        'notes': 'Could not determine deductibility',
      };
    } catch (e) {
      return {
        'deductible': false,
        'percentage': 0,
        'deductionType': 'none',
        'notes': 'Error: $e',
      };
    }
  }

  /// Map to financial category
  String mapFinancialCategory({
    required String expenseCategory,
    required String description,
  }) {
    final categoryMap = {
      'dining': 'Food & Dining',
      'groceries': 'Groceries',
      'transportation': 'Transportation',
      'utilities': 'Utilities',
      'entertainment': 'Entertainment',
      'healthcare': 'Healthcare',
      'shopping': 'Shopping',
      'travel': 'Travel',
      'education': 'Education',
      'other': 'Other',
    };
    
    return categoryMap[expenseCategory.toLowerCase()] ?? 'Other';
  }
}
