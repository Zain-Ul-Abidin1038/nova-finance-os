import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final novaServiceV2Provider = Provider((ref) => NovaServiceV2());

/// Nova 3 Service with Production-Grade Optimizations
/// - Structured JSON output (no regex parsing)
/// - Thinking level control (cost optimization)
/// - Thought signature continuity (better reasoning)
/// - Retry logic with exponential backoff
/// - Media resolution control (better OCR)
class NovaServiceV2 {
  // API Key from environment
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }

  // Base URL for Nova 3 Flash Preview
  static const String _baseUrl = 
    'https://generativelanguage.googleapis.com/v1beta/models/nova-3-flash-preview:generateContent';

  // Thought signature storage for reasoning continuity
  String? _lastThoughtSignature;

  /// Send message with structured JSON output
  Future<Map<String, dynamic>> sendStructuredMessage({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    String? systemInstruction,
    String thinkingLevel = 'low',
    int maxTokens = 2048,
  }) async {
    final requestBody = _buildJsonRequest(
      prompt: prompt,
      schema: responseSchema,
      systemInstruction: systemInstruction,
      thinkingLevel: thinkingLevel,
      maxTokens: maxTokens,
    );

    try {
      final response = await _postWithRetry(requestBody);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Extract thought signature for continuity
        _lastThoughtSignature = _extractThoughtSignature(jsonResponse);
        
        // Extract structured JSON response
        final candidates = jsonResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          
          for (var part in parts) {
            if (part.containsKey('text')) {
              // Parse JSON directly (no regex needed with structured output)
              final structuredData = jsonDecode(part['text']);
              return {
                'success': true,
                'data': structuredData,
                'thoughtSignature': _lastThoughtSignature ?? 'none',
              };
            }
          }
        }
      }
      
      return {
        'success': false,
        'error': 'Failed to parse response',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      safePrint('[Nova V2] Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send text message (legacy compatibility)
  Future<Map<String, String>> sendMessage({
    required String prompt,
    String? systemInstruction,
    String thinkingLevel = 'low',
    int maxTokens = 2048,
  }) async {
    final requestBody = _buildTextRequest(
      prompt: prompt,
      systemInstruction: systemInstruction,
      thinkingLevel: thinkingLevel,
      maxTokens: maxTokens,
    );

    try {
      final response = await _postWithRetry(requestBody);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Extract thought signature
        _lastThoughtSignature = _extractThoughtSignature(jsonResponse);
        
        // Extract text
        final candidates = jsonResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          
          StringBuffer textOutput = StringBuffer();
          for (var part in parts) {
            if (part.containsKey('text')) {
              textOutput.write(part['text']);
            }
          }
          
          return {
            'text': textOutput.toString(),
            'thoughtSignature': _lastThoughtSignature ?? 'none',
          };
        }
      }
      
      return {
        'text': 'Error: ${response.statusCode}',
        'thoughtSignature': 'error',
      };
    } catch (e) {
      safePrint('[Nova V2] Exception: $e');
      return {
        'text': 'Failed to connect: $e',
        'thoughtSignature': 'error',
      };
    }
  }

  /// Analyze receipt with high-resolution media and structured output
  Future<Map<String, dynamic>> analyzeReceiptImage({
    required String base64Image,
    String? region,
  }) async {
    final receiptSchema = {
      "type": "object",
      "properties": {
        "vendor": {"type": "string"},
        "date": {"type": "string"},
        "total": {"type": "number"},
        "tax": {"type": "number"},
        "currency": {"type": "string"},
        "category": {"type": "string"},
        "alcoholAmount": {"type": "number"},
        "deductibleAmount": {"type": "number"},
        "confidence": {"type": "number"},
        "notes": {"type": "string"}
      },
      "required": ["vendor", "total", "deductibleAmount"]
    };

    String systemInstruction = '''You are Finance OS AI specialized in receipt analysis.

<tax_rules_2026>
- Business meals: 50% deductible
- Alcohol: 0% deductible (must be separated)
- Office supplies: 100% deductible
- Travel expenses: 100% deductible
- Entertainment: 0% deductible
</tax_rules_2026>''';

    if (region != null) {
      systemInstruction += '\n\n<region>$region</region>';
    }

    final prompt = '''Analyze this receipt and extract structured data.
Calculate deductible amount based on tax rules.
Return confidence score (0-1) for OCR accuracy.''';

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image
              },
              "mediaResolution": {
                "level": "media_resolution_high"
              }
            }
          ]
        }
      ],
      "systemInstruction": {
        "parts": [{"text": systemInstruction}]
      },
      "generationConfig": {
        "thinkingConfig": {"thinkingLevel": "medium"},
        "responseMimeType": "application/json",
        "responseJsonSchema": receiptSchema,
        "maxOutputTokens": 2048
      }
    };

    try {
      final response = await _postWithRetry(requestBody);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Extract thought signature
        _lastThoughtSignature = _extractThoughtSignature(jsonResponse);
        
        // Extract structured receipt data
        final candidates = jsonResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          
          for (var part in parts) {
            if (part.containsKey('text')) {
              final receiptData = jsonDecode(part['text']) as Map<String, dynamic>;
              receiptData['thoughtSignature'] = _lastThoughtSignature ?? 'none';
              return receiptData;
            }
          }
        }
      }
      
      return _errorReceiptData('API error: ${response.statusCode}');
    } catch (e) {
      safePrint('[Nova V2 Vision] Exception: $e');
      return _errorReceiptData('Exception: $e');
    }
  }

  /// Build structured JSON request
  Map<String, dynamic> _buildJsonRequest({
    required String prompt,
    required Map<String, dynamic> schema,
    String? systemInstruction,
    required String thinkingLevel,
    required int maxTokens,
  }) {
    final request = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "thinkingConfig": {"thinkingLevel": thinkingLevel},
        "responseMimeType": "application/json",
        "responseJsonSchema": schema,
        "maxOutputTokens": maxTokens
      }
    };

    if (systemInstruction != null) {
      request["systemInstruction"] = {
        "parts": [{"text": systemInstruction}]
      };
    }

    // Attach thought signature for reasoning continuity
    if (_lastThoughtSignature != null) {
      (request["contents"] as List)[0]["parts"].add({
        "thoughtSignature": _lastThoughtSignature
      });
    }

    return request;
  }

  /// Build text request
  Map<String, dynamic> _buildTextRequest({
    required String prompt,
    String? systemInstruction,
    required String thinkingLevel,
    required int maxTokens,
  }) {
    final request = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "thinkingConfig": {"thinkingLevel": thinkingLevel},
        "maxOutputTokens": maxTokens,
        "temperature": 1.0,
        "topP": 0.95,
        "topK": 64,
      }
    };

    if (systemInstruction != null) {
      request["systemInstruction"] = {
        "parts": [{"text": systemInstruction}]
      };
    }

    // Attach thought signature for reasoning continuity
    if (_lastThoughtSignature != null) {
      (request["contents"] as List)[0]["parts"].add({
        "thoughtSignature": _lastThoughtSignature
      });
    }

    return request;
  }

  /// POST with retry and exponential backoff
  Future<http.Response> _postWithRetry(Map<String, dynamic> requestBody) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(requestBody);

    final delays = [
      Duration(milliseconds: 300),
      Duration(seconds: 1),
      Duration(milliseconds: 2500),
    ];

    for (int i = 0; i < delays.length; i++) {
      try {
        final response = await http.post(url, headers: headers, body: body);

        // Success
        if (response.statusCode == 200) {
          return response;
        }

        // Non-503 error - don't retry
        if (response.statusCode != 503) {
          safePrint('[Nova V2] Error ${response.statusCode}: ${response.body}');
          return response;
        }

        // 503 - retry with backoff
        safePrint('[Nova V2] 503 error, retrying in ${delays[i].inMilliseconds}ms...');
        await Future.delayed(delays[i]);
      } catch (e) {
        if (i == delays.length - 1) {
          rethrow;
        }
        await Future.delayed(delays[i]);
      }
    }

    throw Exception('Nova API unavailable after retries');
  }

  /// Extract thought signature from response
  String? _extractThoughtSignature(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final parts = candidates[0]['content']['parts'] as List;
      for (final part in parts) {
        if (part['thoughtSignature'] != null) {
          return part['thoughtSignature'] as String;
        }
      }
    } catch (e) {
      safePrint('[Nova V2] Failed to extract thought signature: $e');
    }
    return null;
  }

  /// Error receipt data
  Map<String, dynamic> _errorReceiptData(String error) {
    return {
      'vendor': 'Error',
      'date': '',
      'total': 0.0,
      'tax': 0.0,
      'currency': 'INR',
      'category': 'Error',
      'alcoholAmount': 0.0,
      'deductibleAmount': 0.0,
      'confidence': 0.0,
      'notes': error,
      'thoughtSignature': 'error',
    };
  }

  /// Reset thought signature (for new conversation)
  void resetThoughtSignature() {
    _lastThoughtSignature = null;
  }
}

