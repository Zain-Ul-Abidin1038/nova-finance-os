import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/vision_nova/services/vision_nova_service.dart';

class VisionNovaScreen extends ConsumerStatefulWidget {
  const VisionNovaScreen({super.key});

  @override
  ConsumerState<VisionNovaScreen> createState() => _VisionNovaScreenState();
}

class _VisionNovaScreenState extends ConsumerState<VisionNovaScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _isListening = false;
  String _novaAdvice = '';
  Timer? _analysisTimer;
  final List<String> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startContinuousAnalysis();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        safePrint('[Vision Nova] No cameras available');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      safePrint('[Vision Nova] Camera initialization error: $e');
    }
  }

  void _startContinuousAnalysis() {
    // Analyze frame every 3 seconds for real-time advice
    _analysisTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isInitialized && !_isAnalyzing && _isListening) {
        _analyzeCurrentFrame();
      }
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // Capture current frame
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      // Send to Vision Nova service for analysis
      final visionService = ref.read(visionNovaServiceProvider);
      final result = await visionService.analyzeReceiptLive(imageFile);

      if (result['success'] == true) {
        final advice = result['advice'] as String;

        setState(() {
          _novaAdvice = advice;
          _conversationHistory.add('🤖 Nova: $advice');
        });

        // Speak the advice (text-to-speech would go here)
        safePrint('[Vision Nova] Advice: $advice');
      }
    } catch (e) {
      safePrint('[Vision Nova] Analysis error: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _conversationHistory.add('👻 Vision Nova activated - I\'m watching!');
      } else {
        _conversationHistory.add('👻 Vision Nova paused');
      }
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      final visionService = ref.read(visionNovaServiceProvider);
      final result = await visionService.analyzeReceiptDetailed(imageFile);

      if (result['success'] == true) {
        // Show detailed analysis dialog
        _showDetailedAnalysis(result);
      }
    } catch (e) {
      safePrint('[Vision Nova] Capture error: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _showDetailedAnalysis(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailedAnalysisSheet(result),
    );
  }

  Widget _buildDetailedAnalysisSheet(Map<String, dynamic> result) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.background : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.softPurple.withValues(alpha: 0.3),
                                AppColors.neonTeal.withValues(alpha: 0.2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            color: AppColors.softPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vision Nova Analysis',
                                style: TextStyle(
                                  color: isDark ? AppColors.textPrimary : AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'AI-Powered Financial Advice',
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondary : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Analysis sections
                    _buildAnalysisSection(
                      'What I See',
                      result['analysis'] ?? 'Analyzing...',
                      Icons.visibility_outlined,
                      isDark,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildAnalysisSection(
                      'Financial Advice',
                      result['advice'] ?? 'Processing...',
                      Icons.lightbulb_outline,
                      isDark,
                    ),
                    
                    if (result['amount'] != null) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisSection(
                        'Amount Detected',
                        '₹${result['amount']}',
                        Icons.attach_money,
                        isDark,
                      ),
                    ],
                    
                    if (result['taxDeductible'] != null) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisSection(
                        'Tax Deductible',
                        '₹${result['taxDeductible']} (${result['deductionRate']}%)',
                        Icons.account_balance_outlined,
                        isDark,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Save transaction
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save Transaction'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Dismiss'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisSection(String title, String content, IconData icon, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.neonTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : LightColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : LightColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: AppColors.softPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Vision Nova',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isListening) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonTeal),
              ),
            ),
          
          // Overlay with advice
          if (_isListening && _novaAdvice.isNotEmpty)
            Positioned(
              top: 120,
              left: 16,
              right: 16,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                borderColor: AppColors.softPurple.withValues(alpha: 0.5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.softPurple.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: AppColors.softPurple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Nova Advice',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _novaAdvice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Analysis indicator
          if (_isAnalyzing)
            Positioned(
              top: 100,
              right: 16,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.neonTeal,
                        width: 2,
                      ),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonTeal),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle listening
                  _buildControlButton(
                    icon: _isListening ? Icons.pause : Icons.play_arrow,
                    label: _isListening ? 'Pause' : 'Start',
                    color: _isListening ? Colors.orange : AppColors.neonTeal,
                    onTap: _toggleListening,
                  ),
                  
                  // Capture and analyze
                  _buildControlButton(
                    icon: Icons.camera_alt,
                    label: 'Capture',
                    color: AppColors.softPurple,
                    onTap: _captureAndAnalyze,
                    size: 70,
                  ),
                  
                  // View history
                  _buildControlButton(
                    icon: Icons.history,
                    label: 'History',
                    color: Colors.white.withValues(alpha: 0.7),
                    onTap: () => _showConversationHistory(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double size = 60,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(size / 2),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: size * 0.4,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showConversationHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Conversation History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _conversationHistory.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _conversationHistory[index],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
