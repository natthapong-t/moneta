import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B);    // Slate 800
  static const Color surfaceLight = Color(0xFF334155);// Slate 700

  // Brand Accents
  static const Color primary = Color(0xFF10B981);   // Emerald 500
  static const Color primaryGlow = Color(0x3310B981);
  static const Color accent = Color(0xFF6366F1);    // Indigo 500

  // Category Colors
  static const Color catFood = Color(0xFFF97316);       // Orange
  static const Color catTransport = Color(0xFF0EA5E9);  // Sky Blue
  static const Color catShopping = Color(0xFFEC4899);   // Pink
  static const Color catBills = Color(0xFF10B981);      // Emerald Green
  static const Color catOther = Color(0xFF8B5CF6);      // Purple

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
