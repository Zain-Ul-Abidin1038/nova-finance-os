import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'nova_memory.dart';
import 'nova_logger.dart';
import 'nova_router.dart';
import 'nova_cost_estimator.dart';
import 'nova_fallback.dart';
import 'nova_validator.dart';
import 'nova_parser.dart';

final novaServiceV3Provider = Provider((ref) => NovaServiceV3(
      memory: ref.read(novaMemoryProvider),
      logger: ref.read(novaLoggerProvider),
      router: ref.read(novaRouterProvider),
      costEstimator: ref.read(novaCostEstimatorProvider),
      fallback: ref.read(novaFallbackProvider),
      validator: ref.read(novaValidatorProvider),
    ));

/// Nova Service V3 - Production-Grade Layered AI System
/// 
/// Architecture:
/// UI → SimpleChatService → NovaService V3
///   ├── Request Builder
///   ├── Hybrid Model Router (Flash/Pro)
///   ├── Retry Interceptor
///   ├── Response Validator
///   ├── Cost Estimator
///   ├── Thought Memory
///   ├── Logging Middleware
///   └── Offline Fallback Engine
class NovaServiceV3 {
  final NovaMemory memory;
  final NovaLogger logger;
  final NovaRouter router;
  final NovaCostEstimator costEstimator;
  final NovaFallbackEngine fallback;
  final NovaResponseValidator validator;

  NovaServiceV3({
    required this.memory,
    required this.logger,
    required this.router,
    required this.costEstimator,
    required this.fallback,
    required this.validator,
  });

  static String get _apiKey {
    // Try to get from dotenv first
    try {
      final key = dotenv.env['GEMINI_API_KEY'];
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (e) {
      safePrint('[Nova] dotenv not loaded: $e');
    }
    
    // Fallback: Use hardcoded key for web (since .env doesn't work on web)
    // In production, this should come from environment variables or secure config
    const fallbackKey = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'AIzaSyA10HbjmIeRuQ_1CxV7cZrfEeb5JXn91Ms',
    );
    
    if (fallbackKey.isEmpty || fallbackKey == 'AIzaSyA10HbjmIeRuQ_1CxV7cZrfEeb5JXn91Ms') {
      safePrint('[Nova] Using fallback API key');
      return 'AIzaSyA10HbjmIeRuQ_1CxV7cZrfEeb5JXn91Ms';
    }
    
    return fallbackKey;
  }

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Send text message with automatic model selection
  Future<Map<String, dynamic>> sendMessage({
    required String prompt,
    String? systemInstruction,
    bool deepReasoning = false,
    bool isParsing = false,
    bool isMultiTransaction = false,
  }) async {
    try {
      // Select optimal profile
      final profile = router.selectProfile(
        needsDeepReasoning: deepReasoning,
        isVision: false,
        isParsing: isParsing,
        isMultiTransaction: isMultiTransaction,
      );

      // Build request
      final request = _buildTextRequest(
        prompt: prompt,
        systemInstruction: systemInstruction,
        profile: profile,
      );

      logger.logRequest(profile.model, request);

      // Execute with retry
      final response = await _postWithRetry(profile.model, request);

      // Validate response
      validator.validateText(response);

      // Extract thought signature
      memory.lastThoughtSignature = NovaParser.extractThoughtSignature(response);

      // Track cost
      costEstimator.record(response);

      logger.logResponse(response);

      // Extract text
      final result = NovaParser.extractText(response);
      result['thoughtSignature'] = memory.lastThoughtSignature ?? 'none';
      result['success'] = true;

      return result;
    } catch (e) {
      logger.logError(e);
      return fallback.textResponse(prompt);
    }
  }

  /// Send structured JSON message
  Future<Map<String, dynamic>> sendStructuredMessage({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    String? systemInstruction,
    bool deepReasoning = false,
    bool isParsing = true,
  }) async {
    try {
      // Select optimal profile
      final profile = router.selectProfile(
        needsDeepReasoning: deepReasoning,
        isVision: false,
        isParsing: isParsing,
      );

      // Build request with JSON schema
      final request = _buildStructuredRequest(
        prompt: prompt,
        systemInstruction: systemInstruction,
        profile: profile,
        responseSchema: responseSchema,
      );

      logger.logRequest(profile.model, request);

      // Execute with retry
      final response = await _postWithRetry(profile.model, request);

      // Validate response
      validator.validateText(response);

      // Extract thought signature
      memory.lastThoughtSignature = NovaParser.extractThoughtSignature(response);

      // Track cost
      costEstimator.record(response);

      logger.logResponse(response);

      // Extract structured JSON
      final data = NovaParser.extractJson(response);

      return {
        'success': true,
        'data': data,
        'thoughtSignature': memory.lastThoughtSignature ?? 'none',
      };
    } catch (e) {
      logger.logError(e);
      return {
        'success': false,
        'error': e.toString(),
        'data': fallback.financeCommandResponse(),
      };
    }
  }

  /// Analyze receipt with high-resolution vision
  Future<Map<String, dynamic>> analyzeReceiptImage({
    required String base64Image,
    String? region,
  }) async {
    try {
      // Select vision profile
      final profile = router.selectProfile(
        needsDeepReasoning: false,
        isVision: true,
        isParsing: false,
      );

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

      // Build vision request
      final request = _buildVisionRequest(
        prompt: prompt,
        systemInstruction: systemInstruction,
        base64Image: base64Image,
        profile: profile,
      );

      logger.logRequest(profile.model, request);

      // Execute with retry
      final response = await _postWithRetry(profile.model, request);

      // Validate response
      validator.validateText(response);

      // Extract thought signature
      memory.lastThoughtSignature = NovaParser.extractThoughtSignature(response);

      // Track cost
      costEstimator.record(response);

      logger.logResponse(response);

      // Extract receipt data
      final receiptData = NovaParser.extractJson(response);
      receiptData['thoughtSignature'] = memory.lastThoughtSignature ?? 'none';

      // Validate receipt data
      validator.validateReceipt(receiptData);

      return receiptData;
    } catch (e) {
      logger.logError(e);
      return fallback.receiptResponse();
    }
  }

