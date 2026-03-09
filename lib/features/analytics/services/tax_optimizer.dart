import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:nova_finance_os/features/analytics/domain/tax_plan.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final taxOptimizerProvider = Provider((ref) => TaxOptimizer(
      nova: ref.read(novaServiceV3Provider),
    ));

/// Tax Optimization Planner
/// 
/// Transforms expenses → tax strategy
/// - Calculates total deductions
/// - Provides optimization suggestions
/// - Region-aware tax rules
/// - Quarterly estimate calculator
class TaxOptimizer {
  final NovaServiceV3 nova;

  TaxOptimizer({required this.nova});

  /// Generate comprehensive tax plan
  Future<TaxPlan> generatePlan({
    required List<Receipt> receipts,
    String region = 'US',
    double taxRate = 0.25,
  }) async {
    safePrint('[TaxOptimizer] Generating tax plan for ${receipts.length} receipts...');

    // 1. Calculate total deductions
    double deductibleTotal = 0;
    final Map<String, double> deductionsByCategory = {};

    for (final receipt in receipts.where((r) => r.isApproved)) {
      deductibleTotal += receipt.deductibleAmount;
      
      final category = receipt.category;
      deductionsByCategory[category] = 
          (deductionsByCategory[category] ?? 0) + receipt.deductibleAmount;
    }

    safePrint('[TaxOptimizer] Total deductions: \$${deductibleTotal.toStringAsFixed(2)}');

    // 2. Calculate estimated tax savings
    final estimatedSavings = deductibleTotal * taxRate;

    // 3. Generate suggestions
    final suggestions = await _generateSuggestions(
      receipts: receipts,
      deductibleTotal: deductibleTotal,
      region: region,
    );

    return TaxPlan(
      deductibleTotal: deductibleTotal,
      suggestions: suggestions,
      deductionsByCategory: deductionsByCategory,
      estimatedTaxSavings: estimatedSavings,
    );
  }

  /// Generate AI-powered tax optimization suggestions
  Future<List<String>> _generateSuggestions({
    required List<Receipt> receipts,
    required double deductibleTotal,
    required String region,
  }) async {
    final suggestions = <String>[];

    // Statistical suggestions
    final mealTotal = receipts
        .where((r) => r.category.toLowerCase().contains('meal') || 
                     r.category.toLowerCase().contains('food'))
        .fold(0.0, (sum, r) => sum + r.total);

    if (mealTotal > 0) {
      suggestions.add('📋 Ensure business purpose documented for \$${mealTotal.toStringAsFixed(2)} in meals');
    }

    final officeSupplies = receipts
        .where((r) => r.category.toLowerCase().contains('office') ||
                     r.category.toLowerCase().contains('supplies'))
        .fold(0.0, (sum, r) => sum + r.deductibleAmount);

    if (officeSupplies > 500) {
      suggestions.add('🏢 Consider Section 179 deduction for \$${officeSupplies.toStringAsFixed(2)} in office equipment');
    }

    // AI-powered suggestions
    try {
      final prompt = '''Tax Optimization Analysis:
- Region: $region
- Total Deductions: \$${deductibleTotal.toStringAsFixed(2)}
- Meal Expenses: \$${mealTotal.toStringAsFixed(2)}
- Receipt Count: ${receipts.length}

Provide 2 specific tax optimization tips for this business.''';

      final response = await nova.sendMessage(
        prompt: prompt,
        systemInstruction: '''You are a tax optimization advisor.

Provide specific, actionable tax tips:
- Reference actual amounts from the data
- Mention specific deductions or strategies
- Use emoji prefixes
- Keep each tip to one sentence

Focus on legitimate tax optimization strategies.''',
        deepReasoning: true,
      );

      final aiSuggestions = (response['text'] ?? '')
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(2)
          .toList();

      suggestions.addAll(aiSuggestions);
    } catch (e) {
      safePrint('[TaxOptimizer] AI suggestions failed: $e');
      
      // Fallback suggestions
      suggestions.add('🏠 Track home office area for proportional deduction');
      suggestions.add('📱 Keep digital copies of all receipts for audit protection');
    }

    return suggestions;
  }

  /// Calculate quarterly estimated tax
  Future<Map<String, double>> calculateQuarterlyEstimate({
    required double annualIncome,
    required double annualDeductions,
    double taxRate = 0.25,
  }) async {
    final taxableIncome = annualIncome - annualDeductions;
    final annualTax = taxableIncome * taxRate;
    final quarterlyPayment = annualTax / 4;

    return {
      'taxableIncome': taxableIncome,
      'annualTax': annualTax,
      'quarterlyPayment': quarterlyPayment,
    };
  }

  /// Estimate audit risk score (0-100)
  Future<int> estimateAuditRisk({
    required List<Receipt> receipts,
    required double totalIncome,
  }) async {
    int riskScore = 0;

    // High deduction ratio
    final totalDeductions = receipts
        .where((r) => r.isApproved)
        .fold(0.0, (sum, r) => sum + r.deductibleAmount);

    final deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0;

    if (deductionRatio > 0.5) {
      riskScore += 30; // High deduction ratio
    } else if (deductionRatio > 0.3) {
      riskScore += 15;
    }

    // Large cash transactions
    final largeCashReceipts = receipts
        .where((r) => r.total > 10000)
        .length;

    riskScore += largeCashReceipts * 10;

    // Missing documentation
    final missingDocs = receipts
        .where((r) => r.notes == null || r.notes!.isEmpty)
        .length;

    riskScore += (missingDocs / receipts.length * 20).toInt();

    // Low confidence receipts
    final lowConfidence = receipts
        .where((r) => r.confidence < 0.8)
        .length;

    riskScore += (lowConfidence / receipts.length * 15).toInt();

    return riskScore.clamp(0, 100);
  }

  /// Get region-specific tax rules
  Map<String, dynamic> getRegionTaxRules(String region) {
    // Simplified - would be expanded with real tax rules
    switch (region.toUpperCase()) {
      case 'US':
        return {
          'mealDeduction': 0.5,
          'alcoholDeduction': 0.0,
          'officeSupplies': 1.0,
          'travel': 1.0,
          'homeOffice': 'proportional',
          'standardMileage': 0.655, // 2023 rate
        };
      case 'UK':
        return {
          'mealDeduction': 1.0,
          'alcoholDeduction': 0.0,
          'officeSupplies': 1.0,
          'travel': 1.0,
          'homeOffice': 'proportional',
        };
      default:
        return {
          'mealDeduction': 0.5,
          'alcoholDeduction': 0.0,
          'officeSupplies': 1.0,
          'travel': 1.0,
        };
    }
  }
}
