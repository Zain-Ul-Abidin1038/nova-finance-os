// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/receipts/services/hive_transaction_provider.dart';
import 'package:nova_finance_os/core/services/nova_service.dart';
import 'package:nova_finance_os/core/services/aws_memory_service.dart';
import 'package:nova_finance_os/core/services/error_handler_service.dart';
import 'package:nova_finance_os/core/services/validation_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      text: 'Hello! I\'m your Finance OS AI assistant. Ask me anything about your expenses, tax deductions, or financial insights.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    // Validate message length
    final validation = ref.read(validationServiceProvider);
    final lengthError = validation.validateMaxLength(message, 1000, 'Message');
    if (lengthError != null) {
      if (mounted) {
        ref.read(errorHandlerProvider).showWarning(context, lengthError);
      }
      return;
    }

    // Capture context before async operations
    final currentContext = context;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Add thinking indicator
    setState(() {
      _messages.add(ChatMessage(
        text: 'Thinking...',
        isUser: false,
        timestamp: DateTime.now(),
        isThinking: true,
      ));
    });

    try {
      // Get Nova service with timeout
      final novaService = ref.read(novaServiceProvider);
      final memoryService = ref.read(awsMemoryServiceProvider);
      final transactionState = ref.read(hiveTransactionProvider);
      
      // Build transaction context for the prompt
      final transactionContext = transactionState.receipts.isEmpty
          ? 'No transactions yet.'
          : transactionState.receipts.map((t) => 
              '${t.vendor}: \$${t.total.toStringAsFixed(2)} (${t.category}) - Deductible: \$${t.deductibleAmount.toStringAsFixed(2)}'
            ).join('\n');
      
      // Get memory context (may be empty if not initialized)
      List<String> memories = [];
      try {
        memories = await memoryService.getRecentMemories(limit: 5);
      } catch (e) {
        // Memory service not initialized, continue without memories
        debugPrint('[Chat] Memory service not available: $e');
      }
      
      // Build enhanced prompt with context
      final enhancedPrompt = '''User question: $message

<current_transactions>
$transactionContext
</current_transactions>

Please provide a helpful response about their expenses, tax deductions, or financial insights.''';
      
      // Call Nova API with timeout
      final result = await ref.read(errorHandlerProvider).executeWithRetry(
        operation: () => novaService.sendMessage(
          prompt: enhancedPrompt,
          memoryContext: memories,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timed out. Please try again.'),
        ),
        context: currentContext,
        maxRetries: 1,
        errorTitle: 'Chat Error',
      );
      
      if (result == null) {
        // Error was already shown by executeWithRetry
        if (mounted) {
          setState(() {
            _messages.removeLast();
          });
        }
        return;
      }
      
      final response = result['text'] ?? 'No response from AI';
      
      if (mounted) {
        setState(() {
          // Remove thinking indicator
          _messages.removeLast();
          
          // Add AI response
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });

        // Scroll to bottom again
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
        });
        ref.read(errorHandlerProvider).showError(
          currentContext,
          e,
          title: 'Chat Error',
        );
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
    final surfaceColor = isDark ? AppColors.surfaceDark : LightColors.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
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
                  color: isDark 
                      ? AppColors.glassWhite 
                      : Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.glassBorder : LightColors.glassBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),
          ),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    secondaryAccent.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: secondaryAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondaryAccent.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: secondaryAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nova AI',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Financial Assistant',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 100), // Space for app bar
          
          // Messages List
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
                            boxShadow: [
                              BoxShadow(
                                color: secondaryAccent.withValues(alpha: 0.3),
                                blurRadius: 24,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: secondaryAccent,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask about expenses, deductions, or insights',
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
                        surfaceColor,
                        isDark,
                      );
                    },
                  ),
          ),

          // Input Area with proper glassmorphism using GlassCard
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              borderRadius: 28,
              blur: 20,
              borderColor: isDark ? AppColors.glassBorder : LightColors.glassBorder,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask Finance OS...',
                          hintStyle: TextStyle(
                            color: secondaryTextColor.withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accentColor, secondaryAccent],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _sendMessage,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
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
    Color surfaceColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                border: Border.all(
                  color: secondaryAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondaryAccent.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: secondaryAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? accentColor.withValues(alpha: 0.15)
                        : (isDark 
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.05)),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                borderRadius: 20,
                borderColor: message.isUser
                    ? accentColor.withValues(alpha: 0.4)
                    : (isDark ? AppColors.glassBorder : LightColors.glassBorder),
                gradient: message.isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.25),
                          secondaryAccent.withValues(alpha: 0.15),
                        ],
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isThinking)
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
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: accentColor,
                size: 20,
              ),
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isThinking;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isThinking = false,
  });
}