  /// Build text request
  Map<String, dynamic> _buildTextRequest({
    required String prompt,
    String? systemInstruction,
    required RequestProfile profile,
  }) {
    final request = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt}
          ]
        }
      ],
      'generationConfig': profile.buildGenerationConfig(),
    };

    if (systemInstruction != null) {
      request['systemInstruction'] = <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': systemInstruction}
        ]
      };
    }

    // Attach thought signature for continuity
    if (memory.lastThoughtSignature != null) {
      (request['contents'] as List)[0]['parts'].add(<String, dynamic>{
        'thoughtSignature': memory.lastThoughtSignature
      });
    }

    return request;
  }

  /// Build structured JSON request
  Map<String, dynamic> _buildStructuredRequest({
    required String prompt,
    String? systemInstruction,
    required RequestProfile profile,
    required Map<String, dynamic> responseSchema,
  }) {
    final request = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt}
          ]
        }
      ],
      'generationConfig': profile.buildGenerationConfig(
        responseMimeType: 'application/json',
        responseJsonSchema: responseSchema,
      ),
    };

    if (systemInstruction != null) {
      request['systemInstruction'] = <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': systemInstruction}
        ]
      };
    }

    // Attach thought signature for continuity
    if (memory.lastThoughtSignature != null) {
      (request['contents'] as List)[0]['parts'].add(<String, dynamic>{
        'thoughtSignature': memory.lastThoughtSignature
      });
    }

    return request;
  }

  /// Build vision request with high-resolution media
  Map<String, dynamic> _buildVisionRequest({
    required String prompt,
    required String systemInstruction,
    required String base64Image,
    required RequestProfile profile,
  }) {
    final receiptSchema = <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'vendor': <String, String>{'type': 'string'},
        'date': <String, String>{'type': 'string'},
        'total': <String, String>{'type': 'number'},
        'tax': <String, String>{'type': 'number'},
        'currency': <String, String>{'type': 'string'},
        'category': <String, String>{'type': 'string'},
        'alcoholAmount': <String, String>{'type': 'number'},
        'deductibleAmount': <String, String>{'type': 'number'},
        'confidence': <String, String>{'type': 'number'},
        'notes': <String, String>{'type': 'string'}
      },
      'required': <String>['vendor', 'total', 'deductibleAmount']
    };

    final request = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt},
            <String, dynamic>{
              'inlineData': <String, dynamic>{
                'mimeType': 'image/jpeg',
                'data': base64Image
              },
              'mediaResolution': <String, String>{
                'level': 'media_resolution_high'
              }
            }
          ]
        }
      ],
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': systemInstruction}
        ]
      },
      'generationConfig': profile.buildGenerationConfig(
        responseMimeType: 'application/json',
        responseJsonSchema: receiptSchema,
      ),
    };

    return request;
  }

  /// POST with retry and exponential backoff
  Future<Map<String, dynamic>> _postWithRetry(
    String model,
    Map<String, dynamic> requestBody,
  ) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');
    final headers = <String, String>{'Content-Type': 'application/json'};
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
          return jsonDecode(response.body);
        }

        // Don't retry on quota errors (429) or client errors (4xx)
        if (response.statusCode == 429 || (response.statusCode >= 400 && response.statusCode < 500)) {
          safePrint('[Nova V3] Error ${response.statusCode}: ${response.body}');
          throw Exception('API error: ${response.statusCode}');
        }

        // Only retry on server errors (503, 500, etc)
        if (response.statusCode == 503 || response.statusCode >= 500) {
          if (i < delays.length - 1) {
            logger.logRetry(i + 1, delays[i]);
            await Future.delayed(delays[i]);
            continue;
          }
        }
        
        // Other errors - don't retry
        safePrint('[Nova V3] Error ${response.statusCode}: ${response.body}');
        throw Exception('API error: ${response.statusCode}');
      } catch (e) {
        if (i == delays.length - 1) {
          rethrow;
        }
        // Only retry on network errors, not API errors
        if (e is Exception && e.toString().contains('API error')) {
          rethrow;
        }
        await Future.delayed(delays[i]);
      }
    }

    throw Exception('Nova API unavailable after retries');
  }

  /// Reset thought signature (for new conversation)
  void resetThoughtSignature() {
    memory.lastThoughtSignature = null;
  }
  
  /// Get cost summary
  Map<String, dynamic> getCostSummary() {
    return costEstimator.getSummary();
  }
}

/// Predefined JSON Schemas
class NovaSchemas {
  static const financeCommand = {
    'type': 'object',
    'properties': {
      'action': {'type': 'string'},
      'amount': {'type': 'number'},
      'currency': {'type': 'string'},
      'category': {'type': 'string'},
      'personName': {'type': 'string'},
      'description': {'type': 'string'}
    },
    'required': ['action']
  };

  static const receipt = {
    'type': 'object',
    'properties': {
      'vendor': {'type': 'string'},
      'date': {'type': 'string'},
      'total': {'type': 'number'},
      'tax': {'type': 'number'},
      'currency': {'type': 'string'},
      'category': {'type': 'string'},
      'alcoholAmount': {'type': 'number'},
      'deductibleAmount': {'type': 'number'},
      'confidence': {'type': 'number'},
      'notes': {'type': 'string'}
    },
    'required': ['vendor', 'total', 'deductibleAmount']
  };
}
