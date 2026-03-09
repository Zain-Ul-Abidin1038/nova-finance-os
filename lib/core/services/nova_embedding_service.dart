import 'dart:convert';
import 'dart:math' as math;
import 'aws_bedrock_client.dart';

/// Nova Multimodal Embeddings Service
/// Uses Amazon Titan Embeddings V2 for:
/// - Financial knowledge retrieval
/// - Tax policy search
/// - Receipt similarity search
/// - Memory retrieval
/// - Document search
/// 
/// Real AWS Bedrock Integration
class NovaEmbeddingService {
  final AWSBedrockClient bedrockClient;
  static const String modelId = 'amazon.titan-embed-text-v2:0';
  
  NovaEmbeddingService({
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

  /// Generate embeddings for text using Titan Embeddings V2
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final requestBody = {
        'inputText': text,
        'dimensions': 1024,
        'normalize': true,
      };

      final response = await bedrockClient.invokeModel(
        modelId: modelId,
        body: requestBody,
      );

      if (response['success'] == true) {
        final data = response['data'];
        return List<double>.from(data['embedding']);
      } else {
        throw Exception('Titan embedding error: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Nova embedding service error: $e');
    }
  }

  /// Search financial knowledge base using embeddings
  Future<List<Map<String, dynamic>>> searchFinancialKnowledge({
    required String query,
    required List<Map<String, dynamic>> knowledgeBase,
    int topK = 5,
  }) async {
    try {
      // Generate query embedding
      final queryEmbedding = await generateEmbedding(query);
      
      // Calculate similarity scores
      final results = <Map<String, dynamic>>[];
      for (final doc in knowledgeBase) {
        // Check if document already has embedding
        List<double> docEmbedding;
        if (doc.containsKey('embedding')) {
          docEmbedding = List<double>.from(doc['embedding']);
        } else {
          // Generate embedding for document
          final docText = doc['text'] ?? doc['content'] ?? doc.toString();
          docEmbedding = await generateEmbedding(docText);
        }
        
        final similarity = _cosineSimilarity(queryEmbedding, docEmbedding);
        
        results.add({
          ...doc,
          'similarity': similarity,
        });
      }
      
      // Sort by similarity and return top K
      results.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
      return results.take(topK).toList();
    } catch (e) {
      throw Exception('Knowledge search error: $e');
    }
  }

  /// Search tax policies using embeddings
  Future<List<Map<String, dynamic>>> searchTaxPolicies({
    required String query,
    required List<Map<String, dynamic>> policies,
  }) async {
    return await searchFinancialKnowledge(
      query: query,
      knowledgeBase: policies,
      topK: 3,
    );
  }

  /// Find similar receipts using embeddings
  Future<List<Map<String, dynamic>>> findSimilarReceipts({
    required String receiptDescription,
    required List<Map<String, dynamic>> receipts,
  }) async {
    return await searchFinancialKnowledge(
      query: receiptDescription,
      knowledgeBase: receipts,
      topK: 5,
    );
  }

  /// Retrieve relevant memories using embeddings
  Future<List<Map<String, dynamic>>> retrieveMemories({
    required String context,
    required List<Map<String, dynamic>> memories,
  }) async {
    return await searchFinancialKnowledge(
      query: context,
      knowledgeBase: memories,
      topK: 3,
    );
  }

  /// Search documents using embeddings
  Future<List<Map<String, dynamic>>> searchDocuments({
    required String query,
    required List<Map<String, dynamic>> documents,
  }) async {
    return await searchFinancialKnowledge(
      query: query,
      knowledgeBase: documents,
      topK: 10,
    );
  }

  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have same length');
    }
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }
    
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }
}
