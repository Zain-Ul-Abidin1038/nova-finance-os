import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';

class RunwayGauge extends StatefulWidget {
  final double currentBalance;
  final double monthlyBurn;
  final double predictedRunway; // in months

  const RunwayGauge({
    super.key,
    required this.currentBalance,
    required this.monthlyBurn,
    required this.predictedRunway,
  });

  @override
  State<RunwayGauge> createState() => _RunwayGaugeState();
}

class _RunwayGaugeState extends State<RunwayGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.predictedRunway / 12)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.flight_takeoff, color: AppColors.neonTeal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Financial Runway',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRunwayColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getRunwayColor().withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRunwayStatus(),
                  style: TextStyle(
                    color: _getRunwayColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Animated Gauge
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: RunwayGaugePainter(
                    progress: _animation.value,
                    runwayMonths: widget.predictedRunway,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Balance',
                '\$${widget.currentBalance.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                AppColors.neonTeal,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.glassBorder.withOpacity(0.3),
              ),
              _buildStatColumn(
                'Monthly Burn',
                '\$${widget.monthlyBurn.toStringAsFixed(0)}',
                Icons.local_fire_department,
                AppColors.softPurple,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.glassBorder.withOpacity(0.3),
              ),
              _buildStatColumn(
                'Runway',
                '${widget.predictedRunway.toStringAsFixed(1)} mo',
                Icons.timeline,
                _getRunwayColor(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Prediction
          Pulse(
            infinite: true,
            duration: const Duration(seconds: 3),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.neonTeal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.neonTeal, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPredictionText(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getRunwayColor() {
    if (widget.predictedRunway >= 6) return AppColors.success;
    if (widget.predictedRunway >= 3) return AppColors.neonTeal;
    return AppColors.error;
  }

  String _getRunwayStatus() {
    if (widget.predictedRunway >= 6) return 'HEALTHY';
    if (widget.predictedRunway >= 3) return 'MODERATE';
    return 'CRITICAL';
  }

  String _getPredictionText() {
    if (widget.predictedRunway >= 6) {
      return 'Strong financial position. Consider investing in growth.';
    } else if (widget.predictedRunway >= 3) {
      return 'Moderate runway. Monitor spending and optimize deductions.';
    } else {
      return 'Critical: Reduce expenses or increase revenue immediately.';
    }
  }
}

class RunwayGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double runwayMonths;

  RunwayGaugePainter({
    required this.progress,
    required this.runwayMonths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = size.width * 0.35;
    const startAngle = math.pi; // Start from left
    const sweepAngle = math.pi; // Half circle

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.glassBorder.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc with gradient effect
    final progressAngle = sweepAngle * progress;
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _getColorForProgress(progress),
          _getColorForProgress(progress).withOpacity(0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = _getColorForProgress(progress).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      glowPaint,
    );

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: runwayMonths.toStringAsFixed(1),
        style: TextStyle(
          color: _getColorForProgress(progress),
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height - 10,
      ),
    );

    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'MONTHS',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy + 5,
      ),
    );

    // Tick marks
    _drawTickMarks(canvas, center, radius, startAngle, sweepAngle);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepAngle) {
    final tickPaint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 12; i += 3) {
      final angle = startAngle + (sweepAngle * i / 12);
      final innerRadius = radius + 25;
      final outerRadius = radius + 35;

      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);

      // Draw month labels
      final labelRadius = radius + 50;
      final labelPoint = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Color _getColorForProgress(double progress) {
    if (progress >= 0.5) return AppColors.success;
    if (progress >= 0.25) return AppColors.neonTeal;
    return AppColors.error;
  }

  @override
  bool shouldRepaint(RunwayGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
