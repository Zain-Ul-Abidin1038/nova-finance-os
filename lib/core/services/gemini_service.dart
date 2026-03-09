import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final novaServiceProvider = Provider((ref) => NovaService());

/// Nova 3 REST Service with Thinking Config
/// Uses GCP API key to access Nova 3 with thinking capabilities
class NovaService {
  // Nova API Key from GCP
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not found in .env file. '
        'Please add your GCP API key to .env file.'
      );
    }
    return key;
  }
  
  // Using Nova 3 Flash Preview with GCP API key
  // Model: nova-3-flash-preview (faster, optimized for speed)
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/nova-3-flash-preview:generateContent';

  /// Send message to Nova with high-level thinking
  /// Returns a map with 'text' and 'thoughtSignature'
  Future<Map<String, String>> sendMessage({
    required String prompt,
    String? systemInstruction,
    List<String>? memoryContext,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      // Build system instruction with memory context
      String fullSystemInstruction = systemInstruction ?? 
          'You are a Finance OS AI assistant specialized in tax deductions and financial analysis.';
      
      if (memoryContext != null && memoryContext.isNotEmpty) {
        fullSystemInstruction += '\n\n<financial_memory>\n';
        fullSystemInstruction += 'You remember the following about this user\'s financial history:\n';
        for (final memory in memoryContext) {
          fullSystemInstruction += '- $memory\n';
        }
        fullSystemInstruction += '</financial_memory>';
      }

      // Construct request body for Nova with thinking mode
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "systemInstruction": {
          "parts": [
            {"text": fullSystemInstruction}
          ]
        },
        "generationConfig": {
          "temperature": 1.0,
          "topP": 0.95,
          "topK": 64,
          "maxOutputTokens": 8192,
        }
      };

      safePrint('[Nova API] Sending request...');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Parse response to extract text
        final candidates = jsonResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          
          StringBuffer textOutput = StringBuffer();
          
          // Extract text from parts
          for (var part in parts) {
            if (part.containsKey('text')) {
              textOutput.write(part['text']);
            }
          }
          
          safePrint('[Nova API] Response received');
          
          return {
            'text': textOutput.toString(),
            'thoughtSignature': 'nova-response',
          };
        }
      } else {
        safePrint('[Nova API] Error: ${response.statusCode} - ${response.body}');
        return {
          'text': 'Error: ${response.statusCode} - ${response.body}',
          'thoughtSignature': 'error',
        };
      }
    } catch (e) {
      safePrint('[Nova API] Exception: $e');
      return {
        'text': 'Failed to connect to Nova: $e',
        'thoughtSignature': 'error',
      };
    }
    
    return {
      'text': 'No response from Nova',
      'thoughtSignature': 'no-response',
    };
  }

  /// Analyze receipt image with Nova Vision
  /// Returns structured receipt data
  Future<Map<String, dynamic>> analyzeReceiptImage({
    required String base64Image,
    List<String>? memoryContext,
    String? gpsLocation,
    String? region,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      // Build system instruction with tax rules and memory
      String systemInstruction = '''You are a Finance OS AI specialized in receipt analysis and tax deductions.

<tax_rules_2026>
- Business meals: 50% deductible
- Alcohol: 0% deductible (must be separated)
- Office supplies: 100% deductible
- Travel expenses: 100% deductible
- Entertainment: 0% deductible
- Home office: Proportional deduction based on space
</tax_rules_2026>''';

      if (region != null) {
        systemInstruction += '\n\n<regional_tax_context>\nUser location: $region\nApply local 2026 tax laws for this region.\n</regional_tax_context>';
      }

      if (memoryContext != null && memoryContext.isNotEmpty) {
        systemInstruction += '\n\n<financial_memory>\nYou remember:\n';
        for (final memory in memoryContext) {
          systemInstruction += '- $memory\n';
        }
        systemInstruction += '</financial_memory>';
      }

      final String prompt = '''Analyze this receipt image and extract:
1. Vendor name
2. Total amount
3. Tax amount
4. Category (Business Meal, Office Supplies, Travel, etc.)
5. Alcohol amount (if any)
6. Deductible amount (apply tax rules)

Return JSON format:
{
  "vendor": "string",
  "total": number,
  "tax": number,
  "category": "string",
  "alcoholAmount": number,
  "deductibleAmount": number,
  "thoughtSummary": "brief explanation of deduction logic"
}''';

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "systemInstruction": {
          "parts": [
            {"text": systemInstruction}
          ]
        },
        "generationConfig": {
          "temperature": 1.0,
        }
      };

      safePrint('[Nova Vision] Analyzing receipt...');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final candidates = jsonResponse['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          
          String? textOutput;
          
          for (var part in parts) {
            if (part.containsKey('text')) {
              textOutput = part['text'];
            }
          }
          
          // Parse JSON from text output
          if (textOutput != null) {
            // Extract JSON from markdown code blocks if present
            final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(textOutput);
            final jsonString = jsonMatch?.group(1) ?? textOutput;
            
            try {
              final receiptData = jsonDecode(jsonString) as Map<String, dynamic>;
              receiptData['thoughtSignature'] = 'nova-vision';
              return receiptData;
            } catch (e) {
              safePrint('[Nova Vision] JSON parse error: $e');
              return {
                'vendor': 'Unknown',
                'total': 0.0,
                'tax': 0.0,
                'category': 'Unknown',
                'alcoholAmount': 0.0,
                'deductibleAmount': 0.0,
                'thoughtSummary': 'Failed to parse response',
                'thoughtSignature': 'parse-error',
              };
            }
          }
        }
      } else {
        safePrint('[Nova Vision] Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      safePrint('[Nova Vision] Exception: $e');
    }
    
    return {
      'vendor': 'Error',
      'total': 0.0,
      'tax': 0.0,
      'category': 'Error',
      'alcoholAmount': 0.0,
      'deductibleAmount': 0.0,
      'thoughtSummary': 'Analysis failed',
      'thoughtSignature': 'error',
    };
  }

  /// Raw message sending for testing
  Future<String?> sendRawMessage(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 1.0,
        }
      };

      safePrint('[Nova API] Sending RAW request...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        final candidates = jsonResponse['candidates'] as List;
        if (candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List;
          
          StringBuffer finalOutput = StringBuffer();
          for (var part in parts) {
            if (part.containsKey('text')) {
              finalOutput.write(part['text']);
            }
          }
          return finalOutput.toString();
        }
      } else {
        safePrint('Error: ${response.statusCode} - ${response.body}');
        return "Error: ${response.body}";
      }
    } catch (e) {
      safePrint('Exception: $e');
      return "Failed to connect to Nova.";
    }
    return null;
  }
}
