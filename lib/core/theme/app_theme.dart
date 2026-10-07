import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Duolingo & Arcade Flat Light Mode Canvas
  static const Color background = Color(0xFFF7F9FA);       // Crisp playful off-white
  static const Color surface = Color(0xFFFFFFFF);          // Pure White
  static const Color surfaceLight = Color(0xFFF1F5F9);     // Soft cool tint
  static const Color border = Color(0xFFE5E7EB);           // Crisp border
  static const Color borderDark = Color(0xFFCBD5E1);       // Darker cartoon border
  static const Color shadowDefault = Color(0xFFD1D5DB);    // Flat 3D neutral bevel

  // Duolingo Punchy Cartoon Accents
  static const Color gold = Color(0xFFFFC800);             // Arcade Gold / Star
  static const Color goldShadow = Color(0xFFE5A500);       // Gold 3D bottom bevel
  static const Color goldBright = Color(0xFFFFD93D);       // Highlight Gold
  static const Color goldGlow = Color(0x33FFC800);

  // Duolingo 4 Vault Colors (Main + Solid 3D Bevel Shadow)
  // 1. Food: Vibrant Coral Red
  static const Color vaultTaverna = Color(0xFFFF4B4B);
  static const Color vaultTavernaShadow = Color(0xFFD32F2F);
  static const Color vaultTavernaBg = Color(0xFFFFF0F0);

  // 2. Transport: Electric Sky Blue
  static const Color vaultQuadriga = Color(0xFF1CB0F6);
  static const Color vaultQuadrigaShadow = Color(0xFF1899D6);
  static const Color vaultQuadrigaBg = Color(0xFFF0F9FF);

  // 3. Shopping: Playful Lilac Purple
  static const Color vaultForum = Color(0xFFCE82FF);
  static const Color vaultForumShadow = Color(0xFFA855F7);
  static const Color vaultForumBg = Color(0xFFFAF5FF);

  // 4. Bills: Duolingo Lime Green
  static const Color vaultTributum = Color(0xFF58CC02);
  static const Color vaultTributumShadow = Color(0xFF46A302);
  static const Color vaultTributumBg = Color(0xFFF0FDF4);

  // Supporting Cartoon Accents
  static const Color tyrianPurple = Color(0xFF9333EA);
  static const Color waxSealRed = Color(0xFFFF4B4B);

  // Financial Indicators (Income vs Expense)
  static const Color emerald = Color(0xFF10B981);          // Fresh Income Green
  static const Color emeraldShadow = Color(0xFF059669);    // Income 3D Shadow
  static const Color emeraldBg = Color(0xFFECFDF5);        // Income Light Tint
  static const Color expenseRed = Color(0xFFFF4B4B);       // Expense Red
  static const Color expenseRedShadow = Color(0xFFD32F2F);

  // High-Contrast Cartoon Typography
  static const Color marbleWhite = Color(0xFF1E293B);      // Dark Charcoal / Slate for bold headings
  static const Color textPrimary = Color(0xFF1E293B);      // Dark slate
  static const Color textSecondary = Color(0xFF64748B);    // Medium slate
  static const Color textMuted = Color(0xFF94A3B8);        // Soft slate
}

class AppTheme {
  /// Duolingo-style flat 3D bevel shadow (Zero blur, crisp bottom extrusion)
  static List<BoxShadow> arcadeShadow({
    required Color shadowColor,
    double depth = 4.0,
  }) {
    return [
      BoxShadow(
        color: shadowColor,
        offset: Offset(0, depth),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    final notoSansThaiTheme = GoogleFonts.notoSansThaiTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.notoSansThai().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: notoSansThaiTheme,
      primaryTextTheme: notoSansThaiTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.notoSansThai(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static ThemeData get romanDarkTheme => lightTheme;
}

