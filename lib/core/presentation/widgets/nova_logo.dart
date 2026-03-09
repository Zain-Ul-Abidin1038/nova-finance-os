import 'package:flutter/material.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';

/// Circular Nova Logo with optional neon glow effect
/// Used in auth screen, chat welcome, and message avatars
class NovaLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  
  const NovaLogo({
    super.key,
    this.size = 160,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showGlow
            ? LinearGradient(
                colors: [
                  AppColors.neonTeal.withValues(alpha: 0.3),
                  AppColors.softPurple.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.neonTeal.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppColors.softPurple.withValues(alpha: 0.3),
                  blurRadius: 60,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: Container(
        margin: EdgeInsets.all(showGlow ? 4 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: showGlow ? AppColors.surfaceDark : Colors.transparent,
          border: showGlow
              ? Border.all(
                  color: AppColors.glassBorder.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/nova_profile.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image not found
              return Icon(
                Icons.auto_awesome,
                color: AppColors.neonTeal,
                size: size * 0.4,
              );
            },
          ),
        ),
      ),
    );
  }
}
