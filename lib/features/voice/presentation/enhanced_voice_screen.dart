import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/trace/services/nova_trace_service.dart';

class EnhancedVoiceScreen extends ConsumerStatefulWidget {
  const EnhancedVoiceScreen({super.key});

  @override
  ConsumerState<EnhancedVoiceScreen> createState() => _EnhancedVoiceScreenState();
}

class _EnhancedVoiceScreenState extends ConsumerState<EnhancedVoiceScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = '';
  String _aiResponse = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _transcription = '';
          _aiResponse = '';
        });
        
        _speech.listen(
          onResult: (result) {
            setState(() {
              _transcription = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      
      if (_transcription.isNotEmpty) {
        await _processVoiceInput();
      }
    }
  }

  Future<void> _processVoiceInput() async {
    setState(() {
      _isProcessing = true;
    });

    final traceService = ref.read(novaTraceServiceProvider);

    traceService.addTrace("[Voice] Processing: '$_transcription'");
    traceService.addTrace("[Voice] AI services have been removed");

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _aiResponse = 'AI services have been removed.\n\n'
            'Your voice input was:\n"$_transcription"\n\n'
            'Mock analysis:\n'
            'Amount: \$50.00\n'
            'Category: Business Expense\n'
            'Vendor: Unknown\n'
            'Notes: AI analysis not available';
        _isProcessing = false;
      });

      traceService.addTrace("[Voice] Mock analysis returned");
    } catch (e) {
      setState(() {
        _aiResponse = 'Error processing voice input: $e';
        _isProcessing = false;
      });
      traceService.addTrace("[Voice ERROR] $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppColors.softPurple.withValues(alpha: 0.15),
                    AppColors.background,
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.softPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: AppColors.softPurple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Voice Assistant',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Center(
                      child: GestureDetector(
                        onTapDown: (_) => _startListening(),
                        onTapUp: (_) => _stopListening(),
                        onTapCancel: () => _stopListening(),
                        child: _isListening
                            ? Pulse(
                                infinite: true,
                                duration: const Duration(milliseconds: 1000),
                                child: _buildMicButton(true),
                              )
                            : _buildMicButton(false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Center(
                      child: Text(
                        _isListening
                            ? 'Listening...'
                            : _isProcessing
                                ? 'Processing...'
                                : 'Hold to speak',
                        style: TextStyle(
                          color: _isListening ? AppColors.neonTeal : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_transcription.isNotEmpty)
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.record_voice_over, color: AppColors.neonTeal, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Transcription',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _transcription,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_aiResponse.isNotEmpty)
                    FadeInUp(
                      duration: const Duration(milliseconds: 1100),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.psychology, color: AppColors.softPurple, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'AI Analysis',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _aiResponse,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Expense saved to Safe Layer!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonTeal,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Expense',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lightbulb_outline, color: AppColors.neonTeal, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Try saying:',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildExampleChip('"I spent \$45 on office supplies at Staples"'),
                          const SizedBox(height: 8),
                          _buildExampleChip('"Lunch meeting at The Bistro, \$85"'),
                          const SizedBox(height: 8),
                          _buildExampleChip('"Uber to client meeting, \$22"'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton(bool isActive) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isActive
              ? [AppColors.neonTeal, AppColors.softPurple]
              : [AppColors.glassBorder.withValues(alpha: 0.3), AppColors.glassBorder.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.neonTeal.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ]
            : [],
      ),
      child: Icon(
        Icons.mic,
        size: 50,
        color: isActive ? AppColors.background : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassBorder.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
