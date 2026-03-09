import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/features/marathon/services/marathon_agent.dart';

class MarathonScreen extends ConsumerStatefulWidget {
  const MarathonScreen({super.key});

  @override
  ConsumerState<MarathonScreen> createState() => _MarathonScreenState();
}

class _MarathonScreenState extends ConsumerState<MarathonScreen> {
  MarathonTask? _currentTask;
  final List<String> _progressLogs = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Marathon Agent',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _currentTask == null
            ? _buildStartScreen()
            : _buildProgressScreen(),
      ),
    );
  }

  Widget _buildStartScreen() {
    return FadeIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Marathon Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.neonTeal, AppColors.softPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonTeal.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_run,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Financial Marathon Agent',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Autonomous multi-day financial tasks\nwith self-correction and verification',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Quick Start Options
              _buildQuickStartOption(
                icon: Icons.analytics,
                title: 'Optimize Q1 Taxes',
                description: '5-day analysis of all transactions',
                days: 5,
                onTap: () => _startMarathon(
                  'Optimize my Q1 taxes by analyzing all transactions and finding missed deductions',
                  const Duration(days: 5),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildQuickStartOption(
                icon: Icons.category,
                title: 'Categorize All Expenses',
                description: '3-day smart categorization',
                days: 3,
                onTap: () => _startMarathon(
                  'Categorize all my expenses intelligently and identify spending patterns',
                  const Duration(days: 3),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildQuickStartOption(
                icon: Icons.assessment,
                title: 'Generate Audit Report',
                description: '7-day comprehensive audit',
                days: 7,
                onTap: () => _startMarathon(
                  'Generate a comprehensive audit-ready financial report with all deductions',
                  const Duration(days: 7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStartOption({
    required IconData icon,
    required String title,
    required String description,
    required int days,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isRunning ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.glassBorder.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.neonTeal, AppColors.softPurple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$days days',
                    style: const TextStyle(
                      color: AppColors.neonTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressScreen() {
    final task = _currentTask!;
    final progress = task.progress.length / task.duration.inDays;
    
    return FadeIn(
      child: Column(
        children: [
          // Progress Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Goal
                Text(
                  task.goal,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Progress Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: AppColors.glassWhite,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.neonTeal,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Day ${task.currentDay}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'of ${task.duration.inDays}',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(task.status),
                    style: TextStyle(
                      color: _getStatusColor(task.status),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress Logs
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress Log',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _progressLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _progressLogs[index],
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                                  fontSize: 13,
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
          ),
        ],
      ),
    );
  }

  Future<void> _startMarathon(String goal, Duration duration) async {
    setState(() {
      _isRunning = true;
      _progressLogs.clear();
    });

    final agent = ref.read(marathonAgentProvider);

    try {
      // Start marathon
      final task = await agent.startMarathon(
        goal: goal,
        duration: duration,
        onProgress: (message) {
          setState(() {
            _progressLogs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
          });
        },
      );

      setState(() {
        _currentTask = task;
      });

      // Execute Day 1 (demo)
      final dayResult = await agent.executeDayTask(
        task: task,
        day: 1,
        onProgress: (message) {
          setState(() {
            _progressLogs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
          });
        },
      );

      // Update task with day 1 results
      setState(() {
        _currentTask = task.copyWith(
          currentDay: 2,
          progress: [dayResult],
        );
        _progressLogs.add('[${DateTime.now().toString().substring(11, 19)}] ✓ Day 1 complete');
      });

      // Self-correct if needed
      if (dayResult.errors.isNotEmpty) {
        await agent.correctErrors(
          task: task,
          errors: dayResult.errors,
          onProgress: (message) {
            setState(() {
              _progressLogs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
            });
          },
        );
      }

    } catch (e) {
      setState(() {
        _progressLogs.add('[ERROR] $e');
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Color _getStatusColor(MarathonStatus status) {
    switch (status) {
      case MarathonStatus.planning:
        return AppColors.softPurple;
      case MarathonStatus.running:
        return AppColors.neonTeal;
      case MarathonStatus.paused:
        return Colors.orange;
      case MarathonStatus.completed:
        return AppColors.success;
      case MarathonStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText(MarathonStatus status) {
    switch (status) {
      case MarathonStatus.planning:
        return '🧠 Planning';
      case MarathonStatus.running:
        return '🏃 Running';
      case MarathonStatus.paused:
        return '⏸️ Paused';
      case MarathonStatus.completed:
        return '✓ Completed';
      case MarathonStatus.failed:
        return '❌ Failed';
    }
  }
}
