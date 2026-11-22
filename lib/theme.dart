import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sonic Obsidian design tokens (from DESIGN.md + the Stitch HTML files).
class AppColors {
  static const surface = Color(0xFF131313);
  static const surfaceBright = Color(0xFF393939);
  static const surfaceLowest = Color(0xFF0E0E0E);
  static const surfaceLow = Color(0xFF1C1B1B);
  static const surfaceContainer = Color(0xFF201F1F);
  static const surfaceHigh = Color(0xFF2A2A2A);
  static const surfaceHighest = Color(0xFF353534);

  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFBCCBB9);

  static const primary = Color(0xFF53E076);
  static const primaryContainer = Color(0xFF1DB954);
  static const onPrimary = Color(0xFF003914);
  static const onPrimaryContainer = Color(0xFF004118);
  static const primaryFixed = Color(0xFF72FE8F);
  static const onPrimaryFixed = Color(0xFF002108);

  static const secondary = Color(0xFFFFB3AF);
  static const secondaryContainer = Color(0xFFFF5357);
  static const onSecondary = Color(0xFF68000E);

  static const tertiary = Color(0xFFDDB7FF);
  static const tertiaryContainer = Color(0xFFC385FF);

  static const outline = Color(0xFF869585);
  static const outlineVariant = Color(0xFF3D4A3D);

  // Neon equalizer colors used in the floating nudge.
  static const neonGreen = Color(0xFF1DB954);
  static const neonCyan = Color(0xFF00F2FE);
  static const neonViolet = Color(0xFFC385FF);
  static const neonPink = Color(0xFFFF537C);
  static const neonAmber = Color(0xFFFFB800);
}

class AppText {
  static TextStyle headlineLarge(Color c) => GoogleFonts.spaceGrotesk(
        fontSize: 28, fontWeight: FontWeight.w600, height: 34 / 28,
        letterSpacing: -0.01, color: c,
      );
  static TextStyle headlineSmall(Color c) => GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20, color: c,
      );
  static TextStyle titleLarge(Color c) => GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18, color: c,
      );
  static TextStyle titleMedium(Color c) => GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600, height: 22 / 16,
        letterSpacing: 0.01, color: c,
      );
  static TextStyle bodyMedium(Color c) => GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14,
        letterSpacing: 0.015, color: c,
      );
  static TextStyle bodySmall(Color c) => GoogleFonts.plusJakartaSans(
        fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12,
        letterSpacing: 0.02, color: c,
      );
  static TextStyle labelLarge(Color c) => GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600, height: 20 / 14,
        letterSpacing: 0.02, color: c,
      );
  static TextStyle labelMedium(Color c) => GoogleFonts.plusJakartaSans(
        fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12,
        letterSpacing: 0.03, color: c,
      );
  static TextStyle labelSmall(Color c) => GoogleFonts.plusJakartaSans(
        fontSize: 10, fontWeight: FontWeight.w700, height: 14 / 10,
        letterSpacing: 0.05, color: c,
      );
}

class AppTheme {
  static ThemeData get dark {
    final cs = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.secondaryContainer,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.titleLarge(AppColors.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppText.labelLarge(AppColors.onPrimary),
        ),
      ),
    );
  }
}
