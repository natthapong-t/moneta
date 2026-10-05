import 'package:flutter/material.dart';

class AppColors {
  // Imperial Roman Dark Backgrounds
  static const Color background = Color(0xFF090D16);       // Deep Obsidian
  static const Color surface = Color(0xFF131926);          // Temple Slate
  static const Color surfaceLight = Color(0xFF1F293D);     // Marble Slate

  // Imperial Gold & Royalty
  static const Color gold = Color(0xFFD4AF37);             // Classic Roman Gold
  static const Color goldBright = Color(0xFFF59E0B);       // Sun Gold
  static const Color goldGlow = Color(0x40D4AF37);         // Gold Aura
  static const Color tyrianPurple = Color(0xFF6B21A8);     // Emperor's Purple
  static const Color waxSealRed = Color(0xFF991B1B);       // Crimson Wax Seal

  // Roman 4 Vault Colors
  static const Color vaultTaverna = Color(0xFFE11D48);     // Wine / Feast (Food)
  static const Color vaultQuadriga = Color(0xFF0284C7);    // Chariot / Armor (Transport)
  static const Color vaultForum = Color(0xFFD97706);       // Market / Gold (Shopping)
  static const Color vaultTributum = Color(0xFF059669);    // Laurel Leaf / Tribute (Bills)

  // Typography
  static const Color marbleWhite = Color(0xFFF8FAFC);      // Carrara White
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get romanDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        surface: AppColors.surface,
        onSurface: AppColors.marbleWhite,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
