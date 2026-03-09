import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// AWS Bedrock Client with Signature V4 Authentication
/// Handles all AWS Bedrock API calls with proper authentication
class AWSBedrockClient {
  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final String? sessionToken;
  
  static const String service = 'bedrock';
  static const String algorithm = 'AWS4-HMAC-SHA256';
  
  AWSBedrockClient({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.region,
    this.sessionToken,
  });

  /// Invoke a Bedrock model
  Future<Map<String, dynamic>> invokeModel({
    required String modelId,
    required Map<String, dynamic> body,
    String? accept,
    String? contentType,
  }) async {
    final endpoint = 'bedrock-runtime.$region.amazonaws.com';
    final path = '/model/$modelId/invoke';
    final url = 'https://$endpoint$path';
    
    final bodyJson = jsonEncode(body);
    final headers = await _signRequest(
      method: 'POST',
      endpoint: endpoint,
      path: path,
      body: bodyJson,
      contentType: contentType ?? 'application/json',
      accept: accept ?? 'application/json',
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: bodyJson,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Bedrock API error: ${response.statusCode}',
          'body': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Sign AWS request with Signature V4
  Future<Map<String, String>> _signRequest({
    required String method,
    required String endpoint,
    required String path,
    required String body,
    required String contentType,
    required String accept,
  }) async {
    final now = DateTime.now().toUtc();
    final amzDate = _getAmzDate(now);
    final dateStamp = _getDateStamp(now);
    
    // Create canonical request
    final payloadHash = _sha256Hash(body);
    final canonicalHeaders = 'content-type:$contentType\n'
        'host:$endpoint\n'
        'x-amz-date:$amzDate\n';
    final signedHeaders = 'content-type;host;x-amz-date';
    
    final canonicalRequest = '$method\n'
        '$path\n'
        '\n'  // query string (empty)
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';
    
    // Create string to sign
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = '$algorithm\n'
        '$amzDate\n'
        '$credentialScope\n'
        '${_sha256Hash(canonicalRequest)}';
    
    // Calculate signature
    final signingKey = _getSignatureKey(secretAccessKey, dateStamp, region, service);
    final signature = _hmacSha256(signingKey, stringToSign);
    
    // Create authorization header
    final authorizationHeader = '$algorithm '
        'Credential=$accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=${hex.encode(signature)}';
    
    final headers = {
      'Content-Type': contentType,
      'Accept': accept,
      'Host': endpoint,
      'X-Amz-Date': amzDate,
      'Authorization': authorizationHeader,
    };
    
    if (sessionToken != null) {
      headers['X-Amz-Security-Token'] = sessionToken!;
    }
    
    return headers;
  }

  /// Get AMZ date format (YYYYMMDD'T'HHMMSS'Z')
  String _getAmzDate(DateTime date) {
    return date.toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0] + 'Z';
  }

  /// Get date stamp (YYYYMMDD)
  String _getDateStamp(DateTime date) {
    return date.toIso8601String().split('T')[0].replaceAll('-', '');
  }

  /// SHA256 hash
  String _sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// HMAC SHA256
  List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    return digest.bytes;
  }

  /// Get signature key
  List<int> _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
    final kDate = _hmacSha256(utf8.encode('AWS4$key'), dateStamp);
    final kRegion = _hmacSha256(kDate, regionName);
    final kService = _hmacSha256(kRegion, serviceName);
    final kSigning = _hmacSha256(kService, 'aws4_request');
    return kSigning;
  }
}
