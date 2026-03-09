import 'package:flutter/material.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:glass_kit/glass_kit.dart';

/// ThoughtTraceTerminal - Displays AI thinking process in real-time
/// Shows thought_summary and verification steps from Nova 3.0
class ThoughtTraceTerminal extends StatefulWidget {
  final String? thoughtSummary;
  final List<Map<String, dynamic>>? verificationSteps;
  final bool isAnimated;

  const ThoughtTraceTerminal({
    super.key,
    this.thoughtSummary,
    this.verificationSteps,
    this.isAnimated = true,
  });

  @override
  State<ThoughtTraceTerminal> createState() => _ThoughtTraceTerminalState();
}

class _ThoughtTraceTerminalState extends State<ThoughtTraceTerminal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    if (widget.isAnimated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.thoughtSummary == null && 
        (widget.verificationSteps == null || widget.verificationSteps!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GlassContainer(
        height: null,
        width: double.infinity,
        gradient: LinearGradient(
          colors: [
            AppColors.neonTeal.withOpacity(0.1),
            AppColors.softPurple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            AppColors.neonTeal.withOpacity(0.5),
            AppColors.softPurple.withOpacity(0.5),
          ],
        ),
        blur: 20,
        borderWidth: 1.5,
        elevation: 8,
        isFrostedGlass: true,
        shadowColor: AppColors.neonTeal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terminal Header
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.neonTeal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonTeal.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Thought Process',
                    style: TextStyle(
                      color: AppColors.neonTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.psychology,
                    color: AppColors.softPurple,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Thought Summary
              if (widget.thoughtSummary != null) ...[
                _buildTerminalLine(
                  icon: Icons.lightbulb_outline,
                  label: 'SUMMARY',
                  content: widget.thoughtSummary!,
                  color: AppColors.neonTeal,
                ),
                const SizedBox(height: 12),
              ],
              
              // Verification Steps
              if (widget.verificationSteps != null && 
                  widget.verificationSteps!.isNotEmpty) ...[
                _buildTerminalLine(
                  icon: Icons.verified_outlined,
                  label: 'VERIFICATION',
                  content: 'Split-Step Analysis (${widget.verificationSteps!.length} phases)',
                  color: AppColors.softPurple,
                ),
                const SizedBox(height: 8),
                ...widget.verificationSteps!.map((step) => _buildVerificationStep(step)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalLine({
    required IconData icon,
    required String label,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep(Map<String, dynamic> step) {
    final phase = step['phase'] ?? 0;
    final name = step['name'] ?? 'Unknown Step';
    final reasoning = step['reasoning'] ?? '';
    
    Color phaseColor;
    switch (phase) {
      case 1:
        phaseColor = AppColors.neonTeal;
        break;
      case 2:
        phaseColor = AppColors.softPurple;
        break;
      case 3:
        phaseColor = Colors.greenAccent;
        break;
      default:
        phaseColor = Colors.white70;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: phaseColor.withOpacity(0.2),
                  border: Border.all(color: phaseColor, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$phase',
                    style: TextStyle(
                      color: phaseColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (reasoning.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                reasoning,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
