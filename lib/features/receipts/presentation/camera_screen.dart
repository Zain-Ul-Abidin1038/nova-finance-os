import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/core/presentation/widgets/thought_trace_terminal.dart';
import 'package:nova_finance_os/features/receipts/domain/receipt.dart';
import 'package:nova_finance_os/features/receipts/services/receipt_service.dart';
import 'package:nova_finance_os/features/receipts/services/hive_transaction_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  File? _image;
  final _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _getImage(ImageSource source) async {
    final themeMode = ref.read(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final errorColor = isDark ? AppColors.error : LightColors.error;
    
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isAnalyzing = true;
        });

        final receiptService = ref.read(receiptServiceProvider);
        try {
          final receipt = await receiptService.analyzeReceipt(_image!);
          if (mounted) {
            setState(() => _isAnalyzing = false);
            _showReceiptResult(receipt);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isAnalyzing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Analysis failed: $e'), backgroundColor: errorColor),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showReceiptResult(Receipt receipt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildResultSheet(receipt),
    );
  }

  Widget _buildResultSheet(Receipt receipt) {
    final themeMode = ref.read(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final mutedTextColor = isDark ? AppColors.textMuted : LightColors.textMuted;
    final successColor = isDark ? AppColors.success : LightColors.success;
    
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      borderRadius: 32,
      borderColor: accentColor.withValues(alpha: 0.3),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mutedTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user_outlined, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INTELLECTUAL AUDIT COMPLETE', 
                      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('Financial Extraction', 
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // MISSION 3: ThoughtTraceTerminal - Shows AI thinking in real-time
          ThoughtTraceTerminal(
            thoughtSummary: receipt.thoughtSummary,
            verificationSteps: receipt.verificationSteps,
          ),
          const SizedBox(height: 24),
          
          _buildResultItem('Vendor', receipt.vendor?.toUpperCase() ?? 'UNKNOWN', textColor, secondaryTextColor),
          _buildResultItem('Total', '\${receipt.total.toStringAsFixed(2)}', textColor, secondaryTextColor, isCritical: true),
          _buildResultItem('Deductible', '\${receipt.deductibleAmount.toStringAsFixed(2)}', textColor, secondaryTextColor, accentColor: successColor),
          _buildResultItem('Category', receipt.category, textColor, secondaryTextColor),
          
          if (receipt.thoughtSignature != null) ...[
            const SizedBox(height: 24),
            GlassNotification(
              title: 'GHOST REASONING',
              message: receipt.thoughtSignature!,
              icon: Icons.psychology_outlined,
              accentColor: secondaryAccent,
            ),
          ],
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: () {
              ref.read(hiveTransactionProvider.notifier).addReceipt(receipt);
              Navigator.pop(context); // Close sheet
              context.go('/'); // Go home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, secondaryAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'VAULT TRANSACTION',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color textColor, Color secondaryTextColor, {bool isCritical = false, Color? accentColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: accentColor ?? (isCritical ? textColor : secondaryTextColor),
              fontSize: isCritical ? 20 : 16,
              fontWeight: isCritical ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final mutedTextColor = isDark ? AppColors.textMuted : LightColors.textMuted;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;
    final borderColor = isDark ? AppColors.glassBorder : LightColors.glassBorder;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background reflection
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryAccent.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(textColor),
                Expanded(
                  child: Center(
                    child: _buildCameraPreview(mutedTextColor, borderColor),
                  ),
                ),
                _buildControls(accentColor, secondaryAccent),
              ],
            ),
          ),

          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: accentColor),
                      const SizedBox(height: 24),
                      Text(
                        'ANALYZING WITH GHOST EYES...',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 8),
          Text(
            'SECURE SCAN',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(Color mutedTextColor, Color borderColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: _image == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: mutedTextColor, size: 64),
                const SizedBox(height: 16),
                Text('NO IMAGE CAPTURED', style: TextStyle(color: mutedTextColor, fontWeight: FontWeight.bold)),
              ],
            )
          : Image.file(_image!, fit: BoxFit.cover),
    );
  }

  Widget _buildControls(Color accentColor, Color secondaryAccent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NeonButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            isSecondary: true,
            neonColor: secondaryAccent,
            onPressed: () => _getImage(ImageSource.gallery),
          ),
          GestureDetector(
            onTap: () => _getImage(ImageSource.camera),
            child: Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 3),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 36),
              ),
            ),
          ),
          const SizedBox(width: 72), // Spacer to balance NeonButton
        ],
      ),
    );
  }
}
