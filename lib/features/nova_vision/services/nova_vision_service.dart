import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';

final visionNovaServiceProvider = Provider((ref) => VisionNovaService(
      novaService: ref.read(novaServiceV3Provider),
    ));

class VisionNovaService {
  final NovaServiceV3 novaService;

  VisionNovaService({required this.novaService});

  /// Convert image file to base64
  Future<String> _imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Analyze receipt in real-time with quick advice
  Future<Map<String, dynamic>> analyzeReceiptLive(File imageFile) async {
    try {
      safePrint('[Vision Nova] Analyzing live frame...');

      final base64Image = await _imageToBase64(imageFile);

      final result = await novaService.analyzeReceiptImage(
        base64Image: base64Image,
      );

      if (result['vendor'] != null) {
        // Build conversational advice from receipt data
        final vendor = result['vendor'] as String;
        final total = result['total'] as num;
        final deductible = result['deductibleAmount'] as num;
        final category = result['category'] as String? ?? 'expense';
        
        String advice = 'I see a receipt from $vendor for ₹$total.';
        
        if (deductible > 0) {
          final percentage = ((deductible / total) * 100).round();
          advice += ' That\'s $percentage% tax deductible (₹$deductible). Save this receipt!';
        } else {
          advice += ' This is not tax deductible.';
        }

        return {
          'success': true,
          'advice': advice,
          'analysis': 'Receipt from $vendor in $category category',
          'amount': total,
          'category': category,
          'thoughtSignature': result['thoughtSignature'],
        };
      }

      return {
        'success': false,
        'advice': 'Unable to analyze image',
        'analysis': 'Error occurred',
      };
    } catch (e) {
      safePrint('[Vision Nova] Error: $e');
      return {
        'success': false,
        'advice': 'Analysis failed: $e',
        'analysis': 'Error',
      };
    }
  }

  /// Detailed analysis with full breakdown
  Future<Map<String, dynamic>> analyzeReceiptDetailed(File imageFile) async {
    try {
      safePrint('[Vision Nova] Performing detailed analysis...');

      final base64Image = await _imageToBase64(imageFile);

      final result = await novaService.analyzeReceiptImage(
        base64Image: base64Image,
      );

      if (result['vendor'] != null) {
        final vendor = result['vendor'] as String;
        final total = result['total'] as num;
        final deductible = result['deductibleAmount'] as num;
        final category = result['category'] as String? ?? 'expense';
        final date = result['date'] as String? ?? 'Unknown date';
        final notes = result['notes'] as String? ?? '';
        
        final deductionRate = total > 0 ? ((deductible / total) * 100).round() : 0;
        
        String analysis = 'Receipt from $vendor dated $date. Total amount: ₹$total.';
        if (notes.isNotEmpty) {
          analysis += ' $notes';
        }
        
        String advice = 'This is a $category expense. ';
        if (deductible > 0) {
          advice += 'You can deduct ₹$deductible ($deductionRate%) for tax purposes. ';
          advice += 'Make sure to keep this receipt for your records.';
        } else {
          advice += 'This expense is not tax deductible.';
        }

        return {
          'success': true,
          'analysis': analysis,
          'advice': advice,
          'amount': total,
          'taxDeductible': deductible,
          'deductionRate': deductionRate,
          'vendor': vendor,
          'date': date,
          'category': category,
          'thoughtSignature': result['thoughtSignature'],
        };
      }

      return {
        'success': false,
        'analysis': 'Unable to analyze image',
        'advice': 'Please try again',
      };
    } catch (e) {
      safePrint('[Vision Nova] Error: $e');
      return {
        'success': false,
        'analysis': 'Analysis failed: $e',
        'advice': 'Please try again',
      };
    }
  }

  /// Analyze a product before purchase
  Future<Map<String, dynamic>> analyzePurchaseDecision(File imageFile, String context) async {
    try {
      safePrint('[Vision Nova] Analyzing purchase decision...');

      final base64Image = await _imageToBase64(imageFile);

      // For purchase decisions, we'll use the receipt analyzer
      // and interpret the results differently
      final result = await novaService.analyzeReceiptImage(
        base64Image: base64Image,
      );

      if (result['vendor'] != null) {
        final vendor = result['vendor'] as String;
        final total = result['total'] as num;
        final category = result['category'] as String? ?? 'product';
        
        String advice = 'This is a $category from $vendor priced at ₹$total. ';
        advice += 'Consider if this purchase aligns with your budget and needs.';

        return {
          'success': true,
          'product': vendor,
          'price': total,
          'recommendation': 'consider',
          'reasoning': advice,
          'thoughtSignature': result['thoughtSignature'],
        };
      }

      return {
        'success': false,
        'advice': 'Unable to analyze product',
      };
    } catch (e) {
      safePrint('[Vision Nova] Error: $e');
      return {
        'success': false,
        'advice': 'Analysis failed: $e',
      };
    }
  }
}
