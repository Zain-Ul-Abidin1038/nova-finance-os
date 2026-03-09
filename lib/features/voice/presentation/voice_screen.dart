import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Tap the microphone to start voice command';
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) {
          debugPrint('onError: $val');
          setState(() {
            _isListening = false;
            _text = 'Error: $val';
          });
        },
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _text = 'Listening...';
        });
        
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords.isEmpty 
                ? 'Listening...' 
                : val.recognizedWords;
          }),
        );
      } else {
        setState(() {
          _text = 'Speech recognition not available';
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      
      if (_text.isNotEmpty && _text != 'Listening...') {
        // TODO: Process voice command with Vertex AI
        setState(() {
          _text = 'Processing: "$_text"\n\n(Configure Firebase to enable AI processing)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    // Theme-aware colors
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: secondaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.mic_none_outlined,
                color: secondaryAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Voice Command',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryAccent.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Microphone button with animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isListening ? _pulseAnimation.value : 1.0,
                                child: GestureDetector(
                                  onTap: _listen,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: _isListening
                                            ? [accentColor, secondaryAccent]
                                            : [
                                                accentColor.withValues(alpha: 0.3),
                                                secondaryAccent.withValues(alpha: 0.3),
                                              ],
                                      ),
                                      boxShadow: _isListening
                                          ? [
                                              BoxShadow(
                                                color: accentColor.withValues(alpha: 0.5),
                                                blurRadius: 30,
                                                spreadRadius: 10,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Status indicator
                          if (_isListening)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'LISTENING...',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 40),
                          
                          // Transcription display
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.text_fields,
                                      color: secondaryAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'TRANSCRIPTION',
                                      style: TextStyle(
                                        color: secondaryAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _text,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Instructions
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: secondaryTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tap the microphone to start or stop voice recording',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