/// Request Profile Presets for Cost Optimization
class NovaProfiles {
  static const fastChat = {
    'thinkingLevel': 'low',
    'maxTokens': 512,
  };

  static const parsing = {
    'thinkingLevel': 'low',
    'maxTokens': 512,
  };

  static const receiptVision = {
    'thinkingLevel': 'medium',
    'maxTokens': 2048,
  };

  static const deepReasoning = {
    'thinkingLevel': 'high',
    'maxTokens': 4096,
  };
}

/// JSON Schemas for Structured Output
class NovaSchemas {
  static const financeCommand = {
    "type": "object",
    "properties": {
      "action": {"type": "string"},
      "amount": {"type": "number"},
      "currency": {"type": "string"},
      "category": {"type": "string"},
      "personName": {"type": "string"},
      "description": {"type": "string"}
    },
    "required": ["action"]
  };

  static const receipt = {
    "type": "object",
    "properties": {
      "vendor": {"type": "string"},
      "date": {"type": "string"},
      "total": {"type": "number"},
      "tax": {"type": "number"},
      "currency": {"type": "string"},
      "category": {"type": "string"},
      "alcoholAmount": {"type": "number"},
      "deductibleAmount": {"type": "number"},
      "confidence": {"type": "number"},
      "notes": {"type": "string"}
    },
    "required": ["vendor", "total", "deductibleAmount"]
  };
}
