import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Theme mode provider with persistence
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _themeBoxName = 'settings';
  static const String _themeModeKey = 'themeMode';
  
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    try {
      final box = await Hive.openBox(_themeBoxName);
      final savedTheme = box.get(_themeModeKey, defaultValue: 'light') as String;
      state = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (e) {
      // If loading fails, keep default light theme
      state = ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    await _saveTheme(newMode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _saveTheme(mode);
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final box = await Hive.openBox(_themeBoxName);
      await box.put(_themeModeKey, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (e) {
      // Silently fail if save fails
    }
  }

  bool get isDark => state == ThemeMode.dark;
}

// Dark Theme
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.dark(
    primary: AppColors.neonTeal,
    secondary: AppColors.softPurple,
    surface: AppColors.surfaceDark,
    background: AppColors.background,
    error: AppColors.error,
  ),
  useMaterial3: true,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
);

// Light Theme
final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F7FA),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF00BCD4), // Lighter teal
    secondary: const Color(0xFF9C27B0), // Lighter purple
    surface: Colors.white,
    background: const Color(0xFFF5F7FA),
    error: const Color(0xFFE53935),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: const Color(0xFF1A1A1A),
    onBackground: const Color(0xFF1A1A1A),
  ),
  useMaterial3: true,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
    titleTextStyle: TextStyle(
      color: Color(0xFF1A1A1A),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);

// Light mode colors (for widgets that need explicit colors)
class LightColors {
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const surfaceLight = Color(0xFFFAFBFC);
  static const surfaceDark = Color(0xFFE8EBF0);
  
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  
  static const neonTeal = Color(0xFF00BCD4);
  static const softPurple = Color(0xFF9C27B0);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFF9800);
  
  static const glassBorder = Color(0xFFE0E0E0);
}
