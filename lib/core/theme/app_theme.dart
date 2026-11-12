import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Mintio OLED Dark Midnight Canvas (Standardized 20-Ways Unslop Palette)
  static const Color background = Color(0xFF0D0E14);       // OLED Deep Dark (#0D0E14)
  static const Color surface = Color(0xFF161722);          // Clean Midnight surface (#161722)
  static const Color surfaceElevated = Color(0xFF1F212E);  // Elevated card (#1F212E)
  static const Color surfaceLight = surfaceElevated;       // Backward compatibility alias
  static const Color border = Color(0xFF282A3A);           // Subtle crisp 1px border (#282A3A)
  static const Color borderDark = Color(0xFF363847);       // Border dark (#363847)
  static const Color shadowDefault = Color(0xFF14151E);    // Dark shadow (#14151E)

  // Clean Crisp Accents
  static const Color indigoPrimary = Color(0xFF4F5FFA);    // Crisp Electric Indigo (#4F5FFA)
  static const Color mintSuccess = Color(0xFF2ED573);      // Clean Mint Green (#2ED573)

  // Duolingo & Mintio Punchy Cartoon Accents (Aliases & Shadows)
  static const Color gold = indigoPrimary;                 // Electric Indigo (Unified Mintio Primary)
  static const Color goldShadow = Color(0xFF3B48D8);       // Electric Indigo 3D bottom bevel
  static const Color goldBright = Color(0xFF6C7CFF);       // Highlight Electric Indigo
  static const Color goldGlow = Color(0x334F5FFA);

  // Duolingo 4 Vault Colors (Main + Solid 3D Bevel Shadow)
  // 1. Food: Vibrant Coral Red
  static const Color vaultTaverna = Color(0xFFFF4B4B);
  static const Color vaultTavernaShadow = Color(0xFFD32F2F);
  static const Color vaultTavernaBg = Color(0xFF2A1E24);

  // 2. Transport: Electric Sky Blue
  static const Color vaultQuadriga = Color(0xFF1CB0F6);
  static const Color vaultQuadrigaShadow = Color(0xFF1899D6);
  static const Color vaultQuadrigaBg = Color(0xFF1A2634);

  // 3. Shopping: Playful Lilac Purple
  static const Color vaultForum = Color(0xFFCE82FF);
  static const Color vaultForumShadow = Color(0xFFA855F7);
  static const Color vaultForumBg = Color(0xFF261D33);

  // 4. Bills: Duolingo Lime Green
  static const Color vaultTributum = Color(0xFF58CC02);
  static const Color vaultTributumShadow = Color(0xFF46A302);
  static const Color vaultTributumBg = Color(0xFF1A2B1D);

  // Supporting Cartoon Accents
  static const Color tyrianPurple = Color(0xFF9333EA);
  static const Color waxSealRed = Color(0xFFFF4B4B);

  // Financial Indicators (Income vs Expense)
  static const Color emerald = Color(0xFF10B981);          // Fresh Income Green
  static const Color emeraldShadow = Color(0xFF059669);    // Income 3D Shadow
  static const Color emeraldBg = Color(0xFF132820);        // Income Dark Tint
  static const Color expenseRed = Color(0xFFFF4B4B);       // Expense Red
  static const Color expenseRedShadow = Color(0xFFD32F2F);

  // High-Contrast Pure White Typography & Secondary
  static const Color marbleWhite = Color(0xFFFFFFFF);      // Pure white headings (#FFFFFF)
  static const Color textPrimary = Color(0xFFFFFFFF);      // Pure white (#FFFFFF)
  static const Color textSecondary = Color(0xFF9EA3B8);    // High-contrast Slate Grey (#9EA3B8)
  static const Color textMuted = Color(0xFF6C728A);        // Clean Slate Muted (#6C728A)

  // Mintio Aesthetic Palette Aliases (Backward-compatibility)
  static const Color mintioMidnight = background;          // Deep OLED canvas
  static const Color mintioCard = surface;                 // Dark card surface
  static const Color mintioCardElevated = surfaceElevated; // Elevated card
  static const Color mintioBorder = border;                // Subtle divider
  static const Color mintioIndigo = indigoPrimary;         // Primary electric action button
  static const Color mintioIndigoLight = Color(0xFF6C7CFF);// Highlight indigo
  static const Color mintioPurple = Color(0xFF6C5CE7);     // Creature card violet
  static const Color mintioCoral = Color(0xFFFF6B4A);      // Creature coral / food
  static const Color mintioRed = Color(0xFFFF4B4B);        // Alert / Delete red
  static const Color mintioMint = mintSuccess;             // Mascot green / success check
  static const Color mintioStreakFlame = Color(0xFFFF5722);// Flame orange streak
  static const Color mintioTextPrimary = textPrimary;      // Pure white headings & numbers
  static const Color mintioTextSecondary = textSecondary;  // High-contrast Slate Grey
  static const Color mintioTextMuted = textMuted;          // Clean Slate Muted
}

class AppTheme {
  /// Rule 4 & 18: Tabular figures utility for monetary amounts, numbers, and stats
  static TextStyle tabularFigures({TextStyle? base}) {
    final style = base ?? const TextStyle();
    return style.copyWith(
      fontFeatures: [
        ...?style.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  /// Rule 14: Golden Corner Radius Formula (`inner radius = outer - padding`)
  static double innerRadius(double outerRadius, double padding) {
    return (outerRadius - padding).clamp(4.0, outerRadius);
  }

  /// Helper for inner border radius based on Rule 14
  static BorderRadius innerBorderRadius(double outerRadius, double padding) {
    return BorderRadius.circular(innerRadius(outerRadius, padding));
  }

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

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    final notoSansThaiTheme = GoogleFonts.notoSansThaiTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      // ignore: deprecated_member_use
      dialogBackgroundColor: AppColors.surface,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
      ),
      cardColor: AppColors.surface,
      fontFamily: GoogleFonts.notoSansThai().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.indigoPrimary,
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

  static ThemeData get lightTheme => darkTheme;

  static ThemeData get romanDarkTheme => darkTheme;
}

/// Rule 4 & 18: Extension for easily applying tabular figures to any TextStyle
extension TabularFiguresExtension on TextStyle {
  TextStyle withTabularFigures() {
    return AppTheme.tabularFigures(base: this);
  }
}
