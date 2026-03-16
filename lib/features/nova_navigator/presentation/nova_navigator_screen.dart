import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/features/nova_navigator/services/nova_navigator_service.dart';
import 'package:nova_finance_os/features/nova_navigator/domain/navigation_task.dart';

class NovaNavigatorScreen extends ConsumerStatefulWidget {
  const NovaNavigatorScreen({super.key});

  @override
  ConsumerState<NovaNavigatorScreen> createState() => _NovaNavigatorScreenState();
}

class _NovaNavigatorScreenState extends ConsumerState<NovaNavigatorScreen> {
  final TextEditingController _taskController = TextEditingController();
  bool _isExecuting = false;
  NavigationTask? _currentTask;
  List<String> _executionLog = [];
  String _currentThought = '';

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _startTask() async {
    final taskDescription = _taskController.text.trim();
    if (taskDescription.isEmpty || _isExecuting) return;

    setState(() {
      _isExecuting = true;
      _executionLog.clear();
      _currentThought = 'Understanding your request...';
    });

    _addLog('🎯 Task: $taskDescription');

    try {
      final navigatorService = ref.read(novaNavigatorServiceProvider);
      
      // Create task
      final task = NavigationTask(
        description: taskDescription,
        status: TaskStatus.planning,
        createdAt: DateTime.now(),
      );

      setState(() => _currentTask = task);

      // Execute task with real-time updates
      await for (final update in navigatorService.executeTask(task)) {
        if (!mounted) break;

        setState(() {
          _currentThought = update['thought'] ?? '';
          if (update['log'] != null) {
            _addLog(update['log']);
          }
          if (update['status'] != null) {
            _currentTask = _currentTask?.copyWith(status: update['status']);
          }
        });
      }

      _addLog('✅ Task completed successfully!');
    } catch (e) {
      _addLog('❌ Error: $e');
      safePrint('[NovaNavigator] Error: $e');
    } finally {
      setState(() {
        _isExecuting = false;
        _currentThought = '';
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _executionLog.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  void _showQuickTasks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickTasksSheet(),
    );
  }

  Widget _buildQuickTasksSheet() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final quickTasks = [
      {
        'icon': Icons.analytics_outlined,
        'title': 'Spending Analysis',
        'description': 'Analyze your spending patterns',
        'task': 'Analyze my spending patterns this month and suggest where I can save',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Budget Plan',
        'description': 'Create a smart budget',
        'task': 'Create a monthly budget plan based on my income and expenses',
      },
      {
        'icon': Icons.category_outlined,
        'title': 'Categorize Expenses',
        'description': 'Auto-categorize transactions',
        'task': 'Review and categorize my recent uncategorized expenses',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Cashflow Forecast',
        'description': 'Predict future cashflow',
        'task': 'Forecast my cashflow for the next 30 days based on my transaction history',
      },
      {
        'icon': Icons.receipt_long_outlined,
        'title': 'Tax Summary',
        'description': 'Prepare tax deductions',
        'task': 'Summarize my tax-deductible expenses and generate a tax report',
      },
      {
        'icon': Icons.savings_outlined,
        'title': 'Savings Goal',
        'description': 'Plan your savings',
        'task': 'Help me set up a savings goal and calculate how much I need to save monthly',
      },
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 500,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.glassWhite
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppColors.glassBorder : LightColors.glassBorder,
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
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Quick Tasks',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : LightColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: quickTasks.length,
                  itemBuilder: (context, index) {
                    final task = quickTasks[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _taskController.text = task['task'] as String;
                        _startTask();
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              task['icon'] as IconData,
                              color: AppColors.neonTeal,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              task['title'] as String,
                              style: TextStyle(
                                color: isDark ? AppColors.textPrimary : LightColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task['description'] as String,
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondary : LightColors.textSecondary,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    final backgroundColor = isDark ? AppColors.background : LightColors.background;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;

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
                ),
                child: Icon(Icons.arrow_back, color: textColor, size: 20),
              ),
            ),
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
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
                Icons.smart_toy_outlined,
                color: AppColors.softPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NovaNavigator',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI Agent • Financial Automation',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.apps, color: textColor),
            onPressed: _showQuickTasks,
            tooltip: 'Quick Tasks',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          
          // Task input
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        color: AppColors.neonTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What should I do for you?',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taskController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g., "Analyze my spending" or "Create a budget plan"',
                      hintStyle: TextStyle(
                        color: secondaryTextColor.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.glassBorder : LightColors.glassBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.glassBorder : LightColors.glassBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.neonTeal,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                    enabled: !_isExecuting,
                    onSubmitted: (_) => _startTask(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExecuting ? null : _startTask,
                      icon: _isExecuting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isExecuting ? 'Executing...' : 'Start Task'),
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
                ],
              ),
            ),
          ),
          
          // Current thought
          if (_currentThought.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.softPurple),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentThought,
                        style: TextStyle(
                          color: AppColors.softPurple,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Execution log
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.terminal,
                          color: AppColors.neonTeal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Execution Log',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_executionLog.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, size: 20, color: secondaryTextColor),
                            onPressed: () => setState(() => _executionLog.clear()),
                            tooltip: 'Clear log',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _executionLog.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: secondaryTextColor.withValues(alpha: 0.5),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tasks executed yet',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter a task above to get started',
                                    style: TextStyle(
                                      color: secondaryTextColor.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _executionLog.length,
                              itemBuilder: (context, index) {
                                final log = _executionLog[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      height: 1.5,
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
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
