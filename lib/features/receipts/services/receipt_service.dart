import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:nova_finance_os/features/trace/services/nova_trace_service.dart';
import 'package:nova_finance_os/core/services/nova_service.dart';
import 'package:nova_finance_os/core/services/aws_memory_service.dart';
import 'package:nova_finance_os/core/services/audit_vault_service.dart';
import 'package:geolocator/geolocator.dart';

final receiptServiceProvider = Provider((ref) => ReceiptService(ref));

/// Receipt Service with Nova API (GCP) + AWS Memory Pipeline
class ReceiptService {
  final Ref _ref;
  
  ReceiptService(this._ref);

  /// Analyze receipt with full memory pipeline
  /// 1. Retrieve top 5 financial stories from AWS Memory
  /// 2. Get GPS location for regional tax rules
  /// 3. Call Nova 3 Pro with memory context
  /// 4. Extract thought signature and send to AWS Memory
  /// 5. Save audit trail to S3
  /// 6. Check for financial guardrails
  Future<Receipt> analyzeReceipt(File imageFile) async {
    final traceService = _ref.read(novaTraceServiceProvider);
    final novaService = _ref.read(novaServiceProvider);
    final memoryService = _ref.read(awsMemoryServiceProvider);
    final auditService = _ref.read(auditVaultServiceProvider);
    
    traceService.addTrace("[Nova Agent] 🧠 Initializing receipt analysis...");
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Step 1: Retrieve financial stories from memory
    traceService.addTrace("[Nova Agent] 📚 Retrieving financial memories...");
    final memoryStories = await memoryService.getMemoryStories(limit: 5);
    if (memoryStories.isNotEmpty) {
      traceService.addTrace("[Nova Agent] ✓ Found ${memoryStories.length} relevant memories");
    }
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Step 2: Get GPS location for regional tax rules
    String? region;
    try {
      traceService.addTrace("[Nova Agent] 📍 Getting location for tax rules...");
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      region = await _getRegionFromCoordinates(position.latitude, position.longitude);
      traceService.addTrace("[Nova Agent] ✓ Location: $region");
    } catch (e) {
      traceService.addTrace("[Nova Agent] ⚠️ Location unavailable, using default tax rules");
    }
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Step 3: Check for cash crunch warning
    final hasCashCrunch = await memoryService.detectCashCrunch();
    if (hasCashCrunch) {
      traceService.addTrace("[Nova Agent] ⚠️ FINANCIAL WARNING: Cash crunch detected in history");
    }
    
    // Step 4: Convert image to base64
    traceService.addTrace("[Nova Agent] 📸 Processing image...");
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Step 5: Call Nova API (GCP) with memory context
    traceService.addTrace("[Nova Agent] 🤖 Analyzing with Nova API...");
    final analysisResult = await novaService.analyzeReceiptImage(
      base64Image: base64Image,
      memoryContext: memoryStories,
      region: region,
    );
    
    final thoughtSignature = analysisResult['thoughtSignature'] as String;
    traceService.addTrace("[Nova Agent] 💭 Thought signature captured");
    traceService.addTrace("[Nova Agent] ${analysisResult['thoughtSummary']}");
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Step 6: Create receipt object
    final receipt = Receipt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      total: (analysisResult['total'] as num).toDouble(),
      tax: (analysisResult['tax'] as num).toDouble(),
      category: analysisResult['category'] as String,
      thoughtSignature: thoughtSignature,
      vendor: analysisResult['vendor'] as String,
      alcoholAmount: (analysisResult['alcoholAmount'] as num).toDouble(),
      deductibleAmount: (analysisResult['deductibleAmount'] as num).toDouble(),
      thoughtSummary: analysisResult['thoughtSummary'] as String,
      currency: 'USD',
      confidence: (analysisResult['confidence'] as num?)?.toDouble() ?? 0.85,
      createdAt: DateTime.now(),
      requiresReview: ((analysisResult['confidence'] as num?)?.toDouble() ?? 0.85) < 0.7,
    );
    
    // Step 7: Send thought signature to AWS Memory
    traceService.addTrace("[Nova Agent] 💾 Storing in long-term memory...");
    await memoryService.putMemoryEvent(
      thoughtSignature: thoughtSignature,
      category: receipt.category,
      metadata: {
        'vendor': receipt.vendor,
        'total': receipt.total,
        'deductibleAmount': receipt.deductibleAmount,
        'alcoholAmount': receipt.alcoholAmount,
        'region': region,
      },
    );
    traceService.addTrace("[Nova Agent] ✓ Memory stored");
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Step 8: Save audit trail to S3
    traceService.addTrace("[Nova Agent] 📝 Saving audit trail to vault...");
    final auditData = {
      'receipt': receipt.toJson(),
      'thoughtSignature': thoughtSignature,
      'memoryContext': memoryStories,
      'region': region,
      'analysisTimestamp': DateTime.now().toIso8601String(),
      'novaModel': 'nova-3-pro-preview',
      'thinkingLevel': 'high',
    };
    await auditService.saveAuditTrail(
      receiptId: receipt.id,
      auditData: auditData,
    );
    traceService.addTrace("[Nova Agent] ✓ Audit trail secured");
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Step 9: Financial guardrails check
    if (hasCashCrunch && receipt.total > 100) {
      traceService.addTrace("[Nova Agent] 🚨 TROUBLE WARNING: Large purchase during cash crunch!");
      await memoryService.storeFinancialWarning(
        warningType: 'cash_crunch_purchase',
        message: 'Large purchase (\$${receipt.total.toStringAsFixed(2)}) during cash crunch period',
        context: {
          'receiptId': receipt.id,
          'vendor': receipt.vendor,
          'amount': receipt.total,
        },
      );
    }
    
    traceService.addTrace("[Nova Agent] ✅ Analysis complete!");
    
    return receipt;
  }

  /// Get region name from GPS coordinates
  Future<String> _getRegionFromCoordinates(double lat, double lon) async {
    // Simplified region detection
    // In production, use reverse geocoding API
    if (lat >= 24.0 && lat <= 49.0 && lon >= -125.0 && lon <= -66.0) {
      return 'United States';
    } else if (lat >= 41.0 && lat <= 83.0 && lon >= -141.0 && lon <= -52.0) {
      return 'Canada';
    } else if (lat >= 36.0 && lat <= 71.0 && lon >= -10.0 && lon <= 40.0) {
      return 'Europe';
    }
    return 'Unknown';
  }

  /// Track social ledger (IOU)
  Future<void> trackIOU({
    required String personName,
    required double amount,
    required String type, // 'lent' or 'borrowed'
  }) async {
    final memoryService = _ref.read(awsMemoryServiceProvider);
    final traceService = _ref.read(novaTraceServiceProvider);
    
    traceService.addTrace("[Nova Agent] 💰 Tracking IOU: $type \$${amount.toStringAsFixed(2)} ${type == 'lent' ? 'to' : 'from'} $personName");
    
    await memoryService.storeSocialLedgerEntry(
      personName: personName,
      amount: amount,
      type: type,
      date: DateTime.now(),
    );
    
    traceService.addTrace("[Nova Agent] ✓ IOU recorded in memory");
  }

  /// Get unpaid IOUs
  Future<List<Map<String, dynamic>>> getUnpaidIOUs() async {
    final memoryService = _ref.read(awsMemoryServiceProvider);
    return await memoryService.getUnpaidIOUs();
  }
}
