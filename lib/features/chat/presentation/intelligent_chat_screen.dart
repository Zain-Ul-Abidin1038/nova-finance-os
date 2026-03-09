import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/core/presentation/widgets/nova_logo.dart';
import 'package:nova_finance_os/features/chat/services/simple_chat_service.dart';
import 'package:nova_finance_os/features/receipts/services/hive_transaction_provider.dart';
import 'package:nova_finance_os/core/services/permission_service.dart';

class IntelligentChatScreen extends ConsumerStatefulWidget {
  const IntelligentChatScreen({super.key});

  @override
  ConsumerState<IntelligentChatScreen> createState() => _IntelligentChatScreenState();
}

class _IntelligentChatScreenState extends ConsumerState<IntelligentChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isProcessing = false;
  bool _isListening = false;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Initialize chat service and load messages FOR DISPLAY ONLY
    // IMPORTANT: Do NOT reprocess old messages through AI parser
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatService = ref.read(simpleChatServiceProvider);
      await chatService.initialize();
      final messages = chatService.getMessages();
      
      if (messages.isEmpty) {
        // Add welcome message
        final welcomeMessage = ChatMessage(
          text: 'Hello! I\'m Finance OS, your intelligent financial assistant. I can help you:\n\n• Track expenses and income\n• Manage loans and IOUs\n• Analyze spending patterns\n• Provide financial insights\n\nJust tell me what you spent or ask me anything!',
          isUser: false,
          timestamp: DateTime.now(),
        );
        await chatService.saveMessage(welcomeMessage);
        setState(() => _messages = [welcomeMessage]);
      } else {
        // Load messages for display only - do NOT process them
        setState(() => _messages = messages);
      }
    });
    
    // Listen to text changes for animated send button
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // Request storage permission
      final permissionService = ref.read(permissionServiceProvider);
      final hasPermission = await permissionService.hasPhotosPermission();
      
      if (!hasPermission) {
        final granted = await permissionService.requestPhotos();
        if (!granted) {
          _showError('Storage permission is required to pick files');
          return;
        }
      }
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _processFile(file);
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _scanReceipt() async {
    try {
      // Request camera permission
      final permissionService = ref.read(permissionServiceProvider);
      final hasPermission = await permissionService.hasCameraPermission();
      
      if (!hasPermission) {
        final granted = await permissionService.requestCamera();
        if (!granted) {
          _showError('Camera permission is required to scan receipts');
          return;
        }
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        await _processFile(file);
      }
    } catch (e) {
      _showError('Failed to scan receipt: $e');
    }
  }

  Future<void> _processFile(File file) async {
    setState(() => _isProcessing = true);
    
    final chatService = ref.read(simpleChatServiceProvider);
    
    // Add user message with file indicator
    final userMessage = ChatMessage(
      text: '📎 Sent ${file.path.split('/').last}',
      isUser: true,
      timestamp: DateTime.now(),
    );
    await chatService.saveMessage(userMessage);
    setState(() => _messages = [..._messages, userMessage]);
    
    _scrollToBottom();
    
    // Add thinking indicator
    final thinkingMessage = ChatMessage(
      text: 'Analyzing image with AI...',
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() => _messages = [..._messages, thinkingMessage]);
    
    try {
      // Process file with Nova Vision API
      final result = await chatService.processImageFile(file);
      
      final filteredMessages = _messages.where((m) => m.text != 'Analyzing image with AI...').toList();
      
      final aiMessage = ChatMessage(
        text: result['message'] ?? 'Processed your image!',
        isUser: false,
        timestamp: DateTime.now(),
        thoughtSignature: result['thoughtSignature'],
      );
      await chatService.saveMessage(aiMessage);
      setState(() => _messages = [...filteredMessages, aiMessage]);
      
      // Refresh transaction list if entry was created
      if (result['transaction'] != null) {
        ref.invalidate(hiveTransactionProvider);
      }
      
      _scrollToBottom();
    } catch (e) {
      final filteredMessages = _messages.where((m) => m.text != 'Analyzing image with AI...').toList();
      
      final errorMessage = ChatMessage(
        text: 'Sorry, I couldn\'t process that image: $e\n\nPlease try again or describe it to me.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await chatService.saveMessage(errorMessage);
      setState(() => _messages = [...filteredMessages, errorMessage]);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _startVoiceInput() async {
    try {
      // Request microphone permission
      final permissionService = ref.read(permissionServiceProvider);
      final hasPermission = await permissionService.hasMicrophonePermission();
      
      if (!hasPermission) {
        final granted = await permissionService.requestMicrophone();
        if (!granted) {
          _showError('Microphone permission is required for voice input');
          return;
        }
      }
      
      if (!_isListening) {
        final available = await _speechToText.initialize(
          onError: (error) {
            safePrint('[Voice] Error: $error');
            setState(() => _isListening = false);
            _showError('Voice input error: ${error.errorMsg}');
          },
          onStatus: (status) {
            safePrint('[Voice] Status: $status');
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
              if (_textController.text.isNotEmpty) {
                _sendMessage();
              }
            }
          },
        );
        
        if (available) {
          setState(() => _isListening = true);
          
          _speechToText.listen(
            onResult: (result) {
              setState(() {
                _textController.text = result.recognizedWords;
              });
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
          
          // Show listening indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('Listening... Speak now'),
                  ],
                ),
                backgroundColor: Colors.orange.shade400,
                duration: const Duration(seconds: 30),
                action: SnackBarAction(
                  label: 'Stop',
                  textColor: Colors.white,
                  onPressed: () {
                    _speechToText.stop();
                    setState(() => _isListening = false);
                  },
                ),
              ),
            );
          }
        } else {
          _showError('Speech recognition not available on this device');
        }
      } else {
        // Stop listening
        setState(() => _isListening = false);
        _speechToText.stop();
        
        // Auto-send if we have text
        if (_textController.text.isNotEmpty) {
          await _sendMessage();
        }
      }
    } catch (e) {
      safePrint('[Voice] Exception: $e');
      _showError('Voice input failed: $e');
      setState(() => _isListening = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    final chatService = ref.read(simpleChatServiceProvider);
    
    // Add user message
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await chatService.saveMessage(userMessage);
    setState(() {
      _messages = [..._messages, userMessage];
    });

    _textController.clear();
    _scrollToBottom();

    // Add thinking indicator
    final thinkingMessage = ChatMessage(
      text: 'Thinking...',
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages = [..._messages, thinkingMessage];
    });

    try {
      // Process message with intelligent service
      final result = await chatService.processMessage(message);

      // Remove thinking indicator
      final filteredMessages = _messages.where((m) => m.text != 'Thinking...').toList();
      
      // Add AI response
      final aiMessage = ChatMessage(
        text: result['message'] ?? 'No response',
        isUser: false,
        timestamp: DateTime.now(),
        thoughtSignature: result['thoughtSignature'],
      );
      await chatService.saveMessage(aiMessage);
      setState(() {
        _messages = [...filteredMessages, aiMessage];
      });

      // If transaction was created, refresh the transaction list
      if (result['transaction'] != null) {
        ref.invalidate(hiveTransactionProvider);
      }

      _scrollToBottom();
    } catch (e) {
      // Remove thinking indicator
      final filteredMessages = _messages.where((m) => m.text != 'Thinking...').toList();

      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error: $e\n\nPlease try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await chatService.saveMessage(errorMessage);
      setState(() {
        _messages = [...filteredMessages, errorMessage];
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.glassWhite 
                    : Colors.white.withValues(alpha: 0.7),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.glassBorder : LightColors.glassBorder,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.glassWhite 
                      : Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.glassBorder : LightColors.glassBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: textColor, size: 20),
              ),
            ),
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          children: [
            const NovaLogo(size: 40, showGlow: false),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Finance OS',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'AI-Powered Expense Tracking',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: secondaryTextColor),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat History?'),
                  content: const Text('This will delete all messages.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final chatService = ref.read(simpleChatServiceProvider);
                await chatService.clearMessages();
                setState(() => _messages = []);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                secondaryAccent.withValues(alpha: 0.2),
                                accentColor.withValues(alpha: 0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chat_bubble_outline, color: secondaryAccent, size: 48),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start a conversation',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(
                        message,
                        textColor,
                        secondaryTextColor,
                        accentColor,
                        secondaryAccent,
                        isDark,
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced from 10 to 6
              borderRadius: 28,
              blur: 20,
              borderColor: isDark ? AppColors.glassBorder : LightColors.glassBorder,
              child: SafeArea(
                child: Row(
                  children: [
                    // + Button (File Picker) - Coming Soon
                    Tooltip(
                      message: 'Coming Soon',
                      child: _buildInputButton(
                        icon: Icons.add_circle_outline,
                        color: secondaryAccent.withValues(alpha: 0.5),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('📎 File upload coming soon!'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: secondaryAccent.withValues(alpha: 0.9),
                            ),
                          );
                        },
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 6), // Reduced from 8
                    
                    // Scanner Button - Coming Soon
                    Tooltip(
                      message: 'Coming Soon',
                      child: _buildInputButton(
                        icon: Icons.document_scanner_outlined,
                        color: accentColor.withValues(alpha: 0.5),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('📸 Receipt scanning coming soon!'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: accentColor.withValues(alpha: 0.9),
                            ),
                          );
                        },
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 6), // Reduced from 8
                    
                    // Audio Button - Coming Soon
                    Tooltip(
                      message: 'Coming Soon',
                      child: _buildInputButton(
                        icon: Icons.mic_none_outlined,
                        color: Colors.orange.shade400.withValues(alpha: 0.5),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('🎤 Voice input coming soon!'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.orange.shade400.withValues(alpha: 0.9),
                            ),
                          );
                        },
                        enabled: true,
                        isActive: false,
                      ),
                    ),
                    const SizedBox(width: 10), // Reduced from 12
                    
                    // Text Input
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: textColor, fontSize: 14), // Reduced from 15
                        decoration: InputDecoration(
                          hintText: 'Tell me anything...',
                          hintStyle: TextStyle(
                            color: secondaryTextColor.withValues(alpha: 0.6),
                            fontSize: 14, // Reduced from 15
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced from 12
                          isDense: true, // Makes the field more compact
                        ),
                        maxLines: 1, // Changed from null to 1 for single line
                        enabled: !_isProcessing,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 6), // Reduced from 8
                    
                    // Animated Send Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _textController.text.isNotEmpty
                              ? [accentColor, secondaryAccent]
                              : [
                                  secondaryTextColor.withValues(alpha: 0.3),
                                  secondaryTextColor.withValues(alpha: 0.2),
                                ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: _textController.text.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: secondaryAccent.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isProcessing ? null : _sendMessage,
                          borderRadius: BorderRadius.circular(20), // Reduced from 24
                          child: Container(
                            padding: const EdgeInsets.all(10), // Reduced from 12
                            child: _isProcessing
                                ? SizedBox(
                                    width: 20, // Reduced from 22
                                    height: 20, // Reduced from 22
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
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

  Widget _buildMessageBubble(
    ChatMessage message,
    Color textColor,
    Color secondaryTextColor,
    Color accentColor,
    Color secondaryAccent,
    bool isDark,
  ) {
    final isThinking = message.text == 'Thinking...';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    secondaryAccent.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: secondaryAccent.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: secondaryAccent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(Icons.psychology_outlined, color: secondaryAccent, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? accentColor.withValues(alpha: 0.15)
                        : (isDark ? AppColors.glassWhite : Colors.white.withValues(alpha: 0.7)),
                    gradient: message.isUser
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.25),
                              secondaryAccent.withValues(alpha: 0.15),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: message.isUser
                          ? accentColor.withValues(alpha: 0.5)
                          : (isDark ? AppColors.glassBorder : const Color(0xFFE0E0E0)),
                      width: 1.5,
                    ),
                    boxShadow: message.isUser
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.2),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isThinking)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(secondaryAccent),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              message.text,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          message.text,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: secondaryTextColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(Icons.person_outline_rounded, color: accentColor, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInputButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool enabled,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18), // Reduced from 20
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(8), // Reduced from 10
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.35),
                      color.withValues(alpha: 0.25),
                    ],
                  )
                : null,
            color: isActive ? null : color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18), // Reduced from 20
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.7)
                  : color.withValues(alpha: 0.3),
              width: isActive ? 2 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: Icon(
            icon,
            color: enabled ? color : color.withValues(alpha: 0.5),
            size: 18, // Reduced from 20
          ),
        ),
      ),
    );
  }
}
