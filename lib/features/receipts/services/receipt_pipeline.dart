import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/core/services/nova_service_v3.dart';
import 'package:nova_finance_os/core/services/nova_validator.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:nova_finance_os/features/receipts/services/receipt_repository.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:uuid/uuid.dart';

final receiptPipelineProvider = Provider((ref) => ReceiptPipeline(
      nova: ref.read(novaServiceV3Provider),
      validator: ref.read(novaValidatorProvider),
      repository: ref.read(receiptRepositoryProvider),
    ));

/// Receipt Processing Pipeline
/// 
/// Flow: Camera → Nova Vision → Validator → Confidence Gate
///       → (auto-save OR review screen) → Hive → Ledger
class ReceiptPipeline {
  final NovaServiceV3 nova;
  final NovaResponseValidator validator;
  final ReceiptRepository repository;

  ReceiptPipeline({
    required this.nova,
    required this.validator,
    required this.repository,
  });

  /// Process receipt image through complete pipeline
  Future<Receipt> process({
    required String base64Image,
    String? imagePath,
    String? region,
  }) async {
    safePrint('[ReceiptPipeline] Starting processing...');

    try {
      // Step 1: Nova Vision Analysis
      final json = await nova.analyzeReceiptImage(
        base64Image: base64Image,
        region: region,
      );

      safePrint('[ReceiptPipeline] AI analysis complete');
      safePrint('[ReceiptPipeline] Confidence: ${json['confidence']}');

      // Step 2: Create Receipt object
      final receipt = Receipt(
        id: const Uuid().v4(),
        vendor: json['vendor'] ?? 'Unknown',
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] ?? 'INR',
        category: json['category'] ?? 'Other',
        alcoholAmount: (json['alcoholAmount'] as num?)?.toDouble() ?? 0.0,
        deductibleAmount: (json['deductibleAmount'] as num?)?.toDouble() ?? 0.0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.now(),
        requiresReview: validator.requiresManualReview(json),
        notes: json['notes'],
        imagePath: imagePath,
        thoughtSignature: json['thoughtSignature'],
      );

      safePrint('[ReceiptPipeline] Receipt created: ${receipt.id}');
      safePrint('[ReceiptPipeline] Requires review: ${receipt.requiresReview}');

      // Step 3: Confidence Gate
      if (!receipt.requiresReview) {
        // Auto-approve and save
        final approvedReceipt = receipt.copyWith(isApproved: true);
        await repository.save(approvedReceipt);
        safePrint('[ReceiptPipeline] Auto-approved and saved');
        return approvedReceipt;
      } else {
        // Save as pending review
        await repository.save(receipt);
        safePrint('[ReceiptPipeline] Saved for manual review');
        return receipt;
      }
    } catch (e) {
      safePrint('[ReceiptPipeline] Error: $e');
      
      // Create error receipt
      final errorReceipt = Receipt(
        id: const Uuid().v4(),
        vendor: 'Error',
        total: 0.0,
        tax: 0.0,
        currency: 'INR',
        category: 'Error',
        alcoholAmount: 0.0,
        deductibleAmount: 0.0,
        confidence: 0.0,
        createdAt: DateTime.now(),
        requiresReview: true,
        notes: 'Failed to process: $e',
        imagePath: imagePath,
      );

      await repository.save(errorReceipt);
      return errorReceipt;
    }
  }

  /// Approve receipt after manual review
  Future<void> approveReceipt(Receipt receipt) async {
    final approved = receipt.copyWith(
      isApproved: true,
      requiresReview: false,
    );
    await repository.update(approved);
    safePrint('[ReceiptPipeline] Receipt approved: ${receipt.id}');
  }

  /// Update receipt with user edits
  Future<void> updateAndApprove(Receipt receipt) async {
    final approved = receipt.copyWith(
      isApproved: true,
      requiresReview: false,
    );
    await repository.update(approved);
    safePrint('[ReceiptPipeline] Receipt updated and approved: ${receipt.id}');
  }

  /// Mark receipt as personal expense (0% deductible)
  Future<void> markAsPersonal(Receipt receipt) async {
    final personal = receipt.copyWith(
      deductibleAmount: 0.0,
      category: 'Personal',
      isApproved: true,
      requiresReview: false,
      notes: 'Marked as personal expense',
    );
    await repository.update(personal);
    safePrint('[ReceiptPipeline] Marked as personal: ${receipt.id}');
  }

  /// Reject and delete receipt
  Future<void> rejectReceipt(String receiptId) async {
    await repository.delete(receiptId);
    safePrint('[ReceiptPipeline] Receipt rejected: $receiptId');
  }
}
