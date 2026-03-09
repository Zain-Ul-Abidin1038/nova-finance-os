import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/grounded_chat/services/grounded_chat_service.dart';
import 'package:nova_finance_os/features/chat/services/simple_chat_service.dart';

class GroundedChatScreen extends ConsumerStatefulWidget {
  const GroundedChatScreen({super.key});

  @override
  ConsumerState<GroundedChatScreen> createState() => _GroundedChatScreenState();
}

class _GroundedChatScreenState extends ConsumerState<GroundedChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;
  List<ChatMessage> _messages = [];
  String _liveStatus = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final chatService = ref.read(simpleChatServiceProvider);
    await chatService.initialize();
    final messages = chatService.getMessages();
    
    if (messages.isEmpty) {
      final welcomeMessage = ChatMessage(
        text: '👋 Hello! I\'m Finance OS with Grounded Search.\n\nI can provide factual answers by searching:\n• 🌐 The web for real-time information\n• 📚 Tax & accounting documents\n\nAsk me anything!',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await chatService.saveMessage(welcomeMessage);
      setState(() => _messages = [welcomeMessage]);
    } else {
      setState(() => _messages = messages);
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    final chatService = ref.read(simpleChatServiceProvider);
    final groundedService = ref.read(groundedChatServiceProvider);
    
    // Add user message
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await chatService.saveMessage(userMessage);
    setState(() => _messages = [..._messages, userMessage]);

    _textController.clear();
    _scrollToBottom();

    // Stream grounded response with live status
    try {
      await for (final update in groundedService.streamGroundedResponse(message)) {
        final status = update['status'] as String;
        
        if (status == 'complete') {
          // Remove status message
          setState(() {
            _messages = _messages.where((m) => !m.text.contains('...')).toList();
            _liveStatus = '';
          });

          // Add final response
          final responseText = update['message'] as String;
          final isGrounded = update['isGrounded'] as bool? ?? false;
          final citations = update['citations'] as List?;

          final aiMessage = ChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
            metadata: {
              'isGrounded': isGrounded,
              'citations': citations,
            },
          );
          await chatService.saveMessage(aiMessage);
          setState(() => _messages = [..._messages, aiMessage]);
        } else {
          // Update live status
          final statusMessage = update['message'] as String;
          setState(() => _liveStatus = statusMessage);
          
          // Show status in UI
          final existingStatus = _messages.lastWhere(
            (m) => m.text.contains('...'),
            orElse: () => ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
          );
          
          if (existingStatus.text.isEmpty) {
            final statusMsg = ChatMessage(
              text: statusMessage,
              isUser: false,
              timestamp: DateTime.now(),
            );
            setState(() => _messages = [..._messages, statusMsg]);
          } else {
            setState(() {
              final index = _messages.indexOf(existingStatus);
              _messages[index] = ChatMessage(
                text: statusMessage,
                isUser: false,
                timestamp: DateTime.now(),
              );
            });
          }
        }
        
        _scrollToBottom();
      }
    } catch (e) {
      safePrint('[Grounded Chat] Error: $e');
      
      // Remove status messages
      setState(() {
        _messages = _messages.where((m) => !m.text.contains('...')).toList();
      });

      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await chatService.saveMessage(errorMessage);
      setState(() => _messages = [..._messages, errorMessage]);
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
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Grounded Chat',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'Factual answers with sources',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          
          // Live status indicator
          if (_liveStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 16,
                borderColor: accentColor.withValues(alpha: 0.5),
                child: Row(
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
                    Expanded(
                      child: Text(
                        _liveStatus,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
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
                          child: Icon(Icons.search, color: accentColor, size: 48),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ask me anything',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'I\'ll search for factual answers',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
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

          // Input field
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: 28,
              blur: 20,
              borderColor: isDark ? AppColors.glassBorder : LightColors.glassBorder,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask a factual question...',
                          hintStyle: TextStyle(
                            color: secondaryTextColor.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        maxLines: 1,
                        enabled: !_isProcessing,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    
                    // Send button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _textController.text.isNotEmpty
                              ? [accentColor, secondaryAccent]
                              : [
                                  secondaryTextColor.withValues(alpha: 0.3),
                                  secondaryTextColor.withValues(alpha: 0.2),
                                ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isProcessing ? null : _sendMessage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
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
    final isGrounded = message.metadata?['isGrounded'] as bool? ?? false;
    final citations = message.metadata?['citations'] as List?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGrounded
                      ? [
                          Colors.green.shade400.withValues(alpha: 0.3),
                          accentColor.withValues(alpha: 0.2),
                        ]
                      : [
                          secondaryAccent.withValues(alpha: 0.3),
                          accentColor.withValues(alpha: 0.2),
                        ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isGrounded 
                      ? Colors.green.shade400.withValues(alpha: 0.5)
                      : secondaryAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isGrounded ? Icons.verified : Icons.psychology_outlined,
                color: isGrounded ? Colors.green.shade400 : secondaryAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              borderRadius: 20,
              borderColor: message.isUser
                  ? accentColor.withValues(alpha: 0.5)
                  : (isDark ? AppColors.glassBorder : const Color(0xFFE0E0E0)),
              gradient: message.isUser
                  ? LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.25),
                        secondaryAccent.withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (isGrounded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green.shade400,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Grounded Answer',
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
